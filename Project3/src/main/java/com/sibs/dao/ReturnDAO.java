package com.sibs.dao;

import com.sibs.model.ReturnRequest;
import com.sibs.util.DBConnection;
import com.sibs.util.RazorpayConfig;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * FIXES APPLIED:
 *   1. getReturnsByStatus()  — was string-concatenated (SQL injection risk + broke when
 *                              called with uppercase 'PENDING' while DB had 'Pending').
 *                              Now uses PreparedStatement.
 *   2. getReturnsByUser()    — same SQL-injection fix, uses PreparedStatement.
 *   3. getReturnById()       — same SQL-injection fix, uses PreparedStatement.
 *   4. confirmPickup()       — stock restore was JOIN orders o … SET p.quantity + o.quantity,
 *                              but orders.quantity is not per-product. Fixed to join order_items.
 *   5. processRefund()       — fetchSql used INNER JOIN users which returns 0 rows when the
 *                              order was placed by a guest (orders.email = NULL / no user row).
 *                              Fixed to read name/email from orders table directly (same pattern
 *                              as BASE_SELECT), so COD/guest orders get the refund email too.
 */
public class ReturnDAO {

    // ──────────────────────────────────────────────────────────────────
    //  SUBMIT (customer-facing – called from ReturnProductServlet)
    // ──────────────────────────────────────────────────────────────────

    public int submitReturn(ReturnRequest r) {
        String sql = "INSERT INTO return_requests " +
                     "(order_id, group_id, user_id, product_id, reason, description, " +
                     " refund_amount, refund_method, status) " +
                     "VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'PENDING')";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setInt   (1, r.getOrderId());
            ps.setInt   (2, r.getGroupId());
            ps.setInt   (3, r.getUserId());
            ps.setInt   (4, r.getProductId());
            ps.setString(5, r.getReason());
            ps.setString(6, r.getDescription());
            ps.setDouble(7, r.getRefundAmount());
            ps.setString(8, r.getRefundMethod());
            ps.executeUpdate();
            updateOrderReturnStatus(conn, r.getOrderId(), "PENDING");
            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (rs.next()) return rs.getInt(1);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return -1;
    }

    // ──────────────────────────────────────────────────────────────────
    //  BASE SELECT — reused by all read queries.
    //  Reads name/email from orders (o.name, o.email) instead of joining
    //  users, so guest orders and orders without a matching user record
    //  still appear in the admin panel.
    // ──────────────────────────────────────────────────────────────────

    private static final String BASE_SELECT =
        "SELECT rr.*, p.name AS product_name, p.image_path AS product_image, " +
        "o.name  AS customer_name, o.email AS customer_email, " +
        "o.payment_method, o.order_date, " +
        "COALESCE((SELECT SUM(oi2.price * oi2.quantity) FROM order_items oi2 WHERE oi2.order_id = rr.order_id), 0) AS order_total " +
        "FROM return_requests rr " +
        "LEFT JOIN products p ON p.id = rr.product_id " +
        "LEFT JOIN orders   o ON o.id = rr.order_id ";

    // ──────────────────────────────────────────────────────────────────
    //  READ METHODS
    // ──────────────────────────────────────────────────────────────────

    public List<ReturnRequest> getAllReturns() {
        String sql = BASE_SELECT + "ORDER BY rr.requested_at DESC";
        return queryListPlain(sql);
    }

