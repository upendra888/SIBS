package com.sibs.servlet;

import com.sibs.dao.DeliveryBoyDAO;
import com.sibs.dao.NotificationDAO;
import com.sibs.model.DeliveryBoy;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.net.URLEncoder;

@WebServlet("/deliveryRegister")
public class Deliveryboyregisterservlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        String name            = req.getParameter("name");
        String email           = req.getParameter("email");
        String phone           = req.getParameter("phone");
        String city            = req.getParameter("city");
        String password        = req.getParameter("password");
        String confirmPassword = req.getParameter("confirmPassword");

        if (password == null || !password.equals(confirmPassword)) {
            res.sendRedirect("delivery-register.jsp?error=password");
            return;
        }

        DeliveryBoyDAO dao = new DeliveryBoyDAO();

        if (dao.isEmailExists(email)) {
            res.sendRedirect("delivery-register.jsp?error=email");
            return;
        }

        if (dao.isPhoneExists(phone)) {
            res.sendRedirect("delivery-register.jsp?error=phone");
            return;
        }

        DeliveryBoy db = new DeliveryBoy();
        db.setName(name);
        db.setEmail(email);
        db.setPhone(phone);
        db.setPassword(com.sibs.util.PasswordUtil.hashPassword(password)); // BCrypt hash

        // ── DEBUG: capture exact SQL error ──────────────────────
        String sqlError = DeliveryBoyDAO.lastError;
        DeliveryBoyDAO.lastError = null;

        int newId = dao.registerDeliveryBoy(db, city);

        sqlError = DeliveryBoyDAO.lastError; // grab error AFTER the call

        if (newId > 0) {
            HttpSession session = req.getSession(true);
            session.setAttribute("pending_delivery_boy_id", newId);
            // ── Notify delivery boy: registration received ────────────
            NotificationDAO.sendRegistrationReceived(newId, name);
            // ─────────────────────────────────────────────────────────
            res.sendRedirect("delivery-documents.jsp");
        } else {
            String msg = (sqlError != null)
                ? URLEncoder.encode("DB Error: " + sqlError, "UTF-8")
                : "failed";
            res.sendRedirect("delivery-register.jsp?error=" + msg);
        }
    }
}