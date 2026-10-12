package com.sibs.model;

import java.sql.Timestamp;

/**
 * Maps one row from the `notifications` table.
 *
 * Recipient targeting is exclusive:
 *   • customer     → userId set
 *   • staff/admin  → staffId set
 *   • delivery boy → deliveryBoyId set
 */
public class Notification {

    private int       id;
    private Integer   userId;          // customer
    private Integer   staffId;         // staff / admin
    private Integer   deliveryBoyId;   // delivery partner

    private String    title;
    private String    message;
    private String    linkUrl;         // deep-link for "view" button
    private String    category;        // ORDER | RETURN | COMPLAINT | DELIVERY | LEAVE | SYSTEM

    private Integer   orderId;
    private Integer   complaintId;
    private Integer   returnId;

    private String    priority;       // HIGH | MEDIUM | LOW
    private boolean   read;
    private Timestamp createdAt;
    private Timestamp readAt;

    // ── Getters & setters ─────────────────────────────────────────────

    public int       getId()             { return id; }
    public void      setId(int id)       { this.id = id; }

    public Integer   getUserId()           { return userId; }
    public void      setUserId(Integer v)  { this.userId = v; }

    public Integer   getStaffId()          { return staffId; }
    public void      setStaffId(Integer v) { this.staffId = v; }

    public Integer   getDeliveryBoyId()          { return deliveryBoyId; }
    public void      setDeliveryBoyId(Integer v) { this.deliveryBoyId = v; }

    public String    getTitle()            { return title; }
    public void      setTitle(String v)    { this.title = v; }

    public String    getMessage()          { return message; }
    public void      setMessage(String v)  { this.message = v; }

    public String    getLinkUrl()          { return linkUrl; }
    public void      setLinkUrl(String v)  { this.linkUrl = v; }

    public String    getCategory()         { return category; }
    public void      setCategory(String v) { this.category = v; }

    public Integer   getOrderId()          { return orderId; }
    public void      setOrderId(Integer v) { this.orderId = v; }

    public Integer   getComplaintId()          { return complaintId; }
    public void      setComplaintId(Integer v) { this.complaintId = v; }

    public Integer   getReturnId()          { return returnId; }
    public void      setReturnId(Integer v) { this.returnId = v; }

    public String    getPriority()         { return priority; }
    public void      setPriority(String v) { this.priority = v; }

    public boolean   isRead()              { return read; }
    public void      setRead(boolean v)    { this.read = v; }

    public Timestamp getCreatedAt()         { return createdAt; }
    public void      setCreatedAt(Timestamp v){ this.createdAt = v; }

    public Timestamp getReadAt()            { return readAt; }
    public void      setReadAt(Timestamp v) { this.readAt = v; }

    // ── Convenience: relative time label ──────────────────────────────

    /** Returns a human-friendly age string: "just now", "5m ago", "2h ago", "3d ago". */
    public String getRelativeTime() {
        if (createdAt == null) return "";
        long diffSec = (System.currentTimeMillis() - createdAt.getTime()) / 1000;
        if (diffSec < 60)         return "just now";
        if (diffSec < 3600)       return (diffSec / 60)   + "m ago";
        if (diffSec < 86400)      return (diffSec / 3600)  + "h ago";
        return                           (diffSec / 86400) + "d ago";
    }
}