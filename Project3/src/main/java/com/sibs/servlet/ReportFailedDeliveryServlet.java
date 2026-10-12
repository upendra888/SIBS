package com.sibs.servlet;

import com.sibs.dao.NotificationDAO;
import com.sibs.dao.OrderStatusHistoryDAO;
import com.sibs.model.DeliveryBoy;
import com.sibs.util.DBConnection;
import com.sibs.util.EmailService;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.sql.*;

/**
 * ReportFailedDeliveryServlet
 *
 * Called from delivery-dashboard.jsp when a delivery boy cannot
 * complete a delivery because the customer is not responding.
 *
 * POST params:
 *   assignmentId — delivery_assignments.id
 *   orderId      — orders.id
 *   note         — optional note from delivery boy
 *
 * Effect:
 *   - Sets orders.status = 'Customer_Not_Responding'
 *   - Logs status history
 *   - Sends email to customer
 *   - Records attempt count in delivery_assignments
 */
@WebServlet("/reportFailedDelivery")
public class ReportFailedDeliveryServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res) throws IOException {

        // Auth — must be delivery boy
        HttpSession session = req.getSession(false);
        DeliveryBoy db = session != null ? (DeliveryBoy) session.getAttribute("deliveryBoy") : null;
        if (db == null) {
            res.sendRedirect("delivery-login.jsp");
            return;
        }

        String assignmentIdStr = req.getParameter("assignmentId");
        String orderIdStr      = req.getParameter("orderId");
        String note            = req.getParameter("note");

        if (assignmentIdStr == null || orderIdStr == null) {
            res.sendRedirect("delivery-dashboard.jsp?error=missing_params");
            return;
        }

        int assignmentId = Integer.parseInt(assignmentIdStr.trim());
        int orderId      = Integer.parseInt(orderIdStr.trim());
        if (note == null) note = "";

        try (Connection con = DBConnection.getConnection()) {

            // 1. Increment attempt count in delivery_assignments
            String updateAttempt =
                "UPDATE delivery_assignments " +
                "SET failed_attempts = COALESCE(failed_attempts, 0) + 1, " +
                "    delivery_note   = ? " +
                "WHERE id = ?";
            try (PreparedStatement ps = con.prepareStatement(updateAttempt)) {
                ps.setString(1, note.trim().isEmpty() ? "Customer not responding" : note.trim());
                ps.setInt(2, assignmentId);
                ps.executeUpdate();
            }

            // 2. Set order status
            String updateOrder = "UPDATE orders SET status = 'Customer_Not_Responding' WHERE id = ?";
            try (PreparedStatement ps = con.prepareStatement(updateOrder)) {
                ps.setInt(1, orderId);
                ps.executeUpdate();
            }

            // 3. Log status history
            int groupId = -1;
            try (PreparedStatement ps = con.prepareStatement("SELECT group_id FROM orders WHERE id=?")) {
                ps.setInt(1, orderId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) groupId = rs.getInt("group_id");
                }
            }
            if (groupId > 0) {
                new OrderStatusHistoryDAO().logByGroup(
                    groupId,
                    "Customer Not Responding",
                    db.getName() != null ? db.getName() : "Delivery Boy"
                );
            }

            // 4. Email + Notification to customer
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT o.id, o.name, o.email, o.user_id, p.name AS product_name " +
                    "FROM orders o JOIN products p ON o.product_id = p.id " +
                    "WHERE o.id = ? LIMIT 1")) {
                ps.setInt(1, orderId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        final String custEmail   = rs.getString("email");
                        final String custName    = rs.getString("name");
                        final String productName = rs.getString("product_name");
                        final int    finalId     = rs.getInt("id");
                        final int    custUserId  = rs.getInt("user_id");
                        new Thread(() ->
                            EmailService.sendOrderStatusEmail(
                                custEmail, custName,
                                "Customer Not Responding - Please reschedule your delivery",
                                finalId, productName)
                        ).start();
                        if (custUserId > 0) {
                            NotificationDAO.sendDeliveryFailed(custUserId, finalId, productName,
                                "Customer not responding");
                        }
                        // Notify delivery boy: delivery failed
                        NotificationDAO.sendDeliveryFailedToDeliveryBoy(db.getId(), finalId,
                            productName, "Customer not responding");
                    }
                }
            }

        } catch (Exception e) {
            e.printStackTrace();
            res.sendRedirect("delivery-dashboard.jsp?error=report_failed");
            return;
        }

        res.sendRedirect("delivery-dashboard.jsp?failed_delivery=reported");
    }
}