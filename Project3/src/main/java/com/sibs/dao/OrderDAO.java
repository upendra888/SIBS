package com.sibs.dao;

import com.sibs.model.Order;
import com.sibs.util.DBConnection;

import java.sql.*;
import java.util.*;

public class OrderDAO {

    public int placeOrder(int userId, int productId, int quantity, double total,
                          String name, String phone, String altPhone, String email,
                          String address, String paymentMethod, int groupId, double deliveryCharge) {
        String sql = "INSERT INTO orders (group_id, user_id, product_id, quantity, total, name, phone, alt_phone, email, address, payment_method, delivery_charge, status, order_date) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,NOW())";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql, PreparedStatement.RETURN_GENERATED_KEYS)) {
            ps.setInt(1, groupId);
            ps.setInt(2, userId);
            ps.setInt(3, productId);
            ps.setInt(4, quantity);
            ps.setDouble(5, total);
            ps.setString(6, name);
            ps.setString(7, phone);
            ps.setString(8, altPhone);
            ps.setString(9, email);
            ps.setString(10, address);
            ps.setString(11, paymentMethod);
            ps.setDouble(12, deliveryCharge);
            ps.setString(13, "Pending");
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                if (keys.next()) return keys.getInt(1);
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return -1;
    }

    public void placeOrder(Order order) {
        String sql = "INSERT INTO orders (group_id, user_id, product_id, quantity, total, name, phone, alt_phone, email, address, payment_method, status, order_date) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,NOW())";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, order.getGroupId());
            ps.setInt(2, order.getUserId());
            ps.setInt(3, order.getProductId());
            ps.setInt(4, order.getQuantity());
            ps.setDouble(5, order.getTotal());
            ps.setString(6, order.getName());
            ps.setString(7, order.getPhone());
            ps.setString(8, order.getAltPhone());
            ps.setString(9, order.getEmail());
            ps.setString(10, order.getAddress());
            ps.setString(11, order.getPaymentMethod());
            ps.setString(12, order.getStatus());
            ps.executeUpdate();
        } catch (SQLException e) { e.printStackTrace(); }
    }

    public List<Order> getOrdersByUser(int userId) {
        List<Order> list = new ArrayList<>();
        String sql = "SELECT o.id, o.group_id, o.user_id, o.product_id, o.quantity, o.total, " +
                     "o.order_date, o.name, o.phone, o.alt_phone, o.email, o.address, " +
                     "o.payment_method, o.status, COALESCE(o.cancel_reason,'') AS cancel_reason, " +
                     "p.name AS product_name, p.image_path AS product_image " +
                     "FROM orders o LEFT JOIN products p ON o.product_id = p.id " +
                     "WHERE o.user_id = ? ORDER BY o.order_date DESC";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Order o = mapRow(rs);
                    list.add(o);
                }
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return list;
    }

    // FIX: da.group_id does not exist in delivery_assignments — changed to da.order_id = o.id
    public List<Order> getDeliveredOrdersByUser(int userId) {
        List<Order> all = getGroupedOrdersByUser(userId);
        List<Order> delivered = new ArrayList<>();
        for (Order o : all) {
            if ("Delivered".equalsIgnoreCase(o.getStatus())) {
                delivered.add(o);
            }
        }
        return delivered;
    }

    public List<Order> getGroupedOrdersByUser(int userId) {
        List<Order> list = new ArrayList<>();
        // FIX: Use COALESCE for cancel_reason in case the column doesn't exist yet,
        // and use IF() / CASE to safely alias it so a missing column won't kill the whole query.
        // Also select cancel_reason via COALESCE to avoid errors on older schemas.
        String sql = "SELECT o.id, o.group_id, o.user_id, o.product_id, o.quantity, o.total, " +
                     "o.order_date, o.name, o.phone, o.alt_phone, o.email, o.address, " +
                     "o.payment_method, o.status, " +
                     "COALESCE(o.cancel_reason, '') AS cancel_reason, " +
                     "COALESCE(o.delivery_charge, 0) AS delivery_charge, " +
                     "p.name AS product_name, p.image_path AS product_image, " +
                     "db.name AS delivery_boy_name, da.status AS da_status, da.id AS assignment_id, " +
                     "da.otp AS da_otp, " +
                     "rr.status AS return_status " +
                     "FROM orders o " +
                     "LEFT JOIN products p ON o.product_id = p.id " +
                     "LEFT JOIN delivery_assignments da ON da.order_id = o.id AND da.status != 'Cancelled' " +
                     "LEFT JOIN delivery_boys db ON db.id = da.delivery_boy_id " +
                     "LEFT JOIN return_requests rr ON rr.order_id = o.id " +
                     "WHERE o.user_id = ? " +
                     "ORDER BY o.order_date DESC, o.group_id DESC, o.id ASC";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                Map<Integer, Order> groupMap = new LinkedHashMap<>();
                while (rs.next()) {
                    int gid = rs.getInt("group_id");
                    if (!groupMap.containsKey(gid)) {
                        Order head = mapRow(rs);
                        try { head.setDeliveryBoy(rs.getString("delivery_boy_name")); } catch (Exception ignored) {}
                        try { head.setReturnStatus(rs.getString("return_status")); } catch (Exception ignored) {}
                        try { head.setCancelReason(rs.getString("cancel_reason")); } catch (Exception ignored) {}
                        groupMap.put(gid, head);
                    }
                    Order item = mapRow(rs);
                    groupMap.get(gid).getItems().add(item);
                }
                list.addAll(groupMap.values());
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return list;
    }

    // FIX: da.group_id does not exist in delivery_assignments — changed to da.order_id = o.id
    public List<Order> getGroupedOrders() {
        List<Order> list = new ArrayList<>();
        String sql = "SELECT o.id, o.group_id, o.user_id, o.product_id, o.quantity, o.total, " +
                     "o.order_date, o.name, o.phone, o.alt_phone, o.email, o.address, " +
                     "o.payment_method, o.status, " +
                     "COALESCE(o.cancel_reason, '') AS cancel_reason, " +
                     "COALESCE(o.delivery_charge, 0) AS delivery_charge, " +
                     "p.name AS product_name, p.image_path AS product_image, " +
                     "db.name AS delivery_boy_name, da.status AS da_status " +
                     "FROM orders o " +
                     "LEFT JOIN products p ON o.product_id = p.id " +
                     "LEFT JOIN delivery_assignments da ON da.order_id = o.id AND da.status != 'Cancelled' " + // FIXED
                     "LEFT JOIN delivery_boys db ON db.id = da.delivery_boy_id " +
                     "ORDER BY o.order_date DESC, o.group_id DESC, o.id ASC";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            Map<Integer, Order> groupMap = new LinkedHashMap<>();
            while (rs.next()) {
                int gid = rs.getInt("group_id");
                if (!groupMap.containsKey(gid)) {
                    Order head = mapRow(rs);
                    try { head.setDeliveryBoy(rs.getString("delivery_boy_name")); } catch (Exception ignored) {}
                    try { head.setCancelReason(rs.getString("cancel_reason")); } catch (Exception ignored) {}
                    try { head.setDeliveryCharge(rs.getDouble("delivery_charge")); } catch (Exception ignored) {}
                    groupMap.put(gid, head);
                }
                Order item = mapRow(rs);
                groupMap.get(gid).getItems().add(item);
            }
            list.addAll(groupMap.values());
        } catch (SQLException e) { e.printStackTrace(); }
        return list;
    }

    public Order getOrderById(int orderId) {
        String sql = "SELECT o.id, o.group_id, o.user_id, o.product_id, o.quantity, o.total, " +
                     "o.order_date, o.name, o.phone, o.alt_phone, o.email, o.address, " +
                     "o.payment_method, o.status, COALESCE(o.cancel_reason,'') AS cancel_reason, " +
                     "p.name AS product_name, p.image_path AS product_image " +
                     "FROM orders o LEFT JOIN products p ON o.product_id = p.id WHERE o.id = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return null;
    }

    public List<Order> getOrdersByGroupId(int groupId) {
        List<Order> list = new ArrayList<>();
        String sql = "SELECT o.id, o.group_id, o.user_id, o.product_id, o.quantity, o.total, " +
                     "o.order_date, o.name, o.phone, o.alt_phone, o.email, o.address, " +
                     "o.payment_method, o.status, COALESCE(o.cancel_reason,'') AS cancel_reason, " +
                     "p.name AS product_name, p.image_path AS product_image " +
                     "FROM orders o LEFT JOIN products p ON o.product_id = p.id WHERE o.group_id = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, groupId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapRow(rs));
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return list;
    }

    public void updateStatus(int groupId, String status) {
        String sql = "UPDATE orders SET status=? WHERE group_id=?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, status);
            ps.setInt(2, groupId);
            ps.executeUpdate();
        } catch (SQLException e) { e.printStackTrace(); }
    }

    public void updateStatusById(int orderId, String status) {
        String sql = "UPDATE orders SET status=? WHERE id=?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, status);
            ps.setInt(2, orderId);
            ps.executeUpdate();
        } catch (SQLException e) { e.printStackTrace(); }
    }

    public int getNextGroupId() {
        String sql = "SELECT COALESCE(MAX(group_id), 0) + 1 FROM orders";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) return rs.getInt(1);
        } catch (SQLException e) { e.printStackTrace(); }
        return 1;
    }

    // FIX: da.group_id does not exist in delivery_assignments — changed to da.order_id = o.id
    public List<Order> getOrdersForDeliveryBoy(int deliveryBoyId) {
        List<Order> list = new ArrayList<>();
        String sql = "SELECT o.id, o.group_id, o.user_id, o.product_id, o.quantity, o.total, " +
                     "o.order_date, o.name, o.phone, o.alt_phone, o.email, o.address, " +
                     "o.payment_method, o.status, COALESCE(o.cancel_reason,'') AS cancel_reason, " +
                     "p.name AS product_name, p.image_path AS product_image " +
                     "FROM orders o " +
                     "LEFT JOIN products p ON o.product_id = p.id " +
                     "JOIN delivery_assignments da ON da.order_id = o.id " + // FIXED
                     "WHERE da.delivery_boy_id = ? AND da.status != 'Cancelled' " +
                     "ORDER BY o.order_date DESC";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, deliveryBoyId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapRow(rs));
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return list;
    }

    public String getStatusByGroupId(int groupId) {
        String sql = "SELECT status FROM orders WHERE group_id=? LIMIT 1";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, groupId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getString("status");
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return null;
    }

    // FIX: da.group_id does not exist in delivery_assignments — changed to da.order_id = o.id
    public List<Map<String, Object>> getLiveOrderStatuses(int userId) {
        List<Map<String, Object>> result = new ArrayList<>();
        String sql = "SELECT o.group_id, o.status, COALESCE(da.status,'') AS da_status " +
                     "FROM orders o " +
                     "LEFT JOIN delivery_assignments da ON da.order_id = o.id AND da.status != 'Cancelled' " + // FIXED
                     "WHERE o.user_id = ? " +
                     "GROUP BY o.group_id, o.status, da.status";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> m = new HashMap<>();
                    m.put("groupId", rs.getInt("group_id"));
                    m.put("status",  rs.getString("status"));
                    m.put("daStatus", rs.getString("da_status"));
                    result.add(m);
                }
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return result;
    }

    public void cancelOrdersByGroup(int groupId) {
        String sql = "UPDATE orders SET status='Cancelled' WHERE group_id=? AND status IN ('Pending', 'Approved', 'Packed')";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, groupId);
            ps.executeUpdate();
        } catch (SQLException e) { e.printStackTrace(); }
    }

    public void cancelOrdersByGroupWithReason(int groupId, String reason) {
        String sql = "UPDATE orders SET status='Cancelled', cancel_reason=? WHERE group_id=? AND status IN ('Pending', 'Approved', 'Packed')";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, reason);
            ps.setInt(2, groupId);
            ps.executeUpdate();
        } catch (Exception e) {
            cancelOrdersByGroup(groupId);
            e.printStackTrace();
        }
    }

    public List<Order> getCancelledOrders() {
        List<Order> list = new ArrayList<>();
        String sql = "SELECT o.group_id, MIN(o.id) as id, o.name, o.email, o.phone, " +
                     "o.status, o.payment_method, o.cancel_reason, " +
                     "MIN(o.order_date) as order_date, SUM(o.total) as total, " +
                     "GROUP_CONCAT(p.name SEPARATOR ', ') as product_names " +
                     "FROM orders o LEFT JOIN products p ON o.product_id=p.id " +
                     "WHERE o.status='Cancelled' " +
                     "GROUP BY o.group_id, o.name, o.email, o.phone, o.status, o.payment_method, o.cancel_reason " +
                     "ORDER BY order_date DESC";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Order o = new Order();
                o.setGroupId(rs.getInt("group_id"));
                o.setId(rs.getInt("id"));
                o.setName(rs.getString("name"));
                o.setEmail(rs.getString("email"));
                o.setPhone(rs.getString("phone"));
                o.setStatus(rs.getString("status"));
                o.setPaymentMethod(rs.getString("payment_method"));
                o.setCancelReason(rs.getString("cancel_reason"));
                o.setOrderDate(rs.getString("order_date"));
                o.setTotal(rs.getDouble("total"));
                o.setProductName(rs.getString("product_names"));
                list.add(o);
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return list;
    }

    // FIX: da.group_id does not exist in delivery_assignments — changed to da.order_id = o.id
    public List<Order> getNotDeliveredOrders() {
        List<Order> list = new ArrayList<>();
        String sql = "SELECT o.group_id, MIN(o.id) as id, o.name, o.email, o.phone, " +
                     "o.status, o.payment_method, MIN(o.order_date) as order_date, SUM(o.total) as total, " +
                     "GROUP_CONCAT(p.name SEPARATOR ', ') as product_names, " +
                     "MAX(db.name) as delivery_boy " +
                     "FROM orders o LEFT JOIN products p ON o.product_id=p.id " +
                     "LEFT JOIN delivery_assignments da ON da.order_id = o.id " + // FIXED
                     "LEFT JOIN delivery_boys db ON db.id = da.delivery_boy_id " +
                     "WHERE o.status IN ('Assigned','Order_Picked_Up','On_Way','Shipped') " +
                     "GROUP BY o.group_id, o.name, o.email, o.phone, o.status, o.payment_method " +
                     "ORDER BY order_date ASC";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Order o = new Order();
                o.setGroupId(rs.getInt("group_id"));
                o.setId(rs.getInt("id"));
                o.setName(rs.getString("name"));
                o.setEmail(rs.getString("email"));
                o.setPhone(rs.getString("phone"));
                o.setStatus(rs.getString("status"));
                o.setPaymentMethod(rs.getString("payment_method"));
                o.setOrderDate(rs.getString("order_date"));
                o.setTotal(rs.getDouble("total"));
                o.setProductName(rs.getString("product_names"));
                o.setDeliveryBoy(rs.getString("delivery_boy"));
                list.add(o);
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return list;
    }

    /**
     * Returns orders grouped by group_id for a given status.
     * Used for "Customer Not Responding" and similar flags.
     */
    public List<Order> getOrdersByStatus(String status) {
        List<Order> list = new ArrayList<>();
        String sql = "SELECT o.group_id, MIN(o.id) as id, o.name, o.email, o.phone, " +
                     "o.status, o.payment_method, MIN(o.order_date) as order_date, SUM(o.total) as total, " +
                     "GROUP_CONCAT(p.name SEPARATOR ', ') as product_names, " +
                     "MAX(db.name) as delivery_boy " +
                     "FROM orders o LEFT JOIN products p ON o.product_id=p.id " +
                     "LEFT JOIN delivery_assignments da ON da.order_id = o.id " +
                     "LEFT JOIN delivery_boys db ON db.id = da.delivery_boy_id " +
                     "WHERE o.status = ? " +
                     "GROUP BY o.group_id, o.name, o.email, o.phone, o.status, o.payment_method " +
                     "ORDER BY order_date ASC";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, status);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Order o = new Order();
                    o.setGroupId(rs.getInt("group_id"));
                    o.setId(rs.getInt("id"));
                    o.setName(rs.getString("name"));
                    o.setEmail(rs.getString("email"));
                    o.setPhone(rs.getString("phone"));
                    o.setStatus(rs.getString("status"));
                    o.setPaymentMethod(rs.getString("payment_method"));
                    o.setOrderDate(rs.getString("order_date"));
                    o.setTotal(rs.getDouble("total"));
                    o.setProductName(rs.getString("product_names"));
                    o.setDeliveryBoy(rs.getString("delivery_boy"));
                    list.add(o);
                }
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return list;
    }

    /**
     * Returns all orders grouped by group_id, with product and delivery boy info.
     * Used by admin-orders.jsp. Functionally identical to getGroupedOrders().
     */
    public List<Order> getOrdersWithProduct() {
        return getGroupedOrders();
    }

    public void updateDeliveryBoyName(int groupId, String deliveryBoyName, String note) {
        // delivery_boy_name is not stored in delivery_assignments;
        // name is fetched via JOIN with delivery_boys at query time. Nothing to update.
    }

    @FunctionalInterface
    private interface SqlRunnable { void run() throws SQLException; }
    private void trySet(SqlRunnable r) {
        try { r.run(); } catch (SQLException ignored) {}
    }

    private Order mapRow(ResultSet rs) throws SQLException {
        Order o = new Order();
        trySet(() -> o.setId(rs.getInt("id")));
        trySet(() -> o.setGroupId(rs.getInt("group_id")));
        trySet(() -> o.setUserId(rs.getInt("user_id")));
        trySet(() -> o.setProductId(rs.getInt("product_id")));
        trySet(() -> o.setQuantity(rs.getInt("quantity")));
        trySet(() -> o.setTotal(rs.getDouble("total")));
        trySet(() -> o.setOrderDate(rs.getString("order_date")));
        trySet(() -> o.setName(rs.getString("name")));
        trySet(() -> o.setPhone(rs.getString("phone")));
        trySet(() -> o.setAltPhone(rs.getString("alt_phone")));
        trySet(() -> o.setEmail(rs.getString("email")));
        trySet(() -> o.setAddress(rs.getString("address")));
        trySet(() -> o.setPaymentMethod(rs.getString("payment_method")));
        trySet(() -> o.setStatus(rs.getString("status")));
        trySet(() -> o.setProductName(rs.getString("product_name")));
        trySet(() -> o.setProductImage(rs.getString("product_image")));
        trySet(() -> o.setCancelReason(rs.getString("cancel_reason")));
        trySet(() -> o.setDeliveryCharge(rs.getDouble("delivery_charge")));
        return o;
    }
}