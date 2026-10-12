package com.sibs.dao;

import com.sibs.model.StaffLeave;
import com.sibs.util.DBConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * Data-access layer for staff_leave_applications.
 */
public class StaffLeaveDAO {

    // ── Row mapper ───────────────────────────────────────────────────────

    private StaffLeave map(ResultSet rs) throws SQLException {
        StaffLeave l = new StaffLeave();
        l.setLeaveId(rs.getInt("leave_id"));
        l.setEmployeeId(rs.getInt("employee_id"));
        l.setLeaveType(rs.getString("leave_type"));
        l.setFromDate(rs.getDate("from_date"));
        l.setToDate(rs.getDate("to_date"));
        l.setReason(rs.getString("reason"));
        l.setStatus(rs.getString("status"));
        l.setAdminRemarks(rs.getString("admin_remarks"));
        l.setAppliedOn(rs.getTimestamp("applied_on"));
        l.setActionedOn(rs.getTimestamp("actioned_on"));
        l.setActionedBy(rs.getInt("actioned_by"));
        // employee_name comes from a JOIN — present only in list queries
        try { l.setEmployeeName(rs.getString("employee_name")); }
        catch (SQLException ignored) {}
        return l;
    }

    // ── Staff: apply for leave ───────────────────────────────────────────

    /**
     * Submit a new leave application.
     * Returns true on success.
     */
    public boolean applyLeave(int employeeId, String leaveType,
                               String fromDate, String toDate, String reason) {
        String sql = "INSERT INTO staff_leave_applications " +
                     "(employee_id, leave_type, from_date, to_date, reason) " +
                     "VALUES (?, ?, ?, ?, ?)";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, employeeId);
            ps.setString(2, leaveType);
            ps.setDate(3, Date.valueOf(fromDate));
            ps.setDate(4, Date.valueOf(toDate));
            ps.setString(5, reason);
            return ps.executeUpdate() == 1;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    // ── Staff: view own leave history ────────────────────────────────────

    public List<StaffLeave> getByEmployee(int employeeId) {
        String sql = "SELECT * FROM staff_leave_applications " +
                     "WHERE employee_id = ? ORDER BY applied_on DESC";
        List<StaffLeave> list = new ArrayList<>();
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, employeeId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) list.add(map(rs));
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    /**
     * Count pending leaves for a specific employee (used for badge display).
     */
    public int countPending(int employeeId) {
        String sql = "SELECT COUNT(*) FROM staff_leave_applications " +
                     "WHERE employee_id = ? AND status = 'PENDING'";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, employeeId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return rs.getInt(1);
        } catch (Exception e) {
            e.printStackTrace();
        }
        return 0;
    }

    // ── Admin: view all applications ─────────────────────────────────────

    /**
     * All applications, newest first, with employee name joined.
     * Pass statusFilter = null to return all statuses.
     */
    public List<StaffLeave> getAll(String statusFilter) {
        StringBuilder sql = new StringBuilder(
            "SELECT la.*, u.username AS employee_name " +
            "FROM staff_leave_applications la " +
            "LEFT JOIN users u ON u.id = la.employee_id "
        );
        if (statusFilter != null && !statusFilter.isEmpty()) {
            sql.append("WHERE la.status = ? ");
        }
        sql.append("ORDER BY la.applied_on DESC");

        List<StaffLeave> list = new ArrayList<>();
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql.toString())) {
            if (statusFilter != null && !statusFilter.isEmpty()) {
                ps.setString(1, statusFilter);
            }
            ResultSet rs = ps.executeQuery();
            while (rs.next()) list.add(map(rs));
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    /**
     * Count all PENDING applications (used for admin badge).
     */
    public int countAllPending() {
        String sql = "SELECT COUNT(*) FROM staff_leave_applications WHERE status = 'PENDING'";
        try (Connection con = DBConnection.getConnection();
             Statement st = con.createStatement();
             ResultSet rs = st.executeQuery(sql)) {
            if (rs.next()) return rs.getInt(1);
        } catch (Exception e) {
            e.printStackTrace();
        }
        return 0;
    }

    // ── Admin: approve / reject ──────────────────────────────────────────

    /**
     * Approve or reject a leave application.
     * @param leaveId      application to update
     * @param newStatus    "APPROVED" or "REJECTED"
     * @param adminRemarks optional remarks from admin
     * @param adminId      id of the admin performing the action
     */
    public boolean updateStatus(int leaveId, String newStatus,
                                 String adminRemarks, int adminId) {
        String sql = "UPDATE staff_leave_applications " +
                     "SET status = ?, admin_remarks = ?, " +
                     "    actioned_on = NOW(), actioned_by = ? " +
                     "WHERE leave_id = ? AND status = 'PENDING'";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, newStatus);
            ps.setString(2, adminRemarks);
            ps.setInt(3, adminId);
            ps.setInt(4, leaveId);
            return ps.executeUpdate() == 1;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    // ── Staff: cancel a pending application ─────────────────────────────

    public boolean cancelLeave(int leaveId, int employeeId) {
        String sql = "DELETE FROM staff_leave_applications " +
                     "WHERE leave_id = ? AND employee_id = ? AND status = 'PENDING'";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, leaveId);
            ps.setInt(2, employeeId);
            return ps.executeUpdate() == 1;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }
}