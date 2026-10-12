<%@ page import="com.sibs.model.User, com.sibs.model.Notification,
                 com.sibs.dao.NotificationDAO, java.util.List" %>
<%
User navUser = (User) session.getAttribute("customer");
if (navUser == null) {
    response.sendRedirect(request.getContextPath() + "/customer-login.jsp");
    return;
}

// Load unread count and recent notifications using NotificationDAO
int navUnread = 0;
List<Notification> navNotifications = new java.util.ArrayList<>();
try {
    if (navUser.getId() > 0) {
        NotificationDAO navNdao = new NotificationDAO();
        navUnread = navNdao.countUnreadForCustomer(navUser.getId());
        navNotifications = navNdao.getForCustomer(navUser.getId(), 15);
    }
} catch (Exception e) { }
%>
<style>
:root{--bg:#f8fafc;--surface:#fff;--border:#e2e8f0;--text:#0f172a;--muted:#64748b;--primary:#2563eb;--success:#16a34a;--danger:#ef4444;--warn:#f59e0b;}
*{margin:0;padding:0;box-sizing:border-box;font-family:'Inter',sans-serif;}
body{background:var(--bg);color:var(--text);}
.notif-bell{position:relative;display:flex;align-items:center;justify-content:center;width:38px;height:38px;border-radius:8px;border:1px solid var(--border);cursor:pointer;background:var(--surface);color:var(--muted);font-size:16px;transition:.15s;}
.notif-bell:hover{background:var(--bg);color:var(--primary);}
.notif-bell .dot{position:absolute;top:-4px;right:-4px;background:#ef4444;color:#fff;border-radius:50%;width:17px;height:17px;font-size:10px;font-weight:700;display:flex;align-items:center;justify-content:center;border:2px solid var(--surface);}
/* Notif drawer */
.nav-notif-overlay{display:none;position:fixed;inset:0;background:rgba(0,0,0,.3);z-index:500;}
.nav-notif-overlay.open{display:block;}
.nav-notif-drawer{display:none;position:fixed;top:0;right:0;width:340px;height:100vh;background:var(--surface);border-left:1px solid var(--border);z-index:501;flex-direction:column;box-shadow:-4px 0 24px rgba(0,0,0,.12);}
.nav-notif-drawer.open{display:flex;}
.nav-notif-hdr{padding:16px 18px;border-bottom:1px solid var(--border);display:flex;align-items:center;justify-content:space-between;}
.nav-notif-hdr h3{font-size:14px;font-weight:700;display:flex;align-items:center;gap:6px;}
.nav-notif-close{background:none;border:none;cursor:pointer;font-size:18px;color:var(--muted);padding:4px;}
.nav-notif-list{flex:1;overflow-y:auto;padding:12px;}
.nav-notif-item{border-radius:10px;padding:13px;margin-bottom:10px;border:1px solid;cursor:pointer;transition:.1s;}
.nav-notif-item:hover{filter:brightness(.97);}
.nav-notif-item.resolved{background:#f0fdf4;border-color:#bbf7d0;}
.nav-notif-item.closed  {background:#fef2f2;border-color:#fecaca;}
.nav-notif-item.review  {background:#eff6ff;border-color:#bfdbfe;}
.nav-notif-ticket{font-size:11px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.05em;}
.nav-notif-title{font-size:13px;font-weight:700;margin:3px 0;}
.nav-notif-body{font-size:12px;line-height:1.6;color:var(--muted);}
.nav-notif-time{font-size:11px;color:var(--muted);margin-top:5px;}
.nav-notif-footer{padding:12px 18px;border-top:1px solid var(--border);}
.nav-notif-footer a{display:block;text-align:center;font-size:13px;font-weight:600;color:var(--primary);text-decoration:none;padding:9px;border-radius:8px;border:1px solid var(--border);}
.nav-notif-footer a:hover{background:var(--bg);}
.logo{font-weight:700;font-size:20px;color:var(--primary);white-space:nowrap;text-decoration:none;}
.topbar-actions{display:flex;align-items:center;gap:10px;margin-left:auto;}
.cart-btn{display:flex;align-items:center;gap:6px;background:var(--primary);color:#fff;padding:8px 14px;border-radius:8px;border:none;cursor:pointer;font-size:13px;font-weight:500;text-decoration:none;}
.cart-badge{background:#ef4444;color:#fff;border-radius:999px;padding:1px 7px;font-size:11px;font-weight:700;}
.user-btn{display:flex;align-items:center;gap:6px;cursor:pointer;padding:6px 10px;border-radius:8px;border:1px solid var(--border);font-size:13px;transition:.15s;}
.user-btn:hover{background:var(--bg);}
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
</style>

<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">

<div class="slide-overlay" id="overlay" onclick="closeMenu()"></div>
<div class="slide-menu" id="menu">
  <div class="slide-header">
    <p>👋 <%=navUser.getUsername()%></p>
    <span><%=navUser.getEmail()%></span>
  </div>
  <a class="slide-link" href="<%=request.getContextPath()%>/customer-dashboard.jsp"><i class="fa fa-home"></i> Shop</a>
  <a class="slide-link" href="<%=request.getContextPath()%>/cart.jsp"><i class="fa fa-cart-shopping"></i> My Cart</a>
  <a class="slide-link" href="<%=request.getContextPath()%>/my-orders.jsp"><i class="fa fa-box"></i> My Orders</a>
  <a class="slide-link" href="<%=request.getContextPath()%>/myreturns.jsp"><i class="fa fa-rotate-left"></i> My Returns</a>
  <a class="slide-link" href="<%=request.getContextPath()%>/customer-profile.jsp"><i class="fa fa-user"></i> Profile</a>
  <a class="slide-link" href="<%=request.getContextPath()%>/customer-support.jsp"><i class="fa fa-headset"></i> Help &amp; Support</a>
  <a class="slide-link" href="<%=request.getContextPath()%>/logout" style="color:var(--danger);"><i class="fa fa-sign-out-alt"></i> Logout</a>
</div>

<%-- Notification overlay + drawer --%>
<div class="nav-notif-overlay" id="navNotifOverlay" onclick="closeNavNotif()"></div>
<div class="nav-notif-drawer" id="navNotifDrawer">
  <div class="nav-notif-hdr">
    <h3><i class="fa fa-bell" style="color:var(--primary);"></i> Notifications
      <% if (navUnread > 0) { %><span style="background:#ef4444;color:#fff;border-radius:20px;padding:1px 7px;font-size:10px;"><%=navUnread%></span><% } %>
    </h3>
    <button class="nav-notif-close" onclick="closeNavNotif()"><i class="fa fa-xmark"></i></button>
  </div>
  <div class="nav-notif-list" id="navNotifList">
    <%
      java.text.SimpleDateFormat navDtf = new java.text.SimpleDateFormat("dd MMM, h:mm a");
      if (navNotifications == null || navNotifications.isEmpty()) { %>
      <div style="text-align:center;padding:40px 20px;color:var(--muted);font-size:13px;">
        <i class="fa fa-bell-slash" style="font-size:28px;display:block;margin-bottom:10px;opacity:.4;"></i>
        No notifications yet
      </div>
    <% } else {
        String[] NAV_ICONS = {}; // mapped in JS
        for (Notification noti : navNotifications) {
            String nBg    = noti.isRead() ? "#f8fafc" : "#eff6ff";
            String nBdr   = noti.isRead() ? "#e2e8f0" : "#bfdbfe";
            String iconCls;
            switch (noti.getCategory() != null ? noti.getCategory() : "SYSTEM") {
                case "ORDER":      iconCls = "fa-box";            break;
                case "DELIVERY":   iconCls = "fa-motorcycle";     break;
                case "RETURN":     iconCls = "fa-rotate-left";    break;
                case "COMPLAINT":  iconCls = "fa-headset";        break;
                case "PAYMENT":    iconCls = "fa-credit-card";    break;
                default:           iconCls = "fa-bell";           break;
            }
            String nTime = noti.getCreatedAt() != null ? navDtf.format(noti.getCreatedAt()) : "";
    %>
      <div class="nav-notif-item" style="background:<%=nBg%>;border-color:<%=nBdr%>;"
           onclick="navNotifOpen(<%=noti.getId()%>,'<%=noti.getLinkUrl() != null ? noti.getLinkUrl() : "/my-orders.jsp"%>')">
        <div style="display:flex;align-items:flex-start;gap:10px;">
          <div style="width:32px;height:32px;border-radius:50%;background:#dbeafe;color:#1d4ed8;display:flex;align-items:center;justify-content:center;flex-shrink:0;font-size:13px;">
            <i class="fa <%=iconCls%>"></i>
          </div>
          <div style="flex:1;min-width:0;">
            <div class="nav-notif-title" style="<%=noti.isRead()?"":"font-weight:700;"%>"><%=noti.getTitle()%></div>
            <div class="nav-notif-body"><%=noti.getMessage()%></div>
            <div class="nav-notif-time"><i class="fa fa-clock"></i> <%=nTime%></div>
          </div>
          <% if (!noti.isRead()) { %><div style="width:7px;height:7px;border-radius:50%;background:#2563eb;flex-shrink:0;margin-top:5px;"></div><% } %>
        </div>
      </div>
    <% } } %>
  </div>
  <div class="nav-notif-footer">
    <a href="<%=request.getContextPath()%>/my-orders.jsp"><i class="fa fa-box"></i> Go to My Orders</a>
  </div>
</div>

<div class="topbar">
  <button onclick="openMenu()" style="background:none;border:none;cursor:pointer;color:var(--muted);font-size:18px;"><i class="fa fa-bars"></i></button>
  <a class="logo" href="<%=request.getContextPath()%>/customer-dashboard.jsp">SIBS</a>
  <div class="topbar-actions">
    <div class="notif-bell" onclick="openNavNotif()" title="Notifications">
      <i class="fa fa-bell"></i>
      <% if (navUnread > 0) { %><span class="dot"><%=navUnread%></span><% } %>
    </div>
    <a class="cart-btn" href="<%=request.getContextPath()%>/cart.jsp">
      <i class="fa fa-cart-shopping"></i>
      <span>Cart</span>
    </a>
    <div class="user-btn" onclick="openMenu()">
      <i class="fa fa-user"></i>
      <span><%=navUser.getUsername()%></span>
    </div>
  </div>
</div>

<script>
function openMenu()  { document.getElementById('menu').classList.add('open'); document.getElementById('overlay').classList.add('open'); }
function closeMenu() { document.getElementById('menu').classList.remove('open'); document.getElementById('overlay').classList.remove('open'); }
function openNavNotif()  { document.getElementById('navNotifDrawer').classList.add('open'); document.getElementById('navNotifOverlay').classList.add('open'); }
function closeNavNotif() { document.getElementById('navNotifDrawer').classList.remove('open'); document.getElementById('navNotifOverlay').classList.remove('open'); }
function navNotifOpen(id, url) {
  fetch('<%=request.getContextPath()%>/getNotifications?action=markRead&id=' + id, {method:'POST'});
  if (url) window.location.href = '<%=request.getContextPath()%>' + url;
}
</script>
