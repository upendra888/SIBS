package com.sibs.servlet;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import com.sibs.dao.CartDAO;
import com.sibs.dao.NotificationDAO;
import com.sibs.model.User;
import com.sibs.util.DBConnection;

/**
 * ConfirmCODServlet - called from payment.jsp when user clicks COD confirm button.
 * The order was already placed by PlaceOrderServlet. This servlet just confirms it
 * and clears the cart, then redirects to order-success.jsp.
 */
@WebServlet("/confirmCOD")
public class ConfirmCODServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        User user = (session != null) ? (User) session.getAttribute("customer") : null;

        if (user == null) {
            response.sendRedirect("customer-login.jsp");
            return;
        }

        Object oidObj = session.getAttribute("pendingOrderId");
        if (oidObj == null) {
            // Check lastOrderId as fallback
            oidObj = session.getAttribute("lastOrderId");
        }

        if (oidObj != null) {
            int orderId = Integer.parseInt(oidObj.toString());
            Object gidObj = session.getAttribute("pendingGroupId");
            int groupId = gidObj != null ? Integer.parseInt(gidObj.toString()) : -1;

            try (Connection con = DBConnection.getConnection();
                 PreparedStatement ps = con.prepareStatement(
                     groupId > 0
                         ? "UPDATE orders SET status='Pending', payment_status='COD' WHERE group_id=?"
                         : "UPDATE orders SET status='Pending', payment_status='COD' WHERE id=?")) {
                ps.setInt(1, groupId > 0 ? groupId : orderId);
                ps.executeUpdate();
            } catch (Exception e) { e.printStackTrace(); }

            // Clear cart
            Boolean isBuyNow = (Boolean) session.getAttribute("isBuyNow");
            if (isBuyNow == null || !isBuyNow) {
                new CartDAO().clearCart(user.getId());
            }

            // ── Notifications ─────────────────────────────────────────
            String customerName = user.getName() != null ? user.getName() : "Customer";
            // Notify customer: order confirmed
            NotificationDAO.sendOrderPlaced(user.getId(), orderId, "your COD order");
            // Notify staff: new COD order needs attention
            NotificationDAO.sendNewCODOrderToStaff(orderId, customerName);
            // ─────────────────────────────────────────────────────────

            session.removeAttribute("pendingOrderId");
            session.removeAttribute("pendingAmount");
        }

        response.sendRedirect("order-success.jsp");
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        doPost(request, response);
    }
}