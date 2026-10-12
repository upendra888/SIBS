package com.sibs.servlet;

import com.sibs.dao.NotificationDAO;
import com.sibs.model.DeliveryBoy;
import com.sibs.model.Notification;
import com.sibs.model.User;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.List;

/**
 * GetNotificationsServlet
 *
 * Unified AJAX endpoint for the notification bell on every dashboard.
 *
 * GET  /getNotifications           → JSON list of latest 20 notifications
 * POST /getNotifications?action=markRead&id=N     → mark one as read
 * POST /getNotifications?action=markAllRead       → mark all as read
 *
 * Session key checked (in order): "customer", "user" (staff/admin)
 * Delivery boys use their own session key "deliveryBoy" (int id).
 *
 * Add to web.xml:
 *   <servlet>
 *       <servlet-name>GetNotificationsServlet</servlet-name>
 *       <servlet-class>com.sibs.servlet.GetNotificationsServlet</servlet-class>
 *   </servlet>
 *   <servlet-mapping>
 *       <servlet-name>GetNotificationsServlet</servlet-name>
 *       <url-pattern>/getNotifications</url-pattern>
 *   </servlet-mapping>
 */
@WebServlet("/getNotifications")
public class GetNotificationsServlet extends HttpServlet {

    private final NotificationDAO dao = new NotificationDAO();

    // ── GET: fetch list + unread count ───────────────────────────────────────
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        res.setContentType("application/json;charset=UTF-8");
        PrintWriter out = res.getWriter();

        HttpSession session = req.getSession(false);
        if (session == null) { out.print("{\"error\":\"not-logged-in\"}"); return; }

        RecipientContext ctx = resolve(session);
        if (ctx == null) { out.print("{\"error\":\"unknown-role\"}"); return; }

        List<Notification> list = ctx.fetchList(dao, 20);
        int unread = ctx.countUnread(dao);

        StringBuilder sb = new StringBuilder();
        sb.append("{\"unread\":").append(unread).append(",\"items\":[");
        for (int i = 0; i < list.size(); i++) {
            if (i > 0) sb.append(",");
            Notification n = list.get(i);
            sb.append("{")
              .append("\"id\":").append(n.getId()).append(",")
              .append("\"title\":\"").append(escape(n.getTitle())).append("\",")
              .append("\"message\":\"").append(escape(n.getMessage())).append("\",")
              .append("\"category\":\"").append(escape(n.getCategory())).append("\",")
              .append("\"priority\":\"").append(escape(n.getPriority() != null ? n.getPriority() : "LOW")).append("\",")
              .append("\"linkUrl\":\"").append(escape(n.getLinkUrl() != null ? n.getLinkUrl() : "")).append("\",")
              .append("\"relativeTime\":\"").append(escape(n.getRelativeTime())).append("\",")
              .append("\"isRead\":").append(n.isRead())
              .append("}");
        }
        sb.append("]}");
        out.print(sb);
    }

    // ── POST: mark read actions ──────────────────────────────────────────────
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        res.setContentType("application/json;charset=UTF-8");
        PrintWriter out = res.getWriter();

        HttpSession session = req.getSession(false);
        if (session == null) { out.print("{\"ok\":false}"); return; }

        RecipientContext ctx = resolve(session);
        if (ctx == null) { out.print("{\"ok\":false}"); return; }

        String action = req.getParameter("action");

        if ("markRead".equals(action)) {
            String idStr = req.getParameter("id");
            if (idStr != null) {
                dao.markRead(Integer.parseInt(idStr));
            }
        } else if ("markAllRead".equals(action)) {
            ctx.markAllRead(dao);
        } else if ("delete".equals(action)) {
            String idStr = req.getParameter("id");
            if (idStr != null) {
                dao.deleteOne(Integer.parseInt(idStr));
            }
        } else if ("deleteAll".equals(action)) {
            ctx.deleteAll(dao);
        }

        out.print("{\"ok\":true,\"unread\":" + ctx.countUnread(dao) + "}");
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Inner strategy: resolves who is logged in and delegates DAO calls
    // ─────────────────────────────────────────────────────────────────────────

    private RecipientContext resolve(HttpSession session) {
        // Customer — check FIRST so customer browser never gets staff notifications
        User customer = (User) session.getAttribute("customer");
        if (customer != null) {
            int id = customer.getId();
            return new RecipientContext() {
                public List<Notification> fetchList(NotificationDAO d, int limit) { return d.getForCustomer(id, limit); }
                public int  countUnread(NotificationDAO d) { return d.countUnreadForCustomer(id); }
                public void markAllRead(NotificationDAO d) { d.markAllReadForCustomer(id); }
                public void deleteAll(NotificationDAO d)   { d.deleteAllForCustomer(id); }
            };
        }

        // Staff / Admin
        User staff = (User) session.getAttribute("user");
        if (staff != null) {
            int id = staff.getId();
            return new RecipientContext() {
                public List<Notification> fetchList(NotificationDAO d, int limit) { return d.getForStaff(id, limit); }
                public int  countUnread(NotificationDAO d) { return d.countUnreadForStaff(id); }
                public void markAllRead(NotificationDAO d) { d.markAllReadForStaff(id); }
                public void deleteAll(NotificationDAO d)   { d.deleteAllForStaff(id); }
            };
        }

        // Delivery boy — stored as DeliveryBoy object in session
        Object dbSession = session.getAttribute("deliveryBoy");
        if (dbSession instanceof DeliveryBoy) {
            int id = ((DeliveryBoy) dbSession).getId();
            return new RecipientContext() {
                public List<Notification> fetchList(NotificationDAO d, int limit) { return d.getForDeliveryBoy(id, limit); }
                public int  countUnread(NotificationDAO d) { return d.countUnreadForDeliveryBoy(id); }
                public void markAllRead(NotificationDAO d) { d.markAllReadForDeliveryBoy(id); }
                public void deleteAll(NotificationDAO d)   { d.deleteAllForDeliveryBoy(id); }
            };
        }

        return null;
    }

    private interface RecipientContext {
        List<Notification> fetchList(NotificationDAO dao, int limit);
        int  countUnread(NotificationDAO dao);
        void markAllRead(NotificationDAO dao);
        void deleteAll(NotificationDAO dao);
    }

    /** Minimal JSON string escaping (no external dependency). */
    private static String escape(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\n", "\\n")
                .replace("\r", "\\r")
                .replace("\t", "\\t");
    }
}