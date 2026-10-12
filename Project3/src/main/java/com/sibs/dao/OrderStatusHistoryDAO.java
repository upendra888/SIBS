package com.sibs.dao;

import com.sibs.util.DBConnection;

import java.sql.*;
import java.util.HashMap;
import java.util.Map;

/**
 * DAO for order_status_history table.
 *
 * SQL to create the table (run once in MySQL):
 * -----------------------------------------------
 * CREATE TABLE IF NOT EXISTS order_status_history (
 *     id         INT AUTO_INCREMENT PRIMARY KEY,
 *     group_id   INT         NOT NULL,
 *     status     VARCHAR(50) NOT NULL,
 *     changed_by VARCHAR(100),
 *     changed_at TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
 *     INDEX idx_osh_group (group_id)
 * );
 * -----------------------------------------------
 */
public class OrderStatusHistoryDAO {

    /**
     * Log a status change for every order row that shares the given group_id.
     * Inserts one row into order_status_history per call (the group is the
     * natural key — all items in a batch share the same lifecycle).
     *
     * @param groupId   the batch group id (same value stored in orders.group_id)
     * @param status    new status string e.g. "Placed", "Approved", "Delivered"
     * @param changedBy display name of the actor (customer name, staff name, "System")
     */
    public void logByGroup(int groupId, String status, String changedBy) {
        String sql = "INSERT INTO order_status_history (group_id, status, changed_by) VALUES (?, ?, ?)";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, groupId);
            ps.setString(2, status);
            ps.setString(3, changedBy != null ? changedBy : "System");
            ps.executeUpdate();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    /**
     * Return the timestamp of the FIRST time each status was logged for this group.
     * Key   = status string (e.g. "Placed", "Approved", "Assigned", "Picked", "Delivered")
     * Value = formatted date-time string "dd MMM, HH:mm" (e.g. "28 Apr, 14:32")
     *
     * Only the earliest entry per status is kept so the timeline always shows
     * when a stage was first reached, not any later re-entries.
     */
    public Map<String, String> getHistoryByGroup(int groupId) {
        Map<String, String> map = new HashMap<>();
        String sql =
            "SELECT status, MIN(changed_at) AS first_at " +
            "FROM order_status_history " +
            "WHERE group_id = ? " +
            "GROUP BY status";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, groupId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Timestamp ts = rs.getTimestamp("first_at");
                    if (ts != null) {
                        // Format: "28 Apr, 14:32"
                        java.text.SimpleDateFormat sdf =
                            new java.text.SimpleDateFormat("dd MMM, HH:mm");
                        map.put(rs.getString("status"), sdf.format(ts));
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return map;
    }
}