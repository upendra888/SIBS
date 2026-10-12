package com.sibs.util;

import jakarta.mail.*;
import jakarta.mail.internet.*;
import java.util.Properties;

public class EmailService {

    // ── Email credentials loaded from environment variables ──────────────────────
    // Set these in your server environment (Tomcat setenv.sh, OS env, or Docker):
    //   SIBS_MAIL_FROM=you@gmail.com
    //   SIBS_MAIL_PASSWORD=your_app_password
    //   SIBS_MAIL_ADMIN=admin@yourdomain.com
    //
    // NEVER hardcode credentials here. See README_SECURITY.md for setup instructions.
    private static final String FROM_EMAIL  = getEnv("SIBS_MAIL_FROM",  "no-reply@sibs.local");
    private static final String PASSWORD    = getEnv("SIBS_MAIL_PASSWORD", "");
    private static final String ADMIN_EMAIL = getEnv("SIBS_MAIL_ADMIN", FROM_EMAIL);

    private static String getEnv(String key, String fallback) {
        String val = System.getenv(key);
        return (val != null && !val.isBlank()) ? val : fallback;
    }

    // ── SMTP Session helper ───────────────────────────────────────────────────
    private static Session createSession() {
        Properties props = new Properties();
        props.put("mail.smtp.host", "smtp.gmail.com");
        props.put("mail.smtp.port", "587");
        props.put("mail.smtp.auth", "true");
        props.put("mail.smtp.starttls.enable", "true");
        return Session.getInstance(props, new Authenticator() {
            protected PasswordAuthentication getPasswordAuthentication() {
                return new PasswordAuthentication(FROM_EMAIL, PASSWORD);
            }
        });
    }

    // ── 1. ORDER STATUS EMAIL (existing) ─────────────────────────────────────
    public static void sendOrderStatusEmail(String toEmail, String customerName,
                                             String status, int orderId, String productName) {
        try {
            String subject = getSubject(status, orderId);
            String body    = getBody(customerName, status, orderId, productName);

            Message msg = new MimeMessage(createSession());
            msg.setFrom(new InternetAddress(FROM_EMAIL));
            msg.setRecipients(Message.RecipientType.TO, InternetAddress.parse(toEmail));
            msg.setSubject(subject);
            msg.setContent(body, "text/html; charset=utf-8");

            Transport.send(msg);
            System.out.println("[Email] Sent to " + toEmail + " — status: " + status);

        } catch (Exception e) {
            System.err.println("[Email] Failed: " + e.getMessage());
        }
    }

    // ── 2. REFUND EMAIL (NEW) ─────────────────────────────────────────────────
    // Sent to customer when online payment is refunded after cancellation
    public static void sendRefundEmail(String toEmail, String customerName,
                                        int orderId, double amount, String refundId) {
        try {
            String subject = "💰 Refund Initiated for Order #" + orderId + " — SIBS";
            String body = "<div style='font-family:Inter,sans-serif;max-width:500px;margin:auto;'>"
                + "<div style='background:#16a34a;padding:30px;text-align:center;border-radius:12px 12px 0 0;'>"
                + "<h1 style='color:#fff;font-size:28px;margin:0;'>💰 SIBS — Refund Initiated</h1>"
                + "</div>"
                + "<div style='background:#fff;padding:30px;border:1px solid #e2e8f0;border-radius:0 0 12px 12px;'>"
                + "<h2 style='color:#0f172a;'>Hello, " + customerName + "!</h2>"
                + "<p style='color:#64748b;font-size:15px;'>Your order has been cancelled and your refund has been initiated successfully.</p>"
                + "<div style='background:#f0fdf4;border:1px solid #bbf7d0;border-radius:8px;padding:16px;margin:20px 0;'>"
                + "<p style='margin:0;color:#0f172a;'><b>Order ID:</b> #" + orderId + "</p>"
                + "<p style='margin:8px 0 0;color:#0f172a;'><b>Refund Amount:</b> ₹" + String.format("%.2f", amount) + "</p>"
                + "<p style='margin:8px 0 0;color:#0f172a;'><b>Refund ID:</b> " + refundId + "</p>"
                + "<p style='margin:8px 0 0;color:#0f172a;'><b>Expected Timeline:</b> 5–7 business days</p>"
                + "</div>"
                + "<p style='color:#64748b;font-size:14px;'>The refund will be credited to your original payment method (UPI/Card/Net Banking).</p>"
                + "<p style='color:#94a3b8;font-size:12px;text-align:center;margin-top:20px;'>SIBS — Smart Inventory &amp; Billing System</p>"
                + "</div></div>";

            Message msg = new MimeMessage(createSession());
            msg.setFrom(new InternetAddress(FROM_EMAIL));
            msg.setRecipients(Message.RecipientType.TO, InternetAddress.parse(toEmail));
            msg.setSubject(subject);
            msg.setContent(body, "text/html; charset=utf-8");

            Transport.send(msg);
            System.out.println("[Email] Refund email sent to " + toEmail + " for order #" + orderId);

        } catch (Exception e) {
            System.err.println("[Email] Refund email failed: " + e.getMessage());
        }
    }