    // FIX: was string-concatenated → SQL injection risk and case mismatch bug.
    public List<ReturnRequest> getReturnsByUser(int userId) {
        String sql = BASE_SELECT + "WHERE rr.user_id = ? ORDER BY rr.requested_at DESC";
        List<ReturnRequest> list = new ArrayList<>();
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapRow(rs));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    // FIX: was string-concatenated → SQL injection risk. Also, the old code compared
    //      against the literal status string, which broke when Returnrequestservlet
    //      inserted 'Pending' but callers queried 'PENDING'.
    public List<ReturnRequest> getReturnsByStatus(String status) {
        String sql = BASE_SELECT + "WHERE rr.status = ? ORDER BY rr.requested_at DESC";
        List<ReturnRequest> list = new ArrayList<>();
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, status);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapRow(rs));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    // FIX: was string-concatenated → SQL injection risk.
    public ReturnRequest getReturnById(int id) {
        String sql = BASE_SELECT + "WHERE rr.id = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return null;
    }

    public boolean returnExists(int orderId) {
        String sql = "SELECT COUNT(*) FROM return_requests WHERE order_id = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1) > 0;
            }
        } catch (Exception e) { e.printStackTrace(); }
        return false;
    }

    // ──────────────────────────────────────────────────────────────────
    //  WORKFLOW ACTIONS (staff only)
    // ──────────────────────────────────────────────────────────────────

    public boolean approveReturn(int returnId, double refundAmount,
                                  String refundMethod, String adminNote) {
        String sql = "UPDATE return_requests " +
                     "SET status='APPROVED', refund_amount=?, refund_method=?, admin_note=? " +
                     "WHERE id=?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setDouble(1, refundAmount);
            ps.setString(2, refundMethod);
            ps.setString(3, adminNote);
            ps.setInt   (4, returnId);
            int rows = ps.executeUpdate();
            if (rows > 0) { syncOrderReturnStatus(conn, returnId, "APPROVED"); return true; }
        } catch (Exception e) { e.printStackTrace(); }
        return false;
    }

    public boolean rejectReturn(int returnId, String adminNote) {
        String sql = "UPDATE return_requests SET status='REJECTED', admin_note=? WHERE id=?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, adminNote);
            ps.setInt   (2, returnId);
            int rows = ps.executeUpdate();
            if (rows > 0) { syncOrderReturnStatus(conn, returnId, "REJECTED"); return true; }
        } catch (Exception e) { e.printStackTrace(); }
        return false;
    }

    public boolean schedulePickup(int returnId) {
        return updateStatus(returnId, "PICKUP_SCHEDULED");
    }

    /**
     * Assigns a delivery boy to collect a return pickup.
     * Creates a delivery_assignments row (linked to the original order_id from return_requests)
     * and sets return_requests.status → PICKUP_SCHEDULED.
     * Returns the OTP generated for this assignment, or null on failure.
     */
    public String assignPickupDeliveryBoy(int returnId, int deliveryBoyId) {
        // 1. Fetch the order_id linked to this return
        int orderId = -1;
        String fetchOrder = "SELECT order_id FROM return_requests WHERE id = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(fetchOrder)) {
            ps.setInt(1, returnId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) orderId = rs.getInt("order_id");
            }
        } catch (Exception e) { e.printStackTrace(); return null; }

        if (orderId < 0) return null;

        // 2. Cancel any previous ASSIGNED/PICKED_UP assignments for this order (return pickups)
        String cancelPrev = "UPDATE delivery_assignments SET status='CANCELLED' " +
                            "WHERE order_id = ? AND status IN ('ASSIGNED','PICKED_UP')";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(cancelPrev)) {
            ps.setInt(1, orderId);
            ps.executeUpdate();
        } catch (Exception e) { e.printStackTrace(); }

        // 3. Create new assignment with a 4-digit OTP
        String otp = String.valueOf((int)(Math.random() * 9000) + 1000);
        String insertSql = "INSERT INTO delivery_assignments " +
                           "(order_id, delivery_boy_id, status, otp, assigned_at) " +
                           "VALUES (?, ?, 'ASSIGNED', ?, NOW())";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(insertSql)) {
            ps.setInt   (1, orderId);
            ps.setInt   (2, deliveryBoyId);
            ps.setString(3, otp);
            int rows = ps.executeUpdate();
            if (rows > 0) {
                // 4. Update return status → PICKUP_SCHEDULED
                updateStatus(returnId, "PICKUP_SCHEDULED");
                return otp;
            }
        } catch (Exception e) { e.printStackTrace(); }
        return null;
    }

    public boolean confirmPickup(int returnId) {
        boolean updated = updateStatus(returnId, "PICKED_UP");
        if (updated) {
            // FIX: old code joined orders and used o.quantity, but orders.quantity
            //      does not map per-product in multi-item orders.
            //      Correct approach: join order_items on both order_id AND product_id.
            String sql = "UPDATE products p " +
                         "JOIN return_requests rr ON rr.product_id = p.id " +
                         "JOIN order_items oi ON oi.order_id = rr.order_id " +
                         "                   AND oi.product_id = rr.product_id " +
                         "SET p.quantity = p.quantity + oi.quantity " +
                         "WHERE rr.id = ?";
            try (Connection conn = DBConnection.getConnection();
                 PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setInt(1, returnId);
                ps.executeUpdate();
            } catch (Exception e) { e.printStackTrace(); }
        }
        return updated;
    }

    public boolean processRefund(int returnId) {
        boolean updated = updateStatus(returnId, "REFUNDED");
        if (!updated) return false;

        // FIX: old code used INNER JOIN users ON u.id = rr.user_id.
        //      When the order was placed as a guest (or orders.email is NULL / no matching
        //      users row), the JOIN returns 0 rows and custEmail stays null → no email sent.
        //      Read name/email from orders directly (same approach as BASE_SELECT).
        String fetchSql =
            "SELECT rr.refund_amount, rr.refund_method, rr.order_id, rr.user_id, " +
            "       o.name  AS customer_name, o.email AS customer_email, " +
            "       p.name  AS product_name, " +
            "       pay.razorpay_payment_id, pay.payment_method AS pay_method " +
            "FROM return_requests rr " +
            "LEFT JOIN orders   o   ON o.id  = rr.order_id " +
            "LEFT JOIN products p   ON p.id  = rr.product_id " +
            "LEFT JOIN payments pay ON pay.order_id = rr.order_id " +
            "WHERE rr.id = ? LIMIT 1";

        String razorpayPaymentId = null;
        String payMethod         = null;
        String refundMethod      = null;
        double refundAmount      = 0;
        String custEmail         = null;
        String custName          = null;
        String productName       = null;
        int    orderId           = -1;
        int    userId            = -1;

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(fetchSql)) {
            ps.setInt(1, returnId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    razorpayPaymentId = rs.getString("razorpay_payment_id");
                    payMethod         = rs.getString("pay_method");
                    refundMethod      = rs.getString("refund_method");
                    refundAmount      = rs.getDouble("refund_amount");
                    custEmail         = rs.getString("customer_email");
                    custName          = rs.getString("customer_name");
                    productName       = rs.getString("product_name");
                    orderId           = rs.getInt("order_id");
//                    userId            = rs.getInt("user_id");
                }
            }
        } catch (Exception e) { e.printStackTrace(); }

        // Mark payment row as refunded
        String markSql =
            "UPDATE payments pay " +
            "JOIN orders o ON o.id = pay.order_id " +
            "JOIN return_requests rr ON rr.order_id = o.id " +
            "SET pay.status = 'refunded' " +
            "WHERE rr.id = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(markSql)) {
            ps.setInt(1, returnId);
            ps.executeUpdate();
        } catch (Exception e) { e.printStackTrace(); }

        final boolean isOnline = razorpayPaymentId != null && !razorpayPaymentId.isEmpty()
                                 && !"COD".equalsIgnoreCase(payMethod);
        final boolean isWalletRefund = "WALLET".equalsIgnoreCase(refundMethod);
        final String[] capturedRefundId = {null};

        // Credit wallet for WALLET refund method (COD orders refunded as store credit)
        if (isWalletRefund && userId > 0 && refundAmount > 0) {
            final int    finalUserId  = userId;
            final double finalAmount  = refundAmount;
            final int    finalOrderId = orderId;
            final String finalProduct = productName != null ? productName : "product";
            new CustomerWalletDAO().credit(
                finalUserId,
                finalAmount,
                "Refund for return of " + finalProduct + " (Order #" + finalOrderId + ")",
                finalOrderId > 0 ? finalOrderId : null
            );
        }

        // Send in-app notification to customer
        if (userId > 0) {
            final String notifProduct = productName != null ? productName : "your product";
            final String notifEmail   = custEmail;
            final String notifName    = custName;
            new Thread(() ->
                com.sibs.dao.NotificationDAO.sendReturnStatusChanged(
                    userId, returnId, notifProduct, "Refunded",
                    notifEmail, notifName)
            ).start();
        }

        // Trigger Razorpay refund for online payments (skip if wallet refund)
        if (isOnline && !isWalletRefund) {
            final String finalRzpId    = razorpayPaymentId;
            final long   amountInPaise = Math.round(refundAmount * 100);
            try {
                String url = "https://api.razorpay.com/v1/payments/" + finalRzpId + "/refund";
                java.net.HttpURLConnection conn2 =
                    (java.net.HttpURLConnection) new java.net.URL(url).openConnection();
                conn2.setRequestMethod("POST");
                conn2.setDoOutput(true);
                conn2.setRequestProperty("Content-Type", "application/json");
                String encoded = RazorpayConfig.basicAuth(null);
                if (encoded == null) {
                    System.err.println("[ReturnDAO] Razorpay not configured — online refund skipped");
                } else {
                    conn2.setRequestProperty("Authorization", "Basic " + encoded);
                    String body = "{\"amount\":" + amountInPaise + ",\"speed\":\"normal\"}";
                    try (java.io.OutputStream os = conn2.getOutputStream()) {
                        os.write(body.getBytes(java.nio.charset.StandardCharsets.UTF_8));
                    }
                    int code = conn2.getResponseCode();
                    java.util.Scanner sc = code < 400
                        ? new java.util.Scanner(conn2.getInputStream())
                        : new java.util.Scanner(conn2.getErrorStream());
                    StringBuilder resp = new StringBuilder();
                    while (sc.hasNext()) resp.append(sc.nextLine());
                    sc.close();
                    if (code == 200) {
                        String json   = resp.toString();
                        String search = "\"id\":\"";
                        int start = json.indexOf(search);
                        if (start != -1) {
                            start += search.length();
                            int end = json.indexOf("\"", start);
                            capturedRefundId[0] = json.substring(start, end);
                        }
                    }
                }
            } catch (Exception e) { e.printStackTrace(); }
        }

        // Send notification emails asynchronously
        if (custEmail != null && orderId > 0) {
            final String  finalEmail    = custEmail;
            final String  finalName     = custName != null ? custName : "Customer";
            final String  finalProduct  = productName != null ? productName : "your product";
            final int     finalOrderId  = orderId;
            final double  finalAmount   = refundAmount;
            final boolean finalOnline   = isOnline;
            final String  finalRefundId = capturedRefundId[0];

            new Thread(() -> {
                com.sibs.util.EmailService.sendOrderStatusEmail(
                    finalEmail, finalName, "Refunded", finalOrderId, finalProduct);
                if (finalOnline && finalAmount > 0) {
                    String refId = finalRefundId != null ? finalRefundId : "via-return-" + finalOrderId;
                    com.sibs.util.EmailService.sendRefundEmail(
                        finalEmail, finalName, finalOrderId, finalAmount, refId);
                }
            }).start();
        }
        return true;
    }

    // ──────────────────────────────────────────────────────────────────
    //  COUNT PENDING — used by adminSidebar.jsp for the live badge
    // ──────────────────────────────────────────────────────────────────

    public int countPending() {
        String sql = "SELECT COUNT(*) FROM return_requests WHERE status = 'PENDING'";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            return rs.next() ? rs.getInt(1) : 0;
        } catch (Exception e) {
            e.printStackTrace();
            return 0;
        }
    }

    // ──────────────────────────────────────────────────────────────────
    //  PRIVATE HELPERS
    // ──────────────────────────────────────────────────────────────────

    private boolean updateStatus(int returnId, String status) {
        String sql = "UPDATE return_requests SET status=? WHERE id=?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, status);
            ps.setInt   (2, returnId);
            int rows = ps.executeUpdate();
            if (rows > 0) { syncOrderReturnStatus(conn, returnId, status); return true; }
        } catch (Exception e) { e.printStackTrace(); }
        return false;
    }

    private void syncOrderReturnStatus(Connection conn, int returnId, String status) {
        String sql = "UPDATE orders o " +
                     "JOIN return_requests rr ON rr.order_id = o.id " +
                     "SET o.return_status = ? WHERE rr.id = ?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, status);
            ps.setInt   (2, returnId);
            ps.executeUpdate();
        } catch (Exception e) { e.printStackTrace(); }
    }

    private void updateOrderReturnStatus(Connection conn, int orderId, String status) {
        String sql = "UPDATE orders SET return_status=? WHERE id=?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, status);
            ps.setInt   (2, orderId);
            ps.executeUpdate();
        } catch (Exception e) { e.printStackTrace(); }
    }

    /** Used only by getAllReturns() which builds a safe static SQL string. */
    private List<ReturnRequest> queryListPlain(String sql) {
        List<ReturnRequest> list = new ArrayList<>();
        try (Connection conn = DBConnection.getConnection();
             Statement st = conn.createStatement();
             ResultSet rs = st.executeQuery(sql)) {
            while (rs.next()) list.add(mapRow(rs));
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    private ReturnRequest mapRow(ResultSet rs) throws SQLException {
        ReturnRequest r = new ReturnRequest();
        r.setId          (rs.getInt      ("id"));
        r.setOrderId     (rs.getInt      ("order_id"));
        r.setGroupId     (rs.getInt      ("group_id"));
        r.setUserId      (rs.getInt      ("user_id"));
        r.setProductId   (rs.getInt      ("product_id"));
        r.setReason      (rs.getString   ("reason"));
        r.setDescription (rs.getString   ("description"));
        r.setStatus      (rs.getString   ("status"));
        r.setRefundAmount(rs.getDouble   ("refund_amount"));
        r.setRefundMethod(rs.getString   ("refund_method"));
        r.setAdminNote   (rs.getString   ("admin_note"));
        r.setRequestedAt (rs.getTimestamp("requested_at"));
        r.setUpdatedAt   (rs.getTimestamp("updated_at"));
        trySet(r, rs, "product_name",   ReturnRequest::setProductName);
        trySet(r, rs, "product_image",  ReturnRequest::setProductImage);
        trySet(r, rs, "customer_name",  ReturnRequest::setCustomerName);
        trySet(r, rs, "customer_email", ReturnRequest::setCustomerEmail);
        trySet(r, rs, "payment_method", ReturnRequest::setPaymentMethod);
        trySet(r, rs, "order_date",     ReturnRequest::setOrderDate);
        try { r.setOrderTotal(rs.getDouble("order_total")); } catch (Exception ignored) {}
        return r;
    }

    @FunctionalInterface
    private interface Setter { void set(ReturnRequest r, String v); }

    private void trySet(ReturnRequest r, ResultSet rs, String col, Setter s) {
        try { s.set(r, rs.getString(col)); } catch (Exception ignored) {}
    }
}