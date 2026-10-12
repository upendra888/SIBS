package com.sibs.dao;

import com.sibs.model.StaffAttendance;
import com.sibs.util.DBConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * Data-Access Object for the staff_attendance table.
 *
 * Changes in this version:
 *  - break_count column is incremented on each breakIn (max 2 per day).
 *  - breakIn() is blocked if break_count >= 2.
 *  - getTodayRecord() and map() now read break_count.
 */
public class StaffAttendanceDAO {

    // ── Working-hours status logic constants ─────────────────────────────────
    private static final int FULL_DAY_MINUTES  = 360;  // 6 h  → PRESENT
    private static final int HALF_DAY_MINUTES  = 240;  // 4 h  → HALF_DAY
    private static final int MAX_BREAKS        = 2;    // maximum breaks per shift

    // Run migration once per JVM lifetime (not per instance)
    private static volatile boolean columnChecked = false;

    public StaffAttendanceDAO() {
        if (!columnChecked) {
            synchronized (StaffAttendanceDAO.class) {
                if (!columnChecked) {
                    ensureBreakCountColumn();
                    columnChecked = true;
                }
            }
        }
    }

    // ── Row mapper ───────────────────────────────────────────────────────────
    private StaffAttendance map(ResultSet rs) throws SQLException {
        StaffAttendance a = new StaffAttendance();
        a.setAttendanceId(rs.getInt("attendance_id"));
        a.setEmployeeId(rs.getInt("employee_id"));
        a.setAttendanceDate(rs.getDate("attendance_date"));
        a.setCheckIn(rs.getTime("check_in"));
        a.setBreakIn(rs.getTime("break_in"));
        a.setBreakOut(rs.getTime("break_out"));
        a.setCheckOut(rs.getTime("check_out"));
        a.setTotalBreakTime(rs.getString("total_break_time"));
        a.setWorkingHours(rs.getString("working_hours"));
        a.setStatus(rs.getString("status"));
        try { a.setBreakCount(rs.getInt("break_count")); } catch (SQLException ignored) {}
        // employeeName only present when joined
        try { a.setEmployeeName(rs.getString("employee_name")); } catch (SQLException ignored) {}
        return a;
    }

