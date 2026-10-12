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

@WebServlet("/login")
public class LoginServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String username = request.getParameter("username");
        String password = request.getParameter("password");
        String role     = request.getParameter("role");

        UserDAO dao = new UserDAO();

        // Load user by username/role only — password checked separately with BCrypt
        User user = dao.findByUsernameAndRole(username, role);

        if (user != null && isPasswordValid(password, user.getPassword())) {
            HttpSession session = request.getSession();
            session.removeAttribute("customer");
            session.removeAttribute("deliveryBoy");
            session.setAttribute("user", user);

            // On-the-fly migration: re-hash with BCrypt if the stored hash is legacy SHA-256
            if (PasswordUtil.needsMigration(user.getPassword())) {
                dao.updatePassword(user.getId(), PasswordUtil.hashPassword(password));
            }

            if ("ADMIN".equals(user.getRole())) {
                response.sendRedirect("dashboard.jsp");
            } else if ("STAFF".equals(user.getRole())) {
                response.sendRedirect("staff-dashboard.jsp");
            } else {
                response.sendRedirect("login.jsp?error=invalidrole");
            }
        } else {
            response.sendRedirect("login.jsp?error=1");
        }
    }

    /**
     * Handles both BCrypt hashes (new) and legacy SHA-256 hashes (migration path).
     */
    private boolean isPasswordValid(String plain, String stored) {
        if (PasswordUtil.needsMigration(stored)) {
            // Legacy SHA-256 — compare the old way during transition
            return PasswordUtil.legacySHA256(plain).equals(stored);
        }
        return PasswordUtil.checkPassword(plain, stored);
    }
}