package com.sibs.listener;

import com.sibs.util.DBConnection;
import jakarta.servlet.ServletContextEvent;
import jakarta.servlet.ServletContextListener;
import jakarta.servlet.annotation.WebListener;

/**
 * Gracefully shuts down the HikariCP connection pool when the application stops.
 * Without this, Tomcat may log a warning about abandoned connections on undeploy.
 */
@WebListener
public class AppContextListener implements ServletContextListener {

    @Override
    public void contextInitialized(ServletContextEvent sce) {
        // Pool is initialized lazily on first getConnection() call via DBConnection static block
    }

    @Override
    public void contextDestroyed(ServletContextEvent sce) {
        DBConnection.shutdown();
    }
}