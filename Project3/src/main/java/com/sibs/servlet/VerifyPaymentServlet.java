package com.sibs.servlet;

import java.io.IOException;
import java.io.PrintWriter;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import com.sibs.dao.CartDAO;
import com.sibs.dao.CouponDAO;
import com.sibs.dao.NotificationDAO;
import com.sibs.dao.PaymentDAO;
import com.sibs.model.User;
import com.sibs.dao.OrderDAO;
import com.sibs.service.PaymentService;
import com.sibs.util.EmailService;
import java.util.Map;

@WebServlet("/verifyPayment")
public class VerifyPaymentServlet extends HttpServlet {

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
            out.print("{\"success\":false,\"redirect\":\"customer-login.jsp\"}");
            return;
        }

        String razorpayOrderId   = request.getParameter("razorpay_order_id");
        String razorpayPaymentId = request.getParameter("razorpay_payment_id");
        String razorpaySignature = request.getParameter("razorpay_signature");

        Object pidObj = session.getAttribute("pendingPaymentId");
        Object oidObj = session.getAttribute("pendingOrderId");

        if (pidObj == null || oidObj == null
                || razorpayOrderId   == null
                || razorpayPaymentId == null
                || razorpaySignature == null) {
            out.print("{\"success\":false,\"redirect\":\"payment-failed.jsp?error=missing_params\"}");
            return;
        }

        int paymentId = Integer.parseInt(pidObj.toString());
        int orderId   = Integer.parseInt(oidObj.toString());
        Object gidObj = session.getAttribute("pendingGroupId");
        int groupId   = (gidObj != null) ? Integer.parseInt(gidObj.toString()) : -1;

        Boolean isBuyNow = (Boolean) session.getAttribute("isBuyNow");
        if (isBuyNow == null) isBuyNow = false;

        try {
            // ── Duplicate payment guard ────────────────────────────
            if (paymentDAO.isDuplicatePayment(razorpayPaymentId)) {
                out.print("{\"success\":true,\"redirect\":\"payment-succes.jsp?duplicate=1\"}");
                return;
            }

            // ── Gateway reported failure ───────────────────────────
            if ("FAILED".equals(razorpaySignature)) {
                paymentService.failPayment(paymentId, orderId, "Payment failed on gateway");
                if (groupId > 0) new OrderDAO().cancelOrdersByGroup(groupId); // FIXED
                NotificationDAO.sendPaymentFailed(user.getId(), orderId, "Payment failed on gateway");
                cleanPendingSession(session);
                out.print("{\"success\":false,\"redirect\":\"payment-failed.jsp?error=payment_failed\"}");
                return;
            }

            // ── Verify Razorpay HMAC signature ────────────────────
            boolean valid = paymentService.verifySignature(
                    razorpayOrderId, razorpayPaymentId, razorpaySignature);

            if (valid) {
                boolean confirmed = paymentService.confirmPayment(
                        paymentId, orderId, razorpayPaymentId, razorpaySignature);

                if (confirmed) {
                    Boolean isSelectedPay = (Boolean) session.getAttribute("isSelectedPayment");
                    String[] selPids = (String[]) session.getAttribute("paymentSelectedProductIds");
                    if (!isBuyNow) {
                        if (isSelectedPay != null && isSelectedPay && selPids != null) {
                            new CartDAO().clearSelectedItems(user.getId(), selPids);
                        } else {
                            new CartDAO().clearCart(user.getId());
                        }
                    }

                    session.setAttribute("lastPaymentId",     paymentId);
                    session.setAttribute("lastTransactionId", razorpayPaymentId);
                    session.setAttribute("lastOrderId",       groupId > 0 ? groupId : orderId);

                    // ── Notification: payment success ──────────────
                    NotificationDAO.sendPaymentSuccess(user.getId(), orderId, razorpayPaymentId, "UPI/Card");
                    // Staff: new online order placed
                    String _cname = (user.getName() != null && !user.getName().isEmpty()) ? user.getName() : "Customer";
                    NotificationDAO.sendNewCODOrderToStaff(orderId, _cname);

                    // ── Coupon: increment usage on successful online payment ──
                    String _coupon = (String) session.getAttribute("pendingCouponCode");
                    if (_coupon != null && !_coupon.trim().isEmpty()) {
                        new CouponDAO().incrementUsage(_coupon);
                        session.removeAttribute("pendingCouponCode");
                    }

                    // ── Wallet: debit on successful online payment ────────────
                    try {
                        Object _wAmt = session.getAttribute("pendingWalletDeducted");
                        Object _wOrd = session.getAttribute("pendingWalletOrderId");
                        if (_wAmt != null) {
                            double _walletAmt = Double.parseDouble(_wAmt.toString());
                            int    _wOrdId    = _wOrd != null ? Integer.parseInt(_wOrd.toString()) : orderId;
                            if (_walletAmt > 0) {
                                new com.sibs.dao.CustomerWalletDAO().debit(
                                    user.getId(), _walletAmt,
                                    "Used at checkout for Order #" + _wOrdId, _wOrdId
                                );
                            }
                            session.removeAttribute("pendingWalletDeducted");
                            session.removeAttribute("pendingWalletOrderId");
                        }
                    } catch (Exception _we) { _we.printStackTrace(); }

                    // ── Email: Order confirmation + next coupon hint ──────────
                    try {
                        String custEmail = user.getEmail();
                        if (custEmail != null && !custEmail.isEmpty()) {
                            double _total = 0;
                            try { Object t = session.getAttribute("pendingOrderTotal"); if(t!=null) _total=Double.parseDouble(t.toString()); } catch(Exception ignored){}
                            String nxtCode = null, nxtDesc = null;
                            for (Map<String,Object> c : new CouponDAO().getAllCoupons()) {
                                if (Integer.parseInt(String.valueOf(c.get("is_active"))) != 1) continue;
                                String cc = (String) c.get("code");
                                if (cc.equals(_coupon)) continue;
                                nxtCode = cc;
                                nxtDesc = (String) c.get("description");
                                String dtype = (String) c.get("discount_type");
                                double dval  = Double.parseDouble(String.valueOf(c.get("discount_value")));
                                if (nxtDesc == null || nxtDesc.trim().isEmpty())
                                    nxtDesc = "PERCENT".equals(dtype) ? (int)dval+"% off your next order" : "₹"+(int)dval+" off your next order";
                                break;
                            }
                            String _cust = (user.getName() != null && !user.getName().isEmpty()) ? user.getName() : user.getUsername();
                            EmailService.sendOrderConfirmationWithCoupon(custEmail, _cust, orderId, _total, "UPI/Card", nxtCode, nxtDesc);
                        }
                    } catch (Exception ex) { ex.printStackTrace(); }

                    cleanPendingSession(session);

                    out.print("{\"success\":true,\"redirect\":\"payment-succes.jsp\"}");
                } else {
                    out.print("{\"success\":false,\"redirect\":\"payment-failed.jsp?error=db_update_failed\"}");
                }
            } else {
                paymentService.failPayment(paymentId, orderId, "Signature verification failed");
                if (groupId > 0) new OrderDAO().cancelOrdersByGroup(groupId); // FIXED
                System.err.println("[SECURITY] Signature mismatch for payment " + razorpayPaymentId);
                out.print("{\"success\":false,\"redirect\":\"payment-failed.jsp?error=signature_mismatch\"}");
            }

        } catch (Exception e) {
            e.printStackTrace();
            out.print("{\"success\":false,\"redirect\":\"payment-failed.jsp?error=server_error\"}");
        }
    }

    private void cleanPendingSession(HttpSession session) {
        session.removeAttribute("pendingPaymentId");
        session.removeAttribute("pendingOrderId");
        session.removeAttribute("pendingAmount");
        session.removeAttribute("pendingOrderTotal");
        session.removeAttribute("isBuyNow");
        session.removeAttribute("pendingGroupId");
        session.removeAttribute("pendingCouponCode");
    }
}