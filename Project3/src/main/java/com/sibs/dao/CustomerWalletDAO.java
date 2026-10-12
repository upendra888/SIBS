package com.sibs.dao;

import com.sibs.util.DBConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * CustomerWalletDAO — manages customer store-credit wallet.
 * Used for refunds credited back as wallet balance.
 * Tables auto-created on first use.
 */
public class CustomerWalletDAO {

    private static final String CREATE_WALLET_TABLE =
        "CREATE TABLE IF NOT EXISTS customer_wallet (" +
        "  user_id     INT PRIMARY KEY," +
        "  balance     DECIMAL(10,2) NOT NULL DEFAULT 0.00," +
        "  updated_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP" +
        ")";

    private static final String CREATE_TXN_TABLE =
        "CREATE TABLE IF NOT EXISTS customer_wallet_transactions (" +
        "  id          INT AUTO_INCREMENT PRIMARY KEY," +
        "  user_id     INT NOT NULL," +
        "  amount      DECIMAL(10,2) NOT NULL," +
        "  type        ENUM('CREDIT','DEBIT') NOT NULL," +
        "  reason      VARCHAR(500)," +
        "  ref_order_id INT DEFAULT NULL," +
        "  created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP" +
        ")";

    private void ensureTables(Connection con) throws SQLException {
        con.createStatement().execute(CREATE_WALLET_TABLE);
        con.createStatement().execute(CREATE_TXN_TABLE);
    }

    /** Get current wallet balance for a customer. */
    public double getBalance(int userId) {
        try (Connection con = DBConnection.getConnection()) {
            ensureTables(con);
            PreparedStatement ps = con.prepareStatement(
                "SELECT balance FROM customer_wallet WHERE user_id=?");
            ps.setInt(1, userId);
            ResultSet rs = ps.executeQuery();
            return rs.next() ? rs.getDouble("balance") : 0.0;
        } catch (SQLException e) {
            e.printStackTrace();
            return 0.0;
        }
    }

    /**
     * Credit wallet (e.g. refund). Creates wallet row if not exists.
     * @return new balance, or -1 on error.
     */
    public double credit(int userId, double amount, String reason, Integer refOrderId) {
        try (Connection con = DBConnection.getConnection()) {
            ensureTables(con);
            con.setAutoCommit(false);
            try {
                // Upsert wallet row
                PreparedStatement upsert = con.prepareStatement(
                    "INSERT INTO customer_wallet (user_id, balance) VALUES (?, ?) " +
                    "ON DUPLICATE KEY UPDATE balance = balance + VALUES(balance)");
                upsert.setInt(1, userId);
                upsert.setDouble(2, amount);
                upsert.executeUpdate();

                // Log transaction
                PreparedStatement log = con.prepareStatement(
                    "INSERT INTO customer_wallet_transactions (user_id, amount, type, reason, ref_order_id) " +
                    "VALUES (?, ?, 'CREDIT', ?, ?)");
                log.setInt(1, userId);
                log.setDouble(2, amount);
                log.setString(3, reason);
                if (refOrderId != null) log.setInt(4, refOrderId); else log.setNull(4, Types.INTEGER);
                log.executeUpdate();

                con.commit();

                // Return new balance
                return getBalance(userId);
            } catch (SQLException e) {
                con.rollback();
                throw e;
            } finally {
                con.setAutoCommit(true);
            }
        } catch (SQLException e) {
            e.printStackTrace();
            return -1;
        }
    }

    /**
     * Debit wallet (e.g. used at checkout). Returns new balance or -1 on error/insufficient funds.
     */
    public double debit(int userId, double amount, String reason, Integer refOrderId) {
        try (Connection con = DBConnection.getConnection()) {
            ensureTables(con);
            con.setAutoCommit(false);
            try {
                // Check balance first
                PreparedStatement check = con.prepareStatement(
                    "SELECT balance FROM customer_wallet WHERE user_id=? FOR UPDATE");
                check.setInt(1, userId);
                ResultSet rs = check.executeQuery();
                double current = rs.next() ? rs.getDouble("balance") : 0.0;
                if (current < amount) {
                    con.rollback();
                    return -1; // Insufficient
                }

                // Deduct
                PreparedStatement deduct = con.prepareStatement(
                    "UPDATE customer_wallet SET balance = balance - ? WHERE user_id=?");
                deduct.setDouble(1, amount);
                deduct.setInt(2, userId);
                deduct.executeUpdate();

                // Log
                PreparedStatement log = con.prepareStatement(
                    "INSERT INTO customer_wallet_transactions (user_id, amount, type, reason, ref_order_id) " +
                    "VALUES (?, ?, 'DEBIT', ?, ?)");
                log.setInt(1, userId);
                log.setDouble(2, amount);
                log.setString(3, reason);
                if (refOrderId != null) log.setInt(4, refOrderId); else log.setNull(4, Types.INTEGER);
                log.executeUpdate();

                con.commit();
                return getBalance(userId);
            } catch (SQLException e) {
                con.rollback();
                throw e;
            } finally {
                con.setAutoCommit(true);
            }
        } catch (SQLException e) {
            e.printStackTrace();
            return -1;
        }
    }

    /** Get transaction history for a customer (latest 30). */
    public List<String[]> getTransactions(int userId) {
        List<String[]> list = new ArrayList<>();
        try (Connection con = DBConnection.getConnection()) {
            ensureTables(con);
            PreparedStatement ps = con.prepareStatement(
                "SELECT amount, type, reason, ref_order_id, created_at " +
                "FROM customer_wallet_transactions " +
                "WHERE user_id=? ORDER BY created_at DESC LIMIT 30");
            ps.setInt(1, userId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                list.add(new String[]{
                    String.valueOf(rs.getDouble("amount")),
                    rs.getString("type"),
                    rs.getString("reason"),
                    rs.getString("ref_order_id"),
                    rs.getString("created_at")
                });
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }
}