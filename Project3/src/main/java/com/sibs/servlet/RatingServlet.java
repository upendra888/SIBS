package com.sibs.servlet;

import com.sibs.dao.DeliveryRatingDAO;
import com.sibs.dao.NotificationDAO;
import com.sibs.model.User;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;

/**
 * POST /submitRating
 * Params: orderId, stars, comment
 * Called from customer-rate-rider.jsp after a delivered order.
 */
@WebServlet("/submitRating")
public class RatingServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        User user = session != null ? (User) session.getAttribute("customer") : null;

        if (user == null) {
            res.sendRedirect("customer-login.jsp");
            return;
        }

        String orderIdStr = req.getParameter("orderId");
        String starsStr   = req.getParameter("stars");
        String comment    = req.getParameter("comment");

        if (orderIdStr == null || starsStr == null) {
            res.sendRedirect("customer-dashboard.jsp?ratingErr=1");
            return;
        }

        try {
            int orderId = Integer.parseInt(orderIdStr.trim());
            int stars   = Integer.parseInt(starsStr.trim());

            if (stars < 1 || stars > 5) {
                res.sendRedirect("customer-rate-rider.jsp?orderId=" + orderId + "&err=invalid_stars");
                return;
            }

            DeliveryRatingDAO dao = new DeliveryRatingDAO();
            int deliveryBoyId = dao.getDeliveryBoyIdForOrder(orderId);

            if (deliveryBoyId == -1) {
                res.sendRedirect("my-orders.jsp?ratingErr=no_rider");
                return;
            }

            boolean ok = dao.submitRating(orderId, deliveryBoyId, user.getId(), stars, comment);
            if (ok) {
                // Notify delivery boy: new rating received
                NotificationDAO.sendNewRatingReceived(deliveryBoyId, orderId, stars,
                    user.getName() != null ? user.getName() : "A customer");

                // Check average rating and alert if dropped below 3.0
                double avg = dao.getAverageRating(deliveryBoyId);
                if (avg > 0 && avg < 3.0) {
                    NotificationDAO.sendRatingDropAlert(deliveryBoyId, avg);
                }

                // Notify customer: thank you for rating
                NotificationDAO.sendRatingThankYou(user.getId(), orderId, stars);

                res.sendRedirect("my-orders.jsp?rated=1");
            } else {
                res.sendRedirect("my-orders.jsp?rated=dup");
            }

        } catch (NumberFormatException e) {
            res.sendRedirect("customer-dashboard.jsp?ratingErr=1");
        }
    }
}