    // ────────────────────────────────────────────────────────────────────────
    //  ENSURE break_count COLUMN EXISTS  (safe migration, run once per startup)
    // ────────────────────────────────────────────────────────────────────────
    public void ensureBreakCountColumn() {
        String check = "SELECT COUNT(*) FROM information_schema.COLUMNS " +
                       "WHERE TABLE_SCHEMA = DATABASE() " +
                       "AND TABLE_NAME = 'staff_attendance' " +
                       "AND COLUMN_NAME = 'break_count'";
        String alter = "ALTER TABLE staff_attendance ADD COLUMN break_count INT NOT NULL DEFAULT 0";
        String backfill = "UPDATE staff_attendance SET break_count = 1 WHERE break_in IS NOT NULL AND break_count = 0";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(check);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next() && rs.getInt(1) == 0) {
                try (Statement st = con.createStatement()) {
                    st.execute(alter);
                    System.out.println("[StaffAttendanceDAO] Added break_count column.");
                }
            }
            // Always run backfill to fix rows inserted before column existed
            try (Statement st = con.createStatement()) {
                int fixed = st.executeUpdate(backfill);
                if (fixed > 0)
                    System.out.println("[StaffAttendanceDAO] Backfilled break_count for " + fixed + " row(s).");
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    // ────────────────────────────────────────────────────────────────────────
    //  CHECK-IN
    // ────────────────────────────────────────────────────────────────────────
    public boolean checkIn(int employeeId) {
        String sql =
            "INSERT IGNORE INTO staff_attendance " +
            "  (employee_id, attendance_date, check_in, status, break_count) " +
            "VALUES (?, CURDATE(), CURTIME(), " +
            "  IF(CURTIME() > '10:00:00', 'LATE', 'PRESENT'), 0)";

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, employeeId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    // ────────────────────────────────────────────────────────────────────────
    //  BREAK-IN (start break) — limited to MAX_BREAKS per day
    // ────────────────────────────────────────────────────────────────────────
    /**
     * Starts a new break. Allowed when:
     *   - Not already on an active break.
     *   - break_count < MAX_BREAKS (2 per shift).
     * Increments break_count on each start.
     */
    public boolean breakIn(int employeeId) {
        String sql =
            "UPDATE staff_attendance " +
            "SET    break_in    = CURTIME(), " +
            "       break_out   = NULL, " +          // mark break as active
            "       break_count = break_count + 1 " +
            "WHERE  employee_id      = ? " +
            "  AND  attendance_date  = CURDATE() " +
            "  AND  check_in IS NOT NULL " +
            // Not currently on an active break
            "  AND  NOT (break_in IS NOT NULL AND break_out IS NULL) " +
            "  AND  check_out IS NULL " +
            // Enforce break limit
            "  AND  break_count < " + MAX_BREAKS;

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, employeeId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    // ────────────────────────────────────────────────────────────────────────
    //  BREAK-OUT (end break)
    // ────────────────────────────────────────────────────────────────────────
    public boolean breakOut(int employeeId) {
        String sql =
            "UPDATE staff_attendance " +
            "SET    break_out        = CURTIME(), " +
            "       total_break_time = " +
            "         SEC_TO_TIME( " +
            "           COALESCE(TIME_TO_SEC(CAST(total_break_time AS TIME)),0) " +
            "           + TIME_TO_SEC(TIMEDIFF(CURTIME(), break_in)) " +
            "         ) " +
            "WHERE  employee_id      = ? " +
            "  AND  attendance_date  = CURDATE() " +
            "  AND  break_in IS NOT NULL " +
            "  AND  break_out IS NULL " +           // active break sentinel
            "  AND  check_out IS NULL";

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, employeeId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    // ────────────────────────────────────────────────────────────────────────
    //  CHECK-OUT
    // ────────────────────────────────────────────────────────────────────────
    public boolean checkOut(int employeeId) {
        String sql =
            "UPDATE staff_attendance " +
            "SET    check_out     = CURTIME(), " +
            "       working_hours = " +
            "         LEFT( " +
            "           SEC_TO_TIME( " +
            "             GREATEST(0, " +
            "               TIME_TO_SEC(TIMEDIFF(CURTIME(), check_in)) " +
            "               - COALESCE(TIME_TO_SEC(CAST(total_break_time AS TIME)),0) " +
            "             ) " +
            "           ), 5 " +
            "         ), " +
            "       status = CASE " +
            "         WHEN GREATEST(0, TIME_TO_SEC(TIMEDIFF(CURTIME(), check_in)) " +
            "               - COALESCE(TIME_TO_SEC(CAST(total_break_time AS TIME)),0)) " +
            "              >= ? * 60  THEN IF(check_in > '10:00:00', 'LATE', 'PRESENT') " +
            "         WHEN GREATEST(0, TIME_TO_SEC(TIMEDIFF(CURTIME(), check_in)) " +
            "               - COALESCE(TIME_TO_SEC(CAST(total_break_time AS TIME)),0)) " +
            "              >= ? * 60  THEN 'HALF_DAY' " +
            "         ELSE 'ABSENT' " +
            "       END " +
            "WHERE  employee_id     = ? " +
            "  AND  attendance_date = CURDATE() " +
            "  AND  check_in IS NOT NULL " +
            "  AND  NOT (break_in IS NOT NULL AND break_out IS NULL) " +
            "  AND  check_out IS NULL";

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, FULL_DAY_MINUTES);
            ps.setInt(2, HALF_DAY_MINUTES);
            ps.setInt(3, employeeId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    // ────────────────────────────────────────────────────────────────────────
    //  GET TODAY'S RECORD for a single employee
    // ────────────────────────────────────────────────────────────────────────
    public StaffAttendance getTodayRecord(int employeeId) {
        String sql =
            "SELECT attendance_id, employee_id, attendance_date, check_in, " +
            "  COALESCE(break_in, " +
            "    IF(break_out IS NOT NULL AND total_break_time IS NOT NULL, " +
            "       SUBTIME(break_out, CAST(total_break_time AS TIME)), NULL)) AS break_in, " +
            "  break_out, check_out, total_break_time, working_hours, " +
            "  GREATEST(COALESCE(break_count, 0), IF(break_in IS NOT NULL, 1, 0)) AS break_count, " +
            "  CASE " +
            "    WHEN check_out IS NOT NULL AND TIME_TO_SEC(CAST(working_hours AS TIME)) >= 360*60 THEN IF(check_in > '10:00:00', 'LATE', 'PRESENT') " +
            "    WHEN check_out IS NOT NULL AND TIME_TO_SEC(CAST(working_hours AS TIME)) >= 240*60 THEN 'HALF_DAY' " +
            "    WHEN check_out IS NOT NULL THEN 'ABSENT' " +
            "    WHEN check_in  IS NOT NULL THEN IF(check_in > '10:00:00', 'LATE', 'PRESENT') " +
            "    ELSE 'ABSENT' " +
            "  END AS status " +
            "FROM staff_attendance " +
            "WHERE employee_id = ? AND attendance_date = CURDATE()";

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, employeeId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return map(rs);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    // ────────────────────────────────────────────────────────────────────────
    //  GET ALL STAFF ATTENDANCE TODAY  (admin / manager view)
    // ────────────────────────────────────────────────────────────────────────
    public List<StaffAttendance> getTodayAll() {
        String sql =
            "SELECT " +
            "  u.id            AS uid, " +
            "  u.username      AS employee_name, " +
            "  sa.attendance_id, " +
            "  sa.attendance_date, " +
            "  sa.check_in, " +
            "  COALESCE(sa.break_in, " +
            "    IF(sa.break_out IS NOT NULL AND sa.total_break_time IS NOT NULL, " +
            "       SUBTIME(sa.break_out, CAST(sa.total_break_time AS TIME)), NULL)) AS break_in, " +
            "  sa.break_out, " +
            "  sa.check_out, " +
            "  sa.total_break_time, " +
            "  sa.working_hours, " +
            "  GREATEST(COALESCE(sa.break_count, 0), IF(sa.break_in IS NOT NULL, 1, 0)) AS break_count, " +
            "  CASE " +
            "    WHEN sa.check_out IS NOT NULL AND TIME_TO_SEC(CAST(sa.working_hours AS TIME)) >= 360*60 THEN IF(sa.check_in > '10:00:00', 'LATE', 'PRESENT') " +
            "    WHEN sa.check_out IS NOT NULL AND TIME_TO_SEC(CAST(sa.working_hours AS TIME)) >= 240*60 THEN 'HALF_DAY' " +
            "    WHEN sa.check_out IS NOT NULL THEN 'ABSENT' " +
            "    WHEN sa.check_in  IS NOT NULL THEN IF(sa.check_in > '10:00:00', 'LATE', 'PRESENT') " +
            "    ELSE 'NOT CHECKED IN' " +
            "  END AS att_status " +
            "FROM   users u " +
            "LEFT JOIN staff_attendance sa " +
            "       ON sa.employee_id = u.id AND sa.attendance_date = CURDATE() " +
            "WHERE  u.role = 'STAFF' AND u.status = 'ACTIVE' " +
            "ORDER  BY u.username";

        List<StaffAttendance> list = new ArrayList<>();
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                StaffAttendance a = new StaffAttendance();
                a.setEmployeeId(rs.getInt("uid"));
                a.setEmployeeName(rs.getString("employee_name"));
                a.setAttendanceId(rs.getInt("attendance_id"));
                a.setAttendanceDate(rs.getDate("attendance_date"));
                a.setCheckIn(rs.getTime("check_in"));
                a.setBreakIn(rs.getTime("break_in"));
                a.setBreakOut(rs.getTime("break_out"));
                a.setCheckOut(rs.getTime("check_out"));
                a.setTotalBreakTime(rs.getString("total_break_time"));
                a.setWorkingHours(rs.getString("working_hours"));
                a.setBreakCount(rs.getInt("break_count"));
                String status = rs.getString("att_status");
                a.setStatus(status != null ? status : "ABSENT");
                list.add(a);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    // ────────────────────────────────────────────────────────────────────────
    //  MONTHLY REPORT  (admin / manager view)
    // ────────────────────────────────────────────────────────────────────────
    public List<StaffAttendance> getMonthlyReport(int year, int month) {
        java.time.LocalDate systemStart = java.time.LocalDate.of(2026, 5, 11);
        java.time.LocalDate firstDay = java.time.LocalDate.of(year, month, 1);
        if (firstDay.isBefore(systemStart)) firstDay = systemStart;
        java.time.LocalDate lastDay  = java.time.LocalDate.of(year, month, 1).withDayOfMonth(
            java.time.LocalDate.of(year, month, 1).lengthOfMonth());
        java.time.LocalDate today = java.time.LocalDate.now();
        if (lastDay.isAfter(today)) lastDay = today;
        if (firstDay.isAfter(today)) return new ArrayList<>();

        StringBuilder cal = new StringBuilder();
        java.time.LocalDate d = firstDay;
        while (!d.isAfter(lastDay)) {
            if (cal.length() > 0) cal.append(" UNION ALL ");
            cal.append("SELECT '").append(d).append("' AS dt");
            d = d.plusDays(1);
        }

        String sql =
            "SELECT " +
            "  u.id            AS employee_id, " +
            "  u.username      AS employee_name, " +
            "  cal.dt          AS attendance_date, " +
            "  sa.attendance_id, " +
            "  sa.check_in, " +
            "  COALESCE(sa.break_in, " +
            "    IF(sa.break_out IS NOT NULL AND sa.total_break_time IS NOT NULL, " +
            "       SUBTIME(sa.break_out, CAST(sa.total_break_time AS TIME)), NULL)) AS break_in, " +
            "  sa.break_out, " +
            "  sa.check_out, " +
            "  COALESCE(sa.total_break_time, '0:00') AS total_break_time, " +
            "  sa.working_hours, " +
            "  GREATEST(COALESCE(sa.break_count, 0), IF(sa.break_in IS NOT NULL, 1, 0)) AS break_count, " +
            "  CASE " +
            "    WHEN sa.attendance_id IS NULL                                                              THEN 'ABSENT' " +
            "    WHEN sa.check_out IS NOT NULL " +
            "         AND TIME_TO_SEC(CAST(sa.working_hours AS TIME)) >= 360*60                             THEN IF(sa.check_in > '10:00:00', 'LATE', 'PRESENT') " +
            "    WHEN sa.check_out IS NOT NULL " +
            "         AND TIME_TO_SEC(CAST(sa.working_hours AS TIME)) >= 240*60                             THEN 'HALF_DAY' " +
            "    WHEN sa.check_out IS NOT NULL                                                              THEN 'ABSENT' " +
            "    WHEN sa.check_in IS NOT NULL AND sa.check_out IS NULL AND cal.dt < CURDATE()              THEN 'INCOMPLETE' " +
            "    WHEN sa.check_in IS NOT NULL                                                               THEN IF(sa.check_in > '10:00:00', 'LATE', 'PRESENT') " +
            "    ELSE 'ABSENT' " +
            "  END AS status " +
            "FROM users u " +
            "CROSS JOIN (" + cal + ") cal " +
            "LEFT JOIN staff_attendance sa " +
            "       ON sa.employee_id = u.id " +
            "      AND sa.attendance_date = cal.dt " +
            "WHERE u.role = 'STAFF' AND u.status = 'ACTIVE' " +
            "ORDER BY cal.dt DESC, u.username ASC";

        List<StaffAttendance> list = new ArrayList<>();
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                StaffAttendance a = new StaffAttendance();
                a.setEmployeeId(rs.getInt("employee_id"));
                a.setEmployeeName(rs.getString("employee_name"));
                a.setAttendanceDate(rs.getDate("attendance_date"));
                a.setAttendanceId(rs.getInt("attendance_id"));
                a.setCheckIn(rs.getTime("check_in"));
                a.setBreakIn(rs.getTime("break_in"));
                a.setBreakOut(rs.getTime("break_out"));
                a.setCheckOut(rs.getTime("check_out"));
                a.setTotalBreakTime(rs.getString("total_break_time"));
                a.setWorkingHours(rs.getString("working_hours"));
                a.setBreakCount(rs.getInt("break_count"));
                a.setStatus(rs.getString("status"));
                list.add(a);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    // ────────────────────────────────────────────────────────────────────────
    //  PERSONAL HISTORY  (staff's own records)
    // ────────────────────────────────────────────────────────────────────────
    public List<StaffAttendance> getMyHistory(int employeeId, int days) {
        String sql =
            "SELECT attendance_id, employee_id, attendance_date, check_in, " +
            "  COALESCE(break_in, " +
            "    IF(break_out IS NOT NULL AND total_break_time IS NOT NULL, " +
            "       SUBTIME(break_out, CAST(total_break_time AS TIME)), NULL)) AS break_in, " +
            "  break_out, check_out, total_break_time, working_hours, " +
            "  GREATEST(COALESCE(break_count, 0), IF(break_in IS NOT NULL, 1, 0)) AS break_count, " +
            "  CASE " +
            "    WHEN check_out IS NOT NULL AND TIME_TO_SEC(CAST(working_hours AS TIME)) >= 360*60 THEN IF(check_in > '10:00:00', 'LATE', 'PRESENT') " +
            "    WHEN check_out IS NOT NULL AND TIME_TO_SEC(CAST(working_hours AS TIME)) >= 240*60 THEN 'HALF_DAY' " +
            "    WHEN check_out IS NOT NULL THEN 'ABSENT' " +
            "    WHEN check_in IS NOT NULL AND check_out IS NULL AND attendance_date < CURDATE() THEN 'INCOMPLETE' " +
            "    WHEN check_in  IS NOT NULL THEN IF(check_in > '10:00:00', 'LATE', 'PRESENT') " +
            "    ELSE 'ABSENT' " +
            "  END AS status " +
            "FROM staff_attendance " +
            "WHERE  employee_id = ? " +
            "  AND  attendance_date >= CURDATE() - INTERVAL ? DAY " +
            "ORDER  BY attendance_date DESC";

        List<StaffAttendance> list = new ArrayList<>();
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, employeeId);
            ps.setInt(2, days);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(map(rs));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    // ────────────────────────────────────────────────────────────────────────
    //  SUMMARY COUNTS (for dashboard cards)
    // ────────────────────────────────────────────────────────────────────────
    public int[] getTodaySummary() {
        String sql =
            "SELECT " +
            "  COUNT(u.id) AS total_staff, " +
            "  SUM(CASE " +
            "        WHEN sa.check_in IS NOT NULL AND sa.check_out IS NULL THEN 1 " +
            "        WHEN sa.check_out IS NOT NULL AND TIME_TO_SEC(CAST(sa.working_hours AS TIME)) >= 360*60 THEN 1 " +
            "        ELSE 0 END) AS present_count, " +
            "  SUM(CASE " +
            "        WHEN sa.check_in > '10:00:00' AND sa.check_out IS NULL THEN 1 " +
            "        WHEN sa.check_in > '10:00:00' AND sa.check_out IS NOT NULL " +
            "             AND TIME_TO_SEC(CAST(sa.working_hours AS TIME)) >= 360*60 THEN 1 " +
            "        ELSE 0 END) AS late_count, " +
            "  SUM(CASE WHEN sa.check_out IS NOT NULL " +
            "            AND TIME_TO_SEC(CAST(sa.working_hours AS TIME)) >= 240*60 " +
            "            AND TIME_TO_SEC(CAST(sa.working_hours AS TIME)) < 360*60 THEN 1 ELSE 0 END) AS half_day_count, " +
            "  SUM(CASE WHEN sa.attendance_id IS NULL " +
            "            OR (sa.check_out IS NOT NULL AND TIME_TO_SEC(CAST(sa.working_hours AS TIME)) < 240*60) " +
            "           THEN 1 ELSE 0 END) AS absent_count " +
            "FROM   users u " +
            "LEFT JOIN staff_attendance sa " +
            "       ON sa.employee_id = u.id AND sa.attendance_date = CURDATE() " +
            "WHERE  u.role = 'STAFF' AND u.status = 'ACTIVE'";

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                return new int[]{
                    rs.getInt("present_count"),
                    rs.getInt("absent_count"),
                    rs.getInt("late_count"),
                    rs.getInt("half_day_count"),
                    rs.getInt("total_staff")
                };
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return new int[]{0, 0, 0, 0, 0};
    }

    // ────────────────────────────────────────────────────────────────────────
    //  PERSONAL HISTORY FROM A FIXED DATE
    // ────────────────────────────────────────────────────────────────────────
    public List<StaffAttendance> getMyHistoryFrom(int employeeId, String fromDate) {
        String sql =
            "WITH RECURSIVE date_series AS ( " +
            "  SELECT CAST(? AS DATE) AS dt " +
            "  UNION ALL " +
            "  SELECT dt + INTERVAL 1 DAY FROM date_series WHERE dt + INTERVAL 1 DAY <= CURDATE() " +
            ") " +
            "SELECT " +
            "  sa.attendance_id, " +
            "  COALESCE(sa.employee_id, ?) AS employee_id, " +
            "  ds.dt AS attendance_date, " +
            "  sa.check_in, " +
            "  COALESCE(sa.break_in, " +
            "    IF(sa.break_out IS NOT NULL AND sa.total_break_time IS NOT NULL, " +
            "       SUBTIME(sa.break_out, CAST(sa.total_break_time AS TIME)), NULL)) AS break_in, " +
            "  sa.break_out, sa.check_out, sa.total_break_time, sa.working_hours, " +
            "  GREATEST(COALESCE(sa.break_count, 0), IF(sa.break_in IS NOT NULL, 1, 0)) AS break_count, " +
            "  CASE " +
            "    WHEN ds.dt = CURDATE() AND sa.attendance_id IS NULL THEN 'NOT CHECKED IN' " +
            "    WHEN sa.attendance_id IS NULL THEN 'ABSENT' " +
            "    WHEN sa.check_out IS NOT NULL AND TIME_TO_SEC(CAST(sa.working_hours AS TIME)) >= 360*60 THEN IF(sa.check_in > '10:00:00', 'LATE', 'PRESENT') " +
            "    WHEN sa.check_out IS NOT NULL AND TIME_TO_SEC(CAST(sa.working_hours AS TIME)) >= 240*60 THEN 'HALF_DAY' " +
            "    WHEN sa.check_out IS NOT NULL THEN 'ABSENT' " +
            "    WHEN sa.check_in IS NOT NULL AND sa.check_out IS NULL AND ds.dt < CURDATE() THEN 'INCOMPLETE' " +
            "    WHEN sa.check_in IS NOT NULL THEN IF(sa.check_in > '10:00:00', 'LATE', 'PRESENT') " +
            "    ELSE 'ABSENT' " +
            "  END AS status " +
            "FROM date_series ds " +
            "LEFT JOIN staff_attendance sa " +
            "       ON sa.employee_id = ? AND sa.attendance_date = ds.dt " +
            "ORDER BY ds.dt DESC";

        List<StaffAttendance> list = new ArrayList<>();
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, fromDate);
            ps.setInt(2, employeeId);
            ps.setInt(3, employeeId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(map(rs));
            }
        } catch (Exception e) {
            System.err.println("[StaffAttendanceDAO] getMyHistoryFrom ERROR: " + e.getMessage());
            e.printStackTrace();
            // Fallback: run without break_count (for DBs that haven't migrated yet)
            list = getMyHistoryFromFallback(employeeId, fromDate);
        }
        return list;
    }

    private List<StaffAttendance> getMyHistoryFromFallback(int employeeId, String fromDate) {
        String sql =
            "WITH RECURSIVE date_series AS ( " +
            "  SELECT CAST(? AS DATE) AS dt " +
            "  UNION ALL " +
            "  SELECT dt + INTERVAL 1 DAY FROM date_series WHERE dt + INTERVAL 1 DAY <= CURDATE() " +
            ") " +
            "SELECT " +
            "  sa.attendance_id, " +
            "  COALESCE(sa.employee_id, ?) AS employee_id, " +
            "  ds.dt AS attendance_date, " +
            "  sa.check_in, " +
            "  COALESCE(sa.break_in, " +
            "    IF(sa.break_out IS NOT NULL AND sa.total_break_time IS NOT NULL, " +
            "       SUBTIME(sa.break_out, CAST(sa.total_break_time AS TIME)), NULL)) AS break_in, " +
            "  sa.break_out, sa.check_out, sa.total_break_time, sa.working_hours, " +
            "  0 AS break_count, " +
            "  CASE " +
            "    WHEN ds.dt = CURDATE() AND sa.attendance_id IS NULL THEN 'NOT CHECKED IN' " +
            "    WHEN sa.attendance_id IS NULL THEN 'ABSENT' " +
            "    WHEN sa.check_out IS NOT NULL AND TIME_TO_SEC(CAST(sa.working_hours AS TIME)) >= 360*60 THEN IF(sa.check_in > '10:00:00', 'LATE', 'PRESENT') " +
            "    WHEN sa.check_out IS NOT NULL AND TIME_TO_SEC(CAST(sa.working_hours AS TIME)) >= 240*60 THEN 'HALF_DAY' " +
            "    WHEN sa.check_out IS NOT NULL THEN 'ABSENT' " +
            "    WHEN sa.check_in IS NOT NULL AND sa.check_out IS NULL AND ds.dt < CURDATE() THEN 'INCOMPLETE' " +
            "    WHEN sa.check_in IS NOT NULL THEN IF(sa.check_in > '10:00:00', 'LATE', 'PRESENT') " +
            "    ELSE 'ABSENT' " +
            "  END AS status " +
            "FROM date_series ds " +
            "LEFT JOIN staff_attendance sa " +
            "       ON sa.employee_id = ? AND sa.attendance_date = ds.dt " +
            "ORDER BY ds.dt DESC";

        List<StaffAttendance> list = new ArrayList<>();
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, fromDate);
            ps.setInt(2, employeeId);
            ps.setInt(3, employeeId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(map(rs));
            }
        } catch (Exception e) {
            System.err.println("[StaffAttendanceDAO] getMyHistoryFromFallback ERROR: " + e.getMessage());
            e.printStackTrace();
        }
        return list;
    }

    // ────────────────────────────────────────────────────────────────────────
    //  AUTO PUNCH-OUT
    // ────────────────────────────────────────────────────────────────────────
    public void autoPunchOut() {
        String sql =
            "UPDATE staff_attendance " +
            "SET check_out = '18:00:00', " +
            "    working_hours = LEFT(SEC_TO_TIME(GREATEST(0, " +
            "        TIME_TO_SEC(TIMEDIFF('18:00:00', check_in)) " +
            "        - COALESCE(TIME_TO_SEC(CAST(total_break_time AS TIME)), 0)" +
            "    )), 5), " +
            "    status = CASE " +
            "        WHEN GREATEST(0, TIME_TO_SEC(TIMEDIFF('18:00:00', check_in)) " +
            "             - COALESCE(TIME_TO_SEC(CAST(total_break_time AS TIME)), 0)) " +
            "             >= 360*60 THEN IF(check_in > '10:00:00', 'LATE', 'PRESENT') " +
            "        WHEN GREATEST(0, TIME_TO_SEC(TIMEDIFF('18:00:00', check_in)) " +
            "             - COALESCE(TIME_TO_SEC(CAST(total_break_time AS TIME)), 0)) " +
            "             >= 240*60 THEN 'HALF_DAY' " +
            "        ELSE 'ABSENT' " +
            "    END " +
            "WHERE check_in IS NOT NULL " +
            "  AND check_out IS NULL " +
            "  AND ( " +
            "        attendance_date < CURDATE() " +
            "        OR (attendance_date = CURDATE() AND CURTIME() >= '18:00:00') " +
            "      )";

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            int rows = ps.executeUpdate();
            if (rows > 0) System.out.println("[AutoPunchOut] Updated " + rows + " record(s).");
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}