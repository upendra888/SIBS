package com.sibs.servlet;

import com.sibs.dao.CodLedgerDAO;
import com.sibs.dao.DeliveryBoyDAO;
import com.sibs.dao.DeliverySlotDAO;
import com.sibs.dao.NotificationDAO;
import com.sibs.model.DeliveryBoy;
import com.sibs.model.DeliverySlot;
import com.sibs.util.AppSettings;
import com.sibs.util.DBConnection;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

/**
 * POST /shiftToggle
 * Body: state=ONLINE | ON_BREAK | OFFLINE
 * Response: {"ok":true,"state":"ONLINE"}
 *
 * Gates when going ONLINE:
 *   LOW_WALLET → wallet < Rs.200
 *   COD_DEBT   → pending COD remittance > (today earnings + wallet)
 */
@WebServlet("/shiftToggle")
public class ShiftToggleServlet extends HttpServlet {

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

        DeliveryBoy db = (DeliveryBoy) session.getAttribute("deliveryBoy");
        if (db == null) {
            resp.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            out.print("{\"ok\":false,\"error\":\"not-logged-in\"}");
            return;
        }

        String state = req.getParameter("state");
        if (state == null || !state.matches("ONLINE|ON_BREAK|OFFLINE")) {
            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            out.print("{\"ok\":false,\"error\":\"invalid-state\"}");
            return;
        }

        DeliveryBoyDAO dao = new DeliveryBoyDAO();

        // Gate checks — only when trying to go ONLINE
        if ("ONLINE".equals(state)) {

            // Gate 1: wallet >= Rs.200
            double wallet = getWalletBalance(db.getId());
            if (wallet < 200.0) {
                out.print("{\"ok\":false,\"status\":\"LOW_WALLET\"}");
                return;
            }

            // Gate 0: must have an ACTIVE slot booking to go online
            DeliverySlotDAO slotDao = new DeliverySlotDAO();
            DeliverySlot activeSlot = slotDao.getTodayBooking(db.getId());
            if (activeSlot == null || !"ACTIVE".equals(activeSlot.getStatus())) {
                out.print("{\"ok\":false,\"status\":\"NO_ACTIVE_SLOT\"}");
                return;
            }

            // Gate 2: pending COD must not exceed earnings + wallet
            double pendingRemittance = getPendingRemittance(db.getId());
            if (pendingRemittance > 0) {
                double earnings = getNetEarnings(db.getId());
                if (pendingRemittance > (earnings + wallet)) {
                    dao.setShiftStatus(db.getId(), "OFFLINE");
                    db.setShiftStatus("OFFLINE");
                    db.setOnline(false);
                    session.setAttribute("deliveryBoy", db);
                    session.setAttribute("shiftStatus", "OFFLINE");
                    out.print("{\"ok\":false,\"status\":\"COD_DEBT\","
                        + "\"pending\":" + String.format("%.2f", pendingRemittance) + ","
                        + "\"available\":" + String.format("%.2f", (earnings + wallet)) + "}");
                    return;
                }
            }
        }

        // Persist to DB
        dao.setShiftStatus(db.getId(), state);

        // ── Break tracking ──────────────────────────────────────────
        // ON_BREAK  → record break_started_at = NOW()
        // ONLINE    → accumulate break into total_break_seconds, clear break_started_at
        // OFFLINE   → accumulate any active break, clear break_started_at, reset total for next day
        try (Connection bCon = DBConnection.getConnection()) {
            if ("ON_BREAK".equals(state)) {
                // Start break timer
                try (PreparedStatement ps = bCon.prepareStatement(
                        "UPDATE delivery_boys SET break_started_at = NOW() WHERE id = ?")) {
                    ps.setInt(1, db.getId());
                    ps.executeUpdate();
                }
            } else if ("ONLINE".equals(state)) {
                // End break: accumulate seconds into total_break_seconds
                try (PreparedStatement ps = bCon.prepareStatement(
                        "UPDATE delivery_boys " +
                        "SET total_break_seconds = total_break_seconds + " +
                        "    GREATEST(0, TIMESTAMPDIFF(SECOND, break_started_at, NOW())), " +
                        "    break_started_at = NULL " +
                        "WHERE id = ? AND break_started_at IS NOT NULL")) {
                    ps.setInt(1, db.getId());
                    ps.executeUpdate();
                }
            } else if ("OFFLINE".equals(state)) {
                // Accumulate any active break then reset for next day
                try (PreparedStatement ps = bCon.prepareStatement(
                        "UPDATE delivery_boys " +
                        "SET total_break_seconds = total_break_seconds + " +
                        "    CASE WHEN break_started_at IS NOT NULL " +
                        "         THEN GREATEST(0, TIMESTAMPDIFF(SECOND, break_started_at, NOW())) " +
                        "         ELSE 0 END, " +
                        "    break_started_at = NULL " +
                        "WHERE id = ?")) {
                    ps.setInt(1, db.getId());
                    ps.executeUpdate();
                }
            }
        } catch (Exception e) { e.printStackTrace(); }

        // Keep session in sync
        db.setShiftStatus(state);
        db.setOnline("ONLINE".equals(state) || "ON_BREAK".equals(state));
        session.setAttribute("deliveryBoy", db);
        session.setAttribute("shiftStatus", state);

        // Notify delivery boy based on state
        if ("ONLINE".equals(state)) {
            NotificationDAO.sendShiftStarted(db.getId(), db.getName());
        } else if ("OFFLINE".equals(state)) {
            NotificationDAO.sendShiftEnded(db.getId(), db.getName());
        }

        out.print("{\"ok\":true,\"state\":\"" + state + "\"}");
    }

    private double getPendingRemittance(int deliveryBoyId) {
        try { return new CodLedgerDAO().getPendingRemittanceTotal(deliveryBoyId); }
        catch (Exception e) { e.printStackTrace(); return 0; }
    }

    private double getNetEarnings(int deliveryBoyId) {
        String sql =
            "SELECT COUNT(*) FROM delivery_assignments " +
            "WHERE delivery_boy_id=? AND UPPER(status)='DELIVERED' AND DATE(delivered_at)=CURDATE()";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, deliveryBoyId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1) * AppSettings.getPerDeliveryPay();
            }
        } catch (Exception e) { e.printStackTrace(); }
        return 0;
    }

    private double getWalletBalance(int deliveryBoyId) {
        String sql = "SELECT wallet FROM delivery_boys WHERE id=?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, deliveryBoyId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getDouble("wallet");
            }
        } catch (Exception e) { e.printStackTrace(); }
        return 0;
    }
}