package com.sibs.servlet;

import com.sibs.dao.NotificationDAO;
import com.sibs.model.User;
import com.sibs.util.DBConnection;
import com.sibs.util.EmailService;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.sql.*;

@WebServlet("/deliveryApproval")
public class DeliveryApprovalServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            res.sendRedirect(req.getContextPath() + "/login.jsp");
            return;
        }

        int    deliveryBoyId = Integer.parseInt(req.getParameter("deliveryBoyId"));
        String action        = req.getParameter("action"); // approve | reject | review
        User   adminUser     = (User) session.getAttribute("user");
        String reviewedBy    = (adminUser != null) ? adminUser.getUsername() : "admin";

        String newStatus;
        switch (action) {
            case "approve": newStatus = "ACTIVE";        break;
            case "reject":  newStatus = "REJECTED";      break;
            case "review":  newStatus = "UNDER_REVIEW";  break;
            default:
                res.sendRedirect("admin-delivery-approvals.jsp?error=err");
                return;
        }

        // ── Fetch delivery boy email + name ──────────────────────────────────
        String name  = null;
        String email = null;

        String fetchSql = "SELECT name, email FROM delivery_boys WHERE id = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(fetchSql)) {
            ps.setInt(1, deliveryBoyId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    name  = rs.getString("name");
                    email = rs.getString("email");
                }
            }
        } catch (SQLException e) { e.printStackTrace(); }

        if (email == null) {
            res.sendRedirect("admin-delivery-approvals.jsp?error=err");
            return;
        }

        // ── Update status ────────────────────────────────────────────────────
        String updateSql;
        if ("ACTIVE".equals(newStatus)) {
            updateSql = "UPDATE delivery_boys SET status=?, approved_at=NOW(), reviewed_by=? WHERE id=?";
        } else if ("REJECTED".equals(newStatus)) {
            updateSql = "UPDATE delivery_boys SET status=?, rejected_at=NOW(), reviewed_by=? WHERE id=?";
        } else {
            updateSql = "UPDATE delivery_boys SET status=?, reviewed_by=? WHERE id=?";
        }
        boolean ok = false;
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(updateSql)) {
            ps.setString(1, newStatus);
            ps.setString(2, reviewedBy);
            ps.setInt   (3, deliveryBoyId);
            ok = ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); }

        if (!ok) {
            res.sendRedirect("admin-delivery-approvals.jsp?error=err");
            return;
        }

        // ── Send email + push notification ──────────────────────────────────
        if ("ACTIVE".equals(newStatus)) {
            EmailService.sendDeliveryBoyApprovedEmail(email, name);
            NotificationDAO.sendApprovalDecision(deliveryBoyId, "Approved");
            NotificationDAO.sendKycApproved(deliveryBoyId);
            res.sendRedirect("admin-delivery-approvals.jsp?msg=approved&tab=ACTIVE");
        } else if ("REJECTED".equals(newStatus)) {
            EmailService.sendDeliveryBoyRejectedEmail(email, name);
            NotificationDAO.sendApprovalDecision(deliveryBoyId, "Rejected");
            NotificationDAO.sendKycRejected(deliveryBoyId, null);
            res.sendRedirect("admin-delivery-approvals.jsp?msg=rejected&tab=REJECTED");
        } else {
            res.sendRedirect("admin-delivery-approvals.jsp?tab=UNDER_REVIEW");
        }
    }
}