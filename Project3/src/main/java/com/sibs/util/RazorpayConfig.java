package com.sibs.util;

import java.io.InputStream;
import java.util.Properties;

import jakarta.servlet.ServletContext;

/**
 * Loads Razorpay credentials from environment variables, servlet context init parameters,
 * or classpath {@code razorpay.properties} (copy from razorpay.properties.example).
 */
public final class RazorpayConfig {

    private static final Properties FILE_PROPS = loadFileProps();

    private RazorpayConfig() {}

    private static Properties loadFileProps() {
        Properties p = new Properties();
        try (InputStream in = RazorpayConfig.class.getClassLoader()
                .getResourceAsStream("razorpay.properties")) {
            if (in != null) p.load(in);
        } catch (Exception ignored) {}
        return p;
    }

    public static String keyId(ServletContext ctx) {
        String v = System.getenv("RAZORPAY_KEY_ID");
        if (v != null && !v.isBlank()) return v.trim();
        if (ctx != null) {
            v = ctx.getInitParameter("razorpay.key.id");
            if (v != null && !v.isBlank()) return v.trim();
        }
        v = FILE_PROPS.getProperty("razorpay.key.id");
        if (v != null && !v.isBlank()) return v.trim();
        v = System.getProperty("razorpay.key.id");
        return v != null ? v.trim() : "";
    }

    public static String keySecret(ServletContext ctx) {
        String v = System.getenv("RAZORPAY_KEY_SECRET");
        if (v != null && !v.isBlank()) return v.trim();
        if (ctx != null) {
            v = ctx.getInitParameter("razorpay.key.secret");
            if (v != null && !v.isBlank()) return v.trim();
        }
        v = FILE_PROPS.getProperty("razorpay.key.secret");
        if (v != null && !v.isBlank()) return v.trim();
        v = System.getProperty("razorpay.key.secret");
        return v != null ? v.trim() : "";
    }

    public static String basicAuth(ServletContext ctx) {
        String id = keyId(ctx);
        String secret = keySecret(ctx);
        if (id.isEmpty() || secret.isEmpty()) {
            return null;
        }
        return java.util.Base64.getEncoder()
                .encodeToString((id + ":" + secret).getBytes(java.nio.charset.StandardCharsets.UTF_8));
    }
}
