package com.sibs.servlet;

import com.sibs.dao.DeliveryBoyDAO;
import com.sibs.model.User;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.*;
import java.io.IOException;

public class DeleteDeliveryBoyServlet extends HttpServlet {
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        User user = (User) req.getSession().getAttribute("user");
        if (user == null || !"STAFF".equals(user.getRole())) {
            res.sendRedirect("login.jsp");
            return;
        }
        int id = Integer.parseInt(req.getParameter("id"));
        new DeliveryBoyDAO().deleteDeliveryBoy(id);
        res.sendRedirect("manage-delivery-boys.jsp?msg=Delivery+Boy+Deleted");
    }
}