    // ── 3. ADMIN CANCEL NOTIFICATION (NEW) ───────────────────────────────────
    // Sent to admin/staff when a customer cancels an order
    public static void sendAdminCancelNotification(int groupId, String cancelledBy,
                                                    String paymentMethod) {
        try {
            String subject = "🚫 Order #" + groupId + " Cancelled by Customer — SIBS";
            String body = "<div style='font-family:Inter,sans-serif;max-width:500px;margin:auto;'>"
                + "<div style='background:#ef4444;padding:30px;text-align:center;border-radius:12px 12px 0 0;'>"
                + "<h1 style='color:#fff;font-size:28px;margin:0;'>🚫 Order Cancelled</h1>"
                + "</div>"
                + "<div style='background:#fff;padding:30px;border:1px solid #e2e8f0;border-radius:0 0 12px 12px;'>"
                + "<h2 style='color:#0f172a;'>Admin Alert</h2>"
                + "<p style='color:#64748b;font-size:15px;'>A customer has cancelled their order. Please stop processing this order immediately.</p>"
                + "<div style='background:#fef2f2;border:1px solid #fecaca;border-radius:8px;padding:16px;margin:20px 0;'>"
                + "<p style='margin:0;color:#0f172a;'><b>Group Order ID:</b> #" + groupId + "</p>"
                + "<p style='margin:8px 0 0;color:#0f172a;'><b>Cancelled By:</b> " + cancelledBy + "</p>"
                + "<p style='margin:8px 0 0;color:#0f172a;'><b>Payment Method:</b> " + paymentMethod + "</p>"
                + "<p style='margin:8px 0 0;color:#ef4444;'><b>Action Required:</b> "
                + ("COD".equalsIgnoreCase(paymentMethod) ? "No refund needed (COD order)" : "Refund has been triggered via Razorpay")
                + "</p>"
                + "</div>"
                + "<p style='color:#64748b;font-size:14px;'>Stock has been automatically restored. Please check the admin dashboard for details.</p>"
                + "<p style='color:#94a3b8;font-size:12px;text-align:center;margin-top:20px;'>SIBS — Smart Inventory &amp; Billing System</p>"
                + "</div></div>";

            Message msg = new MimeMessage(createSession());
            msg.setFrom(new InternetAddress(FROM_EMAIL));
            msg.setRecipients(Message.RecipientType.TO, InternetAddress.parse(ADMIN_EMAIL));
            msg.setSubject(subject);
            msg.setContent(body, "text/html; charset=utf-8");

            Transport.send(msg);
            System.out.println("[Email] Admin cancel notification sent for group #" + groupId);

        } catch (Exception e) {
            System.err.println("[Email] Admin notification failed: " + e.getMessage());
        }
    }

    // ── 4. OTP EMAIL (existing) ───────────────────────────────────────────────
    public static void sendOtpEmail(String toEmail, String customerName,
                                     int orderId, String otp) {
        try {
            String subject = "Delivery OTP for Order #" + orderId + " - SIBS";
            String body = "<div style='font-family:Inter,sans-serif;max-width:500px;margin:auto;'>"
                + "<div style='background:#2563eb;padding:30px;text-align:center;border-radius:12px 12px 0 0;'>"
                + "<h1 style='color:#fff;font-size:28px;margin:0;'>SIBS - Delivery OTP</h1>"
                + "</div>"
                + "<div style='background:#fff;padding:30px;border:1px solid #e2e8f0;border-radius:0 0 12px 12px;'>"
                + "<h2 style='color:#0f172a;'>Hello, " + customerName + "!</h2>"
                + "<p style='color:#64748b;font-size:15px;'>Your delivery boy has picked up your order."
                + " Please share the OTP below to confirm delivery.</p>"
                + "<div style='background:#f0f9ff;border:2px dashed #2563eb;border-radius:12px;"
                + "padding:24px;text-align:center;margin:20px 0;'>"
                + "<p style='margin:0;color:#64748b;font-size:13px;'>Your One-Time Password</p>"
                + "<h1 style='margin:8px 0 0;color:#2563eb;font-size:48px;letter-spacing:12px;'>"
                + otp + "</h1>"
                + "</div>"
                + "<p style='color:#ef4444;font-size:13px;'>Do NOT share this OTP with anyone except the delivery person.</p>"
                + "<p style='color:#94a3b8;font-size:12px;'>Order #" + orderId + " | SIBS</p>"
                + "</div></div>";

            Message msg = new MimeMessage(createSession());
            msg.setFrom(new InternetAddress(FROM_EMAIL));
            msg.setRecipients(Message.RecipientType.TO, InternetAddress.parse(toEmail));
            msg.setSubject(subject);
            msg.setContent(body, "text/html; charset=utf-8");

            Transport.send(msg);
            System.out.println("[Email] OTP sent to " + toEmail + " for order #" + orderId);
        } catch (Exception e) {
            System.err.println("[Email] OTP send failed: " + e.getMessage());
        }
    }

