package com.sibs.servlet;

import com.sibs.dao.CodLedgerDAO;
import com.sibs.dao.NotificationDAO;
import com.sibs.model.DeliveryBoy;
import com.sibs.dao.DeliveryBoyDAO;
import com.sibs.util.AppSettings;
import com.sibs.util.DBConnection;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

/**
 * POST /codLedger
 *
 * action=remit    → single-entry remittance
 * action=remitAll → bulk remittance using earnings-first, wallet fallback:
 *
 *   LOGIC:
 *   1. Calculate pendingRemittance (amount to give staff)
 *   2. Use net earnings to cover it first
 *   3. If earnings not enough, use wallet balance for the remainder
 *   4. Mark all COLLECTED entries as REMITTED
 */
@WebServlet("/codLedger")
public class CodLedgerServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        DeliveryBoy db = session != null
                ? (DeliveryBoy) session.getAttribute("deliveryBoy") : null;

        if (db == null) {
            res.sendRedirect("delivery-login.jsp");
            return;
        }

        String action = req.getParameter("action");

        if ("remit".equals(action)) {
            // Single-entry remittance (from COD ledger page)
            String ledgerIdStr = req.getParameter("ledgerId");
            String note        = req.getParameter("note");
            if (ledgerIdStr != null) {
                int ledgerId = Integer.parseInt(ledgerIdStr.trim());
                new CodLedgerDAO().markRemitted(ledgerId, db.getId(), note);
            }
            res.sendRedirect("delivery-cash-ledger.jsp?done=1");

        } else if ("remitAll".equals(action)) {
            // ── REMITTANCE LOGIC ──
            //
            // Customer paid ₹100 COD:
            //   boy keeps ₹40 delivery charge as physical cash
            //   ₹60 (product price) must go to staff
            //
            // To pay staff ₹60:
            //   Step 1 — use net earnings (from online/prepaid deliveries × ₹40)
            //   Step 2 — if earnings not enough, use wallet balance for remainder
            //   Step 3 — if still not enough → block and show error
            try {
                CodLedgerDAO codDao = new CodLedgerDAO();

                double pendingRemittance = codDao.getPendingRemittanceTotal(db.getId());

                if (pendingRemittance <= 0) {
                    res.sendRedirect("delivery-earnings.jsp?flash=nothing_to_remit");
                    return;
                }

                // Step 1: use net earnings (Online + COD deliveries × ₹40)
                double grossEarnings  = getNetEarnings(db.getId());
                double netEarnings    = grossEarnings; // no subtraction
                double walletForCheck = getWalletBalance(db.getId());

                // ── FORCE OFFLINE CHECK ────────────────────────────────────────
                // If pending remittance exceeds (earnings + wallet) combined,
                // the boy cannot cover the amount → force him OFFLINE immediately.
                if (pendingRemittance > (netEarnings + walletForCheck)) {
                    new DeliveryBoyDAO().setShiftStatus(db.getId(), "OFFLINE");
                    db.setShiftStatus("OFFLINE");
                    session.setAttribute("deliveryBoy", db);
                    NotificationDAO.sendCodForceOffline(db.getId(), db.getName(), pendingRemittance);
                    res.sendRedirect("delivery-earnings.jsp?flash=force_offline");
                    return;
                }
                // ──────────────────────────────────────────────────────────────

                double fromEarnings   = Math.min(netEarnings, pendingRemittance);
                double remaining      = pendingRemittance - fromEarnings;

                // Record earnings consumed so the earnings display reduces
                if (fromEarnings > 0) {
                    recordEarningsUsed(db.getId(), fromEarnings,
                        "COD remittance: \u20b9" + (int)fromEarnings + " from earnings \u2014 " + db.getName());
                }

                // Step 2: cover remaining shortfall from regular wallet (delivery_boys.wallet)
                double fromWallet = 0;
                if (remaining > 0) {
                    double walletBalance = getWalletBalance(db.getId());
                    if (walletBalance < remaining) {
                        res.sendRedirect("delivery-earnings.jsp?flash=insufficient");
                        return;
                    }
                    fromWallet = remaining;
                    deductFromWallet(db.getId(), fromWallet,
                        "COD remittance: \u20b9" + (int)fromWallet + " from wallet \u2014 " + db.getName());
                }

                // Step 3: mark all COLLECTED entries as REMITTED
                String note = "COD remitted to staff"
                    + (fromEarnings > 0 ? " | \u20b9" + (int)fromEarnings + " from earnings" : "")
                    + (fromWallet   > 0 ? " | \u20b9" + (int)fromWallet   + " from wallet" : "")
                    + " \u2014 " + db.getName();
                codDao.bulkMarkRemitted(db.getId(), note);

                // Refresh session
                db.setWallet(getWalletBalance(db.getId()));
                session.setAttribute("deliveryBoy", db);

                NotificationDAO.sendCodRemitted(db.getId(), db.getName(), pendingRemittance);
                String flash = (fromWallet > 0) ? "remit_partial" : "cod_remitted";
                res.sendRedirect("delivery-earnings.jsp?flash=" + flash);

            } catch (Exception e) {
                e.printStackTrace();
                res.sendRedirect("delivery-earnings.jsp?flash=remit_error");
            }

        } else {
            res.sendRedirect("delivery-cash-ledger.jsp");
        }
    }

    /**
     * Net earnings = (Online + COD) deliveries × ₹40 today.
     */
    private double getNetEarnings(int deliveryBoyId) {
        String sql =
            "SELECT COUNT(*) FROM delivery_assignments da " +
            "WHERE da.delivery_boy_id = ? " +
            "AND UPPER(da.status) = 'DELIVERED' " +
            "AND DATE(da.delivered_at) = CURDATE()";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, deliveryBoyId);
            try (java.sql.ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1) * AppSettings.getPerDeliveryPay();
            }
        } catch (Exception e) { e.printStackTrace(); }
        return 0;
    }

    /**
     * Get wallet balance for a delivery boy from delivery_boys.wallet column.
     */
    private double getWalletBalance(int deliveryBoyId) {
        String sql = "SELECT wallet FROM delivery_boys WHERE id = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, deliveryBoyId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getDouble("wallet");
            }
        } catch (Exception e) { e.printStackTrace(); }
        return 0;
    }

    /**
     * Returns how much of today's earnings have already been used for COD remittances.
     * Stored in delivery_earnings_used table (created on first use).
     */
    private double getUsedEarnings(int deliveryBoyId) {
        String createSql =
            "CREATE TABLE IF NOT EXISTS delivery_earnings_used (" +
            "  id               INT AUTO_INCREMENT PRIMARY KEY," +
            "  delivery_boy_id  INT NOT NULL," +
            "  amount           DECIMAL(10,2) NOT NULL," +
            "  used_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP," +
            "  note             VARCHAR(500)" +
            ")";
        String selectSql =
            "SELECT COALESCE(SUM(amount),0) FROM delivery_earnings_used " +
            "WHERE delivery_boy_id=? AND DATE(used_at)=CURDATE()";
        try (Connection con = DBConnection.getConnection()) {
            con.createStatement().execute(createSql);
            try (PreparedStatement ps = con.prepareStatement(selectSql)) {
                ps.setInt(1, deliveryBoyId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) return rs.getDouble(1);
                }
            }
        } catch (Exception e) { e.printStackTrace(); }
        return 0;
    }

    /**
     * Record that earnings were consumed for a COD remittance.
     */
    private void recordEarningsUsed(int deliveryBoyId, double amount, String note) {
        String createSql =
            "CREATE TABLE IF NOT EXISTS delivery_earnings_used (" +
            "  id               INT AUTO_INCREMENT PRIMARY KEY," +
            "  delivery_boy_id  INT NOT NULL," +
            "  amount           DECIMAL(10,2) NOT NULL," +
            "  used_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP," +
            "  note             VARCHAR(500)" +
            ")";
        String insertSql =
            "INSERT INTO delivery_earnings_used (delivery_boy_id, amount, note) VALUES (?, ?, ?)";
        try (Connection con = DBConnection.getConnection()) {
            con.createStatement().execute(createSql);
            try (PreparedStatement ps = con.prepareStatement(insertSql)) {
                ps.setInt(1, deliveryBoyId);
                ps.setDouble(2, amount);
                ps.setString(3, note);
                ps.executeUpdate();
            }
        } catch (Exception e) { e.printStackTrace(); }
    }

    /**
     * Get deposit wallet balance from delivery_deposits table (CREDIT - DEBIT).
     */
    private double getDepositBalance(int deliveryBoyId) {
        String sql =
            "SELECT COALESCE(SUM(CASE WHEN type='CREDIT' THEN amount ELSE 0 END),0) - " +
            "       COALESCE(SUM(CASE WHEN type='DEBIT'  THEN amount ELSE 0 END),0) AS balance " +
            "FROM delivery_deposits WHERE delivery_boy_id=?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, deliveryBoyId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    double bal = rs.getDouble("balance");
                    return Math.max(0, bal);
                }
            }
        } catch (Exception e) { e.printStackTrace(); }
        return 0;
    }

    /**
     * Deduct amount from deposit wallet (delivery_deposits table as DEBIT entry).
     */
    private void deductFromDepositWallet(int deliveryBoyId, double amount, String note) {
        String sql = "INSERT INTO delivery_deposits (delivery_boy_id, amount, type, note, deposited_at) " +
                     "VALUES (?, ?, 'DEBIT', ?, NOW())";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, deliveryBoyId);
            ps.setDouble(2, amount);
            ps.setString(3, note);
            ps.executeUpdate();
        } catch (Exception e) { e.printStackTrace(); }
    }

    /**
     */
    private void deductFromWallet(int deliveryBoyId, double amount, String note) {
        try (Connection con = DBConnection.getConnection()) {
            // Deduct from wallet column
            try (PreparedStatement ps = con.prepareStatement(
                    "UPDATE delivery_boys SET wallet = wallet - ? WHERE id = ?")) {
                ps.setDouble(1, amount);
                ps.setInt(2, deliveryBoyId);
                ps.executeUpdate();
            }
            // Log the transaction
            con.createStatement().execute(
                "CREATE TABLE IF NOT EXISTS wallet_transactions (" +
                "  id INT AUTO_INCREMENT PRIMARY KEY," +
                "  delivery_boy_id INT NOT NULL," +
                "  amount DECIMAL(10,2) NOT NULL," +
                "  type ENUM('CREDIT','DEBIT') NOT NULL DEFAULT 'CREDIT'," +
                "  note VARCHAR(500)," +
                "  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP" +
                ")"
            );
            try (PreparedStatement ps = con.prepareStatement(
                    "INSERT INTO wallet_transactions (delivery_boy_id, amount, type, note) VALUES (?, ?, 'DEBIT', ?)")) {
                ps.setInt(1, deliveryBoyId);
                ps.setDouble(2, amount);
                ps.setString(3, note);
                ps.executeUpdate();
            }
        } catch (Exception e) { e.printStackTrace(); }
    }
}