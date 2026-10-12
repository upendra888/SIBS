package com.sibs.servlet;

import com.sibs.dao.OrderDAO;
import com.sibs.model.Order;
import com.sibs.model.User;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.util.*;

@WebServlet("/GetCustomerOrders")
public class GetCustomerOrdersServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        User user = null;
        if (req.getSession(false) != null) {
            // Try both keys — staff/admin use "user", customers use "customer"
            user = (User) req.getSession(false).getAttribute("user");
            if (user == null)
                user = (User) req.getSession(false).getAttribute("customer");
        }
        if (user == null) { resp.sendError(401); return; }

        int userId;
        String customerIdParam = req.getParameter("customerId");
        if (customerIdParam != null && (user.getRole().equalsIgnoreCase("staff")
                || user.getRole().equalsIgnoreCase("admin"))) {
            userId = Integer.parseInt(customerIdParam);
        } else {
            userId = user.getId();
        }

        // getGroupedOrdersByUser returns one Order per group, items inside getItems()
        List<Order> groups = new OrderDAO().getGroupedOrdersByUser(userId);

        StringBuilder sb = new StringBuilder("[");
        boolean first = true;
        for (Order g : groups) {
            if (!first) sb.append(",");
            first = false;

            // Collect product names from items list
            List<String> prodNames = new ArrayList<>();
            if (g.getItems() != null) {
                for (Order item : g.getItems()) {
                    if (item.getProductName() != null && !item.getProductName().isEmpty()) {
                        prodNames.add(item.getProductName());
                    }
                }
            }
            // Fallback: use head order's product name
            if (prodNames.isEmpty() && g.getProductName() != null) {
                prodNames.add(g.getProductName());
            }
            String prodStr = prodNames.isEmpty() ? "Order #" + g.getGroupId() : String.join(", ", prodNames);

            sb.append("{")
              .append("\"groupId\":").append(g.getGroupId()).append(",")
              .append("\"status\":\"").append(esc(g.getStatus())).append("\",")
              .append("\"total\":").append(g.getTotal()).append(",")
              .append("\"orderDate\":\"").append(esc(String.valueOf(g.getOrderDate()))).append("\",")
              .append("\"paymentMethod\":\"").append(esc(String.valueOf(g.getPaymentMethod()))).append("\",")
              .append("\"products\":\"").append(esc(prodStr)).append("\"")
              .append("}");
        }
        sb.append("]");

        resp.setContentType("application/json");
        resp.setCharacterEncoding("UTF-8");
        resp.getWriter().write(sb.toString());
    }

    private String esc(String s) {
        if (s == null || s.equals("null")) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"");
    }
}