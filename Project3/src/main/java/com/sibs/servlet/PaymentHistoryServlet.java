package com.sibs.servlet;

import java.io.IOException;
import java.util.List;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import com.sibs.dao.PaymentDAO;
import com.sibs.model.Payment;
import com.sibs.model.User;

/**
 * PaymentHistoryServlet
 * URL: GET /paymentHistory
 * Forwards to payment-history.jsp with user's payment list.
 */
@WebServlet("/paymentHistory")
public class PaymentHistoryServlet extends HttpServlet {

    private final PaymentDAO paymentDAO = new PaymentDAO();

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        User user = (session != null)
                    ? (User) session.getAttribute("customer")
                    : null;

        if (user == null) {
            response.sendRedirect("customer-login.jsp");
            return;
        }

        List<Payment> payments = paymentDAO.getPaymentsByUser(user.getId());
        request.setAttribute("payments", payments);
        request.getRequestDispatcher("payment-history.jsp")
               .forward(request, response);
    }
}