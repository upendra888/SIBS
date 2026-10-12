package com.sibs.servlet;

import com.sibs.dao.DeliveryBoyDAO;
import com.sibs.dao.NotificationDAO;
import com.sibs.model.User;
import com.sibs.util.DBConnection;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

/**
 * StaffWithdrawServlet
 *
 * POST /staffWithdraw
 *   Params:
 *     action        – "approve" | "reject"
 *     requestId     – int (wallet_withdraw_requests.id)
 *     staffNote     – optional note / reason
 */
@WebServlet("/staffWithdraw")
public class StaffWithdrawServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {

        // Staff auth check
        User user = (User) req.getSession().getAttribute("user");
        if (user == null || (!"STAFF".equals(user.getRole()) && !"ADMIN".equals(user.getRole()))) {
            resp.sendRedirect("login.jsp");
            return;
        }

        String action    = req.getParameter("action");
        String staffNote = req.getParameter("staffNote");
        int requestId;
        try {
            requestId = Integer.parseInt(req.getParameter("requestId"));
        } catch (Exception e) {
            resp.sendRedirect("staff-withdrawals.jsp?flash=invalid");
            return;
        }

        DeliveryBoyDAO dao = new DeliveryBoyDAO();

        if ("approve".equalsIgnoreCase(action)) {
            // Fetch delivery boy id and amount for notification
            int deliveryBoyId = 0;
            double amount = 0;
            try (Connection con = DBConnection.getConnection();
                 PreparedStatement ps = con.prepareStatement(
                     "SELECT delivery_boy_id, amount FROM wallet_withdraw_requests WHERE id=?")) {
                ps.setInt(1, requestId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        deliveryBoyId = rs.getInt("delivery_boy_id");
                        amount        = rs.getDouble("amount");
                    }
                }
            } catch (Exception ignored) {}

            String result = dao.approveWithdraw(requestId, staffNote);
            if ("OK".equals(result)) {
                if (deliveryBoyId > 0) {
                    NotificationDAO.sendWithdrawApproved(deliveryBoyId, amount, staffNote);
                }
                resp.sendRedirect("staff-withdrawals.jsp?flash=approved");
            } else if ("INSUFFICIENT".equals(result)) {
                resp.sendRedirect("staff-withdrawals.jsp?flash=insufficient");
            } else if ("NOT_FOUND".equals(result)) {
                resp.sendRedirect("staff-withdrawals.jsp?flash=not_found");
            } else {
                resp.sendRedirect("staff-withdrawals.jsp?flash=error");
            }

        } else if ("reject".equalsIgnoreCase(action)) {
            int deliveryBoyId = 0;
            double amount = 0;
            try (Connection con = DBConnection.getConnection();
                 PreparedStatement ps = con.prepareStatement(
                     "SELECT delivery_boy_id, amount FROM wallet_withdraw_requests WHERE id=?")) {
                ps.setInt(1, requestId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        deliveryBoyId = rs.getInt("delivery_boy_id");
                        amount        = rs.getDouble("amount");
                    }
                }
            } catch (Exception ignored) {}

            String result = dao.rejectWithdraw(requestId, staffNote);
            if ("OK".equals(result)) {
                if (deliveryBoyId > 0) {
                    NotificationDAO.sendWithdrawRejected(deliveryBoyId, amount, staffNote);
                }
                resp.sendRedirect("staff-withdrawals.jsp?flash=rejected");
            } else {
                resp.sendRedirect("staff-withdrawals.jsp?flash=error");
            }

        } else {
            resp.sendRedirect("staff-withdrawals.jsp?flash=invalid");
        }
    }
}