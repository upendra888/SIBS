package com.sibs.dao;

import com.sibs.model.DeliverySlot;
import com.sibs.util.DBConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * Data-Access Object for the delivery slot booking module.
 *
 * Tables used:
 *   delivery_slots          — master slot definitions (seeded once)
 *   delivery_slot_bookings  — per-day booking records
 */
public class DeliverySlotDAO {

    // ── Row mapper (booking + slot joined) ──────────────────────────────────
    private DeliverySlot mapBookingRow(ResultSet rs) throws SQLException {
        DeliverySlot s = new DeliverySlot();
        s.setSlotId(rs.getInt("slot_id"));
        s.setSlotName(rs.getString("slot_name"));
        s.setStartTime(rs.getTime("start_time"));
        s.setEndTime(rs.getTime("end_time"));
        s.setMaxCapacity(rs.getInt("max_capacity"));
        s.setActive(rs.getInt("is_active") == 1);
        // booking columns (may be null for unbooked slots)
        int bid = rs.getInt("booking_id");
        if (!rs.wasNull()) s.setBookingId(bid);
        int dbid = rs.getInt("delivery_boy_id");
        if (!rs.wasNull()) s.setDeliveryBoyId(dbid);
        s.setBookingDate(rs.getDate("booking_date"));
        s.setStatus(rs.getString("status"));
        s.setShiftStart(rs.getTime("shift_start"));
        s.setShiftEnd(rs.getTime("shift_end"));
        s.setWorkingHours(rs.getString("working_hours"));
        return s;
    }

    // ────────────────────────────────────────────────────────────────────────
    //  1. GET ALL SLOTS WITH TODAY'S AVAILABILITY  (delivery boy view)
    //     Returns all active slots annotated with:
    //       - booked_count: how many boys booked this slot today
    //       - this boy's booking row if it exists (or nulls)
    // ────────────────────────────────────────────────────────────────────────
    public List<DeliverySlot> getSlotsForBoy(int deliveryBoyId) {
        String sql =
            "SELECT ds.slot_id, ds.slot_name, ds.start_time, ds.end_time, " +
            "       ds.max_capacity, ds.is_active, " +
            // count ALL bookings for this slot today (not just this boy)
            "  (SELECT COUNT(*) FROM delivery_slot_bookings b2 " +
            "   WHERE b2.slot_id = ds.slot_id AND b2.booking_date = CURDATE() " +
            "     AND b2.status != 'CANCELLED') AS booked_count, " +
            // this delivery boy's own LATEST active booking for this slot today
            "  my.booking_id, my.delivery_boy_id, my.booking_date, " +
            "  my.status, my.shift_start, my.shift_end, my.working_hours " +
            "FROM   delivery_slots ds " +
            "LEFT JOIN delivery_slot_bookings my " +
            "       ON my.booking_id = (" +
            "           SELECT booking_id FROM delivery_slot_bookings " +
            "           WHERE slot_id = ds.slot_id AND delivery_boy_id = ? " +
            "             AND booking_date = CURDATE() " +
            "           ORDER BY FIELD(status,'ACTIVE','BOOKED','COMPLETED','CANCELLED') " +
            "           LIMIT 1) " +
            "WHERE  ds.is_active = 1 " +
            "ORDER  BY ds.start_time";

        // Use LinkedHashMap keyed by slot_id — guarantees one row per slot, preserves order
        java.util.LinkedHashMap<Integer, DeliverySlot> map = new java.util.LinkedHashMap<>();
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, deliveryBoyId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    DeliverySlot slot = mapBookingRow(rs);
                    slot.setBookedCount(rs.getInt("booked_count"));
                    map.putIfAbsent(slot.getSlotId(), slot); // keep first (highest-priority) row only
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return new ArrayList<>(map.values());
    }

