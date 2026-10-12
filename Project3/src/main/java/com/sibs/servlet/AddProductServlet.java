package com.sibs.servlet;

import java.io.File;
import java.io.IOException;

import com.sibs.dao.ProductDAO;
import com.sibs.dao.NotificationDAO;
import com.sibs.model.Product;
import com.sibs.model.User;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

@WebServlet("/addProduct")
@MultipartConfig
public class AddProductServlet extends HttpServlet {

    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        try {

            // 1. SESSION CHECK
            User user = (User) request.getSession().getAttribute("user");

            if (user == null || !"ADMIN".equals(user.getRole())) {
                response.sendRedirect("login.jsp");
                return;
            }

            // 2. GET DATA
            String name     = request.getParameter("name");
            double price    = Double.parseDouble(request.getParameter("price"));
            int quantity    = Integer.parseInt(request.getParameter("quantity"));
            String category = request.getParameter("category");
            double weight   = Double.parseDouble(request.getParameter("weight"));
            String unit     = request.getParameter("unit");
            String description = request.getParameter("description");
            int stockStatus = 1;
            try { stockStatus = Integer.parseInt(request.getParameter("stockStatus")); } catch (Exception ignored) {}

            // 3. IMAGE FILE
            Part filePart = request.getPart("image");
            String fileName = filePart.getSubmittedFileName();

            String imagePath = "images/default.png"; // default

            if (fileName != null && !fileName.isEmpty()) {

                String uploadPath = getServletContext().getRealPath("") + "images";
                File uploadDir = new File(uploadPath);

                if (!uploadDir.exists()) {
                    uploadDir.mkdir();
                }

                String filePath = uploadPath + File.separator + fileName;
                filePart.write(filePath);

                imagePath = "images/" + fileName;
            }

            // 4. DAO
            ProductDAO dao = new ProductDAO();

            // 5. CHECK DUPLICATE
            if (dao.isProductExists(name)) {
                response.sendRedirect("add-product.jsp?error=duplicate");
                return;
            }

            // 6. SAVE PRODUCT
            Product p = new Product();
            p.setName(name);
            p.setPrice(price);
            p.setQuantity(quantity);
            p.setCategory(category);
            p.setWeight(weight);
            p.setUnit(unit);
            p.setImagePath(imagePath);
            p.setDescription(description);
            p.setStockStatus(stockStatus);

            boolean status = dao.addProduct(p);

            // 7. RESPONSE
            if (status) {
                // ── Notify staff: new product added ──────────────────
                NotificationDAO.sendProductAdded(name);
                // ─────────────────────────────────────────────────────
                response.sendRedirect("products.jsp?success=1");
            } else {
                response.sendRedirect("add-product.jsp?error=1");
            }

        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("add-product.jsp?error=server");
        }
    }
}