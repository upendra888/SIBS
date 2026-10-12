package com.sibs.servlet;

import com.sibs.dao.DeliveryBoyDAO;
import com.sibs.dao.OrderDAO;
import com.sibs.dao.PaymentDAO;
import com.sibs.dao.NotificationDAO;
import com.sibs.dao.SupportComplaintDAO;
import com.sibs.dao.WrongItemReturnService;
import com.sibs.dao.DeliverySlotDAO;
import com.sibs.model.DeliveryBoy;
import com.sibs.model.Order;
import com.sibs.model.Payment;
import com.sibs.model.SupportComplaint;
import com.sibs.model.User;
import com.sibs.util.DBConnection;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.util.Base64;
import java.util.List;

/**
 * SupportServlet  –  /support
 *
 * GET  (no action / action=list)  → ticket list
 * GET  action=view&id=X           → single ticket  (auto OPEN→UNDER_REVIEW)
 *
 * POST action=review              → save investigation notes
 * POST action=verdict             → FRAUD  → CLOSED
 *                                   GENUINE + resolution=REDELIVER → RESOLVED + reassign delivery
 *                                   GENUINE + resolution=REFUND    → RESOLVED + Razorpay / COD note
 *                                   GENUINE + resolution=MANUAL    → RESOLVED + manual note only
 *                                   GENUINE + resolution=PICKUP_RETURN → RESOLVED + return create + redirect schedule-pickup
 */
@WebServlet("/support")
public class SupportServlet extends HttpServlet {

    private final SupportComplaintDAO dao          = new SupportComplaintDAO();
    private final WrongItemReturnService wrongItemSvc = new WrongItemReturnService();
    private final DeliverySlotDAO        slotDao      = new DeliverySlotDAO();
    private final DeliveryBoyDAO      dboyDao  = new DeliveryBoyDAO();
    private final OrderDAO            orderDao = new OrderDAO();
    private final PaymentDAO          payDao   = new PaymentDAO();

    // ── GET ───────────────────────────────────────────────────────────────────
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        if (!isStaff(req, res)) return;

        String action = req.getParameter("action");
        if (action == null) action = "list";

