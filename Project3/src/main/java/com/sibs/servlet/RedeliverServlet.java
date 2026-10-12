package com.sibs.servlet;

import com.sibs.dao.DeliveryBoyDAO;
import com.sibs.dao.NotificationDAO;
import com.sibs.dao.OrderDAO;
import com.sibs.model.Order;
import com.sibs.model.User;
import com.sibs.util.DBConnection;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.util.List;

public class RedeliverServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        User user = (session != null) ? (User) session.getAttribute("user") : null;

        if (user == null || (!"STAFF".equals(user.getRole()) && !"ADMIN".equals(user.getRole()))) {
            response.sendRedirect("login.jsp");
            return;
        }

        int groupId        = Integer.parseInt(request.getParameter("groupId"));
        int deliveryBoyId  = Integer.parseInt(request.getParameter("deliveryBoyId"));
        String newAddress  = request.getParameter("newAddress");
        String note        = request.getParameter("note");
        if (note == null) note = "";

        try (Connection con = DBConnection.getConnection()) {

            // 1. Update delivery address on all orders in the group
            PreparedStatement ps1 = con.prepareStatement(
                "UPDATE orders SET address=? WHERE group_id=?"
            );
            ps1.setString(1, newAddress);
            ps1.setInt(2, groupId);
            ps1.executeUpdate();
            ps1.close();

            // 2. Reset status to Assigned for re-delivery
            PreparedStatement ps2 = con.prepareStatement(
                "UPDATE orders SET status='Assigned' WHERE group_id=?"
            );
            ps2.setInt(1, groupId);
            ps2.executeUpdate();
            ps2.close();

            // 3. Reassign delivery boy
            OrderDAO orderDao = new OrderDAO();
            DeliveryBoyDAO dbDao = new DeliveryBoyDAO();
            List<Order> groupOrders = orderDao.getOrdersByGroupId(groupId);
            for (Order o : groupOrders) {
                dbDao.assignDeliveryBoy(o.getId(), deliveryBoyId, note);
            }

            // Notify delivery boy: re-delivery scheduled
            String customerName = groupOrders.isEmpty() ? "Customer" :
                (groupOrders.get(0).getName() != null ? groupOrders.get(0).getName() : "Customer");
            int firstOrderId = groupOrders.isEmpty() ? 0 : groupOrders.get(0).getId();
            NotificationDAO.sendRedeliveryScheduled(deliveryBoyId, firstOrderId, customerName);

        } catch (Exception e) {
            e.printStackTrace();
        }

        String redirect = "ADMIN".equals(user.getRole()) ? "admin-orders.jsp?msg=redelivered" : "staff-orders.jsp?msg=redelivered";
        response.sendRedirect(redirect);
    }
}