

<%@ page import="com.sibs.model.User,com.sibs.model.DeliveryBoy,com.sibs.dao.DashboardDAO,com.sibs.dao.OrderDAO,com.sibs.dao.DeliveryBoyDAO,com.sibs.dao.StaffLeaveDAO,com.sibs.dao.SupportComplaintDAO,java.util.List" %>
<%
User user = (User)session.getAttribute("user");
if(user == null || !"STAFF".equals(user.getRole())){
    response.sendRedirect("login.jsp");
    return;
}
DashboardDAO dao            = new DashboardDAO();
StaffLeaveDAO leaveDao      = new StaffLeaveDAO();
SupportComplaintDAO suppDao = new SupportComplaintDAO();
int myPendingLeaves         = leaveDao.countPending(user.getId());
int totalProducts           = dao.getTotalProducts();
int lowStock                = dao.getLowStockCount();
OrderDAO orderDao           = new OrderDAO();
int totalCancelled          = orderDao.getCancelledOrders().size();
int openComplaints          = 0;
try { openComplaints = suppDao.countOpen(); } catch(Exception ignored){}
int pendingPickups          = 0;
try {
    java.sql.Connection _pc = com.sibs.util.DBConnection.getConnection();
    java.sql.PreparedStatement _ps = _pc.prepareStatement(
        "SELECT COUNT(*) FROM return_requests WHERE reason='WRONG_ITEM' AND status='PICKUP_SCHEDULED'");
    java.sql.ResultSet _rs = _ps.executeQuery();
    if(_rs.next()) pendingPickups = _rs.getInt(1);
    _rs.close(); _ps.close(); _pc.close();
} catch(Exception ignored){}
DeliveryBoyDAO dbDao        = new DeliveryBoyDAO();
List<DeliveryBoy> allBoys   = dbDao.getAllWithStats();
int onlineCount = 0, workingCount = 0, offlineCount = 0;
for(DeliveryBoy b : allBoys){
    if(!b.isOnline())              offlineCount++;
    else if(b.getActiveOrders()>0) workingCount++;
    else                           onlineCount++;
}
String username = user.getUsername();
String initials = username.length() >= 2
    ? username.substring(0,1).toUpperCase() + username.substring(1,2).toLowerCase()
    : username.substring(0,1).toUpperCase();
java.util.Calendar cal = java.util.Calendar.getInstance();
int hour = cal.get(java.util.Calendar.HOUR_OF_DAY);
String greeting = hour < 12 ? "Good morning" : hour < 17 ? "Good afternoon" : "Good evening";
String greetEmoji = hour < 12 ? "☀️" : hour < 17 ? "👋" : "🌙";
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Staff Dashboard — SIBS</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<style>
*{margin:0;padding:0;box-sizing:border-box;font-family:'Inter',sans-serif;}
:root{
  --bg:#f1f0ea;--surface:#fff;--border:#e5e4dc;
  --text:#1a1a1a;--muted:#6b7280;--muted2:#9ca3af;
  --sidebar-bg:#fff;--sidebar-border:#e5e4dc;
  --active-bg:#ede9fe;--active-text:#4f46e5;
  --accent:#6366f1;--accent2:#4f46e5;
  --section-label:#9ca3af;
  --badge-bg:#e0e7ff;--badge-text:#3730a3;
  --hover-bg:#f3f4f6;
  --card-shadow:0 1px 4px rgba(0,0,0,.06);
  --card-shadow-hover:0 6px 20px rgba(0,0,0,.1);
}
[data-theme="dark"]{
  --bg:#0f172a;--surface:#1e293b;--border:#334155;
  --text:#f1f5f9;--muted:#94a3b8;--muted2:#64748b;
  --sidebar-bg:#1e293b;--sidebar-border:#334155;
  --active-bg:#312e81;--active-text:#a5b4fc;
  --accent:#818cf8;--accent2:#6366f1;
  --section-label:#475569;
  --badge-bg:#1e1b4b;--badge-text:#a5b4fc;
  --hover-bg:#293548;
  --card-shadow:0 1px 6px rgba(0,0,0,.3);
  --card-shadow-hover:0 6px 24px rgba(0,0,0,.4);
}
html,body{height:100%;overflow:hidden;}
body{background:var(--bg);color:var(--text);display:flex;transition:background .25s,color .25s;}

/* ══ SCROLLBAR ══ */
::-webkit-scrollbar{width:4px;height:4px;}
::-webkit-scrollbar-track{background:transparent;}
::-webkit-scrollbar-thumb{background:var(--border);border-radius:4px;}

