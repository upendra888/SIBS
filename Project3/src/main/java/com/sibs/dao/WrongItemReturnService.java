package com.sibs.dao;

import com.sibs.model.ReturnRequest;
import com.sibs.util.DBConnection;

import java.sql.*;
import java.util.*;

/**
 * WrongItemReturnService — Option B (Semi-manual)
 *
 * Staff GENUINE mark chesaaka:
 *   Step 1 (auto)   — return_requests lo entry create + approve
 *   Step 2 (manual) — Staff pickup date + slot choose chestaru
 *   Step 3 (auto)   — Staff confirm chesaaka schedule + notification
 */
public class WrongItemReturnService {

    private final ReturnDAO returnDAO = new ReturnDAO();

    // -----------------------------------------------------------------------
    // STEP 1 — GENUINE chesaaka auto: return create + approve only
    // Pickup schedule cheyyadu — staff manually chestadu
    // -----------------------------------------------------------------------
    public int createAndApproveReturn(int complaintId, String staffNote) {
        try (Connection conn = DBConnection.getConnection()) {

            ComplaintInfo ci = fetchComplaintInfo(conn, complaintId);
            if (ci == null) return -1;

            // Already return unte return id return cheyyali
            if (returnDAO.returnExists(ci.orderId)) {
                return getExistingReturnId(conn, ci.orderId);
            }

            // Return create
            ReturnRequest rr = new ReturnRequest();
            rr.setOrderId(ci.orderId);
            rr.setGroupId(ci.groupId);
            rr.setUserId(ci.userId);
            rr.setProductId(ci.productId);
            rr.setReason("WRONG_ITEM");
            rr.setDescription("Wrong item received. Complaint #" + complaintId
                    + " resolved as GENUINE. Note: " + (staffNote != null ? staffNote : ""));
            rr.setRefundAmount(ci.orderTotal);
            rr.setRefundMethod("ORIGINAL");

            int returnId = returnDAO.submitReturn(rr);
            if (returnId <= 0) return -1;

            // Auto-approve (GENUINE kabatti)
            returnDAO.approveReturn(returnId, ci.orderTotal, "ORIGINAL",
                    "Auto-approved: wrong item confirmed. Complaint #" + complaintId);

            // Order return_status update
            updateOrderReturnStatus(conn, ci.orderId, "Return_Approved_Pending_Pickup");

            // Customer ki notification — pickup pending
            NotificationDAO.sendReturnStatusChanged(
                    ci.userId, returnId, ci.productName, "APPROVED");

            // Staff ki notification
            NotificationDAO.sendNewReturnToStaff(returnId, ci.customerName, ci.productName);

            return returnId;

        } catch (Exception e) {
            e.printStackTrace();
            return -1;
        }
    }

    // -----------------------------------------------------------------------
    // STEP 2 — Available slots fetch cheyali (staff ki show cheyyataniki)
    // -----------------------------------------------------------------------
    public List<Map<String, Object>> getAvailableSlots(String pickupDate) {
        List<Map<String, Object>> slots = new ArrayList<>();
        String sql =
            "SELECT ds.slot_id, ds.slot_name, ds.start_time, ds.end_time, " +
            "       ds.max_capacity, " +
            "       (SELECT COUNT(*) FROM delivery_slot_bookings b " +
            "        WHERE b.slot_id = ds.slot_id AND b.booking_date = ? " +
            "          AND b.status != 'CANCELLED') AS booked_count " +
            "FROM   delivery_slots ds " +
            "WHERE  ds.is_active = 1 " +
            "ORDER  BY ds.start_time";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, pickupDate);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    int max    = rs.getInt("max_capacity");
                    int booked = rs.getInt("booked_count");
                    if (booked >= max) continue; // full slots skip

