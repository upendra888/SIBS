package com.sibs.servlet;

import com.sibs.model.User;
import com.sibs.util.DBConnection;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.*;

/**
 * Returns JSON for a return/refund request by group_id.
 *
 * GET /GetReturnByGroup?groupId=42
 *
 * Response:
 * {
 *   "found": true,
 *   "returnId": 7,
 *   "orderId": 15,
 *   "groupId": 42,
 *   "status": "PENDING",
 *   "reason": "Damaged product",
 *   "description": "...",
 *   "refundAmount": 180.0,
 *   "refundMethod": "COD",
 *   "adminNote": "",
 *   "productName": "Apple",
 *   "customerName": "Ravi",
 *   "paymentMethod": "COD",
 *   "requestedAt": "2026-05-20 09:15"
 * }
 *
 * If no return request exists: { "found": false }
 */
@WebServlet("/GetReturnByGroup")
public class GetReturnByGroupServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        // Staff or admin only
        User user = null;
        if (req.getSession(false) != null)
            user = (User) req.getSession(false).getAttribute("user");
        if (user == null) { resp.sendError(401); return; }
        String role = user.getRole();
        if (!"staff".equalsIgnoreCase(role) && !"admin".equalsIgnoreCase(role)) {
            resp.sendError(403); return;
        }

        String groupIdParam = req.getParameter("groupId");
        if (groupIdParam == null || groupIdParam.trim().isEmpty()) {
            resp.sendError(400, "groupId required"); return;
        }

        int groupId;
        try { groupId = Integer.parseInt(groupIdParam.trim()); }
        catch (NumberFormatException e) { resp.sendError(400, "invalid groupId"); return; }

        String sql =
            "SELECT rr.id AS return_id, rr.order_id, rr.group_id, rr.status, " +
            "  rr.reason, rr.description, rr.refund_amount, rr.refund_method, rr.admin_note, " +
            "  DATE_FORMAT(rr.requested_at, '%Y-%m-%d %H:%i') AS requested_at, " +
            "  p.name AS product_name, " +
            "  o.name  AS customer_name, " +
            "  o.payment_method " +
            "FROM return_requests rr " +
            "LEFT JOIN products p ON p.id = rr.product_id " +
            "LEFT JOIN orders   o ON o.id = rr.order_id " +
            "WHERE rr.group_id = ? " +
            "ORDER BY rr.requested_at DESC LIMIT 1";

        resp.setContentType("application/json");
        resp.setCharacterEncoding("UTF-8");

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, groupId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    resp.getWriter().write("{\"found\":false}");
                    return;
                }
                StringBuilder sb = new StringBuilder();
                sb.append("{")
                  .append("\"found\":true,")
                  .append("\"returnId\":").append(rs.getInt("return_id")).append(",")
                  .append("\"orderId\":").append(rs.getInt("order_id")).append(",")
                  .append("\"groupId\":").append(rs.getInt("group_id")).append(",")
                  .append("\"status\":\"").append(esc(rs.getString("status"))).append("\",")
                  .append("\"reason\":\"").append(esc(rs.getString("reason"))).append("\",")
                  .append("\"description\":\"").append(esc(rs.getString("description"))).append("\",")
                  .append("\"refundAmount\":").append(rs.getDouble("refund_amount")).append(",")
                  .append("\"refundMethod\":\"").append(esc(rs.getString("refund_method"))).append("\",")
                  .append("\"adminNote\":\"").append(esc(rs.getString("admin_note"))).append("\",")
                  .append("\"requestedAt\":\"").append(esc(rs.getString("requested_at"))).append("\",")
                  .append("\"productName\":\"").append(esc(rs.getString("product_name"))).append("\",")
                  .append("\"customerName\":\"").append(esc(rs.getString("customer_name"))).append("\",")
                  .append("\"paymentMethod\":\"").append(esc(rs.getString("payment_method"))).append("\"")
                  .append("}");
                resp.getWriter().write(sb.toString());
            }
        } catch (SQLException e) {
            e.printStackTrace();
            resp.sendError(500, "DB error");
        }
    }

    private String esc(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\n", "\\n")
                .replace("\r", "");
    }
}