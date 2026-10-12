package com.sibs.servlet;

import java.io.IOException;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import com.sibs.dao.CartDAO;
import com.sibs.dao.ProductDAO;
import com.sibs.model.Product;
import com.sibs.model.User;

@WebServlet("/addToCart")
public class AddToCartServlet extends HttpServlet {

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // ── 1. AUTH CHECK ─────────────────────────────────────────────
        User user = (User) request.getSession().getAttribute("customer");

        if (user == null) {
            response.sendRedirect("customer-login.jsp");
            return;
        }

        // ── 2. GET PARAMS ─────────────────────────────────────────────
        int    userId    = user.getId();
        int    productId = Integer.parseInt(request.getParameter("productId"));
        int    qty       = Integer.parseInt(request.getParameter("qty"));
        double price     = Double.parseDouble(request.getParameter("price"));
        String img       = request.getParameter("img");

        // ── 3. STOCK CHECK ────────────────────────────────────────────
        ProductDAO productDAO = new ProductDAO();
        Product product = productDAO.getProductById(productId);

        if (product == null) {
            response.getWriter().print("error:Product not found");
            return;
        }

        if (product.getQuantity() <= 0) {
            response.getWriter().print("error:Out of stock");
            return;
        }

        if (qty > product.getQuantity()) {
            response.getWriter().print("error:Only " + product.getQuantity() + " units available");
            return;
        }

        // ── 4. ADD TO CART ────────────────────────────────────────────
        CartDAO dao = new CartDAO();
        dao.addToCart(userId, productId, qty, price, img);

        response.getWriter().print("success");
    }
}