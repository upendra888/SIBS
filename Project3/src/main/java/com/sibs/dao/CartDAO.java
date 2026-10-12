package com.sibs.dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;

import com.sibs.model.Product;
import com.sibs.util.DBConnection;

public class CartDAO {

    /* ================= ADD TO CART ================= */
    public void addToCart(int userId, int productId, int qty, double price, String img) {

        String checkSql  = "SELECT id FROM cart WHERE user_id=? AND product_id=?";
        String updateSql = "UPDATE cart SET quantity = quantity + ? WHERE user_id=? AND product_id=?";
        String insertSql = "INSERT INTO cart(user_id,product_id,quantity,price,image_path) VALUES(?,?,?,?,?)";

        try (Connection con = DBConnection.getConnection()) {

            // Check if item already in cart
            try (PreparedStatement check = con.prepareStatement(checkSql)) {
                check.setInt(1, userId);
                check.setInt(2, productId);

                try (ResultSet rs = check.executeQuery()) {
                    if (rs.next()) {
                        // Already exists — increase quantity
                        try (PreparedStatement update = con.prepareStatement(updateSql)) {
                            update.setInt(1, qty);
                            update.setInt(2, userId);
                            update.setInt(3, productId);
                            update.executeUpdate();
                        }
                    } else {
                        // New item — insert
                        try (PreparedStatement insert = con.prepareStatement(insertSql)) {
                            insert.setInt(1, userId);
                            insert.setInt(2, productId);
                            insert.setInt(3, qty);
                            insert.setDouble(4, price);
                            insert.setString(5, img);
                            insert.executeUpdate();
                        }
                    }
                }
            }

        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    /* ================= GET CART ITEMS ================= */
    public List<Product> getCartByUser(int userId) {

        List<Product> list = new ArrayList<>();
        String sql = "SELECT c.product_id, c.quantity, c.price, p.name " +
                     "FROM cart c JOIN products p ON c.product_id = p.id " +
                     "WHERE c.user_id=?";

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setInt(1, userId);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Product p = new Product();
                    p.setId(rs.getInt("product_id"));
                    p.setQuantity(rs.getInt("quantity"));
                    p.setPrice(rs.getDouble("price"));
                    p.setName(rs.getString("name"));
                    list.add(p);
                }
            }

        } catch (Exception e) {
            e.printStackTrace();
        }

        return list;
    }

    /* ================= CLEAR CART ================= */
    public void clearCart(int userId) {

        String sql = "DELETE FROM cart WHERE user_id=?";

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setInt(1, userId);
            ps.executeUpdate();

        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    /* ================= CLEAR SELECTED ITEMS ONLY ================= */
    public void clearSelectedItems(int userId, String[] productIds) {
        if (productIds == null || productIds.length == 0) return;
        String sql = "DELETE FROM cart WHERE user_id=? AND product_id=?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            for (String pid : productIds) {
                try {
                    ps.setInt(1, userId);
                    ps.setInt(2, Integer.parseInt(pid.trim()));
                    ps.executeUpdate();
                } catch (Exception ex) { ex.printStackTrace(); }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}