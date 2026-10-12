package com.sibs.servlet;

import com.sibs.dao.NotificationDAO;
import com.sibs.model.DeliveryBoy;
import com.sibs.service.PaymentService;
import com.sibs.util.DBConnection;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

/**
 * WalletRechargeServlet
 *
 * GET  /walletRecharge?step=createOrder&amount=200
 *      → Creates Razorpay order and returns JSON { razorpayOrderId, keyId, amount }
 *
 * POST /walletRecharge
 *      → Called after Razorpay payment succeeds.
 *        Verifies signature, then credits the delivery_boys.wallet column.
 *
 * Params (POST):
 *   amount                - recharge amount (min 200)
 *   razorpay_payment_id   - from Razorpay handler
 *   razorpay_order_id     - from Razorpay handler
 *   razorpay_signature    - HMAC verified
 */
@WebServlet("/walletRecharge")
public class WalletRechargeServlet extends HttpServlet {

    private PaymentService paymentService;

    // ── STEP 1: Create Razorpay order ────────────────────────────────────────
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws IOException {

        HttpSession session = req.getSession(false);
        DeliveryBoy db = session != null
                ? (DeliveryBoy) session.getAttribute("deliveryBoy") : null;

        if (db == null) {
            res.setStatus(401);
            res.setContentType("application/json");
            res.getWriter().write("{\"error\":\"Not logged in\"}");
            return;
        }

        paymentService = new PaymentService(getServletContext());

        double amount = 200.0; // default minimum
        try {
            String a = req.getParameter("amount");
            if (a != null && !a.isBlank()) amount = Double.parseDouble(a.trim());
        } catch (NumberFormatException ignored) {}

        if (amount < 200) {
            res.setStatus(400);
            res.setContentType("application/json");
            res.getWriter().write("{\"error\":\"Minimum recharge is ₹200\"}");
            return;
        }

        res.setContentType("application/json");
        res.setCharacterEncoding("UTF-8");
        PrintWriter out = res.getWriter();

        try {
            String razorpayJson    = paymentService.createRazorpayOrder(amount, db.getId());
            String razorpayOrderId = paymentService.extractJsonField(razorpayJson, "id");

            if (razorpayOrderId == null || razorpayOrderId.isEmpty()) {
                res.setStatus(500);
                out.write("{\"error\":\"Razorpay order creation failed\"}");
                return;
            }

            session.setAttribute("walletRazorpayOrderId", razorpayOrderId);
            session.setAttribute("walletRechargeAmount", amount);

            out.write("{" +
                "\"razorpayOrderId\":\"" + razorpayOrderId + "\"," +
                "\"keyId\":\""           + paymentService.getRazorpayKeyId() + "\"," +
                "\"amount\":"            + Math.round(amount * 100) +
            "}");

        } catch (Exception e) {
            e.printStackTrace();
            res.setStatus(500);
            out.write("{\"error\":\"" + e.getMessage() + "\"}");
        }
    }

