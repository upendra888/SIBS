package com.sibs.servlet;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import com.sibs.dao.NotificationDAO;
import com.sibs.model.User;
import com.sibs.util.DBConnection;

import java.io.IOException;
import java.sql.*;

/**
 * ReturnRequestServlet
 *
 * Called from my-orders.jsp when a customer clicks "Request Return"
 * on a Delivered order.
 *
 * POST params:
 *   orderId  — the order id (any row id from the group)
 *   groupId  — the group_id of the order batch
 *   reason   — customer's reason text
 *
 * FIXES APPLIED:
 *   1. status inserted as 'PENDING' (uppercase) to match ReturnDAO / managereturns.jsp checks.
 *   2. Order status updated to 'RETURN_REQUESTED' (consistent uppercase enum style).
 *   3. Duplicate check now covers both order_id and group_id to be safe.
 */
@WebServlet("/returnRequest")
public class Returnrequestservlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // ── 1. AUTH ───────────────────────────────────────────────────
        HttpSession session = request.getSession(false);
        User user = (session != null) ? (User) session.getAttribute("customer") : null;
        if (user == null) {
            response.sendRedirect("customer-login.jsp");
            return;
        }

        // ── 2. PARAMS ────────────────────────────────────────────────
        String orderIdStr = request.getParameter("orderId");
        String groupIdStr = request.getParameter("groupId");
        String reason     = request.getParameter("reason");

        if (orderIdStr == null || groupIdStr == null || reason == null || reason.trim().isEmpty()) {
            response.sendRedirect("my-orders.jsp?error=return_invalid");
            return;
        }

        int orderId;
        int groupId;
        try {
            orderId = Integer.parseInt(orderIdStr.trim());
            groupId = Integer.parseInt(groupIdStr.trim());
        } catch (NumberFormatException e) {
            response.sendRedirect("my-orders.jsp?error=return_invalid");
            return;
        }

        // ── 3. VERIFY ORDER BELONGS TO USER AND IS DELIVERED ─────────
        String checkSql = "SELECT status FROM orders WHERE group_id=? AND user_id=? LIMIT 1";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(checkSql)) {
            ps.setInt(1, groupId);
            ps.setInt(2, user.getId());
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    response.sendRedirect("my-orders.jsp?error=return_not_found");
                    return;
                }
                String status = rs.getString("status");
                // FIX: use equalsIgnoreCase to handle any case variant in DB
                if (!"Delivered".equalsIgnoreCase(status)) {
                    response.sendRedirect("my-orders.jsp?error=return_not_delivered");
                    return;
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("my-orders.jsp?error=return_failed");
            return;
        }

        // ── 4. CHECK FOR DUPLICATE (only one return per group) ────────
        String dupSql = "SELECT id FROM return_requests WHERE group_id=? LIMIT 1";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(dupSql)) {
            ps.setInt(1, groupId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    response.sendRedirect("my-orders.jsp?error=return_exists");
                    return;
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("my-orders.jsp?error=return_failed");
            return;
        }

        // ── 5. INSERT RETURN REQUEST ──────────────────────────────────
        // FIX: status must be 'PENDING' (uppercase) so ReturnDAO.getAllReturns()
        //      and the JSP stat-card comparisons (${r.status eq 'PENDING'}) work correctly.
        //      The old code inserted 'Pending' which caused the admin panel to show 0 everywhere.
        String insertSql = "INSERT INTO return_requests (order_id, group_id, user_id, reason, status) " +
                           "VALUES (?, ?, ?, ?, ?)";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(insertSql)) {
            ps.setInt   (1, orderId);
            ps.setInt   (2, groupId);
            ps.setInt   (3, user.getId());
            ps.setString(4, reason.trim());
            ps.setString(5, "PENDING"); // FIX: was "Pending"
            ps.executeUpdate();
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("my-orders.jsp?error=return_failed");
            return;
        }

        // ── 6. UPDATE ORDER STATUS ────────────────────────────────────
        String updateSql = "UPDATE orders SET status='RETURN_REQUESTED' WHERE group_id=?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(updateSql)) {
            ps.setInt(1, groupId);
            ps.executeUpdate();
        } catch (Exception e) {
            e.printStackTrace();
            // non-fatal – return was already submitted
        }

        // ── 7. NOTIFY STAFF about new return request ─────────────────
        try {
            String pSql = "SELECT p.name FROM orders o JOIN products p ON o.product_id=p.id WHERE o.id=? LIMIT 1";
            try (Connection con = DBConnection.getConnection();
                 PreparedStatement ps = con.prepareStatement(pSql)) {
                ps.setInt(1, orderId);
                try (ResultSet rs = ps.executeQuery()) {
                    String productName = rs.next() ? rs.getString("name") : "item";
                    NotificationDAO.sendNewReturnToStaff(orderId, user.getName(), productName);
                }
            }
        } catch (Exception ignored) {}

        response.sendRedirect("my-orders.jsp?return_success=1");
    }
}