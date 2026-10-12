package com.sibs.servlet;

import com.sibs.dao.DeliveryBoyDAO;
import com.sibs.model.DeliveryBoy;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.*;
import java.io.IOException;

public class DeliveryLogoutServlet extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        DeliveryBoy db = (DeliveryBoy) req.getSession().getAttribute("deliveryBoy");
        if (db != null) {
            new DeliveryBoyDAO().setOnlineStatus(db.getId(), false);
        }
        req.getSession().removeAttribute("deliveryBoy");
        res.sendRedirect("delivery-login.jsp");
    }
}