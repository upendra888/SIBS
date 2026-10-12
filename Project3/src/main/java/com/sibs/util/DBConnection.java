package com.sibs.util;

import java.io.InputStream;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Properties;

/**
 * Database connection — credentials loaded from db.properties on classpath.
 * No hardcoded credentials.
 */
public class DBConnection {

    private static final String URL;
    private static final String USERNAME;
    private static final String PASSWORD;

    static {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");

            InputStream in = DBConnection.class
                    .getClassLoader()
                    .getResourceAsStream("db.properties");

            if (in != null) {
                Properties props = new Properties();
                props.load(in);
                URL      = props.getProperty("db.url");
                USERNAME = props.getProperty("db.username");
                PASSWORD = props.getProperty("db.password");
            } else {
                throw new IllegalStateException(
                    "db.properties not found on classpath. " +
                    "Ensure src/main/java/resources is added as a source folder in Build Path.");
            }

        } catch (Exception e) {
            throw new ExceptionInInitializerError("DB init failed: " + e.getMessage());
        }
    }

    public static Connection getConnection() throws SQLException {
        return DriverManager.getConnection(URL, USERNAME, PASSWORD);
    }

    public static void shutdown() {
        // Nothing to close for DriverManager-based connections
    }
}