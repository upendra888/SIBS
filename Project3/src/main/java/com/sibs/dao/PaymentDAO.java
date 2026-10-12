package com.sibs.dao;

import java.sql.*;
import java.util.*;
import com.sibs.model.Payment;
import com.sibs.util.DBConnection;

/**
 * PaymentDAO — handles all DB operations for the payments table.
 * Every method opens and closes its own connection (no shared state).
 */
public class PaymentDAO {

    // ─── 1. CREATE PENDING PAYMENT RECORD ─────────────────────────────────────
    public int createPayment(Payment payment) {

        String sql = "INSERT INTO payments "
                   + "(order_id, user_id, payment_method, amount, currency, "
                   + " razorpay_order_id, status) "
                   + "VALUES (?, ?, ?, ?, ?, ?, 'PENDING')";

        Connection con = null;
        PreparedStatement ps = null;
        ResultSet keys = null;

        try {
            con  = DBConnection.getConnection();
            ps   = con.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS);
            ps.setInt(1,    payment.getOrderId());
            ps.setInt(2,    payment.getUserId());
            ps.setString(3, payment.getPaymentMethod() != null
                            ? payment.getPaymentMethod() : "ONLINE");
            ps.setDouble(4, payment.getAmount());
            ps.setString(5, payment.getCurrency() != null
                            ? payment.getCurrency() : "INR");
            ps.setString(6, payment.getRazorpayOrderId());
            ps.executeUpdate();

            keys = ps.getGeneratedKeys();
            if (keys.next()) return keys.getInt(1);

        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            close(keys, ps, con);
        }
        return -1;
    }

    // ─── 2. MARK PAYMENT SUCCESS ───────────────────────────────────────────────
    public boolean markSuccess(int paymentId,
                                String razorpayPaymentId,
                                String razorpaySignature) {

        String sql = "UPDATE payments SET status='SUCCESS', "
                   + "razorpay_payment_id=?, razorpay_signature=? "
                   + "WHERE payment_id=?";

        Connection con = null;
        PreparedStatement ps = null;

        try {
            con = DBConnection.getConnection();
            ps  = con.prepareStatement(sql);
            ps.setString(1, razorpayPaymentId);
            ps.setString(2, razorpaySignature);
            ps.setInt(3,    paymentId);
            return ps.executeUpdate() > 0;

        } catch (Exception e) {
            e.printStackTrace();
            return false;
        } finally {
            close(null, ps, con);
        }
    }

    // ─── 3. MARK PAYMENT FAILED ────────────────────────────────────────────────
    public boolean markFailed(int paymentId, String reason) {

        String sql = "UPDATE payments SET status='FAILED', failure_reason=? "
                   + "WHERE payment_id=?";

        Connection con = null;
        PreparedStatement ps = null;

        try {
            con = DBConnection.getConnection();
            ps  = con.prepareStatement(sql);
            ps.setString(1, reason);
            ps.setInt(2,    paymentId);
            return ps.executeUpdate() > 0;

        } catch (Exception e) {
            e.printStackTrace();
            return false;
        } finally {
            close(null, ps, con);
        }
    }

    // ─── 4. GET PAYMENT BY ID ──────────────────────────────────────────────────
    public Payment getPaymentById(int paymentId) {

        String sql = "SELECT * FROM payments WHERE payment_id=?";
        Connection con = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            con = DBConnection.getConnection();
            ps  = con.prepareStatement(sql);
            ps.setInt(1, paymentId);
            rs  = ps.executeQuery();
            if (rs.next()) return mapPayment(rs);

        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            close(rs, ps, con);
        }
        return null;
    }

    // ─── 5. GET PAYMENT BY RAZORPAY ORDER ID ──────────────────────────────────
    public Payment getPaymentByRazorpayOrderId(String razorpayOrderId) {

        String sql = "SELECT * FROM payments WHERE razorpay_order_id=?";
        Connection con = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            con = DBConnection.getConnection();
            ps  = con.prepareStatement(sql);
            ps.setString(1, razorpayOrderId);
            rs  = ps.executeQuery();
            if (rs.next()) return mapPayment(rs);

        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            close(rs, ps, con);
        }
        return null;
    }

    // ─── 6. GET PAYMENT BY GROUP ID ───────────────────────────────────────────
    // ADDED: needed by CancelOrderServlet to find payment record for a group
    public Payment getPaymentByGroupId(int groupId) {

        String sql = "SELECT p.* FROM payments p "
                   + "JOIN orders o ON p.order_id = o.id "
                   + "WHERE o.group_id = ? AND p.status = 'SUCCESS' "
                   + "ORDER BY p.payment_id DESC LIMIT 1";
        Connection con = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            con = DBConnection.getConnection();
            ps  = con.prepareStatement(sql);
            ps.setInt(1, groupId);
            rs  = ps.executeQuery();
            if (rs.next()) return mapPayment(rs);

        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            close(rs, ps, con);
        }
        return null;
    }

    // ─── 7. GET ALL PAYMENTS FOR A USER (payment history) ────────────────────
    public List<Payment> getPaymentsByUser(int userId) {

        String sql = "SELECT * FROM payments WHERE user_id=? ORDER BY payment_date DESC";
        List<Payment> list = new ArrayList<>();
        Connection con = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            con = DBConnection.getConnection();
            ps  = con.prepareStatement(sql);
            ps.setInt(1, userId);
            rs  = ps.executeQuery();
            while (rs.next()) list.add(mapPayment(rs));

        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            close(rs, ps, con);
        }
        return list;
    }

    // ─── 8. GET ALL PAYMENTS (admin view) ─────────────────────────────────────
    public List<Payment> getAllPayments() {

        String sql = "SELECT * FROM payments ORDER BY payment_date DESC";
        List<Payment> list = new ArrayList<>();
        Connection con = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            con = DBConnection.getConnection();
            ps  = con.prepareStatement(sql);
            rs  = ps.executeQuery();
            while (rs.next()) list.add(mapPayment(rs));

        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            close(rs, ps, con);
        }
        return list;
    }

    // ─── 9. CHECK FOR DUPLICATE PAYMENT ───────────────────────────────────────
    public boolean isDuplicatePayment(String razorpayPaymentId) {

        String sql = "SELECT payment_id FROM payments "
                   + "WHERE razorpay_payment_id=? AND status='SUCCESS'";
        Connection con = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            con = DBConnection.getConnection();
            ps  = con.prepareStatement(sql);
            ps.setString(1, razorpayPaymentId);
            rs  = ps.executeQuery();
            return rs.next();

        } catch (Exception e) {
            e.printStackTrace();
            return false;
        } finally {
            close(rs, ps, con);
        }
    }

    // ─── 10. MARK REFUNDED (FIXED: now also stores refund_id from Razorpay) ───
    public boolean markRefunded(int paymentId, String refundId) {

        String sql = "UPDATE payments SET status='REFUNDED', refund_id=? WHERE payment_id=?";
        Connection con = null;
        PreparedStatement ps = null;

        try {
            con = DBConnection.getConnection();
            ps  = con.prepareStatement(sql);
            ps.setString(1, refundId);
            ps.setInt(2,    paymentId);
            return ps.executeUpdate() > 0;

        } catch (Exception e) {
            e.printStackTrace();
            return false;
        } finally {
            close(null, ps, con);
        }
    }

    // ─── HELPER: Map ResultSet → Payment ──────────────────────────────────────
    private Payment mapPayment(ResultSet rs) throws SQLException {
        Payment p = new Payment();
        p.setPaymentId(rs.getInt("payment_id"));
        p.setOrderId(rs.getInt("order_id"));
        p.setUserId(rs.getInt("user_id"));
        p.setPaymentMethod(rs.getString("payment_method"));
        p.setAmount(rs.getDouble("amount"));
        p.setCurrency(rs.getString("currency"));
        p.setRazorpayOrderId(rs.getString("razorpay_order_id"));
        p.setRazorpayPaymentId(rs.getString("razorpay_payment_id"));
        p.setRazorpaySignature(rs.getString("razorpay_signature"));
        p.setStatus(rs.getString("status"));
        p.setFailureReason(rs.getString("failure_reason"));
        p.setRefundId(rs.getString("refund_id"));
        p.setPaymentDate(rs.getTimestamp("payment_date"));
        p.setUpdatedAt(rs.getTimestamp("updated_at"));
        return p;
    }

    // ─── HELPER: Close resources ──────────────────────────────────────────────
    private void close(ResultSet rs, PreparedStatement ps, Connection con) {
        if (rs  != null) try { rs.close();  } catch (Exception e) {}
        if (ps  != null) try { ps.close();  } catch (Exception e) {}
        if (con != null) try { con.close(); } catch (Exception e) {}
    }
}