<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*,java.util.*,com.sibs.util.DBConnection,com.sibs.model.User,com.sibs.dao.AddressDAO,com.sibs.model.Address,com.sibs.dao.CouponDAO,com.sibs.dao.CustomerWalletDAO" %>
<%
User user = (User)session.getAttribute("customer");
if(user == null){ response.sendRedirect("customer-login.jsp"); return; }

// ── Buy-Now mode detection ──────────────────────────────────────────────────
Integer buyNowProductId = (Integer) session.getAttribute("buyNowProductId");
Integer buyNowQty       = (Integer) session.getAttribute("buyNowQty");
boolean isBuyNow        = (buyNowProductId != null && buyNowQty != null);
if(isBuyNow){
    session.removeAttribute("buyNowProductId");
    session.removeAttribute("buyNowQty");
}

// ── Selected-items checkout mode ────────────────────────────────────────────
Boolean isSelectedCheckout = (Boolean) session.getAttribute("isSelectedCheckout");
String[] selProductIds     = (String[]) session.getAttribute("selectedProductIds");
String[] selQtys           = (String[]) session.getAttribute("selectedQtys");
boolean  isSelected        = (isSelectedCheckout != null && isSelectedCheckout
                              && selProductIds != null && selProductIds.length > 0);
if(isSelected){
    session.removeAttribute("isSelectedCheckout");
    session.removeAttribute("selectedProductIds");
    session.removeAttribute("selectedQtys");
}
// ───────────────────────────────────────────────────────────────────────────

Connection con=null; PreparedStatement ps=null; ResultSet rs=null;
double subtotal=0;
List<Object[]> cartItems = new ArrayList<>();

if(isBuyNow){
    // Single product direct buy
    try{
        con=DBConnection.getConnection();
        ps=con.prepareStatement("SELECT id, name, price, image_path FROM products WHERE id=?");
        ps.setInt(1, buyNowProductId);
        rs=ps.executeQuery();
        if(rs.next()){
            double price    = rs.getDouble("price");
            double discPrice= price * 0.90;
            double lineTotal= discPrice * buyNowQty;
            cartItems.add(new Object[]{ rs.getString("name"), (int)buyNowQty, price, rs.getString("image_path"), discPrice, lineTotal });
            subtotal += price * buyNowQty;
        }
    } finally {
        if(rs!=null)try{rs.close();}catch(Exception e){}
        if(ps!=null)try{ps.close();}catch(Exception e){}
        if(con!=null)try{con.close();}catch(Exception e){}
    }
} else if(isSelected){
    // Only selected cart items
    for(int i=0; i<selProductIds.length; i++){
        int pid = Integer.parseInt(selProductIds[i]);
        int qty = (selQtys!=null && i<selQtys.length) ? Integer.parseInt(selQtys[i]) : 1;
        try{
            con=DBConnection.getConnection();
            ps=con.prepareStatement("SELECT name, price, image_path FROM products WHERE id=?");
            ps.setInt(1, pid); rs=ps.executeQuery();
            if(rs.next()){
                double price    = rs.getDouble("price");
                double discPrice= price * 0.90;
                double lineTotal= discPrice * qty;
                cartItems.add(new Object[]{ rs.getString("name"), qty, price, rs.getString("image_path"), discPrice, lineTotal });
                subtotal += price * qty;
            }
        } finally {
            if(rs!=null)try{rs.close();}catch(Exception e){}
            if(ps!=null)try{ps.close();}catch(Exception e){}
            if(con!=null)try{con.close();}catch(Exception e){}
            con=null; ps=null; rs=null;
        }
    }
} else {
    // Full cart checkout
    try{
        con=DBConnection.getConnection();
        ps=con.prepareStatement(
            "SELECT c.*, p.name, p.image_path FROM cart c JOIN products p ON c.product_id=p.id WHERE c.user_id=?"
        );
        ps.setInt(1,user.getId()); rs=ps.executeQuery();
        while(rs.next()){
            int    qty      = rs.getInt("quantity");
            double price    = rs.getDouble("price");
            double discPrice= price * 0.90;
            double lineTotal= discPrice * qty;
            cartItems.add(new Object[]{ rs.getString("name"), qty, price, rs.getString("image_path"), discPrice, lineTotal });
            subtotal += price * qty;
        }
    } finally {
        if(rs!=null)try{rs.close();}catch(Exception e){}
        if(ps!=null)try{ps.close();}catch(Exception e){}
        if(con!=null)try{con.close();}catch(Exception e){}
    }
}

AddressDAO adao = new AddressDAO();
List<Address> addresses = adao.getAddressByUser(user.getId());
double discount   = subtotal * 0.10;
double delivery   = subtotal > 0 ? 40 : 0;
double orderTotal = subtotal - discount + delivery;

// Fetch active coupons to show customer
List<Map<String,Object>> activeCoupons = new ArrayList<>();
try {
    CouponDAO cDao = new CouponDAO();
    for (Map<String,Object> c : cDao.getAllCoupons()) {
        if (Integer.parseInt(String.valueOf(c.get("is_active"))) != 1) continue;
        // Only show coupons where min_order_amount <= subtotal
        double minOrd = Double.parseDouble(String.valueOf(c.get("min_order_amount")));
        if (subtotal >= minOrd) activeCoupons.add(c);
    }
} catch (Exception ignored) {}

