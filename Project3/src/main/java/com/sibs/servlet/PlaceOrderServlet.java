package com.sibs.servlet;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import jakarta.servlet.*;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import com.sibs.dao.OrderDAO;
import com.sibs.dao.CartDAO;
import com.sibs.dao.ProductDAO;
import com.sibs.dao.OrderStatusHistoryDAO;
import com.sibs.dao.NotificationDAO;          // ← NEW
import com.sibs.dao.CouponDAO;
import com.sibs.dao.CustomerWalletDAO;
import com.sibs.util.EmailService;
import com.sibs.model.User;
import com.sibs.model.Product;
import com.sibs.util.DBConnection;

@MultipartConfig
@WebServlet("/placeOrder")
public class PlaceOrderServlet extends HttpServlet {

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession();
        User user = (User) session.getAttribute("customer");

        if (user == null) {
            response.sendRedirect("customer-login.jsp");
            return;
        }

        int userId = user.getId();

        String productIdParam = request.getParameter("productId");
        String qtyParam       = request.getParameter("qty");
        String paymentMethod  = request.getParameter("paymentMethod");
        String addressId      = request.getParameter("selectedAddress");

        if (paymentMethod != null) paymentMethod = paymentMethod.trim();

        System.out.println("[PlaceOrder] userId="        + userId);
        System.out.println("[PlaceOrder] addressId="     + addressId);
        System.out.println("[PlaceOrder] paymentMethod=" + paymentMethod);

        boolean isOnline = "UPI".equalsIgnoreCase(paymentMethod)
                        || "Card".equalsIgnoreCase(paymentMethod)
                        || "ONLINE".equalsIgnoreCase(paymentMethod);

        if (isOnline) {
            response.setContentType("application/json");
            response.setCharacterEncoding("UTF-8");
        }

        PrintWriter out = response.getWriter();

        // Build item list
        List<Product> itemsToOrder = new ArrayList<>();
        boolean isBuyNow = (productIdParam != null && !productIdParam.trim().isEmpty());

        String[] selProductIds = request.getParameterValues("selectedProductIds");
        String[] selQtys       = request.getParameterValues("selectedQtys");
        boolean  isSelected    = (!isBuyNow && selProductIds != null && selProductIds.length > 0);

        if (isBuyNow) {
            try {
                int productId = Integer.parseInt(productIdParam.trim());
                int qty       = Integer.parseInt(qtyParam != null ? qtyParam.trim() : "1");
                ProductDAO productDAO = new ProductDAO();
                Product p = productDAO.getProductById(productId);
                if (p == null) { writeError(out, isOnline, response, session, "Product not found"); return; }
                p.setQuantity(qty);
                itemsToOrder.add(p);
            } catch (Exception e) {
                e.printStackTrace();
                String msg = e.getMessage() != null ? e.getMessage() : e.getClass().getSimpleName();
                writeError(out, isOnline, response, session, "Invalid product data: " + msg); return;
            }
        } else if (isSelected) {
            ProductDAO productDAO = new ProductDAO();
            for (int i = 0; i < selProductIds.length; i++) {
                try {
                    int pid = Integer.parseInt(selProductIds[i].trim());
                    int qty = (selQtys != null && i < selQtys.length) ? Integer.parseInt(selQtys[i].trim()) : 1;
                    Product p = productDAO.getProductById(pid);
                    if (p == null) continue;
                    p.setQuantity(qty);
                    itemsToOrder.add(p);
                } catch (Exception e) { e.printStackTrace(); }
            }
            if (itemsToOrder.isEmpty()) { writeError(out, isOnline, response, session, "No valid products selected"); return; }
        } else {
            CartDAO cartDAO = new CartDAO();
            List<Product> cart = cartDAO.getCartByUser(userId);
            if (cart == null || cart.isEmpty()) { writeError(out, isOnline, response, session, "Cart is empty"); return; }
            itemsToOrder = cart;
        }

        // Resolve delivery address
        String name     = request.getParameter("name");
        String phone    = request.getParameter("phone");
        String altPhone = request.getParameter("altPhone");
        String email    = request.getParameter("email");
        String address  = request.getParameter("address");

