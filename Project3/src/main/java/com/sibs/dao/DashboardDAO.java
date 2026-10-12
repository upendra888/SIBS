package com.sibs.dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import com.sibs.util.DBConnection;

public class DashboardDAO {

    // ✅ FIXED: Removed shared instance fields (Connection con, PreparedStatement ps, ResultSet rs)
    // They were declared as instance variables, causing thread-safety issues under concurrent requests.
    // All variables are now local to each method, matching the pattern used in all other DAOs.

    // Total Products
    public int getTotalProducts() {
        int count = 0;
        Connection con = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            con = DBConnection.getConnection();
            ps  = con.prepareStatement("SELECT COUNT(*) FROM products");
            rs  = ps.executeQuery();
            if (rs.next()) {
                count = rs.getInt(1);
            }
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            close(rs, ps, con);
        }
        return count;
    }

    // Total Users
    public int getTotalUsers() {
        int count = 0;
        Connection con = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            con = DBConnection.getConnection();
            ps  = con.prepareStatement("SELECT COUNT(*) FROM users");
            rs  = ps.executeQuery();
            if (rs.next()) {
                count = rs.getInt(1);
            }
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            close(rs, ps, con);
        }
        return count;
    }

    // Total Sales — counts confirmed/paid orders
    public int getTotalSales() {
        int count = 0;
        Connection con = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            con = DBConnection.getConnection();
            ps  = con.prepareStatement(
                "SELECT COUNT(*) FROM orders WHERE payment_status='PAID' OR status='Confirmed'"
            );
            rs  = ps.executeQuery();
            if (rs.next()) {
                count = rs.getInt(1);
            }
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            close(rs, ps, con);
        }
        return count;
    }

    // Low Stock
    public int getLowStockCount() {
        int count = 0;
        Connection con = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            con = DBConnection.getConnection();
            ps  = con.prepareStatement("SELECT COUNT(*) FROM products WHERE quantity < 5");
            rs  = ps.executeQuery();
            if (rs.next()) {
                count = rs.getInt(1);
            }
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            close(rs, ps, con);
        }
        return count;
    }

    // ── Pending Orders (status = 'Pending') ──────────────────────────────────
    public int getPendingOrdersCount() {
        return countQuery("SELECT COUNT(DISTINCT group_id) FROM orders WHERE status='Pending'");
    }

    // ── Cancelled Orders (today) ──────────────────────────────────────────────
    public int getCancelledOrdersCount() {
        return countQuery("SELECT COUNT(DISTINCT group_id) FROM orders WHERE status='Cancelled' AND DATE(order_date)=CURDATE()");
    }

    // ── Delivery Boys Online ──────────────────────────────────────────────────
    public int getOnlineDeliveryBoysCount() {
        return countQuery("SELECT COUNT(*) FROM delivery_boys WHERE is_online=1 AND status='ACTIVE'");
    }

    // ── Active Deliveries (assigned, not yet delivered) ───────────────────────
    public int getActiveDeliveriesCount() {
        return countQuery("SELECT COUNT(*) FROM delivery_assignments WHERE status NOT IN ('Delivered','Cancelled','DELIVERED','CANCELLED')");
    }

    // ── Today's Delivery Slot Bookings ────────────────────────────────────────
    public int getTodaySlotsCount() {
        return countQuery("SELECT COUNT(*) FROM delivery_slot_bookings WHERE booking_date=CURDATE() AND status!='CANCELLED'");
    }

    // ── COD Pending Remittance ────────────────────────────────────────────────
    public int getPendingCodCount() {
        return countQuery("SELECT COUNT(*) FROM cod_ledger WHERE status='COLLECTED'");
    }

    // ── Unpaid Bills ─────────────────────────────────────────────────────────
    public int getUnpaidBillsCount() {
        return countQuery("SELECT COUNT(*) FROM bills WHERE paid=0 OR paid IS NULL");
    }

    // ── Today's Sales count ───────────────────────────────────────────────────
    public int getTodaySalesCount() {
        return countQuery("SELECT COUNT(DISTINCT group_id) FROM orders WHERE (payment_status='PAID' OR status='Confirmed') AND DATE(order_date)=CURDATE()");
    }

    // ── Staff Absent Today ────────────────────────────────────────────────────
    public int getAbsentStaffCount() {
        return countQuery(
            "SELECT COUNT(*) FROM users u " +
            "WHERE u.role='STAFF' AND u.status='ACTIVE' " +
            "AND u.id NOT IN (SELECT employee_id FROM staff_attendance WHERE attendance_date=CURDATE())"
        );
    }

    // ── Generic count helper ──────────────────────────────────────────────────
    private int countQuery(String sql) {
        int count = 0;
        Connection con = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            con = DBConnection.getConnection();
            ps  = con.prepareStatement(sql);
            rs  = ps.executeQuery();
            if (rs.next()) count = rs.getInt(1);
        } catch (Exception e) {
            // silently return 0 if table/column doesn't exist yet
        } finally {
            close(rs, ps, con);
        }
        return count;
    }

    // Helper: close resources
    private void close(ResultSet rs, PreparedStatement ps, Connection con) {
        if (rs  != null) try { rs.close();  } catch (Exception e) {}
        if (ps  != null) try { ps.close();  } catch (Exception e) {}
        if (con != null) try { con.close(); } catch (Exception e) {}
    }
}