// Fetch wallet balance
double walletBalance = 0;
double walletApplied = 0;
try {
    walletBalance = new CustomerWalletDAO().getBalance(user.getId());
    walletApplied = Math.min(walletBalance, orderTotal);
} catch (Exception ignored) {}
%>
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Checkout — SIBS</title>
<link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/leaflet.min.css">
<script src="https://checkout.razorpay.com/v1/checkout.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/leaflet.min.js"></script>
<style>
:root{
  --bg:#eef2ff;--surface:#fff;--border:#dde3f5;--text:#0d1321;--muted:#6b7a9e;
  --primary:#4361ee;--primary-light:#eef0fd;--success:#22c55e;--success-light:#dcfce7;
  --danger:#ef4444;--radius:13px;
}
[data-theme="dark"]{
  --bg:#0b0f1a;--surface:#131929;--border:#1e2a42;--text:#e8eeff;--muted:#5a6a8a;
  --primary:#5878f5;--primary-light:#1a2040;--success-light:#0a2a14;
}
*{margin:0;padding:0;box-sizing:border-box;font-family:'DM Sans',sans-serif;}
body{background:var(--bg);color:var(--text);}
.topbar{background:var(--surface);border-bottom:1px solid var(--border);padding:0 20px;height:60px;
  display:flex;align-items:center;gap:12px;position:sticky;top:0;z-index:50;}
.back-link{display:flex;align-items:center;gap:7px;text-decoration:none;color:var(--muted);
  font-size:13px;font-weight:500;padding:7px 12px;border-radius:8px;border:1px solid var(--border);transition:.15s;}
.back-link:hover{color:var(--primary);border-color:var(--primary);background:var(--primary-light);}
.brand{font-weight:800;font-size:16px;color:var(--primary);}
.page-title{font-weight:700;font-size:15px;}
.dark-btn{background:none;border:1px solid var(--border);width:36px;height:36px;border-radius:9px;
  cursor:pointer;color:var(--muted);display:flex;align-items:center;justify-content:center;
  font-size:14px;margin-left:auto;transition:.15s;}
.dark-btn:hover{border-color:var(--primary);color:var(--primary);}
.layout{max-width:1020px;margin:24px auto;padding:0 16px;display:grid;
  grid-template-columns:1fr 330px;gap:18px;}
@media(max-width:720px){.layout{grid-template-columns:1fr;}}
.card{background:var(--surface);border:1.5px solid var(--border);border-radius:var(--radius);
  padding:20px;margin-bottom:14px;box-shadow:0 2px 12px rgba(67,97,238,.06);}
.section-title{font-size:14px;font-weight:700;margin-bottom:16px;display:flex;align-items:center;gap:8px;}
.section-title i{color:var(--primary);}
.addr-list{display:flex;flex-direction:column;gap:10px;margin-bottom:12px;}
.addr-card{border:1.5px solid var(--border);border-radius:11px;padding:14px 14px 14px 46px;
  position:relative;cursor:pointer;transition:.15s;}
.addr-card:hover{border-color:var(--primary);}
.addr-card.selected{border-color:var(--primary);background:var(--primary-light);}
.addr-card input[type=radio]{position:absolute;left:14px;top:18px;
  accent-color:var(--primary);width:16px;height:16px;}
.addr-top{display:flex;align-items:flex-start;justify-content:space-between;gap:8px;}
.addr-name{font-weight:700;font-size:13px;}
.addr-type-tag{font-size:10px;font-weight:700;padding:2px 8px;border-radius:99px;
  background:var(--primary-light);color:var(--primary);}
.addr-text{font-size:12px;color:var(--muted);margin-top:3px;line-height:1.5;}
.addr-phone{font-size:12px;color:var(--muted);margin-top:4px;display:flex;align-items:center;gap:4px;}
.addr-coords{font-size:11px;color:var(--success);margin-top:3px;display:flex;align-items:center;gap:4px;}
.default-tag{font-size:11px;color:var(--success);font-weight:700;margin-top:5px;display:flex;align-items:center;gap:4px;}
.addr-actions{display:flex;gap:10px;margin-top:8px;}
.addr-actions a{font-size:12px;color:var(--primary);text-decoration:none;font-weight:500;}
.addr-actions a.del{color:var(--danger);}
.deliver-btn{margin-top:10px;padding:7px 16px;background:var(--primary);color:#fff;
  border:none;border-radius:7px;cursor:pointer;font-size:12px;font-weight:600;
  display:inline-flex;align-items:center;gap:6px;}
.add-addr-box{border:2px dashed var(--border);border-radius:11px;padding:14px;
  text-align:center;cursor:pointer;color:var(--primary);font-size:13px;font-weight:600;
  transition:.15s;display:flex;align-items:center;justify-content:center;gap:8px;}
.add-addr-box:hover{background:var(--primary-light);border-color:var(--primary);}
.new-addr-form{display:none;background:var(--bg);border:1.5px solid var(--border);
  border-radius:11px;padding:18px;margin-top:10px;}
.form-grid{display:grid;grid-template-columns:1fr 1fr;gap:12px;}
@media(max-width:500px){.form-grid{grid-template-columns:1fr;}}
.field{display:flex;flex-direction:column;gap:4px;}
.field label{font-size:11px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.4px;}
.field input,.field textarea{width:100%;padding:9px 11px;border:1.5px solid var(--border);
  border-radius:8px;background:var(--surface);color:var(--text);font-size:13px;outline:none;transition:.15s;}
.field input:focus,.field textarea:focus{border-color:var(--primary);}
.field textarea{resize:vertical;min-height:64px;}
.addr-type-btns{display:flex;gap:8px;flex-wrap:wrap;}
.type-btn{padding:7px 14px;border:1.5px solid var(--border);border-radius:8px;cursor:pointer;
  font-size:12px;font-weight:600;background:none;color:var(--muted);transition:.15s;
  display:flex;align-items:center;gap:5px;}
.type-btn.sel,.type-btn:hover{border-color:var(--primary);color:var(--primary);background:var(--primary-light);}
.locate-btn{padding:7px 14px;border:1.5px solid var(--success);border-radius:8px;cursor:pointer;
  font-size:12px;font-weight:600;background:var(--success-light);color:var(--success);
  display:flex;align-items:center;gap:6px;transition:.15s;}
.locate-btn:hover{opacity:.85;}
.locate-btn:disabled{opacity:.5;cursor:not-allowed;}
.locate-status{font-size:11px;color:var(--success);margin-top:6px;display:flex;align-items:center;gap:5px;}
#miniPickMap{width:100%;height:200px;border-radius:9px;border:1.5px solid var(--border);
  margin-top:10px;display:none;}
