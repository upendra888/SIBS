package com.sibs.servlet;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import com.sibs.util.DBConnection;

@WebServlet("/removeCart")
public class RemoveCartServlet extends HttpServlet {

    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        int cartId = Integer.parseInt(req.getParameter("cartId"));

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement("DELETE FROM cart WHERE id=?")) {
            ps.setInt(1, cartId);
            ps.executeUpdate();
        } catch(Exception e){
            e.printStackTrace();
        }

        // Always redirect back to cart
        res.sendRedirect("cart.jsp");
    }
}