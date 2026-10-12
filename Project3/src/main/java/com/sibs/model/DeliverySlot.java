package com.sibs.model;

import java.sql.Date;
import java.sql.Time;

/**
 * Represents a single delivery-slot booking row,
 * joined with the master slot definition.
 */
public class DeliverySlot {

    // ── Master slot fields ────────────────────────────────────
    private int    slotId;
    private String slotName;       // "Morning", "Midday", …
    private Time   startTime;
    private Time   endTime;
    private int    maxCapacity;
    private int    bookedCount;    // how many boys have booked this slot today
    private boolean active;        // is_active flag

    // ── Booking fields (null when no booking exists) ──────────
    private Integer bookingId;
    private Integer deliveryBoyId;
    private String  deliveryBoyName;
    private Date    bookingDate;
    private String  status;        // BOOKED | ACTIVE | COMPLETED | CANCELLED
    private Time    shiftStart;
    private Time    shiftEnd;
    private String  workingHours;  // "HH:MM"

    // ── Computed helpers ──────────────────────────────────────

    /** Slots still open for new bookings today. */
    public int getRemainingCapacity() {
        return Math.max(0, maxCapacity - bookedCount);
    }

    public boolean isAvailable() {
        return active && getRemainingCapacity() > 0;
    }

    public boolean isBooked()    { return "BOOKED".equals(status);    }
    public boolean isOnShift()   { return "ACTIVE".equals(status);    }
    public boolean isCompleted() { return "COMPLETED".equals(status); }
    public boolean isCancelled() { return "CANCELLED".equals(status); }

    // ── Getters / Setters ─────────────────────────────────────

    public int    getSlotId()           { return slotId; }
    public void   setSlotId(int v)      { this.slotId = v; }

    public String getSlotName()         { return slotName; }
    public void   setSlotName(String v) { this.slotName = v; }

    public Time   getStartTime()        { return startTime; }
    public void   setStartTime(Time v)  { this.startTime = v; }

    public Time   getEndTime()          { return endTime; }
    public void   setEndTime(Time v)    { this.endTime = v; }

    public int    getMaxCapacity()      { return maxCapacity; }
    public void   setMaxCapacity(int v) { this.maxCapacity = v; }

    public int    getBookedCount()      { return bookedCount; }
    public void   setBookedCount(int v) { this.bookedCount = v; }

    public boolean isActive()           { return active; }
    public void    setActive(boolean v) { this.active = v; }

    public Integer getBookingId()           { return bookingId; }
    public void    setBookingId(Integer v)  { this.bookingId = v; }

    public Integer getDeliveryBoyId()          { return deliveryBoyId; }
    public void    setDeliveryBoyId(Integer v) { this.deliveryBoyId = v; }

    public String  getDeliveryBoyName()           { return deliveryBoyName; }
    public void    setDeliveryBoyName(String v)   { this.deliveryBoyName = v; }

    public Date    getBookingDate()         { return bookingDate; }
    public void    setBookingDate(Date v)   { this.bookingDate = v; }

    public String  getStatus()          { return status; }
    public void    setStatus(String v)  { this.status = v; }

    public Time    getShiftStart()          { return shiftStart; }
    public void    setShiftStart(Time v)    { this.shiftStart = v; }

    public Time    getShiftEnd()            { return shiftEnd; }
    public void    setShiftEnd(Time v)      { this.shiftEnd = v; }

    public String  getWorkingHours()           { return workingHours; }
    public void    setWorkingHours(String v)   { this.workingHours = v; }
}