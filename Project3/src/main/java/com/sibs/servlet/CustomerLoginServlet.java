package com.sibs.servlet;

import java.io.IOException;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import com.sibs.dao.UserDAO;
import com.sibs.model.User;
import com.sibs.util.PasswordUtil;

@WebServlet("/CustomerLoginServlet")
public class CustomerLoginServlet extends HttpServlet {

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String username = request.getParameter("username");
        String password = request.getParameter("password");

        UserDAO dao = new UserDAO();

        // Load user by username/role — verify password separately with BCrypt
        User user = dao.findByUsernameAndRole(username, "CUSTOMER");

        if (user != null && isPasswordValid(password, user.getPassword())) {
            HttpSession session = request.getSession();
            session.removeAttribute("user");
            session.removeAttribute("deliveryBoy");
            session.setAttribute("customer", user);

            // On-the-fly migration: re-hash with BCrypt if the stored hash is legacy SHA-256
            if (PasswordUtil.needsMigration(user.getPassword())) {
                dao.updatePassword(user.getId(), PasswordUtil.hashPassword(password));
            }

            response.sendRedirect(request.getContextPath() + "/customer-dashboard.jsp");
        } else {
            response.sendRedirect("customer-login.jsp?error=1");
        }
    }

    /**
     * Handles both BCrypt hashes (new) and legacy SHA-256 hashes (migration path).
     */
    private boolean isPasswordValid(String plain, String stored) {
        if (PasswordUtil.needsMigration(stored)) {
            return PasswordUtil.legacySHA256(plain).equals(stored);
        }
        return PasswordUtil.checkPassword(plain, stored);
    }
}