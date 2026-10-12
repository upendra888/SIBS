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

/**
 * DeliveryDepositServlet
 *
 * GET  /deliveryDeposit?step=createOrder&amount=500
 *      → Calls PaymentService.createRazorpayOrder() and returns JSON
 *        { razorpayOrderId, keyId, amount } for the frontend Razorpay checkout.
 *
 * POST /deliveryDeposit
 *      → Called after Razorpay payment succeeds.
 *        Verifies signature, then records a CREDIT in delivery_deposits wallet.
 *
 * Params (POST):
 *   amount                - deposit amount (500)
 *   razorpay_payment_id   - from Razorpay handler
 *   razorpay_order_id     - from Razorpay handler
 *   razorpay_signature    - from Razorpay handler (HMAC verified)
 */
public class DeliveryDepositServlet extends HttpServlet {

    private PaymentService paymentService;

    // ── STEP 1: Frontend calls GET to create Razorpay order ──
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

        double amount = 500.0;
        try {
            String a = req.getParameter("amount");
            if (a != null && !a.isBlank()) amount = Double.parseDouble(a.trim());
        } catch (NumberFormatException ignored) {}

        res.setContentType("application/json");
        res.setCharacterEncoding("UTF-8");
        PrintWriter out = res.getWriter();

        try {
            // Reuse existing PaymentService — pass deliveryBoyId as "orderId" for receipt
            String razorpayJson    = paymentService.createRazorpayOrder(amount, db.getId());
            String razorpayOrderId = paymentService.extractJsonField(razorpayJson, "id");

            if (razorpayOrderId == null || razorpayOrderId.isEmpty()) {
                res.setStatus(500);
                out.write("{\"error\":\"Razorpay order creation failed\"}");
                return;
            }

            // Store in session so POST can verify
            session.setAttribute("depositRazorpayOrderId", razorpayOrderId);
            session.setAttribute("depositAmount", amount);

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

    // ── STEP 2: Called after Razorpay payment success ──
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

        String paymentId  = req.getParameter("razorpay_payment_id");
        String orderId    = req.getParameter("razorpay_order_id");
        String signature  = req.getParameter("razorpay_signature");

        // ── FIX 1: Validate that required POST params are present ──
        if (paymentId == null || paymentId.isBlank() ||
            orderId   == null || orderId.isBlank()   ||
            signature == null || signature.isBlank()) {
            System.err.println("[DeliveryDepositServlet] Missing Razorpay params in POST. " +
                "payment_id=" + paymentId + " order_id=" + orderId);
            res.sendRedirect("delivery-earnings.jsp?flash=deposit_error");
            return;
        }

        // ── FIX 2: Cross-check posted order_id against what we stored in session ──
        String sessionOrderId = (String) session.getAttribute("depositRazorpayOrderId");
        if (sessionOrderId == null || !sessionOrderId.equals(orderId)) {
            System.err.println("[DeliveryDepositServlet] Order ID mismatch! " +
                "session=" + sessionOrderId + " posted=" + orderId);
            res.sendRedirect("delivery-earnings.jsp?flash=deposit_error");
            return;
        }

        // ── FIX 3: Verify signature with detailed logging ──
        try {
            boolean valid = paymentService.verifySignature(orderId, paymentId, signature);
            if (!valid) {
                System.err.println("[DeliveryDepositServlet] Signature verification FAILED. " +
                    "payment_id=" + paymentId + " order_id=" + orderId);
                res.sendRedirect("delivery-earnings.jsp?flash=deposit_error");
                return;
            }
        } catch (Exception e) {
            System.err.println("[DeliveryDepositServlet] Exception during signature verification: " + e.getMessage());
            e.printStackTrace();
            res.sendRedirect("delivery-earnings.jsp?flash=deposit_error");
            return;
        }

        double amount = 500.0;
        Object amt = session.getAttribute("depositAmount");
        if (amt != null) amount = (double) amt;

        String note = "Security deposit via Razorpay | payment_id=" + paymentId
                    + " | order_id=" + orderId;

        try (Connection con = DBConnection.getConnection()) {

            // Ensure table exists with CREDIT/DEBIT type column
            con.createStatement().execute(
                "CREATE TABLE IF NOT EXISTS delivery_deposits (" +
                "  id               INT AUTO_INCREMENT PRIMARY KEY," +
                "  delivery_boy_id  INT NOT NULL," +
                "  amount           DECIMAL(10,2) NOT NULL DEFAULT 500.00," +
                "  type             ENUM('CREDIT','DEBIT') NOT NULL DEFAULT 'CREDIT'," +
                "  deposited_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP," +
                "  note             VARCHAR(500)" +
                ")"
            );

            // Safely add type column if upgrading old table
            try {
                con.createStatement().execute(
                    "ALTER TABLE delivery_deposits ADD COLUMN IF NOT EXISTS " +
                    "type ENUM('CREDIT','DEBIT') NOT NULL DEFAULT 'CREDIT'"
                );
            } catch (Exception ignored) {}

            // ── FIX 4: Idempotency — skip insert if this payment_id already recorded ──
            boolean alreadyRecorded = false;
            try (PreparedStatement check = con.prepareStatement(
                    "SELECT COUNT(*) FROM delivery_deposits WHERE note LIKE ?")) {
                check.setString(1, "%" + paymentId + "%");
                try (java.sql.ResultSet rs = check.executeQuery()) {
                    if (rs.next() && rs.getInt(1) > 0) {
                        alreadyRecorded = true;
                        System.out.println("[DeliveryDepositServlet] Payment already recorded (idempotent): " + paymentId);
                    }
                }
            }

            if (!alreadyRecorded) {
                // Record CREDIT in wallet
                String sql =
                    "INSERT INTO delivery_deposits (delivery_boy_id, amount, type, note) " +
                    "VALUES (?, ?, 'CREDIT', ?)";
                try (PreparedStatement ps = con.prepareStatement(sql)) {
                    ps.setInt(1, db.getId());
                    ps.setDouble(2, amount);
                    ps.setString(3, note);
                    int rows = ps.executeUpdate();
                    System.out.println("[DeliveryDepositServlet] Deposit recorded successfully. rows=" + rows +
                        " delivery_boy_id=" + db.getId() + " amount=" + amount);
                }
            }

        } catch (Exception e) {
            System.err.println("[DeliveryDepositServlet] DB error recording deposit: " + e.getMessage());
            e.printStackTrace();
            res.sendRedirect("delivery-earnings.jsp?flash=deposit_error");
            return;
        }

        // Clean session
        session.removeAttribute("depositRazorpayOrderId");
        session.removeAttribute("depositAmount");

        // Notify delivery boy: deposit successful
        NotificationDAO.sendEarningsCredited(db.getId(), amount, "wallet deposit");

        res.sendRedirect("delivery-earnings.jsp?flash=deposited");
    }
}