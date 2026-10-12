package com.sibs.servlet;

import com.sibs.dao.NotificationDAO;
import com.sibs.model.DeliveryBoy;
import com.sibs.model.Notification;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.List;

/**
 * Delivery Boy Notification Servlet
 *
 * GET  /delivery-notifications?action=poll      → unread count + latest notifications (JSON)
 * POST /delivery-notifications?action=markRead  → mark one notification as read
 * POST /delivery-notifications?action=markAll   → mark all as read
 */
@WebServlet("/delivery-notifications")
public class DeliveryNotificationServlet extends HttpServlet {

    private final NotificationDAO notifDao = new NotificationDAO();

    /* ── GET ──────────────────────────────────────────────────────────── */
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        resp.setContentType("application/json;charset=UTF-8");
        resp.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
        PrintWriter out = resp.getWriter();

        HttpSession session = req.getSession(false);
        DeliveryBoy db = (session != null) ? (DeliveryBoy) session.getAttribute("deliveryBoy") : null;

        if (db == null) {
            resp.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            out.print("{\"error\":\"Not logged in\"}");
            return;
        }

        String action = req.getParameter("action");
        int deliveryBoyId = db.getId();

        if ("poll".equals(action)) {
            int limit = 10;
            try {
                String lp = req.getParameter("limit");
                if (lp != null) limit = Math.min(Integer.parseInt(lp), 50);
            } catch (NumberFormatException ignored) {}

            int unreadCount = notifDao.countUnreadForDeliveryBoy(deliveryBoyId);
            List<Notification> notifications = notifDao.getForDeliveryBoy(deliveryBoyId, limit);

            StringBuilder json = new StringBuilder();
            json.append("{\"unreadCount\":").append(unreadCount).append(",\"notifications\":[");

            for (int i = 0; i < notifications.size(); i++) {
                Notification n = notifications.get(i);
                if (i > 0) json.append(",");
                json.append("{");
                json.append("\"id\":").append(n.getId()).append(",");
                json.append("\"title\":").append(jsonStr(n.getTitle())).append(",");
                json.append("\"message\":").append(jsonStr(n.getMessage())).append(",");
                json.append("\"category\":").append(jsonStr(n.getCategory())).append(",");
                json.append("\"priority\":").append(jsonStr(n.getPriority())).append(",");
                json.append("\"linkUrl\":").append(jsonStr(n.getLinkUrl())).append(",");
                json.append("\"isRead\":").append(n.isRead()).append(",");
                json.append("\"timeAgo\":").append(jsonStr(n.getRelativeTime()));
                if (n.getOrderId() != null) {
                    json.append(",\"orderId\":").append(n.getOrderId());
                }
                json.append("}");
            }
            json.append("]}");
            out.print(json.toString());

        } else {
            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            out.print("{\"error\":\"Unknown action\"}");
        }
    }

    /* ── POST ─────────────────────────────────────────────────────────── */
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        resp.setContentType("application/json;charset=UTF-8");
        PrintWriter out = resp.getWriter();

        HttpSession session = req.getSession(false);
        DeliveryBoy db = (session != null) ? (DeliveryBoy) session.getAttribute("deliveryBoy") : null;

        if (db == null) {
            resp.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            out.print("{\"error\":\"Not logged in\"}");
            return;
        }

        String action = req.getParameter("action");
        int deliveryBoyId = db.getId();

        if ("markRead".equals(action)) {
            String idStr = req.getParameter("id");
            if (idStr == null) {
                resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                out.print("{\"error\":\"Missing id\"}");
                return;
            }
            try {
                int notifId = Integer.parseInt(idStr);
                boolean ok = notifDao.markRead(notifId);
                out.print("{\"success\":" + ok + "}");
            } catch (NumberFormatException e) {
                resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                out.print("{\"error\":\"Invalid id\"}");
            }

        } else if ("markAll".equals(action)) {
            notifDao.markAllReadForDeliveryBoy(deliveryBoyId);
            out.print("{\"success\":true}");

        } else {
            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            out.print("{\"error\":\"Unknown action\"}");
        }
    }

    /** Safely JSON-encode a string */
    private String jsonStr(String s) {
        if (s == null) return "null";
        return "\"" + s.replace("\\", "\\\\")
                       .replace("\"", "\\\"")
                       .replace("\n", "\\n")
                       .replace("\r", "\\r") + "\"";
    }
}