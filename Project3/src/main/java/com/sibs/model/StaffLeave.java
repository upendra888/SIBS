package com.sibs.model;

import java.sql.Date;
import java.sql.Timestamp;

/**
 * Model for the staff_leave_applications table.
 */
public class StaffLeave {

    private int       leaveId;
    private int       employeeId;
    private String    employeeName;   // joined from users — display only
    private String    leaveType;      // SICK | CASUAL | EMERGENCY | OTHER
    private Date      fromDate;
    private Date      toDate;
    private String    reason;
    private String    status;         // PENDING | APPROVED | REJECTED
    private String    adminRemarks;
    private Timestamp appliedOn;
    private Timestamp actionedOn;
    private int       actionedBy;

    // ── Derived helpers ──────────────────────────────────────────────────

    /** Number of calendar days covered by this leave request (inclusive). */
    public long getDays() {
        if (fromDate == null || toDate == null) return 0;
        long diff = toDate.getTime() - fromDate.getTime();
        return (diff / (1000L * 60 * 60 * 24)) + 1;
    }

    // ── Getters / Setters ────────────────────────────────────────────────

    public int       getLeaveId()       { return leaveId; }
    public void      setLeaveId(int v)  { this.leaveId = v; }

    public int       getEmployeeId()       { return employeeId; }
    public void      setEmployeeId(int v)  { this.employeeId = v; }

    public String    getEmployeeName()         { return employeeName; }
    public void      setEmployeeName(String v) { this.employeeName = v; }

    public String    getLeaveType()         { return leaveType; }
    public void      setLeaveType(String v) { this.leaveType = v; }

    public Date      getFromDate()       { return fromDate; }
    public void      setFromDate(Date v) { this.fromDate = v; }

    public Date      getToDate()       { return toDate; }
    public void      setToDate(Date v) { this.toDate = v; }

    public String    getReason()         { return reason; }
    public void      setReason(String v) { this.reason = v; }

    public String    getStatus()         { return status; }
    public void      setStatus(String v) { this.status = v; }

    public String    getAdminRemarks()         { return adminRemarks; }
    public void      setAdminRemarks(String v) { this.adminRemarks = v; }

    public Timestamp getAppliedOn()       { return appliedOn; }
    public void      setAppliedOn(Timestamp v) { this.appliedOn = v; }

    public Timestamp getActionedOn()       { return actionedOn; }
    public void      setActionedOn(Timestamp v) { this.actionedOn = v; }

    public int       getActionedBy()       { return actionedBy; }
    public void      setActionedBy(int v)  { this.actionedBy = v; }
}