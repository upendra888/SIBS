package com.sibs.dao;

import com.sibs.util.DBConnection;
import java.sql.*;
import java.util.*;

/**
 * SALARY FORMULA:
 *   Final Payout = Base Salary - Total Remittance Amount
 *
 * Example:
 *   Base Salary         = Rs.15,000
 *   Total COD collected = Rs.10,000 (cash boy holds)
 *   Delivery Charges    = Rs.4,000  (company income - NOT deducted)
 *   Total Remittance    = Rs.6,000  (product price only - deducted)
 *   Final Payout        = Rs.15,000 - Rs.6,000 = Rs.9,000
 */
public class DeliveryBoyEarningsDAO {

    public static class EarningsSummary {
        public int    deliveryBoyId;
        public String riderName;
        public double baseSalary;
        public double totalCashCollected;   // full COD cash boy holds
        public double totalDeliveryCharge;  // delivery fees (company income)
        public double totalRemittance;      // product amount deducted from salary
        public double finalPayout;          // baseSalary - totalRemittance
        public int    ordersCount;
        public String month;
    }

    /**
     * Preview settlement — calculate without saving anything
     */
    public EarningsSummary calculateSettlement(int deliveryBoyId, double baseSalary) {
        CodLedgerDAO ledgerDAO = new CodLedgerDAO();
        double[] summary = ledgerDAO.getRemittanceSummary(deliveryBoyId);

        EarningsSummary es     = new EarningsSummary();
        es.deliveryBoyId       = deliveryBoyId;
        es.baseSalary          = baseSalary;
        es.totalCashCollected  = summary[0];
        es.totalDeliveryCharge = summary[1];
        es.totalRemittance     = summary[2];
        es.finalPayout         = Math.max(baseSalary - summary[2], 0);
        return es;
    }

    /**
     * Process salary settlement:
     * 1. Calculate deductions
     * 2. Save to delivery_boy_earnings table
     * 3. Mark all pending COD entries as REMITTED
     */
    public EarningsSummary processSettlement(int deliveryBoyId, double baseSalary, String note) {
        EarningsSummary es = calculateSettlement(deliveryBoyId, baseSalary);

        String sql =
            "INSERT INTO delivery_boy_earnings " +
            "  (delivery_boy_id, month, base_salary, total_collected, total_deduction, final_payout, settled, settled_at) " +
            "VALUES (?, DATE_FORMAT(NOW(), '%Y-%m-01'), ?, ?, ?, ?, TRUE, NOW()) " +
            "ON DUPLICATE KEY UPDATE " +
            "  base_salary=VALUES(base_salary), " +
            "  total_collected=VALUES(total_collected), " +
            "  total_deduction=VALUES(total_deduction), " +
            "  final_payout=VALUES(final_payout), " +
            "  settled=TRUE, settled_at=NOW()";

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, deliveryBoyId);
            ps.setDouble(2, baseSalary);
            ps.setDouble(3, es.totalCashCollected);
            ps.setDouble(4, es.totalRemittance);
            ps.setDouble(5, es.finalPayout);
            ps.executeUpdate();
        } catch (Exception e) { e.printStackTrace(); }

        // Mark all COD entries as REMITTED
        new CodLedgerDAO().bulkMarkRemitted(deliveryBoyId, note);

        return es;
    }

    /**
     * Get earnings history for a delivery boy
     */
    public List<Map<String, Object>> getHistory(int deliveryBoyId) {
        List<Map<String, Object>> list = new ArrayList<>();
        String sql =
            "SELECT DATE_FORMAT(month, '%M %Y') AS month_label, " +
            "       base_salary, total_collected, total_deduction, final_payout, " +
            "       settled, settled_at " +
            "FROM delivery_boy_earnings " +
            "WHERE delivery_boy_id = ? " +
            "ORDER BY month DESC";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, deliveryBoyId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                Map<String, Object> row = new LinkedHashMap<>();
                row.put("month",          rs.getString("month_label"));
                row.put("baseSalary",     rs.getDouble("base_salary"));
                row.put("totalCollected", rs.getDouble("total_collected"));
                row.put("totalDeduction", rs.getDouble("total_deduction"));
                row.put("finalPayout",    rs.getDouble("final_payout"));
                row.put("settled",        rs.getBoolean("settled"));
                row.put("settledAt",      rs.getString("settled_at"));
                list.add(row);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    /**
     * Admin: preview settlement for ALL delivery boys
     */
    public List<EarningsSummary> getAllSettlementPreview() {
        List<EarningsSummary> list = new ArrayList<>();
        String sql =
            "SELECT db.id, db.name, " +
            "       COUNT(cl.id) AS orders_count, " +
            "       COALESCE(SUM(cl.amount),0) AS cash_held, " +
            "       COALESCE(SUM(cl.delivery_charge),0) AS dc_total, " +
            "       COALESCE(SUM(cl.remittance_amount),0) AS remittance_total " +
            "FROM delivery_boys db " +
            "LEFT JOIN cod_ledger cl ON cl.delivery_boy_id = db.id AND cl.status = 'COLLECTED' " +
            "GROUP BY db.id, db.name " +
            "HAVING remittance_total > 0 " +
            "ORDER BY db.name";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                EarningsSummary es     = new EarningsSummary();
                es.deliveryBoyId       = rs.getInt("id");
                es.riderName           = rs.getString("name");
                es.ordersCount         = rs.getInt("orders_count");
                es.totalCashCollected  = rs.getDouble("cash_held");
                es.totalDeliveryCharge = rs.getDouble("dc_total");
                es.totalRemittance     = rs.getDouble("remittance_total");
                list.add(es);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }
}