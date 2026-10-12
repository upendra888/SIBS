package com.sibs.servlet;

import com.sibs.dao.DeliveryBoyDAO;
import com.sibs.dao.NotificationDAO;
import com.sibs.model.DeliveryBoy;
import com.sibs.util.DBConnection;
import com.sibs.util.EmailService;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

public class ConfirmPickupServlet extends HttpServlet {
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        DeliveryBoy db = (DeliveryBoy) req.getSession().getAttribute("deliveryBoy");
        if (db == null) { res.sendRedirect("delivery-login.jsp"); return; }

        int assignmentId = Integer.parseInt(req.getParameter("assignmentId"));

        // Check if this is a return pickup
        String returnIdParam = req.getParameter("returnId");
        boolean isReturnPickup = (returnIdParam != null && !returnIdParam.isEmpty());
        int returnId = isReturnPickup ? Integer.parseInt(returnIdParam) : 0;

        int orderId = 0;
        int customerId = 0;
        String customerEmail = null;
        String customerName  = null;
        String productName   = "your order";

        try (Connection con = DBConnection.getConnection()) {
            // Get order info from this assignment
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT o.id, o.email, o.name, o.group_id, o.user_id, " +
                    "       p.name AS product_name " +
                    "FROM orders o " +
                    "JOIN delivery_assignments da ON da.order_id = o.id " +
                    "LEFT JOIN products p ON p.id = o.product_id " +
                    "WHERE da.id = ? LIMIT 1")) {
                ps.setInt(1, assignmentId);
                ResultSet rs = ps.executeQuery();
                if (rs.next()) {
                    orderId       = rs.getInt("id");
                    customerEmail = rs.getString("email");
                    customerName  = rs.getString("name");
                    customerId    = rs.getInt("user_id");
                    String pn     = rs.getString("product_name");
                    if (pn != null && !pn.isEmpty()) productName = pn;
                    int groupId   = rs.getInt("group_id");

                    if (isReturnPickup) {
                        // Return pickup: return_requests నుండి user_id తీసుకో
                        try (PreparedStatement rps = con.prepareStatement(
                                "SELECT rr.user_id, u.email, u.username, p2.name AS pname " +
                                "FROM return_requests rr " +
                                "LEFT JOIN users u ON u.id = rr.user_id " +
                                "LEFT JOIN products p2 ON p2.id = rr.product_id " +
                                "WHERE rr.id = ? LIMIT 1")) {
                            rps.setInt(1, returnId);
                            ResultSet rrs = rps.executeQuery();
                            if (rrs.next()) {
                                customerId    = rrs.getInt("user_id");
                                customerEmail = rrs.getString("email");
                                customerName  = rrs.getString("username");
                                String rPname = rrs.getString("pname");
                                if (rPname != null && !rPname.isEmpty()) productName = rPname;
                            }
                        }
                        // return_requests status → PICKED_UP
                        try (PreparedStatement upd = con.prepareStatement(
                                "UPDATE return_requests SET status='PICKED_UP' WHERE id=? AND status='PICKUP_SCHEDULED'")) {
                            upd.setInt(1, returnId);
                            upd.executeUpdate();
                        }
                        // order return_status update
                        try (PreparedStatement upd = con.prepareStatement(
                                "UPDATE orders SET return_status='Return_Item_Picked_Up' WHERE group_id=?")) {
                            upd.setInt(1, groupId);
                            upd.executeUpdate();
                        }
                    } else {
                        // Normal delivery: update order status to Out for Delivery
                        try (PreparedStatement upd = con.prepareStatement(
                                "UPDATE orders SET status='Out for Delivery' WHERE group_id=?")) {
                            upd.setInt(1, groupId);
                            upd.executeUpdate();
                        }
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        // Mark pickup in delivery_assignments and get OTP
        String otp = new DeliveryBoyDAO().confirmPickup(assignmentId);

        if (otp == null) {
            res.sendRedirect("delivery-dashboard.jsp?error=pickup_failed");
            return;
        }

        if (!isReturnPickup) {
            // Only send OTP email for normal delivery
            if (customerEmail != null && !customerEmail.isEmpty()) {
                EmailService.sendOtpEmail(customerEmail,
                    customerName != null ? customerName : "Customer", orderId, otp);
            }
            // Notify customer: out for delivery
            if (customerId > 0) {
                NotificationDAO.sendDeliveryStarted(customerId, orderId, productName);
            }
        } else {
            // Return pickup: notify customer that item has been picked up
            if (customerId > 0) {
                NotificationDAO.sendReturnStatusChanged(customerId, returnId,
                    productName, "PICKED_UP");
            }
        }

        // Notify delivery boy
        NotificationDAO.sendPickupConfirmed(db.getId(), orderId, productName);

        res.sendRedirect("delivery-dashboard.jsp?pickup=success");
    }
}