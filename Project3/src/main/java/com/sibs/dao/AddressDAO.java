package com.sibs.dao;

import com.sibs.model.Address;
import com.sibs.util.DBConnection;
import java.sql.*;
import java.util.*;

public class AddressDAO {

    // ── Fetch all addresses for a user ────────────────────────────────────
    public List<Address> getAddressByUser(int userId) {
        List<Address> list = new ArrayList<>();
        String sql = "SELECT * FROM addresses WHERE user_id = ? ORDER BY is_default DESC, id DESC";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(map(rs));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    // ── Fetch single address by ID ────────────────────────────────────────
    public Address getById(int id) {
        String sql = "SELECT * FROM addresses WHERE id = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return map(rs);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return null;
    }

    // ── Alias for getById — used by editaddress.jsp ───────────────────────
    public Address getAddressById(int id) {
        return getById(id);
    }

    // ── Save new address — returns boolean (existing method, kept for compatibility) ──
    public boolean save(Address a, int userId) {
        return saveAndGetId(a, userId) > 0;
    }

    // ── Save new address — returns generated ID ───────────────────────────
    public int saveAndGetId(Address a, int userId) {
        if (a.isDefault()) clearDefaults(userId);

        String sql = "INSERT INTO addresses " +
                     "(user_id, name, phone, address, landmark, city, state, pincode, " +
                     " is_default, latitude, longitude) " +
                     "VALUES (?,?,?,?,?,?,?,?,?,?,?)";

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            ps.setInt(1,     userId);
            ps.setString(2,  a.getName());
            ps.setString(3,  a.getPhone());
            ps.setString(4,  a.getAddress());
            ps.setString(5,  a.getLandmark());
            ps.setString(6,  a.getCity());
            ps.setString(7,  a.getState());
            ps.setString(8,  a.getPincode());
            ps.setBoolean(9, a.isDefault());
            ps.setDouble(10, a.getLatitude());
            ps.setDouble(11, a.getLongitude());

            ps.executeUpdate();

            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (rs.next()) return rs.getInt(1);
            }

        } catch (Exception e) { e.printStackTrace(); }
        return -1;
    }

    // ── Update address ────────────────────────────────────────────────────
    public boolean update(Address a, int userId) {
        if (a.isDefault()) clearDefaults(userId);
        String sql = "UPDATE addresses SET name=?, phone=?, address=?, landmark=?, " +
                     "city=?, state=?, pincode=?, is_default=?, latitude=?, longitude=? " +
                     "WHERE id=? AND user_id=?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1,  a.getName());
            ps.setString(2,  a.getPhone());
            ps.setString(3,  a.getAddress());
            ps.setString(4,  a.getLandmark());
            ps.setString(5,  a.getCity());
            ps.setString(6,  a.getState());
            ps.setString(7,  a.getPincode());
            ps.setBoolean(8, a.isDefault());
            ps.setDouble(9,  a.getLatitude());
            ps.setDouble(10, a.getLongitude());
            ps.setInt(11,    a.getId());
            ps.setInt(12,    userId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    // ── Delete ────────────────────────────────────────────────────────────
    public boolean delete(int id, int userId) {
        String sql = "DELETE FROM addresses WHERE id=? AND user_id=?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, id);
            ps.setInt(2, userId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    // ── Helpers ───────────────────────────────────────────────────────────
    private void clearDefaults(int userId) {
        String sql = "UPDATE addresses SET is_default=0 WHERE user_id=?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, userId);
            ps.executeUpdate();
        } catch (Exception e) { e.printStackTrace(); }
    }

    private Address map(ResultSet rs) throws SQLException {
        Address a = new Address();
        a.setId(rs.getInt("id"));
        a.setUserId(rs.getInt("user_id"));
        a.setName(rs.getString("name"));
        a.setPhone(rs.getString("phone"));
        a.setAddress(rs.getString("address"));
        a.setLandmark(rs.getString("landmark"));
        a.setCity(rs.getString("city"));
        a.setState(rs.getString("state"));
        a.setPincode(rs.getString("pincode"));
        a.setDefault(rs.getBoolean("is_default"));
        a.setLatitude(rs.getDouble("latitude"));
        a.setLongitude(rs.getDouble("longitude"));
        return a;
    }
}