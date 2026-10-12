package com.sibs.servlet;

import com.sibs.util.DBConnection;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.sql.*;

@WebServlet("/setDefaultAddress")
public class SetDefaultAddressServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        int id = Integer.parseInt(req.getParameter("id"));
        String redirect = req.getParameter("redirect");
        if (redirect == null || redirect.isEmpty()) redirect = "cartCheckout.jsp";

        HttpSession session = req.getSession();
        com.sibs.model.User user = (com.sibs.model.User) session.getAttribute("customer");
        if (user == null) { res.sendRedirect("customer-login.jsp"); return; }

        Connection con = null;
        try {
            con = DBConnection.getConnection();

            // Clear all defaults for this user
            PreparedStatement ps0 = con.prepareStatement(
                "UPDATE user_addresses SET is_default=0 WHERE user_id=?"
            );
            ps0.setInt(1, user.getId());
            ps0.executeUpdate();
            ps0.close();

            // Set the chosen address as default
            PreparedStatement ps1 = con.prepareStatement(
                "UPDATE user_addresses SET is_default=1 WHERE id=? AND user_id=?"
            );
            ps1.setInt(1, id);
            ps1.setInt(2, user.getId());
            ps1.executeUpdate();
            ps1.close();

        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            if (con != null) try { con.close(); } catch (Exception ignored) {}
        }

        res.sendRedirect(redirect);
    }
}