.form-actions{display:flex;gap:10px;margin-top:14px;}
.save-addr-btn{padding:9px 18px;background:var(--primary);color:#fff;border:none;
  border-radius:8px;cursor:pointer;font-size:13px;font-weight:700;display:flex;align-items:center;gap:6px;}
.cancel-form-btn{padding:9px 14px;background:none;border:1.5px solid var(--border);
  border-radius:8px;cursor:pointer;font-size:13px;font-weight:600;color:var(--muted);}
.pay-options{display:flex;flex-direction:column;gap:8px;}
.pay-opt{display:flex;align-items:center;gap:12px;padding:11px 14px;border:1.5px solid var(--border);
  border-radius:9px;cursor:pointer;transition:.15s;}
.pay-opt:hover,.pay-opt.sel{border-color:var(--primary);background:var(--primary-light);}
.pay-opt input{accent-color:var(--primary);}
.pay-opt label{font-size:13px;cursor:pointer;font-weight:500;}
.summary-sticky{position:sticky;top:76px;}
.checkout-item{display:flex;gap:10px;align-items:flex-start;padding:10px 0;border-bottom:1px solid var(--border);}
.checkout-item:last-child{border-bottom:none;}
.ci-img{width:56px;height:56px;border-radius:8px;object-fit:contain;background:var(--bg);
  padding:4px;border:1px solid var(--border);}
.disc-badge{display:block;margin-top:4px;background:#dcfce7;color:#15803d;font-size:10px;
  font-weight:700;text-align:center;border-radius:4px;padding:1px 4px;}
