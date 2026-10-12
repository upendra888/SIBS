package com.sibs.servlet;

import com.sibs.dao.NotificationDAO;
import com.sibs.dao.StaffLeaveDAO;
import com.sibs.model.User;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.io.PrintWriter;

/**
 * Handles all staff-leave AJAX actions.
 * URL: /staffLeave
 *
 * Actions (POST):
 *   apply   — staff submits a new leave application
 *   cancel  — staff cancels their own PENDING application
 *   approve — admin approves a PENDING application
 *   reject  — admin rejects  a PENDING application
 */
@WebServlet("/staffLeave")
public class StaffLeaveServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        resp.setContentType("application/json;charset=UTF-8");
        PrintWriter out = resp.getWriter();

        HttpSession session = req.getSession(false);
        if (session == null) {
            resp.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            out.print("{\"ok\":false,\"error\":\"not-logged-in\"}");
            return;
        }

        User user = (User) session.getAttribute("user");
        if (user == null) {
            resp.setStatus(HttpServletResponse.SC_FORBIDDEN);
            out.print("{\"ok\":false,\"error\":\"access-denied\"}");
            return;
        }

        String role   = user.getRole();
        String action = req.getParameter("action");
        if (action == null) {
            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            out.print("{\"ok\":false,\"error\":\"missing-action\"}");
            return;
        }

        StaffLeaveDAO dao = new StaffLeaveDAO();

        switch (action) {

            // ── Staff: submit new leave ────────────────────────────────
            case "apply": {
                if (!"STAFF".equals(role) && !"ADMIN".equals(role)) {
                    resp.setStatus(HttpServletResponse.SC_FORBIDDEN);
                    out.print("{\"ok\":false,\"error\":\"access-denied\"}");
                    return;
                }
                String leaveType = req.getParameter("leaveType");
                String fromDate  = req.getParameter("fromDate");
                String toDate    = req.getParameter("toDate");
                String reason    = req.getParameter("reason");

                if (leaveType == null || fromDate == null || toDate == null
                        || reason == null || reason.trim().isEmpty()) {
                    out.print("{\"ok\":false,\"error\":\"All fields are required.\"}");
                    return;
                }
                if (fromDate.compareTo(toDate) > 0) {
                    out.print("{\"ok\":false,\"error\":\"From date cannot be after To date.\"}");
                    return;
                }

                if (dao.applyLeave(user.getId(), leaveType, fromDate, toDate, reason.trim())) {
                    NotificationDAO.sendLeaveApplicationToAdmin(user.getId(), user.getName());
                    out.print("{\"ok\":true,\"message\":\"Leave application submitted successfully!\"}");
                } else {
                    out.print("{\"ok\":false,\"error\":\"Failed to submit leave. Please try again.\"}");
                }
                break;
            }

            // ── Staff: cancel own pending leave ────────────────────────
            case "cancel": {
                if (!"STAFF".equals(role) && !"ADMIN".equals(role)) {
                    resp.setStatus(HttpServletResponse.SC_FORBIDDEN);
                    out.print("{\"ok\":false,\"error\":\"access-denied\"}");
                    return;
                }
                String leaveIdStr = req.getParameter("leaveId");
                if (leaveIdStr == null) {
                    out.print("{\"ok\":false,\"error\":\"Missing leaveId.\"}");
                    return;
                }
                int leaveId = Integer.parseInt(leaveIdStr);
                if (dao.cancelLeave(leaveId, user.getId())) {
                    // ── Notify staff: leave cancelled ─────────────────
                    String name = user.getName() != null ? user.getName() : user.getUsername();
                    NotificationDAO.sendLeaveCancelledBySelf(user.getId(), name);
                    // ─────────────────────────────────────────────────
                    out.print("{\"ok\":true,\"message\":\"Leave application cancelled.\"}");
                } else {
                    out.print("{\"ok\":false,\"error\":\"Could not cancel — it may already be processed.\"}");
                }
                break;
            }

            // ── Admin: approve ─────────────────────────────────────────
            case "approve": {
                if (!"ADMIN".equals(role)) {
                    resp.setStatus(HttpServletResponse.SC_FORBIDDEN);
                    out.print("{\"ok\":false,\"error\":\"Admin access required.\"}");
                    return;
                }
                String leaveIdStr   = req.getParameter("leaveId");
                String adminRemarks = req.getParameter("adminRemarks");
                if (leaveIdStr == null) {
                    out.print("{\"ok\":false,\"error\":\"Missing leaveId.\"}");
                    return;
                }
                int leaveId = Integer.parseInt(leaveIdStr);
                if (dao.updateStatus(leaveId, "APPROVED",
                        adminRemarks == null ? "" : adminRemarks.trim(), user.getId())) {
                    // Notify the staff member whose leave was approved
                    try {
                        String lSql = "SELECT employee_id FROM staff_leave_applications WHERE id=?";
                        try (java.sql.Connection lCon = com.sibs.util.DBConnection.getConnection();
                             java.sql.PreparedStatement lPs = lCon.prepareStatement(lSql)) {
                            lPs.setInt(1, leaveId);
                            java.sql.ResultSet lRs = lPs.executeQuery();
                            if (lRs.next()) {
                                NotificationDAO.sendLeaveDecisionToStaff(
                                    lRs.getInt("employee_id"), "Approved",
                                    adminRemarks == null ? "" : adminRemarks.trim());
                            }
                        }
                    } catch (Exception ignored) {}
                    out.print("{\"ok\":true,\"message\":\"Leave approved.\"}");
                } else {
                    out.print("{\"ok\":false,\"error\":\"Could not approve — leave may already be processed.\"}");
                }
                break;
            }

            // ── Admin: reject ──────────────────────────────────────────
            case "reject": {
                if (!"ADMIN".equals(role)) {
                    resp.setStatus(HttpServletResponse.SC_FORBIDDEN);
                    out.print("{\"ok\":false,\"error\":\"Admin access required.\"}");
                    return;
                }
                String leaveIdStr   = req.getParameter("leaveId");
                String adminRemarks = req.getParameter("adminRemarks");
                if (leaveIdStr == null) {
                    out.print("{\"ok\":false,\"error\":\"Missing leaveId.\"}");
                    return;
                }
                int leaveId = Integer.parseInt(leaveIdStr);
                if (dao.updateStatus(leaveId, "REJECTED",
                        adminRemarks == null ? "" : adminRemarks.trim(), user.getId())) {
                    // Notify the staff member whose leave was rejected
                    try {
                        String lSql = "SELECT employee_id FROM staff_leave_applications WHERE id=?";
                        try (java.sql.Connection lCon = com.sibs.util.DBConnection.getConnection();
                             java.sql.PreparedStatement lPs = lCon.prepareStatement(lSql)) {
                            lPs.setInt(1, leaveId);
                            java.sql.ResultSet lRs = lPs.executeQuery();
                            if (lRs.next()) {
                                NotificationDAO.sendLeaveDecisionToStaff(
                                    lRs.getInt("employee_id"), "Rejected",
                                    adminRemarks == null ? "" : adminRemarks.trim());
                            }
                        }
                    } catch (Exception ignored) {}
                    out.print("{\"ok\":true,\"message\":\"Leave rejected.\"}");
                } else {
                    out.print("{\"ok\":false,\"error\":\"Could not reject — leave may already be processed.\"}");
                }
                break;
            }

            default:
                resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                out.print("{\"ok\":false,\"error\":\"unknown-action\"}");
        }
    }
}