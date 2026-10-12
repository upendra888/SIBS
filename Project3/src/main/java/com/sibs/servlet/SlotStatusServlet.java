package com.sibs.servlet;

import com.sibs.dao.DeliverySlotDAO;
import com.sibs.model.DeliveryBoy;
import com.sibs.model.DeliverySlot;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import jakarta.servlet.*;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.List;

/**
 * SlotStatusServlet
 *
 * Returns a JSON array of today's delivery slots with live capacity data.
 * Also triggers expireStaleSlots() on every call so the UI always shows
 * up-to-date slot states without a full page reload.
 *
 * URL : GET /slotStatus
 * Auth: delivery boy session required
 *
 * Response example:
 * {
 *   "mySlotStatus": "BOOKED",
 *   "slots": [
 *     {
 *       "slotId": 1,
 *       "slotName": "Morning",
 *       "startTime": "09:00",
 *       "endTime": "11:00",
 *       "bookedCount": 3,
 *       "maxCapacity": 5,
 *       "remaining": 2,
 *       "isFull": false,
 *       "isMine": true,
 *       "myStatus": "BOOKED",
 *       "isExpired": false
 *     },
 *     ...
 *   ]
 * }
 */
@WebServlet("/slotStatus")
public class SlotStatusServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        resp.setContentType("application/json;charset=UTF-8");
        resp.setHeader("Cache-Control", "no-cache, no-store");

        HttpSession session = req.getSession(false);
        DeliveryBoy db = (session != null)
                ? (DeliveryBoy) session.getAttribute("deliveryBoy") : null;

        if (db == null) {
            resp.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            resp.getWriter().write("{\"error\":\"not_logged_in\"}");
            return;
        }

        DeliverySlotDAO dao = new DeliverySlotDAO();

        // Run auto-expiry on every poll — catches stale BOOKED slots silently
        dao.expireStaleSlots();

        List<DeliverySlot> slots = dao.getSlotsForBoy(db.getId());
        DeliverySlot mySlot     = dao.getTodayBooking(db.getId());

        PrintWriter out = resp.getWriter();
        StringBuilder json = new StringBuilder();
        json.append("{");

        // My current slot status (null if none or all cancelled)
        json.append("\"mySlotStatus\":");
        if (mySlot != null) {
            json.append("\"").append(escape(mySlot.getStatus())).append("\"");
        } else {
            json.append("null");
        }

        json.append(",\"slots\":[");

        for (int i = 0; i < slots.size(); i++) {
            DeliverySlot s = slots.get(i);
            boolean isMine   = s.getBookingId() != null;
            boolean isFull   = !s.isAvailable() && !isMine;
            int remaining    = Math.max(0, s.getMaxCapacity() - s.getBookedCount());

            // Check if slot window has passed (expired)
            java.sql.Time now = new java.sql.Time(System.currentTimeMillis());
            boolean isExpired = s.getEndTime() != null && now.after(s.getEndTime());

            if (i > 0) json.append(",");
            json.append("{");
            json.append("\"slotId\":").append(s.getSlotId()).append(",");
            json.append("\"slotName\":\"").append(escape(s.getSlotName())).append("\",");
            json.append("\"startTime\":\"").append(s.getStartTime().toString().substring(0, 5)).append("\",");
            json.append("\"endTime\":\"").append(s.getEndTime().toString().substring(0, 5)).append("\",");
            json.append("\"bookedCount\":").append(s.getBookedCount()).append(",");
            json.append("\"maxCapacity\":").append(s.getMaxCapacity()).append(",");
            json.append("\"remaining\":").append(remaining).append(",");
            json.append("\"isFull\":").append(isFull).append(",");
            json.append("\"isMine\":").append(isMine).append(",");
            json.append("\"myStatus\":").append(isMine && s.getStatus() != null
                    ? "\"" + escape(s.getStatus()) + "\"" : "null").append(",");
            json.append("\"isExpired\":").append(isExpired);
            json.append("}");
        }

        json.append("]}");
        out.write(json.toString());
    }

    private String escape(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"");
    }
}