    // ── STEP 2: Verify payment and credit wallet ──────────────────────────────
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws IOException {

        HttpSession session = req.getSession(false);
        DeliveryBoy db = session != null
                ? (DeliveryBoy) session.getAttribute("deliveryBoy") : null;

        if (db == null) {
            res.sendRedirect("delivery-login.jsp");
            return;
        }

        paymentService = new PaymentService(getServletContext());

        String paymentId = req.getParameter("razorpay_payment_id");
        String orderId   = req.getParameter("razorpay_order_id");
        String signature = req.getParameter("razorpay_signature");

        if (paymentId == null || paymentId.isBlank() ||
            orderId   == null || orderId.isBlank()   ||
            signature == null || signature.isBlank()) {
            System.err.println("[WalletRechargeServlet] Missing Razorpay params.");
            res.sendRedirect("delivery-wallet.jsp?flash=recharge_error");
            return;
        }

        String sessionOrderId = (String) session.getAttribute("walletRazorpayOrderId");
        if (sessionOrderId == null || !sessionOrderId.equals(orderId)) {
            System.err.println("[WalletRechargeServlet] Order ID mismatch! " +
                "session=" + sessionOrderId + " posted=" + orderId);
            res.sendRedirect("delivery-wallet.jsp?flash=recharge_error");
            return;
        }

        try {
            boolean valid = paymentService.verifySignature(orderId, paymentId, signature);
            if (!valid) {
                System.err.println("[WalletRechargeServlet] Signature verification FAILED.");
                res.sendRedirect("delivery-wallet.jsp?flash=recharge_error");
                return;
            }
        } catch (Exception e) {
            e.printStackTrace();
            res.sendRedirect("delivery-wallet.jsp?flash=recharge_error");
            return;
        }

        double amount = 200.0;
        Object amt = session.getAttribute("walletRechargeAmount");
        if (amt != null) amount = (double) amt;

        try (Connection con = DBConnection.getConnection()) {

            // Ensure wallet_transactions table exists
            con.createStatement().execute(
                "CREATE TABLE IF NOT EXISTS wallet_transactions (" +
                "  id               INT AUTO_INCREMENT PRIMARY KEY," +
                "  delivery_boy_id  INT NOT NULL," +
                "  amount           DECIMAL(10,2) NOT NULL," +
                "  type             ENUM('CREDIT','DEBIT') NOT NULL DEFAULT 'CREDIT'," +
                "  note             VARCHAR(500)," +
                "  created_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP" +
                ")"
            );

            // Idempotency check
            boolean alreadyRecorded = false;
            try (PreparedStatement check = con.prepareStatement(
                    "SELECT COUNT(*) FROM wallet_transactions WHERE note LIKE ?")) {
                check.setString(1, "%" + paymentId + "%");
                try (ResultSet rs = check.executeQuery()) {
                    if (rs.next() && rs.getInt(1) > 0) {
                        alreadyRecorded = true;
                    }
                }
            }

            if (!alreadyRecorded) {
                String note = "Wallet recharge via Razorpay | payment_id=" + paymentId
                            + " | order_id=" + orderId;

                // Record transaction log
                try (PreparedStatement ps = con.prepareStatement(
                        "INSERT INTO wallet_transactions (delivery_boy_id, amount, type, note) VALUES (?, ?, 'CREDIT', ?)")) {
                    ps.setInt(1, db.getId());
                    ps.setDouble(2, amount);
                    ps.setString(3, note);
                    ps.executeUpdate();
                }

                // Credit delivery_boys.wallet
                try (PreparedStatement ps = con.prepareStatement(
                        "UPDATE delivery_boys SET wallet = wallet + ? WHERE id = ?")) {
                    ps.setDouble(1, amount);
                    ps.setInt(2, db.getId());
                    ps.executeUpdate();
                }

                // Refresh session
                try (PreparedStatement ps = con.prepareStatement(
                        "SELECT wallet FROM delivery_boys WHERE id = ?")) {
                    ps.setInt(1, db.getId());
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            db.setWallet(rs.getDouble("wallet"));
                            session.setAttribute("deliveryBoy", db);
                        }
                    }
                }

                System.out.println("[WalletRechargeServlet] Wallet credited ₹" + amount +
                    " for delivery_boy_id=" + db.getId());
            }

        } catch (Exception e) {
            System.err.println("[WalletRechargeServlet] DB error: " + e.getMessage());
            e.printStackTrace();
            res.sendRedirect("delivery-wallet.jsp?flash=recharge_error");
            return;
        }

        session.removeAttribute("walletRazorpayOrderId");
        session.removeAttribute("walletRechargeAmount");

        // Notify delivery boy: wallet recharged
        NotificationDAO.sendEarningsCredited(db.getId(), amount, "wallet recharge");

        res.sendRedirect("delivery-dashboard.jsp?flash=recharged");
    }
}