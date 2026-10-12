package com.sibs.dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;

import com.sibs.model.Product;
import com.sibs.util.DBConnection;

public class ProductDAO {

    /* ================= ADD PRODUCT ================= */
    public boolean addProduct(Product p) {
        String sql = "INSERT INTO products(name,price,quantity,category,weight,unit,image_path,description,stock_status) VALUES(?,?,?,?,?,?,?,?,?)";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, p.getName());
            ps.setDouble(2, p.getPrice());
            ps.setInt(3, p.getQuantity());
            ps.setString(4, p.getCategory().toUpperCase());
            ps.setDouble(5, p.getWeight());
            ps.setString(6, p.getUnit());
            ps.setString(7, p.getImagePath());
            ps.setString(8, p.getDescription());
            ps.setInt(9, p.getStockStatus());

            return ps.executeUpdate() > 0;

        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    /* ================= CHECK DUPLICATE ================= */
    public boolean isProductExists(String name) {
        String sql = "SELECT id FROM products WHERE LOWER(name)=LOWER(?)";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, name);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }

        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    /* ================= GET ALL PRODUCTS ================= */
    public List<Product> getAllProducts() {
        List<Product> list = new ArrayList<>();
        String sql = "SELECT * FROM products";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                list.add(mapProduct(rs));
            }

        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    /* ================= GET PRODUCT BY ID ================= */
    public Product getProductById(int id) {
        String sql = "SELECT * FROM products WHERE id=?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapProduct(rs);
            }

        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    /* ================= UPDATE PRODUCT ================= */
    public boolean updateProduct(Product p) {
        String sql = "UPDATE products SET name=?,price=?,quantity=?,category=?,weight=?,unit=?,image_path=?,description=?,stock_status=? WHERE id=?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, p.getName());
            ps.setDouble(2, p.getPrice());
            ps.setInt(3, p.getQuantity());
            ps.setString(4, p.getCategory().toUpperCase());
            ps.setDouble(5, p.getWeight());
            ps.setString(6, p.getUnit());
            ps.setString(7, p.getImagePath());
            ps.setString(8, p.getDescription());
            ps.setInt(9, p.getStockStatus());
            ps.setInt(10, p.getId());

            return ps.executeUpdate() > 0;

        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    /* ================= DELETE PRODUCT ================= */
    public boolean deleteProduct(int id) {
        String sql = "DELETE FROM products WHERE id=?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setInt(1, id);
            return ps.executeUpdate() > 0;

        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    /* ================= SEARCH + FILTER ================= */
    public List<Product> searchProducts(String category, String search) {
        List<Product> list = new ArrayList<>();

        String query = "SELECT * FROM products WHERE 1=1";
        if (category != null && !category.equalsIgnoreCase("ALL"))
            query += " AND UPPER(category)=UPPER(?)";
        if (search != null && !search.trim().isEmpty())
            query += " AND UPPER(name) LIKE UPPER(?)";

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(query)) {

            int index = 1;
            if (category != null && !category.equalsIgnoreCase("ALL"))
                ps.setString(index++, category.trim());
            if (search != null && !search.trim().isEmpty())
                ps.setString(index++, "%" + search.trim() + "%");

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapProduct(rs));
            }

        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    /* ================= GET PRODUCT BY NAME ================= */
    public Product getProductByName(String name) {
        String sql = "SELECT * FROM products WHERE name=?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, name);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapProduct(rs);
            }

        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    /* ================= UPDATE STOCK ================= */
    public void updateStock(int id, int qty) {
        String sql = "UPDATE products SET quantity=? WHERE id=?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setInt(1, qty);
            ps.setInt(2, id);
            ps.executeUpdate();

        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    /* ================= STOCK: CHECK AVAILABILITY ================= */
    /**
     * Returns the name of the first product whose available stock is less than
     * the requested quantity, or null if all items are available.
     * Call this BEFORE inserting any order rows.
     */
    public String getOutOfStockItem(java.util.List<Product> items) {
        String sql = "SELECT name, quantity FROM products WHERE id = ?";
        try (Connection con = DBConnection.getConnection()) {
            for (Product item : items) {
                try (PreparedStatement ps = con.prepareStatement(sql)) {
                    ps.setInt(1, item.getId());
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            int available = rs.getInt("quantity");
                            if (available < item.getQuantity()) {
                                return rs.getString("name") + " (available: " + available
                                        + ", requested: " + item.getQuantity() + ")";
                            }
                        } else {
                            return "Product id=" + item.getId() + " not found";
                        }
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null; // all items are in stock
    }

    /* ================= STOCK: DEDUCT BY GROUP ================= */
    /**
     * Deducts stock for every order row that belongs to group_id.
     * Uses WHERE p.quantity >= o.quantity so it never goes negative.
     * Call this after COD order is confirmed or after Razorpay payment succeeds.
     */
    public void deductStockByGroup(int groupId) {
        String sql = "UPDATE products p " +
                     "JOIN orders o ON p.id = o.product_id " +
                     "SET p.quantity = p.quantity - o.quantity " +
                     "WHERE o.group_id = ? AND p.quantity >= o.quantity";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, groupId);
            ps.executeUpdate();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    /* ================= STOCK: RESTORE BY GROUP ================= */
    /**
     * Restores stock for every order row that belongs to group_id.
     * Call this when an order is cancelled.
     */
    public void restoreStockByGroup(int groupId) {
        String sql = "UPDATE products p " +
                     "JOIN orders o ON p.id = o.product_id " +
                     "SET p.quantity = p.quantity + o.quantity " +
                     "WHERE o.group_id = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, groupId);
            ps.executeUpdate();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    /* ================= HELPER: MAP ROW ================= */
    private Product mapProduct(ResultSet rs) throws Exception {
        Product p = new Product();
        p.setId(rs.getInt("id"));
        p.setName(rs.getString("name"));
        p.setPrice(rs.getDouble("price"));
        p.setQuantity(rs.getInt("quantity"));
        p.setCategory(rs.getString("category"));
        p.setWeight(rs.getDouble("weight"));
        p.setUnit(rs.getString("unit"));
        p.setImagePath(rs.getString("image_path"));
        try { p.setDescription(rs.getString("description")); } catch (Exception ignored) {}
        try { p.setStockStatus(rs.getInt("stock_status")); } catch (Exception ignored) {}
        return p;
    }
}