package com.sibs.dao;

import com.sibs.model.SupportComplaint;
import com.sibs.util.DBConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * SupportComplaintDAO
 *
 * Flowchart coverage:
 *  - Customer raises complaint           → insert()
 *  - Staff reviews ticket                → updateStatus()
 *  - Staff checks order / delivery       → getByIdWithDetails()
 *  - Staff decides verdict (fraud/genuine) → resolveComplaint()
 *  - Customer sees "Under Review"        → getByUserId()
 *  - Customer sees "Resolved"            → getByUserId()
 *  - Staff list all open tickets         → getAllOpen(), getAll()
 *
 * NOTE: The SIBS schema stores order line-items directly in the `orders`
 *       table (each row = one product; rows sharing a group_id form one
 *       order group).  There is NO separate `order_items` table.
 *       The join therefore goes through `orders` using group_id.
 */
public class SupportComplaintDAO {

    // ── shared SELECT fragment ─────────────────────────────────────────────
    private static final String SELECT_BASE =
        "SELECT sc.*, "
      + "  u.username  AS customer_name, "
      + "  u.phone     AS customer_phone, "
      + "  db.name     AS delivery_boy_name, "
      + "  db.phone    AS delivery_boy_phone, "
      + "  sc.order_id AS order_group_id, "
      + "  GROUP_CONCAT(DISTINCT p.name ORDER BY p.name SEPARATOR ', ') AS order_products "
      + "FROM support_complaints sc "
      + "JOIN  users         u  ON u.id  = sc.user_id "
      + "LEFT JOIN delivery_boys db ON db.id = sc.delivery_boy_id "
      + "LEFT JOIN orders    oi ON oi.group_id = sc.order_id "
      + "LEFT JOIN products  p  ON p.id = oi.product_id ";

    /* ── 1. Customer raises complaint ───────────────────────────────────── */
    public int insert(SupportComplaint c) throws SQLException {
        String sql = "INSERT INTO support_complaints "
                   + "(user_id, order_id, issue_type, description, photo_path, status, delivery_boy_id) "
                   + "VALUES (?, ?, ?, ?, ?, 'OPEN', ?)";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setInt(1, c.getUserId());
            setNullableInt(ps, 2, c.getOrderId());
            ps.setString(3, c.getIssueType());
            ps.setString(4, c.getDescription());
            ps.setString(5, c.getPhotoPath());
            setNullableInt(ps, 6, c.getDeliveryBoyId());
            ps.executeUpdate();
            try (ResultSet rs = ps.getGeneratedKeys()) {
                return rs.next() ? rs.getInt(1) : -1;
            }
        }
    }

    /* ── 2. Customer: view own complaints (past complaints panel) ───────── */
    public List<SupportComplaint> getByUserId(int userId) throws SQLException {
        String sql = SELECT_BASE
                   + "WHERE sc.user_id = ? "
                   + "GROUP BY sc.id "
                   + "ORDER BY sc.created_at DESC";
        return query(sql, userId);
    }

    /* ── 3. Staff: all open / under-review tickets ──────────────────────── */
    public List<SupportComplaint> getAllOpen() throws SQLException {
        return queryNoParam(
            SELECT_BASE
          + "WHERE sc.status IN ('OPEN','UNDER_REVIEW') "
          + "GROUP BY sc.id ORDER BY sc.created_at ASC");
    }

    /* ── 4. Staff: all tickets (history / report view) ──────────────────── */
    public List<SupportComplaint> getAll() throws SQLException {
        return queryNoParam(
            SELECT_BASE
          + "GROUP BY sc.id ORDER BY sc.created_at DESC");
    }

    /* ── 5. Staff: fetch one ticket with full details ───────────────────── */
    public SupportComplaint getByIdWithDetails(int id) throws SQLException {
        String sql = SELECT_BASE
                   + "WHERE sc.id = ? GROUP BY sc.id";
        List<SupportComplaint> list = query(sql, id);
        return list.isEmpty() ? null : list.get(0);
    }

    /* ── 6. Staff: change status (OPEN → UNDER_REVIEW) ─────────────────── */
    public boolean updateStatus(int id, String status, String staffNotes) throws SQLException {
        String sql = "UPDATE support_complaints SET status=?, staff_notes=?, updated_at=NOW() WHERE id=?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, status);
            ps.setString(2, staffNotes);
            ps.setInt(3, id);
            return ps.executeUpdate() > 0;
        }
    }

    /* ── 7. Staff: final verdict ─────────────────────────────────────────
     *   verdict = "GENUINE"  → status = RESOLVED  (re-deliver / refund)
     *   verdict = "FRAUD"    → status = CLOSED     (complaint rejected)
     * ──────────────────────────────────────────────────────────────────── */
    public boolean resolveComplaint(int id, String verdict, String staffNotes) throws SQLException {
        String status = "GENUINE".equalsIgnoreCase(verdict) ? "RESOLVED" : "CLOSED";
        String sql    = "UPDATE support_complaints "
                      + "SET status=?, staff_notes=?, resolved_at=NOW(), updated_at=NOW() "
                      + "WHERE id=?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, status);
            ps.setString(2, staffNotes);
            ps.setInt(3, id);
            return ps.executeUpdate() > 0;
        }
    }

    /* ── 8. Count open tickets (dashboard badge) ────────────────────────── */
    public int countOpen() throws SQLException {
        String sql = "SELECT COUNT(*) FROM support_complaints WHERE status IN ('OPEN','UNDER_REVIEW')";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            return rs.next() ? rs.getInt(1) : 0;
        }
    }

    // ─────────────────────────────────────────────────────────────────────
    // Private helpers
    // ─────────────────────────────────────────────────────────────────────

    private List<SupportComplaint> query(String sql, int param) throws SQLException {
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, param);
            return map(ps.executeQuery());
        }
    }

    private List<SupportComplaint> queryNoParam(String sql) throws SQLException {
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            return map(ps.executeQuery());
        }
    }

    private List<SupportComplaint> map(ResultSet rs) throws SQLException {
        List<SupportComplaint> list = new ArrayList<>();
        while (rs.next()) {
            SupportComplaint c = new SupportComplaint();
            c.setId(rs.getInt("id"));
            c.setUserId(rs.getInt("user_id"));
            c.setOrderId((Integer) rs.getObject("order_id"));
            c.setIssueType(rs.getString("issue_type"));
            c.setDescription(rs.getString("description"));
            c.setPhotoPath(rs.getString("photo_path"));
            c.setStatus(rs.getString("status"));
            c.setStaffNotes(rs.getString("staff_notes"));
            c.setDeliveryBoyId((Integer) rs.getObject("delivery_boy_id"));
            c.setCreatedAt(rs.getTimestamp("created_at"));
            c.setUpdatedAt(rs.getTimestamp("updated_at"));
            c.setResolvedAt(rs.getTimestamp("resolved_at"));
            // join fields
            c.setCustomerName(rs.getString("customer_name"));
            c.setCustomerPhone(rs.getString("customer_phone"));
            c.setDeliveryBoyName(rs.getString("delivery_boy_name"));
            c.setDeliveryBoyPhone(rs.getString("delivery_boy_phone"));
            c.setOrderProducts(rs.getString("order_products"));
            try { c.setOrderGroupId((Integer) rs.getObject("order_group_id")); } catch (Exception ignored) {}
            list.add(c);
        }
        return list;
    }

    private void setNullableInt(PreparedStatement ps, int idx, Integer val) throws SQLException {
        if (val == null) ps.setNull(idx, Types.INTEGER);
        else             ps.setInt(idx, val);
    }
}