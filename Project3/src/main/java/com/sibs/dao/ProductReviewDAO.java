package com.sibs.dao;

import com.sibs.util.DBConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * ProductReviewDAO — product ratings and reviews from customers.
 * Only customers who ordered and received the product can review.
 * Table auto-created on first use.
 */
public class ProductReviewDAO {

    private static final String CREATE_TABLE =
        "CREATE TABLE IF NOT EXISTS product_reviews (" +
        "  id          INT AUTO_INCREMENT PRIMARY KEY," +
        "  product_id  INT NOT NULL," +
        "  user_id     INT NOT NULL," +
        "  order_id    INT NOT NULL," +
        "  rating      TINYINT NOT NULL CHECK (rating BETWEEN 1 AND 5)," +
        "  review_text TEXT," +
        "  created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP," +
        "  UNIQUE KEY uq_review (product_id, user_id, order_id)" +
        ")";

    /**
     * Get all reviews (for staff panel) — latest 200.
     * Returns List of String[]{id, productName, reviewerName, rating, text, date}
     */
    public List<String[]> getAllReviews() {
        List<String[]> list = new ArrayList<>();
        String sql =
            "SELECT r.id, p.name AS product_name, COALESCE(u.name, u.username) AS reviewer, " +
            "r.rating, r.review_text, r.created_at " +
            "FROM product_reviews r " +
            "JOIN products p ON p.id = r.product_id " +
            "JOIN users u ON u.id = r.user_id " +
            "ORDER BY r.created_at DESC LIMIT 200";
        try (Connection con = DBConnection.getConnection()) {
            ensureTable(con);
            ResultSet rs = con.createStatement().executeQuery(sql);
            while (rs.next()) {
                list.add(new String[]{
                    rs.getString("id"),
                    rs.getString("product_name"),
                    rs.getString("reviewer"),
                    String.valueOf(rs.getInt("rating")),
                    rs.getString("review_text"),
                    rs.getString("created_at")
                });
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return list;
    }

    /**
     * Delete a review by id.
     */
    public boolean deleteReview(int reviewId) {
        try (Connection con = DBConnection.getConnection()) {
            ensureTable(con);
            PreparedStatement ps = con.prepareStatement(
                "DELETE FROM product_reviews WHERE id=?");
            ps.setInt(1, reviewId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); return false; }
    }

    private void ensureTable(Connection con) throws SQLException {
        con.createStatement().execute(CREATE_TABLE);
    }

    /**
     * Submit a review. Each (product, user, order) combination is unique.
     * @return true if saved, false if already reviewed or error.
     */
    public boolean submitReview(int productId, int userId, int orderId, int rating, String text) {
        try (Connection con = DBConnection.getConnection()) {
            ensureTable(con);
            PreparedStatement ps = con.prepareStatement(
                "INSERT IGNORE INTO product_reviews (product_id, user_id, order_id, rating, review_text) " +
                "VALUES (?, ?, ?, ?, ?)");
            ps.setInt(1, productId);
            ps.setInt(2, userId);
            ps.setInt(3, orderId);
            ps.setInt(4, rating);
            ps.setString(5, text != null ? text.trim() : "");
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    /**
     * Update existing review.
     */
    public boolean updateReview(int productId, int userId, int orderId, int rating, String text) {
        try (Connection con = DBConnection.getConnection()) {
            ensureTable(con);
            PreparedStatement ps = con.prepareStatement(
                "UPDATE product_reviews SET rating=?, review_text=? " +
                "WHERE product_id=? AND user_id=? AND order_id=?");
            ps.setInt(1, rating);
            ps.setString(2, text != null ? text.trim() : "");
            ps.setInt(3, productId);
            ps.setInt(4, userId);
            ps.setInt(5, orderId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    /**
     * Check if a user already reviewed this product for this order.
     */
    public boolean hasReviewed(int productId, int userId, int orderId) {
        try (Connection con = DBConnection.getConnection()) {
            ensureTable(con);
            PreparedStatement ps = con.prepareStatement(
                "SELECT 1 FROM product_reviews WHERE product_id=? AND user_id=? AND order_id=?");
            ps.setInt(1, productId);
            ps.setInt(2, userId);
            ps.setInt(3, orderId);
            return ps.executeQuery().next();
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    /**
     * Get average rating and count for a product.
     * Returns double[]{avgRating, count}
     */
    public double[] getProductRating(int productId) {
        try (Connection con = DBConnection.getConnection()) {
            ensureTable(con);
            PreparedStatement ps = con.prepareStatement(
                "SELECT AVG(rating) as avg_r, COUNT(*) as cnt " +
                "FROM product_reviews WHERE product_id=?");
            ps.setInt(1, productId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                double avg = rs.getDouble("avg_r");
                int cnt = rs.getInt("cnt");
                return new double[]{avg, cnt};
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return new double[]{0.0, 0};
    }

    /**
     * Get all reviews for a product (latest 20), with reviewer name.
     * Returns List of String[]{reviewerName, rating, text, date}
     */
    public List<String[]> getProductReviews(int productId) {
        List<String[]> list = new ArrayList<>();
        String sql =
            "SELECT COALESCE(u.name, u.username) AS reviewer, r.rating, r.review_text, r.created_at " +
            "FROM product_reviews r " +
            "JOIN users u ON u.id = r.user_id " +
            "WHERE r.product_id=? " +
            "ORDER BY r.created_at DESC LIMIT 20";
        try (Connection con = DBConnection.getConnection()) {
            ensureTable(con);
            PreparedStatement ps = con.prepareStatement(sql);
            ps.setInt(1, productId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                list.add(new String[]{
                    rs.getString("reviewer"),
                    String.valueOf(rs.getInt("rating")),
                    rs.getString("review_text"),
                    rs.getString("created_at")
                });
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    /**
     * Get products a customer can still review (delivered orders, not yet reviewed).
     * Returns List of String[]{orderId, productId, productName, orderDate}
     */
    public List<String[]> getPendingReviewsForUser(int userId) {
        List<String[]> list = new ArrayList<>();
        // Join order_items with orders where status=DELIVERED, left-exclude already reviewed
        String sql =
            "SELECT DISTINCT o.id AS order_id, oi.product_id, p.name, p.image_path, " +
            "       oi.price, o.order_date AS order_date " +
            "FROM orders o " +
            "JOIN order_items oi ON oi.order_id = o.id " +
            "JOIN products p ON p.id = oi.product_id " +
            "LEFT JOIN product_reviews rv ON rv.product_id = oi.product_id " +
            "    AND rv.user_id = o.user_id AND rv.order_id = o.id " +
            "WHERE o.user_id=? AND o.status='Delivered' AND rv.id IS NULL " +
            "ORDER BY o.order_date DESC LIMIT 30";
        try (Connection con = DBConnection.getConnection()) {
            ensureTable(con);
            PreparedStatement ps = con.prepareStatement(sql);
            ps.setInt(1, userId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                list.add(new String[]{
                    rs.getString("order_id"),
                    rs.getString("product_id"),
                    rs.getString("name"),
                    rs.getString("image_path"),
                    rs.getString("price"),
                    rs.getString("order_date")
                });
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    /**
     * Get reviews already written by a user.
     * Returns List of String[]{productId, productName, rating, text, date}
     */
    public List<String[]> getMyReviews(int userId) {
        List<String[]> list = new ArrayList<>();
        String sql =
            "SELECT r.product_id, p.name, p.image_path, r.rating, r.review_text, r.created_at " +
            "FROM product_reviews r " +
            "JOIN products p ON p.id = r.product_id " +
            "WHERE r.user_id=? ORDER BY r.created_at DESC";
        try (Connection con = DBConnection.getConnection()) {
            ensureTable(con);
            PreparedStatement ps = con.prepareStatement(sql);
            ps.setInt(1, userId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                list.add(new String[]{
                    rs.getString("product_id"),
                    rs.getString("name"),
                    rs.getString("image_path"),
                    String.valueOf(rs.getInt("rating")),
                    rs.getString("review_text"),
                    rs.getString("created_at")
                });
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }
}