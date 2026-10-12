package com.sibs.model;

public class DeliveryAssignment {
    private int    id;
    private int    orderId;
    private int    deliveryBoyId;
    private String customerName;
    private String customerPhone;
    private String deliveryAddress;
    private String productName;
    private int    quantity;
    private double amount;
    private String paymentMethod;
    private String status;
    private String otp;
    private String assignedAt;
    private String deliveredAt;
    // NEW
    private double destLat;
    private double destLng;

    // Return pickup support
    private boolean isReturnPickup;
    private int     returnId;

    // ── Getters / Setters ─────────────────────────────────────────────────
    public int    getId()                    { return id; }
    public void   setId(int id)              { this.id = id; }

    public int    getOrderId()               { return orderId; }
    public void   setOrderId(int orderId)    { this.orderId = orderId; }

    public int    getDeliveryBoyId()                     { return deliveryBoyId; }
    public void   setDeliveryBoyId(int deliveryBoyId)    { this.deliveryBoyId = deliveryBoyId; }

    public String getCustomerName()                      { return customerName; }
    public void   setCustomerName(String customerName)   { this.customerName = customerName; }

    public String getCustomerPhone()                     { return customerPhone; }
    public void   setCustomerPhone(String customerPhone) { this.customerPhone = customerPhone; }

    public String getDeliveryAddress()                         { return deliveryAddress; }
    public void   setDeliveryAddress(String deliveryAddress)   { this.deliveryAddress = deliveryAddress; }

    public String getProductName()                     { return productName; }
    public void   setProductName(String productName)   { this.productName = productName; }

    public int    getQuantity()                { return quantity; }
    public void   setQuantity(int quantity)    { this.quantity = quantity; }

    public double getAmount()                  { return amount; }
    public void   setAmount(double amount)     { this.amount = amount; }

    public String getPaymentMethod()                       { return paymentMethod; }
    public void   setPaymentMethod(String paymentMethod)   { this.paymentMethod = paymentMethod; }

    public String getStatus()                { return status; }
    public void   setStatus(String status)   { this.status = status; }

    public String getOtp()             { return otp; }
    public void   setOtp(String otp)   { this.otp = otp; }

    public String getAssignedAt()                    { return assignedAt; }
    public void   setAssignedAt(String assignedAt)   { this.assignedAt = assignedAt; }

    public String getDeliveredAt()                   { return deliveredAt; }
    public void   setDeliveredAt(String deliveredAt) { this.deliveredAt = deliveredAt; }

    // NEW
    public double getDestLat()               { return destLat; }
    public void   setDestLat(double destLat) { this.destLat = destLat; }

    public double getDestLng()               { return destLng; }
    public void   setDestLng(double destLng) { this.destLng = destLng; }

    // Return pickup
    public boolean isReturnPickup()                        { return isReturnPickup; }
    public void    setReturnPickup(boolean isReturnPickup) { this.isReturnPickup = isReturnPickup; }

    public int  getReturnId()              { return returnId; }
    public void setReturnId(int returnId)  { this.returnId = returnId; }
}