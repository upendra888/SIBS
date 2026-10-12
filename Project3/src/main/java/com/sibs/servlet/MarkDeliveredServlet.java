package com.sibs.servlet;

import com.sibs.dao.CodLedgerDAO;
import com.sibs.dao.NotificationDAO;
import com.sibs.dao.DeliveryBoyDAO;
import com.sibs.dao.OrderStatusHistoryDAO;
import com.sibs.model.DeliveryBoy;
import com.sibs.util.AppSettings;
import com.sibs.util.DBConnection;
import com.sibs.util.EmailService;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

@WebServlet("/markDelivered")
public class MarkDeliveredServlet extends HttpServlet {

    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws IOException {

        DeliveryBoy db = (DeliveryBoy) req.getSession().getAttribute("deliveryBoy");
        if (db == null) {
            res.sendRedirect("delivery-login.jsp");
            return;
        }

        try {
            int assignmentId = Integer.parseInt(req.getParameter("assignmentId"));
            int orderId      = Integer.parseInt(req.getParameter("orderId"));

            // ── Return pickup: "Confirm Item Received" — different flow ──────
            String returnIdParam = req.getParameter("returnId");
            if (returnIdParam != null && !returnIdParam.isEmpty()) {
                int returnId = Integer.parseInt(returnIdParam);
                // Mark assignment DELIVERED
                new DeliveryBoyDAO().markDelivered(assignmentId, db.getId());
                // Mark return COMPLETED + update order return_status
                try (Connection con = DBConnection.getConnection()) {
                    try (PreparedStatement ps = con.prepareStatement(
                            "UPDATE return_requests SET status='COMPLETED' WHERE id=?")) {
                        ps.setInt(1, returnId);
                        ps.executeUpdate();
                    }
                    try (PreparedStatement ps = con.prepareStatement(
                            "UPDATE orders SET return_status='Return_Completed' WHERE id=?")) {
                        ps.setInt(1, orderId);
                        ps.executeUpdate();
                    }
                    // Notify customer
                    try (PreparedStatement ps = con.prepareStatement(
                            "SELECT rr.user_id, p.name FROM return_requests rr " +
                            "JOIN products p ON p.id=rr.product_id WHERE rr.id=?")) {
                        ps.setInt(1, returnId);
                        try (java.sql.ResultSet rs = ps.executeQuery()) {
                            if (rs.next()) {
                                int uid = rs.getInt("user_id");
                                String pname = rs.getString("name");
                                NotificationDAO.sendReturnStatusChanged(uid, returnId, pname, "COMPLETED");
                            }
                        }
                    }
                }
                res.sendRedirect("delivery-dashboard.jsp?delivered=success");
                return;
            }
            // ─────────────────────────────────────────────────────────────────

            System.out.println("[MARK-DELIVERED] assignmentId=" + assignmentId + " orderId=" + orderId + " deliveryBoyId=" + db.getId());

            // 1. Mark assignment as DELIVERED
            if (!new DeliveryBoyDAO().markDelivered(assignmentId, db.getId())) {
                res.sendRedirect("delivery-dashboard.jsp?error=invalid_assignment");
                return;
            }

            // 2. Update all orders in group to Delivered
            try (Connection con = DBConnection.getConnection();
                 PreparedStatement ps = con.prepareStatement(
                     "SELECT group_id FROM orders WHERE id=?")) {
                ps.setInt(1, orderId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        int groupId = rs.getInt("group_id");
                        try (PreparedStatement upd = con.prepareStatement(
                                "UPDATE orders SET status='Delivered' WHERE group_id=?")) {
                            upd.setInt(1, groupId);
                            upd.executeUpdate();
                        }
                        new OrderStatusHistoryDAO().logByGroup(
                            groupId, "Delivered",
                            db.getName() != null ? db.getName() : "Delivery Boy");
                    }
                }
            }

            // 3. Get order details
            String custEmail      = null;
            String custName       = null;
            String productName    = null;
            String payMethod      = null;
            int    custUserId     = 0;
            double itemsTotal     = 0;
            double deliveryCharge = 0;

            try (Connection con = DBConnection.getConnection();
                 PreparedStatement ps = con.prepareStatement(
                     "SELECT MAX(o.name) AS name, MAX(o.email) AS email, " +
                     "       MAX(o.payment_method) AS payment_method, " +
                     "       SUM(o.total) AS items_total, " +
                     "       MAX(COALESCE(o.delivery_charge,0)) AS delivery_charge, " +
                     "       MAX(o.user_id) AS user_id, " +
                     "       GROUP_CONCAT(p.name SEPARATOR ', ') AS product_name " +
                     "FROM orders o LEFT JOIN products p ON o.product_id = p.id " +
                     "WHERE o.group_id = (SELECT group_id FROM orders WHERE id=? LIMIT 1)")) {
                ps.setInt(1, orderId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        custEmail      = rs.getString("email");
                        custName       = rs.getString("name");
                        productName    = rs.getString("product_name");
                        custUserId     = rs.getInt("user_id");
                        payMethod      = rs.getString("payment_method");
                        itemsTotal     = rs.getDouble("items_total");
                        deliveryCharge = rs.getDouble("delivery_charge");
                    }
                }
            }

