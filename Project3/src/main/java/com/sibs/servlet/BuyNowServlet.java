package com.sibs.servlet;

import java.io.IOException;

import com.sibs.model.User;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

@WebServlet("/buyNow")
public class BuyNowServlet extends HttpServlet {

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        User user = session != null ? (User) session.getAttribute("customer") : null;
        if (user == null) {
            response.sendRedirect("customer-login.jsp");
            return;
        }

        int productId = Integer.parseInt(request.getParameter("productId"));
        int qty       = Integer.parseInt(request.getParameter("qty"));

        session = request.getSession();
        session.setAttribute("buyNowProductId", productId);
        session.setAttribute("buyNowQty", qty);

        response.sendRedirect("cartCheckout.jsp");
    }
}
