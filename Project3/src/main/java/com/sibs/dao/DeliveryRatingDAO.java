package com.sibs.dao;

import com.sibs.util.DBConnection;
import java.sql.*;
import java.util.*;

/**
 * DAO for the delivery_ratings table.
 * Customers rate the rider after delivery (1-5 stars + optional comment).
 */
public class DeliveryRatingDAO {

    public static class Rating {
        public int id, orderId, deliveryBoyId, customerId, stars;
        public String comment, createdAt, customerName;
    }

    /** Submit a rating. Returns false if already rated for this order. */
    public boolean submitRating(int orderId, int deliveryBoyId, int customerId, int stars, String comment) {
        // Prevent duplicate rating for same order
        String check = "SELECT id FROM delivery_ratings WHERE order_id=? AND customer_id=?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(check)) {
            ps.setInt(1, orderId);
            ps.setInt(2, customerId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return false; // already rated
        } catch (Exception e) { e.printStackTrace(); return false; }

        String sql = "INSERT INTO delivery_ratings (order_id, delivery_boy_id, customer_id, stars, comment, created_at) " +
                     "VALUES (?, ?, ?, ?, ?, NOW())";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, orderId);
            ps.setInt(2, deliveryBoyId);
            ps.setInt(3, customerId);
            ps.setInt(4, stars);
            ps.setString(5, comment);
            ps.executeUpdate();
            return true;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    /** Get all ratings for a delivery boy, newest first */
    public List<Rating> getRatingsForRider(int deliveryBoyId) {
        List<Rating> list = new ArrayList<>();
        String sql =
            "SELECT dr.*, u.name AS customer_name " +
            "FROM delivery_ratings dr " +
            "JOIN users u ON u.id = dr.customer_id " +
            "WHERE dr.delivery_boy_id = ? " +
            "ORDER BY dr.created_at DESC";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, deliveryBoyId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                Rating r = new Rating();
                r.id             = rs.getInt("id");
                r.orderId        = rs.getInt("order_id");
                r.deliveryBoyId  = deliveryBoyId;
                r.customerId     = rs.getInt("customer_id");
                r.stars          = rs.getInt("stars");
                r.comment        = rs.getString("comment");
                r.createdAt      = rs.getString("created_at");
                r.customerName   = rs.getString("customer_name");
                list.add(r);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    /** Average star rating for a delivery boy */
    public double getAvgRating(int deliveryBoyId) {
        String sql = "SELECT COALESCE(AVG(stars),0) FROM delivery_ratings WHERE delivery_boy_id=?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, deliveryBoyId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return rs.getDouble(1);
        } catch (Exception e) { e.printStackTrace(); }
        return 0;
    }

    /** Check if a customer already rated an order */
    public boolean hasRated(int orderId, int customerId) {
        String sql = "SELECT id FROM delivery_ratings WHERE order_id=? AND customer_id=?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, orderId);
            ps.setInt(2, customerId);
            return ps.executeQuery().next();
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    /** Get assignment's delivery boy for a given order (for rating page) */
    public int getDeliveryBoyIdForOrder(int orderId) {
        String sql = "SELECT delivery_boy_id FROM delivery_assignments WHERE order_id=? AND status='DELIVERED' LIMIT 1";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, orderId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return rs.getInt(1);
        } catch (Exception e) { e.printStackTrace(); }
        return -1;
    }

    /** Get average star rating for a delivery boy (0 if no ratings yet) */
    public double getAverageRating(int deliveryBoyId) {
        String sql = "SELECT AVG(stars) FROM delivery_ratings WHERE delivery_boy_id=?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, deliveryBoyId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return rs.getDouble(1);
        } catch (Exception e) { e.printStackTrace(); }
        return 0;
    }
}