    // ── 5. DELIVERY BOY APPLICATION RECEIVED (admin alert) ───────────────────
    public static void sendDeliveryBoyApplicationEmail(int deliveryBoyId) {
        try {
            String subject = "🛵 New Delivery Boy Application #" + deliveryBoyId + " — SIBS";
            String body = "<div style='font-family:Inter,sans-serif;max-width:500px;margin:auto;'>"
                + "<div style='background:#f97316;padding:30px;text-align:center;border-radius:12px 12px 0 0;'>"
                + "<h1 style='color:#fff;font-size:24px;margin:0;'>🛵 New Delivery Application</h1>"
                + "</div>"
                + "<div style='background:#fff;padding:30px;border:1px solid #e2e8f0;border-radius:0 0 12px 12px;'>"
                + "<p style='color:#0f172a;font-size:15px;'>A new delivery boy has submitted their documents for review.</p>"
                + "<div style='background:#fff7ed;border:1px solid #fed7aa;border-radius:8px;padding:16px;margin:16px 0;'>"
                + "<p style='margin:0;color:#0f172a;'><b>Application ID:</b> #" + deliveryBoyId + "</p>"
                + "<p style='margin:8px 0 0;color:#0f172a;'>Please review and approve/reject from the admin panel.</p>"
                + "</div>"
                + "<p style='color:#94a3b8;font-size:12px;text-align:center;margin-top:20px;'>SIBS — Smart Inventory &amp; Billing System</p>"
                + "</div></div>";

            Message msg = new MimeMessage(createSession());
            msg.setFrom(new InternetAddress(FROM_EMAIL));
            msg.setRecipients(Message.RecipientType.TO, InternetAddress.parse(ADMIN_EMAIL));
            msg.setSubject(subject);
            msg.setContent(body, "text/html; charset=utf-8");
            Transport.send(msg);
        } catch (Exception e) {
            System.err.println("[Email] Delivery application alert failed: " + e.getMessage());
        }
    }

    // ── 6. DELIVERY BOY APPROVED ─────────────────────────────────────────────
    public static void sendDeliveryBoyApprovedEmail(String toEmail, String name) {
        try {
            String subject = "🎉 Congratulations! Your SIBS Delivery Account is Approved";
            String body = "<div style='font-family:Inter,sans-serif;max-width:500px;margin:auto;'>"
                + "<div style='background:#16a34a;padding:30px;text-align:center;border-radius:12px 12px 0 0;'>"
                + "<h1 style='color:#fff;font-size:26px;margin:0;'>🎉 Account Approved!</h1>"
                + "</div>"
                + "<div style='background:#fff;padding:30px;border:1px solid #e2e8f0;border-radius:0 0 12px 12px;'>"
                + "<h2 style='color:#0f172a;'>Welcome, " + name + "!</h2>"
                + "<p style='color:#64748b;font-size:15px;'>Your delivery partner application has been <strong style='color:#16a34a;'>approved</strong>. "
                + "Your account is now active and ready to use.</p>"
                + "<div style='background:#f0fdf4;border:1px solid #bbf7d0;border-radius:8px;padding:16px;margin:20px 0;'>"
                + "<p style='margin:0;color:#0f172a;font-weight:600;'>Next Steps:</p>"
                + "<p style='margin:8px 0 0;color:#0f172a;'>1. Open the Delivery Partner App</p>"
                + "<p style='margin:4px 0 0;color:#0f172a;'>2. Login with your registered email &amp; password</p>"
                + "<p style='margin:4px 0 0;color:#0f172a;'>3. Go Online and start accepting orders!</p>"
                + "</div>"
                + "<p style='color:#64748b;font-size:14px;'>If you have any questions, contact our support team.</p>"
                + "<p style='color:#94a3b8;font-size:12px;text-align:center;margin-top:20px;'>SIBS — Smart Inventory &amp; Billing System</p>"
                + "</div></div>";

            Message msg = new MimeMessage(createSession());
            msg.setFrom(new InternetAddress(FROM_EMAIL));
            msg.setRecipients(Message.RecipientType.TO, InternetAddress.parse(toEmail));
            msg.setSubject(subject);
            msg.setContent(body, "text/html; charset=utf-8");
            Transport.send(msg);
            System.out.println("[Email] Approval email sent to " + toEmail);
        } catch (Exception e) {
            System.err.println("[Email] Approval email failed: " + e.getMessage());
        }
    }

