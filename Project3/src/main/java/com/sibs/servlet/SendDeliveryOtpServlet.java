package com.sibs.servlet;

import com.sibs.dao.DeliveryBoyDAO;
import jakarta.mail.*;
import jakarta.mail.internet.*;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.security.SecureRandom;
import java.util.Properties;

@WebServlet("/sendDeliveryOtp")
public class SendDeliveryOtpServlet extends HttpServlet {

    // ── Email credentials come from environment variables (same as EmailService) ──
    //   SIBS_MAIL_FROM=you@gmail.com
    //   SIBS_MAIL_PASSWORD=your_gmail_app_password
    private static final String FROM_EMAIL = System.getenv("SIBS_MAIL_FROM");
    private static final String PASSWORD   = System.getenv("SIBS_MAIL_PASSWORD");

    private static final SecureRandom RANDOM = new SecureRandom();

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        String name            = req.getParameter("name");
        String email           = req.getParameter("email");
        String phone           = req.getParameter("phone");
        String city            = req.getParameter("city");
        String password        = req.getParameter("password");
        String confirmPassword = req.getParameter("confirmPassword");

        // 1. Password match
        if (password == null || !password.equals(confirmPassword)) {
            res.sendRedirect("delivery-register.jsp?error=password");
            return;
        }

        // 2. Duplicate email check
        DeliveryBoyDAO dao = new DeliveryBoyDAO();
        if (dao.isEmailExists(email)) {
            res.sendRedirect("delivery-register.jsp?error=email");
            return;
        }

        // 3. Duplicate phone check
        if (dao.isPhoneExists(phone)) {
            res.sendRedirect("delivery-register.jsp?error=phone");
            return;
        }

        // 4. Generate 6-digit OTP
        String otp = String.format("%06d", RANDOM.nextInt(1_000_000));

        // 5. Store details + OTP in session
        HttpSession session = req.getSession();
        session.setAttribute("reg_name",     name);
        session.setAttribute("reg_email",    email);
        session.setAttribute("reg_phone",    phone);
        session.setAttribute("reg_city",     city);
        session.setAttribute("reg_password", password);
        session.setAttribute("reg_otp",      otp);
        session.setAttribute("reg_otp_time", System.currentTimeMillis()); // for expiry check

        // 6. Send OTP email
        boolean sent = sendOtpEmail(email, name, otp);

        if (!sent) {
            // OTP email failed — still let them proceed (show OTP in console for dev)
            System.out.println("[DEV] OTP for " + email + " = " + otp);
        }
        res.sendRedirect("delivery-register.jsp?msg=otpSent");
    }

    // ── Send OTP email via Gmail SMTP ──────────────────────────
    private boolean sendOtpEmail(String toEmail, String name, String otp) {
        if (FROM_EMAIL == null || FROM_EMAIL.isBlank() || PASSWORD == null || PASSWORD.isBlank()) {
            System.err.println("[OTP] Email not configured: set SIBS_MAIL_FROM and SIBS_MAIL_PASSWORD");
            return false;
        }
        try {
            Properties props = new Properties();
            props.put("mail.smtp.host",           "smtp.gmail.com");
            props.put("mail.smtp.port",           "587");
            props.put("mail.smtp.auth",           "true");
            props.put("mail.smtp.starttls.enable","true");

            Session mailSession = Session.getInstance(props, new Authenticator() {
                protected PasswordAuthentication getPasswordAuthentication() {
                    return new PasswordAuthentication(FROM_EMAIL, PASSWORD);
                }
            });

            String subject = "🔐 Your SIBS Delivery Registration OTP";
            String body =
                "<div style='font-family:Inter,sans-serif;max-width:500px;margin:auto;'>" +
                "<div style='background:#f97316;padding:30px;text-align:center;border-radius:12px 12px 0 0;'>" +
                "<h1 style='color:#fff;font-size:24px;margin:0;'>🛵 SIBS Delivery Partner</h1>" +
                "</div>" +
                "<div style='background:#fff;padding:30px;border:1px solid #e2e8f0;border-radius:0 0 12px 12px;'>" +
                "<h2 style='color:#0f172a;'>Hello, " + name + "!</h2>" +
                "<p style='color:#64748b;font-size:15px;'>Use the OTP below to complete your delivery partner registration.</p>" +
                "<div style='background:#fff7ed;border:2px dashed #f97316;border-radius:12px;padding:20px;text-align:center;margin:24px 0;'>" +
                "<p style='color:#64748b;font-size:13px;margin-bottom:8px;'>Your One-Time Password</p>" +
                "<h1 style='color:#f97316;font-size:42px;letter-spacing:10px;margin:0;'>" + otp + "</h1>" +
                "<p style='color:#94a3b8;font-size:12px;margin-top:8px;'>Valid for 5 minutes only</p>" +
                "</div>" +
                "<p style='color:#94a3b8;font-size:12px;'>If you did not request this, please ignore this email.</p>" +
                "</div></div>";

            Message msg = new MimeMessage(mailSession);
            msg.setFrom(new InternetAddress(FROM_EMAIL));
            msg.setRecipients(Message.RecipientType.TO, InternetAddress.parse(toEmail));
            msg.setSubject(subject);
            msg.setContent(body, "text/html; charset=utf-8");

            Transport.send(msg);
            System.out.println("[OTP] Sent to " + toEmail);
            return true;

        } catch (Exception e) {
            System.err.println("[OTP] Email failed: " + e.getMessage());
            return false;
        }
    }
}
