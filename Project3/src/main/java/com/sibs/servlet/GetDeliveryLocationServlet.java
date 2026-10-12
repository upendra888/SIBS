package com.sibs.servlet;

import com.sibs.model.User;
import com.sibs.util.DBConnection;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.sql.*;

@WebServlet("/getDeliveryLocation")
public class GetDeliveryLocationServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        res.setContentType("application/json");
        res.setCharacterEncoding("UTF-8");

        // Allow both customer and delivery boy sessions
        HttpSession session = req.getSession(false);
        boolean allowed = session != null &&
                (session.getAttribute("customer") != null ||
                 session.getAttribute("deliveryBoy") != null ||
                 session.getAttribute("admin") != null);

        if (!allowed) {
            res.getWriter().write("{\"error\":\"unauthorized\"}");
            return;
        }

        String orderStr = req.getParameter("orderId");
        if (orderStr == null) {
            res.getWriter().write("{\"error\":\"missing_orderId\"}");
            return;
        }

        String sql =
            "SELECT dl.latitude, dl.longitude, dl.updated_at, " +
            "       db.name AS delivery_name, db.phone AS delivery_phone " +
            "FROM   delivery_location dl " +
            "JOIN   delivery_boys     db ON dl.delivery_boy_id = db.id " +
            "WHERE  dl.order_id = ? " +
            "ORDER  BY dl.updated_at DESC LIMIT 1";

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, Integer.parseInt(orderStr));
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    String json = String.format(
                        "{\"lat\":%.8f,\"lng\":%.8f,\"name\":\"%s\",\"phone\":\"%s\",\"updatedAt\":\"%s\"}",
                        rs.getDouble("latitude"),
                        rs.getDouble("longitude"),
                        rs.getString("delivery_name").replace("\"", "\\\""),
                        rs.getString("delivery_phone"),
                        rs.getString("updated_at")
                    );
                    res.getWriter().write(json);
                } else {
                    res.getWriter().write("{\"error\":\"not_found\"}");
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
            res.getWriter().write("{\"error\":\"db_error\"}");
        }
    }
}