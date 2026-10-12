<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="com.sibs.model.User, com.sibs.model.DeliverySlot, com.sibs.dao.DeliverySlotDAO, java.util.List, java.util.Calendar" %>
<%
// ── Auth: ADMIN or STAFF only ─────────────────────────────────────────────────
User user = (User) session.getAttribute("user");
if (user == null || (!"ADMIN".equals(user.getRole()) && !"STAFF".equals(user.getRole()))) {
    response.sendRedirect("login.jsp");
    return;
}

boolean isAdmin = "ADMIN".equals(user.getRole());

// ── Month/year filter ─────────────────────────────────────────────────────────
Calendar cal      = Calendar.getInstance();
int curYear       = cal.get(Calendar.YEAR);
int curMonth      = cal.get(Calendar.MONTH) + 1;
int selYear       = curYear;
int selMonth      = curMonth;
try {
    String py = request.getParameter("year"), pm = request.getParameter("month");
    if (py != null && !py.isEmpty()) selYear  = Integer.parseInt(py);
    if (pm != null && !pm.isEmpty()) selMonth = Integer.parseInt(pm);
} catch (NumberFormatException ignored) {}

// ── DAO calls ─────────────────────────────────────────────────────────────────
DeliverySlotDAO dao              = new DeliverySlotDAO();
List<DeliverySlot> utilization   = dao.getSlotUtilizationToday();   // summary cards
List<DeliverySlot> todayBookings = dao.getTodayAllBookings();        // today's table
List<DeliverySlot> monthlyList   = dao.getMonthlyReport(selYear, selMonth); // monthly

// ── Quick totals ──────────────────────────────────────────────────────────────
int totalBooked = 0, totalActive = 0, totalCompleted = 0, totalCancelled = 0;
for (DeliverySlot s : todayBookings) {
    String st = s.getStatus() != null ? s.getStatus() : "";
    if      ("BOOKED".equals(st))    totalBooked++;
    else if ("ACTIVE".equals(st))    totalActive++;
    else if ("COMPLETED".equals(st)) totalCompleted++;
    else if ("CANCELLED".equals(st)) totalCancelled++;
}

String[] MONTHS = {"","January","February","March","April","May","June",
                   "July","August","September","October","November","December"};
%>
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Delivery Slot Monitor — SIBS</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<style>
:root{
  --bg:#f8fafc;--surface:#fff;--border:#e2e8f0;
  --text:#0f172a;--muted:#64748b;--primary:#2563eb;
  --success:#16a34a;--danger:#ef4444;--warn:#f59e0b;--purple:#7c3aed;
  --sidebar:#0f172a;--sidebar-text:#cbd5e1;--sidebar-hover:#1e293b;
}
[data-theme="dark"]{
  --bg:#0f172a;--surface:#1e293b;--border:#334155;
  --text:#f1f5f9;--muted:#94a3b8;--sidebar:#020617;--sidebar-hover:#0f172a;
}
*{margin:0;padding:0;box-sizing:border-box;font-family:'Inter',sans-serif;}
body{background:var(--bg);color:var(--text);}

