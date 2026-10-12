package com.sibs.servlet;

import com.sibs.util.DBConnection;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.sql.*;

@WebServlet("/deleteAddress")
public class DeleteAddressServlet extends HttpServlet {

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
            PreparedStatement ps = con.prepareStatement(
                "DELETE FROM addresses WHERE id=? AND user_id=?"
            );
            ps.setInt(1, id);
            ps.setInt(2, user.getId());
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