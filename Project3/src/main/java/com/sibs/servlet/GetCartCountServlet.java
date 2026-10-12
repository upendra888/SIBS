package com.sibs.servlet;

import java.io.IOException;
import java.sql.*;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import com.sibs.model.User;
import com.sibs.util.DBConnection;

@WebServlet("/getCartCount")
public class GetCartCountServlet extends HttpServlet {

    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        int count = 0;

        try {
            User user = (User) request.getSession().getAttribute("customer");

            if(user != null){
                Connection con = DBConnection.getConnection();

                PreparedStatement ps = con.prepareStatement(
                    "SELECT SUM(quantity) FROM cart WHERE user_id=?"
                );
                ps.setInt(1, user.getId());

                ResultSet rs = ps.executeQuery();

                if(rs.next()){
                    count = rs.getInt(1);
                }
            }

        } catch (Exception e) {
            e.printStackTrace();
        }

        response.getWriter().print(count);
    }
}