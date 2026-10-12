package com.sibs.servlet;

import com.sibs.dao.DeliveryBoyDAO;
import com.sibs.dao.NotificationDAO;
import com.sibs.dao.OrderStatusHistoryDAO;
import com.sibs.dao.ProductDAO;
import com.sibs.model.User;
import com.sibs.util.DBConnection;
import com.sibs.util.EmailService;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.sql.*;

/**
 * StaffNoResponseActionServlet
 *
 * Called from staff-cancelled-orders.jsp "Customer Not Responding" section.
 *
 * Staff first calls the customer, then takes one of two actions:
 *
 *   action = "reattempt"
 *       → Staff confirmed customer is available. Reassign delivery boy,
 *         update order status to Assigned, notify delivery boy.
 *
 *   action = "cancel"
 *       → Customer still unreachable or refused. Cancel order,
 *         restore stock, notify delivery boy + customer.
 *
 * POST params (both actions):
 *   groupId        — orders.group_id
 *   action         — "reattempt" | "cancel"
 *   staffNote      — optional note from staff
 *
 * Additional params for reattempt:
 *   deliveryBoyId  — delivery_boys.id to assign
 *   newAddress     — updated delivery address
 *
 * Additional params for cancel:
 *   cancelReason   — reason shown to customer
 */
@WebServlet("/staffNoResponseAction")
public class StaffNoResponseActionServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res) throws IOException {

        // ── Auth ──────────────────────────────────────────────────────
        HttpSession session = req.getSession(false);
        User user = session != null ? (User) session.getAttribute("user") : null;
        if (user == null || (!"STAFF".equals(user.getRole()) && !"ADMIN".equals(user.getRole()))) {
            res.sendRedirect("login.jsp");
            return;
        }

        String action     = req.getParameter("action");
        String groupIdStr = req.getParameter("groupId");
        String staffNote  = req.getParameter("staffNote");
        if (staffNote == null) staffNote = "";

        if (groupIdStr == null || action == null) {
            res.sendRedirect("staff-cancelled-orders.jsp?error=missing_params");
            return;
        }

        int groupId = Integer.parseInt(groupIdStr.trim());
        String staffName = user.getName() != null ? user.getName() : user.getRole();

