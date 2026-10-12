package com.sibs.service;

import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.security.InvalidKeyException;
import java.security.NoSuchAlgorithmException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.Base64;
import java.util.Scanner;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

import com.sibs.dao.OrderStatusHistoryDAO;
import com.sibs.dao.PaymentDAO;
import com.sibs.dao.ProductDAO;
import com.sibs.util.DBConnection;
import com.sibs.util.RazorpayConfig;

import jakarta.servlet.ServletContext;

public class PaymentService {

    private final ServletContext servletContext;
    private final PaymentDAO paymentDAO = new PaymentDAO();

    public PaymentService() {
        this.servletContext = null;
    }

    public PaymentService(ServletContext servletContext) {
        this.servletContext = servletContext;
    }

    private String keyId() {
        return RazorpayConfig.keyId(servletContext);
    }

    private String keySecret() {
        return RazorpayConfig.keySecret(servletContext);
    }

    public String createRazorpayOrder(double amountInRupees, int orderId) throws Exception {
        String id = keyId();
        String secret = keySecret();
        if (id.isEmpty() || secret.isEmpty()) {
            throw new IllegalStateException("Razorpay credentials not configured");
        }

        long amountInPaise = Math.round(amountInRupees * 100);
        String jsonBody = "{"
                + "\"amount\":" + amountInPaise + ","
                + "\"currency\":\"INR\","
                + "\"receipt\":\"sibs_order_" + orderId + "\","
                + "\"payment_capture\":1"
                + "}";
        URL url = new URL("https://api.razorpay.com/v1/orders");
        HttpURLConnection conn = (HttpURLConnection) url.openConnection();
        conn.setRequestMethod("POST");
        conn.setDoOutput(true);
        conn.setRequestProperty("Content-Type", "application/json");
        conn.setRequestProperty("Authorization",
                "Basic " + Base64.getEncoder().encodeToString(
                        (id + ":" + secret).getBytes(StandardCharsets.UTF_8)));
        try (OutputStream os = conn.getOutputStream()) {
            os.write(jsonBody.getBytes(StandardCharsets.UTF_8));
        }
        int responseCode = conn.getResponseCode();
        Scanner scanner = responseCode >= 200 && responseCode < 300
                ? new Scanner(conn.getInputStream(), StandardCharsets.UTF_8)
                : new Scanner(conn.getErrorStream(), StandardCharsets.UTF_8);
        StringBuilder sb = new StringBuilder();
        while (scanner.hasNext()) sb.append(scanner.nextLine());
        scanner.close();
        if (responseCode != 200) {
            throw new RuntimeException("Razorpay API error " + responseCode + ": " + sb);
        }
        return sb.toString();
    }

    public String extractJsonField(String json, String key) {
        String search = "\"" + key + "\":";
        int start = json.indexOf(search);
        if (start == -1) return null;
        start += search.length();
        char first = json.charAt(start);
        if (first == '"') {
            int end = json.indexOf('"', start + 1);
            return json.substring(start + 1, end);
        } else {
            int end = json.indexOf(',', start);
            if (end == -1) end = json.indexOf('}', start);
            return json.substring(start, end).trim();
        }
    }

    public boolean verifySignature(String razorpayOrderId,
                                   String razorpayPaymentId,
                                   String razorpaySignature)
            throws NoSuchAlgorithmException, InvalidKeyException {

        String secret = keySecret();
        if (secret.isEmpty()) {
            throw new IllegalStateException("Razorpay secret not configured");
        }

        String payload = razorpayOrderId + "|" + razorpayPaymentId;
        Mac mac = Mac.getInstance("HmacSHA256");
        mac.init(new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
        byte[] hash = mac.doFinal(payload.getBytes(StandardCharsets.UTF_8));
        String computed = bytesToHex(hash);
        return computed.equalsIgnoreCase(razorpaySignature);
    }

    public boolean confirmPayment(int paymentId, int orderId,
                                  String razorpayPaymentId,
                                  String razorpaySignature) {
        boolean ok = paymentDAO.markSuccess(paymentId, razorpayPaymentId, razorpaySignature);
        if (!ok) return false;
        Connection con = null;
        PreparedStatement ps = null;
        int groupId = -1;
        try {
            con = DBConnection.getConnection();
            PreparedStatement gps = con.prepareStatement("SELECT group_id FROM orders WHERE id=?");
            gps.setInt(1, orderId);
            ResultSet grs = gps.executeQuery();
            if (grs.next()) groupId = grs.getInt("group_id");
            gps.close();
            ps = con.prepareStatement(
                "UPDATE orders SET status='Pending', payment_status='PAID', " +
                "payment_method='ONLINE', transaction_id=? WHERE group_id=?");
            ps.setString(1, razorpayPaymentId);
            ps.setInt(2, groupId > 0 ? groupId : orderId);
            ok = ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        } finally {
            close(ps, con);
        }
        if (ok && groupId > 0) {
            new ProductDAO().deductStockByGroup(groupId);
            try {
                new OrderStatusHistoryDAO().logByGroup(groupId, "Placed", "Customer");
            } catch (Exception ignored) {}
        }
        return ok;
    }

    public boolean failPayment(int paymentId, int orderId, String reason) {
        paymentDAO.markFailed(paymentId, reason);
        Connection con = null;
        try {
            con = DBConnection.getConnection();
            int groupId = -1;
            try (PreparedStatement gps = con.prepareStatement("SELECT group_id FROM orders WHERE id=?")) {
                gps.setInt(1, orderId);
                try (ResultSet rs = gps.executeQuery()) {
                    if (rs.next()) groupId = rs.getInt("group_id");
                }
            }
            try (PreparedStatement ps = con.prepareStatement(
                    "UPDATE orders SET status='Failed', payment_status='FAILED' WHERE "
                    + (groupId > 0 ? "group_id=?" : "id=?"))) {
                ps.setInt(1, groupId > 0 ? groupId : orderId);
                return ps.executeUpdate() > 0;
            }
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        } finally {
            if (con != null) try { con.close(); } catch (Exception e) {}
        }
    }

    public String getRazorpayKeyId() { return keyId(); }

    private static String bytesToHex(byte[] bytes) {
        StringBuilder sb = new StringBuilder();
        for (byte b : bytes) sb.append(String.format("%02x", b));
        return sb.toString();
    }

    private void close(PreparedStatement ps, Connection con) {
        if (ps  != null) try { ps.close();  } catch (Exception e) {}
        if (con != null) try { con.close(); } catch (Exception e) {}
    }
}
