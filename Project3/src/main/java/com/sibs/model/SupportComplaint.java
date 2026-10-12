package com.sibs.model;

import java.sql.Timestamp;

public class SupportComplaint {

    private int       id;
    private int       userId;
    private Integer   orderId;
    private String    issueType;
    private String    description;
    private String    photoPath;
    private String    status;
    private String    staffNotes;
    private Integer   deliveryBoyId;
    private Timestamp createdAt;
    private Timestamp updatedAt;
    private Timestamp resolvedAt;

    // ── join fields ──
    private String orderProducts;
    private String customerName;
    private String customerPhone;
    private String deliveryBoyName;
    private String deliveryBoyPhone;
    private Integer orderGroupId;

    public int     getId()                    { return id; }
    public void    setId(int id)              { this.id = id; }

    public int     getUserId()                { return userId; }
    public void    setUserId(int v)           { this.userId = v; }

    public Integer getOrderId()               { return orderId; }
    public void    setOrderId(Integer v)      { this.orderId = v; }

    public String  getIssueType()             { return issueType; }
    public void    setIssueType(String v)     { this.issueType = v; }

    public String  getDescription()           { return description; }
    public void    setDescription(String v)   { this.description = v; }

    public String  getPhotoPath()             { return photoPath; }
    public void    setPhotoPath(String v)     { this.photoPath = v; }

    public String  getStatus()                { return status; }
    public void    setStatus(String v)        { this.status = v; }

    public String  getStaffNotes()            { return staffNotes; }
    public void    setStaffNotes(String v)    { this.staffNotes = v; }

    public Integer getDeliveryBoyId()         { return deliveryBoyId; }
    public void    setDeliveryBoyId(Integer v){ this.deliveryBoyId = v; }

    public Timestamp getCreatedAt()           { return createdAt; }
    public void      setCreatedAt(Timestamp v){ this.createdAt = v; }

    public Timestamp getUpdatedAt()           { return updatedAt; }
    public void      setUpdatedAt(Timestamp v){ this.updatedAt = v; }

    public Timestamp getResolvedAt()          { return resolvedAt; }
    public void      setResolvedAt(Timestamp v){ this.resolvedAt = v; }

    public String  getOrderProducts()         { return orderProducts; }
    public void    setOrderProducts(String v) { this.orderProducts = v; }

    public String  getCustomerName()          { return customerName; }
    public void    setCustomerName(String v)  { this.customerName = v; }

    public String  getCustomerPhone()         { return customerPhone; }
    public void    setCustomerPhone(String v) { this.customerPhone = v; }

    public String  getDeliveryBoyName()       { return deliveryBoyName; }
    public void    setDeliveryBoyName(String v){ this.deliveryBoyName = v; }

    public String  getDeliveryBoyPhone()      { return deliveryBoyPhone; }
    public void    setDeliveryBoyPhone(String v){ this.deliveryBoyPhone = v; }

    public Integer getOrderGroupId()          { return orderGroupId; }
    public void    setOrderGroupId(Integer v) { this.orderGroupId = v; }

    public String getTicketId() {
        return String.format("SUP-%04d", id);
    }
}