package com.sibs.servlet;

import com.sibs.dao.WishlistDAO;
import com.sibs.model.User;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;

/**
 * WishlistServlet
 *
 * POST /wishlist?action=toggle&productId=5
 *      → JSON { "status":"ADDED"|"REMOVED", "wishlisted":true|false }
 *
 * GET  /wishlist?action=count
 *      → JSON { "count": N }
 */
@WebServlet("/wishlist")
public class WishlistServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res) throws IOException {
        res.setContentType("application/json");
        res.setCharacterEncoding("UTF-8");

        HttpSession session = req.getSession(false);
        User user = session != null ? (User) session.getAttribute("customer") : null;
        if (user == null) {
            res.setStatus(401);
            res.getWriter().write("{\"error\":\"Not logged in\"}");
            return;
        }

        String action = req.getParameter("action");
        WishlistDAO dao = new WishlistDAO();

        if ("count".equals(action)) {
            int count = dao.count(user.getId());
            res.getWriter().write("{\"count\":" + count + "}");
        } else if ("check".equals(action)) {
            int productId = Integer.parseInt(req.getParameter("productId"));
            boolean wishlisted = dao.isWishlisted(user.getId(), productId);
            res.getWriter().write("{\"wishlisted\":" + wishlisted + "}");
        } else {
            res.setStatus(400);
            res.getWriter().write("{\"error\":\"Unknown action\"}");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res) throws IOException {
        res.setContentType("application/json");
        res.setCharacterEncoding("UTF-8");

        HttpSession session = req.getSession(false);
        User user = session != null ? (User) session.getAttribute("customer") : null;
        if (user == null) {
            res.setStatus(401);
            res.getWriter().write("{\"error\":\"Not logged in\"}");
            return;
        }

        String action = req.getParameter("action");
        String pidStr = req.getParameter("productId");

        if (pidStr == null || pidStr.isBlank()) {
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

        WishlistDAO dao = new WishlistDAO();

        if ("toggle".equals(action)) {
            String status = dao.toggle(user.getId(), productId);
            boolean wishlisted = "ADDED".equals(status);
            res.getWriter().write(
                "{\"status\":\"" + status + "\",\"wishlisted\":" + wishlisted + "}"
            );
        } else if ("add".equals(action)) {
            boolean added = dao.add(user.getId(), productId);
            res.getWriter().write("{\"wishlisted\":true,\"added\":" + added + "}");
        } else if ("remove".equals(action)) {
            boolean removed = dao.remove(user.getId(), productId);
            res.getWriter().write("{\"wishlisted\":false,\"removed\":" + removed + "}");
        } else {
            res.setStatus(400);
            res.getWriter().write("{\"error\":\"Unknown action\"}");
        }
    }
}