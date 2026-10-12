package com.sibs.dao;

import com.sibs.util.DBConnection;
import java.sql.*;
import java.util.*;

public class CouponDAO {

    // ── Validate & return discount amount for a coupon code ──────────────────
    // Returns: double[]{discountAmount, maxDiscount} or null if invalid
    public double[] validateCoupon(String code, double subtotal) {
        String sql = "SELECT * FROM coupons WHERE code = ? AND is_active = 1 " +
                     "AND valid_from <= CURDATE() AND valid_until >= CURDATE()";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, code.trim().toUpperCase());
            ResultSet rs = ps.executeQuery();
            if (!rs.next()) return null;

            // Check usage limit
            int usageLimit = rs.getInt("usage_limit");
            int usedCount  = rs.getInt("used_count");
            if (usageLimit > 0 && usedCount >= usageLimit) return null;

            // Check minimum order
            double minOrder = rs.getDouble("min_order_amount");
            if (subtotal < minOrder) return null;

            // Calculate discount
            String type  = rs.getString("discount_type");
            double value = rs.getDouble("discount_value");
            double maxD  = rs.getDouble("max_discount");  // 0 means no cap

            double discount;
            if ("PERCENT".equalsIgnoreCase(type)) {
                discount = subtotal * value / 100.0;
                if (maxD > 0 && discount > maxD) discount = maxD;
            } else {
                discount = value;
                if (discount > subtotal) discount = subtotal;
            }

            return new double[]{ Math.round(discount * 100.0) / 100.0,
                                 rs.getInt("id"),
                                 minOrder,
                                 maxD };
        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }

    // ── Get coupon description for UI response ───────────────────────────────
    public String getDescription(String code) {
        String sql = "SELECT description, discount_type, discount_value FROM coupons WHERE code = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, code.trim().toUpperCase());
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                String desc = rs.getString("description");
                if (desc != null && !desc.isEmpty()) return desc;
                String type = rs.getString("discount_type");
                double val  = rs.getDouble("discount_value");
                return "PERCENT".equalsIgnoreCase(type)
                    ? (int) val + "% off applied"
                    : "₹" + (int) val + " off applied";
            }
        } catch (Exception e) { e.printStackTrace(); }
        return "";
    }

    // ── Increment used_count after successful order ──────────────────────────
    public void incrementUsage(String code) {
        if (code == null || code.trim().isEmpty()) return;
        String sql = "UPDATE coupons SET used_count = used_count + 1 WHERE code = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, code.trim().toUpperCase());
            ps.executeUpdate();
        } catch (Exception e) { e.printStackTrace(); }
    }

    // ── List all coupons (staff management) ─────────────────────────────────
    public List<Map<String, Object>> getAllCoupons() {
        List<Map<String, Object>> list = new ArrayList<>();
        String sql = "SELECT * FROM coupons ORDER BY created_at DESC";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> row = new LinkedHashMap<>();
                row.put("id",              rs.getInt("id"));
                row.put("code",            rs.getString("code"));
                row.put("description",     rs.getString("description"));
                row.put("discount_type",   rs.getString("discount_type"));
                row.put("discount_value",  rs.getDouble("discount_value"));
                row.put("min_order_amount",rs.getDouble("min_order_amount"));
                row.put("max_discount",    rs.getDouble("max_discount"));
                row.put("usage_limit",     rs.getInt("usage_limit"));
                row.put("used_count",      rs.getInt("used_count"));
                row.put("valid_from",      rs.getString("valid_from"));
                row.put("valid_until",     rs.getString("valid_until"));
                row.put("is_active",       rs.getInt("is_active"));
                list.add(row);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    // ── Create coupon ────────────────────────────────────────────────────────
    public boolean createCoupon(String code, String description, String discountType,
                                double discountValue, double minOrder, double maxDiscount,
                                Integer usageLimit, String validFrom, String validUntil) {
        String sql = "INSERT INTO coupons (code, description, discount_type, discount_value, " +
                     "min_order_amount, max_discount, usage_limit, valid_from, valid_until, is_active) " +
                     "VALUES (?,?,?,?,?,?,?,?,?,1)";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, code.trim().toUpperCase());
            ps.setString(2, description);
            ps.setString(3, discountType);
            ps.setDouble(4, discountValue);
            ps.setDouble(5, minOrder);
            ps.setDouble(6, maxDiscount);
            if (usageLimit != null && usageLimit > 0) ps.setInt(7, usageLimit);
            else ps.setNull(7, Types.INTEGER);
            ps.setString(8, validFrom);
            ps.setString(9, validUntil);
            ps.executeUpdate();
            return true;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    // ── Toggle active status ─────────────────────────────────────────────────
    public void toggleActive(int id) {
        String sql = "UPDATE coupons SET is_active = 1 - is_active WHERE id = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, id);
            ps.executeUpdate();
        } catch (Exception e) { e.printStackTrace(); }
    }

    // ── Delete coupon ────────────────────────────────────────────────────────
    public void deleteCoupon(int id) {
        String sql = "DELETE FROM coupons WHERE id = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, id);
            ps.executeUpdate();
        } catch (Exception e) { e.printStackTrace(); }
    }
}