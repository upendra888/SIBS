package com.sibs.servlet;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import com.sibs.util.DBConnection;

@WebServlet("/updateCart")
public class UpdateCartServlet extends HttpServlet {

    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        int cartId = Integer.parseInt(req.getParameter("cartId"));
        String action = req.getParameter("action");

        try {
            Connection con = DBConnection.getConnection();

            if(action.equals("increase")){
                PreparedStatement ps = con.prepareStatement(
                    "UPDATE cart SET quantity = quantity + 1 WHERE id=?"
                );
                ps.setInt(1, cartId);
                ps.executeUpdate();

            } else {

                PreparedStatement ps = con.prepareStatement(
                    "UPDATE cart SET quantity = quantity - 1 WHERE id=? AND quantity > 1"
                );
                ps.setInt(1, cartId);
                ps.executeUpdate();
            }

        } catch(Exception e){
            e.printStackTrace();
        }

        res.sendRedirect("cart.jsp");
    }
}