    // ────────────────────────────────────────────────────────────────────────
    //  2b. GET ALL TODAY'S BOOKINGS for one delivery boy (list)
    // ────────────────────────────────────────────────────────────────────────
    public List<DeliverySlot> getTodayBookings(int deliveryBoyId) {
        String sql =
            "SELECT ds.slot_id, ds.slot_name, ds.start_time, ds.end_time, " +
            "       ds.max_capacity, ds.is_active, " +
            "  (SELECT COUNT(*) FROM delivery_slot_bookings b2 " +
            "   WHERE b2.slot_id = ds.slot_id AND b2.booking_date = CURDATE() " +
            "     AND b2.status != 'CANCELLED') AS booked_count, " +
            "  b.booking_id, b.delivery_boy_id, b.booking_date, " +
            "  b.status, b.shift_start, b.shift_end, b.working_hours " +
            "FROM   delivery_slot_bookings b " +
            "JOIN   delivery_slots ds ON ds.slot_id = b.slot_id " +
            "WHERE  b.delivery_boy_id = ? AND b.booking_date = CURDATE() " +
            "  AND  b.status != 'CANCELLED' " +
            "ORDER  BY ds.start_time";

        List<DeliverySlot> list = new ArrayList<>();
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, deliveryBoyId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    DeliverySlot slot = mapBookingRow(rs);
                    slot.setBookedCount(rs.getInt("booked_count"));
                    list.add(slot);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    // ────────────────────────────────────────────────────────────────────────
    //  2. GET TODAY'S BOOKING for one delivery boy  (single record)
    //     FIX: Excludes CANCELLED bookings so the boy can re-book freely.
    // ────────────────────────────────────────────────────────────────────────
    public DeliverySlot getTodayBooking(int deliveryBoyId) {
        String sql =
            "SELECT ds.slot_id, ds.slot_name, ds.start_time, ds.end_time, " +
            "       ds.max_capacity, ds.is_active, " +
            "  (SELECT COUNT(*) FROM delivery_slot_bookings b2 " +
            "   WHERE b2.slot_id = ds.slot_id AND b2.booking_date = CURDATE() " +
            "     AND b2.status != 'CANCELLED') AS booked_count, " +
            "  b.booking_id, b.delivery_boy_id, b.booking_date, " +
            "  b.status, b.shift_start, b.shift_end, b.working_hours " +
            "FROM   delivery_slot_bookings b " +
            "JOIN   delivery_slots ds ON ds.slot_id = b.slot_id " +
            "WHERE  b.delivery_boy_id = ? AND b.booking_date = CURDATE() " +
            "  AND  b.status != 'CANCELLED' " +
            "ORDER BY FIELD(b.status,'ACTIVE','BOOKED','COMPLETED') " +
            "LIMIT 1";  // prioritise ACTIVE > BOOKED > COMPLETED

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, deliveryBoyId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    DeliverySlot slot = mapBookingRow(rs);
                    slot.setBookedCount(rs.getInt("booked_count"));
                    return slot;
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    // ────────────────────────────────────────────────────────────────────────
    //  3. BOOK A SLOT  (auto-confirm, no approval needed)
    //     Returns "ok", "already_booked", "slot_full", or "error".
    // ────────────────────────────────────────────────────────────────────────
    public String bookSlot(int deliveryBoyId, int slotId) {
        try (Connection con = DBConnection.getConnection()) {
            con.setAutoCommit(false);
            try {
                // Check if this boy already has this specific slot booked/active today
                String checkBoy =
                    "SELECT booking_id FROM delivery_slot_bookings " +
                    "WHERE delivery_boy_id = ? AND slot_id = ? AND booking_date = CURDATE() " +
                    "AND status IN ('BOOKED','ACTIVE')";
                try (PreparedStatement ps = con.prepareStatement(checkBoy)) {
                    ps.setInt(1, deliveryBoyId);
                    ps.setInt(2, slotId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) { con.rollback(); return "already_booked"; }
                    }
                }

                // Check capacity — simple SELECT, no FOR UPDATE subquery
                String checkCap =
                    "SELECT ds.max_capacity, " +
                    "  COUNT(b.booking_id) AS booked_count " +
                    "FROM delivery_slots ds " +
                    "LEFT JOIN delivery_slot_bookings b " +
                    "  ON b.slot_id = ds.slot_id AND b.booking_date = CURDATE() AND b.status != 'CANCELLED' " +
                    "WHERE ds.slot_id = ? AND ds.is_active = 1 " +
                    "GROUP BY ds.slot_id, ds.max_capacity";
                try (PreparedStatement ps = con.prepareStatement(checkCap)) {
                    ps.setInt(1, slotId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) { con.rollback(); return "error"; }
                        int max    = rs.getInt("max_capacity");
                        int booked = rs.getInt("booked_count");
                        if (booked >= max) { con.rollback(); return "slot_full"; }
                    }
                }

                // Insert booking
                String insert =
                    "INSERT INTO delivery_slot_bookings " +
                    "  (slot_id, delivery_boy_id, booking_date, status) " +
                    "VALUES (?, ?, CURDATE(), 'BOOKED')";
                try (PreparedStatement ps = con.prepareStatement(insert)) {
                    ps.setInt(1, slotId);
                    ps.setInt(2, deliveryBoyId);
                    ps.executeUpdate();
                }

                con.commit();
                return "ok";

            } catch (Exception e) {
                con.rollback();
                e.printStackTrace();
                return "error";
            } finally {
                con.setAutoCommit(true);
            }
        } catch (Exception e) {
            e.printStackTrace();
            return "error";
        }
    }
    // ────────────────────────────────────────────────────────────────────────
    //  4. START SHIFT
    //     Changes status BOOKED → ACTIVE, records shift_start = NOW().
    // ────────────────────────────────────────────────────────────────────────
    // Legacy no-arg version: finds the earliest BOOKED slot today by doing a SELECT first,
    // then updating by booking_id — avoids MySQL's restriction on ORDER BY/LIMIT in UPDATE.
    public String startShift(int deliveryBoyId) {
        String findSql =
            "SELECT b.booking_id " +
            "FROM   delivery_slot_bookings b " +
            "JOIN   delivery_slots ds ON ds.slot_id = b.slot_id " +
            "WHERE  b.delivery_boy_id = ? AND b.booking_date = CURDATE() AND b.status = 'BOOKED' " +
            "ORDER BY ds.start_time LIMIT 1";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(findSql)) {
            ps.setInt(1, deliveryBoyId);
            try (java.sql.ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) return "not_found";
                return startShift(deliveryBoyId, rs.getInt("booking_id"), con);
            }
        } catch (Exception e) {
            e.printStackTrace();
            return "error";
        }
    }

    // Main startShift — always targets a specific bookingId (no ambiguity, no subquery UPDATE).
    public String startShift(int deliveryBoyId, int bookingId) {
        try (Connection con = DBConnection.getConnection()) {
            return startShift(deliveryBoyId, bookingId, con);
        } catch (Exception e) {
            e.printStackTrace();
            return "error";
        }
    }

    private String startShift(int deliveryBoyId, int bookingId, Connection con) throws Exception {
        // 1. Fetch slot start_time for this specific booking
        String checkSql =
            "SELECT ds.start_time " +
            "FROM   delivery_slot_bookings b " +
            "JOIN   delivery_slots ds ON ds.slot_id = b.slot_id " +
            "WHERE  b.booking_id = ? AND b.delivery_boy_id = ? " +
            "  AND  b.booking_date = CURDATE() AND b.status = 'BOOKED'";
        java.sql.Time slotStart;
        try (PreparedStatement ps = con.prepareStatement(checkSql)) {
            ps.setInt(1, bookingId);
            ps.setInt(2, deliveryBoyId);
            try (java.sql.ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) return "not_found";
                slotStart = rs.getTime("start_time");
            }
        }

        // 2. Block early start
        java.time.LocalTime now = java.time.LocalTime.now();
        java.time.LocalTime slotStartLocal = slotStart.toLocalTime();
        if (now.isBefore(slotStartLocal)) {
            return "too_early:" + slotStartLocal.toString().substring(0, 5);
        }

        // 3. Mark ACTIVE — simple PK-based UPDATE, no ORDER BY/LIMIT needed
        String updateSql =
            "UPDATE delivery_slot_bookings " +
            "SET    status = 'ACTIVE', shift_start = CURTIME() " +
            "WHERE  booking_id = ? AND delivery_boy_id = ? " +
            "  AND  booking_date = CURDATE() AND status = 'BOOKED'";
        try (PreparedStatement ps = con.prepareStatement(updateSql)) {
            ps.setInt(1, bookingId);
            ps.setInt(2, deliveryBoyId);
            return ps.executeUpdate() > 0 ? "ok" : "not_found";
        }
    }

    // ────────────────────────────────────────────────────────────────────────
    //  5. END SHIFT
    //     Changes status ACTIVE → COMPLETED, records shift_end and
    //     calculates working_hours = shift_end − shift_start.
    // ────────────────────────────────────────────────────────────────────────
    public boolean endShift(int deliveryBoyId) {
        String sql =
            "UPDATE delivery_slot_bookings " +
            "SET    status        = 'COMPLETED', " +
            "       shift_end     = CURTIME(), " +
            "       working_hours = LEFT( " +
            "         SEC_TO_TIME(GREATEST(0, TIME_TO_SEC(TIMEDIFF(CURTIME(), shift_start)))), " +
            "         5) " +         // "HH:MM"
            "WHERE  delivery_boy_id = ? " +
            "  AND  booking_date    = CURDATE() " +
            "  AND  status          = 'ACTIVE'";

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, deliveryBoyId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    // ────────────────────────────────────────────────────────────────────────
    //  6b. CANCEL SPECIFIC BOOKING by booking_id
    // ────────────────────────────────────────────────────────────────────────
    public boolean cancelBookingById(int bookingId, int deliveryBoyId) {
        String sql =
            "UPDATE delivery_slot_bookings " +
            "SET    status = 'CANCELLED' " +
            "WHERE  booking_id = ? AND delivery_boy_id = ? AND status = 'BOOKED'";

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, bookingId);
            ps.setInt(2, deliveryBoyId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    // ────────────────────────────────────────────────────────────────────────
    //  6. CANCEL BOOKING  (before shift starts)
    // ────────────────────────────────────────────────────────────────────────
    public boolean cancelBooking(int deliveryBoyId) {
        String sql =
            "UPDATE delivery_slot_bookings " +
            "SET    status = 'CANCELLED' " +
            "WHERE  delivery_boy_id = ? " +
            "  AND  booking_date    = CURDATE() " +
            "  AND  status          = 'BOOKED'";  // cannot cancel an active shift

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, deliveryBoyId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    // ────────────────────────────────────────────────────────────────────────
    //  7. ADMIN — ALL BOOKINGS FOR TODAY  (with delivery boy names)
    // ────────────────────────────────────────────────────────────────────────
    public List<DeliverySlot> getTodayAllBookings() {
        String sql =
            "SELECT ds.slot_id, ds.slot_name, ds.start_time, ds.end_time, " +
            "       ds.max_capacity, ds.is_active, " +
            "  (SELECT COUNT(*) FROM delivery_slot_bookings b2 " +
            "   WHERE b2.slot_id = ds.slot_id AND b2.booking_date = CURDATE() " +
            "     AND b2.status != 'CANCELLED') AS booked_count, " +
            "  b.booking_id, b.delivery_boy_id, b.booking_date, " +
            "  b.status, b.shift_start, b.shift_end, b.working_hours, " +
            "  db.name AS delivery_boy_name " +
            "FROM   delivery_slot_bookings b " +
            "JOIN   delivery_slots ds  ON ds.slot_id  = b.slot_id " +
            "JOIN   delivery_boys  db  ON db.id = b.delivery_boy_id " +
            "WHERE  b.booking_date = CURDATE() " +
            "ORDER  BY ds.start_time, db.name";

        List<DeliverySlot> list = new ArrayList<>();
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                DeliverySlot slot = mapBookingRow(rs);
                slot.setBookedCount(rs.getInt("booked_count"));
                slot.setDeliveryBoyName(rs.getString("delivery_boy_name"));
                list.add(slot);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    // ────────────────────────────────────────────────────────────────────────
    //  8. ADMIN — SLOT UTILIZATION SUMMARY  (for summary cards)
    //     Returns one DeliverySlot per master slot (with booked_count).
    // ────────────────────────────────────────────────────────────────────────
    public List<DeliverySlot> getSlotUtilizationToday() {
        String sql =
            "SELECT ds.slot_id, ds.slot_name, ds.start_time, ds.end_time, " +
            "       ds.max_capacity, ds.is_active, " +
            "  (SELECT COUNT(*) FROM delivery_slot_bookings b " +
            "   WHERE b.slot_id = ds.slot_id AND b.booking_date = CURDATE() " +
            "     AND b.status != 'CANCELLED') AS booked_count, " +
            "  NULL AS booking_id, NULL AS delivery_boy_id, NULL AS booking_date, " +
            "  NULL AS status, NULL AS shift_start, NULL AS shift_end, NULL AS working_hours " +
            "FROM   delivery_slots ds " +
            "WHERE  ds.is_active = 1 " +
            "ORDER  BY ds.start_time";

        List<DeliverySlot> list = new ArrayList<>();
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                DeliverySlot slot = mapBookingRow(rs);
                slot.setBookedCount(rs.getInt("booked_count"));
                list.add(slot);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    // ────────────────────────────────────────────────────────────────────────
    // 10. AUTO-EXPIRY — cancel BOOKED slots whose end_time has already passed
    //     Called on every SlotStatusServlet poll so stale bookings are cleaned
    //     up automatically without a scheduler.
    //     A slot is "stale" when it is still BOOKED (never started) and the
    //     slot's end_time is in the past.
    // ────────────────────────────────────────────────────────────────────────
    public int expireStaleSlots() {
        String sql =
            "UPDATE delivery_slot_bookings b " +
            "JOIN   delivery_slots ds ON ds.slot_id = b.slot_id " +
            "SET    b.status = 'CANCELLED' " +
            "WHERE  b.booking_date = CURDATE() " +
            "  AND  b.status       = 'BOOKED' " +
            "  AND  ds.end_time    < CURTIME()";   // slot window has passed

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            return ps.executeUpdate();             // returns # of rows expired
        } catch (Exception e) {
            e.printStackTrace();
            return 0;
        }
    }

    // ────────────────────────────────────────────────────────────────────────
    //  9. ADMIN — MONTHLY REPORT  (year + month as 1-12)
    // ────────────────────────────────────────────────────────────────────────
    public List<DeliverySlot> getMonthlyReport(int year, int month) {
        String sql =
            "SELECT ds.slot_id, ds.slot_name, ds.start_time, ds.end_time, " +
            "       ds.max_capacity, ds.is_active, 0 AS booked_count, " +
            "  b.booking_id, b.delivery_boy_id, b.booking_date, " +
            "  b.status, b.shift_start, b.shift_end, b.working_hours, " +
            "  db.name AS delivery_boy_name " +
            "FROM   delivery_slot_bookings b " +
            "JOIN   delivery_slots ds ON ds.slot_id  = b.slot_id " +
            "JOIN   delivery_boys  db ON db.id = b.delivery_boy_id " +
            "WHERE  YEAR(b.booking_date) = ? AND MONTH(b.booking_date) = ? " +
            "ORDER  BY b.booking_date DESC, ds.start_time";

        List<DeliverySlot> list = new ArrayList<>();
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, year);
            ps.setInt(2, month);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    DeliverySlot slot = mapBookingRow(rs);
                    slot.setDeliveryBoyName(rs.getString("delivery_boy_name"));
                    list.add(slot);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }
}