/* ══ SIDEBAR ══ */
.sidebar{
  width:252px;height:100vh;background:var(--sidebar-bg);
  border-right:1px solid var(--sidebar-border);
  display:flex;flex-direction:column;flex-shrink:0;
  position:relative;z-index:100;
  transition:width .28s cubic-bezier(.4,0,.2,1);
  overflow:hidden;
}
body.sc .sidebar{width:58px;}
.sidebar::after{
  content:'';position:absolute;right:0;top:50%;transform:translateY(-50%);
  width:3px;height:48px;border-radius:3px 0 0 3px;
  background:linear-gradient(180deg,var(--accent),#818cf8);
  opacity:0;transition:opacity .2s;pointer-events:none;
}
.sidebar:hover::after{opacity:1;}
.sidebar-logo{
  height:58px;padding:0 14px;border-bottom:1px solid var(--sidebar-border);
  display:flex;align-items:center;gap:10px;flex-shrink:0;white-space:nowrap;
}
.logo-icon{
  width:32px;height:32px;background:linear-gradient(135deg,var(--accent),#818cf8);
  border-radius:9px;display:flex;align-items:center;justify-content:center;
  flex-shrink:0;box-shadow:0 2px 8px rgba(99,102,241,.35);
}
.logo-icon i{font-size:15px;color:#fff;}
.logo-text{font-size:15px;font-weight:700;color:var(--text);
  transition:opacity .2s,max-width .28s;max-width:160px;overflow:hidden;}
body.sc .logo-text{opacity:0;max-width:0;}
.sidebar-toggle{
  margin-left:auto;width:26px;height:26px;border-radius:7px;
  border:1px solid var(--border);background:var(--surface);
  display:flex;align-items:center;justify-content:center;
  cursor:pointer;color:var(--muted);font-size:11px;flex-shrink:0;
  transition:background .15s,color .15s,transform .28s;
}
.sidebar-toggle:hover{background:var(--active-bg);color:var(--active-text);}
body.sc .sidebar-toggle{transform:rotate(180deg);}

.sidebar-nav{flex:1;padding:10px 6px;overflow-y:auto;overflow-x:hidden;}
.nav-section{
  font-size:10px;font-weight:600;color:var(--section-label);
  letter-spacing:.7px;text-transform:uppercase;
  padding:14px 8px 4px;white-space:nowrap;
  transition:opacity .2s,max-height .28s,padding .28s;
  max-height:30px;overflow:hidden;
}
.nav-section:first-child{padding-top:2px;}
body.sc .nav-section{opacity:0;max-height:0;padding:0;}

.nav-item{
  display:flex;align-items:center;gap:10px;padding:8px 10px;
  border-radius:9px;font-size:13px;color:var(--muted);
  cursor:pointer;margin-bottom:2px;
  text-decoration:none;border:none;background:none;width:100%;text-align:left;
  white-space:nowrap;overflow:hidden;position:relative;
  transition:background .12s,color .12s,padding .28s;
}
.nav-item:hover{background:var(--hover-bg);color:var(--text);}
.nav-item.active{background:var(--active-bg);color:var(--active-text);font-weight:600;}
.nav-item.active .nav-icon{color:var(--active-text);}
.nav-icon{width:17px;text-align:center;font-size:13px;flex-shrink:0;transition:transform .28s;}
body.sc .nav-item{padding:8px 20px;}
body.sc .nav-item .nav-icon{transform:scale(1.12);}
.nav-text{transition:opacity .18s,max-width .28s;max-width:160px;overflow:hidden;}
body.sc .nav-text{opacity:0;max-width:0;}

/* Sidebar live badge */
.nbadge{
  margin-left:auto;min-width:20px;height:18px;padding:0 6px;
  border-radius:99px;font-size:10px;font-weight:700;
  display:none;align-items:center;justify-content:center;
  flex-shrink:0;line-height:1;
  transition:opacity .15s,transform .2s,max-width .28s;
  background:var(--badge-bg);color:var(--badge-text);
}
.nbadge.show{display:inline-flex;}
.nbadge.red{background:#fee2e2;color:#dc2626;}
body.sc .nbadge{opacity:0;max-width:0;padding:0;overflow:hidden;}
@keyframes badge-bump{0%,100%{transform:scale(1);}40%{transform:scale(1.3);}70%{transform:scale(.95);}}
.nbadge.bump{animation:badge-bump .35s ease;}

/* Tooltip when collapsed */
body.sc .nav-item::before{
  content:attr(data-tip);
  position:absolute;left:62px;top:50%;
  transform:translateY(-50%) translateX(-8px);
  background:#18181b;color:#fff;font-size:12px;font-weight:500;
  padding:6px 12px;border-radius:8px;white-space:nowrap;
  pointer-events:none;z-index:9999;
  box-shadow:0 4px 16px rgba(0,0,0,.25);
  opacity:0;transition:opacity .15s,transform .15s;
}
body.sc .nav-item:hover::before{opacity:1;transform:translateY(-50%) translateX(0);}

.sidebar-footer{padding:8px 6px;border-top:1px solid var(--sidebar-border);flex-shrink:0;}

/* Mobile overlay */
.mob-overlay{
  display:none;position:fixed;inset:0;background:rgba(0,0,0,.4);
  z-index:99;opacity:0;transition:opacity .25s;pointer-events:none;
  backdrop-filter:blur(3px);
}
@media(max-width:820px){
  .sidebar{position:fixed;left:0;top:0;z-index:200;width:252px !important;
    transform:translateX(0);transition:transform .28s cubic-bezier(.4,0,.2,1);}
  body.sc .sidebar{transform:translateX(-100%);}
  .mob-overlay{display:block;}
  body:not(.sc) .mob-overlay{opacity:1;pointer-events:all;}
  .right-panel{margin-left:0 !important;}
}

/* ══ RIGHT PANEL ══ */
.right-panel{flex:1;display:flex;flex-direction:column;height:100vh;overflow:hidden;min-width:0;}

/* ══ TOPBAR ══ */
.topbar{
  background:var(--surface);border-bottom:1px solid var(--border);
  height:58px;padding:0 20px;display:flex;align-items:center;
  justify-content:space-between;flex-shrink:0;gap:12px;
}
.topbar-left{display:flex;align-items:center;gap:8px;min-width:0;}
.breadcrumb{font-size:13px;color:var(--muted);display:flex;align-items:center;gap:5px;white-space:nowrap;}
.breadcrumb .sep{font-size:10px;color:var(--muted2);}
.breadcrumb .cur{color:var(--text);font-weight:600;}
.search-box{
  display:flex;align-items:center;gap:8px;
  background:var(--bg);border:1px solid var(--border);border-radius:10px;
  padding:7px 13px;width:280px;transition:border-color .15s,box-shadow .15s;
}
.search-box:focus-within{border-color:var(--accent);box-shadow:0 0 0 3px rgba(99,102,241,.12);}
.search-box i{color:var(--muted2);font-size:12px;flex-shrink:0;}
.search-box input{border:none;background:transparent;font-size:13px;
  color:var(--text);outline:none;flex:1;min-width:0;}
.search-box input::placeholder{color:var(--muted2);}
.kbd{
  font-size:10px;color:var(--muted2);background:var(--bg);
  border:1px solid var(--border);border-radius:4px;padding:1px 5px;
  white-space:nowrap;display:none;
}
@media(min-width:900px){.kbd{display:inline;}}
.topbar-right{display:flex;align-items:center;gap:8px;flex-shrink:0;}
.icon-btn{
  width:34px;height:34px;border-radius:9px;border:1px solid var(--border);
  background:var(--surface);display:flex;align-items:center;justify-content:center;
  cursor:pointer;color:var(--muted);font-size:14px;transition:background .12s,color .12s;
  flex-shrink:0;
}
.icon-btn:hover{background:var(--hover-bg);color:var(--text);}



/* ── Avatar + profile dropdown ── */
.av-wrap{position:relative;}
.av{
  width:34px;height:34px;border-radius:50%;
  background:linear-gradient(135deg,var(--accent),#818cf8);
  color:#fff;font-size:12px;font-weight:700;
  display:flex;align-items:center;justify-content:center;cursor:pointer;
  border:2px solid transparent;transition:border-color .15s,box-shadow .15s;
}
.av:hover{border-color:var(--accent);box-shadow:0 0 0 3px rgba(99,102,241,.2);}
.av-dd{
  position:absolute;top:calc(100% + 10px);right:0;
  width:210px;background:var(--surface);border:1px solid var(--border);
  border-radius:14px;box-shadow:0 8px 30px rgba(0,0,0,.15);
  z-index:9999;overflow:hidden;
  opacity:0;pointer-events:none;transform:translateY(-6px);
  transition:opacity .18s,transform .18s;
}
.av-dd.open{opacity:1;pointer-events:all;transform:translateY(0);}
.av-dd-head{padding:14px 16px 10px;border-bottom:1px solid var(--border);}
.av-dd-name{font-size:13px;font-weight:700;color:var(--text);}
.av-dd-role{font-size:11px;color:var(--muted);margin-top:1px;}
.av-dd-item{
  display:flex;align-items:center;gap:10px;padding:9px 14px;
  font-size:13px;color:var(--muted);cursor:pointer;
  transition:background .12s,color .12s;text-decoration:none;
}
.av-dd-item:hover{background:var(--hover-bg);color:var(--text);}
.av-dd-item i{width:15px;text-align:center;font-size:13px;}
.av-dd-sep{height:1px;background:var(--border);margin:4px 0;}
.av-dd-item.danger{color:#dc2626;}
.av-dd-item.danger:hover{background:#fee2e2;}

/* ══ CONTENT ══ */
.content-wrap{flex:1;overflow:hidden;position:relative;display:flex;flex-direction:column;min-height:0;}
.load-overlay{
  position:absolute;inset:0;background:var(--bg);
  display:flex;flex-direction:column;align-items:center;justify-content:center;
  z-index:10;opacity:0;pointer-events:none;transition:opacity .15s;
}
.load-overlay.on{opacity:1;pointer-events:all;}
.spin{width:34px;height:34px;border:3px solid var(--border);border-top-color:var(--accent);
  border-radius:50%;animation:spin .7s linear infinite;}
@keyframes spin{to{transform:rotate(360deg);}}
.load-lbl{font-size:13px;color:var(--muted);margin-top:12px;}
#cf{width:100%;height:100%;border:none;background:var(--bg);flex:1;display:block;}

/* ══ DASH HOME ══ */
.dash-home{width:100%;height:100%;overflow-y:auto;padding:24px;background:var(--bg);}
.dash-greeting-row{display:flex;align-items:flex-start;justify-content:space-between;margin-bottom:20px;flex-wrap:wrap;gap:12px;}
.dash-greeting{font-size:22px;font-weight:700;color:var(--text);line-height:1.2;}
.dash-greeting small{display:block;font-size:13px;font-weight:400;color:var(--muted);margin-top:3px;}
.live-clock{font-size:28px;font-weight:700;color:var(--accent);letter-spacing:.5px;line-height:1;}
.live-clock small{display:block;font-size:11px;font-weight:400;color:var(--muted);text-align:right;margin-top:2px;}

/* Alert */
.alert-strip{
  display:flex;align-items:center;gap:10px;padding:10px 14px;
  border-radius:11px;font-size:13px;margin-bottom:12px;
  border-left:4px solid;
}
.alert-strip.yellow{background:#fefce8;border-color:#fbbf24;color:#92400e;}
.alert-strip.blue{background:#eff6ff;border-color:#60a5fa;color:#1d4ed8;}
[data-theme="dark"] .alert-strip.yellow{background:#291e00;color:#fcd34d;}
[data-theme="dark"] .alert-strip.blue{background:#001a3a;color:#93c5fd;}
.alert-strip .al-icon{font-size:15px;flex-shrink:0;}
.alert-strip .al-body{flex:1;}
.alert-strip .al-link{font-weight:600;cursor:pointer;margin-left:6px;text-decoration:underline;text-underline-offset:2px;}
.alert-strip .al-close{margin-left:auto;cursor:pointer;opacity:.5;font-size:13px;padding:2px 4px;}
.alert-strip .al-close:hover{opacity:1;}

/* KPI */
.kpi-grid{display:grid;grid-template-columns:repeat(4,1fr);gap:12px;margin-bottom:16px;}
@media(max-width:1100px){.kpi-grid{grid-template-columns:repeat(2,1fr);}}
@media(max-width:600px){.kpi-grid{grid-template-columns:1fr;}}
.kpi{
  background:var(--surface);border:1px solid var(--border);border-radius:14px;
  padding:18px;cursor:pointer;transition:transform .15s,box-shadow .15s;
  box-shadow:var(--card-shadow);position:relative;overflow:hidden;
}
.kpi:hover{transform:translateY(-3px);box-shadow:var(--card-shadow-hover);}
.kpi::before{
  content:'';position:absolute;top:-18px;right:-18px;
  width:72px;height:72px;border-radius:50%;opacity:.07;
  background:var(--kpi-color,#6366f1);
}
.kpi-top{display:flex;align-items:flex-start;justify-content:space-between;margin-bottom:12px;}
.kpi-ico{
  width:38px;height:38px;border-radius:11px;
  display:flex;align-items:center;justify-content:center;font-size:16px;
  background:var(--kpi-bg,#ede9fe);color:var(--kpi-color,#6366f1);
}
.kpi-trend{
  display:flex;align-items:center;gap:3px;font-size:11px;font-weight:600;
  padding:3px 8px;border-radius:99px;
}
.kpi-trend.up{background:#dcfce7;color:#15803d;}
.kpi-trend.down{background:#fee2e2;color:#dc2626;}
.kpi-trend.neutral{background:var(--hover-bg);color:var(--muted);}
.kpi-num{font-size:28px;font-weight:700;line-height:1;margin-bottom:4px;color:var(--kpi-color,#6366f1);}
.kpi-lbl{font-size:12px;color:var(--muted);margin-bottom:2px;}
.kpi-sub{font-size:11.5px;font-weight:500;color:var(--muted);}

/* Bottom grid */
.bottom-grid{display:grid;grid-template-columns:1.3fr 1fr;gap:12px;}
@media(max-width:900px){.bottom-grid{grid-template-columns:1fr;}}
.card{background:var(--surface);border:1px solid var(--border);border-radius:14px;padding:18px;box-shadow:var(--card-shadow);}
.card-head{display:flex;align-items:center;justify-content:space-between;margin-bottom:14px;}
.card-title{font-size:14px;font-weight:700;color:var(--text);}
.card-link{font-size:12px;color:var(--accent);font-weight:600;cursor:pointer;}

/* Delivery boy list */
.db-pills{display:flex;gap:8px;margin-bottom:14px;flex-wrap:wrap;}
.db-pill{
  display:flex;align-items:center;gap:6px;padding:5px 12px;
  border-radius:99px;font-size:12px;font-weight:500;
  border:1px solid var(--border);background:var(--surface);color:var(--text);
}
.dp{width:7px;height:7px;border-radius:50%;}
.db-row{display:flex;align-items:center;gap:10px;padding:9px 0;border-bottom:1px solid var(--border);}
.db-row:last-child{border-bottom:none;}
.db-av{
  width:36px;height:36px;border-radius:50%;flex-shrink:0;
  display:flex;align-items:center;justify-content:center;
  font-size:13px;font-weight:700;color:#fff;
}
.db-info{flex:1;}
.db-name{font-size:13px;font-weight:600;color:var(--text);}
.db-sub{font-size:11.5px;color:var(--muted);margin-top:1px;}
.db-orders{text-align:right;margin-right:8px;}
.db-orders strong{font-size:13px;font-weight:700;}
.db-orders small{font-size:10px;color:var(--muted);display:block;}
.sp{font-size:11px;font-weight:600;padding:3px 10px;border-radius:99px;}
.sp.working{background:#ffedd5;color:#c2410c;}
.sp.online{background:#dcfce7;color:#15803d;}
.sp.offline{background:var(--hover-bg);color:var(--muted);}

/* Quick actions */
.qa-grid{display:grid;grid-template-columns:1fr 1fr;gap:8px;}
.qa{
  background:var(--bg);border:1px solid var(--border);border-radius:11px;
  padding:14px 10px;text-align:center;cursor:pointer;
  transition:transform .12s,box-shadow .12s,background .12s;
}
.qa:hover{background:var(--hover-bg);transform:translateY(-2px);box-shadow:var(--card-shadow);}
.qa i{font-size:20px;display:block;margin-bottom:7px;}
.qa span{font-size:12px;color:var(--muted);font-weight:500;}

/* ══ TOAST ══ */
#toast-rack{
  position:fixed;bottom:24px;right:24px;z-index:99999;
  display:flex;flex-direction:column;gap:10px;align-items:flex-end;
}
.toast{
  background:var(--surface);border:1px solid var(--border);border-radius:14px;
  padding:13px 16px;box-shadow:0 8px 28px rgba(0,0,0,.18);
  display:flex;align-items:flex-start;gap:12px;
  max-width:320px;min-width:260px;
  transform:translateX(115%);opacity:0;
  transition:transform .35s cubic-bezier(.34,1.56,.64,1),opacity .3s;
  position:relative;overflow:hidden;
}
.toast.show{transform:translateX(0);opacity:1;}
.toast::after{
  content:'';position:absolute;bottom:0;left:0;height:3px;
  background:var(--toast-color,var(--accent));
  animation:toast-progress 5s linear forwards;
}
@keyframes toast-progress{from{width:100%;}to{width:0%;}}
.toast-ico{
  width:38px;height:38px;border-radius:11px;flex-shrink:0;
  display:flex;align-items:center;justify-content:center;font-size:15px;
}
.toast-body{flex:1;}
.toast-title{font-size:13px;font-weight:700;color:var(--text);margin-bottom:2px;}
.toast-msg{font-size:12px;color:var(--muted);line-height:1.4;}
.toast-close{
  font-size:12px;color:var(--muted);cursor:pointer;
  padding:2px 4px;flex-shrink:0;
  transition:color .12s;
}
.toast-close:hover{color:var(--text);}

@keyframes pulse{0%,100%{opacity:1;}50%{opacity:.3;}}
@keyframes fadeIn{from{opacity:0;transform:translateY(8px);}to{opacity:1;transform:translateY(0);}}
.dash-home > *{animation:fadeIn .3s ease both;}
</style>
</head>
<body>

<div class="mob-overlay" id="mobOverlay" onclick="toggleSidebar()"></div>

<!-- ══ SIDEBAR ══ -->
<div class="sidebar">
  <div class="sidebar-logo">
    <div class="logo-icon"><i class="fa fa-cubes"></i></div>
    <span class="logo-text">SIBS Staff</span>
    <div class="sidebar-toggle" onclick="toggleSidebar()" title="Toggle sidebar">
      <i class="fa fa-chevron-left"></i>
    </div>
  </div>

  <div class="sidebar-nav">

    <div class="nav-section">Main</div>
    <div class="nav-item active" onclick="nav('home','Dashboard')" data-page="home" data-tip="Dashboard">
      <i class="nav-icon fa fa-gauge-high"></i><span class="nav-text">Dashboard</span>
    </div>
    <div class="nav-item" onclick="nav('staff-orders.jsp','Orders')" data-page="staff-orders.jsp" data-tip="Orders">
      <i class="nav-icon fa fa-shopping-bag"></i><span class="nav-text">Orders</span>
      <span class="nbadge" id="nb-orders"></span>
    </div>
    <div class="nav-item" onclick="nav('products.jsp','Products')" data-page="products.jsp" data-tip="Products">
      <i class="nav-icon fa fa-box"></i><span class="nav-text">Products</span>
      <span class="nbadge red" id="nb-stock"></span>
    </div>

    <div class="nav-section">Delivery</div>
    <div class="nav-item" onclick="nav('manage-delivery-boys.jsp','Delivery Boys')" data-page="manage-delivery-boys.jsp" data-tip="Delivery boys">
      <i class="nav-icon fa fa-motorcycle"></i><span class="nav-text">Delivery boys</span>
      <span class="nbadge red" id="nb-approvals"></span>
    </div>
    <div class="nav-item" onclick="nav('delivery-monitor.jsp','Monitor')" data-page="delivery-monitor.jsp" data-tip="Live monitor">
      <i class="nav-icon fa fa-satellite-dish"></i><span class="nav-text">Live monitor</span>
      <span class="nbadge" id="nb-active"></span>
    </div>
    <div class="nav-item" onclick="nav('AdminReturnServlet?action=list','Returns')" data-page="AdminReturnServlet" data-tip="Returns">
      <i class="nav-icon fa fa-rotate-left"></i><span class="nav-text">Returns</span>
      <span class="nbadge red" id="nb-returns"></span>
    </div>
    <div class="nav-item" onclick="nav('staff-orders.jsp?tab=pickups','Wrong Item Pickups')" data-page="staff-orders.jsp" data-tip="Pickups">
      <i class="nav-icon fa fa-box-open"></i><span class="nav-text">Wrong item pickups</span>
      <span class="nbadge red" id="nb-pickups"></span>
    </div>
    <div class="nav-item" onclick="nav('admin-delivery-slots.jsp','Delivery Slots')" data-page="admin-delivery-slots.jsp" data-tip="Slots">
      <i class="nav-icon fa fa-calendar-check"></i><span class="nav-text">Slots</span>
    </div>
    <div class="nav-item" onclick="nav('staff-cancelled-orders.jsp','Cancelled')" data-page="staff-cancelled-orders.jsp" data-tip="Cancelled">
      <i class="nav-icon fa fa-ban"></i><span class="nav-text">Cancelled</span>
      <span class="nbadge red" id="nb-cancelled"></span>
    </div>

    <div class="nav-section">Finance</div>
    <div class="nav-item" onclick="nav('admin-cod-ledger.jsp','COD Remittance')" data-page="admin-cod-ledger.jsp" data-tip="COD remittance">
      <i class="nav-icon fa fa-money-bill-wave"></i><span class="nav-text">COD remittance</span>
    </div>
    <div class="nav-item" onclick="nav('staff-withdrawals.jsp','Wallet Withdrawals')" data-page="staff-withdrawals.jsp" data-tip="Wallet withdrawals">
      <i class="nav-icon fa fa-wallet"></i><span class="nav-text">Withdrawals</span>
      <span class="nbadge warn" id="nb-withdrawals"></span>
    </div>
    <div class="nav-item" onclick="nav('billing.jsp','Billing')" data-page="billing.jsp" data-tip="Billing">
      <i class="nav-icon fa fa-file-invoice"></i><span class="nav-text">Billing</span>
    </div>
    <div class="nav-item" onclick="nav('sales.jsp','Sales')" data-page="sales.jsp" data-tip="Sales">
      <i class="nav-icon fa fa-chart-line"></i><span class="nav-text">Sales</span>
    </div>

    <div class="nav-section">Staff</div>
    <div class="nav-item" onclick="nav('staff-attendance.jsp','Attendance')" data-page="staff-attendance.jsp" data-tip="Attendance">
      <i class="nav-icon fa fa-user-clock"></i><span class="nav-text">Attendance</span>
    </div>
    <div class="nav-item" onclick="nav('staff-leave.jsp','My Leaves')" data-page="staff-leave.jsp" data-tip="My leaves">
      <i class="nav-icon fa fa-calendar-xmark"></i><span class="nav-text">My leaves</span>
      <span class="nbadge" id="nb-leaves"></span>
    </div>
    <div class="nav-item" onclick="nav('staff-support.jsp','Support')" data-page="staff-support.jsp" data-tip="Support">
      <i class="nav-icon fa fa-headset"></i><span class="nav-text">Support</span>
      <span class="nbadge red" id="nb-support"></span>
    </div>
    <div class="nav-item" onclick="nav('staff-reviews.jsp','Reviews')" data-page="staff-reviews.jsp" data-tip="Reviews">
      <i class="nav-icon fa fa-star"></i><span class="nav-text">Reviews</span>
    </div>
        <div class="nav-item" onclick="nav('staff-coupons.jsp','Coupons')" data-page="staff-coupons.jsp" data-tip="Coupons">
      <i class="nav-icon fa fa-ticket"></i><span class="nav-text">Coupons</span>
    </div>
    <div class="nav-item" onclick="nav('staff-notifications.jsp','Notifications')" data-page="staff-notifications.jsp" data-tip="Notifications">
      <i class="nav-icon fa fa-bell"></i><span class="nav-text">Notifications</span>
      <span class="nbadge red" id="nb-notifs"></span>
    </div>

  </div>

  <div class="sidebar-footer">
    <a class="nav-item" href="logout" style="text-decoration:none;" data-tip="Logout">
      <i class="nav-icon fa fa-sign-out-alt"></i><span class="nav-text">Logout</span>
    </a>
  </div>
</div>

<!-- ══ RIGHT PANEL ══ -->
<div class="right-panel">

  <!-- TOPBAR -->
  <div class="topbar">
    <div class="topbar-left">
      <div class="icon-btn" onclick="toggleSidebar()"><i class="fa fa-bars"></i></div>
      <div class="breadcrumb">
        <span>SIBS</span>
        <span class="sep"><i class="fa fa-chevron-right"></i></span>
        <span class="cur" id="pg-label">Dashboard</span>
      </div>
    </div>

    <div class="search-box">
      <i class="fa fa-magnifying-glass"></i>
      <input type="text" id="gsearch" placeholder="Search...">
      <span class="kbd">Ctrl K</span>
    </div>

    <div class="topbar-right">
      <!-- Theme toggle -->
      <div class="icon-btn" onclick="toggleTheme()" title="Toggle theme">
        <i class="fa fa-moon" id="themeIco"></i>
      </div>

      <!-- Notification Bell -->
      <%@ include file="includes/staffNotificationBell.jsp" %>

      <!-- Avatar + Profile dropdown -->
      <div class="av-wrap" id="avWrap">
        <div class="av" onclick="toggleAvDd(event)" title="<%=username%>"><%=initials%></div>
        <div class="av-dd" id="avDd">
          <div class="av-dd-head">
            <div class="av-dd-name"><%=username%></div>
            <div class="av-dd-role">Staff Member</div>
          </div>
          <a class="av-dd-item" href="staff-profile.jsp">
            <i class="fa fa-user-circle"></i> My Profile
          </a>
          <div class="av-dd-item" onclick="nav('staff-attendance.jsp','Attendance');closeAvDd()">
            <i class="fa fa-user-clock"></i> My Attendance
          </div>
          <div class="av-dd-item" onclick="nav('staff-leave.jsp','My Leaves');closeAvDd()">
            <i class="fa fa-calendar-xmark"></i> My Leaves
          </div>
          <div class="av-dd-sep"></div>
          <a class="av-dd-item danger" href="logout">
            <i class="fa fa-sign-out-alt"></i> Logout
          </a>
        </div>
      </div>
    </div>
  </div>

  <!-- CONTENT AREA -->
  <div class="content-wrap">
    <div class="load-overlay" id="loader">
      <div class="spin"></div>
      <div class="load-lbl" id="load-txt">Loading...</div>
    </div>

    <!-- ── DASHBOARD HOME ── -->
    <div class="dash-home" id="dash-home">

      <!-- Greeting row -->
      <div class="dash-greeting-row">
        <div class="dash-greeting">
          <%=greeting%>, <%=username%> <%=greetEmoji%>
          <small id="dash-date">
            <%
              java.text.SimpleDateFormat sdf = new java.text.SimpleDateFormat("EEEE, d MMMM yyyy");
              out.print(sdf.format(new java.util.Date()));
            %>
          </small>
        </div>
        <div class="live-clock">
          <span id="clockTime">--:--</span>
          <small id="clockAmPm">--</small>
        </div>
      </div>

      <!-- Alert banners -->
      <% if(lowStock > 0){ %>
      <div class="alert-strip yellow" id="al-stock">
        <i class="al-icon fa fa-triangle-exclamation"></i>
        <div class="al-body">
          <b>Low stock alert:</b> <%=lowStock%> product(s) need restocking.
          <span class="al-link" onclick="nav('products.jsp','Products')">View products →</span>
        </div>
        <span class="al-close" onclick="this.closest('.alert-strip').remove()">✕</span>
      </div>
      <% } %>
      <% if(myPendingLeaves > 0){ %>
      <div class="alert-strip blue" id="al-leave">
        <i class="al-icon fa fa-clock"></i>
        <div class="al-body">
          You have <b><%=myPendingLeaves%> pending leave request<%=myPendingLeaves>1?"s":""%></b> awaiting approval.
          <span class="al-link" onclick="nav('staff-leave.jsp','My Leaves')">View →</span>
        </div>
        <span class="al-close" onclick="this.closest('.alert-strip').remove()">✕</span>
      </div>
      <% } %>
      <% if(openComplaints > 0){ %>
      <div class="alert-strip yellow" id="al-complaints">
        <i class="al-icon fa fa-headset"></i>
        <div class="al-body">
          <b><%=openComplaints%> open support complaint<%=openComplaints>1?"s":""%></b> need attention.
          <span class="al-link" onclick="nav('staff-support.jsp','Support')">Handle now →</span>
        </div>
        <span class="al-close" onclick="this.closest('.alert-strip').remove()">✕</span>
      </div>
      <% } %>
      <% if(pendingPickups > 0){ %>
      <div class="alert-strip blue" id="al-pickups">
        <i class="al-icon fa fa-box-open"></i>
        <div class="al-body">
          <b><%=pendingPickups%> wrong item pickup<%=pendingPickups>1?"s":""%></b> scheduled — assign delivery boy.
          <span class="al-link" onclick="nav('staff-orders.jsp?tab=pickups','Wrong Item Pickups')">Schedule now →</span>
        </div>
        <span class="al-close" onclick="this.closest('.alert-strip').remove()">✕</span>
      </div>
      <% } %>

      <!-- KPI cards -->
      <div class="kpi-grid">
        <div class="kpi" onclick="nav('staff-orders.jsp','Orders')" style="--kpi-bg:#ede9fe;--kpi-color:#6366f1;">
          <div class="kpi-top">
            <div class="kpi-ico"><i class="fa fa-shopping-bag"></i></div>
            <span class="kpi-trend neutral" id="kpi-trend-orders"><i class="fa fa-minus"></i> —</span>
          </div>
          <div class="kpi-num" id="kpi-orders">—</div>
          <div class="kpi-lbl">Pending orders</div>
          <div class="kpi-sub">Click to manage →</div>
        </div>

        <div class="kpi" onclick="nav('delivery-monitor.jsp','Monitor')" style="--kpi-bg:#dcfce7;--kpi-color:#16a34a;">
          <div class="kpi-top">
            <div class="kpi-ico"><i class="fa fa-truck-fast"></i></div>
            <span class="kpi-trend up"><i class="fa fa-circle-dot"></i> Live</span>
          </div>
          <div class="kpi-num" style="color:#16a34a;"><%=workingCount%></div>
          <div class="kpi-lbl">Active deliveries</div>
          <div class="kpi-sub"><%=onlineCount%> idle &bull; <%=offlineCount%> offline</div>
        </div>

        <div class="kpi" onclick="nav('products.jsp','Products')" style="--kpi-bg:#ffedd5;--kpi-color:#ea580c;">
          <div class="kpi-top">
            <div class="kpi-ico"><i class="fa fa-box"></i></div>
            <% if(lowStock > 0){ %>
              <span class="kpi-trend down"><i class="fa fa-arrow-down"></i> <%=lowStock%> low</span>
            <% } else { %>
              <span class="kpi-trend up"><i class="fa fa-check"></i> OK</span>
            <% } %>
          </div>
          <div class="kpi-num" style="color:#ea580c;"><%=totalProducts%></div>
          <div class="kpi-lbl">Total products</div>
          <div class="kpi-sub" style="color:<%=lowStock>0?"#ef4444":"#16a34a"%>;"><%=lowStock>0?lowStock+" need restocking":"All fully stocked"%></div>
        </div>

        <div class="kpi" onclick="nav('staff-cancelled-orders.jsp','Cancelled')" style="--kpi-bg:#fee2e2;--kpi-color:#dc2626;">
          <div class="kpi-top">
            <div class="kpi-ico"><i class="fa fa-ban"></i></div>
            <% if(totalCancelled > 0){ %>
              <span class="kpi-trend down"><i class="fa fa-arrow-down"></i> Review</span>
            <% } else { %>
              <span class="kpi-trend up"><i class="fa fa-check"></i> Clear</span>
            <% } %>
          </div>
          <div class="kpi-num" style="color:#dc2626;"><%=totalCancelled%></div>
          <div class="kpi-lbl">Cancelled orders</div>
          <div class="kpi-sub"><%=totalCancelled==0?"No cancellations":"Needs review"%></div>
        </div>
      </div>

      <!-- Bottom grid -->
      <div class="bottom-grid">

        <!-- Delivery boys -->
        <div class="card">
          <div class="card-head">
            <span class="card-title">Delivery boy status</span>
            <span class="card-link" onclick="nav('delivery-monitor.jsp','Monitor')">Live map →</span>
          </div>
          <div class="db-pills">
            <div class="db-pill">
              <span class="dp" style="background:#f97316;animation:pulse 1.4s infinite;"></span>
              <%=workingCount%> Working
            </div>
            <div class="db-pill">
              <span class="dp" style="background:#22c55e;animation:pulse 2s infinite;"></span>
              <%=onlineCount%> Online
            </div>
            <div class="db-pill">
              <span class="dp" style="background:#d1d5db;"></span>
              <%=offlineCount%> Offline
            </div>
          </div>

          <% if(allBoys.isEmpty()){ %>
          <div style="padding:24px;text-align:center;color:var(--muted);font-size:13px;">
            <i class="fa fa-motorcycle" style="font-size:22px;display:block;margin-bottom:8px;color:var(--muted2);"></i>
            No delivery boys yet. Delivery boys can self-register.
          </div>
          <% } else {
               int shown = 0;
               for(DeliveryBoy b : allBoys){
                 if(shown++ >= 6) break;
                 String pr = b.getPresenceLabel().toLowerCase();
                 String ini2 = b.getName().length()>=2
                   ? b.getName().substring(0,1).toUpperCase()+b.getName().substring(1,2).toLowerCase()
                   : b.getName().substring(0,1).toUpperCase();
                 String ac = "working".equals(pr)?"#f97316":"online".equals(pr)?"#22c55e":"#94a3b8";
                 String ls = "working".equals(pr)?"On delivery right now"
                           : "online".equals(pr) ?"Online — idle"
                           : "Last seen: "+(b.getLastSeen()!=null?b.getLastSeen():"never");
          %>
          <div class="db-row">
            <div class="db-av" style="background:<%=ac%>;"><%=ini2%></div>
            <div class="db-info">
              <div class="db-name"><%=b.getName()%></div>
              <div class="db-sub"><%=ls%></div>
            </div>
            <div class="db-orders">
              <strong style="color:<%="working".equals(pr)?"#f97316":"var(--muted)"%>;"><%=b.getActiveOrders()%></strong>
              <small>orders</small>
            </div>
            <span class="sp <%=pr%>"><%="working".equals(pr)?"Working":"online".equals(pr)?"Online":"Offline"%></span>
          </div>
          <% }} %>
          <% if(allBoys.size() > 6){ %>
          <div style="padding-top:10px;text-align:center;">
            <span onclick="nav('manage-delivery-boys.jsp','Delivery Boys')" style="font-size:12px;color:var(--accent);cursor:pointer;font-weight:600;">
              View all <%=allBoys.size()%> delivery boys →
            </span>
          </div>
          <% } %>
        </div>

        <!-- Quick actions -->
        <div class="card">
          <div class="card-head">
            <span class="card-title">Quick actions</span>
          </div>
          <div class="qa-grid">
            <div class="qa" onclick="nav('staff-orders.jsp','Orders')">
              <i class="fa fa-shopping-bag" style="color:#6366f1;"></i><span>Orders</span>
            </div>
            <div class="qa" onclick="nav('delivery-monitor.jsp','Monitor')">
              <i class="fa fa-satellite-dish" style="color:#16a34a;"></i><span>Live monitor</span>
            </div>
            <div class="qa" onclick="nav('staff-attendance.jsp','Attendance')">
              <i class="fa fa-user-clock" style="color:#f97316;"></i><span>Attendance</span>
            </div>
            <div class="qa" onclick="nav('staff-leave.jsp','My Leaves')">
              <i class="fa fa-calendar-xmark" style="color:#dc2626;"></i><span>Apply leave</span>
            </div>
            <div class="qa" onclick="nav('products.jsp','Products')">
              <i class="fa fa-box" style="color:#ea580c;"></i><span>Products</span>
            </div>
            <div class="qa" onclick="nav('manage-delivery-boys.jsp','Delivery Boys')">
              <i class="fa fa-motorcycle" style="color:#7c3aed;"></i><span>Delivery boys</span>
            </div>
            <div class="qa" onclick="nav('AdminReturnServlet?action=list','Returns')">
              <i class="fa fa-rotate-left" style="color:#0891b2;"></i><span>Returns</span>
            </div>
            <div class="qa" onclick="nav('staff-orders.jsp?tab=pickups','Wrong Item Pickups')" style="position:relative;">
              <i class="fa fa-box-open" style="color:#dc2626;"></i><span>Wrong item pickups<% if(pendingPickups>0){%> <b style="color:#dc2626;">(<%=pendingPickups%>)</b><%}%></span>
            </div>
            <div class="qa" onclick="nav('staff-support.jsp','Support')">
              <i class="fa fa-headset" style="color:#059669;"></i><span>Support</span>
            </div>
            <div class="qa" onclick="nav('staff-withdrawals.jsp','Withdrawals')">
              <i class="fa fa-money-bill-wave" style="color:#7c3aed;"></i><span>Withdrawals</span>
            </div>
            <div class="qa" onclick="nav('staff-coupons.jsp','Coupons')"><i class="fa fa-ticket" style="color:#0891b2;"></i><span>Coupons</span></div>
            <div class="qa" onclick="nav('staff-notifications.jsp','Notifications')">
              <i class="fa fa-bell" style="color:#e11d48;"></i><span>Notifications</span>
            </div>
          </div>
        </div>

      </div><!-- /bottom-grid -->
    </div><!-- /dash-home -->

    <iframe id="cf" src="about:blank" style="display:none;height:100%;"></iframe>

  </div><!-- /content-wrap -->
</div><!-- /right-panel -->

<div id="toast-rack"></div>

<script>
/* ═══════════════ INIT ═══════════════ */
(function(){
  var t = localStorage.getItem('sibs-theme') || 'light';
  document.documentElement.setAttribute('data-theme', t);
  document.getElementById('themeIco').className = t==='dark' ? 'fa fa-sun' : 'fa fa-moon';
  if(localStorage.getItem('sibs-sb') === 'c') document.body.classList.add('sc');
})();

/* ═══════════════ THEME ═══════════════ */
function toggleTheme(){
  var d = document.documentElement.getAttribute('data-theme') === 'dark';
  var n = d ? 'light' : 'dark';
  document.documentElement.setAttribute('data-theme', n);
  localStorage.setItem('sibs-theme', n);
  document.getElementById('themeIco').className = n==='dark' ? 'fa fa-sun' : 'fa fa-moon';
}

/* ═══════════════ SIDEBAR ═══════════════ */
function toggleSidebar(){
  var c = document.body.classList.toggle('sc');
  localStorage.setItem('sibs-sb', c ? 'c' : 'o');
}

/* ═══════════════ CLOCK ═══════════════ */
function tickClock(){
  var d = new Date();
  var h = d.getHours(), m = d.getMinutes(), s = d.getSeconds();
  var ap = h >= 12 ? 'PM' : 'AM';
  var h12 = h % 12 || 12;
  document.getElementById('clockTime').textContent =
    h12 + ':' + (m<10?'0':'')+m + ':' + (s<10?'0':'')+s;
  document.getElementById('clockAmPm').textContent = ap;
}
tickClock(); setInterval(tickClock, 1000);

/* ═══════════════ SEARCH SHORTCUT ═══════════════ */
document.addEventListener('keydown', function(e){
  if((e.ctrlKey || e.metaKey) && e.key === 'k'){
    e.preventDefault();
    document.getElementById('gsearch').focus();
  }
  if(e.key === 'Escape') document.getElementById('gsearch').blur();
});

/* ═══════════════ SPA NAV ═══════════════ */
var frame   = document.getElementById('cf');
var dHome   = document.getElementById('dash-home');
var loader  = document.getElementById('loader');
var loadTxt = document.getElementById('load-txt');
var pgLabel = document.getElementById('pg-label');
var curPage = 'home';

function setActive(p){
  document.querySelectorAll('.nav-item[data-page]').forEach(function(el){
    el.classList.toggle('active', el.dataset.page===p || el.dataset.page===p.split('?')[0]);
  });
}
function nav(url, label){
  if(curPage === url) return;
  curPage = url; pgLabel.textContent = label; setActive(url);
  if(url === 'home'){
    frame.style.display = 'none'; dHome.style.display = 'block'; return;
  }
  loadTxt.textContent = 'Loading ' + label + '...';
  loader.classList.add('on'); dHome.style.display = 'none'; frame.style.display = 'none';
  frame.src = url;
  frame.onload = function(){
    loader.classList.remove('on');
    // Detect if iframe redirected to login page
    try{
      var iUrl = frame.contentWindow.location.href;
      if(iUrl.indexOf('login.jsp') !== -1 || iUrl.indexOf('login') !== -1){
        window.top.location.href = 'login.jsp';
        return;
      }
    }catch(e){}
    frame.style.display = 'block';
    try{
      var doc = frame.contentDocument || frame.contentWindow.document;
      var old = doc.getElementById('__sibs-e');
      if(old) old.remove();
      var s = doc.createElement('style'); s.id='__sibs-e';
      s.textContent='.sidebar,#sidebar{display:none!important}.topbar{display:none!important}.content-area,.main-content,.content-wrap,body>.content,body>main{margin-left:0!important;padding-left:0!important}html,body{height:auto!important;overflow:auto!important}';
      doc.head.appendChild(s);
    }catch(e){}
  };
  frame.onerror = function(){ loader.classList.remove('on'); frame.style.display='block'; };
}

/* ═══════════════ SIDEBAR BADGES ═══════════════ */
var BADGE_MAP = {
  'nb-orders':      'pendingOrders',
  'nb-stock':       'lowStock',
  'nb-approvals':   'pendingApprovals',
  'nb-active':      'activeDeliveries',
  'nb-returns':     'pendingReturns',
  'nb-cancelled':   'cancelledToday',
  'nb-leaves':      'pendingLeaves',
  'nb-support':     'openComplaints',
  'nb-withdrawals': 'pendingWithdrawals',
  'nb-pickups':     'pendingPickups'
};
function updateBadges(data){
  for(var id in BADGE_MAP){
    var el = document.getElementById(id);
    if(!el) continue;
    var val = data[BADGE_MAP[id]];
    if(val != null && val > 0){
      var prev = parseInt(el.dataset.prev||'0',10);
      el.textContent = val > 99 ? '99+' : val;
      el.classList.add('show');
      if(val > prev && prev > 0){ el.classList.remove('bump'); void el.offsetWidth; el.classList.add('bump'); }
      el.dataset.prev = val;
    } else {
      el.textContent=''; el.classList.remove('show'); el.dataset.prev='0';
    }
  }
  if(data.pendingOrders != null){
    var ko = document.getElementById('kpi-orders');
    if(ko) ko.textContent = data.pendingOrders;
    var tr = document.getElementById('kpi-trend-orders');
    if(tr){
      if(data.pendingOrders > 0){
        tr.className='kpi-trend down'; tr.innerHTML='<i class="fa fa-arrow-up"></i> '+data.pendingOrders;
      } else {
        tr.className='kpi-trend up'; tr.innerHTML='<i class="fa fa-check"></i> Clear';
      }
    }
  }
}
function fetchBadges(){
  fetch('getDashboardStats').then(function(r){ return r.json(); }).then(updateBadges).catch(function(){});
}



function esc(s){ if(!s)return''; return s.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;'); }

document.addEventListener('click', function(e){
  var aw = document.getElementById('avWrap');
  if(aw && !aw.contains(e.target)) closeAvDd();
});

function toggleAvDd(e){ e.stopPropagation(); document.getElementById('avDd').classList.toggle('open'); }
function closeAvDd(){ document.getElementById('avDd').classList.remove('open'); }

/* ═══════════════ POLLING ═══════════════ */
fetchBadges();
setInterval(function(){
  if(!document.hidden){ fetchBadges(); }
}, 30000);


</script>
</body>
</html>
