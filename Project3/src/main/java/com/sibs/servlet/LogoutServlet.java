package com.sibs.servlet;

import java.io.IOException;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

@WebServlet("/logout")
public class LogoutServlet extends HttpServlet {

    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        String redirectPage = "login.jsp"; // default

        if (session != null) {

            // ✅ Check who is logged in BEFORE destroying session
            if (session.getAttribute("customer") != null) {
                redirectPage = "customer-login.jsp";
            } else if (session.getAttribute("user") != null) {
                redirectPage = "login.jsp";
            }

            session.invalidate(); // destroy session
        }

        // ✅ Dynamic redirect
        response.sendRedirect(request.getContextPath() + "/" + redirectPage);
    }
}