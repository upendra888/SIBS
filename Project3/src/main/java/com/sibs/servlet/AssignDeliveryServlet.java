package com.sibs.servlet;

import com.sibs.dao.DeliveryBoyDAO;
import com.sibs.dao.NotificationDAO;
import com.sibs.dao.OrderDAO;
import com.sibs.model.Order;
import com.sibs.model.User;
import com.sibs.util.DBConnection;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.util.List;

public class AssignDeliveryServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws IOException {

        HttpSession session = request.getSession(false);
        User user = (session != null) ? (User) session.getAttribute("user") : null;

        if (user == null || (!"STAFF".equals(user.getRole()) && !"ADMIN".equals(user.getRole()))) {
            response.sendRedirect("login.jsp");
            return;
        }

        int    groupId       = Integer.parseInt(request.getParameter("groupId"));
        int    deliveryBoyId = Integer.parseInt(request.getParameter("deliveryBoyId"));
        String note          = request.getParameter("deliveryNote");

        DeliveryBoyDAO dbDao    = new DeliveryBoyDAO();
        OrderDAO       orderDao = new OrderDAO();

        List<Order> groupOrders = orderDao.getOrdersByGroupId(groupId);

        // FIX: Create only ONE delivery_assignment for the whole group (first order id).
        // Previously looped over all rows → created 3 assignments for a 3-item order.
        if (!groupOrders.isEmpty()) {
            dbDao.assignDeliveryBoy(groupOrders.get(0).getId(), deliveryBoyId, note);
        }

        // Update ALL orders in the group to 'Assigned' in one shot.
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(
                 "UPDATE orders SET status='Assigned' WHERE group_id=?")) {
            ps.setInt(1, groupId);
            ps.executeUpdate();
        } catch (Exception e) {
            e.printStackTrace();
        }

        // ── Notify delivery boy + customer — ONCE per group ─────────────────
        try {
            String infoSql = "SELECT o.user_id, u.name AS customer_name " +
                             "FROM orders o JOIN users u ON o.user_id = u.id " +
                             "WHERE o.group_id = ? LIMIT 1";
            try (Connection con2 = DBConnection.getConnection();
                 PreparedStatement ps2 = con2.prepareStatement(infoSql)) {
                ps2.setInt(1, groupId);
                try (java.sql.ResultSet rs = ps2.executeQuery()) {
                    if (rs.next()) {
                        int    customerId   = rs.getInt("user_id");
                        String customerName = rs.getString("customer_name");

                        // FIX: Send ONE notification, not one per product row.
                        int firstOrderId = groupOrders.get(0).getId();
                        NotificationDAO.sendDeliveryAssigned(deliveryBoyId, firstOrderId, customerName);
                        NotificationDAO.sendOrderStatusChanged(customerId, firstOrderId, "your order", "Assigned");
                    }
                }
            }
        } catch (Exception e) { e.printStackTrace(); }

        if ("ADMIN".equals(user.getRole())) {
            response.sendRedirect("admin-orders.jsp?msg=assigned");
        } else {
            response.sendRedirect("staff-orders.jsp?msg=assigned");
        }
    }
}