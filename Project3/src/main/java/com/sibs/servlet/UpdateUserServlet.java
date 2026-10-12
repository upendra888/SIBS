package com.sibs.servlet;

import java.io.IOException;

import com.sibs.dao.UserDAO;
import com.sibs.model.User;
import com.sibs.util.PasswordUtil;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

@WebServlet("/updateUser")
public class UpdateUserServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        User sessionUser = (User) session.getAttribute("user");
        User sessionCustomer = (User) session.getAttribute("customer");
        User actor = sessionUser != null ? sessionUser : sessionCustomer;

        if (actor == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        int id;
        try {
            id = Integer.parseInt(request.getParameter("id"));
        } catch (NumberFormatException e) {
            response.sendRedirect("login.jsp?error=invalid");
            return;
        }

        boolean isAdmin = sessionUser != null && "ADMIN".equals(sessionUser.getRole());
        if (id != actor.getId() && !isAdmin) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN);
            return;
        }

        UserDAO dao = new UserDAO();
        User user = dao.getUserById(id);
        if (user == null) {
            response.sendRedirect("login.jsp?error=notfound");
            return;
        }

        String name = request.getParameter("name");
        String username = request.getParameter("username");
        String phone = request.getParameter("phone");
        String address = request.getParameter("address");
        String gender = request.getParameter("gender");
        String redirect = request.getParameter("redirect");

        if (name != null && !name.isBlank()) user.setName(name.trim());
        if (username != null && !username.isBlank()) user.setUsername(username.trim());
        if (phone != null) user.setPhone(phone.trim());
        if (address != null) user.setAddress(address.trim());
        if (gender != null) user.setGender(gender.trim());

        if (isAdmin && id != actor.getId()) {
            String email = request.getParameter("email");
            String role = request.getParameter("role");
            String status = request.getParameter("status");
            if (email != null && !email.isBlank()) user.setEmail(email.trim());
            if (role != null && !role.isBlank()) user.setRole(role);
            if (status != null && !status.isBlank()) user.setStatus(status);
        }

        if (!dao.updateUser(user)) {
            response.sendRedirect((redirect != null ? redirect : "login.jsp") + "?error=1");
            return;
        }

        String newPassword = request.getParameter("password");
        if (newPassword != null && !newPassword.isBlank()) {
            dao.updatePassword(id, PasswordUtil.hashPassword(newPassword));
        }

        User refreshed = dao.getUserById(id);
        if (sessionUser != null && sessionUser.getId() == id) {
            session.setAttribute("user", refreshed);
        }
        if (sessionCustomer != null && sessionCustomer.getId() == id) {
            session.setAttribute("customer", refreshed);
        }

        String target = redirect != null && !redirect.isBlank() ? redirect
                : ("CUSTOMER".equalsIgnoreCase(user.getRole()) ? "customer-profile.jsp" : "admin-profile.jsp");
        response.sendRedirect(target + "?updated=1");
    }
}