            double amountCollected = itemsTotal + deliveryCharge;
            System.out.println("[MARK-DELIVERED] payMethod='" + payMethod + "' amountCollected=" + amountCollected);

            // 4. COD check — treat null payment_method as COD
            boolean isCod = (payMethod == null || "COD".equalsIgnoreCase(payMethod.trim()));
            System.out.println("[MARK-DELIVERED] isCod=" + isCod);

            if (isCod && amountCollected > 0) {

                // Record in ledger
                new CodLedgerDAO().recordCollection(db.getId(), orderId, amountCollected, deliveryCharge);

                // Fetch wallet
                double wallet = 0;
                try (Connection con = DBConnection.getConnection();
                     PreparedStatement ps = con.prepareStatement(
                         "SELECT wallet FROM delivery_boys WHERE id=?")) {
                    ps.setInt(1, db.getId());
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) wallet = rs.getDouble(1);
                    }
                }

                // Fetch today's delivered count
                double earningsToday = 0;
                try (Connection con = DBConnection.getConnection();
                     PreparedStatement ps = con.prepareStatement(
                         "SELECT COUNT(*) FROM delivery_assignments " +
                         "WHERE delivery_boy_id=? " +
                         "AND UPPER(status)='DELIVERED' " +
                         "AND DATE(delivered_at)=CURDATE()")) {
                    ps.setInt(1, db.getId());
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) earningsToday = rs.getInt(1) * AppSettings.getPerDeliveryPay();
                    }
                }

                double available = wallet + earningsToday;

                System.out.println("[COD-CHECK] wallet=" + wallet
                    + " earningsToday=" + earningsToday
                    + " available=" + available
                    + " codAmount=" + amountCollected);

                if (available < amountCollected) {
                    System.out.println("[COD-CHECK] INSUFFICIENT — forcing offline id=" + db.getId());

                    // Force offline
                    try (Connection con = DBConnection.getConnection();
                         PreparedStatement ps = con.prepareStatement(
                             "UPDATE delivery_boys SET is_online=0, shift_status='OFFLINE' WHERE id=?")) {
                        ps.setInt(1, db.getId());
                        ps.executeUpdate();
                    }

                    // Store DB alert for dashboard banner
                    String alertMsg = String.format(
                        "You have been taken Offline because your " +
                        "wallet (Rs.%.0f) + today earnings (Rs.%.0f) = Rs.%.0f " +
                        "is less than COD amount collected (Rs.%.0f). " +
                        "Please recharge your wallet and go Online again.",
                        wallet, earningsToday, available, amountCollected);

                    try (Connection con = DBConnection.getConnection();
                         PreparedStatement ps = con.prepareStatement(
                             "UPDATE delivery_boys SET cod_offline_alert=? WHERE id=?")) {
                        ps.setString(1, alertMsg);
                        ps.setInt(2, db.getId());
                        ps.executeUpdate();
                    }

                    // Session message — shows immediately on dashboard
                    req.getSession().setAttribute("onlineError",
                        "Taken Offline: wallet + earnings Rs." +
                        String.format("%.0f", available) +
                        " is less than COD Rs." +
                        String.format("%.0f", amountCollected) +
                        ". Please recharge and go Online.");

                } else {
                    System.out.println("[COD-CHECK] OK — sufficient funds, staying online");
                }
            }

            // 5. Send email + in-app notification
            if (custUserId > 0) {
                final String fprod = productName;
                NotificationDAO.sendOrderStatusChanged(custUserId, orderId, fprod != null ? fprod : "your order", "Delivered");
            }
            // Notify delivery boy: delivery successful
            NotificationDAO.sendDeliverySuccessful(db.getId(), orderId, productName != null ? productName : "the order");

            // Notify delivery boy: COD collected reminder
            if (isCod && amountCollected > 0) {
                NotificationDAO.sendCodCollected(db.getId(), orderId, amountCollected);
            }
            if (custEmail != null) {
                final String fe = custEmail, fn = custName, fp = productName;
                final int foid = orderId;
                new Thread(() ->
                    EmailService.sendOrderStatusEmail(fe, fn, "Delivered", foid, fp)
                ).start();
            }

            res.sendRedirect("delivery-dashboard.jsp?delivered=success");

        } catch (Exception e) {
            e.printStackTrace();
            res.sendRedirect("delivery-dashboard.jsp?error=deliver_failed");
        }
    }
}