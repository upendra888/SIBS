package com.sibs.servlet;

import com.sibs.dao.NotificationDAO;
import com.sibs.model.Notification;
import com.sibs.model.User;
import com.sibs.util.DBConnection;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;

/**
 * AdminBroadcastServlet
 *
 * Allows admin to send custom announcement notifications to:
 *   - ALL staff (staff_id = 0 broadcast)
 *   - ALL customers (one row per customer)
 *   - ALL delivery boys (one row per delivery boy)
 *   - EVERYONE (all of the above)
 *
 * POST /adminBroadcast
 *   target  : "staff" | "customers" | "delivery" | "all"
 *   title   : notification title
 *   message : notification body
 *   priority: "HIGH" | "MEDIUM" | "LOW"
 *
 * Returns JSON { ok: true, sent: N } or redirects to admin page.
 */
@WebServlet("/adminBroadcast")
public class Adminbroadcastservlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        User admin = (session != null) ? (User) session.getAttribute("user") : null;
        if (admin == null) {
            res.sendRedirect("admin-login.jsp");
            return;
        }

        String target   = req.getParameter("target");
        String title    = req.getParameter("title");
        String message  = req.getParameter("message");
        String priority = req.getParameter("priority");

        if (title == null || title.trim().isEmpty() ||
            message == null || message.trim().isEmpty() ||
            target == null) {
            res.sendRedirect("admin-notifications.jsp?error=missing_fields");
            return;
        }

        title    = title.trim();
        message  = message.trim();
        priority = (priority != null && !priority.trim().isEmpty()) ? priority.trim() : "MEDIUM";

        int sent = 0;

        try {
            if ("staff".equals(target) || "all".equals(target)) {
                // Single broadcast row — staff_id=0 means all staff see it
                sendBroadcastToStaff(title, message, priority);
                sent++;
            }

            if ("customers".equals(target) || "all".equals(target)) {
                sent += sendToAllCustomers(title, message, priority);
            }

            if ("delivery".equals(target) || "all".equals(target)) {
                sent += sendToAllDeliveryBoys(title, message, priority);
            }
        } catch (Exception e) {
            e.printStackTrace();
            res.sendRedirect("admin-notifications.jsp?error=broadcast_failed");
            return;
        }

        // If AJAX, return JSON; otherwise redirect
        String accept = req.getHeader("Accept");
        if (accept != null && accept.contains("application/json")) {
            res.setContentType("application/json;charset=UTF-8");
            PrintWriter out = res.getWriter();
            out.print("{\"ok\":true,\"sent\":" + sent + "}");
        } else {
            res.sendRedirect("admin-notifications.jsp?broadcast=success&sent=" + sent);
        }
    }

    /** One broadcast row for all staff (staff_id = 0). */
    private void sendBroadcastToStaff(String title, String message, String priority) {
        Notification n = new Notification();
        n.setStaffId(0);          // 0 = broadcast to all staff
        n.setCategory("SYSTEM");
        n.setPriority(priority);
        n.setTitle(title);
        n.setMessage(message);
        n.setLinkUrl("/admin-notifications.jsp");
        insertDirect(n);
    }

    /** One row per customer. Returns count inserted. */
    private int sendToAllCustomers(String title, String message, String priority) {
        List<Integer> ids = fetchIds(
            "SELECT id FROM users WHERE role='customer' OR role IS NULL");
        for (int id : ids) {
            Notification n = new Notification();
            n.setUserId(id);
            n.setCategory("SYSTEM");
            n.setPriority(priority);
            n.setTitle(title);
            n.setMessage(message);
            n.setLinkUrl("/notifications.jsp");
            insertDirect(n);
        }
        return ids.size();
    }

    /** One row per active delivery boy. Returns count inserted. */
    private int sendToAllDeliveryBoys(String title, String message, String priority) {
        List<Integer> ids = fetchIds(
            "SELECT id FROM delivery_boys WHERE status='ACTIVE'");
        for (int id : ids) {
            Notification n = new Notification();
            n.setDeliveryBoyId(id);
            n.setCategory("SYSTEM");
            n.setPriority(priority);
            n.setTitle(title);
            n.setMessage(message);
            n.setLinkUrl("/delivery-dashboard.jsp");
            insertDirect(n);
        }
        return ids.size();
    }

    private List<Integer> fetchIds(String sql) {
        List<Integer> ids = new ArrayList<>();
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) ids.add(rs.getInt(1));
        } catch (Exception e) {
            e.printStackTrace();
        }
        return ids;
    }

    private void insertDirect(Notification n) {
        String sql = "INSERT INTO notifications " +
                     "(user_id, staff_id, delivery_boy_id, title, message, link_url, " +
                     " category, priority) VALUES (?,?,?,?,?,?,?,?)";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            setNullableInt(ps, 1, n.getUserId());
            setNullableInt(ps, 2, n.getStaffId());
            setNullableInt(ps, 3, n.getDeliveryBoyId());
            ps.setString(4, n.getTitle());
            ps.setString(5, n.getMessage());
            ps.setString(6, n.getLinkUrl() != null ? n.getLinkUrl() : "#");
            ps.setString(7, n.getCategory() != null ? n.getCategory() : "SYSTEM");
            ps.setString(8, n.getPriority() != null ? n.getPriority() : "MEDIUM");
            ps.executeUpdate();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void setNullableInt(PreparedStatement ps, int idx, Integer val)
            throws java.sql.SQLException {
        if (val == null) ps.setNull(idx, java.sql.Types.INTEGER);
        else             ps.setInt(idx, val);
    }
}