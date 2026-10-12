package com.sibs.servlet;

import java.io.IOException;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import com.sibs.model.User;
import com.sibs.dao.NotificationDAO;
import com.sibs.service.PaymentService;

/**
 * PaymentFailureServlet — called when Razorpay modal fires ondismiss() or payment.failed.
 */
@WebServlet("/paymentFailed")
public class PaymentFailureServlet extends HttpServlet {

    private PaymentService paymentService;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        User user = (session != null) ? (User) session.getAttribute("customer") : null;

        if (user == null) { response.sendRedirect("customer-login.jsp"); return; }

        paymentService = new PaymentService(getServletContext());

        String errorCode = request.getParameter("error_code");
        String errorDesc = request.getParameter("error_description");
        String reason    = (errorDesc != null && !errorDesc.isEmpty()) ? errorDesc : "Payment cancelled or declined";

        Object pidObj = session.getAttribute("pendingPaymentId");
        Object oidObj = session.getAttribute("pendingOrderId");

        if (pidObj != null && oidObj != null) {
            try {
                int paymentId = Integer.parseInt(pidObj.toString());
                int orderId   = Integer.parseInt(oidObj.toString());
                paymentService.failPayment(paymentId, orderId, reason);
                // ── Notify customer: payment failed ───────────────────
                NotificationDAO.sendPaymentFailed(user.getId(), orderId, reason);
                // ─────────────────────────────────────────────────────
            } catch (Exception e) { e.printStackTrace(); }
            session.removeAttribute("pendingPaymentId");
            session.removeAttribute("pendingOrderId");
            session.removeAttribute("pendingAmount");
        }

        System.out.println("[PaymentFailed] User=" + user.getId() + " code=" + errorCode + " reason=" + reason);

        response.sendRedirect("payment-failed.jsp?reason=" + java.net.URLEncoder.encode(reason, "UTF-8"));
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        doPost(request, response);
    }
}