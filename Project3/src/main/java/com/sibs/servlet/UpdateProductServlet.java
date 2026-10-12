package com.sibs.servlet;

import java.io.File;
import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import com.sibs.dao.ProductDAO;
import com.sibs.dao.NotificationDAO;
import com.sibs.model.Product;
import com.sibs.model.User;

@WebServlet("/updateProduct")
@MultipartConfig
public class UpdateProductServlet extends HttpServlet {

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        try {

            // 1. SESSION CHECK
            User user = (User) request.getSession().getAttribute("user");

            if (user == null || !"ADMIN".equals(user.getRole())) {
                response.sendRedirect("login.jsp");
                return;
            }

            // 2. GET DATA
            int id          = Integer.parseInt(request.getParameter("id"));
            String name     = request.getParameter("name");
            double price    = Double.parseDouble(request.getParameter("price"));
            int quantity    = Integer.parseInt(request.getParameter("quantity"));
            String category = request.getParameter("category");
            double weight   = Double.parseDouble(request.getParameter("weight"));
            String unit     = request.getParameter("unit");    // ✅ FIXED: was missing
            String oldImage = request.getParameter("oldImage");

            // 3. IMAGE FILE
            Part filePart = request.getPart("image");
            String fileName = filePart.getSubmittedFileName();
            String imagePath = oldImage;

            if (fileName != null && !fileName.isEmpty()) {

                String uploadPath = getServletContext().getRealPath("") + "images";
                File uploadDir = new File(uploadPath);

                if (!uploadDir.exists()) {
                    uploadDir.mkdir();
                }

                filePart.write(uploadPath + File.separator + fileName);
                imagePath = "images/" + fileName;
            }

            // 4. BUILD PRODUCT
            Product p = new Product();
            p.setId(id);
            p.setName(name);
            p.setPrice(price);
            p.setQuantity(quantity);
            p.setCategory(category);
            p.setWeight(weight);
            p.setUnit(unit);           // ✅ FIXED: was missing
            p.setImagePath(imagePath);

            // 5. UPDATE
            ProductDAO dao = new ProductDAO();
            dao.updateProduct(p);

            // ── Notify staff: product updated ─────────────────────────
            NotificationDAO.sendProductUpdated(name);
            // Low stock alert if quantity dropped below 5
            if (quantity < 5) {
                NotificationDAO.sendLowStockAlert(name, quantity);
            }
            // ─────────────────────────────────────────────────────────

            response.sendRedirect("products.jsp");

        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("products.jsp?error=server");
        }
    }
}