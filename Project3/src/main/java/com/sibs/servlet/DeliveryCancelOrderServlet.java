package com.sibs.servlet;

import com.sibs.dao.NotificationDAO;
import com.sibs.dao.OrderStatusHistoryDAO;
import com.sibs.dao.ProductDAO;
import com.sibs.model.DeliveryBoy;
import com.sibs.util.DBConnection;
import com.sibs.util.EmailService;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.sql.*;

/**
 * DeliveryCancelOrderServlet
 *
 * Called from delivery-dashboard.jsp when a delivery boy needs to cancel an
 * order AFTER pickup has been confirmed — e.g. wrong address, customer
 * completely unreachable at doorstep, customer refused delivery, etc.
 *
 * This is different from:
 *   - cancelRide  → before pickup, just re-assigns to staff
 *   - reportFailedDelivery → flags order as "Customer Not Responding" (no cancel)
 *
 * POST params:
 *   assignmentId — delivery_assignments.id
 *   orderId      — orders.id
 *   reason       — reason chosen by delivery boy (mandatory)
 *   note         — optional free-text note
 *
 * Effect:
 *   - Validates assignment is in PICKED_UP state
 *   - Sets orders.status = 'Cancelled'
 *   - Sets delivery_assignments.status = 'CANCELLED'
 *   - Records cancel reason + note in delivery_assignments.delivery_note
 *   - Restores product stock
 *   - Logs status history
 *   - Emails customer about cancellation
 */
@WebServlet("/deliveryCancelOrder")
public class DeliveryCancelOrderServlet extends HttpServlet {

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
        String reason          = req.getParameter("reason");
        String note            = req.getParameter("note");

        if (assignmentIdStr == null || orderIdStr == null || reason == null || reason.trim().isEmpty()) {
            res.sendRedirect("delivery-dashboard.jsp?error=missing_params");
            return;
        }

        int assignmentId = Integer.parseInt(assignmentIdStr.trim());
        int orderId      = Integer.parseInt(orderIdStr.trim());
        reason = reason.trim();
        if (note == null) note = "";
        String fullNote = reason + (note.trim().isEmpty() ? "" : " — " + note.trim());

        try (Connection con = DBConnection.getConnection()) {

            // 1. Guard: only allow cancel if assignment is PICKED_UP
            String checkSql = "SELECT status FROM delivery_assignments WHERE id = ?";
            String assignStatus = null;
            try (PreparedStatement ps = con.prepareStatement(checkSql)) {
                ps.setInt(1, assignmentId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) assignStatus = rs.getString("status");
                }
            }
            // Allow cancel in PICKED_UP or OTP_VERIFIED states (both mean delivery is in progress)
            boolean cancellable = assignStatus != null &&
                (assignStatus.equalsIgnoreCase("PICKED_UP") ||
                 assignStatus.equalsIgnoreCase("OTP_VERIFIED"));
            if (!cancellable) {
                res.sendRedirect("delivery-dashboard.jsp?error=cannot_cancel_now");
                return;
            }

            // 2. Cancel the delivery assignment
            try (PreparedStatement ps = con.prepareStatement(
                    "UPDATE delivery_assignments SET status='CANCELLED', delivery_note=? WHERE id=?")) {
                ps.setString(1, fullNote);
                ps.setInt(2, assignmentId);
                ps.executeUpdate();
            }

            // 3. Cancel the order
            try (PreparedStatement ps = con.prepareStatement(
                    "UPDATE orders SET status='Cancelled' WHERE id=?")) {
                ps.setInt(1, orderId);
                ps.executeUpdate();
            }

            // 4. Restore product stock
            int groupId = 0;
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT group_id FROM orders WHERE id=?")) {
                ps.setInt(1, orderId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        groupId = rs.getInt("group_id");
                        new ProductDAO().restoreStockByGroup(groupId);

                        // 5. Log status history
                        new OrderStatusHistoryDAO().logByGroup(
                            groupId,
                            "Cancelled",
                            db.getName() != null ? db.getName() : "Delivery Boy"
                        );
                    }
                }
            }

            // 6. Email customer + notify staff to reassign
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT o.id, o.name, o.email, p.name AS product_name " +
                    "FROM orders o JOIN products p ON o.product_id = p.id " +
                    "WHERE o.id = ? LIMIT 1")) {
                ps.setInt(1, orderId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        final String custEmail   = rs.getString("email");
                        final String custName    = rs.getString("name");
                        final String productName = rs.getString("product_name");
                        final int    finalId     = rs.getInt("id");
                        final String finalReason = reason;
                        new Thread(() ->
                            EmailService.sendOrderStatusEmail(
                                custEmail, custName,
                                "Cancelled — Reason: " + finalReason,
                                finalId, productName)
                        ).start();
                        // Notify delivery boy: order cancelled confirmed
                        NotificationDAO.sendAssignedOrderCancelled(db.getId(), finalId, productName);
                        // Notify all staff: ride cancelled, reassignment needed
                        NotificationDAO.sendRideCancelledByDeliveryBoy(groupId, finalId);
                    }
                }
            }

        } catch (Exception e) {
            e.printStackTrace();
            res.sendRedirect("delivery-dashboard.jsp?error=delivery_cancel_failed");
            return;
        }

        res.sendRedirect("delivery-dashboard.jsp?delivery_cancelled=1");
    }
}