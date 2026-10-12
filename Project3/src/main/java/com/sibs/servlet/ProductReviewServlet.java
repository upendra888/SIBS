package com.sibs.servlet;

import com.sibs.dao.ProductReviewDAO;
import com.sibs.dao.NotificationDAO;
import com.sibs.dao.ProductDAO;
import com.sibs.model.Product;
import com.sibs.model.User;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.util.List;

/**
 * ProductReviewServlet
 *
 * POST /productReview
 *      Params: productId, orderId, rating (1-5), reviewText
 *      → JSON { "success": true|false, "message": "..." }
 *
 * GET /productReview?productId=5
 *      → JSON { "avg": 4.2, "count": 8, "reviews": [...] }
 */
@WebServlet("/productReview")
public class ProductReviewServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res) throws IOException {
        res.setContentType("application/json");
        res.setCharacterEncoding("UTF-8");

        HttpSession session = req.getSession(false);
        User user = session != null ? (User) session.getAttribute("customer") : null;
        if (user == null) {
            res.setStatus(401);
            res.getWriter().write("{\"success\":false,\"message\":\"Please login to review\"}");
            return;
        }

        String pidStr   = req.getParameter("productId");
        String oidStr   = req.getParameter("orderId");
        String rStr     = req.getParameter("rating");
        String text     = req.getParameter("reviewText");

        if (pidStr == null || oidStr == null || rStr == null) {
            res.setStatus(400);
            res.getWriter().write("{\"success\":false,\"message\":\"Missing fields\"}");
            return;
        }

        int productId, orderId, rating;
        try {
            productId = Integer.parseInt(pidStr.trim());
            orderId   = Integer.parseInt(oidStr.trim());
            rating    = Integer.parseInt(rStr.trim());
        } catch (NumberFormatException e) {
            res.setStatus(400);
            res.getWriter().write("{\"success\":false,\"message\":\"Invalid numeric fields\"}");
            return;
        }

        if (rating < 1 || rating > 5) {
            res.setStatus(400);
            res.getWriter().write("{\"success\":false,\"message\":\"Rating must be 1-5\"}");
            return;
        }

        ProductReviewDAO dao = new ProductReviewDAO();
        ProductDAO pDao = new ProductDAO();
        Product product = pDao.getProductById(productId);
        String productName = product != null ? product.getName() : "the product";

        // Check if already reviewed — offer update
        boolean alreadyReviewed = dao.hasReviewed(productId, user.getId(), orderId);

        boolean ok;
        if (alreadyReviewed) {
            ok = dao.updateReview(productId, user.getId(), orderId, rating, text);
            if (ok) NotificationDAO.sendReviewSubmitted(user.getId(), productName, rating, true);
            res.getWriter().write("{\"success\":" + ok + ",\"message\":\"" +
                (ok ? "Review updated!" : "Could not update review") + "\"}");
        } else {
            ok = dao.submitReview(productId, user.getId(), orderId, rating, text);
            if (ok) NotificationDAO.sendReviewSubmitted(user.getId(), productName, rating, false);
            res.getWriter().write("{\"success\":" + ok + ",\"message\":\"" +
                (ok ? "Thank you for your review!" : "Could not submit review") + "\"}");
        }
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res) throws IOException {
        res.setContentType("application/json");
        res.setCharacterEncoding("UTF-8");

        String pidStr = req.getParameter("productId");
        if (pidStr == null) {
            res.setStatus(400);
            res.getWriter().write("{\"error\":\"productId required\"}");
            return;
        }

        int productId;
        try {
            productId = Integer.parseInt(pidStr.trim());
        } catch (NumberFormatException e) {
            res.setStatus(400);
            res.getWriter().write("{\"error\":\"Invalid productId\"}");
            return;
        }

        ProductReviewDAO dao = new ProductReviewDAO();
        double[] rating = dao.getProductRating(productId);
        List<String[]> reviews = dao.getProductReviews(productId);

        StringBuilder sb = new StringBuilder();
        sb.append("{");
        sb.append("\"avg\":").append(String.format("%.1f", rating[0])).append(",");
        sb.append("\"count\":").append((int) rating[1]).append(",");
        sb.append("\"reviews\":[");
        for (int i = 0; i < reviews.size(); i++) {
            String[] r = reviews.get(i);
            if (i > 0) sb.append(",");
            sb.append("{");
            sb.append("\"name\":\"").append(escape(r[0])).append("\",");
            sb.append("\"rating\":").append(r[1]).append(",");
            sb.append("\"text\":\"").append(escape(r[2])).append("\",");
            sb.append("\"date\":\"").append(escape(r[3])).append("\"");
            sb.append("}");
        }
        sb.append("]}");
        res.getWriter().write(sb.toString());
    }

    private String escape(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "");
    }
}