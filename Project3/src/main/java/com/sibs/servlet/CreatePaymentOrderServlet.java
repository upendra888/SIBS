package com.sibs.servlet;

import java.io.IOException;
import java.io.PrintWriter;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import com.sibs.dao.PaymentDAO;
import com.sibs.model.Payment;
import com.sibs.model.User;
import com.sibs.service.PaymentService;

/**
 * CreatePaymentOrderServlet
 *
 * URL: POST /createPaymentOrder
 *
 * Flow:
 *  1. Customer clicks "Pay via UPI/Card" on checkout or payment page
 *  2. This servlet is called via AJAX with orderId + amount
 *  3. We call Razorpay API to get razorpay_order_id
 *  4. Save a PENDING payment record in DB
 *  5. Return JSON {razorpayOrderId, keyId, amount, paymentId} to frontend
 *  6. Frontend opens Razorpay checkout modal
 */
@WebServlet("/createPaymentOrder")
public class CreatePaymentOrderServlet extends HttpServlet {

    private PaymentService paymentService;
    private final PaymentDAO     paymentDAO     = new PaymentDAO();

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();
        paymentService = new PaymentService(getServletContext());

        HttpSession session = request.getSession(false);
        User user = (session != null) ? (User) session.getAttribute("customer") : null;

        if (user == null) {
            response.setStatus(401);
            out.print("{\"error\":\"Not logged in\"}");
            return;
        }

        String orderIdStr = request.getParameter("orderId");
        String amountStr  = request.getParameter("amount");

        if (orderIdStr == null || orderIdStr.isEmpty() || amountStr == null || amountStr.isEmpty()) {
            response.setStatus(400);
            out.print("{\"error\":\"Missing orderId or amount\"}");
            return;
        }

        try {
            int    orderId = Integer.parseInt(orderIdStr.trim());
            double amount  = Double.parseDouble(amountStr.trim());

            // 1. Call Razorpay API to create order
            String json            = paymentService.createRazorpayOrder(amount, orderId);
            String razorpayOrderId = paymentService.extractJsonField(json, "id");

            if (razorpayOrderId == null || razorpayOrderId.isEmpty()) {
                response.setStatus(500);
                out.print("{\"error\":\"Razorpay order creation failed\"}");
                return;
            }

            // 2. Save PENDING payment record in DB
            Payment payment = new Payment(orderId, user.getId(), amount, razorpayOrderId);
            int paymentId = paymentDAO.createPayment(payment);

            if (paymentId < 1) {
                response.setStatus(500);
                out.print("{\"error\":\"Failed to create payment record\"}");
                return;
            }

            // 3. Store in session for VerifyPaymentServlet
            session.setAttribute("pendingPaymentId", paymentId);
            session.setAttribute("pendingOrderId",   orderId);
            session.setAttribute("pendingAmount",    amount);

            // 4. Return details to frontend
            String phone = user.getPhone();
            if (phone == null) phone = "";
            String email = user.getEmail();
            if (email == null) email = "";

            out.print("{"
                + "\"razorpayOrderId\":\"" + razorpayOrderId + "\","
                + "\"keyId\":\""           + paymentService.getRazorpayKeyId() + "\","
                + "\"amount\":"            + Math.round(amount * 100) + ","
                + "\"currency\":\"INR\","
                + "\"paymentId\":"         + paymentId + ","
                + "\"customerName\":\""    + escapeJson(user.getUsername()) + "\","
                + "\"customerEmail\":\""   + escapeJson(email) + "\","
                + "\"customerPhone\":\""   + escapeJson(phone) + "\""
                + "}");

        } catch (NumberFormatException e) {
            response.setStatus(400);
            out.print("{\"error\":\"Invalid orderId or amount format\"}");
        } catch (Exception e) {
            e.printStackTrace();
            response.setStatus(500);
            String msg = e.getMessage() != null ? e.getMessage() : "Unknown error";
            out.print("{\"error\":\"" + escapeJson(msg) + "\"}");
        }
    }

    private String escapeJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "");
    }
}
