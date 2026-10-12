package com.sibs.servlet;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.util.*;

import com.sibs.dao.BillDAO;
import com.sibs.dao.ProductDAO;
import com.sibs.model.BillItem;
import com.sibs.model.Product;
import com.sibs.model.User;

@WebServlet("/generateBill")
public class BillingServlet extends HttpServlet {

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        try {

            // ✅ FIXED: Billing is done by STAFF or ADMIN who have a "user" session,
            //           NOT a "customer" session. The old code used getAttribute("customer")
            //           which always returned null for staff, causing NullPointerException
            //           and a blank/error page instead of the invoice.
            HttpSession session = request.getSession();
            User user = (User) session.getAttribute("user");

            if (user == null) {
                response.getWriter().println("Not logged in. Please login as Staff or Admin.");
                return;
            }

            String role = user.getRole();
            if (!"STAFF".equals(role) && !"ADMIN".equals(role)) {
                response.getWriter().println("Access denied. Only Staff and Admin can generate bills.");
                return;
            }

            // Use the staff/admin user's ID as the "customer" for the bill record
            int customerId = user.getId();

            // GET CART DATA
            String[] productNames = request.getParameterValues("productName");
            String[] quantities   = request.getParameterValues("quantity");

            if (productNames == null || quantities == null) {
                response.getWriter().println("Cart is empty!");
                return;
            }

            ProductDAO productDAO = new ProductDAO();
            List<BillItem> items = new ArrayList<>();

            double subtotal = 0;

            // LOOP PRODUCTS
            for (int i = 0; i < productNames.length; i++) {

                String name = productNames[i];

                int qty = 0;
                try {
                    qty = Integer.parseInt(quantities[i]);
                } catch (Exception e) {
                    response.getWriter().println("Invalid quantity for " + name);
                    return;
                }

                Product product = productDAO.getProductByName(name);

                if (product == null) {
                    response.getWriter().println("Product not found: " + name);
                    return;
                }

                if (product.getQuantity() < qty) {
                    response.getWriter().println("Error: Insufficient stock for " + name
                        + " (available: " + product.getQuantity() + ")");
                    return;
                }

                // CREATE BILL ITEM
                BillItem item = new BillItem();
                item.setProductId(product.getId());
                item.setProductName(product.getName());
                item.setQuantity(qty);
                item.setPrice(product.getPrice());
                item.setTotalPrice(product.getPrice() * qty);

                subtotal += item.getTotalPrice();
                items.add(item);

                // UPDATE STOCK
                int newStock = product.getQuantity() - qty;
                productDAO.updateStock(product.getId(), newStock);
            }

            // CALCULATIONS
            double discount = subtotal * 0.10;
            double tax      = (subtotal - discount) * 0.18;
            double total    = subtotal - discount + tax;

            // SAVE BILL
            BillDAO billDAO = new BillDAO();
            int billId = billDAO.saveBill(customerId, subtotal, discount, tax, total, items);

            // SEND TO JSP
            request.setAttribute("billId",   billId);
            request.setAttribute("items",    items);
            request.setAttribute("subtotal", subtotal);
            request.setAttribute("discount", discount);
            request.setAttribute("tax",      tax);
            request.setAttribute("total",    total);

            request.getRequestDispatcher("invoice.jsp").forward(request, response);

        } catch (Exception e) {
            e.printStackTrace();
            response.getWriter().println("ERROR: " + e.getMessage());
        }
    }
}