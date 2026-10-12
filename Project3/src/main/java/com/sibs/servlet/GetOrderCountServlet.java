package com.sibs.servlet;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import com.sibs.model.User;
import com.sibs.util.DBConnection;

/**
 * GetOrderCountServlet
 *
 * URL: GET /getOrderCount
 *
 * Returns the total number of orders as plain text (integer).
 * Used by staff-dashboard.jsp to populate the "Total Orders" stat card
 * via a real-time fetch() call.
 *
 * Fix for the broken 3rd stat card which was calling fetch('getOrderCount')
 * but had no matching servlet — causing a 404 whose raw HTML was rendered
 * inside the dashboard card.
 */
@WebServlet("/getOrderCount")
public class GetOrderCountServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        // ── Auth check ────────────────────────────────────────
        HttpSession session = request.getSession(false);
        User user = (session != null) ? (User) session.getAttribute("user") : null;

        if (user == null) {
            response.setStatus(401);
            response.getWriter().write("0");
            return;
        }

        response.setContentType("text/plain");
        response.setCharacterEncoding("UTF-8");

        int count = 0;
        Connection con = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            con = DBConnection.getConnection();
            ps  = con.prepareStatement("SELECT COUNT(*) FROM orders");
            rs  = ps.executeQuery();
            if (rs.next()) {
                count = rs.getInt(1);
            }
        } catch (Exception e) {
            e.printStackTrace();
            // Return 0 on DB error — dashboard still renders cleanly
        } finally {
            if (rs  != null) try { rs.close();  } catch (Exception e) {}
            if (ps  != null) try { ps.close();  } catch (Exception e) {}
            if (con != null) try { con.close(); } catch (Exception e) {}
        }

        response.getWriter().write(String.valueOf(count));
    }
}