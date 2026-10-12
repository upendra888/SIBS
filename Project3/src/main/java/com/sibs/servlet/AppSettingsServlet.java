package com.sibs.servlet;

import com.sibs.model.User;
import com.sibs.util.AppSettings;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;

/**
 * AppSettingsServlet
 *
 * POST /appSettings
 *   Params:
 *     action           = "saveDeliveryPay"
 *     per_delivery_pay = numeric value (e.g. 60)
 *
 * Admin only.
 */
@WebServlet("/appSettings")
public class AppSettingsServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws IOException {

        // Admin auth check
        HttpSession session = req.getSession(false);
        User user = session != null ? (User) session.getAttribute("user") : null;
        if (user == null || !"ADMIN".equals(user.getRole())) {
            res.sendRedirect("login.jsp");
            return;
        }

        String action = req.getParameter("action");

        if ("saveDeliveryPay".equals(action)) {
            String payStr = req.getParameter("per_delivery_pay");
            try {
                double pay = Double.parseDouble(payStr.trim());
                if (pay <= 0) throw new NumberFormatException("Must be > 0");
                AppSettings.set(AppSettings.KEY_PER_DELIVERY_PAY, String.valueOf(pay));
                res.sendRedirect("admin-settings.jsp?flash=saved");
            } catch (Exception e) {
                res.sendRedirect("admin-settings.jsp?flash=invalid");
            }
            return;
        }

        res.sendRedirect("admin-settings.jsp");
    }
}