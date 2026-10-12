package com.sibs.controller;

import com.sibs.model.User;
import com.sibs.dao.OrderStatusHistoryDAO;
import com.sibs.dao.NotificationDAO;          // ← NEW
import com.sibs.util.DBConnection;
import com.sibs.util.EmailService;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.Arrays;
import java.util.List;

@WebServlet("/updateOrder")
public class UpdateOrderServlet extends HttpServlet {

    private static final List<String> VALID_STATUSES = Arrays.asList(
        "Approved", "Rejected", "Packed", "Assigned",
        "Picked", "Out for Delivery", "Delivered"
    );

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        User user = (session != null) ? (User) session.getAttribute("user") : null;

        if (user == null) { response.sendRedirect("login.jsp"); return; }
        if (!"ADMIN".equals(user.getRole()) && !"STAFF".equals(user.getRole())) {
            response.sendRedirect("login.jsp"); return;
        }

        String orderIdParam = request.getParameter("orderId");
        String newStatus    = request.getParameter("status");

        if (orderIdParam == null || newStatus == null || !VALID_STATUSES.contains(newStatus)) {
            response.sendRedirect("admin-orders.jsp?error=invalid"); return;
        }

        int orderId = Integer.parseInt(orderIdParam.trim());

        String currentStatus = null;
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement("SELECT status FROM orders WHERE id=?")) {
            ps.setInt(1, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) currentStatus = rs.getString("status");
            }
        } catch (Exception e) { e.printStackTrace(); }

        if (currentStatus == null) {
            response.sendRedirect("admin-orders.jsp?error=notfound"); return;
        }

        // Strict status chain — no skipping steps
        boolean validTransition = false;
        switch (currentStatus) {
            case "Pending":
                validTransition = "Approved".equals(newStatus) || "Rejected".equals(newStatus); break;
            case "Approved":
                validTransition = "Packed".equals(newStatus) || "Rejected".equals(newStatus); break;
            case "Packed":
                validTransition = "Assigned".equals(newStatus); break;
            case "Assigned":
                validTransition = "Picked".equals(newStatus) || "Out for Delivery".equals(newStatus); break;
            case "Picked":
            case "Out for Delivery":
                validTransition = "Delivered".equals(newStatus); break;
            case "Delivered": case "Rejected": case "Cancelled":
                validTransition = false; break;
            default: validTransition = false;
        }

        if (!validTransition) {
            response.sendRedirect("admin-orders.jsp?error=invalid_transition&from="
                + currentStatus + "&to=" + newStatus);
            return;
        }

        // Update ETA on each status change
        int etaDays;
        switch (newStatus) {
            case "Approved":         etaDays = 4; break;
            case "Packed":           etaDays = 3; break;
            case "Assigned":         etaDays = 2; break;
            case "Out for Delivery": etaDays = 1; break;
            case "Delivered":        etaDays = 0; break;
            default:                 etaDays = -1;
        }

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(
                     etaDays >= 0
                     ? "UPDATE orders SET status=?, estimated_delivery=DATE_ADD(CURDATE(), INTERVAL ? DAY) WHERE id=?"
                     : "UPDATE orders SET status=? WHERE id=?")) {
            ps.setString(1, newStatus);
            if (etaDays >= 0) { ps.setInt(2, etaDays); ps.setInt(3, orderId); }
            else              { ps.setInt(2, orderId); }
            ps.executeUpdate();
        } catch (Exception e) { e.printStackTrace(); }

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement("SELECT group_id FROM orders WHERE id=?")) {
            ps.setInt(1, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    int groupId = rs.getInt("group_id");
                    String changedBy = user.getName() != null ? user.getName() : user.getRole();
                    new OrderStatusHistoryDAO().logByGroup(groupId, newStatus, changedBy);
                }
            }
        } catch (Exception e) { e.printStackTrace(); }

        if ("Packed".equals(newStatus)) {
            try (Connection con = DBConnection.getConnection();
                 PreparedStatement ps = con.prepareStatement(
                         "SELECT product_id, quantity FROM orders WHERE id=?")) {
                ps.setInt(1, orderId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        int productId = rs.getInt("product_id");
                        int qty       = rs.getInt("quantity");
                        try (PreparedStatement upd = con.prepareStatement(
                                "UPDATE products SET quantity = quantity - ? WHERE id=? AND quantity >= ?")) {
                            upd.setInt(1, qty); upd.setInt(2, productId); upd.setInt(3, qty);
                            upd.executeUpdate();
                        }
                    }
                }
            } catch (Exception e) { e.printStackTrace(); }
        }

        // Fetch customer details for email + in-app notification
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(
                     "SELECT o.id, o.user_id, o.name, o.email, p.name AS product_name " +
                     "FROM orders o JOIN products p ON o.product_id = p.id WHERE o.id=?")) {
            ps.setInt(1, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    final String customerName  = rs.getString("name");
                    final String customerEmail = rs.getString("email");
                    final String productName   = rs.getString("product_name");
                    final int    finalOrderId  = rs.getInt("id");
                    final int    customerId    = rs.getInt("user_id");   // ← needed for notification
                    final String finalStatus   = newStatus;

                    // Email (existing behaviour — keep on background thread)
                    new Thread(() ->
                        EmailService.sendOrderStatusEmail(
                            customerEmail, customerName, finalStatus, finalOrderId, productName)
                    ).start();

                    // ── NOTIFICATION: In-app status update ───────────────
                    try {
                        NotificationDAO.sendOrderStatusChanged(customerId, finalOrderId, productName, finalStatus);
                    } catch (Exception ex) {
                        ex.printStackTrace(); // non-fatal
                    }
                    // ─────────────────────────────────────────────────────
                }
            }
        } catch (Exception e) { e.printStackTrace(); }

        String referer = request.getHeader("Referer");
        if (referer != null && referer.contains("staff")) {
            response.sendRedirect("staff-orders.jsp");
        } else {
            response.sendRedirect("admin-orders.jsp");
        }
    }
}