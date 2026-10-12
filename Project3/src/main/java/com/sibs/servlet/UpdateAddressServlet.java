package com.sibs.servlet;

import com.sibs.util.DBConnection;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.sql.*;

@WebServlet("/updateAddress")
public class UpdateAddressServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        int id          = Integer.parseInt(req.getParameter("id"));
        String name     = req.getParameter("name");
        String phone    = req.getParameter("phone");
        String address  = req.getParameter("address");
        boolean isDef   = "true".equals(req.getParameter("isDefault"));
        String redirect = req.getParameter("redirect");
        if (redirect == null || redirect.isEmpty()) redirect = "cartCheckout.jsp";

        HttpSession session = req.getSession();
        com.sibs.model.User user = (com.sibs.model.User) session.getAttribute("customer");
        if (user == null) { res.sendRedirect("customer-login.jsp"); return; }

        Connection con = null;
        try {
            con = DBConnection.getConnection();

            // If setting as default, clear existing default first
            if (isDef) {
                PreparedStatement ps0 = con.prepareStatement(
                    "UPDATE user_addresses SET is_default=0 WHERE user_id=?"
                );
                ps0.setInt(1, user.getId());
                ps0.executeUpdate();
                ps0.close();
            }

            PreparedStatement ps = con.prepareStatement(
                "UPDATE user_addresses SET name=?,phone=?,address=?,is_default=? WHERE id=? AND user_id=?"
            );
            ps.setString(1, name);
            ps.setString(2, phone);
            ps.setString(3, address);
            ps.setBoolean(4, isDef);
            ps.setInt(5, id);
            ps.setInt(6, user.getId());
            ps.executeUpdate();
            ps.close();

        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            if (con != null) try { con.close(); } catch (Exception ignored) {}
        }

        res.sendRedirect(redirect);
    }
}