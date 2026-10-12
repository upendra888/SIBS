package com.sibs.dao;

import com.sibs.model.DeliveryAssignment;
import com.sibs.model.DeliveryBoy;
import com.sibs.util.AppSettings;
import com.sibs.util.DBConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class DeliveryBoyDAO {

    // ── DEBUG: stores the last SQL exception message ─────────────
    public static volatile String lastError = null;

    // ─────────────────────────────────────────────
    //  CRUD – Delivery Boys
    // ─────────────────────────────────────────────

    // Used by self-registration servlet — returns generated ID, status = PENDING
    public int registerDeliveryBoy(DeliveryBoy db, String city) {
        lastError = null;
        String sql = "INSERT INTO delivery_boys (name, phone, email, password, city, status) VALUES (?, ?, ?, ?, ?, 'PENDING')";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, db.getName());
            ps.setString(2, db.getPhone());
            ps.setString(3, db.getEmail());
            ps.setString(4, db.getPassword());
            ps.setString(5, city);
            if (ps.executeUpdate() > 0) {
                try (ResultSet keys = ps.getGeneratedKeys()) {
                    if (keys.next()) return keys.getInt(1);
                }
            }
        } catch (SQLException e) {
            lastError = e.getMessage() + " [SQLState=" + e.getSQLState() + " Code=" + e.getErrorCode() + "]";
            System.err.println("[DeliveryBoyDAO] registerDeliveryBoy FAILED: " + lastError);
            e.printStackTrace();
        }
        return -1;
    }

    // Used by Admin (Add Delivery Boy page) — no city field
    public boolean addDeliveryBoy(DeliveryBoy db) {
        return addDeliveryBoy(db, null);
    }

    // Used by self-registration servlet — includes city
    public boolean addDeliveryBoy(DeliveryBoy db, String city) {
        String sql = "INSERT INTO delivery_boys (name, phone, email, password, city, status) VALUES (?, ?, ?, ?, ?, 'ACTIVE')";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, db.getName());
            ps.setString(2, db.getPhone());
            ps.setString(3, db.getEmail());
            ps.setString(4, db.getPassword());
            ps.setString(5, city);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }

    public boolean deleteDeliveryBoy(int id) {
        String sql = "DELETE FROM delivery_boys WHERE id = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, id);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }

    public List<DeliveryBoy> getAllDeliveryBoys() {
        String sql = "SELECT * FROM delivery_boys ORDER BY name";
        List<DeliveryBoy> list = new ArrayList<>();
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapDeliveryBoy(rs));
        } catch (SQLException e) { e.printStackTrace(); }
        return list;
    }

    public List<DeliveryBoy> getOnlineDeliveryBoys() {
        String sql = "SELECT * FROM delivery_boys WHERE is_online = 1 ORDER BY name";
        List<DeliveryBoy> list = new ArrayList<>();
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapDeliveryBoy(rs));
        } catch (SQLException e) { e.printStackTrace(); }
        return list;
    }

    // ─────────────────────────────────────────────
    //  Registration Helpers
    // ─────────────────────────────────────────────

    public boolean isEmailExists(String email) {
        String sql = "SELECT COUNT(*) FROM delivery_boys WHERE email = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, email);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() && rs.getInt(1) > 0;
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }

    public boolean isPhoneExists(String phone) {
        String sql = "SELECT COUNT(*) FROM delivery_boys WHERE phone = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, phone);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() && rs.getInt(1) > 0;
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }

    // ─────────────────────────────────────────────
    //  Online Presence Tracking
    // ─────────────────────────────────────────────

    private static final double MINIMUM_WALLET = 200.00;

    public String setOnlineStatus(int deliveryBoyId, boolean online) {
        if (online) {
            String checkSql = "SELECT wallet FROM delivery_boys WHERE id = ?";
            try (Connection con = DBConnection.getConnection();
                 PreparedStatement ps = con.prepareStatement(checkSql)) {
                ps.setInt(1, deliveryBoyId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        double wallet = rs.getDouble("wallet");
                        if (wallet < MINIMUM_WALLET) {
                            return "LOW_WALLET";
                        }
                    }
                }
            } catch (SQLException e) {
                e.printStackTrace();
                return "ERROR";
            }
        }

        String sql = online
            ? "UPDATE delivery_boys SET is_online=1, last_seen=NOW() WHERE id=?"
            : "UPDATE delivery_boys SET is_online=0                   WHERE id=?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, deliveryBoyId);
            ps.executeUpdate();
            return "OK";
        } catch (SQLException e) {
            e.printStackTrace();
            return "ERROR";
        }
    }

    public void setShiftStatus(int deliveryBoyId, String state) {
        String sql;
        if ("ONLINE".equals(state)) {
            sql = "UPDATE delivery_boys " +
                  "SET shift_status='ONLINE', is_online=1, " +
                  "    shift_started_at=COALESCE(shift_started_at, NOW()), " +
                  "    last_seen=NOW() " +
                  "WHERE id=?";
        } else if ("ON_BREAK".equals(state)) {
            sql = "UPDATE delivery_boys " +
                  "SET shift_status='ON_BREAK', is_online=1, last_seen=NOW() " +
                  "WHERE id=?";
        } else {
            sql = "UPDATE delivery_boys " +
                  "SET shift_status='OFFLINE', is_online=0, last_seen=NOW() " +
                  "WHERE id=?";
        }
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, deliveryBoyId);
            ps.executeUpdate();
        } catch (SQLException e) { e.printStackTrace(); }
    }

    public List<DeliveryBoy> getAllWithStats() {
        String sql =
            "SELECT db.id, db.name, db.phone, db.email, db.password, db.status, db.created_at, " +
            "       db.is_online, db.shift_status, COALESCE(db.shift_started_at, db.shift_started) AS shift_started_at, db.last_seen, " +
            "       COUNT(CASE WHEN UPPER(da.status) NOT IN ('DELIVERED','CANCELLED') THEN 1 END) AS active_orders, " +
            "       COUNT(CASE WHEN UPPER(da.status) = 'DELIVERED'                    THEN 1 END) AS delivered_total " +
            "FROM delivery_boys db " +
            "LEFT JOIN delivery_assignments da ON da.delivery_boy_id = db.id " +
            "GROUP BY db.id " +
            "ORDER BY db.is_online DESC, db.name ASC";

        List<DeliveryBoy> list = new ArrayList<>();
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                DeliveryBoy boy = mapDeliveryBoy(rs);
                boy.setOnline(rs.getInt("is_online") == 1);
                boy.setActiveOrders(rs.getInt("active_orders"));
                boy.setDeliveredTotal(rs.getInt("delivered_total"));

                String ss = rs.getString("shift_status");
                boy.setShiftStatus(ss != null ? ss : (boy.isOnline() ? "ONLINE" : "OFFLINE"));

                Timestamp shiftTs = rs.getTimestamp("shift_started_at");
                if (shiftTs != null) {
                    java.text.SimpleDateFormat sdf = new java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss");
                    boy.setShiftStartedAt(sdf.format(shiftTs));
                }

                Timestamp lastTs = rs.getTimestamp("last_seen");
                if (lastTs != null) {
                    java.text.SimpleDateFormat sdf2 = new java.text.SimpleDateFormat("dd MMM, HH:mm");
                    boy.setLastSeen(sdf2.format(lastTs));
                }

                list.add(boy);
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return list;
    }

    // ─────────────────────────────────────────────
    //  Assignment – write
    // ─────────────────────────────────────────────

    public boolean assignDeliveryBoy(int orderId, int deliveryBoyId, String note) {
        String otp = String.valueOf((int)(Math.random() * 9000) + 1000);
        String sql = "INSERT INTO delivery_assignments (order_id, delivery_boy_id, status, otp, assigned_at) " +
                     "VALUES (?, ?, 'ASSIGNED', ?, NOW())";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, orderId);
            ps.setInt(2, deliveryBoyId);
            ps.setString(3, otp);
            int rows = ps.executeUpdate();
            if (rows > 0) {
                try (PreparedStatement gps = con.prepareStatement(
                        "SELECT group_id FROM orders WHERE id = ?")) {
                    gps.setInt(1, orderId);
                    try (ResultSet grs = gps.executeQuery()) {
                        if (grs.next()) {
                            int gid = grs.getInt("group_id");
                            try (PreparedStatement ups = con.prepareStatement(
                                    "UPDATE orders SET status = 'Assigned' WHERE group_id = ?")) {
                                ups.setInt(1, gid);
                                ups.executeUpdate();
                            }
                        }
                    }
                }
                return true;
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }

    public boolean verifyOtpAndDeliver(int assignmentId, int orderId, String enteredOtp) {
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(
                     "SELECT otp FROM delivery_assignments WHERE id = ?")) {
            ps.setInt(1, assignmentId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    String storedOtp = rs.getString("otp");
                    if (storedOtp != null && storedOtp.equals(enteredOtp.trim())) {
                        try (PreparedStatement ups = con.prepareStatement(
                                "UPDATE delivery_assignments SET status='DELIVERED', delivered_at=NOW() WHERE id=?")) {
                            ups.setInt(1, assignmentId);
                            ups.executeUpdate();
                        }
                        try (PreparedStatement gps = con.prepareStatement(
                                "SELECT group_id FROM orders WHERE id = ?")) {
                            gps.setInt(1, orderId);
                            try (ResultSet grs = gps.executeQuery()) {
                                if (grs.next()) {
                                    int gid = grs.getInt("group_id");
                                    try (PreparedStatement upo = con.prepareStatement(
                                            "UPDATE orders SET status='Delivered' WHERE group_id=?")) {
                                        upo.setInt(1, gid);
                                        upo.executeUpdate();
                                    }
                                }
                            }
                        }
                        return true;
                    }
                }
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }

    // ─────────────────────────────────────────────
    //  Authentication
    // ─────────────────────────────────────────────

    public DeliveryBoy login(String email, String plainPassword) {
        String sql = "SELECT * FROM delivery_boys WHERE email=? AND status='ACTIVE'";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, email);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    DeliveryBoy db = mapDeliveryBoy(rs);
                    String stored = db.getPassword();
                    boolean valid = com.sibs.util.PasswordUtil.checkPassword(plainPassword, stored);
                    if (valid && com.sibs.util.PasswordUtil.needsMigration(stored)) {
                        updatePassword(db.getId(), com.sibs.util.PasswordUtil.hashPassword(plainPassword));
                    }
                    return valid ? db : null;
                }
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return null;
    }

    public boolean updatePassword(int id, String newHashedPassword) {
        String sql = "UPDATE delivery_boys SET password=? WHERE id=?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, newHashedPassword);
            ps.setInt(2, id);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }

    // ─────────────────────────────────────────────
    //  Assignments – read
    // ─────────────────────────────────────────────

    public List<DeliveryAssignment> getAssignments(int deliveryBoyId) {
        List<DeliveryAssignment> list = new ArrayList<>();
        String sql =
            "SELECT da.id, da.order_id, da.status, da.otp, da.delivered_at, " +
            "       SUM(o.total) + MAX(COALESCE(o.delivery_charge,0)) AS total_amount, " +
            "       o.payment_method, " +
            "       o.name  AS customer_name, o.phone AS customer_phone, " +
            "       o.address AS delivery_address, " +
            "       0 AS dest_lat, 0 AS dest_lng, " +
            "       GROUP_CONCAT(p.name ORDER BY o.id SEPARATOR ', ') AS product_name, " +
            "       SUM(o.quantity) AS quantity, " +
            "       o.group_id, " +
            "       rr.id AS return_id " +
            "FROM   delivery_assignments da " +
            "JOIN   orders   o ON o.group_id = (SELECT group_id FROM orders WHERE id = da.order_id LIMIT 1) " +
            "LEFT JOIN products p ON p.id = o.product_id " +
            "LEFT JOIN return_requests rr " +
            "       ON rr.order_id = da.order_id " +
            "       AND rr.status IN ('PICKUP_SCHEDULED','PICKED_UP') " +
            "WHERE  da.delivery_boy_id = ? " +
            "AND    da.status != 'CANCELLED' " +
            "GROUP  BY da.id, da.status, da.otp, da.delivered_at, " +
            "          o.payment_method, o.name, o.phone, o.address, o.group_id, rr.id " +
            "ORDER  BY da.id DESC";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, deliveryBoyId);
            try (ResultSet rs = ps.executeQuery()) {
                java.util.Set<Integer> seenGroups = new java.util.HashSet<>();
                while (rs.next()) {
                    int gid = rs.getInt("group_id");
                    if (seenGroups.contains(gid)) continue;
                    seenGroups.add(gid);
                    DeliveryAssignment da = new DeliveryAssignment();
                    da.setId(rs.getInt("id"));
                    da.setOrderId(gid > 0 ? gid : rs.getInt("order_id"));
                    da.setDeliveryBoyId(deliveryBoyId);
                    da.setStatus(rs.getString("status"));
                    da.setOtp(rs.getString("otp"));
                    da.setDeliveredAt(rs.getString("delivered_at"));
                    da.setAmount(rs.getDouble("total_amount"));
                    String pm = rs.getString("payment_method");
                    da.setPaymentMethod(pm != null ? pm.toUpperCase() : "COD");
                    da.setCustomerName(rs.getString("customer_name"));
                    da.setCustomerPhone(rs.getString("customer_phone"));
                    da.setDeliveryAddress(rs.getString("delivery_address"));
                    da.setDestLat(rs.getDouble("dest_lat"));
                    da.setDestLng(rs.getDouble("dest_lng"));
                    String pName = rs.getString("product_name");
                    da.setProductName(pName != null ? pName : "Unknown");
                    da.setQuantity(rs.getInt("quantity"));
                    int retId = rs.getInt("return_id");
                    if (retId > 0) {
                        da.setReturnPickup(true);
                        da.setReturnId(retId);
                    }
                    list.add(da);
                }
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    public List<DeliveryAssignment> getAssignmentsByStatus(int deliveryBoyId, String status) {
        String sql = "SELECT da.id, da.order_id, da.delivery_boy_id, da.status, da.otp, " +
                     "       da.assigned_at, da.delivered_at, " +
                     "       o.name AS customer_name, o.phone AS customer_phone, " +
                     "       o.address AS delivery_address, " +
                     "       o.total AS total_amount, " +
                     "       o.quantity AS order_quantity, " +
                     "       o.group_id, " +
                     "       p.name AS product_name " +
                     "FROM   delivery_assignments da " +
                     "JOIN   orders o ON da.order_id = o.id " +
                     "LEFT JOIN products p ON o.product_id = p.id " +
                     "WHERE  da.delivery_boy_id = ? AND UPPER(da.status) = UPPER(?) " +
                     "ORDER  BY da.assigned_at DESC";

        List<DeliveryAssignment> list = new ArrayList<>();
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, deliveryBoyId);
            ps.setString(2, status);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapAssignment(rs));
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return list;
    }

    public DeliveryAssignment getAssignmentById(int assignmentId) {
        String sql = "SELECT da.id, da.order_id, da.delivery_boy_id, da.status, da.otp, " +
                     "       da.assigned_at, da.delivered_at, " +
                     "       o.name AS customer_name, o.phone AS customer_phone, " +
                     "       o.address AS delivery_address, " +
                     "       o.total AS total_amount, " +
                     "       o.quantity AS order_quantity, " +
                     "       o.group_id, " +
                     "       p.name AS product_name " +
                     "FROM   delivery_assignments da " +
                     "JOIN   orders o ON da.order_id = o.id " +
                     "LEFT JOIN products p ON o.product_id = p.id " +
                     "WHERE  da.id = ?";

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, assignmentId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapAssignment(rs);
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return null;
    }

    // ─────────────────────────────────────────────
    //  Dashboard counts
    // ─────────────────────────────────────────────

    public int getTotalAssignedToday(int deliveryBoyId) {
        return countQuery("SELECT COUNT(*) FROM delivery_assignments " +
                          "WHERE delivery_boy_id = ? " +
                          "AND UPPER(status) != 'CANCELLED' " +
                          "AND DATE(assigned_at) = CURDATE()", deliveryBoyId);
    }

    public int getPendingToday(int deliveryBoyId) {
        return countQuery("SELECT COUNT(*) FROM delivery_assignments " +
                          "WHERE delivery_boy_id = ? " +
                          "AND UPPER(status) NOT IN ('DELIVERED', 'CANCELLED')", deliveryBoyId);
    }

    public int getDeliveredToday(int deliveryBoyId) {
        return countQuery("SELECT COUNT(*) FROM delivery_assignments " +
                          "WHERE delivery_boy_id = ? " +
                          "AND UPPER(status) = 'DELIVERED' " +
                          "AND DATE(delivered_at) = CURDATE()", deliveryBoyId);
    }

    public int getDeliveredTodayOnline(int deliveryBoyId) {
        String sql =
            "SELECT COUNT(DISTINCT da.id) FROM delivery_assignments da " +
            "JOIN orders o ON o.id = da.order_id " +
            "WHERE da.delivery_boy_id = ? " +
            "AND UPPER(da.status) = 'DELIVERED' " +
            "AND DATE(da.delivered_at) = CURDATE() " +
            "AND UPPER(COALESCE(" +
            "  (SELECT payment_method FROM orders o2 WHERE o2.group_id = o.group_id " +
            "   AND UPPER(COALESCE(o2.payment_method,'COD')) != 'COD' LIMIT 1)" +
            ",'COD')) != 'COD'";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, deliveryBoyId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return 0;
    }

    public int getDeliveredTodayCod(int deliveryBoyId) {
        String sql =
            "SELECT COUNT(*) FROM delivery_assignments da " +
            "JOIN orders o ON o.id = da.order_id " +
            "WHERE da.delivery_boy_id = ? " +
            "AND UPPER(da.status) = 'DELIVERED' " +
            "AND DATE(da.delivered_at) = CURDATE() " +
            "AND UPPER(COALESCE(o.payment_method,'COD')) = 'COD'";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, deliveryBoyId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return 0;
    }

    // ─────────────────────────────────────────────
    //  Status transitions
    // ─────────────────────────────────────────────

    public String confirmPickup(int assignmentId) {
        boolean ok = updateAssignmentStatus(assignmentId, "PICKED_UP", "Out for Delivery");
        if (!ok) return null;
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(
                     "SELECT otp FROM delivery_assignments WHERE id = ?")) {
            ps.setInt(1, assignmentId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getString("otp");
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return null;
    }

    public boolean verifyOtp(int assignmentId, String enteredOtp) {
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(
                     "SELECT otp FROM delivery_assignments WHERE id = ?")) {
            ps.setInt(1, assignmentId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    String storedOtp = rs.getString("otp");
                    if (storedOtp != null && storedOtp.equals(enteredOtp.trim())) {
                        return updateAssignmentStatus(assignmentId, "OTP_VERIFIED", "ORDER_OTP_VERIFIED");
                    }
                }
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }

    public boolean markDelivered(int assignmentId) {
        return markDelivered(assignmentId, -1);
    }

    public boolean markDelivered(int assignmentId, int deliveryBoyId) {
        String sql = deliveryBoyId > 0
            ? "UPDATE delivery_assignments SET status='DELIVERED', delivered_at=NOW() " +
              "WHERE id=? AND delivery_boy_id=? AND UPPER(status) NOT IN ('DELIVERED','CANCELLED')"
            : "UPDATE delivery_assignments SET status='DELIVERED', delivered_at=NOW() WHERE id=?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, assignmentId);
            if (deliveryBoyId > 0) ps.setInt(2, deliveryBoyId);
            int rows = ps.executeUpdate();
            if (rows > 0) {
                updateOrderStatusByAssignment(con, assignmentId, "Delivered");
                return true;
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }

    public boolean updateProfile(DeliveryBoy db) {
        String sql = "UPDATE delivery_boys SET name=?, phone=? WHERE id=?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, db.getName());
            ps.setString(2, db.getPhone());
            ps.setInt(3, db.getId());
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    // ─────────────────────────────────────────────
    //  Search
    // ─────────────────────────────────────────────

    public List<DeliveryAssignment> searchAssignments(int deliveryBoyId, String keyword) {
        String sql = "SELECT da.id, da.order_id, da.delivery_boy_id, da.status, da.otp, " +
                     "       da.assigned_at, da.delivered_at, " +
                     "       o.name AS customer_name, o.phone AS customer_phone, " +
                     "       o.address AS delivery_address, " +
                     "       o.total AS total_amount, " +
                     "       o.quantity AS order_quantity, " +
                     "       o.group_id, " +
                     "       p.name AS product_name " +
                     "FROM   delivery_assignments da " +
                     "JOIN   orders o ON da.order_id = o.id " +
                     "LEFT JOIN products p ON o.product_id = p.id " +
                     "WHERE  da.delivery_boy_id = ? " +
                     "AND   (o.name LIKE ? OR o.phone LIKE ?) " +
                     "ORDER  BY da.assigned_at DESC";

        List<DeliveryAssignment> list = new ArrayList<>();
        String like = "%" + keyword + "%";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, deliveryBoyId);
            ps.setString(2, like);
            ps.setString(3, like);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapAssignment(rs));
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return list;
    }

    // ─────────────────────────────────────────────
    //  Cancel ride
    // ─────────────────────────────────────────────

    public boolean cancelRide(int assignmentId, int orderId) {
        String sql = "SELECT status FROM delivery_assignments WHERE id=?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, assignmentId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    String status = rs.getString("status");
                    if (!"ASSIGNED".equalsIgnoreCase(status)) return false;
                }
            }
        } catch (SQLException e) { e.printStackTrace(); return false; }

        int groupId = -1;
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement("SELECT group_id FROM orders WHERE id=?")) {
            ps.setInt(1, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) groupId = rs.getInt("group_id");
            }
        } catch (SQLException e) { e.printStackTrace(); return false; }

        if (groupId == -1) return false;

        String cancelAssign = "UPDATE delivery_assignments SET status='CANCELLED' WHERE id=?";
        String resetOrders  = "UPDATE orders SET status='Pending', delivery_boy=NULL, delivery_note=NULL WHERE group_id=?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps1 = con.prepareStatement(cancelAssign);
             PreparedStatement ps2 = con.prepareStatement(resetOrders)) {
            ps1.setInt(1, assignmentId);
            ps1.executeUpdate();
            ps2.setInt(1, groupId);
            ps2.executeUpdate();
        } catch (SQLException e) { e.printStackTrace(); return false; }

        try {
            NotificationDAO.sendRideCancelledByDeliveryBoy(groupId, orderId);
        } catch (Exception e) { e.printStackTrace(); }

        return true;
    }

    // ─────────────────────────────────────────────
    //  Reload fresh record by id
    // ─────────────────────────────────────────────

    public DeliveryBoy getById(int id) {
        String sql =
            "SELECT db.*, " +
            "       COUNT(CASE WHEN UPPER(da.status) = 'DELIVERED' THEN 1 END) AS delivered_total " +
            "FROM delivery_boys db " +
            "LEFT JOIN delivery_assignments da ON da.delivery_boy_id = db.id " +
            "WHERE db.id = ? " +
            "GROUP BY db.id";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    DeliveryBoy boy = mapDeliveryBoy(rs);
                    boy.setDeliveredTotal(rs.getInt("delivered_total"));
                    try {
                        Timestamp bts = rs.getTimestamp("break_started_at");
                        if (bts != null) {
                            java.text.SimpleDateFormat sdf = new java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss");
                            boy.setBreakStartedAt(sdf.format(bts));
                        }
                        boy.setTotalBreakSeconds(rs.getInt("total_break_seconds"));
                    } catch (SQLException ignored) {}
                    return boy;
                }
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return null;
    }

    // ─────────────────────────────────────────────
    //  Private helpers
    // ─────────────────────────────────────────────

    private boolean updateAssignmentStatus(int assignmentId, String newStatus, String orderStatus) {
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(
                     "UPDATE delivery_assignments SET status = ? WHERE id = ?")) {
            ps.setString(1, newStatus);
            ps.setInt(2, assignmentId);
            int rows = ps.executeUpdate();
            if (rows > 0) {
                updateOrderStatusByAssignment(con, assignmentId, orderStatus);
                return true;
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }

    private void updateOrderStatusByAssignment(Connection con, int assignmentId, String orderStatus)
            throws SQLException {
        int groupId = -1;
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT o.group_id FROM orders o " +
                "JOIN delivery_assignments da ON da.order_id = o.id WHERE da.id = ?")) {
            ps.setInt(1, assignmentId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) groupId = rs.getInt("group_id");
            }
        }
        if (groupId < 0) return;
        try (PreparedStatement ps = con.prepareStatement(
                "UPDATE orders SET status = ? WHERE group_id = ?")) {
            ps.setString(1, orderStatus);
            ps.setInt(2, groupId);
            ps.executeUpdate();
        }
    }

    private int countQuery(String sql, int deliveryBoyId) {
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, deliveryBoyId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return 0;
    }

    private DeliveryAssignment mapAssignment(ResultSet rs) throws SQLException {
        DeliveryAssignment da = new DeliveryAssignment();
        da.setId(rs.getInt("id"));
        int mgid = rs.getInt("group_id");
        da.setOrderId(mgid > 0 ? mgid : rs.getInt("order_id"));
        da.setDeliveryBoyId(rs.getInt("delivery_boy_id"));
        da.setStatus(rs.getString("status"));
        da.setOtp(rs.getString("otp"));
        da.setAssignedAt(rs.getString("assigned_at"));
        da.setDeliveredAt(rs.getString("delivered_at"));
        da.setCustomerName(rs.getString("customer_name"));
        da.setCustomerPhone(rs.getString("customer_phone"));
        da.setDeliveryAddress(rs.getString("delivery_address"));
        String pName = rs.getString("product_name");
        da.setProductName(pName != null ? pName : "Unknown");
        da.setQuantity(rs.getInt("order_quantity"));
        da.setAmount(rs.getDouble("total_amount"));
        String pm = rs.getString("payment_method");
        da.setPaymentMethod(pm != null ? pm.toUpperCase() : "COD");
        return da;
    }

    private DeliveryBoy mapDeliveryBoy(ResultSet rs) throws SQLException {
        DeliveryBoy db = new DeliveryBoy();
        db.setId(rs.getInt("id"));
        db.setName(rs.getString("name"));
        db.setPhone(rs.getString("phone"));
        db.setEmail(rs.getString("email"));
        db.setPassword(rs.getString("password"));
        db.setStatus(rs.getString("status"));
        db.setCreatedAt(rs.getString("created_at"));
        try { db.setOnline(rs.getInt("is_online") == 1); } catch (SQLException ignored) {}
        try {
            String ss = rs.getString("shift_status");
            if (ss != null) db.setShiftStatus(ss);
        } catch (SQLException ignored) {}
        try { db.setWallet(rs.getDouble("wallet")); } catch (SQLException ignored) {}
        return db;
    }

    // ─────────────────────────────────────────────────────────────────────────
    //  SLOT CHECK
    // ─────────────────────────────────────────────────────────────────────────

    public boolean hasActiveSlotToday(int deliveryBoyId) {
        String sql =
            "SELECT COUNT(*) FROM delivery_slot_bookings " +
            "WHERE delivery_boy_id = ? " +
            "  AND booking_date = CURDATE() " +
            "  AND status IN ('BOOKED', 'ACTIVE')";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, deliveryBoyId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() && rs.getInt(1) > 0;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    // ─────────────────────────────────────────────────────────────────────────
    //  COD Affordability Check
    // ─────────────────────────────────────────────────────────────────────────

    public String checkAndForceOfflineIfInsufficientForCod(int deliveryBoyId, double codAmount) {
        try (Connection con = DBConnection.getConnection()) {

            double wallet = 0;
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT wallet FROM delivery_boys WHERE id = ?")) {
                ps.setInt(1, deliveryBoyId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) wallet = rs.getDouble(1);
                }
            }

            double earningsToday = 0;
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT COUNT(*) FROM delivery_assignments " +
                    "WHERE delivery_boy_id = ? " +
                    "AND UPPER(status) = 'DELIVERED' " +
                    "AND DATE(delivered_at) = CURDATE()")) {
                ps.setInt(1, deliveryBoyId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) earningsToday = rs.getInt(1) * AppSettings.getPerDeliveryPay();
                }
            }

            double availableFunds = wallet + earningsToday;

            System.out.println("[COD-CHECK] id=" + deliveryBoyId
                + " wallet=" + wallet + " earnings=" + earningsToday
                + " available=" + availableFunds + " codAmount=" + codAmount);

            if (availableFunds < codAmount) {
                try (PreparedStatement upd = con.prepareStatement(
                        "UPDATE delivery_boys SET is_online=0, shift_status='OFFLINE' WHERE id=?")) {
                    upd.setInt(1, deliveryBoyId);
                    upd.executeUpdate();
                }
                System.out.println("[COD-CHECK] INSUFFICIENT - forced offline id=" + deliveryBoyId);
                return "INSUFFICIENT";
            }

            return "OK";

        } catch (Exception e) {
            e.printStackTrace();
            return "ERROR";
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    //  WALLET WITHDRAW
    // ─────────────────────────────────────────────────────────────────────────

    public String withdrawWallet(int deliveryBoyId, double amount) {
        if (amount <= 0) return "INVALID_AMOUNT";

        try (Connection con = DBConnection.getConnection()) {

            double currentWallet = 0;
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT wallet FROM delivery_boys WHERE id = ?")) {
                ps.setInt(1, deliveryBoyId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) currentWallet = rs.getDouble(1);
                }
            }

            if ((currentWallet - amount) < MINIMUM_WALLET) {
                return "INSUFFICIENT";
            }

            con.createStatement().execute(
                "CREATE TABLE IF NOT EXISTS wallet_transactions (" +
                "  id              INT AUTO_INCREMENT PRIMARY KEY," +
                "  delivery_boy_id INT NOT NULL," +
                "  amount          DECIMAL(10,2) NOT NULL," +
                "  type            ENUM('CREDIT','DEBIT') NOT NULL DEFAULT 'CREDIT'," +
                "  note            VARCHAR(500)," +
                "  created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP" +
                ")"
            );

            try (PreparedStatement ps = con.prepareStatement(
                    "INSERT INTO wallet_transactions (delivery_boy_id, amount, type, note) VALUES (?, ?, 'DEBIT', ?)")) {
                ps.setInt(1, deliveryBoyId);
                ps.setDouble(2, amount);
                ps.setString(3, "Wallet withdrawal by delivery boy");
                ps.executeUpdate();
            }

            try (PreparedStatement ps = con.prepareStatement(
                    "UPDATE delivery_boys SET wallet = wallet - ? WHERE id = ?")) {
                ps.setDouble(1, amount);
                ps.setInt(2, deliveryBoyId);
                ps.executeUpdate();
            }

            System.out.println("[WalletWithdraw] ₹" + amount + " debited for delivery_boy_id=" + deliveryBoyId);
            return "OK";

        } catch (Exception e) {
            e.printStackTrace();
            return "ERROR";
        }
    }

    public int countPendingApprovals() {
        String sql = "SELECT COUNT(*) FROM delivery_boys WHERE status = 'PENDING'";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            return rs.next() ? rs.getInt(1) : 0;
        } catch (Exception e) {
            e.printStackTrace();
            return 0;
        }
    }

    // ─────────────────────────────────────────────────────────────────
    //  Wallet Withdraw Request (staff-approval workflow)
    // ─────────────────────────────────────────────────────────────────

    private void ensureWithdrawTable(Connection con) throws java.sql.SQLException {
        con.createStatement().execute(
            "CREATE TABLE IF NOT EXISTS wallet_withdraw_requests (" +
            "  id              INT AUTO_INCREMENT PRIMARY KEY," +
            "  delivery_boy_id INT NOT NULL," +
            "  amount          DECIMAL(10,2) NOT NULL," +
            "  status          ENUM('PENDING','APPROVED','REJECTED') NOT NULL DEFAULT 'PENDING'," +
            "  staff_note      VARCHAR(500)," +
            "  requested_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP," +
            "  decided_at      DATETIME" +
            ")"
        );
    }

    public String requestWithdraw(int deliveryBoyId, double amount) {
        if (amount <= 0) return "INVALID_AMOUNT";
        try (Connection con = DBConnection.getConnection()) {
            ensureWithdrawTable(con);

            double wallet = 0;
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT wallet FROM delivery_boys WHERE id = ?")) {
                ps.setInt(1, deliveryBoyId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) wallet = rs.getDouble(1);
                }
            }
            if ((wallet - amount) < MINIMUM_WALLET) return "INSUFFICIENT";

            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT COUNT(*) FROM wallet_withdraw_requests " +
                    "WHERE delivery_boy_id=? AND status='PENDING'")) {
                ps.setInt(1, deliveryBoyId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next() && rs.getInt(1) > 0) return "PENDING_EXISTS";
                }
            }

            try (PreparedStatement ps = con.prepareStatement(
                    "INSERT INTO wallet_withdraw_requests (delivery_boy_id, amount) VALUES (?, ?)")) {
                ps.setInt(1, deliveryBoyId);
                ps.setDouble(2, amount);
                ps.executeUpdate();
            }
            return "OK";
        } catch (Exception e) {
            e.printStackTrace();
            return "ERROR";
        }
    }

    public String approveWithdraw(int requestId, String staffNote) {
        try (Connection con = DBConnection.getConnection()) {
            ensureWithdrawTable(con);
            con.setAutoCommit(false);

            int deliveryBoyId;
            double amount;

            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT delivery_boy_id, amount FROM wallet_withdraw_requests " +
                    "WHERE id=? AND status='PENDING' FOR UPDATE")) {
                ps.setInt(1, requestId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) { con.rollback(); return "NOT_FOUND"; }
                    deliveryBoyId = rs.getInt("delivery_boy_id");
                    amount        = rs.getDouble("amount");
                }
            }

            double wallet = 0;
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT wallet FROM delivery_boys WHERE id=?")) {
                ps.setInt(1, deliveryBoyId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) wallet = rs.getDouble(1);
                }
            }
            if ((wallet - amount) < MINIMUM_WALLET) {
                con.rollback();
                return "INSUFFICIENT";
            }

            try (PreparedStatement ps = con.prepareStatement(
                    "UPDATE delivery_boys SET wallet = wallet - ? WHERE id=?")) {
                ps.setDouble(1, amount);
                ps.setInt(2, deliveryBoyId);
                ps.executeUpdate();
            }

            con.createStatement().execute(
                "CREATE TABLE IF NOT EXISTS wallet_transactions (" +
                "  id INT AUTO_INCREMENT PRIMARY KEY," +
                "  delivery_boy_id INT NOT NULL," +
                "  amount DECIMAL(10,2) NOT NULL," +
                "  type ENUM('CREDIT','DEBIT') NOT NULL DEFAULT 'CREDIT'," +
                "  note VARCHAR(500)," +
                "  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP" +
                ")"
            );
            try (PreparedStatement ps = con.prepareStatement(
                    "INSERT INTO wallet_transactions (delivery_boy_id, amount, type, note) VALUES (?,?,'DEBIT',?)")) {
                ps.setInt(1, deliveryBoyId);
                ps.setDouble(2, amount);
                ps.setString(3, "Withdrawal approved by staff" + (staffNote != null && !staffNote.isBlank() ? ": " + staffNote : ""));
                ps.executeUpdate();
            }

            try (PreparedStatement ps = con.prepareStatement(
                    "UPDATE wallet_withdraw_requests SET status='APPROVED', staff_note=?, decided_at=NOW() WHERE id=?")) {
                ps.setString(1, staffNote);
                ps.setInt(2, requestId);
                ps.executeUpdate();
            }

            con.commit();
            return "OK";
        } catch (Exception e) {
            e.printStackTrace();
            return "ERROR";
        }
    }

    public String rejectWithdraw(int requestId, String staffNote) {
        try (Connection con = DBConnection.getConnection()) {
            ensureWithdrawTable(con);
            try (PreparedStatement ps = con.prepareStatement(
                    "UPDATE wallet_withdraw_requests SET status='REJECTED', staff_note=?, decided_at=NOW() " +
                    "WHERE id=? AND status='PENDING'")) {
                ps.setString(1, staffNote);
                ps.setInt(2, requestId);
                int rows = ps.executeUpdate();
                return rows > 0 ? "OK" : "NOT_FOUND";
            }
        } catch (Exception e) {
            e.printStackTrace();
            return "ERROR";
        }
    }

    public java.util.List<String[]> getAllWithdrawRequests() {
        java.util.List<String[]> list = new java.util.ArrayList<>();
        try (Connection con = DBConnection.getConnection()) {
            ensureWithdrawTable(con);
            String sql = "SELECT wr.id, db.name, db.phone, wr.delivery_boy_id, wr.amount, " +
                         "wr.status, wr.staff_note, wr.requested_at, wr.decided_at " +
                         "FROM wallet_withdraw_requests wr " +
                         "JOIN delivery_boys db ON db.id = wr.delivery_boy_id " +
                         "ORDER BY FIELD(wr.status,'PENDING','APPROVED','REJECTED'), wr.requested_at DESC";
            try (ResultSet rs = con.createStatement().executeQuery(sql)) {
                while (rs.next()) {
                    list.add(new String[]{
                        rs.getString("wr.id"),
                        rs.getString("db.name"),
                        rs.getString("db.phone"),
                        rs.getString("wr.delivery_boy_id"),
                        String.valueOf(rs.getDouble("wr.amount")),
                        rs.getString("wr.status"),
                        rs.getString("wr.staff_note"),
                        rs.getString("wr.requested_at"),
                        rs.getString("wr.decided_at")
                    });
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    public java.util.List<String[]> getWithdrawRequestsFor(int deliveryBoyId) {
        java.util.List<String[]> list = new java.util.ArrayList<>();
        try (Connection con = DBConnection.getConnection()) {
            ensureWithdrawTable(con);
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT id, amount, status, staff_note, requested_at, decided_at " +
                    "FROM wallet_withdraw_requests WHERE delivery_boy_id=? ORDER BY requested_at DESC LIMIT 10")) {
                ps.setInt(1, deliveryBoyId);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        list.add(new String[]{
                            rs.getString("id"),
                            String.valueOf(rs.getDouble("amount")),
                            rs.getString("status"),
                            rs.getString("staff_note"),
                            rs.getString("requested_at"),
                            rs.getString("decided_at")
                        });
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    public int countPendingWithdrawRequests() {
        try (Connection con = DBConnection.getConnection()) {
            ensureWithdrawTable(con);
            try (ResultSet rs = con.createStatement().executeQuery(
                    "SELECT COUNT(*) FROM wallet_withdraw_requests WHERE status='PENDING'")) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        } catch (Exception e) {
            e.printStackTrace();
            return 0;
        }
    }
}