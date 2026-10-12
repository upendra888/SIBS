package com.sibs.servlet;

import java.io.IOException;

import com.sibs.dao.UserDAO;
import com.sibs.model.User;
import com.sibs.util.PasswordUtil;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/register")
public class RegisterServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        User admin = session != null ? (User) session.getAttribute("user") : null;
        if (admin == null || !"ADMIN".equals(admin.getRole())) {
            response.sendRedirect("login.jsp");
            return;
        }

        String username = request.getParameter("username");
        String email = request.getParameter("email");
        String password = request.getParameter("password");

        if (username == null || email == null || password == null
                || username.isBlank() || email.isBlank() || password.isBlank()) {
            response.sendRedirect("admin-register.jsp?error=failed");
            return;
        }

        UserDAO dao = new UserDAO();

        if (dao.isUsernameExists(username)) {
            response.sendRedirect("admin-register.jsp?error=username");
            return;
        }

        if (dao.isEmailExists(email)) {
            response.sendRedirect("admin-register.jsp?error=email");
            return;
        }

        User user = new User();
        user.setUsername(username.trim());
        user.setEmail(email.trim());
        user.setPassword(PasswordUtil.hashPassword(password));

        if (dao.registerAdmin(user)) {
            response.sendRedirect("users.jsp?success=admin_created");
        } else {
            response.sendRedirect("admin-register.jsp?error=failed");
        }
    }
}