/* ── SIDEBAR ── */
.sidebar{width:240px;height:100vh;background:var(--sidebar);position:fixed;top:0;left:0;display:flex;flex-direction:column;z-index:200;}
.sidebar-logo{padding:20px 24px;border-bottom:1px solid rgba(255,255,255,.07);display:flex;align-items:center;gap:10px;}
.sidebar-logo span{color:#fff;font-weight:700;font-size:17px;}
.sidebar-logo i{color:#f97316;font-size:19px;}
.sidebar nav{flex:1;padding:12px 0;overflow-y:auto;}
.nav-item{display:flex;align-items:center;gap:10px;padding:11px 20px;color:var(--sidebar-text);text-decoration:none;font-size:14px;transition:.15s;border-left:3px solid transparent;}
.nav-item:hover,.nav-item.active{background:var(--sidebar-hover);color:#fff;border-left-color:#f97316;}
.nav-item i{width:18px;text-align:center;}
.sidebar-footer{padding:16px;border-top:1px solid rgba(255,255,255,.07);}

/* ── TOPBAR ── */
.topbar{margin-left:0;height:62px;background:var(--surface);border-bottom:1px solid var(--border);display:flex;align-items:center;justify-content:space-between;padding:0 24px;position:sticky;top:0;z-index:100;box-shadow:0 1px 3px rgba(0,0,0,.06);}
.topbar-left{font-weight:600;font-size:15px;}
.topbar-right{display:flex;align-items:center;gap:12px;}
.dark-btn{background:none;border:1px solid var(--border);width:34px;height:34px;border-radius:8px;cursor:pointer;color:var(--muted);}
.profile-pill{display:flex;align-items:center;gap:8px;cursor:pointer;padding:6px 10px;border-radius:8px;border:1px solid var(--border);}
.avatar{width:30px;height:30px;border-radius:50%;background:var(--primary);display:flex;align-items:center;justify-content:center;color:#fff;font-weight:700;font-size:12px;}
.profile-name{font-size:13px;font-weight:500;}
.profile-role{font-size:11px;color:var(--muted);}
.dropdown{position:relative;}
.dropdown-menu{position:absolute;top:calc(100% + 8px);right:0;background:var(--surface);border:1px solid var(--border);border-radius:10px;width:200px;box-shadow:0 10px 25px rgba(0,0,0,.15);display:none;z-index:300;overflow:hidden;}
.dropdown-menu.open{display:block;}
.dropdown-header{padding:14px 16px;border-bottom:1px solid var(--border);}
.dropdown-header p{font-size:13px;font-weight:600;}
.dropdown-header span{font-size:11px;color:var(--muted);}
.dropdown-item{display:flex;align-items:center;gap:10px;padding:10px 16px;font-size:13px;color:var(--text);text-decoration:none;}
.dropdown-item:hover{background:var(--bg);}
.dropdown-item.red{color:var(--danger);}

/* ── CONTENT ── */
.content{margin-left:0;padding:28px 24px;}
.page-header{display:flex;align-items:flex-start;justify-content:space-between;flex-wrap:wrap;gap:16px;margin-bottom:24px;}
.page-title{font-size:21px;font-weight:700;}
.page-sub{font-size:13px;color:var(--muted);margin-top:3px;}

/* ── SLOT UTILIZATION CARDS ── */
.slot-util-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(200px,1fr));gap:14px;margin-bottom:28px;}
.slot-util-card{background:var(--surface);border:1px solid var(--border);border-radius:14px;padding:18px 20px;box-shadow:0 1px 3px rgba(0,0,0,.05);}
.slot-util-top{display:flex;align-items:center;justify-content:space-between;margin-bottom:12px;}
.slot-name{font-size:13px;font-weight:700;}
.slot-time-tag{font-size:11px;color:var(--muted);background:var(--bg);padding:3px 8px;border-radius:6px;}
.slot-bar-track{height:7px;background:var(--bg);border-radius:999px;overflow:hidden;margin-bottom:10px;}
.slot-bar-fill{height:100%;border-radius:999px;transition:width .5s;}
.slot-bar-fill.low   {background:linear-gradient(90deg,#16a34a,#4ade80);}
.slot-bar-fill.mid   {background:linear-gradient(90deg,#f59e0b,#fbbf24);}
.slot-bar-fill.high  {background:linear-gradient(90deg,#ef4444,#f87171);}
.slot-util-row{display:flex;justify-content:space-between;font-size:12px;color:var(--muted);}
.slot-util-row span{font-weight:600;color:var(--text);}

/* ── SUMMARY STAT CARDS ── */
.stat-cards{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:14px;margin-bottom:28px;}
.stat-card{background:var(--surface);border:1px solid var(--border);border-radius:14px;padding:18px 20px;box-shadow:0 1px 3px rgba(0,0,0,.05);}
.stat-icon{width:38px;height:38px;border-radius:10px;display:flex;align-items:center;justify-content:center;font-size:16px;margin-bottom:10px;}
.icon-blue  {background:#dbeafe;color:#1d4ed8;}
.icon-green {background:#dcfce7;color:#16a34a;}
.icon-amber {background:#fef9c3;color:#92400e;}
.icon-red   {background:#fee2e2;color:#dc2626;}
.icon-purple{background:#f3e8ff;color:#7c3aed;}
.stat-num{font-size:28px;font-weight:700;line-height:1;}
.stat-label{font-size:12px;color:var(--muted);font-weight:500;margin-top:4px;}

/* ── SECTION HEADER ── */
.section-head{display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:12px;margin-bottom:14px;}
.section-title{font-size:16px;font-weight:700;display:flex;align-items:center;gap:8px;}
.section-title i{color:var(--primary);}

/* ── SEARCH ── */
.search-box{position:relative;display:flex;align-items:center;}
.search-box i{position:absolute;left:10px;color:var(--muted);font-size:13px;}
.search-box input{padding:8px 12px 8px 32px;border:1px solid var(--border);border-radius:8px;font-size:13px;background:var(--surface);color:var(--text);outline:none;width:200px;}
.search-box input:focus{border-color:var(--primary);}

/* ── FILTER FORM ── */
.filter-bar{display:flex;align-items:center;gap:10px;flex-wrap:wrap;}
.filter-bar select,.filter-bar input[type=number]{padding:8px 12px;border:1px solid var(--border);border-radius:8px;font-size:13px;background:var(--surface);color:var(--text);outline:none;}
.btn-primary{padding:8px 18px;background:var(--primary);color:#fff;border:none;border-radius:8px;font-size:13px;font-weight:600;cursor:pointer;display:inline-flex;align-items:center;gap:6px;}
.btn-primary:hover{background:#1d4ed8;}
.btn-outline{padding:8px 14px;background:var(--surface);color:var(--text);border:1px solid var(--border);border-radius:8px;font-size:13px;font-weight:600;cursor:pointer;display:inline-flex;align-items:center;gap:6px;text-decoration:none;}
.btn-outline:hover{background:var(--bg);}

/* ── TABLE ── */
.table-wrap{overflow-x:auto;border-radius:12px;border:1px solid var(--border);background:var(--surface);margin-bottom:32px;}
table{width:100%;border-collapse:collapse;font-size:13px;}
thead tr{background:var(--bg);}
th{padding:12px 14px;text-align:left;font-weight:600;color:var(--muted);font-size:11px;text-transform:uppercase;letter-spacing:.4px;border-bottom:1px solid var(--border);white-space:nowrap;}
td{padding:11px 14px;border-bottom:1px solid var(--border);color:var(--text);}
tr:last-child td{border-bottom:none;}
tr:hover td{background:var(--bg);}
.emp-name-cell{display:flex;align-items:center;gap:8px;}
.emp-avatar{width:28px;height:28px;border-radius:50%;background:var(--primary);display:flex;align-items:center;justify-content:center;color:#fff;font-weight:700;font-size:11px;flex-shrink:0;}

/* ── STATUS BADGES ── */
.badge{padding:3px 11px;border-radius:99px;font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:.3px;white-space:nowrap;}
.badge-booked   {background:#dbeafe;color:#1d4ed8;}
.badge-active   {background:#dcfce7;color:#15803d;}
.badge-completed{background:#e0e7ff;color:#4338ca;}
.badge-cancelled{background:#fee2e2;color:#dc2626;}

/* ── EMPTY STATE ── */
.empty{text-align:center;padding:48px 20px;color:var(--muted);}
.empty i{font-size:36px;margin-bottom:12px;opacity:.3;display:block;}
.empty p{font-size:14px;}

/* ── LIVE DOT ── */
.live-dot{width:8px;height:8px;background:#16a34a;border-radius:50%;display:inline-block;animation:blink 1.4s ease-in-out infinite;margin-right:4px;}
@keyframes blink{0%,100%{opacity:1;}50%{opacity:.3;}}
</style>
</head>
<body>

<!-- ══════════ SIDEBAR ══════════ -->
<div class="sidebar">
  <div class="sidebar-logo">
    <i class="fa fa-cubes"></i>
    <span>SIBS <%=isAdmin ? "Admin" : "Staff"%></span>
  </div>
  <nav>
    <% if (isAdmin) { %>
    <a class="nav-item" href="dashboard.jsp"><i class="fa fa-gauge-high"></i> Dashboard</a>
    <a class="nav-item" href="add-staff.jsp"><i class="fa fa-user-plus"></i> Add Staff</a>
    <a class="nav-item" href="users.jsp"><i class="fa fa-users"></i> Manage Users</a>
    <a class="nav-item" href="products.jsp"><i class="fa fa-box"></i> Products</a>
    <a class="nav-item" href="admin-orders.jsp"><i class="fa fa-shopping-bag"></i> Orders</a>
    <a class="nav-item" href="manage-delivery-boys.jsp"><i class="fa fa-motorcycle"></i> Delivery Boys</a>
    <a class="nav-item" href="admin-delivery-approvals.jsp"><i class="fa fa-user-check"></i> Delivery Approvals</a>
    <a class="nav-item" href="delivery-monitor.jsp"><i class="fa fa-satellite-dish"></i> Delivery Monitor</a>
    <a class="nav-item" href="AdminReturnServlet?action=list"><i class="fa fa-rotate-left"></i> Manage Returns</a>
    <a class="nav-item" href="admin-cod-ledger.jsp"><i class="fa fa-money-bill-wave"></i> COD Remittance</a>
    <a class="nav-item" href="staff-cancelled-orders.jsp"><i class="fa fa-ban"></i> Cancelled Orders</a>
    <a class="nav-item" href="admin-attendance.jsp"><i class="fa fa-clock"></i> Staff Attendance</a>
    <a class="nav-item active" href="admin-delivery-slots.jsp"><i class="fa fa-calendar-check"></i> Delivery Slots</a>
    <a class="nav-item" href="invoice.jsp"><i class="fa fa-file-invoice"></i> Billing</a>
    <% } else { %>
    <a class="nav-item" href="staff-dashboard.jsp"><i class="fa fa-gauge-high"></i> Dashboard</a>
    <a class="nav-item" href="products.jsp"><i class="fa fa-box"></i> Products</a>
    <a class="nav-item" href="staff-orders.jsp"><i class="fa fa-shopping-bag"></i> Orders</a>
    <a class="nav-item" href="manage-delivery-boys.jsp"><i class="fa fa-motorcycle"></i> Delivery Boys</a>
    <a class="nav-item" href="staff-attendance.jsp"><i class="fa fa-clock"></i> My Attendance</a>
    <a class="nav-item active" href="admin-delivery-slots.jsp"><i class="fa fa-calendar-check"></i> Delivery Slots</a>
    <a class="nav-item" href="AdminReturnServlet?action=list"><i class="fa fa-rotate-left"></i> Manage Returns</a>
    <a class="nav-item" href="staff-cancelled-orders.jsp"><i class="fa fa-ban"></i> Cancelled Orders</a>
    <a class="nav-item" href="admin-cod-ledger.jsp"><i class="fa fa-money-bill-wave"></i> COD Remittance</a>
    <% } %>
  </nav>
  <div class="sidebar-footer">
    <a class="nav-item" href="logout" style="padding:0;color:#94a3b8;">
      <i class="fa fa-sign-out-alt"></i> Logout (<%=user.getUsername()%>)
    </a>
  </div>
</div>

<!-- ══════════ TOPBAR ══════════ -->
<div class="topbar">
  <span class="topbar-left">
    <i class="fa fa-calendar-check" style="color:var(--primary);margin-right:8px;"></i>
    Delivery Slot Monitor
  </span>
  <div class="topbar-right">
    <button class="dark-btn" onclick="toggleDark()" title="Toggle dark mode"><i class="fa fa-moon"></i></button>
    <div class="dropdown">
      <div class="profile-pill" onclick="toggleDropdown()">
        <div class="avatar"><%=user.getUsername().substring(0,1).toUpperCase()%></div>
        <div>
          <div class="profile-name"><%=user.getUsername()%></div>
          <div class="profile-role"><%=isAdmin ? "Admin" : "Staff"%></div>
        </div>
        <i class="fa fa-chevron-down" style="font-size:10px;color:var(--muted);"></i>
      </div>
      <div class="dropdown-menu" id="profileDrop">
        <div class="dropdown-header">
          <p><%=user.getUsername()%></p>
          <span><%=user.getEmail()%></span>
        </div>
        <a class="dropdown-item red" href="logout"><i class="fa fa-sign-out-alt"></i> Logout</a>
      </div>
    </div>
  </div>
</div>

<!-- ══════════ CONTENT ══════════ -->
<div class="content">

  <div class="page-header">
    <div>
      <div class="page-title">Delivery Slot Monitor</div>
      <div class="page-sub">
        Live slot availability and shift tracking for today — <%=new java.util.Date().toString().substring(0,10)%>
      </div>
    </div>
  </div>

  <!-- ══ SECTION 1: SLOT UTILIZATION CARDS ══ -->
  <div class="section-head" style="margin-bottom:12px;">
    <div class="section-title">
      <i class="fa fa-chart-bar"></i> Slot Availability — Today
    </div>
  </div>

  <div class="slot-util-grid">
  <% if (utilization.isEmpty()) { %>
    <div style="color:var(--muted);font-size:13px;padding:16px;">No slots configured.</div>
  <% } else {
       for (DeliverySlot s : utilization) {
         int pct = s.getMaxCapacity() > 0
             ? Math.min(100, (int)Math.round(s.getBookedCount() * 100.0 / s.getMaxCapacity())) : 0;
         String barCls = pct < 50 ? "low" : pct < 85 ? "mid" : "high";
         int remaining = s.getMaxCapacity() - s.getBookedCount();
  %>
    <div class="slot-util-card">
      <div class="slot-util-top">
        <span class="slot-name"><%=s.getSlotName()%></span>
        <span class="slot-time-tag">
          <%=s.getStartTime().toString().substring(0,5)%> – <%=s.getEndTime().toString().substring(0,5)%>
        </span>
      </div>
      <div class="slot-bar-track">
        <div class="slot-bar-fill <%=barCls%>" style="width:<%=pct%>%;"></div>
      </div>
      <div class="slot-util-row">
        <div>Booked <span><%=s.getBookedCount()%></span></div>
        <div>Available <span style="color:<%=remaining>0?"var(--success)":"var(--danger)"%>;"><%=remaining%></span></div>
        <div>Max <span><%=s.getMaxCapacity()%></span></div>
      </div>
    </div>
  <% } } %>
  </div>

  <!-- ══ SUMMARY STAT CARDS ══ -->
  <div class="stat-cards">
    <div class="stat-card">
      <div class="stat-icon icon-purple"><i class="fa fa-calendar-check"></i></div>
      <div class="stat-num"><%=todayBookings.size()%></div>
      <div class="stat-label">Total Bookings</div>
    </div>
    <div class="stat-card">
      <div class="stat-icon icon-blue"><i class="fa fa-clock"></i></div>
      <div class="stat-num"><%=totalBooked%></div>
      <div class="stat-label">Booked (Not Started)</div>
    </div>
    <div class="stat-card">
      <div class="stat-icon icon-green"><i class="fa fa-circle-dot"></i></div>
      <div class="stat-num"><%=totalActive%></div>
      <div class="stat-label">Currently On Shift</div>
    </div>
    <div class="stat-card">
      <div class="stat-icon icon-amber"><i class="fa fa-circle-check"></i></div>
      <div class="stat-num"><%=totalCompleted%></div>
      <div class="stat-label">Completed</div>
    </div>
    <div class="stat-card">
      <div class="stat-icon icon-red"><i class="fa fa-ban"></i></div>
      <div class="stat-num"><%=totalCancelled%></div>
      <div class="stat-label">Cancelled</div>
    </div>
  </div>

  <!-- ══ SECTION 2: TODAY'S BOOKINGS TABLE ══ -->
  <div class="section-head">
    <div class="section-title">
      <span class="live-dot"></span>
      <i class="fa fa-calendar-day"></i> Today's Slot Bookings
    </div>
    <div class="search-box">
      <i class="fa fa-search"></i>
      <input type="text" placeholder="Search delivery boy…" oninput="filterTable('todayTbody', this.value)">
    </div>
  </div>

  <div class="table-wrap">
    <table>
      <thead>
        <tr>
          <th>#</th>
          <th>Delivery Boy</th>
          <th>Slot</th>
          <th>Slot Time</th>
          <th>Shift Start</th>
          <th>Shift End</th>
          <th>Working Hrs</th>
          <th>Status</th>
        </tr>
      </thead>
      <tbody id="todayTbody">
        <% if (todayBookings.isEmpty()) { %>
        <tr>
          <td colspan="8">
            <div class="empty">
              <i class="fa fa-calendar-xmark"></i>
              <p>No slot bookings found for today.</p>
            </div>
          </td>
        </tr>
        <% } else {
             int idx = 1;
             for (DeliverySlot b : todayBookings) {
               String st  = b.getStatus() != null ? b.getStatus() : "";
               String bc  = "BOOKED".equals(st)    ? "badge-booked"
                          : "ACTIVE".equals(st)    ? "badge-active"
                          : "COMPLETED".equals(st) ? "badge-completed"
                          : "badge-cancelled";
               String stl = "BOOKED".equals(st)    ? "Booked"
                          : "ACTIVE".equals(st)    ? "On Shift"
                          : "COMPLETED".equals(st) ? "Completed"
                          : "Cancelled";
               String init = (b.getDeliveryBoyName() != null && !b.getDeliveryBoyName().isEmpty())
                           ? b.getDeliveryBoyName().substring(0,1).toUpperCase() : "?";
        %>
        <tr>
          <td style="color:var(--muted);font-size:12px;"><%=idx++%></td>
          <td>
            <div class="emp-name-cell">
              <div class="emp-avatar"><%=init%></div>
              <%=b.getDeliveryBoyName() != null ? b.getDeliveryBoyName() : "—"%>
            </div>
          </td>
          <td style="font-weight:600;"><%=b.getSlotName()%></td>
          <td><%=b.getStartTime().toString().substring(0,5)%> – <%=b.getEndTime().toString().substring(0,5)%></td>
          <td><%=b.getShiftStart() != null ? b.getShiftStart().toString().substring(0,5) : "—"%></td>
          <td><%=b.getShiftEnd()   != null ? b.getShiftEnd().toString().substring(0,5)   : "—"%></td>
          <td style="font-weight:600;"><%=b.getWorkingHours() != null ? b.getWorkingHours() : "—"%></td>
          <td><span class="badge <%=bc%>"><%=stl%></span></td>
        </tr>
        <% } } %>
      </tbody>
    </table>
  </div>

  <!-- ══ SECTION 3: MONTHLY REPORT ══ -->
  <div class="section-head" style="margin-top:8px;">
    <div class="section-title">
      <i class="fa fa-calendar-alt"></i>
      Monthly Report — <%=MONTHS[selMonth]%> <%=selYear%>
    </div>
    <form method="get" action="admin-delivery-slots.jsp" class="filter-bar">
      <select name="month">
        <% for (int m = 1; m <= 12; m++) { %>
        <option value="<%=m%>" <%=m==selMonth?"selected":""%>><%=MONTHS[m]%></option>
        <% } %>
      </select>
      <input type="number" name="year" value="<%=selYear%>" min="2020" max="<%=curYear+1%>" style="width:90px;">
      <button type="submit" class="btn-primary"><i class="fa fa-filter"></i> Filter</button>
      <a href="admin-delivery-slots.jsp" class="btn-outline"><i class="fa fa-rotate-right"></i> Reset</a>
    </form>
  </div>

  <%
  int mBooked=0, mActive=0, mCompleted=0, mCancelled=0;
  for (DeliverySlot b : monthlyList) {
      String s = b.getStatus() != null ? b.getStatus() : "";
      if      ("BOOKED".equals(s))    mBooked++;
      else if ("ACTIVE".equals(s))    mActive++;
      else if ("COMPLETED".equals(s)) mCompleted++;
      else if ("CANCELLED".equals(s)) mCancelled++;
  }
  %>
  <% if (!monthlyList.isEmpty()) { %>
  <div style="display:flex;gap:16px;flex-wrap:wrap;margin-bottom:14px;font-size:13px;color:var(--muted);">
    <span>Total <strong style="color:var(--text);"><%=monthlyList.size()%></strong></span> ·
    <span>Completed <strong style="color:#4338ca;"><%=mCompleted%></strong></span> ·
    <span>On Shift <strong style="color:var(--success);"><%=mActive%></strong></span> ·
    <span>Booked <strong style="color:#1d4ed8;"><%=mBooked%></strong></span> ·
    <span>Cancelled <strong style="color:var(--danger);"><%=mCancelled%></strong></span>
  </div>
  <% } %>

  <div class="table-wrap">
    <table>
      <thead>
        <tr>
          <th>#</th>
          <th>Date</th>
          <th>Delivery Boy</th>
          <th>Slot</th>
          <th>Slot Time</th>
          <th>Shift Start</th>
          <th>Shift End</th>
          <th>Working Hrs</th>
          <th>Status</th>
        </tr>
      </thead>
      <tbody id="monthlyTbody">
        <% if (monthlyList.isEmpty()) { %>
        <tr>
          <td colspan="9">
            <div class="empty">
              <i class="fa fa-calendar-xmark"></i>
              <p>No slot bookings found for <%=MONTHS[selMonth]%> <%=selYear%>.</p>
            </div>
          </td>
        </tr>
        <% } else {
             int idx = 1;
             for (DeliverySlot b : monthlyList) {
               String st  = b.getStatus() != null ? b.getStatus() : "";
               String bc  = "BOOKED".equals(st)    ? "badge-booked"
                          : "ACTIVE".equals(st)    ? "badge-active"
                          : "COMPLETED".equals(st) ? "badge-completed"
                          : "badge-cancelled";
               String stl = "BOOKED".equals(st)    ? "Booked"
                          : "ACTIVE".equals(st)    ? "On Shift"
                          : "COMPLETED".equals(st) ? "Completed"
                          : "Cancelled";
               String init = (b.getDeliveryBoyName() != null && !b.getDeliveryBoyName().isEmpty())
                           ? b.getDeliveryBoyName().substring(0,1).toUpperCase() : "?";
        %>
        <tr>
          <td style="color:var(--muted);font-size:12px;"><%=idx++%></td>
          <td style="font-weight:500;white-space:nowrap;"><%=b.getBookingDate()%></td>
          <td>
            <div class="emp-name-cell">
              <div class="emp-avatar"><%=init%></div>
              <%=b.getDeliveryBoyName() != null ? b.getDeliveryBoyName() : "—"%>
            </div>
          </td>
          <td style="font-weight:600;"><%=b.getSlotName()%></td>
          <td><%=b.getStartTime().toString().substring(0,5)%> – <%=b.getEndTime().toString().substring(0,5)%></td>
          <td><%=b.getShiftStart() != null ? b.getShiftStart().toString().substring(0,5) : "—"%></td>
          <td><%=b.getShiftEnd()   != null ? b.getShiftEnd().toString().substring(0,5)   : "—"%></td>
          <td style="font-weight:600;"><%=b.getWorkingHours() != null ? b.getWorkingHours() : "—"%></td>
          <td><span class="badge <%=bc%>"><%=stl%></span></td>
        </tr>
        <% } } %>
      </tbody>
    </table>
  </div>

</div><!-- /content -->

<script>
// ── Live search ──
function filterTable(tbodyId, q) {
  q = q.toLowerCase().trim();
  document.getElementById(tbodyId).querySelectorAll('tr').forEach(row => {
    row.style.display = !q || row.textContent.toLowerCase().includes(q) ? '' : 'none';
  });
}

// ── Dark mode ──
function toggleDark() {
  const h = document.documentElement, d = h.getAttribute('data-theme') === 'dark';
  h.setAttribute('data-theme', d ? 'light' : 'dark');
  localStorage.setItem('sibs-theme', d ? 'light' : 'dark');
}
(function(){ const t = localStorage.getItem('sibs-theme'); if(t) document.documentElement.setAttribute('data-theme',t); })();

// ── Dropdown ──
function toggleDropdown(){ document.getElementById('profileDrop').classList.toggle('open'); }
document.addEventListener('click', e => {
  if (!e.target.closest('.dropdown')) document.getElementById('profileDrop').classList.remove('open');
});

// ── Auto-refresh today's table every 60s ──
setTimeout(() => location.reload(), 60000);
</script>
</body>
</html>
