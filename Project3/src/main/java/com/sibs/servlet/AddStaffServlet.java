package com.sibs.servlet;

import java.io.IOException;

import com.sibs.dao.UserDAO;
import com.sibs.dao.NotificationDAO;
import com.sibs.model.User;
import com.sibs.util.EmailService;
import com.sibs.util.PasswordUtil;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@WebServlet("/addStaff")
public class AddStaffServlet extends HttpServlet {

    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        // Auth check
        User loggedIn = (User) request.getSession().getAttribute("user");
        if (loggedIn == null || !"ADMIN".equals(loggedIn.getRole())) {
            response.sendRedirect("login.jsp");
            return;
        }

        String username = request.getParameter("username");
        String email    = request.getParameter("email");
        String password = request.getParameter("password");
        String role     = request.getParameter("role");
        String status   = request.getParameter("status");

        UserDAO dao = new UserDAO();

        // Check Username Exists
        if (dao.isUsernameExists(username)) {
            response.sendRedirect("add-staff.jsp?error=username");
            return;
        }

        // Check Email Exists
        if (dao.isEmailExists(email)) {
            response.sendRedirect("add-staff.jsp?error=email");
            return;
        }

        // Hash Password
        String hashedPassword = PasswordUtil.hashPassword(password);

        User user = new User();
        user.setUsername(username);
        user.setEmail(email);
        user.setPassword(hashedPassword);
        user.setRole(role != null ? role : "STAFF");
        user.setStatus(status != null ? status : "ACTIVE");

        boolean success = dao.addStaff(user);

        if (success) {
            // Send welcome email with login credentials to the staff member's email
            EmailService.sendStaffWelcomeEmail(email, username, null);

            // ── Notifications ─────────────────────────────────────────
            // Fetch new staff ID to send them a personal welcome notification
            User newStaff = dao.getUserByUsername(username);
            if (newStaff != null) {
                String displayName = (newStaff.getName() != null && !newStaff.getName().isEmpty())
                    ? newStaff.getName() : username;
                // Welcome notification on new staff's own bell
                NotificationDAO.sendStaffWelcome(newStaff.getId(), displayName);
                // Broadcast to all admins/staff: new team member joined
                NotificationDAO.sendNewStaffToAdmin(displayName,
                    role != null ? role : "STAFF");
            }
            // ─────────────────────────────────────────────────────────

            response.sendRedirect("add-staff.jsp?success=1");
        } else {
            response.sendRedirect("add-staff.jsp?error=failed");
        }
    }
}