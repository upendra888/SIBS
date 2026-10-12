package com.sibs.servlet;

import java.io.IOException;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import com.sibs.dao.UserDAO;
import com.sibs.model.User;
import com.sibs.util.PasswordUtil;

@WebServlet("/CustomerRegisterServlet")
public class CustomerRegisterServlet extends HttpServlet {

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String username = request.getParameter("name");
        String email = request.getParameter("email");
        String phone = request.getParameter("phone");
        String password = request.getParameter("password");
        String confirmPassword = request.getParameter("confirmPassword");
        String address = request.getParameter("address");
        String gender = request.getParameter("gender");

        if (password == null || confirmPassword == null || !password.equals(confirmPassword)) {
            response.sendRedirect("customer-register.jsp?error=password");
            return;
        }

        UserDAO dao = new UserDAO();

        if (dao.isEmailExists(email)) {
            response.sendRedirect("customer-register.jsp?error=email");
            return;
        }

        if (dao.isUsernameExists(username)) {
            response.sendRedirect("customer-register.jsp?error=username");
            return;
        }

        // 🔐 HASH PASSWORD
        String hashedPassword = PasswordUtil.hashPassword(password);

        User user = new User();
        user.setName(username);
        user.setUsername(username);
        user.setEmail(email);
        user.setPhone(phone);
        user.setPassword(hashedPassword);
        user.setAddress(address);
        user.setGender(gender);

        if (!dao.registerCustomer(user)) {
            response.sendRedirect("customer-register.jsp?error=failed");
            return;
        }

        HttpSession session = request.getSession();
        session.setAttribute("msg", "Successfully Registered!");

        response.sendRedirect(request.getContextPath() + "/customer-login.jsp");
    }
}