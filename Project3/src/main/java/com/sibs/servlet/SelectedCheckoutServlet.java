package com.sibs.servlet;

import java.io.IOException;

import com.sibs.model.User;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

@WebServlet("/selectedCheckout")
public class SelectedCheckoutServlet extends HttpServlet {

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        User user = session != null ? (User) session.getAttribute("customer") : null;
        if (user == null) {
            response.sendRedirect("customer-login.jsp");
            return;
        }

        String[] productIds = request.getParameterValues("selectedProductIds");
        String[] qtys       = request.getParameterValues("selectedQtys");

        session = request.getSession();
        session.setAttribute("selectedProductIds", productIds);
        session.setAttribute("selectedQtys", qtys);
        session.setAttribute("isSelectedCheckout", true);

        response.sendRedirect("cartCheckout.jsp");
    }
}
