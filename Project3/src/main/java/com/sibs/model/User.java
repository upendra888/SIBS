package com.sibs.model;

public class User {

    private int    id;
    private String name;
    private String username;
    private String email;
    private String password;
    private String role;       // "customer" | "staff" | "admin"
    private String phone;
    private String address;
    private String gender;
    private String status;     // "ACTIVE" | "INACTIVE"
    private String createdAt;

    // ── Constructors ──────────────────────────────────────
    public User() {}

    public User(String name, String username, String email, String password, String role) {
        this.name     = name;
        this.username = username;
        this.email    = email;
        this.password = password;
        this.role     = role;
    }

    // ── Getters & Setters ─────────────────────────────────
    public int    getId()                      { return id; }
    public void   setId(int id)                { this.id = id; }

    public String getName()                    { return name; }
    public void   setName(String name)         { this.name = name; }

    public String getUsername()                { return username; }
    public void   setUsername(String username) { this.username = username; }

    public String getEmail()                   { return email; }
    public void   setEmail(String email)       { this.email = email; }

    public String getPassword()                { return password; }
    public void   setPassword(String pw)       { this.password = pw; }

    public String getRole()                    { return role; }
    public void   setRole(String role)         { this.role = role; }

    public String getPhone()                   { return phone; }
    public void   setPhone(String phone)       { this.phone = phone; }

    public String getAddress()                 { return address; }
    public void   setAddress(String address)   { this.address = address; }

    public String getGender()                  { return gender; }
    public void   setGender(String gender)     { this.gender = gender; }

    public String getStatus()                  { return status; }
    public void   setStatus(String status)     { this.status = status; }

    public String getCreatedAt()               { return createdAt; }
    public void   setCreatedAt(String ts)      { this.createdAt = ts; }

    // ── Convenience ───────────────────────────────────────
    public boolean isAdmin()    { return "admin".equals(role); }
    public boolean isStaff()    { return "staff".equals(role) || "admin".equals(role); }
    public boolean isCustomer() { return "customer".equals(role); }

    @Override
    public String toString() {
        return "User{id=" + id + ", username=" + username + ", role=" + role + "}";
    }
}