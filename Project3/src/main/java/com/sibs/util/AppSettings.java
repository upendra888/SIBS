package com.sibs.util;

import java.sql.*;

/**
 * AppSettings — reads / writes the app_settings table.
 *
 * Table is created automatically on first use:
 *   app_settings (key VARCHAR PK, value VARCHAR)
 *
 * Usage:
 *   double rate = AppSettings.getDouble("per_delivery_pay", 40.0);
 *   AppSettings.set("per_delivery_pay", "60");
 */
public class AppSettings {

    private static final String CREATE_SQL =
        "CREATE TABLE IF NOT EXISTS app_settings (" +
        "  `key`   VARCHAR(100) NOT NULL PRIMARY KEY," +
        "  `value` VARCHAR(500) NOT NULL," +
        "  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP" +
        ")";

    // ── Default values ────────────────────────────────────────────────────────
    public static final String KEY_PER_DELIVERY_PAY = "per_delivery_pay";
    public static final double DEFAULT_PER_DELIVERY_PAY = 40.0;

    // ── Read ──────────────────────────────────────────────────────────────────

    public static String get(String key, String defaultValue) {
        try (Connection con = DBConnection.getConnection()) {
            con.createStatement().execute(CREATE_SQL);
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT `value` FROM app_settings WHERE `key` = ?")) {
                ps.setString(1, key);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) return rs.getString(1);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return defaultValue;
    }

    public static double getDouble(String key, double defaultValue) {
        try {
            return Double.parseDouble(get(key, String.valueOf(defaultValue)));
        } catch (NumberFormatException e) {
            return defaultValue;
        }
    }

    public static int getInt(String key, int defaultValue) {
        try {
            return Integer.parseInt(get(key, String.valueOf(defaultValue)));
        } catch (NumberFormatException e) {
            return defaultValue;
        }
    }

    // ── Write ─────────────────────────────────────────────────────────────────

    /**
     * Insert or update a setting.
     * Returns true on success.
     */
    public static boolean set(String key, String value) {
        try (Connection con = DBConnection.getConnection()) {
            con.createStatement().execute(CREATE_SQL);
            try (PreparedStatement ps = con.prepareStatement(
                    "INSERT INTO app_settings (`key`, `value`) VALUES (?, ?) " +
                    "ON DUPLICATE KEY UPDATE `value` = VALUES(`value`)")) {
                ps.setString(1, key);
                ps.setString(2, value);
                ps.executeUpdate();
                return true;
            }
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    // ── Convenience ───────────────────────────────────────────────────────────

    /** Returns per-delivery pay rate (₹). Defaults to ₹40 if not configured. */
    public static double getPerDeliveryPay() {
        return getDouble(KEY_PER_DELIVERY_PAY, DEFAULT_PER_DELIVERY_PAY);
    }
}