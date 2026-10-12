package com.sibs.servlet;

import com.sibs.dao.NotificationDAO;
import com.sibs.dao.StaffAttendanceDAO;
import com.sibs.model.User;

import java.time.LocalTime;
import java.time.format.DateTimeFormatter;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.io.PrintWriter;

@WebServlet("/staffAttendance")
public class StaffAttendanceServlet extends HttpServlet {

    @Override
    public void init() throws ServletException {
        // Ensure break_count column exists (safe migration, runs once on startup)
        new StaffAttendanceDAO().ensureBreakCountColumn();
    }

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
        if (user == null || (!"STAFF".equals(user.getRole()) && !"ADMIN".equals(user.getRole()))) {
            resp.setStatus(HttpServletResponse.SC_FORBIDDEN);
            out.print("{\"ok\":false,\"error\":\"access-denied\"}");
            return;
        }

        String action = req.getParameter("action");
        if (action == null) {
            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            out.print("{\"ok\":false,\"error\":\"missing-action\"}");
            return;
        }

        StaffAttendanceDAO dao = new StaffAttendanceDAO();
        int empId = user.getId();
        String name = user.getName() != null ? user.getName() : "Staff";
        String now = LocalTime.now().format(DateTimeFormatter.ofPattern("hh:mm a"));

        switch (action) {
            case "checkIn":
                if (dao.checkIn(empId)) {
                    NotificationDAO.sendCheckIn(empId, name, now);
                    // Late check — if checked in after 10:00 AM, send late alert
                    if (LocalTime.now().isAfter(LocalTime.of(10, 0))) {
                        String email = user.getEmail() != null ? user.getEmail() : "";
                        NotificationDAO.sendLateAttendance(empId, name, now, email);
                    }
                    out.print("{\"ok\":true,\"message\":\"Checked in successfully!\"}");
                } else {
                    out.print("{\"ok\":false,\"error\":\"Already checked in today or a database error occurred.\"}");
                }
                break;

            case "breakIn":
                if (dao.breakIn(empId)) {
                    NotificationDAO.sendBreakIn(empId, name, now);
                    out.print("{\"ok\":true,\"message\":\"Break started.\"}");
                } else {
                    // Check if limit was the reason
                    com.sibs.model.StaffAttendance today = dao.getTodayRecord(empId);
                    if (today != null && today.isBreakLimitReached()) {
                        out.print("{\"ok\":false,\"error\":\"Break limit reached. You have used all 2 breaks allowed for today.\"}");
                    } else {
                        out.print("{\"ok\":false,\"error\":\"Cannot start break — check your check-in status.\"}");
                    }
                }
                break;

            case "breakOut":
                if (dao.breakOut(empId)) {
                    NotificationDAO.sendBreakOut(empId, name, now);
                    out.print("{\"ok\":true,\"message\":\"Break ended. Welcome back!\"}");
                } else {
                    out.print("{\"ok\":false,\"error\":\"Cannot end break — you may not be on break right now.\"}");
                }
                break;

            case "checkOut":
                if (dao.checkOut(empId)) {
                    NotificationDAO.sendCheckOut(empId, name, now);
                    out.print("{\"ok\":true,\"message\":\"Checked out. Have a great day!\"}");
                } else {
                    out.print("{\"ok\":false,\"error\":\"Cannot check out — please check in first or end your break first.\"}");
                }
                break;

            default:
                resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                out.print("{\"ok\":false,\"error\":\"unknown-action\"}");
        }
    }
}