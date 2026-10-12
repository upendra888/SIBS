package com.sibs.servlet;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import com.sibs.dao.ProductDAO;
import com.sibs.dao.NotificationDAO;
import com.sibs.dao.OrderStatusHistoryDAO;
import com.sibs.model.User;
import com.sibs.util.DBConnection;
import com.sibs.util.EmailService;

import java.io.IOException;
import java.sql.*;

/**
 * ProcessReturnServlet
 *
 * Called from return-requests.jsp (staff panel).
 * Staff can Approve or Reject a return request.
 *
 * POST params:
 *   returnId  — id of the return_requests row
 *   action    — "approve" or "reject"
 *   staffNote — optional note
 */
@WebServlet("/processReturn")
public class Processreturnservlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // ── 1. AUTH ───────────────────────────────────────────────────
        HttpSession session = request.getSession(false);
        User user = (session != null) ? (User) session.getAttribute("user") : null;
        if (user == null || (!"ADMIN".equals(user.getRole()) && !"STAFF".equals(user.getRole()))) {
            response.sendRedirect("login.jsp");
            return;
        }

        // Admin is monitoring only — staff handles all return actions
        if ("ADMIN".equals(user.getRole())) {
            response.sendRedirect("return-requests.jsp?error=admin_readonly");
            return;
        }

        // ── 2. PARAMS ────────────────────────────────────────────────
        String returnIdStr = request.getParameter("returnId");
        String action      = request.getParameter("action");   // "approve" or "reject"
        String staffNote   = request.getParameter("staffNote");

        if (returnIdStr == null || action == null ||
            (!action.equals("approve") && !action.equals("reject"))) {
            response.sendRedirect("return-requests.jsp?error=invalid");
            return;
        }

        int returnId = Integer.parseInt(returnIdStr.trim());

        // ── 3. FETCH RETURN REQUEST ──────────────────────────────────
        int groupId  = -1;
        int orderId  = -1;
        int userId   = -1;
        String currentReturnStatus = null;

        String fetchSql = "SELECT group_id, order_id, user_id, status FROM return_requests WHERE id=?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(fetchSql)) {
            ps.setInt(1, returnId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    groupId             = rs.getInt("group_id");
                    orderId             = rs.getInt("order_id");
                    userId              = rs.getInt("user_id");
                    currentReturnStatus = rs.getString("status");
                } else {
                    response.sendRedirect("return-requests.jsp?error=not_found");
                    return;
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("return-requests.jsp?error=fetch_failed");
            return;
        }

        // ── 4. GUARD: Only process Pending requests ────────────────
        if (!"Pending".equalsIgnoreCase(currentReturnStatus)) {
            response.sendRedirect("return-requests.jsp?error=already_processed");
            return;
        }

        // ── 5. UPDATE return_requests ─────────────────────────────────
        String newReturnStatus = action.equals("approve") ? "APPROVED" : "REJECTED";
        String updateRR = "UPDATE return_requests SET status=?, admin_note=? WHERE id=?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(updateRR)) {
            ps.setString(1, newReturnStatus);
            ps.setString(2, staffNote != null ? staffNote.trim() : "");
            ps.setInt(3, returnId);
            ps.executeUpdate();
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("return-requests.jsp?error=update_failed");
            return;
        }

        // ── 6. UPDATE order status ────────────────────────────────────
        String orderStatus = action.equals("approve") ? "Returned" : "Return Rejected";
        String updateOrder = "UPDATE orders SET status=? WHERE group_id=?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(updateOrder)) {
            ps.setString(1, orderStatus);
            ps.setInt(2, groupId);
            ps.executeUpdate();
        } catch (Exception e) {
            e.printStackTrace();
        }

        // ── 7. LOG STATUS HISTORY ─────────────────────────────────────
        String changedBy = user.getName() != null ? user.getName() : user.getRole();
        new OrderStatusHistoryDAO().logByGroup(groupId, orderStatus, changedBy);

        // ── 8. IF APPROVED: restore stock ─────────────────────────────
        if (action.equals("approve")) {
            new ProductDAO().restoreStockByGroup(groupId);
        }

        // ── 9. SEND EMAIL + NOTIFICATION TO CUSTOMER ─────────────────
        final String finalOrderStatus = orderStatus;
        final int    finalGroupId     = groupId;
        final int    finalUserId      = userId;
        final int    finalReturnId    = returnId;
        final String finalAction      = action;
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(
                 "SELECT o.id, o.name, o.email, p.name AS product_name " +
                 "FROM orders o JOIN products p ON o.product_id = p.id " +
                 "WHERE o.group_id=? LIMIT 1")) {
            ps.setInt(1, finalGroupId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    final String custEmail   = rs.getString("email");
                    final String custName    = rs.getString("name");
                    final String productName = rs.getString("product_name");
                    final int    firstId     = rs.getInt("id");
                    new Thread(() ->
                        EmailService.sendOrderStatusEmail(
                            custEmail, custName, finalOrderStatus, firstId, productName)
                    ).start();
                    // Push notification to customer
                    NotificationDAO.sendReturnStatusChanged(
                        finalUserId, finalReturnId, productName,
                        finalAction.equals("approve") ? "Approved" : "Rejected");
                }
            }
        } catch (Exception ignored) {}

        response.sendRedirect("return-requests.jsp?success=" + action);
    }
}