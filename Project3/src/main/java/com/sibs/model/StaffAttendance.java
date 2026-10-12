package com.sibs.model;

import java.sql.Date;
import java.sql.Time;

/**
 * Model for the staff_attendance table.
 */
public class StaffAttendance {

    private int    attendanceId;
    private int    employeeId;
    private String employeeName;   // joined from users — display only
    private Date   attendanceDate;
    private Time   checkIn;
    private Time   breakIn;
    private Time   breakOut;
    private Time   checkOut;
    private String totalBreakTime; // "00:30"
    private String workingHours;   // "07:30"
    private String status;         // PRESENT | LATE | HALF_DAY | FULL_DAY | ABSENT
    private int    breakCount;     // number of breaks taken today (max 2)

    // ── Getters / Setters ──────────────────────────────────────────────────

    public int getAttendanceId() { return attendanceId; }
    public void setAttendanceId(int attendanceId) { this.attendanceId = attendanceId; }

    public int getEmployeeId() { return employeeId; }
    public void setEmployeeId(int employeeId) { this.employeeId = employeeId; }

    public String getEmployeeName() { return employeeName; }
    public void setEmployeeName(String employeeName) { this.employeeName = employeeName; }

    public Date getAttendanceDate() { return attendanceDate; }
    public void setAttendanceDate(Date attendanceDate) { this.attendanceDate = attendanceDate; }

    public Time getCheckIn() { return checkIn; }
    public void setCheckIn(Time checkIn) { this.checkIn = checkIn; }

    public Time getBreakIn() { return breakIn; }
    public void setBreakIn(Time breakIn) { this.breakIn = breakIn; }

    public Time getBreakOut() { return breakOut; }
    public void setBreakOut(Time breakOut) { this.breakOut = breakOut; }

    public Time getCheckOut() { return checkOut; }
    public void setCheckOut(Time checkOut) { this.checkOut = checkOut; }

    public String getTotalBreakTime() { return totalBreakTime; }
    public void setTotalBreakTime(String totalBreakTime) { this.totalBreakTime = totalBreakTime; }

    public String getWorkingHours() { return workingHours; }
    public void setWorkingHours(String workingHours) { this.workingHours = workingHours; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public int getBreakCount() { return breakCount; }
    public void setBreakCount(int breakCount) { this.breakCount = breakCount; }

    // ── Helpers ───────────────────────────────────────────────────────────

    /** True if the employee has already checked in today. */
    public boolean isCheckedIn()  { return checkIn != null; }

    /**
     * True if the employee is currently on an active break.
     * break_in IS NOT NULL and break_out IS NULL = active break sentinel.
     */
    public boolean isOnBreak()    { return breakIn != null && breakOut == null; }

    /** True if the employee has checked out for the day. */
    public boolean isCheckedOut() { return checkOut != null; }

    /** True if the employee has used all 2 allowed breaks. */
    public boolean isBreakLimitReached() { return breakCount >= 2; }
}