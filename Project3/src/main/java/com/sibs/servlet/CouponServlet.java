package com.sibs.servlet;

import com.sibs.dao.CouponDAO;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.io.PrintWriter;

/**
 * Handles two URL patterns:
 *   GET  /applyCoupon        — Customer: validate coupon & return discount JSON
 *   POST /manageCoupon       — Staff: create / toggle / delete coupons
 */
@WebServlet(urlPatterns = {"/applyCoupon", "/manageCoupon"})
public class CouponServlet extends HttpServlet {

    // ── Customer: validate coupon ─────────────────────────────────────────────
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws IOException {

        res.setContentType("application/json");
        res.setCharacterEncoding("UTF-8");
        PrintWriter out = res.getWriter();

        String code      = req.getParameter("code");
        String subtotalS = req.getParameter("subtotal");

        if (code == null || code.trim().isEmpty()) {
            out.write("{\"valid\":false,\"message\":\"Please enter a coupon code.\"}");
            return;
        }

        double subtotal = 0;
        try { subtotal = Double.parseDouble(subtotalS); } catch (Exception ignored) {}

        CouponDAO dao  = new CouponDAO();
        double[]  result = dao.validateCoupon(code, subtotal);

        if (result == null) {
            out.write("{\"valid\":false,\"message\":\"Invalid, expired, or minimum order not met.\"}");
        } else {
            double discount = result[0];
            String desc     = dao.getDescription(code);
            out.write("{\"valid\":true,\"discount\":" + discount
                    + ",\"description\":\"" + escJson(desc) + "\"}");
        }
    }

    // ── Staff: create / toggle / delete ──────────────────────────────────────
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws IOException {

        // Staff-only guard
        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            res.sendRedirect("login.jsp");
            return;
        }

        String action = req.getParameter("action");
        CouponDAO dao = new CouponDAO();

        if ("create".equals(action)) {
            String code        = req.getParameter("code");
            String description = req.getParameter("description");
            String type        = req.getParameter("discountType");
            double value       = parseD(req.getParameter("discountValue"));
            double minOrder    = parseD(req.getParameter("minOrderAmount"));
            double maxDiscount = parseD(req.getParameter("maxDiscount"));
            String usageLimitS = req.getParameter("usageLimit");
            Integer usageLimit = (usageLimitS != null && !usageLimitS.trim().isEmpty())
                                  ? Integer.parseInt(usageLimitS.trim()) : null;
            String validFrom   = req.getParameter("validFrom");
            String validUntil  = req.getParameter("validUntil");

            boolean ok = dao.createCoupon(code, description, type, value,
                                          minOrder, maxDiscount, usageLimit,
                                          validFrom, validUntil);
            String msg = ok ? "Coupon created successfully!" : "Error: code may already exist.";
            res.sendRedirect("staff-coupons.jsp?msg=" + java.net.URLEncoder.encode(msg, "UTF-8")
                             + (ok ? "&status=ok" : "&status=err"));

        } else if ("toggle".equals(action)) {
            int id = Integer.parseInt(req.getParameter("id"));
            dao.toggleActive(id);
            res.sendRedirect("staff-coupons.jsp?msg=Status+updated&status=ok");

        } else if ("delete".equals(action)) {
            int id = Integer.parseInt(req.getParameter("id"));
            dao.deleteCoupon(id);
            res.sendRedirect("staff-coupons.jsp?msg=Coupon+deleted&status=ok");

        } else {
            res.sendRedirect("staff-coupons.jsp");
        }
    }

    private double parseD(String s) {
        try { return (s != null && !s.trim().isEmpty()) ? Double.parseDouble(s.trim()) : 0; }
        catch (Exception e) { return 0; }
    }

    private String escJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"")
                .replace("\n", "\\n").replace("\r", "\\r");
    }
}