    // ── 7. DELIVERY BOY REJECTED ─────────────────────────────────────────────
    public static void sendDeliveryBoyRejectedEmail(String toEmail, String name) {
        try {
            String subject = "❌ SIBS Delivery Application Update";
            String body = "<div style='font-family:Inter,sans-serif;max-width:500px;margin:auto;'>"
                + "<div style='background:#ef4444;padding:30px;text-align:center;border-radius:12px 12px 0 0;'>"
                + "<h1 style='color:#fff;font-size:26px;margin:0;'>Application Status Update</h1>"
                + "</div>"
                + "<div style='background:#fff;padding:30px;border:1px solid #e2e8f0;border-radius:0 0 12px 12px;'>"
                + "<h2 style='color:#0f172a;'>Hello, " + name + "</h2>"
                + "<p style='color:#64748b;font-size:15px;'>We have reviewed your delivery partner application. "
                + "Unfortunately, we were unable to approve your application at this time.</p>"
                + "<div style='background:#fef2f2;border:1px solid #fecaca;border-radius:8px;padding:16px;margin:20px 0;'>"
                + "<p style='margin:0;color:#dc2626;font-weight:600;'>Possible reasons:</p>"
                + "<p style='margin:8px 0 0;color:#0f172a;'>• Documents were unclear or incomplete</p>"
                + "<p style='margin:4px 0 0;color:#0f172a;'>• Verification could not be completed</p>"
                + "<p style='margin:4px 0 0;color:#0f172a;'>• Background check did not meet requirements</p>"
                + "</div>"
                + "<p style='color:#64748b;font-size:14px;'>You may re-apply after 30 days with updated documents. "
                + "Contact support for more information.</p>"
                + "<p style='color:#94a3b8;font-size:12px;text-align:center;margin-top:20px;'>SIBS — Smart Inventory &amp; Billing System</p>"
                + "</div></div>";

            Message msg = new MimeMessage(createSession());
            msg.setFrom(new InternetAddress(FROM_EMAIL));
            msg.setRecipients(Message.RecipientType.TO, InternetAddress.parse(toEmail));
            msg.setSubject(subject);
            msg.setContent(body, "text/html; charset=utf-8");
            Transport.send(msg);
            System.out.println("[Email] Rejection email sent to " + toEmail);
        } catch (Exception e) {
            System.err.println("[Email] Rejection email failed: " + e.getMessage());
        }
    }

    // ── HELPERS ───────────────────────────────────────────────────────────────
    private static String getSubject(String status, int orderId) {
        switch (status.toLowerCase()) {
            case "approved":         return "✅ Order #" + orderId + " Approved — SIBS";
            case "packed":           return "📦 Order #" + orderId + " Packed — SIBS";
            case "assigned":         return "🛵 Order #" + orderId + " Delivery Boy Assigned — SIBS";
            case "out for delivery": return "🚚 Order #" + orderId + " Out for Delivery — SIBS";
            case "delivered":        return "🎉 Order #" + orderId + " Delivered — SIBS";
            case "rejected":         return "❌ Order #" + orderId + " Rejected — SIBS";
            case "cancelled":        return "🚫 Order #" + orderId + " Cancelled — SIBS";
            case "returned":         return "↩️ Return Approved for Order #" + orderId + " — SIBS";
            case "return rejected":  return "❌ Return Rejected for Order #" + orderId + " — SIBS";
            case "refunded":         return "💰 Refund Processed for Order #" + orderId + " — SIBS";
            default:                 return "Order #" + orderId + " Update — SIBS";
        }
    }

