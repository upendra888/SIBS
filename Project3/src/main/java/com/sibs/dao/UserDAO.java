package com.sibs.dao;

import com.sibs.model.User;
import com.sibs.util.DBConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class UserDAO {

    private Connection getConnection() throws SQLException {
        return DBConnection.getConnection();
    }

    // ---------------------------------------------------------------
    // Existence checks
    // ---------------------------------------------------------------

    public boolean isUsernameExists(String username) {
        String sql = "SELECT 1 FROM users WHERE username = ?";
        try (Connection c = getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, username);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    public boolean isEmailExists(String email) {
        String sql = "SELECT 1 FROM users WHERE email = ?";
        try (Connection c = getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, email);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    // ---------------------------------------------------------------
    // Authentication
    // ---------------------------------------------------------------

    /**
     * @deprecated Use {@link #findByUsernameAndRole(String, String)} and verify
     *             password in the servlet with {@code PasswordUtil.checkPassword()}.
     */
    @Deprecated
    public User login(String username, String password, String role) {
        return findByUsernameAndRole(username, role);
    }

    /**
     * Fetches a user by username (or email) and role — no password in the query.
     * Password verification is done in Java by the calling servlet using BCrypt.
     */
    public User findByUsernameAndRole(String username, String role) {
        String sql = "SELECT * FROM users WHERE (username = ? OR email = ?) AND UPPER(role) = UPPER(?)";
        try (Connection c = getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, username);
            ps.setString(2, username);
            ps.setString(3, role);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    // ---------------------------------------------------------------
    // Registration / insertion helpers
    // ---------------------------------------------------------------

    public boolean registerCustomer(User user) {
        user.setRole("CUSTOMER");
        user.setStatus("ACTIVE");
        return insertUser(user);
    }

    public boolean registerAdmin(User user) {
        user.setRole("ADMIN");
        user.setStatus("ACTIVE");
        return insertUser(user);
    }

    public boolean addStaff(User user) {
        user.setRole("STAFF");
        user.setStatus("ACTIVE");
        return insertUser(user);
    }

    private boolean insertUser(User user) {
        String sql = "INSERT INTO users (username, email, password, role, phone, address, status) "
                   + "VALUES (?, ?, ?, ?, ?, ?, ?)";
        try (Connection c = getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, user.getUsername());
            ps.setString(2, user.getEmail());
            ps.setString(3, user.getPassword());
            ps.setString(4, user.getRole());
            ps.setString(5, user.getPhone());
            ps.setString(6, user.getAddress());
            ps.setString(7, user.getStatus());
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    // ---------------------------------------------------------------
    // Lookups
    // ---------------------------------------------------------------

    public User getUserById(int id) {
        String sql = "SELECT * FROM users WHERE id = ?";
        try (Connection c = getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    public User getUserByUsername(String username) {
        String sql = "SELECT * FROM users WHERE username = ?";
        try (Connection c = getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, username);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    public User getUserByEmail(String email) {
        String sql = "SELECT * FROM users WHERE email = ?";
        try (Connection c = getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, email);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    public List<User> getUsersByRole(String role) {
        String sql = "SELECT * FROM users WHERE role = ? AND status = 'ACTIVE' ORDER BY username ASC";
        List<User> list = new ArrayList<>();
        try (Connection c = getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, role.toUpperCase());
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapRow(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<User> getAllUsers() {
        String sql = "SELECT * FROM users ORDER BY created_at DESC";
        List<User> list = new ArrayList<>();
        try (Connection c = getConnection();
             PreparedStatement ps = c.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapRow(rs));
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<User> searchUsers(String keyword) {
        String sql = "SELECT * FROM users WHERE name LIKE ? OR username LIKE ? OR email LIKE ?";
        List<User> list = new ArrayList<>();
        String pattern = "%" + keyword + "%";
        try (Connection c = getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, pattern);
            ps.setString(2, pattern);
            ps.setString(3, pattern);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapRow(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public int countByRole(String role) {
        String sql = "SELECT COUNT(*) FROM users WHERE role = ?";
        try (Connection c = getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, role.toUpperCase());
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0;
    }

    // ---------------------------------------------------------------
    // Updates
    // ---------------------------------------------------------------

    public boolean updateUser(User user) {
        String sql = "UPDATE users SET name=?, username=?, email=?, phone=?, address=?, gender=?, status=? WHERE id=?";
        try (Connection c = getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, user.getName());
            ps.setString(2, user.getUsername());
            ps.setString(3, user.getEmail());
            ps.setString(4, user.getPhone());
            ps.setString(5, user.getAddress());
            ps.setString(6, user.getGender());
            ps.setString(7, user.getStatus());
            ps.setInt(8, user.getId());
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    public boolean updatePassword(int userId, String newPassword) {
        String sql = "UPDATE users SET password=? WHERE id=?";
        try (Connection c = getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, newPassword);
            ps.setInt(2, userId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    public boolean updateStatus(int userId, String status) {
        String sql = "UPDATE users SET status=? WHERE id=?";
        try (Connection c = getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, status);
            ps.setInt(2, userId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    public boolean deleteUser(int userId) {
        String sql = "DELETE FROM users WHERE id=?";
        try (Connection c = getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, userId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    // ---------------------------------------------------------------
    // Row mapping
    // ---------------------------------------------------------------

    private User mapRow(ResultSet rs) throws SQLException {
        User u = new User();
        trySet(u, rs, "id");
        trySet(u, rs, "name");
        trySet(u, rs, "username");
        trySet(u, rs, "email");
        trySet(u, rs, "password");
        trySet(u, rs, "role");
        trySet(u, rs, "phone");
        trySet(u, rs, "address");
        trySet(u, rs, "gender");
        trySet(u, rs, "status");
        trySet(u, rs, "created_at");
        return u;
    }

    private void trySet(User u, ResultSet rs, String col) throws SQLException {
        try {
            switch (col) {
                case "id"         -> u.setId(rs.getInt(col));
                case "name"       -> u.setName(rs.getString(col));
                case "username"   -> u.setUsername(rs.getString(col));
                case "email"      -> u.setEmail(rs.getString(col));
                case "password"   -> u.setPassword(rs.getString(col));
                case "role"       -> u.setRole(rs.getString(col));
                case "phone"      -> u.setPhone(rs.getString(col));
                case "address"    -> u.setAddress(rs.getString(col));
                case "gender"     -> u.setGender(rs.getString(col));
                case "status"     -> u.setStatus(rs.getString(col));
                case "created_at" -> u.setCreatedAt(rs.getString(col));
            }
        } catch (SQLException ignored) {
            // column may not exist in all queries — safe to skip
        }
    }
}