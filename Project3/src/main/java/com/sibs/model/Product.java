package com.sibs.model;

public class Product {

    private int id;
    private String name;
    private double price;
    private int quantity;
    private String category;

    // ✅ NEW: Unit (kg, L, pcs)
    private String unit;

    // ✅ Image
    private String imagePath;

    // ✅ Weight / Volume / Count
    private double weight;

    // ✅ Description
    private String description;

    // ✅ Stock Status (1 = In Stock, 0 = Out of Stock)
    private int stockStatus = 1;

    // ================= CONSTRUCTOR =================

    public Product() {
        // default constructor
    }

    // ================= GETTERS & SETTERS =================

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public double getPrice() {
        return price;
    }

    public void setPrice(double price) {
        this.price = price;
    }

    public int getQuantity() {
        return quantity;
    }

    public void setQuantity(int quantity) {
        this.quantity = quantity;
    }

    public String getCategory() {
        return category;
    }

    public void setCategory(String category) {
        this.category = category;
    }

    // ✅ UNIT (IMPORTANT FIX)
    public String getUnit() {
        return unit;
    }

    public void setUnit(String unit) {
        this.unit = unit;
    }

    // ✅ IMAGE
    public String getImagePath() {
        return imagePath;
    }

    public void setImagePath(String imagePath) {
        this.imagePath = imagePath;
    }

    // ✅ WEIGHT / VOLUME / COUNT
    public double getWeight() {
        return weight;
    }

    public void setWeight(double weight) {
        this.weight = weight;
    }

    // ✅ DESCRIPTION
    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    // ✅ STOCK STATUS
    public int getStockStatus() {
        return stockStatus;
    }

    public void setStockStatus(int stockStatus) {
        this.stockStatus = stockStatus;
    }

    public boolean isInStock() {
        return stockStatus == 1;
    }
}