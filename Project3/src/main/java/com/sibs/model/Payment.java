package com.sibs.model;

import java.sql.Timestamp;

/**
 * Payment model — maps to the `payments` table.
 * Carries Razorpay IDs so the backend can verify
 * every transaction server-side (never trust the frontend).
 */
public class Payment {

    // ── Primary fields ────────────────────────────────────────
    private int       paymentId;
    private int       orderId;
    private int       userId;
    private String    paymentMethod;   // ONLINE | COD
    private double    amount;
    private String    currency;        // INR

    // ── Razorpay fields ───────────────────────────────────────
    private String    razorpayOrderId;
    private String    razorpayPaymentId;
    private String    razorpaySignature;

    // ── Status ────────────────────────────────────────────────
    /** PENDING | SUCCESS | FAILED | REFUNDED */
    private String    status;
    private String    failureReason;
    private String    refundId;        // Razorpay refund ID after cancellation

    // ── Timestamps ────────────────────────────────────────────
    private Timestamp paymentDate;
    private Timestamp updatedAt;

    // ── Constructors ──────────────────────────────────────────
    public Payment() {}

    public Payment(int orderId, int userId, double amount,
                   String razorpayOrderId) {
        this.orderId         = orderId;
        this.userId          = userId;
        this.amount          = amount;
        this.razorpayOrderId = razorpayOrderId;
        this.currency        = "INR";
        this.paymentMethod   = "ONLINE";
        this.status          = "PENDING";
    }

    // ── Getters & Setters ─────────────────────────────────────
    public int getPaymentId() { return paymentId; }
    public void setPaymentId(int paymentId) { this.paymentId = paymentId; }

    public int getOrderId() { return orderId; }
    public void setOrderId(int orderId) { this.orderId = orderId; }

    public int getUserId() { return userId; }
    public void setUserId(int userId) { this.userId = userId; }

    public String getPaymentMethod() { return paymentMethod; }
    public void setPaymentMethod(String paymentMethod) { this.paymentMethod = paymentMethod; }

    public double getAmount() { return amount; }
    public void setAmount(double amount) { this.amount = amount; }

    public String getCurrency() { return currency; }
    public void setCurrency(String currency) { this.currency = currency; }

    public String getRazorpayOrderId() { return razorpayOrderId; }
    public void setRazorpayOrderId(String razorpayOrderId) { this.razorpayOrderId = razorpayOrderId; }

    public String getRazorpayPaymentId() { return razorpayPaymentId; }
    public void setRazorpayPaymentId(String razorpayPaymentId) { this.razorpayPaymentId = razorpayPaymentId; }

    public String getRazorpaySignature() { return razorpaySignature; }
    public void setRazorpaySignature(String razorpaySignature) { this.razorpaySignature = razorpaySignature; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getFailureReason() { return failureReason; }
    public void setFailureReason(String failureReason) { this.failureReason = failureReason; }

    public String getRefundId() { return refundId; }
    public void setRefundId(String refundId) { this.refundId = refundId; }

    public Timestamp getPaymentDate() { return paymentDate; }
    public void setPaymentDate(Timestamp paymentDate) { this.paymentDate = paymentDate; }

    public Timestamp getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Timestamp updatedAt) { this.updatedAt = updatedAt; }

    @Override
    public String toString() {
        return "Payment{paymentId=" + paymentId
             + ", orderId=" + orderId
             + ", amount=" + amount
             + ", status=" + status + "}";
    }
}