                    Map<String, Object> slot = new LinkedHashMap<>();
                    slot.put("slot_id",    rs.getInt("slot_id"));
                    slot.put("slot_name",  rs.getString("slot_name"));
                    slot.put("start_time", rs.getString("start_time"));
                    slot.put("end_time",   rs.getString("end_time"));
                    slot.put("remaining",  max - booked);
                    slots.add(slot);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return slots;
    }

    // -----------------------------------------------------------------------
    // STEP 3 — Staff slot + date choose chesaaka: schedule confirm
    // -----------------------------------------------------------------------
    public boolean schedulePickup(int returnId, int slotId, String pickupDate, int deliveryBoyId) {
        try (Connection conn = DBConnection.getConnection()) {

            // return_requests update
            String sql =
                "UPDATE return_requests " +
                "SET    status = 'PICKUP_SCHEDULED', " +
                "       pickup_slot_id = ?, " +
                "       scheduled_pickup_date = ? " +
                "WHERE  id = ? AND status = 'APPROVED'";

            int rows;
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setInt(1, slotId);
                ps.setString(2, pickupDate);
                ps.setInt(3, returnId);
                rows = ps.executeUpdate();
            }

            if (rows == 0) return false;

            // Order return_status update + delivery boy assign
            int orderId = getOrderIdForReturn(conn, returnId);
            if (orderId > 0) {
                updateOrderReturnStatus(conn, orderId, "Return_Pickup_Scheduled");

                // Delivery boy assign cheyyi (pickup ki)
                // NOTE: assignDeliveryBoy() vadadam ledu — adi order status ni
                // 'Assigned' ki tirugustaadi, return pickup ki order already Delivered ga undi.
                // Direct INSERT chestaam — order status touch cheyyakundaa.
                if (deliveryBoyId > 0) {
                    String otp = String.valueOf((int)(Math.random() * 9000) + 1000);
                    try (PreparedStatement ins = conn.prepareStatement(
                            "INSERT INTO delivery_assignments " +
                            "(order_id, delivery_boy_id, status, otp, assigned_at) " +
                            "VALUES (?, ?, 'ASSIGNED', ?, NOW())")) {
                        ins.setInt(1, orderId);
                        ins.setInt(2, deliveryBoyId);
                        ins.setString(3, otp);
                        ins.executeUpdate();
                    }
                    // Delivery boy ki notification
                    NotificationDAO.sendDeliveryAssigned(deliveryBoyId, orderId, "Return Pickup");
                }
            }

            // Customer ki pickup scheduled notification
            ReturnInfo ri = fetchReturnInfo(conn, returnId);
            if (ri != null) {
                NotificationDAO.sendReturnStatusChanged(
                        ri.userId, returnId, ri.productName, "PICKUP_SCHEDULED");
            }

            return true;

        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    // -----------------------------------------------------------------------
    // Internal helpers
    // -----------------------------------------------------------------------

    private ComplaintInfo fetchComplaintInfo(Connection conn, int complaintId) throws SQLException {
        String sql =
            "SELECT sc.order_id, sc.user_id, " +
            "       o.group_id, o.product_id, o.address, " +
            "       COALESCE(o.total, 0) AS order_total, " +
            "       u.username AS customer_name, " +
            "       p.name AS product_name " +
            "FROM   support_complaints sc " +
            "JOIN   orders o  ON o.id  = sc.order_id " +
            "JOIN   users  u  ON u.id  = sc.user_id " +
            "JOIN   products p ON p.id = o.product_id " +
            "WHERE  sc.id = ? LIMIT 1";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, complaintId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    ComplaintInfo ci = new ComplaintInfo();
                    ci.orderId      = rs.getInt("order_id");
                    ci.groupId      = rs.getInt("group_id");
                    ci.userId       = rs.getInt("user_id");
                    ci.productId    = rs.getInt("product_id");
                    ci.address      = rs.getString("address");
                    ci.orderTotal   = rs.getDouble("order_total");
                    ci.customerName = rs.getString("customer_name");
                    ci.productName  = rs.getString("product_name");
                    return ci;
                }
            }
        }
        return null;
    }

    private int getExistingReturnId(Connection conn, int orderId) throws SQLException {
        String sql = "SELECT id FROM return_requests WHERE order_id = ? LIMIT 1";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt("id") : -1;
            }
        }
    }

    private int getOrderIdForReturn(Connection conn, int returnId) throws SQLException {
        String sql = "SELECT order_id FROM return_requests WHERE id = ?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, returnId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt("order_id") : -1;
            }
        }
    }

    private ReturnInfo fetchReturnInfo(Connection conn, int returnId) throws SQLException {
        String sql =
            "SELECT rr.user_id, p.name AS product_name, ds.slot_name " +
            "FROM   return_requests rr " +
            "JOIN   products p ON p.id = rr.product_id " +
            "LEFT JOIN delivery_slots ds ON ds.slot_id = rr.pickup_slot_id " +
            "WHERE  rr.id = ?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, returnId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    ReturnInfo ri = new ReturnInfo();
                    ri.userId      = rs.getInt("user_id");
                    ri.productName = rs.getString("product_name");
                    ri.slotName    = rs.getString("slot_name");
                    return ri;
                }
            }
        }
        return null;
    }

    private void updateOrderReturnStatus(Connection conn, int orderId, String status) throws SQLException {
        String sql = "UPDATE orders SET return_status = ? WHERE id = ?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, status);
            ps.setInt(2, orderId);
            ps.executeUpdate();
        }
    }

    private static class ComplaintInfo {
        int orderId, groupId, userId, productId;
        double orderTotal;
        String address, customerName, productName;
    }

    private static class ReturnInfo {
        int userId;
        String productName, slotName;
    }
}