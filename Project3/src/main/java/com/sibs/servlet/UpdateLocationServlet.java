package com.sibs.servlet;

import com.sibs.model.DeliveryBoy;
import com.sibs.util.DBConnection;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.sql.*;

@WebServlet("/updateLocation")
public class UpdateLocationServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        res.setContentType("application/json");
        res.setCharacterEncoding("UTF-8");

        HttpSession session = req.getSession(false);
        DeliveryBoy db = session != null
                ? (DeliveryBoy) session.getAttribute("deliveryBoy") : null;

        if (db == null) {
            res.getWriter().write("{\"error\":\"unauthorized\"}");
            return;
        }

        String latStr   = req.getParameter("lat");
        String lngStr   = req.getParameter("lng");
        String orderStr = req.getParameter("orderId");

        if (latStr == null || lngStr == null || orderStr == null) {
            res.getWriter().write("{\"error\":\"missing_params\"}");
            return;
        }

        try {
            double lat     = Double.parseDouble(latStr);
            double lng     = Double.parseDouble(lngStr);
            int    orderId = Integer.parseInt(orderStr);

            String sql =
                "INSERT INTO delivery_location (delivery_boy_id, order_id, latitude, longitude) " +
                "VALUES (?, ?, ?, ?) " +
                "ON DUPLICATE KEY UPDATE " +
                "  latitude   = VALUES(latitude), " +
                "  longitude  = VALUES(longitude), " +
                "  updated_at = NOW()";

            try (Connection con = DBConnection.getConnection();
                 PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setInt(1, db.getId());
                ps.setInt(2, orderId);
                ps.setDouble(3, lat);
                ps.setDouble(4, lng);
                ps.executeUpdate();
            }

            res.getWriter().write("{\"ok\":true}");

        } catch (NumberFormatException e) {
            res.getWriter().write("{\"error\":\"invalid_params\"}");
        } catch (Exception e) {
            e.printStackTrace();
            res.getWriter().write("{\"error\":\"db_error\"}");
        }
    }
}