    private static String getBody(String customerName, String status,
                                   int orderId, String productName) {
        String color   = "#2563eb";
        String icon    = "📦";
        String message = "";

        switch (status.toLowerCase()) {
            case "approved":
                color = "#16a34a"; icon = "✅";
                message = "Great news! Your order has been approved and will be packed soon.";
                break;
            case "packed":
                color = "#8b5cf6"; icon = "📦";
                message = "Your order has been packed and is ready for dispatch.";
                break;
            case "assigned":
                color = "#f59e0b"; icon = "🛵";
                message = "A delivery boy has been assigned to your order and will pick it up shortly.";
                break;
            case "out for delivery":
                color = "#2563eb"; icon = "🚚";
                message = "Your order is on the way! Our delivery boy will reach you soon.";
                break;
            case "delivered":
                color = "#16a34a"; icon = "🎉";
                message = "Your order has been delivered. Thank you for shopping with us!";
                break;
            case "rejected":
                color = "#ef4444"; icon = "❌";
                message = "Sorry, your order has been rejected. Please contact support.";
                break;
            case "cancelled":
                color = "#6b7280"; icon = "🚫";
                message = "Your order has been cancelled. If you paid online, a refund will be processed shortly.";
                break;
            case "returned":
                color = "#16a34a"; icon = "↩️";
                message = "Your return request has been approved. Your refund will be processed shortly.";
                break;
            case "return rejected":
                color = "#ef4444"; icon = "❌";
                message = "Unfortunately, your return request has been rejected. Please contact support for more details.";
                break;
            case "refunded":
                color = "#16a34a"; icon = "💰";
                message = "Your refund has been successfully processed. The amount will reflect in your original payment method within 5–7 business days.";
                break;
        }

        return "<div style='font-family:Inter,sans-serif;max-width:500px;margin:auto;'>"
             + "<div style='background:" + color + ";padding:30px;text-align:center;border-radius:12px 12px 0 0;'>"
             + "<h1 style='color:#fff;font-size:28px;margin:0;'>" + icon + " SIBS</h1>"
             + "</div>"
             + "<div style='background:#fff;padding:30px;border:1px solid #e2e8f0;border-radius:0 0 12px 12px;'>"
             + "<h2 style='color:#0f172a;'>Hello, " + customerName + "!</h2>"
             + "<p style='color:#64748b;font-size:15px;'>" + message + "</p>"
             + "<div style='background:#f8fafc;border:1px solid #e2e8f0;border-radius:8px;padding:16px;margin:20px 0;'>"
             + "<p style='margin:0;color:#0f172a;'><b>Order ID:</b> #" + orderId + "</p>"
             + "<p style='margin:8px 0 0;color:#0f172a;'><b>Product:</b> " + productName + "</p>"
             + "<p style='margin:8px 0 0;color:#0f172a;'><b>Status:</b> "
             + "<span style='color:" + color + ";font-weight:700;'>" + status.toUpperCase() + "</span></p>"
             + "</div>"
             + "<p style='color:#94a3b8;font-size:12px;text-align:center;margin-top:20px;'>"
             + "SIBS — Smart Inventory &amp; Billing System</p>"
             + "</div></div>";
    }
 // ── 8. STAFF WELCOME EMAIL ────────────────────────────────────────────────
    // Called when admin registers a new staff member.
    // Sends the plain-text password (before hashing) to the staff's email.
    public static void sendStaffWelcomeEmail(String toEmail, String username, String plainPassword) {
        try {
            String subject = "🎉 Welcome to SIBS — Your Staff Account is Ready";
            String body = "<div style='font-family:Inter,sans-serif;max-width:500px;margin:auto;'>"
                + "<div style='background:#2563eb;padding:30px;text-align:center;border-radius:12px 12px 0 0;'>"
                + "<h1 style='color:#fff;font-size:26px;margin:0;'>👋 Welcome to SIBS!</h1>"
                + "</div>"
                + "<div style='background:#fff;padding:30px;border:1px solid #e2e8f0;border-radius:0 0 12px 12px;'>"
                + "<h2 style='color:#0f172a;'>Hello, " + username + "!</h2>"
                + "<p style='color:#64748b;font-size:15px;'>Your staff account has been created by the admin. "
                + "Here are your login credentials:</p>"
                + "<div style='background:#f0f9ff;border:1px solid #bae6fd;border-radius:8px;padding:20px;margin:20px 0;'>"
                + "<p style='margin:0;color:#0f172a;font-size:15px;'><b>Username:</b> " + username + "</p>"
                + (plainPassword != null && !plainPassword.isBlank()
                    ? "<p style='margin:10px 0 0;color:#0f172a;font-size:15px;'><b>Password:</b> " + plainPassword + "</p>"
                    : "<p style='margin:10px 0 0;color:#0f172a;font-size:15px;'>Use the password your administrator shared with you when creating this account.</p>")
                + "</div>"
                + "<p style='color:#ef4444;font-size:13px;'>⚠️ Please keep your credentials safe and do not share them with anyone.</p>"
                + "<p style='color:#64748b;font-size:14px;'>Log in at your admin-provided SIBS link and change your password after first login.</p>"
                + "<p style='color:#94a3b8;font-size:12px;text-align:center;margin-top:24px;'>SIBS — Smart Inventory &amp; Billing System</p>"
                + "</div></div>";

            Message msg = new MimeMessage(createSession());
            msg.setFrom(new InternetAddress(FROM_EMAIL));
            msg.setRecipients(Message.RecipientType.TO, InternetAddress.parse(toEmail));
            msg.setSubject(subject);
            msg.setContent(body, "text/html; charset=utf-8");
            Transport.send(msg);
            System.out.println("[Email] Staff welcome email sent to " + toEmail);
        } catch (Exception e) {
            System.err.println("[Email] Staff welcome email failed: " + e.getMessage());
        }
    }

