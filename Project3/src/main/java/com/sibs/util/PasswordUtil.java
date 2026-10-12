package com.sibs.util;

import java.nio.charset.StandardCharsets;

import org.mindrot.jbcrypt.BCrypt;

/**
 * Password hashing using BCrypt.
 *
 * BCrypt automatically generates and embeds a per-password salt,
 * making rainbow-table attacks infeasible — unlike bare SHA-256.
 *
 * Required jar (place in WEB-INF/lib):
 *   jbcrypt-0.4.jar
 *
 * ⚠️  MIGRATION NOTE:
 *   Existing users have SHA-256 hashed passwords in the DB.
 *   Use PasswordUtil.needsMigration(storedHash) to detect old hashes,
 *   then re-hash on the user's next successful login.
 *   See LoginServlet / CustomerLoginServlet for where to add this logic.
 */
public class PasswordUtil {

    // BCrypt work factor — 12 is a good balance of security vs speed (~250 ms on modern hardware).
    // Increase to 13 or 14 for higher security at the cost of slower logins.
    private static final int WORK_FACTOR = 12;

    /**
     * Hashes a plain-text password with BCrypt.
     * A unique salt is generated automatically.
     */
    public static String hashPassword(String plainPassword) {
        return BCrypt.hashpw(plainPassword, BCrypt.gensalt(WORK_FACTOR));
    }

    /**
     * Verifies a plain-text password against a stored BCrypt hash.
     */
    public static boolean checkPassword(String plainPassword, String storedHash) {
        if (storedHash == null) return false;
        
        // BCrypt hash అయితే
        if (storedHash.startsWith("$2")) {
            try {
                return BCrypt.checkpw(plainPassword, storedHash);
            } catch (IllegalArgumentException e) {
                return false;
            }
        }
        
        // Legacy SHA-256 hex hash
        if (needsMigration(storedHash)) {
            return legacySHA256(plainPassword).equals(storedHash);
        }

        return false;
    }

    /**
     * Returns true if the stored hash looks like a legacy SHA-256 hex string
     * (64 hex chars) rather than a BCrypt hash (which starts with "$2a$", "$2b$", etc.).
     *
     * Use this during login to detect accounts that still have the old hash format
     * and trigger an on-the-fly migration.
     */
    public static boolean needsMigration(String storedHash) {
        return storedHash != null
                && storedHash.length() == 64
                && storedHash.matches("[0-9a-f]{64}");
    }

    /**
     * Legacy SHA-256 hash — kept only to verify old passwords during migration.
     * Do NOT use this for new passwords.
     *
     * @deprecated Use {@link #hashPassword(String)} and {@link #checkPassword(String, String)} instead.
     */
    @Deprecated
    public static String legacySHA256(String password) {
        try {
            java.security.MessageDigest md = java.security.MessageDigest.getInstance("SHA-256");
            byte[] hash = md.digest(password.getBytes(StandardCharsets.UTF_8));
            StringBuilder hex = new StringBuilder();
            for (byte b : hash) {
                String h = Integer.toHexString(0xff & b);
                if (h.length() == 1) hex.append('0');
                hex.append(h);
            }
            return hex.toString();
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
}