        try {
            if (addressId != null && !addressId.trim().isEmpty()) {
                try (Connection con = DBConnection.getConnection();
                     PreparedStatement ps = con.prepareStatement(
                         "SELECT name, phone, address FROM addresses WHERE id = ? AND user_id = ?")) {
                    ps.setInt(1, Integer.parseInt(addressId.trim()));
                    ps.setInt(2, userId);
                    ResultSet rs = ps.executeQuery();
                    if (rs.next()) {
                        name    = rs.getString("name");
                        phone   = rs.getString("phone");
                        address = rs.getString("address");
                    } else {
                        writeError(out, isOnline, response, session, "Selected address not found. Please choose another."); return;
                    }
                }
            } else {
                if (address == null || address.trim().isEmpty()) {
                    writeError(out, isOnline, response, session, "Please fill in a delivery address."); return;
                }
                try (Connection con = DBConnection.getConnection();
                     PreparedStatement ps = con.prepareStatement(
                         "INSERT INTO addresses(user_id, name, phone, address, is_default) VALUES(?,?,?,?,0)")) {
                    ps.setInt(1, userId);
                    ps.setString(2, name);
                    ps.setString(3, phone);
                    ps.setString(4, address);
                    ps.executeUpdate();
                }
                try (Connection con = DBConnection.getConnection();
                     PreparedStatement ps = con.prepareStatement(
                         "UPDATE users SET phone=?, address=? WHERE id=?")) {
                    ps.setString(1, phone);
                    ps.setString(2, address);
                    ps.setInt(3, userId);
                    ps.executeUpdate();
                }
                user.setPhone(phone);
                user.setAddress(address);
                session.setAttribute("customer", user);
            }

            if (name == null || name.trim().isEmpty() || address == null || address.trim().isEmpty()) {
                writeError(out, isOnline, response, session, "Delivery address is incomplete."); return;
            }

            // ── Coupon: read params passed from checkout form ────────────
            String couponCode     = request.getParameter("couponCode");
            double couponDiscount = 0;
            try {
                String cd = request.getParameter("couponDiscount");
                if (cd != null && !cd.trim().isEmpty()) couponDiscount = Double.parseDouble(cd.trim());
            } catch (Exception ignored) {}

            // ── Wallet: read params passed from checkout form ────────────
            String useWalletParam  = request.getParameter("useWallet");
            String walletAmtParam  = request.getParameter("walletAmount");
            double walletDeducted  = 0;
            if ("true".equals(useWalletParam) && walletAmtParam != null && !walletAmtParam.trim().isEmpty()) {
                try { walletDeducted = Double.parseDouble(walletAmtParam.trim()); } catch (Exception ignored) {}
            }

            // Calculate totals
            double subtotal = 0;
            for (Product p : itemsToOrder) subtotal += p.getPrice() * p.getQuantity();
            double discount   = subtotal * 0.10;
            double delivery   = subtotal > 0 ? 40.0 : 0;
            double grandTotal = subtotal - discount - couponDiscount + delivery;

            // Apply wallet deduction (cap to grandTotal, can't go negative)
            if (walletDeducted > grandTotal) walletDeducted = grandTotal;
            grandTotal = grandTotal - walletDeducted;
            if (grandTotal < 0) grandTotal = 0;
            System.out.println("[PlaceOrder] walletDeducted=" + walletDeducted + " grandTotal=" + grandTotal);

            // Stock check
            ProductDAO productDAO2 = new ProductDAO();
            String outOfStock = productDAO2.getOutOfStockItem(itemsToOrder);
            if (outOfStock != null) {
                writeError(out, isOnline, response, session,
                    "Sorry, insufficient stock for: " + outOfStock);
                return;
            }

            // Insert orders
            OrderDAO orderDAO    = new OrderDAO();
            int      lastOrderId = -1;
            int      groupId     = orderDAO.getNextGroupId();
            boolean  firstItem   = true;
            for (Product p : itemsToOrder) {
                double lineTotal    = p.getPrice() * p.getQuantity() * 0.90;
                double itemDelivery = firstItem ? 40.0 : 0.0;
                lastOrderId = orderDAO.placeOrder(
                    userId, p.getId(), p.getQuantity(), lineTotal,
                    name, phone, altPhone, email, address, paymentMethod, groupId, itemDelivery
                );
                firstItem = false;
            }

            if (lastOrderId < 1) {
                writeError(out, isOnline, response, session, "Order could not be saved. Please try again."); return;
            }

            session.setAttribute("orderName",    name);
            session.setAttribute("orderPhone",   phone);
            session.setAttribute("orderAddress", address);
            session.setAttribute("orderPayment", paymentMethod);
            session.setAttribute("orderTotal",   grandTotal);
            session.setAttribute("lastOrderId",  groupId > 0 ? groupId : lastOrderId);
            session.setAttribute("isBuyNow",     isBuyNow);
            session.setAttribute("pendingGroupId", groupId);
            if (isSelected) {
                session.setAttribute("isSelectedPayment",          true);
                session.setAttribute("paymentSelectedProductIds",  selProductIds);
            }

            if (isOnline) {
                session.setAttribute("pendingOrderId",    lastOrderId);
                session.setAttribute("pendingAmount",     grandTotal);
                session.setAttribute("pendingOrderTotal", grandTotal);
                // Save coupon code in session so payment success servlet can increment usage
                if (couponCode != null && !couponCode.trim().isEmpty()) {
                    session.setAttribute("pendingCouponCode", couponCode);
                }
                // Save wallet amount in session so payment success servlet can debit
                if (walletDeducted > 0) {
                    session.setAttribute("pendingWalletDeducted", walletDeducted);
                    session.setAttribute("pendingWalletOrderId",  lastOrderId);
                }
                out.write("{\"orderId\":" + lastOrderId + ",\"amount\":" + grandTotal + "}");
            } else {
                if (!isBuyNow && !isSelected) {
                    new CartDAO().clearCart(userId);
                } else if (isSelected) {
                    new CartDAO().clearSelectedItems(userId, selProductIds);
                }
                try (Connection con = DBConnection.getConnection();
                     PreparedStatement ps = con.prepareStatement(
                         "UPDATE orders SET status='Pending', payment_method='COD', payment_status='COD', " +
                         "estimated_delivery=DATE_ADD(CURDATE(), INTERVAL 5 DAY) WHERE group_id=?")) {
                    ps.setInt(1, groupId);
                    ps.executeUpdate();
                } catch (Exception ex) { ex.printStackTrace(); }
                new ProductDAO().deductStockByGroup(groupId);
                // ── Coupon: increment usage count ──────────────────────
                if (couponCode != null && !couponCode.trim().isEmpty()) {
                    new CouponDAO().incrementUsage(couponCode);
                }
                // ── Wallet: debit if used ───────────────────────────────
                if (walletDeducted > 0) {
                    new CustomerWalletDAO().debit(
                        userId, walletDeducted,
                        "Used at checkout for Order #" + lastOrderId, lastOrderId
                    );
                }
                String customerName = (user.getName() != null && !user.getName().isEmpty()) ? user.getName() : "Customer";
                new OrderStatusHistoryDAO().logByGroup(groupId, "Placed", customerName);

                // ── NOTIFICATION: Order confirmed (COD path) ──────────────
                try {
                    String productSummary = itemsToOrder.size() == 1
                        ? itemsToOrder.get(0).getName()
                        : itemsToOrder.size() + " items";
                    NotificationDAO.sendOrderPlaced(userId, lastOrderId, productSummary);
                    // Staff: new order needs review & assignment
                    NotificationDAO.sendNewCODOrderToStaff(lastOrderId, customerName);

                    // ── Email: Order confirmation + next coupon hint ──────
                    try {
                        String custEmail = user.getEmail();
                        if (custEmail != null && !custEmail.isEmpty()) {
                            // Pick first active coupon (other than the one just used)
                            String nxtCode = null, nxtDesc = null;
                            for (Map<String,Object> c : new CouponDAO().getAllCoupons()) {
                                if (Integer.parseInt(String.valueOf(c.get("is_active"))) != 1) continue;
                                String cc = (String) c.get("code");
                                if (cc.equals(couponCode)) continue;
                                nxtCode = cc;
                                nxtDesc = (String) c.get("description");
                                String dtype = (String) c.get("discount_type");
                                double dval  = Double.parseDouble(String.valueOf(c.get("discount_value")));
                                if (nxtDesc == null || nxtDesc.trim().isEmpty())
                                    nxtDesc = "PERCENT".equals(dtype) ? (int)dval+"% off your next order" : "₹"+(int)dval+" off your next order";
                                break;
                            }
                            EmailService.sendOrderConfirmationWithCoupon(
                                custEmail, customerName, lastOrderId, grandTotal,
                                paymentMethod, nxtCode, nxtDesc);
                        }
                    } catch (Exception ex) { ex.printStackTrace(); }
                } catch (Exception ex) {
                    ex.printStackTrace(); // non-fatal
                }
                // ─────────────────────────────────────────────────────────

                response.sendRedirect("order-success.jsp");
            }

        } catch (Exception e) {
            e.printStackTrace();
            String msg = e.getMessage() != null ? e.getMessage() : e.getClass().getSimpleName();
            writeError(out, isOnline, response, session, "Order Failed: " + msg);
        }
    }

    private static String jsonEscape(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"")
                .replace("\n", "\\n").replace("\r", "\\r");
    }

    private void writeError(PrintWriter out, boolean isOnline,
                            HttpServletResponse response, HttpSession session, String msg) throws IOException {
        if (isOnline) {
            out.write("{\"error\":\"" + jsonEscape(msg) + "\"}");
        } else {
            response.sendRedirect("cartCheckout.jsp?error=" + java.net.URLEncoder.encode(msg, "UTF-8"));
        }
    }
}