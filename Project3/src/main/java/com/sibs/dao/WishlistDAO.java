package com.sibs.dao;

import com.sibs.model.Product;
import com.sibs.util.DBConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * WishlistDAO — customer wishlist (saved products).
 * Table auto-created on first use (no migration script needed).
 */
public class WishlistDAO {

    private static final String CREATE_TABLE =
        "CREATE TABLE IF NOT EXISTS customer_wishlist (" +
        "  id           INT AUTO_INCREMENT PRIMARY KEY," +
        "  user_id      INT NOT NULL," +
        "  product_id   INT NOT NULL," +
        "  created_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP," +
        "  UNIQUE KEY uq_wish (user_id, product_id)" +
        ")";

    // ── ensure table exists ────────────────────────────────────────────────
    private void ensureTable(Connection con) throws SQLException {
        con.createStatement().execute(CREATE_TABLE);
    }

    /** Add product to wishlist. Returns true if added, false if already there. */
    public boolean add(int userId, int productId) {
        try (Connection con = DBConnection.getConnection()) {
            ensureTable(con);
            PreparedStatement ps = con.prepareStatement(
                "INSERT IGNORE INTO customer_wishlist (user_id, product_id) VALUES (?, ?)");
            ps.setInt(1, userId);
            ps.setInt(2, productId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    /** Remove product from wishlist. Returns true if removed. */
    public boolean remove(int userId, int productId) {
        try (Connection con = DBConnection.getConnection()) {
            ensureTable(con);
            PreparedStatement ps = con.prepareStatement(
                "DELETE FROM customer_wishlist WHERE user_id=? AND product_id=?");
            ps.setInt(1, userId);
            ps.setInt(2, productId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    /** Toggle: add if not present, remove if present. Returns "ADDED" or "REMOVED". */
    public String toggle(int userId, int productId) {
        if (isWishlisted(userId, productId)) {
            remove(userId, productId);
            return "REMOVED";
        } else {
            add(userId, productId);
            return "ADDED";
        }
    }

    /** Check if a specific product is in the wishlist. */
    public boolean isWishlisted(int userId, int productId) {
        try (Connection con = DBConnection.getConnection()) {
            ensureTable(con);
            PreparedStatement ps = con.prepareStatement(
                "SELECT 1 FROM customer_wishlist WHERE user_id=? AND product_id=?");
            ps.setInt(1, userId);
            ps.setInt(2, productId);
            ResultSet rs = ps.executeQuery();
            return rs.next();
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    /** Get all product IDs in a user's wishlist (for fast heart-icon rendering). */
    public Set<Integer> getWishlistIds(int userId) {
        Set<Integer> ids = new HashSet<>();
        try (Connection con = DBConnection.getConnection()) {
            ensureTable(con);
            PreparedStatement ps = con.prepareStatement(
                "SELECT product_id FROM customer_wishlist WHERE user_id=?");
            ps.setInt(1, userId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) ids.add(rs.getInt("product_id"));
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return ids;
    }

    /** Get full product details for all wishlisted items. */
    public List<Product> getWishlistProducts(int userId) {
        List<Product> list = new ArrayList<>();
        String sql =
            "SELECT p.id, p.name, p.price, p.quantity, p.category, p.unit, " +
            "       p.image_path, p.weight, p.description, p.stock_status " +
            "FROM customer_wishlist w " +
            "JOIN products p ON p.id = w.product_id " +
            "WHERE w.user_id = ? " +
            "ORDER BY w.created_at DESC";
        try (Connection con = DBConnection.getConnection()) {
            ensureTable(con);
            PreparedStatement ps = con.prepareStatement(sql);
            ps.setInt(1, userId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                Product p = new Product();
                p.setId(rs.getInt("id"));
                p.setName(rs.getString("name"));
                p.setPrice(rs.getDouble("price"));
                p.setQuantity(rs.getInt("quantity"));
                p.setCategory(rs.getString("category"));
                p.setUnit(rs.getString("unit"));
                p.setImagePath(rs.getString("image_path"));
                p.setWeight(rs.getDouble("weight"));
                p.setDescription(rs.getString("description"));
                p.setStockStatus(rs.getInt("stock_status"));
                list.add(p);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    /** Count of wishlist items. */
    public int count(int userId) {
        try (Connection con = DBConnection.getConnection()) {
            ensureTable(con);
            PreparedStatement ps = con.prepareStatement(
                "SELECT COUNT(*) FROM customer_wishlist WHERE user_id=?");
            ps.setInt(1, userId);
            ResultSet rs = ps.executeQuery();
            return rs.next() ? rs.getInt(1) : 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return 0;
        }
    }
}