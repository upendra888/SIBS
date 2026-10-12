package com.sibs.servlet;

import com.sibs.dao.CodLedgerDAO;
import com.sibs.dao.DeliveryBoyDAO;
import com.sibs.dao.NotificationDAO;
import com.sibs.dao.OrderStatusHistoryDAO;
import com.sibs.model.DeliveryBoy;
import com.sibs.model.User;
import com.sibs.util.DBConnection;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

public class VerifyOtpServlet extends HttpServlet {
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);

        // Check who is confirming — customer or delivery boy
        User customer = session != null ? (User) session.getAttribute("customer") : null;
        DeliveryBoy db = session != null ? (DeliveryBoy) session.getAttribute("deliveryBoy") : null;

        if (customer == null && db == null) {
            res.sendRedirect("customer-login.jsp");
            return;
        }

        int assignmentId, orderId;
        try {
            assignmentId = Integer.parseInt(req.getParameter("assignmentId"));
            orderId      = Integer.parseInt(req.getParameter("orderId"));
        } catch (Exception e) {
            res.sendRedirect("my-orders.jsp?error=invalid");
            return;
        }

        // Build OTP from 4 digit fields
        String d1 = req.getParameter("otp1");
        String d2 = req.getParameter("otp2");
        String d3 = req.getParameter("otp3");
        String d4 = req.getParameter("otp4");
        String enteredOtp = (d1!=null?d1:"") + (d2!=null?d2:"") +
                            (d3!=null?d3:"") + (d4!=null?d4:"");

        boolean success = new DeliveryBoyDAO().verifyOtpAndDeliver(assignmentId, orderId, enteredOtp);

        if (success) {
            // COD Ledger entry
            try (Connection con = DBConnection.getConnection();
                 PreparedStatement ps = con.prepareStatement(
                     "SELECT o.payment_method, " +
                     "       SUM(o.total) AS items_total, " +
                     "       MAX(COALESCE(o.delivery_charge, 0)) AS delivery_charge " +
                     "FROM orders o " +
                     "WHERE o.group_id = (SELECT group_id FROM orders WHERE id = ? LIMIT 1) " +
                     "GROUP BY o.payment_method LIMIT 1")) {
                ps.setInt(1, orderId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        String payMethod      = rs.getString("payment_method");
                        double itemsTotal     = rs.getDouble("items_total");
                        double deliveryCharge = rs.getDouble("delivery_charge");
                        double amountCollected = itemsTotal + deliveryCharge;

                        if ("COD".equalsIgnoreCase(payMethod) && db != null) {
                            new CodLedgerDAO().recordCollection(
                                db.getId(), orderId, amountCollected, deliveryCharge);
                        }
                    }
                }
            } catch (Exception e) {
                e.printStackTrace();
            }

            // Redirect based on who confirmed
            if (customer != null) {
                // Customer confirmed — go back to my orders with success
                res.sendRedirect("my-orders.jsp?delivered=success");
            } else {
                res.sendRedirect("delivery-dashboard.jsp?delivered=success");
            }
        } else {
            if (customer != null) {
                res.sendRedirect("my-orders.jsp?error=wrong_otp&orderId=" + orderId);
            } else {
                res.sendRedirect("delivery-dashboard.jsp?error=wrong_otp&assignmentId=" + assignmentId);
            }
        }
    }
}