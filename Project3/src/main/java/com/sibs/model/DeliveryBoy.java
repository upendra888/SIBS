package com.sibs.model;

public class DeliveryBoy {

    private int id;
    private String name;
    private String phone;
    private String email;
    private String password;
    private String status;
    private String createdAt;
    private boolean isOnline;
    private String shiftStatus;
    private String shiftStartedAt;
    private String lastSeen;
    private int activeOrders;
    private int deliveredTotal;
    private double wallet;
    private String breakStartedAt;   // ISO timestamp when ON_BREAK started
    private int totalBreakSeconds;   // accumulated break seconds today

    // ── Getters & Setters ──────────────────────────────────────────

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getCreatedAt() { return createdAt; }
    public void setCreatedAt(String createdAt) { this.createdAt = createdAt; }

    public boolean isOnline() { return isOnline; }
    public void setOnline(boolean isOnline) { this.isOnline = isOnline; }

    public String getShiftStatus() { return shiftStatus; }
    public void setShiftStatus(String shiftStatus) { this.shiftStatus = shiftStatus; }

    public String getShiftStartedAt() { return shiftStartedAt; }
    public void setShiftStartedAt(String shiftStartedAt) { this.shiftStartedAt = shiftStartedAt; }

    public String getLastSeen() { return lastSeen; }
    public void setLastSeen(String lastSeen) { this.lastSeen = lastSeen; }

    public int getActiveOrders() { return activeOrders; }
    public void setActiveOrders(int activeOrders) { this.activeOrders = activeOrders; }

    public int getDeliveredTotal() { return deliveredTotal; }
    public void setDeliveredTotal(int deliveredTotal) { this.deliveredTotal = deliveredTotal; }

    // ── Wallet ────────────────────────────────────────────────────
    public double getWallet() { return wallet; }
    public void setWallet(double wallet) { this.wallet = wallet; }

    // ── Break tracking ────────────────────────────────────────────
    public String getBreakStartedAt() { return breakStartedAt; }
    public void setBreakStartedAt(String breakStartedAt) { this.breakStartedAt = breakStartedAt; }

    public int getTotalBreakSeconds() { return totalBreakSeconds; }
    public void setTotalBreakSeconds(int totalBreakSeconds) { this.totalBreakSeconds = totalBreakSeconds; }

    // ── Helper ────────────────────────────────────────────────────
    public String getPresenceLabel() {
        if (shiftStatus == null) return "OFFLINE";
        return shiftStatus.equals("ONLINE") ? "ONLINE" : "OFFLINE";
    }
}