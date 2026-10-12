package com.sibs.servlet;

import com.sibs.dao.NotificationDAO;
import com.sibs.dao.OrderDAO;
import com.sibs.dao.ReturnDAO;
import com.sibs.model.Order;
import com.sibs.model.ReturnRequest;
import com.sibs.model.User;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.util.List;

@WebServlet("/ReturnProductServlet")
public class ReturnProductServlet extends HttpServlet {

    private final OrderDAO  orderDAO  = new OrderDAO();
    private final ReturnDAO returnDAO = new ReturnDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        User user = (session != null) ? (User) session.getAttribute("customer") : null;

        System.out.println("[ReturnServlet] user=" + user);

        if (user == null) {
            System.out.println("[ReturnServlet] ERROR: user is null, redirecting to login");
            resp.sendRedirect(req.getContextPath() + "/customer-login.jsp");
            return;
        }

        String orderIdParam = req.getParameter("orderId");
        System.out.println("[ReturnServlet] orderId param=" + orderIdParam);

        if (orderIdParam == null || orderIdParam.isEmpty()) {
            resp.sendRedirect(req.getContextPath() + "/my-orders.jsp?error=no_order_id");
            return;
        }

        int orderId = Integer.parseInt(orderIdParam);
        List<Order> userOrders = orderDAO.getOrdersByUser(user.getId());

        System.out.println("[ReturnServlet] total orders for user: " + userOrders.size());
        for (Order o : userOrders) {
            System.out.println("[ReturnServlet]   order id=" + o.getId() + " status=" + o.getStatus());
        }

        Order order = userOrders.stream()
                .filter(o -> o.getId() == orderId)
                .findFirst().orElse(null);

        System.out.println("[ReturnServlet] matched order=" + order);

        if (order == null) {
            System.out.println("[ReturnServlet] ERROR: order not found for orderId=" + orderId);
            resp.sendRedirect(req.getContextPath() + "/my-orders.jsp?error=order_not_found");
            return;
        }

        System.out.println("[ReturnServlet] order status=" + order.getStatus());

        if (!"Delivered".equalsIgnoreCase(order.getStatus())) {
            System.out.println("[ReturnServlet] ERROR: order not delivered, status=" + order.getStatus());
            resp.sendRedirect(req.getContextPath() + "/my-orders.jsp?error=not_delivered");
            return;
        }

        boolean exists = returnDAO.returnExists(orderId);
        System.out.println("[ReturnServlet] returnExists=" + exists);

        if (exists) {
            resp.sendRedirect(req.getContextPath() + "/my-orders.jsp?error=return_exists");
            return;
        }

        System.out.println("[ReturnServlet] All checks passed, forwarding to return-form.jsp");

        // Fix: populate productId, productName, productImage, quantity from items if header is missing them
        // Use getOrdersByGroupId for a clean item list (avoids JOIN multiplication from delivery_assignments)
        List<Order> groupItems = orderDAO.getOrdersByGroupId(order.getGroupId());
        if (!groupItems.isEmpty()) {
            order.setItems(groupItems);
        }

        if ((order.getProductName() == null || order.getProductName().isEmpty()) && !order.getItems().isEmpty()) {
            Order firstItem = order.getItems().get(0);
            order.setProductName(firstItem.getProductName());
            order.setProductImage(firstItem.getProductImage());
            order.setProductId(firstItem.getProductId());
            order.setQuantity(firstItem.getQuantity());
        }