        switch (action) {

            case "list": {
                boolean showAll = "true".equals(req.getParameter("all"));
                try {
                    List<SupportComplaint> tickets = showAll ? dao.getAll() : dao.getAllOpen();
                    req.setAttribute("tickets", tickets);
                    req.setAttribute("showAll", showAll);
                } catch (Exception e) {
                    log("SupportServlet list error", e);
                    req.setAttribute("error", "Could not load tickets.");
                }
                req.getRequestDispatcher("/staff-support.jsp").forward(req, res);
                break;
            }

            case "view": {
                int id = parseId(req.getParameter("id"));
                if (id <= 0) { res.sendRedirect(req.getContextPath() + "/support"); return; }

                try {
                    SupportComplaint c = dao.getByIdWithDetails(id);
                    if (c == null) { res.sendRedirect(req.getContextPath() + "/support"); return; }

                    if ("OPEN".equals(c.getStatus())) {
                        dao.updateStatus(id, "UNDER_REVIEW", c.getStaffNotes());
                        c.setStatus("UNDER_REVIEW");
                    }
                    req.setAttribute("complaint", c);

                    // Supply delivery boy list for the re-deliver dropdown
                    req.setAttribute("deliveryBoys", dboyDao.getAllDeliveryBoys());

                    // If the complaint has a linked order, fetch its details for the refund panel
                    if (c.getOrderId() != null) {
                        List<Order> grpOrders = orderDao.getOrdersByGroupId(c.getOrderId());
                        Order order = grpOrders.isEmpty() ? null : grpOrders.get(0);
                        if (order != null) {
                            req.setAttribute("linkedOrder", order);
                            Payment payment = payDao.getPaymentByGroupId(c.getOrderId());
                            if (payment != null) req.setAttribute("linkedPayment", payment);
                        }
                    }

                } catch (Exception e) {
                    log("SupportServlet view error", e);
                    req.setAttribute("error", "Could not load ticket.");
                }
                req.getRequestDispatcher("/staff-support.jsp").forward(req, res);
                break;
            }

            case "slots": {
                String date = req.getParameter("date");
                java.util.List<java.util.Map<String, Object>> slots = wrongItemSvc.getAvailableSlots(date);
                res.setContentType("application/json");
                res.setCharacterEncoding("UTF-8");
                StringBuilder json = new StringBuilder("[");
                for (int i = 0; i < slots.size(); i++) {
                    java.util.Map<String,Object> s = slots.get(i);
                    if (i > 0) json.append(",");
                    json.append("{")
                        .append("\"slot_id\":").append(s.get("slot_id")).append(",")
                        .append("\"slot_name\":\"").append(s.get("slot_name")).append("\",")
                        .append("\"start_time\":\"").append(s.get("start_time")).append("\",")
                        .append("\"end_time\":\"").append(s.get("end_time")).append("\",")
                        .append("\"remaining\":").append(s.get("remaining"))
                        .append("}");
                }
                json.append("]");
                res.getWriter().write(json.toString());
                return;
            }

            default:
                res.sendRedirect(req.getContextPath() + "/support");
        }
    }

    // ── POST ──────────────────────────────────────────────────────────────────
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        if (!isStaff(req, res)) return;

        String action = req.getParameter("action");
        int    id     = parseId(req.getParameter("id"));

        if (id <= 0 || action == null) {
            res.sendRedirect(req.getContextPath() + "/support");
            return;
        }

        try {
            switch (action) {

                // ── Save investigation notes ──────────────────────────────────
                case "review": {
                    String notes = req.getParameter("staffNotes");
                    dao.updateStatus(id, "UNDER_REVIEW", notes);
                    setMsg(req, "✅ Notes saved. Ticket remains Under Review.");
                    res.sendRedirect(req.getContextPath() + "/support?action=view&id=" + id);
                    break;
                }

                // ── Final verdict ─────────────────────────────────────────────
                case "verdict": {
                    String verdict    = req.getParameter("verdict");    // GENUINE | FRAUD
                    String resolution = req.getParameter("resolution"); // REDELIVER | REFUND | MANUAL
                    String notes      = req.getParameter("staffNotes");

                    if (!"GENUINE".equals(verdict) && !"FRAUD".equals(verdict)) {
                        setMsg(req, "❌ Invalid verdict.");
                        res.sendRedirect(req.getContextPath() + "/support?action=view&id=" + id);
                        return;
                    }

                    // ── FRAUD → just close ────────────────────────────────────
                    if ("FRAUD".equals(verdict)) {
                        dao.resolveComplaint(id, "FRAUD", notes);
                        SupportComplaint fraudComp = dao.getByIdWithDetails(id);
                        if (fraudComp != null) NotificationDAO.sendComplaintResolved(fraudComp.getUserId(), id, "FRAUD");
                        setMsg(req, "🚫 Verdict: FRAUD — Complaint rejected and closed. Customer notified.");
                        res.sendRedirect(req.getContextPath() + "/support");
                        return;
                    }

                    // ── GENUINE → resolve + execute resolution action ─────────
                    dao.resolveComplaint(id, "GENUINE", notes);

                    SupportComplaint complaint = dao.getByIdWithDetails(id);
                    if (complaint != null) NotificationDAO.sendComplaintResolved(complaint.getUserId(), id, "GENUINE");
                    String outcome = "✅ Verdict: GENUINE — Ticket marked Resolved.";

                    if ("REDELIVER".equals(resolution) && complaint != null && complaint.getOrderId() != null) {
                        outcome = handleRedeliver(req, complaint, outcome);
                    } else if ("REFUND".equals(resolution) && complaint != null && complaint.getOrderId() != null) {
                        outcome = handleRefund(req, complaint, outcome);
                    } else if ("PICKUP_RETURN".equals(resolution) && complaint != null) {
                        // Wrong item delivered — create return + redirect to pickup scheduling
                        int returnId = wrongItemSvc.createAndApproveReturn(id, notes);
                        if (returnId > 0) {
                            // Staff pickup date/slot choose chese page ki redirect
                            res.sendRedirect(req.getContextPath() + "/schedule-pickup.jsp?returnId=" + returnId + "&complaintId=" + id);
                            return;
                        } else if (returnId == -2) {
                            outcome += " ⚠ Return already exists — please schedule pickup via Returns page.";
                        } else {
                            outcome += " ⚠ Return creation failed — please create manually via Returns.";
                        }
                    } else {
                        outcome += " Please initiate re-delivery or refund manually.";
                    }

                    setMsg(req, outcome);
                    res.sendRedirect(req.getContextPath() + "/support");
                    break;
                }

                // ── Schedule wrong item pickup ───────────────────────────
                case "schedulePickup": {
                    int    returnId      = parseId(req.getParameter("returnId"));
                    int    slotId        = parseId(req.getParameter("slotId"));
                    int    deliveryBoyId = parseId(req.getParameter("deliveryBoyId"));
                    String pickupDate    = req.getParameter("pickupDate");
                    boolean ok = wrongItemSvc.schedulePickup(returnId, slotId, pickupDate, deliveryBoyId);
                    if (ok) {
                        String dbMsg = deliveryBoyId > 0 ? " Delivery boy assigned." : " Please assign a delivery boy manually.";
                        setMsg(req, "✅ Pickup scheduled for " + pickupDate + "!" + dbMsg);
                        res.sendRedirect(req.getContextPath() + "/support");
                    } else {
                        res.sendRedirect(req.getContextPath() + "/schedule-pickup.jsp?returnId=" + returnId + "&error=1");
                    }
                    break;
                }

                // ── Available slots JSON (AJAX from schedule-pickup.jsp) ──────
                case "slots": {
                    String date = req.getParameter("date");
                    java.util.List<java.util.Map<String, Object>> slots = wrongItemSvc.getAvailableSlots(date);
                    res.setContentType("application/json");
                    res.setCharacterEncoding("UTF-8");
                    StringBuilder json = new StringBuilder("[");
                    for (int i = 0; i < slots.size(); i++) {
                        java.util.Map<String,Object> s = slots.get(i);
                        if (i > 0) json.append(",");
                        json.append("{")
                            .append("\"slot_id\":").append(s.get("slot_id")).append(",")
                            .append("\"slot_name\":\"").append(s.get("slot_name")).append("\",")
                            .append("\"start_time\":\"").append(s.get("start_time")).append("\",")
                            .append("\"end_time\":\"").append(s.get("end_time")).append("\",")
                            .append("\"remaining\":").append(s.get("remaining"))
                            .append("}");
                    }
                    json.append("]");
                    res.getWriter().write(json.toString());
                    return;
                }

                default:
                    res.sendRedirect(req.getContextPath() + "/support");
            }

        } catch (Exception e) {
            log("SupportServlet POST error", e);
            setMsg(req, "❌ Error processing request. Please try again.");
            res.sendRedirect(req.getContextPath() + "/support");
        }
    }

    // ── Re-deliver handler ────────────────────────────────────────────────────
    private String handleRedeliver(HttpServletRequest req,
                                   SupportComplaint complaint,
                                   String baseMsg) {
        try {
            int    deliveryBoyId = parseId(req.getParameter("deliveryBoyId"));
            String address       = req.getParameter("redeliverAddress");
            String note          = "Re-delivery initiated for support ticket " + complaint.getTicketId();

            Order order = orderDao.getOrdersByGroupId(complaint.getOrderId()).stream().findFirst().orElse(null);
            if (order == null) return baseMsg + " ⚠ Order not found — please re-deliver manually.";

            int groupId = complaint.getOrderId(); // now stored as group_id directly

            try (Connection con = DBConnection.getConnection()) {
                // Update address on all orders in the group
                if (address != null && !address.isBlank()) {
                    try (PreparedStatement ps = con.prepareStatement(
                            "UPDATE orders SET address=? WHERE group_id=?")) {
                        ps.setString(1, address.trim());
                        ps.setInt(2, groupId);
                        ps.executeUpdate();
                    }
                }
                // Reset status to Assigned
                try (PreparedStatement ps = con.prepareStatement(
                        "UPDATE orders SET status='Assigned' WHERE group_id=?")) {
                    ps.setInt(1, groupId);
                    ps.executeUpdate();
                }
            }

            // Reassign delivery boy — ONE assignment per group (first order id)
            if (deliveryBoyId > 0) {
                List<Order> groupOrders = orderDao.getOrdersByGroupId(groupId);
                if (!groupOrders.isEmpty()) {
                    dboyDao.assignDeliveryBoy(groupOrders.get(0).getId(), deliveryBoyId, note);
                }
                return baseMsg + " 🚚 Re-delivery assigned to delivery boy #" + deliveryBoyId + ".";
            } else {
                return baseMsg + " 🚚 Order reset to Assigned — please assign a delivery boy.";
            }

        } catch (Exception e) {
            log("SupportServlet redeliver error", e);
            return baseMsg + " ⚠ Re-delivery setup failed — please do it manually via Orders.";
        }
    }

    // ── Refund handler ────────────────────────────────────────────────────────
    private String handleRefund(HttpServletRequest req,
                                SupportComplaint complaint,
                                String baseMsg) {
        try {
            Order order = orderDao.getOrdersByGroupId(complaint.getOrderId()).stream().findFirst().orElse(null);
            if (order == null) return baseMsg + " ⚠ Order not found — refund manually.";

            Payment payment = payDao.getPaymentByGroupId(complaint.getOrderId());

            // ── COD: no online payment to reverse ────────────────────────────
            if (payment == null || "COD".equalsIgnoreCase(order.getPaymentMethod())) {
                return baseMsg + " 💵 COD order — please issue a manual cash refund of ₹"
                       + String.format("%.2f", order.getTotal()) + " to customer.";
            }

            // ── Already refunded ──────────────────────────────────────────────
            if ("REFUNDED".equalsIgnoreCase(payment.getStatus())) {
                return baseMsg + " ℹ Payment already refunded (ID: " + payment.getRefundId() + ").";
            }

            // ── Online payment: trigger Razorpay refund ───────────────────────
            String rzpKey    = getServletContext().getInitParameter("razorpay.key.id");
            String rzpSecret = getServletContext().getInitParameter("razorpay.key.secret");
            String rzpPayId  = payment.getRazorpayPaymentId();

            if (rzpKey == null || rzpPayId == null || rzpPayId.isBlank()) {
                return baseMsg + " ⚠ Razorpay not configured — please refund ₹"
                       + String.format("%.2f", order.getTotal()) + " via Razorpay dashboard.";
            }

            long amountPaise = Math.round(order.getTotal() * 100);
            String body = "amount=" + amountPaise + "&notes[reason]=support_complaint_" + complaint.getTicketId();
            String auth  = Base64.getEncoder().encodeToString((rzpKey + ":" + rzpSecret).getBytes());

            URL url = new URL("https://api.razorpay.com/v1/payments/" + rzpPayId + "/refund");
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("POST");
            conn.setRequestProperty("Authorization", "Basic " + auth);
            conn.setRequestProperty("Content-Type", "application/x-www-form-urlencoded");
            conn.setDoOutput(true);

            try (OutputStream os = conn.getOutputStream()) {
                os.write(body.getBytes(StandardCharsets.UTF_8));
            }

            int code = conn.getResponseCode();
            if (code == 200 || code == 201) {
                payDao.markRefunded(payment.getPaymentId(), "refund_support_" + complaint.getTicketId());
                return baseMsg + " 💰 Refund of ₹" + String.format("%.2f", order.getTotal())
                       + " initiated via Razorpay.";
            } else {
                return baseMsg + " ⚠ Razorpay refund failed (HTTP " + code
                       + ") — please refund manually via dashboard.";
            }

        } catch (Exception e) {
            log("SupportServlet refund error", e);
            return baseMsg + " ⚠ Refund processing failed — please refund manually.";
        }
    }

    // ── Helpers ───────────────────────────────────────────────────────────────
    private boolean isStaff(HttpServletRequest req, HttpServletResponse res) throws IOException {
        HttpSession session = req.getSession(false);
        User user = (session != null) ? (User) session.getAttribute("user") : null;
        if (user == null || (!"STAFF".equals(user.getRole()) && !"ADMIN".equals(user.getRole()))) {
            res.sendRedirect(req.getContextPath() + "/login.jsp");
            return false;
        }
        return true;
    }

    private int parseId(String s) {
        try { return Integer.parseInt(s); } catch (Exception e) { return -1; }
    }

    private void setMsg(HttpServletRequest req, String msg) {
        req.getSession().setAttribute("supportMsg", msg);
    }
}