package com.sibs.model;

public class Address {
    private int     id;
    private int     userId;
    private String  name;
    private String  phone;
    private String  address;
    private String  landmark;
    private String  city;
    private String  state;
    private String  pincode;
    private boolean isDefault;
    private double  latitude;
    private double  longitude;

    // ── Existing getters/setters ──────────────────────────────────────────
    public int     getId()          { return id; }
    public void    setId(int id)    { this.id = id; }

    public int     getUserId()           { return userId; }
    public void    setUserId(int userId) { this.userId = userId; }

    public String  getName()             { return name; }
    public void    setName(String name)  { this.name = name; }

    public String  getPhone()              { return phone; }
    public void    setPhone(String phone)  { this.phone = phone; }

    public String  getAddress()                { return address; }
    public void    setAddress(String address)  { this.address = address; }

    public String  getLandmark()                 { return landmark; }
    public void    setLandmark(String landmark)  { this.landmark = landmark; }

    public String  getCity()             { return city; }
    public void    setCity(String city)  { this.city = city; }

    public String  getState()              { return state; }
    public void    setState(String state)  { this.state = state; }

    public String  getPincode()                { return pincode; }
    public void    setPincode(String pincode)  { this.pincode = pincode; }

    public boolean isDefault()                   { return isDefault; }
    public void    setDefault(boolean isDefault) { this.isDefault = isDefault; }

    // ── NEW: lat/lng ──────────────────────────────────────────────────────
    public double  getLatitude()               { return latitude; }
    public void    setLatitude(double lat)     { this.latitude  = lat; }

    public double  getLongitude()              { return longitude; }
    public void    setLongitude(double lng)    { this.longitude = lng; }
}