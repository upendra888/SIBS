package com.sibs.servlet;

import com.sibs.dao.DeliveryBoyDAO;
import com.sibs.model.DeliveryBoy;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;

public class DeliveryBoyLoginServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        String email    = req.getParameter("email");
        String password = req.getParameter("password");

        DeliveryBoy deliveryBoy = new DeliveryBoyDAO().login(email, password);

        if (deliveryBoy != null) {
            HttpSession session = req.getSession();
            // Clear other role sessions to prevent cross-role notification leaks
session.removeAttribute("user");
session.removeAttribute("customer");
session.setAttribute("deliveryBoy", deliveryBoy);
            new DeliveryBoyDAO().setOnlineStatus(deliveryBoy.getId(), true);
            res.sendRedirect("delivery-dashboard.jsp");
        } else {
            res.sendRedirect("delivery-login.jsp?error=1");
        }
    }
}