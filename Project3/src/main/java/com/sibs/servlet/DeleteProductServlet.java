package com.sibs.servlet;

import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import com.sibs.dao.ProductDAO;
import com.sibs.dao.NotificationDAO;
import com.sibs.model.Product;
import com.sibs.model.User;

@WebServlet("/deleteProduct")
public class DeleteProductServlet extends HttpServlet {

    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // ✅ FIXED: Auth check was completely missing
        User user = (User) request.getSession().getAttribute("user");
        if (user == null || !"ADMIN".equals(user.getRole())) {
            response.sendRedirect("login.jsp");
            return;
        }

        int id = Integer.parseInt(request.getParameter("id"));

        ProductDAO dao = new ProductDAO();

        // Fetch product name BEFORE deleting (for notification message)
        Product product = dao.getProductById(id);
        String productName = (product != null) ? product.getName() : "Unknown Product";

        boolean status = dao.deleteProduct(id);

        if (status) {
            // ── Notify staff: product removed ─────────────────────────
            NotificationDAO.sendProductDeleted(productName);
            // ─────────────────────────────────────────────────────────
            response.sendRedirect("products.jsp?success=deleted");
        } else {
            response.sendRedirect("products.jsp?error=deletefailed");
        }
    }
}