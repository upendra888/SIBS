package com.sibs.servlet;

import com.sibs.dao.DeliveryBoyDAO;
import com.sibs.model.DeliveryBoy;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;

@WebServlet("/ToggleOnlineServlet")
public class ToggleOnlineServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        // ── Session guard ─────────────────────────────────────────
        if (session == null || session.getAttribute("deliveryBoy") == null) {
            response.sendRedirect("delivery-login.jsp");
            return;
        }

        DeliveryBoy loggedIn = (DeliveryBoy) session.getAttribute("deliveryBoy");
        int deliveryBoyId = loggedIn.getId();

        // ── Read requested status from form ───────────────────────
        String onlineParam = request.getParameter("online"); // "true" or "false"
        boolean goOnline = "true".equalsIgnoreCase(onlineParam);

        // ── Call DAO (wallet check is inside DAO) ─────────────────
        DeliveryBoyDAO dao = new DeliveryBoyDAO();
        String result = dao.setOnlineStatus(deliveryBoyId, goOnline);

        if ("LOW_WALLET".equals(result)) {
            // ❌ Wallet too low — redirect back with error message
            session.setAttribute("onlineError",
                "Insufficient wallet balance! You need at least ₹200.00 to go online. " +
                "Current balance: ₹" + String.format("%.2f", loggedIn.getWallet()));
            response.sendRedirect("delivery-dashboard.jsp");
            return;
        }

        if ("OK".equals(result)) {
            // ✅ Update session object so dashboard reflects new status
            loggedIn.setOnline(goOnline);

            // Reload fresh data from DB (to sync wallet, stats, etc.)
            DeliveryBoy fresh = dao.getById(deliveryBoyId);
            if (fresh != null) {
                session.setAttribute("deliveryBoy", fresh);
            }
        }

        response.sendRedirect("delivery-dashboard.jsp");
    }
}