    // ── 9. LATE ATTENDANCE EMAIL ──────────────────────────────────────────────
    public static void sendLateAttendanceEmail(String toEmail, String name, String time) {
        try {
            String subject = "⚠️ Late Attendance Marked — SIBS";
            String body = "<div style='font-family:Inter,sans-serif;max-width:500px;margin:auto;'>"
                + "<div style='background:#f97316;padding:30px;text-align:center;border-radius:12px 12px 0 0;'>"
                + "<h1 style='color:#fff;font-size:26px;margin:0;'>⚠️ Late Check-In</h1>"
                + "</div>"
                + "<div style='background:#fff;padding:30px;border:1px solid #e2e8f0;border-radius:0 0 12px 12px;'>"
                + "<h2 style='color:#0f172a;'>Hello, " + name + "!</h2>"
                + "<p style='color:#64748b;font-size:15px;'>Your attendance has been marked as <strong style='color:#ef4444;'>LATE</strong> for today.</p>"
                + "<div style='background:#fff7ed;border:1px solid #fed7aa;border-radius:8px;padding:16px;margin:20px 0;'>"
                + "<p style='margin:0;color:#0f172a;'><b>Check-In Time:</b> " + time + "</p>"
                + "<p style='margin:8px 0 0;color:#0f172a;'><b>Expected Time:</b> 10:00 AM</p>"
                + "<p style='margin:8px 0 0;color:#ef4444;'><b>Status:</b> LATE</p>"
                + "</div>"
                + "<p style='color:#64748b;font-size:14px;'>Please ensure punctuality. Repeated late arrivals may affect your performance review.</p>"
                + "<p style='color:#94a3b8;font-size:12px;text-align:center;margin-top:20px;'>SIBS — Smart Inventory &amp; Billing System</p>"
                + "</div></div>";

            Message msg = new MimeMessage(createSession());
            msg.setFrom(new InternetAddress(FROM_EMAIL));
            msg.setRecipients(Message.RecipientType.TO, InternetAddress.parse(toEmail));
            msg.setSubject(subject);
            msg.setContent(body, "text/html; charset=utf-8");
            Transport.send(msg);
            System.out.println("[Email] Late attendance email sent to " + toEmail);
        } catch (Exception e) {
            System.err.println("[Email] Late attendance email failed: " + e.getMessage());
        }
    }

    // ── 10. LEAVE DECISION EMAIL ──────────────────────────────────────────────
    public static void sendLeaveDecisionEmail(String toEmail, String name, String decision, String remarks) {
        boolean approved = "Approved".equalsIgnoreCase(decision);
        try {
            String subject = (approved ? "✅" : "❌") + " Leave Request " + decision + " — SIBS";
            String color = approved ? "#16a34a" : "#ef4444";
            String body = "<div style='font-family:Inter,sans-serif;max-width:500px;margin:auto;'>"
                + "<div style='background:" + color + ";padding:30px;text-align:center;border-radius:12px 12px 0 0;'>"
                + "<h1 style='color:#fff;font-size:26px;margin:0;'>Leave Request " + decision + "</h1>"
                + "</div>"
                + "<div style='background:#fff;padding:30px;border:1px solid #e2e8f0;border-radius:0 0 12px 12px;'>"
                + "<h2 style='color:#0f172a;'>Hello, " + name + "!</h2>"
                + "<p style='color:#64748b;font-size:15px;'>Your leave request has been <strong style='color:" + color + ";'>" + decision.toUpperCase() + "</strong>.</p>"
                + (remarks != null && !remarks.isEmpty()
                    ? "<div style='background:#f8fafc;border:1px solid #e2e8f0;border-radius:8px;padding:16px;margin:16px 0;'>"
                    + "<p style='margin:0;color:#0f172a;'><b>Remarks:</b> " + remarks + "</p></div>" : "")
                + "<p style='color:#94a3b8;font-size:12px;text-align:center;margin-top:20px;'>SIBS — Smart Inventory &amp; Billing System</p>"
                + "</div></div>";

            Message msg = new MimeMessage(createSession());
            msg.setFrom(new InternetAddress(FROM_EMAIL));
            msg.setRecipients(Message.RecipientType.TO, InternetAddress.parse(toEmail));
            msg.setSubject(subject);
            msg.setContent(body, "text/html; charset=utf-8");
            Transport.send(msg);
            System.out.println("[Email] Leave decision email sent to " + toEmail);
        } catch (Exception e) {
            System.err.println("[Email] Leave decision email failed: " + e.getMessage());
        }
    }

