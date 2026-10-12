package com.sibs.servlet;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import com.sibs.dao.OrderDAO;
import com.sibs.dao.PaymentDAO;
import com.sibs.dao.ProductDAO;
import com.sibs.dao.OrderStatusHistoryDAO;
import com.sibs.model.Payment;
import com.sibs.model.User;
import com.sibs.util.DBConnection;
import com.sibs.dao.NotificationDAO;
import com.sibs.util.EmailService;
import com.sibs.util.RazorpayConfig;

import java.io.IOException;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.Base64;
import java.util.Scanner;

@WebServlet("/cancelOrder")
public class CancelOrderServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        doGet(request, response);
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        User user = null;
        boolean isStaff = false;

        // Determine source page for redirect (source param takes priority, then Referer)
        String source = request.getParameter("source");
        if (source == null || source.isEmpty()) {
            String referer = request.getHeader("Referer");
            if (referer != null && referer.contains("staff-orders")) source = "staff";
            else source = "customer";
        }
        final boolean redirectToStaff = "staff".equals(source);

        if (session != null) {
            user = (User) session.getAttribute("customer");
            if (user == null) {
                User staffUser = (User) session.getAttribute("user");
                if (staffUser != null &&
                    ("STAFF".equals(staffUser.getRole()) || "ADMIN".equals(staffUser.getRole()))) {
                    user = staffUser;
                    isStaff = true;
                }
            }
        }

        if (user == null) {
            response.sendRedirect("customer-login.jsp");
            return;
        }

        String idStr = request.getParameter("id");
        String cancelReason = request.getParameter("reason");
        if (cancelReason == null || cancelReason.trim().isEmpty()) {
            cancelReason = "No reason provided";
        }
        cancelReason = cancelReason.trim();

        if (idStr == null || idStr.trim().isEmpty()) {
            response.sendRedirect("my-orders.jsp?error=invalid");
            return;
        }

        try {
            int groupId = Integer.parseInt(idStr.trim());

            String statusSql = isStaff
                ? "SELECT status, payment_method FROM orders WHERE group_id=? LIMIT 1"
                : "SELECT status, payment_method FROM orders WHERE group_id=? AND user_id=? LIMIT 1";
            String currentStatus         = null;
            final String[] paymentMethod = {null};

            try (Connection con = DBConnection.getConnection();
                 PreparedStatement ps = con.prepareStatement(statusSql)) {
                ps.setInt(1, groupId);
                if (!isStaff) ps.setInt(2, user.getId());
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        currentStatus    = rs.getString("status");
                        paymentMethod[0] = rs.getString("payment_method");
                    }
                }
            }

            if (currentStatus == null) {
                response.sendRedirect(redirectToStaff ? "staff-orders.jsp?error=not_found" : "my-orders.jsp?error=not_found");
                return;
            }

            boolean cancellable = "Pending".equalsIgnoreCase(currentStatus)
                               || "Approved".equalsIgnoreCase(currentStatus)
                               || "Packed".equalsIgnoreCase(currentStatus);

            if (!cancellable) {
                response.sendRedirect(redirectToStaff ? "staff-orders.jsp?error=cannot_cancel&status=" + currentStatus : "my-orders.jsp?error=cannot_cancel&status=" + currentStatus);
                return;
            }

            new ProductDAO().restoreStockByGroup(groupId);

            String cancelledBy = (user.getName() != null && !user.getName().isEmpty())
                                 ? user.getName() : "Customer";
            new OrderStatusHistoryDAO().logByGroup(groupId, "Cancelled", cancelledBy);

            new OrderDAO().cancelOrdersByGroupWithReason(groupId, cancelReason);

            // FIX: covers ONLINE, Razorpay, UPI, Card
            boolean isOnline = paymentMethod[0] != null && (
                "ONLINE".equalsIgnoreCase(paymentMethod[0])   ||
                "Razorpay".equalsIgnoreCase(paymentMethod[0]) ||
                "UPI".equalsIgnoreCase(paymentMethod[0])      ||
                "Card".equalsIgnoreCase(paymentMethod[0]));

            String refundId     = null;
            double refundAmount = 0;

            if (isOnline) {
                Payment payment = new PaymentDAO().getPaymentByGroupId(groupId);
                if (payment != null && "SUCCESS".equalsIgnoreCase(payment.getStatus())) {
                    refundAmount = payment.getAmount();
                    refundId = triggerRazorpayRefund(
                        payment.getRazorpayPaymentId(), payment.getAmount());
                    if (refundId != null) {
                        new PaymentDAO().markRefunded(payment.getPaymentId(), refundId);
                    }
                }
            }

            String custEmail   = null;
            String custName    = null;
            String productName = null;
            int    firstId     = 0;
            int    custUserId  = 0;

            try (Connection con = DBConnection.getConnection();
                 PreparedStatement ps = con.prepareStatement(
                     "SELECT o.id, o.user_id, o.name, o.email, p.name AS product_name " +
                     "FROM orders o JOIN products p ON o.product_id = p.id " +
                     "WHERE o.group_id=? LIMIT 1")) {
                ps.setInt(1, groupId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        custEmail   = rs.getString("email");
                        custName    = rs.getString("name");
                        productName = rs.getString("product_name");
                        firstId     = rs.getInt("id");
                        custUserId  = rs.getInt("user_id");
                    }
                }
            } catch (Exception ignored) {}

            if (custUserId > 0) {
                NotificationDAO.sendOrderStatusChanged(custUserId, firstId, productName != null ? productName : "your order", "Cancelled");
            }

            // Notify staff: customer cancelled an order
            if (!redirectToStaff) {  // only when customer cancels, not staff themselves
                String _cn = (custName != null && !custName.isEmpty()) ? custName : "Customer";
                NotificationDAO.sendOrderCancelledToStaff(firstId, groupId, _cn);
            }

            // Notify assigned delivery boy (if any) that their order was cancelled
            try (Connection con2 = DBConnection.getConnection();
                 PreparedStatement ps2 = con2.prepareStatement(
                     "SELECT da.delivery_boy_id FROM delivery_assignments da " +
                     "JOIN orders o ON da.order_id = o.id " +
                     "WHERE o.group_id=? AND da.status NOT IN ('DELIVERED','CANCELLED') LIMIT 1")) {
                ps2.setInt(1, groupId);
                try (java.sql.ResultSet rs2 = ps2.executeQuery()) {
                    if (rs2.next()) {
                        int assignedDbId = rs2.getInt("delivery_boy_id");
                        NotificationDAO.sendAssignedOrderCancelled(assignedDbId, firstId,
                            productName != null ? productName : "your order");
                    }
                }
            } catch (Exception ignored) {}
            if (custEmail != null) {
                final String  finalEmail    = custEmail;
                final String  finalName     = custName;
                final String  finalProduct  = productName;
                final int     finalId       = firstId;
                final boolean finalIsOnline = isOnline;
                final String  finalRefundId = refundId;
                final double  finalAmount   = refundAmount;

                new Thread(() -> {
                    EmailService.sendOrderStatusEmail(
                        finalEmail, finalName, "Cancelled", finalId, finalProduct);
                    if (finalIsOnline && finalRefundId != null) {
                        EmailService.sendRefundEmail(
                            finalEmail, finalName, finalId, finalAmount, finalRefundId);
                    }
                }).start();
            }

            final String finalPaymentMethod = paymentMethod[0];
            final String finalCancelledBy   = cancelledBy;
            new Thread(() -> {
                try {
                    EmailService.sendAdminCancelNotification(
                        groupId, finalCancelledBy, finalPaymentMethod);
                } catch (Exception ignored) {}
            }).start();

            if (redirectToStaff) {
                response.sendRedirect("staff-orders.jsp?cancelled=1");
            } else {
                response.sendRedirect("my-orders.jsp?cancelled=1");
            }

        } catch (Exception e) {
            e.printStackTrace();
            if (redirectToStaff) {
                response.sendRedirect("staff-orders.jsp?error=cancel_failed");
            } else {
                response.sendRedirect("my-orders.jsp?error=cancel_failed");
            }
        }
    }

    private String triggerRazorpayRefund(String razorpayPaymentId, double amount) {
        try {
            long amountInPaise = Math.round(amount * 100);
            String refundUrl   = "https://api.razorpay.com/v1/payments/" + razorpayPaymentId + "/refund";
            String jsonBody    = "{\"amount\":" + amountInPaise + "}";

            URL url = new URL(refundUrl);
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("POST");
            conn.setDoOutput(true);
            conn.setRequestProperty("Content-Type", "application/json");
            String auth = RazorpayConfig.basicAuth(getServletContext());
            if (auth == null) {
                System.err.println("[CancelOrder] Razorpay not configured — refund skipped");
                return null;
            }
            conn.setRequestProperty("Authorization", "Basic " + auth);

            try (OutputStream os = conn.getOutputStream()) {
                os.write(jsonBody.getBytes(StandardCharsets.UTF_8));
            }

            int responseCode = conn.getResponseCode();
            Scanner scanner  = responseCode >= 200 && responseCode < 300
                ? new Scanner(conn.getInputStream(), "UTF-8")
                : new Scanner(conn.getErrorStream(), "UTF-8");

            StringBuilder sb = new StringBuilder();
            while (scanner.hasNext()) sb.append(scanner.nextLine());
            scanner.close();

            if (responseCode == 200) {
                String json   = sb.toString();
                String search = "\"id\":\"";
                int start     = json.indexOf(search);
                if (start != -1) {
                    start += search.length();
                    int end = json.indexOf("\"", start);
                    return json.substring(start, end);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }
}