<%@ page language="java" contentType="text/html; charset=UTF-8" %>
<%@ page import="java.util.*, java.util.Set, com.sibs.dao.ProductDAO, com.sibs.model.Product, com.sibs.model.User, com.sibs.dao.NotificationDAO, com.sibs.dao.WishlistDAO, com.sibs.dao.CustomerWalletDAO, com.sibs.dao.ProductReviewDAO, com.sibs.dao.CouponDAO" %>
<%
ProductDAO dao = new ProductDAO();
List<Product> products = dao.getAllProducts();
User user = (User)session.getAttribute("customer");
if(user == null){
    response.sendRedirect("customer-login.jsp");
    return;
}
int _unread = 0;
try { _unread = new NotificationDAO().countUnreadForCustomer(user.getId()); } catch(Exception e){}
Set<Integer> _wishIds = new java.util.HashSet<>();
try { _wishIds = new WishlistDAO().getWishlistIds(user.getId()); } catch(Exception e){}
double _walletBal = 0;
try { _walletBal = new CustomerWalletDAO().getBalance(user.getId()); } catch(Exception e){}
List<Map<String,Object>> _coupons = new java.util.ArrayList<>();
try { _coupons = new CouponDAO().getAllCoupons(); } catch(Exception e){}
%>
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>SIBS Shop</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<style>
:root{--bg:#f8fafc;--surface:#fff;--border:#e2e8f0;--text:#0f172a;--muted:#64748b;--primary:#2563eb;--success:#16a34a;--danger:#ef4444;--warn:#f59e0b;}
[data-theme="dark"]{--bg:#0f172a;--surface:#1e293b;--border:#334155;--text:#f1f5f9;--muted:#94a3b8;}
*{margin:0;padding:0;box-sizing:border-box;font-family:'Inter',sans-serif;}
body{background:var(--bg);color:var(--text);}

/* TOPBAR */
.topbar{background:var(--surface);border-bottom:1px solid var(--border);padding:0 20px;height:58px;display:flex;align-items:center;gap:12px;position:sticky;top:0;z-index:100;box-shadow:0 1px 4px rgba(0,0,0,.07);}
.logo{font-weight:700;font-size:20px;color:var(--primary);white-space:nowrap;}
.search-wrap{flex:1;max-width:500px;position:relative;}
.search-wrap input{width:100%;padding:9px 14px 9px 38px;border:1px solid var(--border);border-radius:8px;background:var(--bg);color:var(--text);font-size:13px;outline:none;transition:.15s;}
.search-wrap input:focus{border-color:var(--primary);}
.search-wrap i{position:absolute;left:11px;top:50%;transform:translateY(-50%);color:var(--muted);font-size:13px;}
.topbar-actions{display:flex;align-items:center;gap:10px;margin-left:auto;}
.cart-btn{display:flex;align-items:center;gap:6px;background:var(--primary);color:#fff;padding:8px 14px;border-radius:8px;border:none;cursor:pointer;font-size:13px;font-weight:500;text-decoration:none;}
.cart-badge{background:#ef4444;color:#fff;border-radius:999px;padding:1px 7px;font-size:11px;font-weight:700;}
.user-btn{display:flex;align-items:center;gap:6px;cursor:pointer;padding:6px 10px;border-radius:8px;border:1px solid var(--border);font-size:13px;transition:.15s;}
.user-btn:hover{background:var(--bg);}
.dark-btn{background:none;border:1px solid var(--border);width:34px;height:34px;border-radius:8px;cursor:pointer;color:var(--muted);}
.notif-bell{position:relative;display:flex;align-items:center;justify-content:center;width:38px;height:38px;border-radius:8px;border:1px solid var(--border);cursor:pointer;background:var(--surface);color:var(--muted);font-size:16px;transition:.15s;flex-shrink:0;}
.notif-bell:hover{background:var(--bg);color:var(--primary);}
.notif-bell .dot{position:absolute;top:-4px;right:-4px;background:#ef4444;color:#fff;border-radius:50%;width:17px;height:17px;font-size:10px;font-weight:700;display:flex;align-items:center;justify-content:center;border:2px solid var(--surface);}

/* SLIDE MENU */
.slide-menu{position:fixed;top:0;left:-280px;width:280px;height:100%;background:var(--surface);border-right:1px solid var(--border);z-index:400;transition:.3s;padding:24px 0;overflow-y:auto;}
.slide-menu.open{left:0;}
.slide-overlay{position:fixed;inset:0;background:rgba(0,0,0,.4);z-index:399;display:none;}
.slide-overlay.open{display:block;}
.slide-header{padding:0 20px 20px;border-bottom:1px solid var(--border);margin-bottom:8px;}
.slide-header p{font-weight:600;font-size:15px;}
.slide-header span{font-size:12px;color:var(--muted);}
.slide-link{display:flex;align-items:center;gap:10px;padding:12px 20px;color:var(--text);text-decoration:none;font-size:14px;transition:.15s;}
.slide-link:hover{background:var(--bg);color:var(--primary);}
.slide-link i{width:16px;color:var(--muted);}

/* NOTIF DRAWER */
.notif-overlay{display:none;position:fixed;inset:0;background:rgba(0,0,0,.3);z-index:500;}
.notif-overlay.open{display:block;}
.notif-drawer{position:fixed;top:0;right:-360px;width:340px;height:100vh;background:var(--surface);border-left:1px solid var(--border);z-index:501;display:flex;flex-direction:column;box-shadow:-4px 0 24px rgba(0,0,0,.12);transition:right .3s;}
.notif-drawer.open{right:0;}
.notif-hdr{padding:16px 18px;border-bottom:1px solid var(--border);display:flex;align-items:center;justify-content:space-between;}
.notif-hdr h3{font-size:14px;font-weight:700;display:flex;align-items:center;gap:6px;}
.notif-close{background:none;border:none;cursor:pointer;font-size:18px;color:var(--muted);padding:4px;}
.notif-mark-all{background:none;border:none;color:var(--primary);font-size:12px;cursor:pointer;font-weight:500;}
.notif-mark-all:hover{text-decoration:underline;}
.notif-list{flex:1;overflow-y:auto;padding:10px;}
.notif-item{border-radius:10px;padding:12px;margin-bottom:8px;border:1px solid var(--border);cursor:pointer;transition:.1s;display:flex;gap:10px;align-items:flex-start;}
.notif-item:hover{background:var(--bg);}
.notif-item.unread{background:#eff6ff;border-color:#bfdbfe;}
.notif-icon{width:34px;height:34px;border-radius:50%;display:flex;align-items:center;justify-content:center;flex-shrink:0;font-size:14px;}
.notif-icon.ORDER{background:#dbeafe;color:#1d4ed8;}
.notif-icon.RETURN{background:#fef3c7;color:#b45309;}
.notif-icon.COMPLAINT{background:#fee2e2;color:#b91c1c;}
.notif-icon.SYSTEM{background:#f1f5f9;color:#475569;}
.notif-body{flex:1;min-width:0;}
.notif-title{font-size:13px;font-weight:600;}
.notif-msg{font-size:12px;color:var(--muted);margin-top:2px;line-height:1.5;}
.notif-time{font-size:11px;color:var(--muted);margin-top:4px;}
.notif-dot{width:7px;height:7px;border-radius:50%;background:#2563eb;flex-shrink:0;margin-top:6px;}
.notif-empty{text-align:center;padding:40px 20px;color:var(--muted);font-size:13px;}
.notif-empty i{font-size:28px;display:block;margin-bottom:10px;opacity:.4;}
.notif-footer{padding:12px 18px;border-top:1px solid var(--border);}
.notif-footer a{display:block;text-align:center;font-size:13px;font-weight:600;color:var(--primary);text-decoration:none;padding:9px;border-radius:8px;border:1px solid var(--border);}
.notif-footer a:hover{background:var(--bg);}

/* HERO */
.hero{background:linear-gradient(120deg,#1e3a8a,#1d4ed8);color:#fff;padding:40px 20px;text-align:center;position:relative;overflow:hidden;}
.hero::before{content:'';position:absolute;top:-60px;right:-60px;width:220px;height:220px;background:rgba(255,255,255,.06);border-radius:50%;}
.hero::after{content:'';position:absolute;bottom:-60px;left:-40px;width:180px;height:180px;background:rgba(255,255,255,.06);border-radius:50%;}
.hero h2{font-size:26px;font-weight:700;margin-bottom:6px;position:relative;}
.hero p{font-size:14px;opacity:.85;margin-bottom:18px;position:relative;}
.hero-badges{display:flex;justify-content:center;gap:10px;flex-wrap:wrap;position:relative;}
.hero-badge{background:rgba(255,255,255,.15);border:1px solid rgba(255,255,255,.3);color:#fff;padding:5px 14px;border-radius:20px;font-size:12px;}

/* OFFERS BAR */
.offers-bar{background:#fef3c7;border-bottom:1px solid #fde68a;padding:10px 20px;display:flex;align-items:center;gap:10px;flex-wrap:wrap;font-size:13px;color:#92400e;}
.offer-chip{background:#f59e0b;color:#fff;padding:4px 12px;border-radius:20px;font-size:12px;font-weight:600;border:none;cursor:pointer;transition:background .2s;}
.offer-chip:hover{background:#d97706;}

/* FILTERS */
.filters{padding:14px 20px;background:var(--surface);border-bottom:1px solid var(--border);display:flex;gap:8px;flex-wrap:wrap;align-items:center;}
.filter-btn{padding:6px 14px;border:1px solid var(--border);border-radius:999px;background:none;cursor:pointer;font-size:12px;font-weight:500;color:var(--muted);transition:.15s;}
.filter-btn:hover,.filter-btn.active{border-color:var(--primary);color:var(--primary);background:#eff6ff;}
.filter-label{font-size:12px;font-weight:600;color:var(--muted);margin-right:4px;}

/* PRODUCT GRID */
.grid-wrap{padding:20px;}
.grid-header{display:flex;align-items:center;justify-content:space-between;margin-bottom:14px;}
.grid-title{font-size:15px;font-weight:600;color:var(--text);}
.grid-count{font-size:12px;color:var(--muted);}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(185px,1fr));gap:16px;}

/* CARD */
.card{background:var(--surface);border:1px solid var(--border);border-radius:12px;overflow:hidden;transition:transform .2s,box-shadow .2s,border-color .2s;display:flex;flex-direction:column;}
.card:hover{box-shadow:0 8px 24px rgba(0,0,0,.12);transform:translateY(-4px);border-color:var(--primary);}

/* CARD IMAGE */
.card-img{height:150px;display:flex;align-items:center;justify-content:center;background:#f1f5f9;padding:14px;position:relative;border-radius:10px 10px 0 0;}
[data-theme="dark"] .card-img{background:#1e293b;}
.card-img img{max-height:120px;max-width:100%;object-fit:contain;}

/* DISCOUNT BADGE */
.disc-badge{position:absolute;top:8px;left:8px;background:#16a34a;color:#fff;font-size:10px;font-weight:700;padding:3px 9px;border-radius:20px;z-index:2;letter-spacing:.3px;}

/* WISHLIST */
.heart-btn{position:absolute;top:8px;right:8px;width:30px;height:30px;border-radius:50%;background:rgba(255,255,255,.92);border:1px solid #e2e8f0;cursor:pointer;font-size:13px;display:flex;align-items:center;justify-content:center;transition:.15s;z-index:2;}
.heart-btn:hover{transform:scale(1.15);}
.heart-btn.wishlisted{color:#e11d48;}
.heart-btn:not(.wishlisted){color:#cbd5e1;}

/* CARD BODY */
.card-body{padding:12px;display:flex;flex-direction:column;flex:1;}
.card-name{font-size:13px;font-weight:600;margin-bottom:2px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;color:var(--text);}

/* DESCRIPTION */
.card-desc{font-size:11px;color:var(--muted);margin-bottom:5px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;min-height:16px;line-height:1.5;}

/* META: weight + stock */
.card-meta{display:flex;align-items:center;gap:6px;margin-bottom:6px;font-size:11px;color:var(--muted);}
.stock-in{font-size:10px;color:#16a34a;font-weight:600;display:flex;align-items:center;gap:3px;}
.stock-out{font-size:10px;color:#dc2626;font-weight:600;display:flex;align-items:center;gap:3px;}
.stock-dot{width:6px;height:6px;border-radius:50%;display:inline-block;}
.stock-dot.in{background:#16a34a;}
.stock-dot.out{background:#dc2626;}

/* PRICE */
.price-row{display:flex;align-items:center;gap:6px;margin-bottom:6px;flex-wrap:wrap;}
.price-new{font-size:16px;font-weight:700;color:var(--danger);}
.price-old{font-size:11px;color:var(--muted);text-decoration:line-through;}

/* RATING */
.rating-row{display:flex;align-items:center;gap:3px;padding:4px 0 6px;min-height:22px;}
.rating-row a{display:flex;align-items:center;gap:3px;text-decoration:none;font-size:11px;color:var(--muted);}
.rating-row a:hover{color:var(--primary);}
.star-filled{color:#f59e0b;font-size:11px;}
.star-empty{color:#e2e8f0;font-size:11px;}
.rating-score{color:#f59e0b;font-weight:700;font-size:11px;}
.rating-count{color:var(--muted);font-size:11px;}
.no-reviews{font-size:11px;color:var(--muted);font-style:italic;}

/* QTY */
.qty-row{display:flex;align-items:center;gap:8px;margin-bottom:8px;}
.qty-btn{width:26px;height:26px;border:1px solid var(--border);background:var(--bg);cursor:pointer;border-radius:6px;font-size:14px;display:flex;align-items:center;justify-content:center;transition:.15s;color:var(--text);}
.qty-btn:hover{border-color:var(--primary);color:var(--primary);}
.qty-val{font-size:13px;font-weight:600;min-width:20px;text-align:center;color:var(--text);}

/* ACTION BUTTONS */
.card-actions{display:flex;gap:6px;margin-top:auto;}
.btn-add{flex:1;padding:8px;background:var(--bg);border:1px solid var(--border);border-radius:7px;cursor:pointer;font-size:12px;font-weight:500;transition:.15s;display:flex;align-items:center;justify-content:center;gap:4px;color:var(--text);}
.btn-add:hover:not(:disabled){border-color:var(--primary);color:var(--primary);background:#eff6ff;}
.btn-buy{flex:1;padding:8px;background:var(--primary);color:#fff;border:none;border-radius:7px;cursor:pointer;font-size:12px;font-weight:500;transition:.15s;}
.btn-buy:hover:not(:disabled){background:#1d4ed8;}
.btn-add:disabled,.btn-buy:disabled{opacity:.45;cursor:not-allowed;}

/* EMPTY */
.empty{text-align:center;padding:60px 20px;color:var(--muted);}
.empty i{font-size:40px;margin-bottom:12px;display:block;}

/* FOOTER */
.footer{background:var(--surface);border-top:1px solid var(--border);margin-top:40px;padding:40px 20px 0;}
.footer-grid{max-width:1100px;margin:0 auto;display:grid;grid-template-columns:repeat(auto-fit,minmax(200px,1fr));gap:32px;padding-bottom:32px;}
.footer-brand-desc{font-size:13px;color:var(--muted);line-height:1.7;margin-top:10px;}
.footer-heading{font-size:12px;font-weight:700;color:var(--text);margin-bottom:14px;text-transform:uppercase;letter-spacing:.6px;}
.footer-link{display:flex;align-items:center;gap:7px;font-size:13px;color:var(--muted);text-decoration:none;padding:4px 0;transition:.15s;}
.footer-link:hover{color:var(--primary);}
.footer-link i{font-size:10px;}
.footer-social{display:flex;gap:10px;margin-top:14px;}
.social-btn{width:34px;height:34px;border-radius:8px;border:1px solid var(--border);display:flex;align-items:center;justify-content:center;color:var(--muted);text-decoration:none;font-size:14px;transition:.15s;}
.social-btn:hover{border-color:var(--primary);color:var(--primary);}
.footer-contact-item{display:flex;align-items:flex-start;gap:10px;margin-bottom:12px;font-size:13px;color:var(--muted);}
.footer-contact-item i{color:var(--primary);margin-top:2px;width:14px;}
.footer-bottom{border-top:1px solid var(--border);padding:16px 20px;text-align:center;font-size:12px;color:var(--muted);display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:8px;max-width:1100px;margin:0 auto;}
.footer-bottom-links{display:flex;gap:16px;}
.footer-bottom-links a{font-size:12px;color:var(--muted);text-decoration:none;transition:.15s;}
.footer-bottom-links a:hover{color:var(--primary);}

/* TOAST */
#toast{position:fixed;bottom:24px;right:24px;background:#16a34a;color:#fff;padding:12px 18px;border-radius:8px;font-size:13px;font-weight:500;display:none;z-index:9999;box-shadow:0 4px 12px rgba(0,0,0,.2);align-items:center;gap:8px;max-width:280px;}
#toast.show{display:flex;}

@media(max-width:600px){
  .hero h2{font-size:18px;}
  .topbar-actions .user-btn span{display:none;}
  .footer-bottom{flex-direction:column;text-align:center;}
}
</style>
</head>
<body>

<!-- SLIDE MENU OVERLAY -->
<div class="slide-overlay" id="overlay" onclick="closeMenu()"></div>
<div class="slide-menu" id="menu">
  <div class="slide-header">
    <p>👋 <%=user.getUsername()%></p>
    <span><%=user.getEmail()%></span>
  </div>
  <a class="slide-link" href="customer-dashboard.jsp"><i class="fa fa-home"></i> Shop</a>
  <a class="slide-link" href="wishlist.jsp"><i class="fa fa-heart"></i> My Wishlist</a>
  <a class="slide-link" href="customer-wallet.jsp">
    <i class="fa fa-wallet"></i> My Wallet
    <% if(_walletBal > 0){ %>
    <span style="margin-left:auto;font-size:11px;background:#dcfce7;color:#16a34a;border-radius:999px;padding:1px 8px;font-weight:700;">₹<%=String.format("%.0f",_walletBal)%></span>
    <% } %>
  </a>
  <a class="slide-link" href="cart.jsp"><i class="fa fa-cart-shopping"></i> My Cart</a>
  <a class="slide-link" href="my-orders.jsp"><i class="fa fa-box"></i> My Orders</a>
  <a class="slide-link" href="myreturns.jsp"><i class="fa fa-rotate-left"></i> My Returns</a>
  <a class="slide-link" href="paymentHistory"><i class="fa fa-receipt"></i> Payment History</a>
  <a class="slide-link" href="customer-profile.jsp"><i class="fa fa-user"></i> Profile</a>
  <a class="slide-link" href="customer-support.jsp"><i class="fa fa-headset"></i> Help &amp; Support</a>
  <a class="slide-link" href="logout" style="color:var(--danger);"><i class="fa fa-sign-out-alt"></i> Logout</a>
</div>

<!-- NOTIF DRAWER -->
<div class="notif-overlay" id="notifOverlay" onclick="closeNotif()"></div>
<div class="notif-drawer" id="notifDrawer">
  <div class="notif-hdr">
    <h3><i class="fa fa-bell" style="color:var(--primary);"></i> Notifications
      <span id="notifBadgeHdr" style="background:#ef4444;color:#fff;border-radius:20px;padding:1px 7px;font-size:10px;display:none;"></span>
    </h3>
    <div style="display:flex;align-items:center;gap:10px;">
      <button class="notif-mark-all" onclick="markAllRead()">Mark all read</button>
      <button class="notif-close" onclick="closeNotif()"><i class="fa fa-xmark"></i></button>
    </div>
  </div>
  <div class="notif-list" id="notifList"><div class="notif-empty"><i class="fa fa-clock"></i> Loading…</div></div>
  <div class="notif-footer"><a href="my-orders.jsp"><i class="fa fa-box"></i> View My Orders</a></div>
</div>

<!-- TOPBAR -->
<div class="topbar">
  <button onclick="openMenu()" style="background:none;border:none;cursor:pointer;color:var(--muted);font-size:18px;"><i class="fa fa-bars"></i></button>
  <div class="logo">🌿 SIBS</div>
  <div class="search-wrap">
    <i class="fa fa-search"></i>
    <input type="text" id="searchInput" placeholder="Search products..." oninput="filterProducts()">
  </div>
  <div class="topbar-actions">
    <button class="dark-btn" onclick="toggleDark()" title="Toggle dark mode"><i class="fa fa-moon"></i></button>
    <div class="notif-bell" onclick="openNotif()" title="Notifications">
      <i class="fa fa-bell"></i>
      <span class="dot" id="notifCount" style="display:none;"></span>
    </div>
    <a class="cart-btn" href="cart.jsp">
      <i class="fa fa-cart-shopping"></i>
      <span>Cart</span>
      <span class="cart-badge" id="cartCount">0</span>
    </a>
    <div class="user-btn" onclick="openMenu()">
      <i class="fa fa-user"></i>
      <span><%=user.getUsername()%></span>
    </div>
  </div>
</div>

<!-- HERO -->
<div class="hero">
  <h2>🥦 Fresh Groceries &amp; More</h2>
  <p>Quality products delivered fast — Browse and order easily</p>
  <div class="hero-badges">
    <span class="hero-badge">🚚 Free delivery above ₹200</span>
    <span class="hero-badge">✅ 100% Fresh</span>
    <span class="hero-badge">⚡ Same day delivery</span>
  </div>
</div>

<!-- OFFERS BAR -->
<%
boolean _hasOffer = false;
for(Map<String,Object> c : _coupons){
    Object act = c.get("is_active");
    if(act != null && Integer.valueOf(1).equals(act)){ _hasOffer = true; break; }
}
if(_hasOffer){ %>
<div class="offers-bar">
  🎟️ <strong>Available Offers:</strong>
  <% for(Map<String,Object> c : _coupons){
       Object act = c.get("is_active");
       if(act != null && Integer.valueOf(1).equals(act)){ %>
    <button class="offer-chip" onclick="copyCode('<%=c.get("code")%>')">
      <%=c.get("code")%> — <%=c.get("description")%>
    </button>
  <% } } %>
  <span style="font-size:12px;">Click to copy &amp; apply at checkout!</span>
</div>
<% } %>

<!-- FILTERS -->
<div class="filters">
  <span class="filter-label">Filter:</span>
  <button class="filter-btn active" onclick="setFilter('ALL',this)">🏪 All</button>
  <button class="filter-btn" onclick="setFilter('vegetables',this)">🥦 Vegetables</button>
  <button class="filter-btn" onclick="setFilter('fruits',this)">🍎 Fruits</button>
  <button class="filter-btn" onclick="setFilter('non-veg',this)">🍗 Non-Veg</button>
  <button class="filter-btn" onclick="setFilter('dairy',this)">🥛 Dairy</button>
  <button class="filter-btn" onclick="setFilter('beverages',this)">🥤 Drinks</button>
  <button class="filter-btn" onclick="setFilter('snacks',this)">🍿 Snacks</button>
</div>

<!-- PRODUCTS -->
<div class="grid-wrap">
  <div class="grid-header">
    <span class="grid-title">🛍️ Today's Fresh Picks</span>
    <span class="grid-count" id="gridCount"></span>
  </div>
  <div class="grid" id="productGrid">
  <%
  if(products != null){
    for(Product p : products){
      String img = (p.getImagePath() != null && !p.getImagePath().trim().isEmpty())
        ? request.getContextPath()+"/"+p.getImagePath()
        : request.getContextPath()+"/images/default.png";
      String cat = (p.getCategory() != null) ? p.getCategory().toLowerCase().trim() : "";
      double origPrice = p.getPrice() * 1.10;
      int discountPct = (int)Math.round(((origPrice - p.getPrice()) / origPrice) * 100);
      double[] rInfo = new double[]{0,0};
      try{ rInfo = new ProductReviewDAO().getProductRating(p.getId()); }catch(Exception e){}
      double avgR = rInfo[0];
      int cntR = (rInfo.length > 1) ? (int)rInfo[1] : 0;
      int roundedRating = (int)Math.round(avgR);
  %>
  <div class="card product-card" data-category="<%=cat%>" data-name="<%=p.getName().toLowerCase()%>">
    <div class="card-img">
      <div class="disc-badge">-<%=discountPct%>%</div>
      <img src="<%=img%>" alt="<%=p.getName()%>" onerror="this.src='images/default.png'">
      <button class="heart-btn <%=_wishIds.contains(p.getId())?"wishlisted":""%>"
        id="heart_<%=p.getId()%>"
        onclick="toggleWishlist(<%=p.getId()%>)"
        title="<%=_wishIds.contains(p.getId())?"Remove from wishlist":"Add to wishlist"%>">
        <i class="fa fa-heart"></i>
      </button>
    </div>

    <div class="card-body">
      <div class="card-name" title="<%=p.getName()%>"><%=p.getName()%></div>

      <!-- DESCRIPTION -->
      <div class="card-desc">
        <% if(p.getDescription() != null && !p.getDescription().trim().isEmpty()){ %>
          <%=p.getDescription()%>
        <% } else { %>&nbsp;<% } %>
      </div>

      <!-- WEIGHT + STOCK -->
      <div class="card-meta">
        <% if(p.getUnit() != null && !p.getUnit().trim().isEmpty()){ %>
        <span style="display:flex;align-items:center;gap:3px;">
          <i class="fa fa-weight-hanging" style="font-size:9px;"></i> <%=p.getUnit()%>
        </span>
        <span style="color:var(--border);">•</span>
        <% } %>
        <% if(!p.isInStock()){ %>
        <span class="stock-out"><span class="stock-dot out"></span> Out of Stock</span>
        <% } else { %>
        <span class="stock-in"><span class="stock-dot in"></span> In Stock</span>
        <% } %>
      </div>

      <!-- PRICE -->
      <div class="price-row">
        <span class="price-new">₹<%=(int)p.getPrice()%></span>
        <span class="price-old">₹<%=String.format("%.0f",origPrice)%></span>
      </div>

      <!-- RATING -->
      <div class="rating-row">
        <a href="product-reviews.jsp?productId=<%=p.getId()%>">
          <% if(cntR > 0){ %>
          <% for(int s=1;s<=5;s++){ %>
            <i class="fa fa-star <%=s<=roundedRating?"star-filled":"star-empty"%>"></i>
          <% } %>
          <span class="rating-score"><%=String.format("%.1f",avgR)%></span>
          <span class="rating-count">(<%=cntR%>)</span>
          <% } else { %>
          <span class="no-reviews">No reviews yet</span>
          <% } %>
        </a>
      </div>

      <!-- QTY -->
      <div class="qty-row">
        <button class="qty-btn" onclick="changeQty(<%=p.getId()%>,-1)">−</button>
        <span class="qty-val" id="q_<%=p.getId()%>">1</span>
        <button class="qty-btn" onclick="changeQty(<%=p.getId()%>,1)">+</button>
        <span style="font-size:11px;color:var(--muted);">Qty</span>
      </div>

      <!-- ACTIONS -->
      <div class="card-actions">
        <button class="btn-add"
          <%=!p.isInStock()?"disabled":""%>
          onclick="<%=p.isInStock()?"addToCart("+p.getId()+",'"+p.getName().replace("'","")+"',"+p.getPrice()+",'"+p.getImagePath()+"')":""%>">
          <i class="fa fa-cart-plus"></i> Add
        </button>
        <form action="buyNow" method="post" class="buyForm" style="flex:1;">
          <input type="hidden" name="productId" value="<%=p.getId()%>">
          <input type="hidden" name="qty" id="buy_qty_<%=p.getId()%>" value="1">
          <button type="submit" class="btn-buy" style="width:100%;" <%=!p.isInStock()?"disabled":""%>>Buy Now</button>
        </form>
      </div>
    </div>
  </div>
  <% } } %>
  </div>
  <div class="empty" id="emptyState" style="display:none;">
    <i class="fa fa-box-open"></i>
    <p>No products found</p>
  </div>
</div>

<!-- FOOTER -->
<footer class="footer">
  <div class="footer-grid">

    <!-- Brand & About -->
    <div>
      <div style="font-size:22px;font-weight:700;color:var(--primary);">🌿 SIBS</div>
      <p class="footer-brand-desc">
        SIBS is your trusted online grocery store delivering fresh vegetables, fruits, dairy, and daily essentials right to your doorstep. Quality products at the best prices with same-day delivery.
      </p>
      <div class="footer-social">
        <a class="social-btn" href="#" title="Facebook"><i class="fa-brands fa-facebook-f"></i></a>
        <a class="social-btn" href="#" title="Instagram"><i class="fa-brands fa-instagram"></i></a>
        <a class="social-btn" href="#" title="Twitter"><i class="fa-brands fa-twitter"></i></a>
        <a class="social-btn" href="#" title="YouTube"><i class="fa-brands fa-youtube"></i></a>
      </div>
    </div>

    <!-- Quick Links -->
    <div>
      <p class="footer-heading">Quick Links</p>
      <a class="footer-link" href="customer-dashboard.jsp"><i class="fa fa-chevron-right"></i> Shop</a>
      <a class="footer-link" href="cart.jsp"><i class="fa fa-chevron-right"></i> My Cart</a>
      <a class="footer-link" href="my-orders.jsp"><i class="fa fa-chevron-right"></i> My Orders</a>
      <a class="footer-link" href="wishlist.jsp"><i class="fa fa-chevron-right"></i> My Wishlist</a>
      <a class="footer-link" href="myreturns.jsp"><i class="fa fa-chevron-right"></i> My Returns</a>
      <a class="footer-link" href="customer-wallet.jsp"><i class="fa fa-chevron-right"></i> My Wallet</a>
      <a class="footer-link" href="paymentHistory"><i class="fa fa-chevron-right"></i> Payment History</a>
    </div>

    <!-- Categories -->
    <div>
      <p class="footer-heading">Categories</p>
      <a class="footer-link" href="#" onclick="setFilterFooter('vegetables')"><i class="fa fa-chevron-right"></i> 🥦 Vegetables</a>
      <a class="footer-link" href="#" onclick="setFilterFooter('fruits')"><i class="fa fa-chevron-right"></i> 🍎 Fruits</a>
      <a class="footer-link" href="#" onclick="setFilterFooter('dairy')"><i class="fa fa-chevron-right"></i> 🥛 Dairy</a>
      <a class="footer-link" href="#" onclick="setFilterFooter('non-veg')"><i class="fa fa-chevron-right"></i> 🍗 Non-Veg</a>
      <a class="footer-link" href="#" onclick="setFilterFooter('beverages')"><i class="fa fa-chevron-right"></i> 🥤 Drinks</a>
      <a class="footer-link" href="#" onclick="setFilterFooter('snacks')"><i class="fa fa-chevron-right"></i> 🍿 Snacks</a>
    </div>

    <!-- Contact & Help -->
    <div>
      <p class="footer-heading">Contact Us</p>
      <div class="footer-contact-item">
        <i class="fa fa-location-dot"></i>
        <span>123 Market Street, Anantapur, Andhra Pradesh - 515001</span>
      </div>
      <div class="footer-contact-item">
        <i class="fa fa-phone"></i>
        <span>+91 98765 43210</span>
      </div>
      <div class="footer-contact-item">
        <i class="fa fa-envelope"></i>
        <span>support@sibs.in</span>
      </div>
      <div class="footer-contact-item">
        <i class="fa fa-clock"></i>
        <span>Mon – Sat: 8:00 AM – 8:00 PM</span>
      </div>
      <div style="margin-top:12px;">
        <a class="footer-link" href="customer-support.jsp"><i class="fa fa-headset"></i> &nbsp;Help &amp; Support</a>
        <a class="footer-link" href="customer-profile.jsp"><i class="fa fa-user"></i> &nbsp;My Profile</a>
      </div>
    </div>

  </div>

  <!-- Footer Bottom -->
  <div style="border-top:1px solid var(--border);padding:16px 0;margin:0 auto;max-width:1100px;display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:8px;">
    <span style="font-size:12px;color:var(--muted);">© 2025 SIBS Grocery. All rights reserved.</span>
    <div style="display:flex;gap:16px;">
      <a href="#" style="font-size:12px;color:var(--muted);text-decoration:none;" onmouseover="this.style.color='var(--primary)'" onmouseout="this.style.color='var(--muted)'">Privacy Policy</a>
      <a href="#" style="font-size:12px;color:var(--muted);text-decoration:none;" onmouseover="this.style.color='var(--primary)'" onmouseout="this.style.color='var(--muted)'">Terms of Use</a>
      <a href="#" style="font-size:12px;color:var(--muted);text-decoration:none;" onmouseover="this.style.color='var(--primary)'" onmouseout="this.style.color='var(--muted)'">Refund Policy</a>
    </div>
  </div>
</footer>

<div id="toast"><i class="fa fa-check-circle"></i> <span id="toastMsg">Added to cart!</span></div>

<script>
var _CTX='<%=request.getContextPath()%>';
var _ICONS={ORDER:'fa-box',RETURN:'fa-rotate-left',COMPLAINT:'fa-headset',DELIVERY:'fa-motorcycle',SYSTEM:'fa-bell'};

function toggleDark(){
  const h=document.documentElement,d=h.getAttribute('data-theme')==='dark';
  h.setAttribute('data-theme',d?'light':'dark');
  localStorage.setItem('sibs-theme',d?'light':'dark');
}
(function(){const t=localStorage.getItem('sibs-theme');if(t)document.documentElement.setAttribute('data-theme',t);})();

function openMenu(){document.getElementById('menu').classList.add('open');document.getElementById('overlay').classList.add('open');}
function closeMenu(){document.getElementById('menu').classList.remove('open');document.getElementById('overlay').classList.remove('open');}

function openNotif(){
  document.getElementById('notifDrawer').classList.add('open');
  document.getElementById('notifOverlay').classList.add('open');
  loadNotifications();
}
function closeNotif(){
  document.getElementById('notifDrawer').classList.remove('open');
  document.getElementById('notifOverlay').classList.remove('open');
}
function loadNotifications(){
  fetch(_CTX+'/getNotifications')
    .then(r=>r.json())
    .then(data=>{
      setBadge(data.unread);
      var list=document.getElementById('notifList');
      if(!data.items||data.items.length===0){
        list.innerHTML='<div class="notif-empty"><i class="fa fa-bell-slash"></i> All caught up!</div>';return;
      }
      list.innerHTML=data.items.map(n=>
        '<div class="notif-item '+(n.isRead?'':'unread')+'" onclick="openNotifItem('+n.id+',\''+encodeURIComponent(n.linkUrl||'')+'\')">'+
        '<div class="notif-icon '+n.category+'"><i class="fa '+(_ICONS[n.category]||'fa-bell')+'"></i></div>'+
        '<div class="notif-body"><div class="notif-title">'+n.title+'</div>'+
        '<div class="notif-msg">'+n.message+'</div>'+
        '<div class="notif-time">'+n.relativeTime+'</div></div>'+
        (n.isRead?'':'<div class="notif-dot"></div>')+
        '</div>'
      ).join('');
    })
    .catch(()=>{document.getElementById('notifList').innerHTML='<div class="notif-empty">Could not load</div>';});
}
function openNotifItem(id,encodedUrl){
  fetch(_CTX+'/getNotifications?action=markRead&id='+id,{method:'POST'});
  var url=decodeURIComponent(encodedUrl);
  if(url)window.location.href=_CTX+url;
}
function markAllRead(){
  fetch(_CTX+'/getNotifications?action=markAllRead',{method:'POST'})
    .then(r=>r.json()).then(()=>{setBadge(0);loadNotifications();});
}
function setBadge(n){
  var dot=document.getElementById('notifCount'),hdr=document.getElementById('notifBadgeHdr');
  if(n>0){dot.textContent=n>9?'9+':n;dot.style.display='flex';hdr.textContent=n;hdr.style.display='';}
  else{dot.style.display='none';hdr.style.display='none';}
}
setBadge(<%=_unread%>);
setInterval(()=>{fetch(_CTX+'/getNotifications').then(r=>r.json()).then(d=>setBadge(d.unread)).catch(()=>{});},60000);

function showToast(msg){
  document.getElementById('toastMsg').textContent=msg||'Done!';
  const t=document.getElementById('toast');
  t.classList.add('show');
  setTimeout(()=>t.classList.remove('show'),2500);
}

function toggleWishlist(productId){
  fetch(_CTX+'/wishlist',{method:'POST',
    headers:{'Content-Type':'application/x-www-form-urlencoded'},
    body:'action=toggle&productId='+productId})
  .then(r=>r.json()).then(data=>{
    var btn=document.getElementById('heart_'+productId);
    if(!btn)return;
    if(data.wishlisted){
      btn.classList.add('wishlisted');btn.title='Remove from wishlist';
      showToast('❤️ Added to wishlist!');
    } else {
      btn.classList.remove('wishlisted');btn.title='Add to wishlist';
      showToast('Removed from wishlist');
    }
  }).catch(()=>showToast('Please login to use wishlist'));
}

function changeQty(id,val){
  const el=document.getElementById('q_'+id);
  let q=parseInt(el.textContent)+val;
  if(q<1)q=1;
  el.textContent=q;
  const b=document.getElementById('buy_qty_'+id);
  if(b)b.value=q;
}

let activeFilter='ALL';
function setFilter(cat,btn){
  activeFilter=cat;
  document.querySelectorAll('.filter-btn').forEach(b=>b.classList.remove('active'));
  btn.classList.add('active');
  filterProducts();
}
function setFilterFooter(cat){
  activeFilter=cat;
  document.querySelectorAll('.filter-btn').forEach(b=>{
    b.classList.remove('active');
    if(b.getAttribute('onclick')&&b.getAttribute('onclick').includes("'"+cat+"'")){b.classList.add('active');}
  });
  filterProducts();
  window.scrollTo({top:0,behavior:'smooth'});
}
function filterProducts(){
  const q=document.getElementById('searchInput').value.toLowerCase().trim();
  const cards=document.querySelectorAll('.product-card');
  let visible=0;
  cards.forEach(c=>{
    const matchSearch=!q||c.getAttribute('data-name').includes(q);
    const matchCat=activeFilter==='ALL'||c.getAttribute('data-category').includes(activeFilter);
    if(matchSearch&&matchCat){c.style.display='';visible++;}
    else{c.style.display='none';}
  });
  document.getElementById('emptyState').style.display=visible===0?'':'none';
  const gc=document.getElementById('gridCount');
  if(gc)gc.textContent=visible+' items';
}

document.addEventListener('DOMContentLoaded',()=>{
  const total=document.querySelectorAll('.product-card').length;
  const gc=document.getElementById('gridCount');
  if(gc)gc.textContent=total+' items';
  document.querySelectorAll('.buyForm').forEach(f=>{
    f.addEventListener('submit',function(){
      const pid=f.querySelector('input[name="productId"]').value;
      const q=document.getElementById('q_'+pid);
      const bq=document.getElementById('buy_qty_'+pid);
      if(q&&bq)bq.value=q.textContent;
    });
  });
});

function addToCart(id,name,price,img){
  const qty=parseInt(document.getElementById('q_'+id).textContent)||1;
  fetch('addToCart',{
    method:'POST',
    headers:{'Content-Type':'application/x-www-form-urlencoded'},
    body:'productId='+id+'&qty='+qty+'&price='+price+'&img='+encodeURIComponent(img||'')
  }).then(()=>{
    showToast('✅ '+name+' × '+qty+' added!');
    updateCartCount();
  }).catch(()=>showToast('✅ Added to cart!'));
}

function updateCartCount(){
  fetch('getCartCount').then(r=>r.text()).then(c=>{
    document.getElementById('cartCount').textContent=c||'0';
  }).catch(()=>{});
}
updateCartCount();
setInterval(updateCartCount,10000);

function copyCode(code){
  navigator.clipboard.writeText(code)
    .then(()=>showToast('📋 "'+code+'" copied! Apply at checkout.'))
    .catch(()=>showToast('Use code: '+code+' at checkout!'));
}
</script>
</body>
</html>
