package com.sibs.servlet;

import com.sibs.model.User;
import com.sibs.util.DBConnection;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.*;

/**
 * GET /getDeliveryLocations
 * Returns JSON array of all riders with their latest GPS location.
 * Admin only.
 */
@WebServlet("/getDeliveryLocations")
public class GetDeliveryLocationsServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        res.setContentType("application/json");
        res.setCharacterEncoding("UTF-8");

        HttpSession session = req.getSession(false);
        User user = session != null ? (User) session.getAttribute("user") : null;

        if (user == null || (!"ADMIN".equals(user.getRole()) && !"STAFF".equals(user.getRole()))) {
            res.setStatus(401);
            res.getWriter().write("{\"error\":\"unauthorized\"}");
            return;
        }

        StringBuilder json = new StringBuilder("{\"riders\":[");
        boolean first = true;

        String sql =
            "SELECT db.id, db.name, db.phone, " +
            "       COALESCE(db.shift_status, CASE WHEN db.is_online THEN 'ONLINE' ELSE 'OFFLINE' END) AS shift_status, " +
            "       dl.latitude, dl.longitude, dl.order_id, dl.updated_at " +
            "FROM delivery_boys db " +
            "LEFT JOIN delivery_location dl ON dl.delivery_boy_id = db.id " +
            "   AND dl.updated_at = (SELECT MAX(dl2.updated_at) FROM delivery_location dl2 WHERE dl2.delivery_boy_id = db.id) " +
            "WHERE db.status = 'ACTIVE' " +
            "ORDER BY db.is_online DESC, db.name";

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                if (!first) json.append(",");
                first = false;
                double lat = rs.getDouble("latitude");
                double lng = rs.getDouble("longitude");
                boolean hasLoc = !rs.wasNull() && lat != 0;
                String updatedAt = rs.getString("updated_at");

                json.append("{")
                    .append("\"id\":").append(rs.getInt("id")).append(",")
                    .append("\"name\":\"").append(escape(rs.getString("name"))).append("\",")
                    .append("\"phone\":\"").append(escape(rs.getString("phone"))).append("\",")
                    .append("\"shiftStatus\":\"").append(escape(rs.getString("shift_status"))).append("\",")
                    .append("\"lat\":").append(hasLoc ? lat : "null").append(",")
                    .append("\"lng\":").append(hasLoc ? lng : "null").append(",")
                    .append("\"orderId\":").append(rs.getInt("order_id")).append(",")
                    .append("\"updatedAt\":\"").append(updatedAt != null ? escape(updatedAt) : "").append("\"")
                    .append("}");
            }

        } catch (Exception e) {
            e.printStackTrace();
            res.getWriter().write("{\"error\":\"db_error\"}");
            return;
        }

        json.append("]}");
        res.getWriter().write(json.toString());
    }

    private String escape(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"")
                .replace("\n", "\\n").replace("\r", "\\r");
    }
}