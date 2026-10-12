package com.sibs.dao;

import com.sibs.util.DBConnection;
import java.sql.*;
import java.util.*;

/**
 * REMITTANCE LOGIC:
 *   Customer pays total COD (e.g. Rs.100)
 *   delivery_charge = company's COD fee (e.g. Rs.40)  <- company keeps this
 *   remittance_amount = product price (e.g. Rs.60)    <- deducted from boy's salary
 */
public class CodLedgerDAO {

    public static class CodEntry {
        public int    id, orderId, deliveryBoyId;
        public double amount;            // total COD collected from customer
        public double deliveryCharge;    // COD fee (company's earning)
        public double remittanceAmount;  // = amount - deliveryCharge (deducted from salary)
        public String status;            // COLLECTED | REMITTED | DISPUTED
        public String collectedAt, remittedAt, note;
        public String customerName, productName;
        public String riderName;
    }

    /** Record COD collection with delivery charge separation */
    public void recordCollection(int deliveryBoyId, int orderId,
                                 double totalAmount, double deliveryCharge) {
        double remittanceAmount = totalAmount - deliveryCharge;
        String sql = "INSERT INTO cod_ledger " +
                     "(delivery_boy_id, order_id, amount, delivery_charge, remittance_amount, status, collected_at) " +
                     "VALUES (?, ?, ?, ?, ?, 'COLLECTED', NOW()) " +
                     "ON DUPLICATE KEY UPDATE " +
                     "  amount=VALUES(amount), " +
                     "  delivery_charge=VALUES(delivery_charge), " +
                     "  remittance_amount=VALUES(remittance_amount), " +
                     "  status='COLLECTED', collected_at=NOW()";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, deliveryBoyId);
            ps.setInt(2, orderId);
            ps.setDouble(3, totalAmount);
            ps.setDouble(4, deliveryCharge);
            ps.setDouble(5, remittanceAmount);
            ps.executeUpdate();
        } catch (Exception e) { e.printStackTrace(); }
    }

    /** Backward-compatible overload — no delivery charge */
    public void recordCollection(int deliveryBoyId, int orderId, double totalAmount) {
        recordCollection(deliveryBoyId, orderId, totalAmount, 0.0);
    }

    /** Mark one entry as REMITTED */
    public boolean markRemitted(int ledgerId, int deliveryBoyId, String note) {
        String sql = "UPDATE cod_ledger SET status='REMITTED', remitted_at=NOW(), note=? " +
                     "WHERE id=? AND delivery_boy_id=? AND status='COLLECTED'";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, note);
            ps.setInt(2, ledgerId);
            ps.setInt(3, deliveryBoyId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    /** Admin bulk settle: marks ALL COLLECTED entries for a boy as REMITTED */
    public int bulkMarkRemitted(int deliveryBoyId, String note) {
        String sql = "UPDATE cod_ledger SET status='REMITTED', remitted_at=NOW(), note=? " +
                     "WHERE delivery_boy_id=? AND status='COLLECTED'";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, note);
            ps.setInt(2, deliveryBoyId);
            return ps.executeUpdate();
        } catch (Exception e) { e.printStackTrace(); return 0; }
    }

    /** Get all COD entries for a delivery boy */
    public List<CodEntry> getByDeliveryBoy(int deliveryBoyId) {
        List<CodEntry> list = new ArrayList<>();
        String sql =
            "SELECT cl.*, o.name AS cname, p.name AS pname " +
            "FROM cod_ledger cl " +
            "JOIN orders o ON o.id = cl.order_id " +
            "LEFT JOIN products p ON p.id = o.product_id " +
            "WHERE cl.delivery_boy_id = ? " +
            "ORDER BY cl.collected_at DESC";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, deliveryBoyId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) list.add(mapRow(rs, deliveryBoyId));
        } catch (Exception ex) { ex.printStackTrace(); }
        return list;
    }

    /** Total cash physically held by delivery boy */
    public double getPendingTotal(int deliveryBoyId) {
        return queryDouble(
            "SELECT COALESCE(SUM(amount),0) FROM cod_ledger WHERE delivery_boy_id=? AND status='COLLECTED'",
            deliveryBoyId);
    }

    /** Total remittance to deduct from salary (product amount only, no delivery charge) */
    public double getPendingRemittanceTotal(int deliveryBoyId) {
        return queryDouble(
            "SELECT COALESCE(SUM(remittance_amount),0) FROM cod_ledger WHERE delivery_boy_id=? AND status='COLLECTED'",
            deliveryBoyId);
    }

    /** Total delivery charges earned by boy from COD orders (all statuses) */
    public double getTotalDeliveryChargeEarned(int deliveryBoyId) {
        return queryDouble(
            "SELECT COALESCE(SUM(delivery_charge),0) FROM cod_ledger WHERE delivery_boy_id=?",
            deliveryBoyId);
    }

    /** Total remittance already deducted */
    public double getRemittedTotal(int deliveryBoyId) {
        return queryDouble(
            "SELECT COALESCE(SUM(remittance_amount),0) FROM cod_ledger WHERE delivery_boy_id=? AND status='REMITTED'",
            deliveryBoyId);
    }

    /** Total delivery charges (₹40 each) from REMITTED entries — reduces boy's net earning */
    public double getRemittedDeliveryCharges(int deliveryBoyId) {
        return queryDouble(
            "SELECT COALESCE(SUM(delivery_charge),0) FROM cod_ledger WHERE delivery_boy_id=? AND status='REMITTED'",
            deliveryBoyId);
    }

    /** Summary: [totalCashHeld, totalDeliveryCharge, totalRemittanceDue] */
    public double[] getRemittanceSummary(int deliveryBoyId) {
        String sql =
            "SELECT COALESCE(SUM(amount),0) AS tc, " +
            "       COALESCE(SUM(delivery_charge),0) AS tdc, " +
            "       COALESCE(SUM(remittance_amount),0) AS tr " +
            "FROM cod_ledger WHERE delivery_boy_id=? AND status='COLLECTED'";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, deliveryBoyId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return new double[]{
                rs.getDouble("tc"), rs.getDouble("tdc"), rs.getDouble("tr")};
        } catch (Exception e) { e.printStackTrace(); }
        return new double[]{0, 0, 0};
    }

    /** Admin: all COLLECTED entries across all riders */
    public List<CodEntry> getAllPending() {
        List<CodEntry> list = new ArrayList<>();
        String sql =
            "SELECT cl.*, db.name AS rider_name, o.name AS cname " +
            "FROM cod_ledger cl " +
            "JOIN delivery_boys db ON db.id = cl.delivery_boy_id " +
            "JOIN orders o ON o.id = cl.order_id " +
            "WHERE cl.status = 'COLLECTED' " +
            "ORDER BY cl.collected_at DESC";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                CodEntry e = mapRow(rs, rs.getInt("delivery_boy_id"));
                e.riderName = rs.getString("rider_name");
                list.add(e);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    /** Admin: remittance summary grouped by delivery boy */
    public List<Map<String, Object>> getAdminRemittanceSummary() {
        List<Map<String, Object>> result = new ArrayList<>();
        String sql =
            "SELECT db.id AS delivery_boy_id, db.name AS rider_name, " +
            "       COUNT(cl.id) AS orders_count, " +
            "       COALESCE(SUM(cl.amount),0) AS cash_held, " +
            "       COALESCE(SUM(cl.delivery_charge),0) AS delivery_charge_total, " +
            "       COALESCE(SUM(cl.remittance_amount),0) AS remittance_due " +
            "FROM delivery_boys db " +
            "LEFT JOIN cod_ledger cl ON cl.delivery_boy_id = db.id AND cl.status = 'COLLECTED' " +
            "GROUP BY db.id, db.name " +
            "HAVING remittance_due > 0 " +
            "ORDER BY remittance_due DESC";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                Map<String, Object> row = new LinkedHashMap<>();
                row.put("deliveryBoyId",       rs.getInt("delivery_boy_id"));
                row.put("riderName",           rs.getString("rider_name"));
                row.put("ordersCount",         rs.getInt("orders_count"));
                row.put("cashHeld",            rs.getDouble("cash_held"));
                row.put("deliveryChargeTotal", rs.getDouble("delivery_charge_total"));
                row.put("remittanceDue",       rs.getDouble("remittance_due"));
                result.add(row);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return result;
    }

    private CodEntry mapRow(ResultSet rs, int deliveryBoyId) throws SQLException {
        CodEntry e = new CodEntry();
        e.id               = rs.getInt("id");
        e.orderId          = rs.getInt("order_id");
        e.deliveryBoyId    = deliveryBoyId;
        e.amount           = rs.getDouble("amount");
        e.deliveryCharge   = rs.getDouble("delivery_charge");
        e.remittanceAmount = rs.getDouble("remittance_amount");
        e.status           = rs.getString("status");
        e.collectedAt      = rs.getString("collected_at");
        e.remittedAt       = rs.getString("remitted_at");
        e.note             = rs.getString("note");
        try { e.customerName = rs.getString("cname"); } catch (Exception ignored) {}
        try { e.productName  = rs.getString("pname"); } catch (Exception ignored) {}
        return e;
    }

    private double queryDouble(String sql, int param) {
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, param);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return rs.getDouble(1);
        } catch (Exception e) { e.printStackTrace(); }
        return 0;
    }
}