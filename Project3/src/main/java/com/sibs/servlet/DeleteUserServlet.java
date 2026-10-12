package com.sibs.servlet;

import java.io.IOException;

import com.sibs.dao.UserDAO;
import com.sibs.model.User;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

@WebServlet("/deleteUser")
public class DeleteUserServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        User admin = session != null ? (User) session.getAttribute("user") : null;
        if (admin == null || !"ADMIN".equals(admin.getRole())) {
            response.sendRedirect("login.jsp");
            return;
        }

        int id;
        try {
            id = Integer.parseInt(request.getParameter("id"));
        } catch (NumberFormatException e) {
            response.sendRedirect("users.jsp?error=1");
            return;
        }

        if (id == admin.getId()) {
            response.sendRedirect("users.jsp?error=self");
            return;
        }

        boolean status = new UserDAO().deleteUser(id);
        response.sendRedirect(status ? "users.jsp" : "users.jsp?error=1");
    }
}
