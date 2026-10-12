package com.sibs.servlet;

import com.sibs.dao.DeliveryBoyDAO;
import com.sibs.model.DeliveryBoy;
import com.sibs.util.PasswordUtil;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;

@WebServlet("/updateDeliveryBoy")
public class UpdateDeliveryBoyServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        HttpSession session = req.getSession(false);
        DeliveryBoy sessionDb = session != null
                ? (DeliveryBoy) session.getAttribute("deliveryBoy") : null;
        if (sessionDb == null) {
            resp.sendRedirect("delivery-login.jsp");
            return;
        }

        DeliveryBoyDAO dao = new DeliveryBoyDAO();
        DeliveryBoy db = dao.getById(sessionDb.getId());
        if (db == null) {
            resp.sendRedirect("delivery-login.jsp");
            return;
        }

        String name = req.getParameter("name");
        String phone = req.getParameter("phone");
        if (name != null && !name.isBlank()) db.setName(name.trim());
        if (phone != null) db.setPhone(phone.trim());

        dao.updateProfile(db);

        String pwd = req.getParameter("password");
        if (pwd != null && !pwd.isBlank()) {
            dao.updatePassword(db.getId(), PasswordUtil.hashPassword(pwd));
        }

        DeliveryBoy fresh = dao.getById(db.getId());
        if (fresh != null) {
            session.setAttribute("deliveryBoy", fresh);
        }

        resp.sendRedirect("delivery-profile.jsp?updated=1");
    }
}
