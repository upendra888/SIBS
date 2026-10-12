package com.sibs.model;

public class BillItem {

    private int productId;
    private String productName;
    private int quantity;
    private double price;
    private double totalPrice;

    public BillItem() {}

    public BillItem(int productId, String productName, int quantity, double price, double totalPrice) {
        this.productId = productId;
        this.productName = productName;
        this.quantity = quantity;
        this.price = price;
        this.totalPrice = totalPrice;
    }

    public int getProductId() { return productId; }
    public String getProductName() { return productName; }
    public int getQuantity() { return quantity; }
    public double getPrice() { return price; }
    public double getTotalPrice() { return totalPrice; }

    public void setProductId(int productId) { this.productId = productId; }
    public void setProductName(String productName) { this.productName = productName; }
    public void setQuantity(int quantity) { this.quantity = quantity; }
    public void setPrice(double price) { this.price = price; }
    public void setTotalPrice(double totalPrice) { this.totalPrice = totalPrice; }
}