    // ── 11. COD ALERT EMAIL (admin) ───────────────────────────────────────────
    public static void sendCodAlertEmail(String deliveryBoyName, double amount, boolean forceOffline) {
        try {
            String subject = forceOffline
                ? "🚨 COD Alert: Delivery Boy Forced Offline — SIBS"
                : "💰 COD Remittance Received — SIBS";
            String color = forceOffline ? "#ef4444" : "#16a34a";
            String body = "<div style='font-family:Inter,sans-serif;max-width:500px;margin:auto;'>"
                + "<div style='background:" + color + ";padding:30px;text-align:center;border-radius:12px 12px 0 0;'>"
                + "<h1 style='color:#fff;font-size:24px;margin:0;'>" + (forceOffline ? "🚨 COD Alert" : "💰 COD Remittance") + "</h1>"
                + "</div>"
                + "<div style='background:#fff;padding:30px;border:1px solid #e2e8f0;border-radius:0 0 12px 12px;'>"
                + "<p style='color:#0f172a;font-size:15px;'>"
                + (forceOffline
                    ? "<strong>" + deliveryBoyName + "</strong> was forced offline due to insufficient balance to cover <strong>₹" + (int) amount + "</strong> pending COD."
                    : "<strong>" + deliveryBoyName + "</strong> remitted <strong>₹" + (int) amount + "</strong> COD cash. Please verify in the ledger.")
                + "</p>"
                + "<p style='color:#94a3b8;font-size:12px;text-align:center;margin-top:20px;'>SIBS — Smart Inventory &amp; Billing System</p>"
                + "</div></div>";

            Message msg = new MimeMessage(createSession());
            msg.setFrom(new InternetAddress(FROM_EMAIL));
            msg.setRecipients(Message.RecipientType.TO, InternetAddress.parse(ADMIN_EMAIL));
            msg.setSubject(subject);
            msg.setContent(body, "text/html; charset=utf-8");
            Transport.send(msg);
            System.out.println("[Email] COD alert email sent to admin");
        } catch (Exception e) {
            System.err.println("[Email] COD alert email failed: " + e.getMessage());
        }
    }