.ci-info{flex:1;min-width:0;}
.ci-name{font-size:12px;font-weight:700;}
.ci-orig{font-size:11px;color:var(--muted);text-decoration:line-through;}
.ci-price{font-size:12px;color:var(--danger);font-weight:600;}
.ci-qty{font-size:11px;color:var(--muted);}
.ci-total{font-size:13px;font-weight:700;margin-left:auto;white-space:nowrap;}
.sum-row{display:flex;justify-content:space-between;font-size:13px;padding:5px 0;}
.sum-row.disc{color:var(--success);font-weight:600;}
.coupon-row{display:flex;gap:8px;margin:12px 0;}
.coupon-input{flex:1;padding:8px 12px;border:1.5px solid var(--border);border-radius:8px;font-size:13px;outline:none;background:var(--surface);color:var(--text);}
.coupon-input:focus{border-color:var(--primary);}
.coupon-btn{padding:8px 14px;background:var(--primary);color:#fff;border:none;border-radius:8px;font-size:12px;font-weight:600;cursor:pointer;}
.coupon-btn:hover{background:#3451d1;}
.coupon-msg{font-size:12px;margin-bottom:8px;padding:6px 10px;border-radius:6px;}
.coupon-msg.ok{background:#dcfce7;color:#15803d;}
.coupon-msg.err{background:#fee2e2;color:#b91c1c;}
/* Available coupons list */
.avail-coupons{margin-bottom:10px;}
.avail-coupons-title{font-size:11px;font-weight:600;color:var(--muted);text-transform:uppercase;
  letter-spacing:.5px;margin-bottom:8px;display:flex;align-items:center;gap:5px;}
.coupon-chips{display:flex;flex-wrap:wrap;gap:7px;}
.coupon-chip{display:flex;align-items:center;gap:6px;padding:6px 12px;
  border:1.5px dashed var(--primary);border-radius:8px;cursor:pointer;
  background:var(--primary-light);transition:.15s;font-size:12px;}
.coupon-chip:hover{background:var(--primary);color:#fff;border-style:solid;}
.coupon-chip .chip-code{font-weight:700;letter-spacing:.5px;font-size:12px;}
.coupon-chip .chip-desc{color:var(--muted);font-size:11px;}
.coupon-chip:hover .chip-desc{color:rgba(255,255,255,.8);}
.sum-row.total-row{font-weight:800;font-size:17px;padding-top:12px;
  border-top:2px solid var(--border);margin-top:4px;}
.place-btn{width:100%;padding:13px;
  background:linear-gradient(135deg,var(--primary),#7c3aed);
  color:#fff;border:none;border-radius:10px;cursor:pointer;
  font-weight:700;font-size:15px;margin-top:14px;
  display:flex;align-items:center;justify-content:center;gap:8px;}
.place-btn:hover{opacity:.9;}
.savings-strip{background:var(--success-light);border-radius:8px;padding:9px 12px;margin-top:10px;
  font-size:12px;font-weight:600;color:#15803d;display:flex;align-items:center;gap:7px;}
.secure-note{font-size:11px;color:var(--muted);text-align:center;margin-top:10px;
  display:flex;align-items:center;justify-content:center;gap:5px;}
</style>
</head>
<body>

<div class="topbar">
  <a class="back-link" href="cart.jsp"><i class="fa fa-arrow-left"></i> Cart</a>
  <span class="brand">SIBS</span>
  <span class="page-title">Checkout</span>
  <button class="dark-btn" onclick="toggleDark()"><i class="fa fa-moon"></i></button>
</div>

<form action="placeOrder" method="post" id="orderForm">
<% if(isBuyNow){ %>
<input type="hidden" name="productId" value="<%=buyNowProductId%>">
<input type="hidden" name="qty"       value="<%=buyNowQty%>">
<% } else if(isSelected){ %>
<%   for(int i=0;i<selProductIds.length;i++){ %>
<input type="hidden" name="selectedProductIds" value="<%=selProductIds[i]%>">
<input type="hidden" name="selectedQtys"       value="<%=(selQtys!=null&&i<selQtys.length?selQtys[i]:"1")%>">
<%   } %>
<% } %>
<div class="layout">
  <div>
    <!-- ADDRESSES -->
    <div class="card">
      <div class="section-title"><i class="fa fa-location-dot"></i> Delivery Address</div>
      <% if(!addresses.isEmpty()){ %>
      <div class="addr-list">
      <% for(Address a : addresses){ %>
        <label class="addr-card <%=a.isDefault()?"selected":""%>">
          <input type="radio" name="selectedAddress" value="<%=a.getId()%>"
            <%=a.isDefault()?"checked":""%> onchange="markSelected(this)">
          <div class="addr-top">
            <div class="addr-name"><%=a.getName()%></div>
            <span class="addr-type-tag"><i class="fa fa-house"></i> Home</span>
          </div>
          <div class="addr-text"><%=a.getAddress()%></div>
          <div class="addr-phone"><i class="fa fa-phone"></i> <%=a.getPhone()%></div>
          <% if(a.getLatitude() != 0 && a.getLongitude() != 0){ %>
          <div class="addr-coords">
            <i class="fa fa-crosshairs"></i>
            GPS: <%=String.format("%.5f",a.getLatitude())%>, <%=String.format("%.5f",a.getLongitude())%>
          </div>
          <% } %>
          <% if(a.isDefault()){ %>
          <div class="default-tag"><i class="fa fa-circle-check"></i> Default Address</div>
          <% } %>
          <div class="addr-actions">
            <a href="editAddress.jsp?id=<%=a.getId()%>"><i class="fa fa-pen"></i> Edit</a>
            <a class="del" href="javascript:void(0)"
               onclick="if(confirm('Remove this address?'))location.href='deleteAddress?id=<%=a.getId()%>'">
               <i class="fa fa-trash"></i> Remove</a>
          </div>
          <button type="button" class="deliver-btn" onclick="selectDeliverHere(this)">
            <i class="fa fa-circle-check"></i> Deliver here
          </button>
        </label>
      <% } %>
      </div>
      <% } %>

      <div class="add-addr-box" id="addAddrToggle" onclick="openAddressForm()">
        <i class="fa fa-plus"></i> Add a new address
      </div>

      <div class="new-addr-form" id="newAddrForm">
        <div class="section-title"><i class="fa fa-map-pin"></i> New Delivery Address</div>

        <div class="field" style="margin-bottom:14px;">
          <label>Address Type</label>
          <div class="addr-type-btns">
            <button type="button" class="type-btn sel" id="typeHome" onclick="setType('Home')"><i class="fa fa-house"></i> Home</button>
            <button type="button" class="type-btn" id="typeWork" onclick="setType('Work')"><i class="fa fa-briefcase"></i> Work</button>
            <button type="button" class="type-btn" id="typeOther" onclick="setType('Other')"><i class="fa fa-location-dot"></i> Other</button>
          </div>
          <input type="hidden" name="addressType" id="addrTypeInput" value="Home">
        </div>

        <div class="field" style="margin-bottom:14px;">
          <label>Pin Your Location</label>
          <div style="display:flex;align-items:center;gap:10px;flex-wrap:wrap;">
            <button type="button" class="locate-btn" id="locateBtn" onclick="detectLocation()">
              <i class="fa fa-crosshairs"></i> Use My Current Location
            </button>
            <span id="locateStatus" class="locate-status"></span>
          </div>
          <div id="miniPickMap"></div>
          <p style="font-size:11px;color:var(--muted);margin-top:6px;">
            <i class="fa fa-circle-info"></i> You can also drag the pin on the map to adjust your exact location.
          </p>
        </div>

        <input type="hidden" name="latitude"  id="addrLat" value="0">
        <input type="hidden" name="longitude" id="addrLng" value="0">

        <div class="form-grid">
          <div class="field">
            <label>Full Name *</label>
            <input type="text" id="newName" placeholder="e.g. Ravi Kumar" value="<%=user.getUsername()%>">
          </div>
          <div class="field">
            <label>Phone *</label>
            <input type="tel" id="newPhone" placeholder="10-digit"
              value="<%=user.getPhone()!=null?user.getPhone():""%>" maxlength="10">
          </div>
          <div class="field">
            <label>Alternate Phone</label>
            <input type="tel" id="newAltPhone" placeholder="Optional" maxlength="10">
          </div>
          <div class="field">
            <label>Pincode *</label>
            <input type="text" id="pincodeField" placeholder="e.g. 515632"
              maxlength="6" oninput="this.value=this.value.replace(/\D/g,'')"
              onblur="lookupPincode(this.value)">
          </div>
          <div class="field">
            <label>City</label>
            <input type="text" id="cityField" placeholder="Auto-filled">
          </div>
          <div class="field">
            <label>State</label>
            <input type="text" id="stateField" placeholder="Auto-filled">
          </div>
        </div>
        <div class="form-grid" style="margin-top:12px;grid-template-columns:1fr;">
          <div class="field">
            <label>Full Address *</label>
            <textarea id="newAddress" rows="3"
              placeholder="e.g. #12-34, Gandhi Nagar, Near Bus Stand"></textarea>
          </div>
          <div class="field">
            <label>Landmark</label>
            <input type="text" id="newLandmark" placeholder="e.g. Opposite SBI Bank">
          </div>
        </div>
        <div class="form-actions">
          <button type="button" class="save-addr-btn" id="saveAddrBtn" onclick="saveAndDeliver()">
            <i class="fa fa-floppy-disk"></i> Save & Deliver Here
          </button>
          <button type="button" class="cancel-form-btn" onclick="closeAddressForm()">Cancel</button>
        </div>
      </div>
    </div>

    <!-- PAYMENT -->
    <div class="card">
      <div class="section-title"><i class="fa fa-credit-card"></i> Payment Method</div>
      <div class="pay-options">
        <div class="pay-opt sel" id="codOpt">
          <input type="radio" name="paymentMethod" value="COD" id="cod" checked onchange="hilPay('codOpt')">
          <label for="cod">&#128181; Cash on Delivery</label>
        </div>
        <div class="pay-opt" id="upiOpt">
          <input type="radio" name="paymentMethod" value="UPI" id="upi" onchange="hilPay('upiOpt')">
          <label for="upi">&#128241; UPI (PhonePe / GPay / Paytm)</label>
        </div>
        <div class="pay-opt" id="cardOpt">
          <input type="radio" name="paymentMethod" value="Card" id="card" onchange="hilPay('cardOpt')">
          <label for="card">&#128179; Credit / Debit Card</label>
        </div>
      </div>
    </div>
  </div>

  <!-- SUMMARY -->
  <div>
    <div class="card summary-sticky">
      <div class="section-title"><i class="fa fa-receipt"></i> Order Summary</div>
      <%
      for(Object[] item : cartItems){
        String iName     = (String)item[0];
        int qty          = (int)item[1];
        double origPrice = (double)item[2];
        String imgPath   = (String)item[3];
        double discPrice = (double)item[4];
        double lineTotal = (double)item[5];
        String finalImg  = (imgPath!=null&&!imgPath.trim().isEmpty())
            ? request.getContextPath()+"/"+imgPath
            : request.getContextPath()+"/images/default.png";
      %>
      <div class="checkout-item">
        <div style="flex-shrink:0;text-align:center;">
          <img class="ci-img" src="<%=finalImg%>"
               onerror="this.src='images/default.png'" alt="<%=iName%>">
          <span class="disc-badge">10% OFF</span>
        </div>
        <div class="ci-info">
          <div class="ci-name"><%=iName%></div>
          <div class="ci-orig">&#8377;<%=(int)origPrice%></div>
          <div class="ci-price">&#8377;<%=(int)discPrice%>/unit</div>
          <div class="ci-qty">Qty: <%=qty%></div>
        </div>
        <div class="ci-total">&#8377;<%=(int)lineTotal%></div>
      </div>
      <% } %>

      <!-- Available Coupons -->
      <% if (!activeCoupons.isEmpty()) { %>
      <div class="avail-coupons" style="margin-top:12px;">
        <div class="avail-coupons-title"><i class="fa fa-tags"></i> Available Offers — Click to apply</div>
        <div class="coupon-chips">
          <% for (Map<String,Object> ac : activeCoupons) {
              String acCode  = (String) ac.get("code");
              String acDesc  = (String) ac.get("description");
              String acType  = (String) ac.get("discount_type");
              double acVal   = Double.parseDouble(String.valueOf(ac.get("discount_value")));
              double acMinOrd= Double.parseDouble(String.valueOf(ac.get("min_order_amount")));
              String acLabel = "PERCENT".equals(acType) ? (int)acVal+"% off" : "₹"+(int)acVal+" off";
              if (acDesc == null || acDesc.trim().isEmpty()) acDesc = acLabel;
          %>
          <div class="coupon-chip" onclick="applyCouponCode('<%=acCode%>')" title="<%=acDesc%>">
            <i class="fa fa-ticket" style="font-size:11px;"></i>
            <span class="chip-code"><%=acCode%></span>
            <span class="chip-desc">— <%=acLabel%><% if(acMinOrd>0){%> on ₹<%=(int)acMinOrd%>+<%}%></span>
          </div>
          <% } %>
        </div>
      </div>
      <% } %>

      <!-- Promo/Coupon Code Input -->
      <div style="margin-top:12px;">
        <div class="coupon-row">
          <input type="text" id="couponInput" class="coupon-input" placeholder="Enter promo code (e.g. SAVE10)" maxlength="30"/>
          <button type="button" class="coupon-btn" onclick="applyCoupon()">Apply</button>
        </div>
        <div id="couponMsg" class="coupon-msg" style="display:none;"></div>
        <input type="hidden" id="couponCode" name="couponCode" value=""/>
        <input type="hidden" id="couponDiscount" name="couponDiscount" value="0"/>
      </div>
      <!-- WALLET SECTION -->
      <% if(walletBalance > 0){ %>
      <div style="background:#f0fdf4;border:1.5px solid #86efac;border-radius:10px;padding:14px;margin-top:12px;margin-bottom:4px;">
        <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:10px;">
          <span style="font-size:13px;font-weight:700;color:#16a34a;">
            <i class="fa fa-wallet"></i> Wallet Balance: &#8377;<%= String.format("%.2f", walletBalance) %>
          </span>
        </div>
        <label style="display:flex;align-items:center;gap:8px;cursor:pointer;font-size:13px;">
          <input type="checkbox" id="useWalletChk" onchange="toggleWallet(this)"
                 style="width:16px;height:16px;accent-color:#16a34a;">
          Use &#8377;<%= String.format("%.2f", walletApplied) %> from wallet &amp; save more!
        </label>
      </div>
      <% } %>
      <!-- Hidden inputs for PlaceOrderServlet -->
      <input type="hidden" id="useWalletInput"    name="useWallet"    value="false">
      <input type="hidden" id="walletAmountInput" name="walletAmount" value="0">
      <div style="margin-top:12px;">
        <div class="sum-row"><span>Subtotal</span><span>&#8377;<%=(int)subtotal%></span></div>
        <div class="sum-row disc"><span><i class="fa fa-tag"></i> Discount (10%)</span><span>&#8722;&#8377;<%=(int)discount%></span></div>
        <div class="sum-row disc" id="couponRow" style="display:none;"><span><i class="fa fa-ticket"></i> Promo Code</span><span id="couponSaving">&#8722;&#8377;0</span></div>
        <div class="sum-row disc" id="walletRow" style="display:none;"><span><i class="fa fa-wallet"></i> Wallet</span><span id="walletSaving">&#8722;&#8377;0</span></div>
        <div class="sum-row"><span>Delivery</span><span>&#8377;<%=(int)delivery%></span></div>
        <div class="sum-row total-row"><span>You Pay</span><span id="finalTotal">&#8377;<%=(int)orderTotal%></span></div>
      </div>

      <button type="submit" form="orderForm" class="place-btn">
        <i class="fa fa-lock"></i> Place Your Order
      </button>
      <div class="savings-strip">
        <i class="fa fa-circle-check"></i> You save &#8377;<%=(int)discount%> on this order!
      </div>
      <div class="secure-note">
        <i class="fa fa-shield-halved"></i> Secure &amp; Encrypted Checkout
      </div>
    </div>
  </div>
</div>
</form>

<script>
// ── theme ────────────────────────────────────────────────────────────────────
function toggleDark(){
  const h=document.documentElement,d=h.getAttribute('data-theme')==='dark';
  h.setAttribute('data-theme',d?'light':'dark');
  localStorage.setItem('sibs-theme',d?'light':'dark');
}
(function(){const t=localStorage.getItem('sibs-theme');if(t)document.documentElement.setAttribute('data-theme',t);})();

// ── address helpers ──────────────────────────────────────────────────────────
function markSelected(r){
  document.querySelectorAll('.addr-card').forEach(c=>c.classList.remove('selected'));
  r.closest('.addr-card').classList.add('selected');
}
function selectDeliverHere(btn){
  document.querySelectorAll('.addr-card').forEach(c=>c.classList.remove('selected'));
  btn.closest('.addr-card').classList.add('selected');
  var radio=btn.closest('.addr-card').querySelector('input[type="radio"]');
  if(radio) radio.checked=true;
  closeAddressForm();
}
function openAddressForm(){
  document.getElementById('newAddrForm').style.display='block';
  document.getElementById('addAddrToggle').style.display='none';
  document.querySelectorAll('.addr-card input[type=radio]').forEach(r=>r.checked=false);
  document.querySelectorAll('.addr-card').forEach(c=>c.classList.remove('selected'));
  initMiniMap();
}
function closeAddressForm(){
  document.getElementById('newAddrForm').style.display='none';
  document.getElementById('addAddrToggle').style.display='flex';
}
function setType(t){
  ['Home','Work','Other'].forEach(x=>document.getElementById('type'+x).classList.remove('sel'));
  document.getElementById('type'+t).classList.add('sel');
  document.getElementById('addrTypeInput').value=t;
}
function lookupPincode(pin){
  if(pin.length!==6) return;
  fetch('https://api.postalpincode.in/pincode/'+pin)
    .then(r=>r.json())
    .then(d=>{
      if(d&&d[0]&&d[0].Status==='Success'&&d[0].PostOffice.length>0){
        const p=d[0].PostOffice[0];
        document.getElementById('cityField').value=p.District||p.Name||'';
        document.getElementById('stateField').value=p.State||'';
      }
    }).catch(()=>{});
}
function hilPay(id){
  document.querySelectorAll('.pay-opt').forEach(o=>o.classList.remove('sel'));
  document.getElementById(id).classList.add('sel');
}

// ── Mini pick-a-location map ──────────────────────────────────────────────────
var miniMap = null;
var miniMarker = null;

function initMiniMap(lat, lng) {
  var mapEl = document.getElementById('miniPickMap');
  mapEl.style.display = 'block';
  var initLat = lat || 17.3850;
  var initLng = lng || 78.4867;

  if (!miniMap) {
    miniMap = L.map('miniPickMap').setView([initLat, initLng], 15);
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '© OpenStreetMap'
    }).addTo(miniMap);

    var pinIcon = L.divIcon({
      html: '<div style="background:#ef4444;width:16px;height:16px;border-radius:50% 50% 50% 0;transform:rotate(-45deg);border:3px solid #fff;box-shadow:0 2px 8px rgba(0,0,0,.4);"></div>',
      iconSize: [16, 16], iconAnchor: [8, 16]
    });

    miniMarker = L.marker([initLat, initLng], { icon: pinIcon, draggable: true })
      .addTo(miniMap)
      .bindPopup('Drag to adjust your exact location')
      .openPopup();

    miniMarker.on('dragend', function(e) {
      var pos = e.target.getLatLng();
      setLatLng(pos.lat, pos.lng);
      reverseGeocode(pos.lat, pos.lng);
    });

    miniMap.on('click', function(e) {
      miniMarker.setLatLng(e.latlng);
      setLatLng(e.latlng.lat, e.latlng.lng);
      reverseGeocode(e.latlng.lat, e.latlng.lng);
    });
  } else {
    miniMap.setView([initLat, initLng], 15);
    miniMarker.setLatLng([initLat, initLng]);
    setTimeout(function(){ miniMap.invalidateSize(); }, 200);
  }
}

function setLatLng(lat, lng) {
  document.getElementById('addrLat').value = lat.toFixed(8);
  document.getElementById('addrLng').value = lng.toFixed(8);
  document.getElementById('locateStatus').innerHTML =
    '<i class="fa fa-circle-check"></i> ' + lat.toFixed(5) + ', ' + lng.toFixed(5);
}

function reverseGeocode(lat, lng) {
  fetch('https://nominatim.openstreetmap.org/reverse?lat='+lat+'&lon='+lng+'&format=json')
    .then(r=>r.json())
    .then(d=>{
      var a = d.address || {};
      if(a.postcode) document.getElementById('pincodeField').value = a.postcode;
      if(a.city||a.town||a.village)
        document.getElementById('cityField').value = a.city||a.town||a.village;
      if(a.state) document.getElementById('stateField').value = a.state;
    }).catch(()=>{});
}

function detectLocation() {
  var btn    = document.getElementById('locateBtn');
  var status = document.getElementById('locateStatus');
  if (!navigator.geolocation) {
    status.innerHTML = '<i class="fa fa-triangle-exclamation"></i> Not supported by browser.';
    return;
  }
  btn.disabled = true;
  btn.innerHTML = '<i class="fa fa-spinner fa-spin"></i> Locating…';

  navigator.geolocation.getCurrentPosition(
    function(pos) {
      var lat = pos.coords.latitude;
      var lng = pos.coords.longitude;
      setLatLng(lat, lng);
      initMiniMap(lat, lng);
      reverseGeocode(lat, lng);
      btn.disabled = false;
      btn.innerHTML = '<i class="fa fa-circle-check"></i> Location Captured';
    },
    function() {
      btn.disabled = false;
      btn.innerHTML = '<i class="fa fa-crosshairs"></i> Use My Current Location';
      status.innerHTML = '<i class="fa fa-triangle-exclamation"></i> Could not get location. Drag the pin manually.';
      initMiniMap();
    },
    { enableHighAccuracy: true, timeout: 10000 }
  );
}

// ── saveAndDeliver — saves address via AJAX then shows it in the list ────────
function saveAndDeliver() {
  var name    = document.getElementById('newName').value.trim();
  var phone   = document.getElementById('newPhone').value.trim();
  var addr    = document.getElementById('newAddress').value.trim();

  if (!name || !phone || !addr) {
    alert('Please fill in Full Name, Phone and Full Address before continuing.');
    return;
  }

  var saveBtn = document.getElementById('saveAddrBtn');
  saveBtn.disabled = true;
  saveBtn.innerHTML = '<i class="fa fa-spinner fa-spin"></i> Saving...';

  var formData = new FormData();
  formData.append('name',      name);
  formData.append('phone',     phone);
  formData.append('address',   addr);
  formData.append('altPhone',  document.getElementById('newAltPhone').value.trim());
  formData.append('pincode',   document.getElementById('pincodeField').value.trim());
  formData.append('city',      document.getElementById('cityField').value.trim());
  formData.append('state',     document.getElementById('stateField').value.trim());
  formData.append('landmark',  document.getElementById('newLandmark').value.trim());
  formData.append('latitude',  document.getElementById('addrLat').value);
  formData.append('longitude', document.getElementById('addrLng').value);

  fetch('saveAddress', { method: 'POST', body: formData })
    .then(function(r) { return r.json(); })
    .then(function(data) {
      if (!data || data.error) throw new Error(data ? data.error : 'Failed to save address.');

      // Deselect all existing address cards
      document.querySelectorAll('.addr-card').forEach(function(c){ c.classList.remove('selected'); });
      document.querySelectorAll('.addr-card input[type=radio]').forEach(function(r){ r.checked = false; });

      // Build and inject a new address card into the list
      var addrId = data.addressId;
      var card = document.createElement('label');
      card.className = 'addr-card selected';
      card.innerHTML =
        '<input type="radio" name="selectedAddress" value="' + addrId + '" checked onchange="markSelected(this)">' +
        '<div class="addr-top">' +
          '<div class="addr-name">' + escHtml(name) + '</div>' +
          '<span class="addr-type-tag"><i class="fa fa-house"></i> Home</span>' +
        '</div>' +
        '<div class="addr-text">' + escHtml(addr) + '</div>' +
        '<div class="addr-phone"><i class="fa fa-phone"></i> ' + escHtml(phone) + '</div>' +
        '<div class="addr-actions">' +
          '<a href="editAddress.jsp?id=' + addrId + '"><i class="fa fa-pen"></i> Edit</a>' +
          '<a class="del" href="javascript:void(0)" onclick="if(confirm(\'Remove this address?\'))location.href=\'deleteAddress?id=' + addrId + '\'">' +
            '<i class="fa fa-trash"></i> Remove</a>' +
        '</div>' +
        '<button type="button" class="deliver-btn" onclick="selectDeliverHere(this)">' +
          '<i class="fa fa-circle-check"></i> Deliver here' +
        '</button>';

      // Insert into the existing addr-list, or create one if this is the first address
      var list = document.querySelector('.addr-list');
      if (!list) {
        list = document.createElement('div');
        list.className = 'addr-list';
        var toggle = document.getElementById('addAddrToggle');
        toggle.parentNode.insertBefore(list, toggle);
      }
      list.appendChild(card);

      // Close and reset the new address form
      closeAddressForm();
      document.getElementById('newName').value     = '';
      document.getElementById('newPhone').value    = '';
      document.getElementById('newAltPhone').value = '';
      document.getElementById('newAddress').value  = '';
      document.getElementById('newLandmark').value = '';
      document.getElementById('pincodeField').value= '';
      document.getElementById('cityField').value   = '';
      document.getElementById('stateField').value  = '';
      document.getElementById('addrLat').value     = '0';
      document.getElementById('addrLng').value     = '0';

      saveBtn.disabled = false;
      saveBtn.innerHTML = '<i class="fa fa-floppy-disk"></i> Save & Deliver Here';

      // Scroll new card into view so the user can confirm it
      card.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
    })
    .catch(function(err) {
      alert(err.message || 'Could not save address. Please try again.');
      saveBtn.disabled = false;
      saveBtn.innerHTML = '<i class="fa fa-floppy-disk"></i> Save & Deliver Here';
    });
}

// XSS-safe helper for injecting user text into HTML
function escHtml(str) {
  return String(str)
    .replace(/&/g,'&amp;').replace(/</g,'&lt;')
    .replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

document.getElementById('orderForm').addEventListener('submit', function(e) {
  var method = document.querySelector('input[name="paymentMethod"]:checked');
  if (!method) { e.preventDefault(); alert('Please select a payment method.'); return; }

  var savedAddr = document.querySelector('input[name="selectedAddress"]:checked');
  var newFormVisible = document.getElementById('newAddrForm').style.display === 'block';

  if (!savedAddr && newFormVisible) {
    // New address form is open but not yet saved — trigger save first
    e.preventDefault();
    saveAndDeliver();
    return;
  }

  if (!savedAddr) {
    e.preventDefault();
    alert('Please select a delivery address or add a new one.');
    return;
  }

  if (method.value === 'UPI' || method.value === 'Card') {
    e.preventDefault();
    launchRazorpay(this, method.value);
  }
});

function launchRazorpay(form, payMethod) {
  var selectedAddr = document.querySelector('input[name="selectedAddress"]:checked');
  if (!selectedAddr) { alert('Please select a delivery address.'); return; }

  var placeBtn = document.querySelector('.place-btn');
  if (placeBtn) { placeBtn.disabled=true; placeBtn.innerHTML='<i class="fa fa-spinner fa-spin"></i> Processing…'; }

  var fd = new FormData(form);
  fd.set('paymentMethod', payMethod);

  fetch('placeOrder', { method: 'POST', body: fd })
    .then(function(r) {
      var ct = r.headers.get('content-type') || '';
      if (ct.indexOf('application/json') === -1) {
        return r.text().then(function(t) { throw new Error('Order failed: ' + t.substring(0, 200)); });
      }
      return r.json();
    })
    .then(function(orderData) {
      if (!orderData || orderData.error) throw new Error(orderData && orderData.error ? orderData.error : 'Could not create order.');
      if (!orderData.orderId || orderData.orderId < 1) throw new Error('Could not create order.');
      return fetch('createPaymentOrder', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: 'orderId=' + orderData.orderId + '&amount=' + orderData.amount
      }).then(function(r) { return r.json(); });
    })
    .then(function(data) {
      if (!data || data.error) throw new Error(data ? data.error : 'Payment init failed');
      var options = {
        key: data.keyId, amount: data.amount, currency: data.currency || 'INR',
        name: 'SIBS Store', description: 'Order Payment', order_id: data.razorpayOrderId,
        prefill: { name: data.customerName||'', email: data.customerEmail||'', contact: data.customerPhone||'' },
        theme: { color: '#4361ee' },
        handler: function(response) {
          var body = 'razorpay_order_id=' + encodeURIComponent(response.razorpay_order_id)
                   + '&razorpay_payment_id=' + encodeURIComponent(response.razorpay_payment_id)
                   + '&razorpay_signature=' + encodeURIComponent(response.razorpay_signature)
                   + '&paymentId=' + encodeURIComponent(data.paymentId || '');
          fetch('verifyPayment', { method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' }, body: body })
            .then(function(r) { return r.json(); })
            .then(function(result) { window.location.href = result.redirect || 'payment-success.jsp'; })
            .catch(function() { window.location.href = 'payment-failed.jsp?error=network'; });
        },
        modal: { ondismiss: function() {
          if (placeBtn) { placeBtn.disabled=false; placeBtn.innerHTML='<i class="fa fa-lock"></i> Place Your Order'; }
        }}
      };
      var rzp = new Razorpay(options);
      rzp.on('payment.failed', function(resp) {
        fetch('verifyPayment', { method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
          body: 'razorpay_order_id=' + encodeURIComponent(resp.error.metadata.order_id)
              + '&razorpay_payment_id=' + encodeURIComponent(resp.error.metadata.payment_id)
              + '&razorpay_signature=FAILED&paymentId=' + encodeURIComponent(data.paymentId || '')
        }).finally(function() { window.location.href = 'payment-failed.jsp?error=payment_failed'; });
      });
      if (placeBtn) { placeBtn.disabled=false; placeBtn.innerHTML='<i class="fa fa-lock"></i> Place Your Order'; }
      rzp.open();
    })
    .catch(function(err) {
      alert(err.message || 'Could not initialise payment. Please try again.');
      if (placeBtn) { placeBtn.disabled=false; placeBtn.innerHTML='<i class="fa fa-lock"></i> Place Your Order'; }
    });
}
</script>
<script>
var BASE_TOTAL = <%=(int)orderTotal%>;
var WALLET_BALANCE = <%=walletBalance%>;
var currentCouponDiscount = 0;

function toggleWallet(chk) {
    var couponAmt = currentCouponDiscount;
    var walletAmt = chk.checked ? Math.min(WALLET_BALANCE, BASE_TOTAL - couponAmt) : 0;
    if (walletAmt < 0) walletAmt = 0;
    document.getElementById('useWalletInput').value    = chk.checked ? 'true' : 'false';
    document.getElementById('walletAmountInput').value = walletAmt.toFixed(2);
    document.getElementById('walletRow').style.display = walletAmt > 0 ? 'flex' : 'none';
    document.getElementById('walletSaving').textContent = '−₹' + walletAmt.toFixed(0);
    recalcTotal();
}

function recalcTotal() {
    var couponAmt  = currentCouponDiscount;
    var walletChk  = document.getElementById('useWalletChk');
    var walletAmt  = (walletChk && walletChk.checked)
                     ? Math.min(WALLET_BALANCE, BASE_TOTAL - couponAmt) : 0;
    if (walletAmt < 0) walletAmt = 0;
    var finalAmt = BASE_TOTAL - couponAmt - walletAmt;
    if (finalAmt < 0) finalAmt = 0;
    document.getElementById('finalTotal').textContent = '₹' + Math.round(finalAmt);
}
function applyCouponCode(code) {
    document.getElementById('couponInput').value = code;
    applyCoupon();
}
function applyCoupon() {
    var code = document.getElementById('couponInput').value.trim();
    if (!code) { showCouponMsg('Please enter a coupon code.', false); return; }
    fetch('applyCoupon?code=' + encodeURIComponent(code) + '&subtotal=<%=(int)subtotal%>')
        .then(r => r.json())
        .then(data => {
            if (data.valid) {
                currentCouponDiscount = data.discount;
                document.getElementById('couponCode').value     = code;
                document.getElementById('couponDiscount').value = data.discount;
                document.getElementById('couponRow').style.display = 'flex';
                document.getElementById('couponSaving').textContent = '−₹' + data.discount;
                recalcTotal();
                showCouponMsg('✓ Coupon applied! You save ₹' + data.discount + ' (' + data.description + ')', true);
            } else {
                currentCouponDiscount = 0;
                document.getElementById('couponCode').value = '';
                document.getElementById('couponDiscount').value = 0;
                document.getElementById('couponRow').style.display = 'none';
                recalcTotal();
                showCouponMsg(data.message || 'Invalid or expired coupon code.', false);
            }
        })
        .catch(() => showCouponMsg('Could not validate coupon. Try again.', false));
}
function showCouponMsg(text, ok) {
    var el = document.getElementById('couponMsg');
    el.textContent   = text;
    el.className     = 'coupon-msg ' + (ok ? 'ok' : 'err');
    el.style.display = 'block';
}
</script>
</body>
</html>