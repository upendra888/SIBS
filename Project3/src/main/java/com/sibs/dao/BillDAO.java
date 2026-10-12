package com.sibs.dao;

import java.sql.*;
import java.util.List;

import com.sibs.model.BillItem;
import com.sibs.util.DBConnection;

public class BillDAO {

    public int saveBill(int customerId, double subtotal, double discount, double tax, double total, List<BillItem> items) throws Exception {

        Connection con = DBConnection.getConnection();
        con.setAutoCommit(false);

        try {

            String sql = "INSERT INTO bills(customer_id, subtotal, discount, tax, total_amount) VALUES(?,?,?,?,?)";
            PreparedStatement ps = con.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS);

            ps.setInt(1, customerId);
            ps.setDouble(2, subtotal);
            ps.setDouble(3, discount);
            ps.setDouble(4, tax);
            ps.setDouble(5, total);

            ps.executeUpdate();

            ResultSet rs = ps.getGeneratedKeys();
            rs.next();
            int billId = rs.getInt(1);

            String itemSql = "INSERT INTO bill_items(bill_id, product_id, quantity, price, total_price) VALUES(?,?,?,?,?)";
            PreparedStatement ps2 = con.prepareStatement(itemSql);

            for (BillItem item : items) {
                ps2.setInt(1, billId);
                ps2.setInt(2, item.getProductId());
                ps2.setInt(3, item.getQuantity());
                ps2.setDouble(4, item.getPrice());
                ps2.setDouble(5, item.getTotalPrice());
                ps2.addBatch();
            }

            ps2.executeBatch();

            con.commit();

            return billId;

        } catch (Exception e) {
            con.rollback();
            throw e;
        }
    }
}