        try (Connection con = DBConnection.getConnection()) {

            // ── Fetch first order in group (for IDs, customer info) ───
            int    firstOrderId  = -1;
            int    customerId    = -1;
            String customerName  = "Customer";
            String customerEmail = null;
            String productName   = "your order";
            int    deliveryBoyDbId = -1; // current assigned delivery boy DB id

            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT o.id, o.user_id, o.name, o.email, p.name AS product_name " +
                    "FROM orders o LEFT JOIN products p ON o.product_id = p.id " +
                    "WHERE o.group_id = ? ORDER BY o.id ASC LIMIT 1")) {
                ps.setInt(1, groupId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        firstOrderId  = rs.getInt("id");
                        customerId    = rs.getInt("user_id");
                        customerName  = rs.getString("name") != null ? rs.getString("name") : "Customer";
                        customerEmail = rs.getString("email");
                        productName   = rs.getString("product_name") != null ? rs.getString("product_name") : "your order";
                    }
                }
            }

            if (firstOrderId == -1) {
                res.sendRedirect("staff-cancelled-orders.jsp?error=order_not_found");
                return;
            }

            // ── Get current delivery boy ID from delivery_assignments ─
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT delivery_boy_id FROM delivery_assignments " +
                    "WHERE order_id = ? ORDER BY id DESC LIMIT 1")) {
                ps.setInt(1, firstOrderId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) deliveryBoyDbId = rs.getInt("delivery_boy_id");
                }
            }

            // ═══════════════════════════════════════════════════════════
            if ("reattempt".equals(action)) {
            // ═══════════════════════════════════════════════════════════

                String newAddress     = req.getParameter("newAddress");
                String deliveryBoyStr = req.getParameter("deliveryBoyId");

                if (newAddress == null || newAddress.trim().isEmpty()
                        || deliveryBoyStr == null || deliveryBoyStr.trim().isEmpty()) {
                    res.sendRedirect("staff-cancelled-orders.jsp?error=reattempt_missing_fields");
                    return;
                }

                int newDeliveryBoyId = Integer.parseInt(deliveryBoyStr.trim());
                newAddress = newAddress.trim();

                // 1. Update address + status = Assigned for all orders in group
                try (PreparedStatement ps = con.prepareStatement(
                        "UPDATE orders SET status='Assigned', address=? WHERE group_id=?")) {
                    ps.setString(1, newAddress);
                    ps.setInt(2, groupId);
                    ps.executeUpdate();
                }

                // 2. Reassign delivery boy via DeliveryBoyDAO
                DeliveryBoyDAO dbDao = new DeliveryBoyDAO();
                try (PreparedStatement ps = con.prepareStatement(
                        "SELECT id FROM orders WHERE group_id=?")) {
                    ps.setInt(1, groupId);
                    try (ResultSet rs = ps.executeQuery()) {
                        while (rs.next()) {
                            dbDao.assignDeliveryBoy(rs.getInt("id"), newDeliveryBoyId,
                                    "Re-delivery by staff" + (staffNote.isEmpty() ? "" : ": " + staffNote));
                        }
                    }
                }

                // 3. Log status history
                new OrderStatusHistoryDAO().logByGroup(groupId, "Assigned (Re-delivery)", staffName);

                // 4. Notify delivery boy
                NotificationDAO.sendRedeliveryScheduled(newDeliveryBoyId, firstOrderId, customerName);

                // 5. Notify customer
                if (customerId > 0) {
                    NotificationDAO.sendOrderStatusChanged(customerId, firstOrderId, productName,
                            "Rescheduled for Re-delivery");
                }

                // 6. Email customer
                if (customerEmail != null) {
                    final String fe = customerEmail, fn = customerName, fp = productName;
                    final int fid = firstOrderId;
                    new Thread(() -> EmailService.sendOrderStatusEmail(
                            fe, fn, "Rescheduled for Re-delivery", fid, fp)).start();
                }

                res.sendRedirect("staff-cancelled-orders.jsp?success=reattempt_scheduled");

            // ═══════════════════════════════════════════════════════════
            } else if ("cancel".equals(action)) {
            // ═══════════════════════════════════════════════════════════

                String cancelReason = req.getParameter("cancelReason");
                if (cancelReason == null || cancelReason.trim().isEmpty())
                    cancelReason = "Customer not responding";
                cancelReason = cancelReason.trim();

                // 1. Cancel all orders in group
                try (PreparedStatement ps = con.prepareStatement(
                        "UPDATE orders SET status='Cancelled' WHERE group_id=?")) {
                    ps.setInt(1, groupId);
                    ps.executeUpdate();
                }

                // 2. Cancel delivery_assignments
                try (PreparedStatement ps = con.prepareStatement(
                        "UPDATE delivery_assignments SET status='CANCELLED', delivery_note=? " +
                        "WHERE order_id IN (SELECT id FROM orders WHERE group_id=?)")) {
                    ps.setString(1, "Cancelled by staff — " + cancelReason
                            + (staffNote.isEmpty() ? "" : " | " + staffNote));
                    ps.setInt(2, groupId);
                    ps.executeUpdate();
                }

                // 3. Restore stock
                new ProductDAO().restoreStockByGroup(groupId);

                // 4. Log status history
                new OrderStatusHistoryDAO().logByGroup(groupId, "Cancelled", staffName);

                // 5. Notify delivery boy (if assigned)
                if (deliveryBoyDbId > 0) {
                    NotificationDAO.sendAssignedOrderCancelled(deliveryBoyDbId, firstOrderId, productName);
                }

                // 6. Notify + email customer
                if (customerId > 0) {
                    NotificationDAO.sendOrderStatusChanged(customerId, firstOrderId, productName, "Cancelled");
                }
                if (customerEmail != null) {
                    final String fe = customerEmail, fn = customerName, fp = productName, fr = cancelReason;
                    final int fid = firstOrderId;
                    new Thread(() -> EmailService.sendOrderStatusEmail(
                            fe, fn, "Cancelled — " + fr, fid, fp)).start();
                }

                res.sendRedirect("staff-cancelled-orders.jsp?success=order_cancelled");

            } else {
                res.sendRedirect("staff-cancelled-orders.jsp?error=unknown_action");
            }

        } catch (Exception e) {
            e.printStackTrace();
            res.sendRedirect("staff-cancelled-orders.jsp?error=server_error");
        }
    }
}