    // ── 13. ORDER CONFIRMATION EMAIL WITH NEXT COUPON ─────────────────────────
    // Sent to customer after order is placed (COD) or payment verified (Online).
    // Includes a "next order" coupon if available.
    public static void sendOrderConfirmationWithCoupon(
            String toEmail, String customerName,
            int orderId, double grandTotal,
            String paymentMethod,
            String nextCouponCode, String nextCouponDesc) {
        try {
            String subject = "🎉 Order #" + orderId + " Confirmed — SIBS";

            String couponSection = "";
            if (nextCouponCode != null && !nextCouponCode.trim().isEmpty()) {
                couponSection = "<div style='background:#fffbeb;border:2px dashed #f59e0b;"
                    + "border-radius:12px;padding:20px;margin:20px 0;text-align:center;'>"
                    + "<p style='margin:0;color:#92400e;font-size:13px;font-weight:600;'>🎟️ YOUR EXCLUSIVE OFFER</p>"
                    + "<h2 style='margin:10px 0;color:#b45309;font-size:28px;"
                    + "letter-spacing:4px;font-weight:800;'>" + nextCouponCode + "</h2>"
                    + "<p style='margin:0;color:#92400e;font-size:13px;'>" + nextCouponDesc + "</p>"
                    + "<p style='margin:8px 0 0;color:#b45309;font-size:12px;'>Use this code at checkout on your next order!</p>"
                    + "</div>";
            }

            String body = "<div style='font-family:Inter,sans-serif;max-width:520px;margin:auto;'>"
                + "<div style='background:#4361ee;padding:30px;text-align:center;border-radius:12px 12px 0 0;'>"
                + "<h1 style='color:#fff;font-size:26px;margin:0;'>🎉 Order Confirmed!</h1>"
                + "</div>"
                + "<div style='background:#fff;padding:30px;border:1px solid #e2e8f0;border-radius:0 0 12px 12px;'>"
                + "<h2 style='color:#0f172a;margin-top:0;'>Hello, " + customerName + "!</h2>"
                + "<p style='color:#64748b;font-size:15px;'>Thank you for your order. We've received it and will start processing it shortly.</p>"
                + "<div style='background:#f0f9ff;border:1px solid #bae6fd;border-radius:8px;padding:16px;margin:20px 0;'>"
                + "<p style='margin:0;color:#0f172a;'><b>Order ID:</b> #" + orderId + "</p>"
                + "<p style='margin:8px 0 0;color:#0f172a;'><b>Amount Paid:</b> ₹" + String.format("%.0f", grandTotal) + "</p>"
                + "<p style='margin:8px 0 0;color:#0f172a;'><b>Payment:</b> " + paymentMethod + "</p>"
                + "</div>"
                + couponSection
                + "<p style='color:#64748b;font-size:14px;'>You'll receive updates as your order is packed and dispatched.</p>"
                + "<p style='color:#94a3b8;font-size:12px;text-align:center;margin-top:24px;'>SIBS — Smart Inventory &amp; Billing System</p>"
                + "</div></div>";

            Message msg = new MimeMessage(createSession());
            msg.setFrom(new InternetAddress(FROM_EMAIL));
            msg.setRecipients(Message.RecipientType.TO, InternetAddress.parse(toEmail));
            msg.setSubject(subject);
            msg.setContent(body, "text/html; charset=utf-8");
            Transport.send(msg);
            System.out.println("[Email] Order confirmation sent to " + toEmail + " for order #" + orderId);
        } catch (Exception e) {
            System.err.println("[Email] Order confirmation failed: " + e.getMessage());
        }
    }

    // ── 12. RETURN STATUS EMAIL (customer) ────────────────────────────────────
    public static void sendReturnStatusEmail(String toEmail, String customerName,
                                              String productName, String status) {
        boolean approved = "Approved".equalsIgnoreCase(status) || "Refunded".equalsIgnoreCase(status);
        try {
            String subject = (approved ? "✅" : "❌") + " Return " + status + " — SIBS";
            String color = approved ? "#16a34a" : "#ef4444";
            String body = "<div style='font-family:Inter,sans-serif;max-width:500px;margin:auto;'>"
                + "<div style='background:" + color + ";padding:30px;text-align:center;border-radius:12px 12px 0 0;'>"
                + "<h1 style='color:#fff;font-size:26px;margin:0;'>Return " + status + "</h1>"
                + "</div>"
                + "<div style='background:#fff;padding:30px;border:1px solid #e2e8f0;border-radius:0 0 12px 12px;'>"
                + "<h2 style='color:#0f172a;'>Hello, " + customerName + "!</h2>"
                + "<p style='color:#64748b;font-size:15px;'>Your return request has been <strong style='color:" + color + ";'>" + status.toUpperCase() + "</strong>.</p>"
                + "<div style='background:#f8fafc;border:1px solid #e2e8f0;border-radius:8px;padding:16px;margin:16px 0;'>"
                + "<p style='margin:0;color:#0f172a;'><b>Product:</b> " + productName + "</p>"
                + "<p style='margin:8px 0 0;color:#0f172a;'><b>Status:</b> <span style='color:" + color + ";font-weight:700;'>" + status.toUpperCase() + "</span></p>"
                + ("Refunded".equalsIgnoreCase(status) ? "<p style='margin:8px 0 0;color:#0f172a;'>Refund will be credited within 5–7 business days.</p>" : "")
                + "</div>"
                + "<p style='color:#94a3b8;font-size:12px;text-align:center;margin-top:20px;'>SIBS — Smart Inventory &amp; Billing System</p>"
                + "</div></div>";

            Message msg = new MimeMessage(createSession());
            msg.setFrom(new InternetAddress(FROM_EMAIL));
            msg.setRecipients(Message.RecipientType.TO, InternetAddress.parse(toEmail));
            msg.setSubject(subject);
            msg.setContent(body, "text/html; charset=utf-8");
            Transport.send(msg);
            System.out.println("[Email] Return status email sent to " + toEmail);
        } catch (Exception e) {
            System.err.println("[Email] Return status email failed: " + e.getMessage());
        }
    }
}