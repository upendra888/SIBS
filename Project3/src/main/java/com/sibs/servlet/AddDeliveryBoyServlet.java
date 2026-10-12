package com.sibs.servlet;

import com.sibs.dao.DeliveryBoyDAO;
import com.sibs.model.DeliveryBoy;
import com.sibs.model.User;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.*;
import java.io.IOException;

public class AddDeliveryBoyServlet extends HttpServlet {
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        User user = (User) req.getSession().getAttribute("user");
        if (user == null || !"STAFF".equals(user.getRole())) {
            res.sendRedirect("login.jsp");
            return;
        }

        DeliveryBoy db = new DeliveryBoy();
        db.setName(req.getParameter("name"));
        db.setPhone(req.getParameter("phone"));
        db.setEmail(req.getParameter("email"));
        db.setPassword(com.sibs.util.PasswordUtil.hashPassword(req.getParameter("password"))); // BCrypt hash

        boolean success = new DeliveryBoyDAO().addDeliveryBoy(db);

        if (success) {
            res.sendRedirect("manage-delivery-boys.jsp?msg=Delivery+Boy+Added");
        } else {
            res.sendRedirect("manage-delivery-boys.jsp?error=Failed+to+add");
        }
    }
}