        req.setAttribute("order", order);
        req.getRequestDispatcher("/return-form.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        User user = (session != null) ? (User) session.getAttribute("customer") : null;
        if (user == null) { resp.sendRedirect(req.getContextPath() + "/customer-login.jsp"); return; }

        int orderId;
        int groupId;
        try {
            orderId = Integer.parseInt(req.getParameter("orderId"));
            groupId = Integer.parseInt(req.getParameter("groupId"));
        } catch (NumberFormatException e) {
            resp.sendRedirect(req.getContextPath() + "/my-orders.jsp?error=invalid");
            return;
        }

        Order owned = orderDAO.getOrdersByUser(user.getId()).stream()
                .filter(o -> o.getId() == orderId)
                .findFirst().orElse(null);
        if (owned == null || !"Delivered".equalsIgnoreCase(owned.getStatus())) {
            resp.sendRedirect(req.getContextPath() + "/my-orders.jsp?error=order_not_found");
            return;
        }

        double orderTotal = owned.getTotal();
        String reason = req.getParameter("reason");
        String description = req.getParameter("description");
        String paymentMethod = req.getParameter("paymentMethod");
        if (paymentMethod == null || paymentMethod.isBlank()) {
            paymentMethod = owned.getPaymentMethod();
        }

        // Use productId from form (customer selected specific item),
        // fallback to first item in group if not provided
        int productId = 0;
        String selectedPidParam = req.getParameter("productId");
        if (selectedPidParam != null && !selectedPidParam.trim().isEmpty()) {
            try { productId = Integer.parseInt(selectedPidParam.trim()); } catch (Exception ignored) {}
        }
        // Validate that this productId actually belongs to this group
        if (productId > 0) {
            try (java.sql.Connection conn = com.sibs.util.DBConnection.getConnection();
                 java.sql.PreparedStatement ps2 = conn.prepareStatement(
                     "SELECT id FROM orders WHERE group_id = ? AND product_id = ? LIMIT 1")) {
                ps2.setInt(1, groupId);
                ps2.setInt(2, productId);
                java.sql.ResultSet rs2 = ps2.executeQuery();
                if (!rs2.next()) { productId = 0; } // invalid — reset
            } catch (Exception e) {
                System.out.println("[ReturnServlet POST] ERROR validating productId: " + e.getMessage());
            }
        }
        // Fallback: first item in group
        if (productId == 0) {
            try (java.sql.Connection conn = com.sibs.util.DBConnection.getConnection();
                 java.sql.PreparedStatement ps2 = conn.prepareStatement(
                     "SELECT product_id FROM orders WHERE group_id = ? ORDER BY id ASC LIMIT 1")) {
                ps2.setInt(1, groupId);
                java.sql.ResultSet rs2 = ps2.executeQuery();
                if (rs2.next()) productId = rs2.getInt("product_id");
            } catch (Exception e) {
                System.out.println("[ReturnServlet POST] ERROR fetching productId fallback: " + e.getMessage());
            }
        }
        System.out.println("[ReturnServlet POST] final productId=" + productId);

        // Get the exact total for this specific item (not the whole group total)
        double itemTotal = orderTotal; // default to full total
        if (productId > 0) {
            try (java.sql.Connection conn = com.sibs.util.DBConnection.getConnection();
                 java.sql.PreparedStatement psT = conn.prepareStatement(
                     "SELECT total FROM orders WHERE group_id = ? AND product_id = ? LIMIT 1")) {
                psT.setInt(1, groupId);
                psT.setInt(2, productId);
                java.sql.ResultSet rsT = psT.executeQuery();
                if (rsT.next()) itemTotal = rsT.getDouble("total");
            } catch (Exception e) {
                System.out.println("[ReturnServlet POST] ERROR fetching item total: " + e.getMessage());
            }
        }
        System.out.println("[ReturnServlet POST] itemTotal=" + itemTotal);

        // Check duplicate by groupId (more reliable than orderId for grouped orders)
        try (java.sql.Connection conn = com.sibs.util.DBConnection.getConnection();
             java.sql.PreparedStatement ps3 = conn.prepareStatement(
                 "SELECT COUNT(*) FROM return_requests WHERE group_id = ?")) {
            ps3.setInt(1, groupId);
            java.sql.ResultSet rs3 = ps3.executeQuery();
            if (rs3.next() && rs3.getInt(1) > 0) {
                System.out.println("[ReturnServlet POST] Duplicate return for groupId=" + groupId);
                resp.sendRedirect(req.getContextPath() + "/my-orders.jsp?error=return_exists");
                return;
            }
        } catch (Exception e) {
            System.out.println("[ReturnServlet POST] ERROR checking duplicate: " + e.getMessage());
        }

        // ── Return window enforcement: block returns after 14 days of delivery ──
        try (java.sql.Connection conn14 = com.sibs.util.DBConnection.getConnection();
             java.sql.PreparedStatement ps14 = conn14.prepareStatement(
                 "SELECT MAX(changed_at) AS delivered_at FROM order_status_history " +
                 "WHERE group_id = ? AND UPPER(status) = 'DELIVERED'")) {
            ps14.setInt(1, groupId);
            java.sql.ResultSet rs14 = ps14.executeQuery();
            if (rs14.next() && rs14.getTimestamp("delivered_at") != null) {
                long deliveredMs = rs14.getTimestamp("delivered_at").getTime();
                long daysSince   = (System.currentTimeMillis() - deliveredMs) / (1000L * 60 * 60 * 24);
                if (daysSince > 14) {
                    resp.sendRedirect(req.getContextPath() + "/my-orders.jsp?return_error=window_expired");
                    return;
                }
            }
        } catch (Exception e) {
            System.out.println("[ReturnServlet POST] ERROR checking return window: " + e.getMessage());
        }

        // Determine refund method from actual payment record (more reliable than form field)
        String actualPaymentMethod = paymentMethod;
        try (java.sql.Connection conn = com.sibs.util.DBConnection.getConnection();
             java.sql.PreparedStatement ps2 = conn.prepareStatement(
                 "SELECT payment_method, razorpay_payment_id FROM payments WHERE order_id IN " +
                 "(SELECT id FROM orders WHERE group_id = ?) LIMIT 1")) {
            ps2.setInt(1, groupId);
            java.sql.ResultSet rs2 = ps2.executeQuery();
            if (rs2.next()) {
                actualPaymentMethod = rs2.getString("payment_method");
            }
        } catch (Exception e) {
            System.out.println("[ReturnServlet POST] Could not read payment method from payments table: " + e.getMessage());
        }
        String refundMethod = "COD".equalsIgnoreCase(actualPaymentMethod) ? "WALLET" : "ORIGINAL_PAYMENT";

        // Insert return request directly — bypasses any column mismatch in ReturnDAO
        int newId = -1;
        try (java.sql.Connection conn = com.sibs.util.DBConnection.getConnection()) {

            String sql = "INSERT INTO return_requests " +
                         "(order_id, group_id, user_id, product_id, reason, description, " +
                         " refund_amount, refund_method, status) " +
                         "VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'PENDING')";
            try (java.sql.PreparedStatement ps = conn.prepareStatement(sql, java.sql.Statement.RETURN_GENERATED_KEYS)) {
                ps.setInt   (1, orderId);
                ps.setInt   (2, groupId);
                ps.setInt   (3, user.getId());
                ps.setInt   (4, productId);
                ps.setString(5, reason);
                ps.setString(6, description);
                ps.setDouble(7, itemTotal);
                ps.setString(8, refundMethod);
                ps.executeUpdate();

                // Update orders.return_status
                try (java.sql.PreparedStatement upd = conn.prepareStatement(
                        "UPDATE orders SET return_status='PENDING' WHERE group_id=?")) {
                    upd.setInt(1, groupId);
                    upd.executeUpdate();
                }

                java.sql.ResultSet keys = ps.getGeneratedKeys();
                if (keys.next()) newId = keys.getInt(1);
                System.out.println("[ReturnServlet POST] Insert success, newId=" + newId);
            }
        } catch (Exception e) {
            e.printStackTrace();
            resp.sendRedirect(req.getContextPath() + "/my-orders.jsp?error=return_failed");
            return;
        }

        if (newId > 0) {
            // Notify all staff: new return request needs review
            try (java.sql.Connection conn = com.sibs.util.DBConnection.getConnection();
                 java.sql.PreparedStatement ps = conn.prepareStatement(
                     "SELECT name FROM products WHERE id = ?")) {
                ps.setInt(1, productId);
                java.sql.ResultSet rs = ps.executeQuery();
                String productName = rs.next() ? rs.getString("name") : "Unknown Product";
                NotificationDAO.sendNewReturnToStaff(newId, user.getName(), productName);
            } catch (Exception ex) {
                System.out.println("[ReturnServlet POST] WARN: staff notification failed: " + ex.getMessage());
            }
            resp.sendRedirect(req.getContextPath() + "/my-orders.jsp?return_success=1");
        } else {
            resp.sendRedirect(req.getContextPath() + "/my-orders.jsp?error=return_failed");
        }
    }
}