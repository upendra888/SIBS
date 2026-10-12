<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="com.sibs.model.User, com.sibs.model.StaffAttendance, com.sibs.dao.StaffAttendanceDAO, java.util.List, java.util.Calendar, java.util.LinkedHashMap, java.util.Map" %>
<%
// ── Auth: ADMIN only ──────────────────────────────────────────────────────────
User user = (User) session.getAttribute("user");
if (user == null || !"ADMIN".equals(user.getRole())) {
    response.sendRedirect("login.jsp");
    return;
}

// ── Month/year filter (default = current month) ───────────────────────────────
Calendar cal = Calendar.getInstance();
int curYear  = cal.get(Calendar.YEAR);
int curMonth = cal.get(Calendar.MONTH) + 1;  // 1-12

int selYear  = curYear;
int selMonth = curMonth;
try {
    String py = request.getParameter("year"),  pm = request.getParameter("month");
    if (py != null && !py.isEmpty()) selYear  = Integer.parseInt(py);
    if (pm != null && !pm.isEmpty()) selMonth = Integer.parseInt(pm);
} catch (NumberFormatException ignored) {}

// ── DAO calls ─────────────────────────────────────────────────────────────────
StaffAttendanceDAO dao = new StaffAttendanceDAO();
dao.autoPunchOut(); // Auto punch-out at 18:00 for forgotten checkouts
List<StaffAttendance> todayList    = dao.getTodayAll();
List<StaffAttendance> monthlyList  = dao.getMonthlyReport(selYear, selMonth);
// FIX #3 & #9: getTodaySummary now returns 5 elements: [present, absent, late, half_day, total]
int[] summary = dao.getTodaySummary();

String[] MONTHS = {"","January","February","March","April","May","June",
                   "July","August","September","October","November","December"};
%>
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Staff Attendance Report — SIBS Admin</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<style>
/* ── CSS Variables ─────────────────────────────────────────────────────────── */
:root{
  --bg:#f8fafc;--surface:#fff;--border:#e2e8f0;
  --text:#0f172a;--muted:#64748b;--primary:#2563eb;
  --success:#16a34a;--danger:#ef4444;--warn:#f59e0b;
  --sidebar:#0f172a;--sidebar-text:#cbd5e1;--sidebar-hover:#1e293b;
}
[data-theme="dark"]{
  --bg:#0f172a;--surface:#1e293b;--border:#334155;
  --text:#f1f5f9;--muted:#94a3b8;--sidebar:#020617;--sidebar-hover:#0f172a;
}
*{margin:0;padding:0;box-sizing:border-box;font-family:'Inter',sans-serif;}
body{background:var(--bg);color:var(--text);}

/* ── Sidebar ───────────────────────────────────────────────────────────────── */
.sidebar{width:240px;height:100vh;background:var(--sidebar);position:fixed;top:0;left:0;display:flex;flex-direction:column;z-index:200;}
.sidebar-logo{padding:20px 24px;border-bottom:1px solid rgba(255,255,255,.07);display:flex;align-items:center;gap:10px;}
.sidebar-logo span{color:#fff;font-weight:700;font-size:18px;}
.sidebar-logo i{color:var(--primary);font-size:20px;}
.sidebar nav{flex:1;padding:12px 0;overflow-y:auto;}
.nav-item{display:flex;align-items:center;gap:10px;padding:11px 20px;color:var(--sidebar-text);text-decoration:none;font-size:14px;transition:.15s;border-left:3px solid transparent;}
.nav-item:hover,.nav-item.active{background:var(--sidebar-hover);color:#fff;border-left-color:var(--primary);}
.nav-item i{width:18px;text-align:center;}
.sidebar-footer{padding:16px;border-top:1px solid rgba(255,255,255,.07);}

/* ── Topbar ────────────────────────────────────────────────────────────────── */
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

/* ── Content ───────────────────────────────────────────────────────────────── */
.content{margin-left:0;padding:28px 24px;}
.page-header{display:flex;align-items:flex-start;justify-content:space-between;flex-wrap:wrap;gap:16px;margin-bottom:24px;}
.page-title{font-size:21px;font-weight:700;}
.page-sub{font-size:13px;color:var(--muted);margin-top:3px;}

/* ── Summary cards ─────────────────────────────────────────────────────────── */
.cards{display:grid;grid-template-columns:repeat(auto-fit,minmax(160px,1fr));gap:16px;margin-bottom:28px;}
.card{background:var(--surface);border:1px solid var(--border);border-radius:14px;padding:18px 20px;display:flex;flex-direction:column;gap:6px;box-shadow:0 1px 3px rgba(0,0,0,.05);}
.card-icon{width:38px;height:38px;border-radius:10px;display:flex;align-items:center;justify-content:center;font-size:16px;margin-bottom:4px;}
.icon-green{background:#dcfce7;color:#16a34a;}
.icon-red  {background:#fee2e2;color:#ef4444;}
.icon-warn {background:#fef9c3;color:#92400e;}
.icon-blue {background:#dbeafe;color:#1d4ed8;}
.card-num{font-size:28px;font-weight:700;}
.card-label{font-size:12px;color:var(--muted);font-weight:500;}

/* ── Section header ────────────────────────────────────────────────────────── */
.section-head{display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:12px;margin-bottom:14px;}
.section-title{font-size:16px;font-weight:700;display:flex;align-items:center;gap:8px;}
.section-title i{color:var(--primary);}

/* ── Filter form ───────────────────────────────────────────────────────────── */
.filter-bar{display:flex;align-items:center;gap:10px;flex-wrap:wrap;}
.filter-bar select,.filter-bar input[type=number]{padding:8px 12px;border:1px solid var(--border);border-radius:8px;font-size:13px;background:var(--surface);color:var(--text);outline:none;}
.filter-bar select:focus,.filter-bar input:focus{border-color:var(--primary);}
.btn-primary{padding:8px 18px;background:var(--primary);color:#fff;border:none;border-radius:8px;font-size:13px;font-weight:600;cursor:pointer;display:flex;align-items:center;gap:6px;}
.btn-primary:hover{background:#1d4ed8;}
.btn-outline{padding:8px 14px;background:var(--surface);color:var(--text);border:1px solid var(--border);border-radius:8px;font-size:13px;font-weight:600;cursor:pointer;display:flex;align-items:center;gap:6px;}
.btn-outline:hover{background:var(--bg);}

/* ── Table ─────────────────────────────────────────────────────────────────── */
.table-wrap{overflow-x:auto;border-radius:12px;border:1px solid var(--border);background:var(--surface);margin-bottom:32px;}
table{width:100%;border-collapse:collapse;font-size:13px;}
thead tr{background:var(--bg);}
th{padding:12px 14px;text-align:left;font-weight:600;color:var(--muted);font-size:11px;text-transform:uppercase;letter-spacing:.4px;border-bottom:1px solid var(--border);white-space:nowrap;}
td{padding:11px 14px;border-bottom:1px solid var(--border);color:var(--text);}
tr:last-child td{border-bottom:none;}
tr:hover td{background:var(--bg);}
.emp-name{font-weight:600;display:flex;align-items:center;gap:8px;}
.emp-avatar{width:28px;height:28px;border-radius:50%;background:var(--primary);display:flex;align-items:center;justify-content:center;color:#fff;font-weight:700;font-size:11px;flex-shrink:0;}

/* ── Status badges ─────────────────────────────────────────────────────────── */
.badge{padding:3px 11px;border-radius:99px;font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:.3px;white-space:nowrap;}
.badge-present,.badge-full{background:#dcfce7;color:#15803d;}
.badge-late   {background:#fef9c3;color:#92400e;}
.badge-half       {background:#dbeafe;color:#1d4ed8;}
.badge-incomplete {background:#ede9fe;color:#6d28d9;}
.badge-absent {background:#fee2e2;color:#dc2626;}
.badge-none   {background:var(--bg);color:var(--muted);}


/* ── Status filter pills ───────────────────────────────────────────────────── */
.status-filters{display:flex;gap:8px;flex-wrap:wrap;margin-bottom:14px;}
.pill{padding:6px 14px;border-radius:99px;font-size:12px;font-weight:600;cursor:pointer;border:2px solid transparent;transition:.15s;user-select:none;}
.pill.all     {background:#f1f5f9;color:var(--text);border-color:#e2e8f0;}
.pill.present {background:#dcfce7;color:#15803d;border-color:#dcfce7;}
.pill.late    {background:#fef9c3;color:#92400e;border-color:#fef9c3;}
.pill.half    {background:#dbeafe;color:#1d4ed8;border-color:#dbeafe;}
.pill.incomplete{background:#ede9fe;color:#6d28d9;border-color:#ede9fe;}
.pill.absent  {background:#fee2e2;color:#dc2626;border-color:#fee2e2;}
.pill.active  {border-color:#334155 !important;}
.name-link{color:var(--primary);text-decoration:underline;text-underline-offset:2px;cursor:pointer;font-weight:600;}
.name-link:hover{color:#1d4ed8;}
/* ── Clickable staff name in today table ──────────────────────────────────── */
.today-name-active{color:#1d4ed8 !important;background:#dbeafe;border-radius:6px;padding:1px 5px;}
/* ── Empty state ───────────────────────────────────────────────────────────── */
.empty{text-align:center;padding:48px 20px;color:var(--muted);}
.empty i{font-size:36px;margin-bottom:12px;opacity:.35;}
.empty p{font-size:14px;}

/* ── Search input ──────────────────────────────────────────────────────────── */
.search-box{position:relative;display:flex;align-items:center;}
.search-box i{position:absolute;left:10px;color:var(--muted);font-size:13px;}
.search-box input{padding:8px 12px 8px 32px;border:1px solid var(--border);border-radius:8px;font-size:13px;background:var(--surface);color:var(--text);outline:none;width:200px;}
.search-box input:focus{border-color:var(--primary);}

/* ── Staff Detail Modal ─────────────────────────────────────────────────────── */
.modal-overlay{position:fixed;inset:0;background:rgba(0,0,0,.45);z-index:999;display:none;align-items:center;justify-content:center;}
.modal-overlay.open{display:flex;}
.modal-box{background:var(--surface);border-radius:18px;width:420px;max-width:95vw;box-shadow:0 24px 60px rgba(0,0,0,.22);overflow:hidden;animation:modalIn .22s ease;}
@keyframes modalIn{from{transform:scale(.93);opacity:0}to{transform:scale(1);opacity:1}}
.modal-header{padding:20px 22px 16px;border-bottom:1px solid var(--border);display:flex;align-items:center;gap:12px;}
.modal-avatar{width:46px;height:46px;border-radius:50%;background:var(--primary);display:flex;align-items:center;justify-content:center;color:#fff;font-weight:700;font-size:18px;flex-shrink:0;}
.modal-name{font-size:17px;font-weight:700;}
.modal-sub{font-size:12px;color:var(--muted);margin-top:2px;}
.modal-close{margin-left:auto;background:none;border:none;font-size:18px;color:var(--muted);cursor:pointer;width:32px;height:32px;border-radius:8px;display:flex;align-items:center;justify-content:center;}
.modal-close:hover{background:var(--bg);color:var(--text);}
.modal-body{padding:20px 22px;}
/* Donut / percent ring */
.pct-ring-wrap{display:flex;flex-direction:column;align-items:center;margin-bottom:20px;}
.pct-ring{position:relative;width:120px;height:120px;}
.pct-ring svg{transform:rotate(-90deg);}
.pct-ring-label{position:absolute;inset:0;display:flex;flex-direction:column;align-items:center;justify-content:center;}
.pct-ring-num{font-size:26px;font-weight:800;color:var(--text);}
.pct-ring-txt{font-size:11px;color:var(--muted);font-weight:500;}
.pct-caption{margin-top:6px;font-size:13px;color:var(--muted);font-weight:500;}
/* Stat rows */
.stat-grid{display:grid;grid-template-columns:1fr 1fr;gap:10px;margin-bottom:4px;}
.stat-item{border-radius:10px;padding:10px 12px;display:flex;align-items:center;gap:10px;}
.stat-dot{width:10px;height:10px;border-radius:50%;flex-shrink:0;}
.stat-info{flex:1;}
.stat-label{font-size:11px;color:var(--muted);font-weight:500;}
.stat-val{font-size:18px;font-weight:800;}
.stat-pct{font-size:11px;font-weight:600;margin-left:4px;opacity:.75;}
.prog-bar-wrap{margin-top:14px;}
.prog-row{display:flex;align-items:center;gap:8px;margin-bottom:7px;font-size:12px;}
.prog-label{width:72px;color:var(--muted);font-weight:500;}
.prog-track{flex:1;height:7px;background:var(--border);border-radius:99px;overflow:hidden;}
.prog-fill{height:100%;border-radius:99px;transition:width .5s ease;}
.prog-count{width:28px;text-align:right;font-weight:700;font-size:12px;}

</style>
</head>
<body>

<!-- ── SIDEBAR ────────────────────────────────────────────────────────────── -->
<div class="sidebar">
  <div class="sidebar-logo"><i class="fa fa-cubes"></i><span>SIBS Admin</span></div>
  <nav>
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
    <a class="nav-item" href="staff-cancelled-orders.jsp"><i class="fa fa-ban"></i> Cancelled / Not Delivered</a>
    <a class="nav-item active" href="admin-attendance.jsp"><i class="fa fa-clock"></i> Staff Attendance</a>
    <a class="nav-item" href="invoice.jsp"><i class="fa fa-file-invoice"></i> Billing</a>
  </nav>
  <div class="sidebar-footer">
    <a class="nav-item" href="logout" style="padding:0;color:#94a3b8;">
      <i class="fa fa-sign-out-alt"></i> Logout (<%=user.getUsername()%>)
    </a>
  </div>
</div>

<!-- ── TOPBAR ─────────────────────────────────────────────────────────────── -->
<div class="topbar">
  <span class="topbar-left">Staff Attendance Report</span>
  <div class="topbar-right">
    <button class="dark-btn" onclick="toggleDark()" title="Toggle dark mode"><i class="fa fa-moon"></i></button>
    <div class="dropdown">
      <div class="profile-pill" onclick="toggleDropdown()">
        <div class="avatar"><%=user.getUsername().substring(0,1).toUpperCase()%></div>
        <div>
          <div class="profile-name"><%=user.getUsername()%></div>
          <div class="profile-role">Admin</div>
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

<!-- ── CONTENT ────────────────────────────────────────────────────────────── -->
<div class="content">

  <div class="page-header">
    <div>
      <div class="page-title"><i class="fa fa-clock" style="color:var(--primary);margin-right:8px;"></i>Staff Attendance</div>
      <div class="page-sub">Live today's attendance and monthly history reports.</div>
    </div>
  </div>

  <!-- ── SUMMARY CARDS ──────────────────────────────────────────────────────── -->
  <!-- FIX #3 & #9: summary[4] is now real total from users table; LATE no longer counted as absent -->
  <div class="cards">
    <div class="card">
      <div class="card-icon icon-green"><i class="fa fa-user-check"></i></div>
      <div class="card-num"><%=summary[0]%></div>
      <div class="card-label">Present Today</div>
    </div>
    <div class="card">
      <div class="card-icon icon-red"><i class="fa fa-user-xmark"></i></div>
      <div class="card-num"><%=summary[1]%></div>
      <div class="card-label">Absent Today</div>
    </div>
    <div class="card">
      <div class="card-icon icon-warn"><i class="fa fa-clock-rotate-left"></i></div>
      <div class="card-num"><%=summary[2]%></div>
      <div class="card-label">Late Today</div>
    </div>
    <div class="card">
      <!-- FIX #11: replaced invalid "fa-calendar-half" with valid "fa-hourglass-half" -->
      <div class="card-icon icon-blue"><i class="fa fa-hourglass-half"></i></div>
      <div class="card-num"><%=summary[3]%></div>
      <div class="card-label">Half Day</div>
    </div>
    <div class="card">
      <div class="card-icon" style="background:#f3e8ff;color:#7c3aed;"><i class="fa fa-users"></i></div>
      <!-- FIX #9: use summary[4] = actual total staff count from users table -->
      <div class="card-num"><%=summary[4]%></div>
      <div class="card-label">Total Staff</div>
    </div>
  </div>

  <!-- ══════════════════════════════════════════════════════════════════════
       SECTION 1 — TODAY'S ATTENDANCE
  ═══════════════════════════════════════════════════════════════════════ -->
  <div class="section-head">
    <div class="section-title">
      <i class="fa fa-calendar-day"></i>
      Today's Attendance
    </div>
    <div class="search-box">
      <i class="fa fa-search"></i>
      <input type="text" id="todaySearch" placeholder="Search staff…" oninput="filterTable('todayTbody', this.value)">
    </div>
  </div>

  <%
  int tPresent=0,tLate=0,tAbsent=0,tHalf=0,tIncomplete=0,tNotIn=0;
  for(StaffAttendance tmp : todayList){
      String ts = tmp.getStatus()!=null?tmp.getStatus():"NOT CHECKED IN";
      switch(ts){
          case "PRESENT": case "FULL_DAY": tPresent++; break;
          case "LATE":       tLate++;       break;
          case "HALF_DAY":   tHalf++;       break;
          case "INCOMPLETE": tIncomplete++; break;
          case "ABSENT":     tAbsent++;     break;
          default:           tNotIn++;      break;
      }
  }
  %>
  <!-- Today filter pills -->
  <div class="status-filters" id="todayFilters">
    <span class="pill all active" onclick="filterToday('all',this)">All (<%=todayList.size()%>)</span>
    <span class="pill present"    onclick="filterToday('present',this)">Present (<%=tPresent + tLate%>)</span>
    <span class="pill late"       onclick="filterToday('late',this)">Late (<%=tLate%>)</span>
    <span class="pill half"       onclick="filterToday('half_day',this)">Half Day (<%=tHalf%>)</span>
    <span class="pill incomplete" onclick="filterToday('incomplete',this)">Incomplete (<%=tIncomplete%>)</span>
    <span class="pill absent"     onclick="filterToday('absent',this)">Absent (<%=tAbsent%>)</span>
    <span class="pill all"        onclick="filterToday('not_checked_in',this)">Not Checked In (<%=tNotIn%>)</span>
  </div>

  <div class="table-wrap">
    <table>
      <thead>
        <tr>
          <th>#</th>
          <th>Staff Name</th>
          <th>Check In</th>
          <th>Break Start</th>
          <th>Break End</th>
          <th>Check Out</th>
          <th>Total Break</th>
          <th>Working Hrs</th>
          <th>Status</th>
        </tr>
      </thead>
      <tbody id="todayTbody">
        <%
        if (todayList.isEmpty()) {
        %>
        <tr>
          <td colspan="9">
            <div class="empty">
              <i class="fa fa-users"></i>
              <p>No active staff members found.</p>
            </div>
          </td>
        </tr>
        <%
        } else {
            int idx = 1;
            for (StaffAttendance a : todayList) {
                String sc = "badge-absent", st = "Absent";
                String status = a.getStatus() != null ? a.getStatus() : "ABSENT";
                switch (status) {
                    case "PRESENT":        sc="badge-present";    st="Present";         break;
                    case "FULL_DAY":       sc="badge-full";       st="Full Day";        break;
                    case "LATE":           sc="badge-late";        st="Late";            break;
                    case "HALF_DAY":       sc="badge-half";        st="Half Day";        break;
                    case "ABSENT":         sc="badge-absent";      st="Absent";          break;
                    case "INCOMPLETE":     sc="badge-incomplete";  st="Incomplete";      break;
                    case "NOT CHECKED IN": sc="badge-none";        st="Not Checked In";  break;
                }
                String initials = (a.getEmployeeName() != null && !a.getEmployeeName().isEmpty())
                    ? a.getEmployeeName().substring(0,1).toUpperCase() : "?";
        %>
        <tr data-today-status="<%=status.toLowerCase().replace(" ","_")%>">
          <td style="color:var(--muted);font-size:12px;"><%=idx++%></td>
          <td>
            <div class="emp-name">
              <div class="emp-avatar"><%=initials%></div>
              <span class="name-link"
                    data-empname="<%=a.getEmployeeName() != null ? a.getEmployeeName() : ""%>"
                    onclick="openStaffModal(this.dataset.empname)"
                    title="Click to view monthly report"><%=a.getEmployeeName() != null ? a.getEmployeeName() : "—"%></span>
              <i class="fa fa-chevron-down" style="font-size:9px;color:var(--muted);margin-left:3px;"></i>
            </div>
          </td>
          <td><%=a.getCheckIn()  != null ? a.getCheckIn().toString().substring(0,5)  : "—"%></td>
          <td><%=a.getBreakIn()  != null ? a.getBreakIn().toString().substring(0,5)  : "—"%></td>
          <td><%=a.getBreakOut() != null ? a.getBreakOut().toString().substring(0,5) : "—"%></td>
          <td><%=a.getCheckOut() != null ? a.getCheckOut().toString().substring(0,5) : "—"%></td>
          <td><%=a.getTotalBreakTime() != null ? a.getTotalBreakTime() : "0:00"%></td>
          <td style="font-weight:600;"><%=a.getWorkingHours() != null ? a.getWorkingHours() : "—"%></td>
          <td><span class="badge <%=sc%>"><%=st%></span></td>
        </tr>
        <%
            }
        }
        %>
      </tbody>
    </table>
  </div>

  <!-- ══════════════════════════════════════════════════════════════════════
       SECTION 2 — MONTHLY REPORT
  ═══════════════════════════════════════════════════════════════════════ -->
  <div class="section-head" style="margin-top:8px;">
    <div class="section-title">
      <i class="fa fa-calendar-alt"></i>
      Monthly Report — <%=MONTHS[selMonth]%> <%=selYear%>
    </div>
    <div style="display:flex;align-items:center;gap:10px;flex-wrap:wrap;">
    <div class="search-box">
      <i class="fa fa-search"></i>
      <input type="text" id="monthlySearch" placeholder="Search staff…" oninput="filterMonthly(this.value)">
    </div>
    <form method="get" action="admin-attendance.jsp" class="filter-bar">
      <select name="month">
        <% for (int m = 1; m <= 12; m++) { %>
        <option value="<%=m%>" <%=m == selMonth ? "selected" : ""%>><%=MONTHS[m]%></option>
        <% } %>
      </select>
      <!-- FIX #10: max year is curYear + 1 so December of prior year is reachable in January -->
      <input type="number" name="year" value="<%=selYear%>" min="2020" max="<%=curYear + 1%>" style="width:90px;">
      <button type="submit" class="btn-primary"><i class="fa fa-filter"></i> Filter</button>
      <a href="admin-attendance.jsp" class="btn-outline"><i class="fa fa-rotate-right"></i> Reset</a>
    </form>
    </div>
  </div>

  <!-- Monthly stats bar -->
  <%
  int mPresent=0, mFullDay=0, mAbsent=0, mLate=0, mHalf=0, mIncomplete=0;
  for (StaffAttendance a : monthlyList) {
      String s = a.getStatus() != null ? a.getStatus() : "ABSENT";
      if      ("FULL_DAY".equals(s))    mFullDay++;
      else if ("PRESENT".equals(s))     mPresent++;
      else if ("LATE".equals(s))        mLate++;
      else if ("HALF_DAY".equals(s))    mHalf++;
      else if ("INCOMPLETE".equals(s))  mIncomplete++;
      else                              mAbsent++;
  }
  int mTotal = monthlyList.size();

  // Build per-staff summary map: name -> [present, late, halfday, incomplete, absent, total]
  LinkedHashMap<String, int[]> staffSummary = new LinkedHashMap<>();
  for (StaffAttendance a : monthlyList) {
      String name = a.getEmployeeName() != null ? a.getEmployeeName() : "Unknown";
      if (!staffSummary.containsKey(name)) staffSummary.put(name, new int[6]);
      int[] c = staffSummary.get(name);
      String s = a.getStatus() != null ? a.getStatus() : "ABSENT";
      if      ("PRESENT".equals(s) || "FULL_DAY".equals(s)) c[0]++;
      else if ("LATE".equals(s))       c[1]++;
      else if ("HALF_DAY".equals(s))   c[2]++;
      else if ("INCOMPLETE".equals(s)) c[3]++;
      else                             c[4]++;
      c[5]++;
  }
  %>
  <% if (mTotal > 0) { %>
  <div style="display:flex;gap:16px;flex-wrap:wrap;margin-bottom:16px;">
    <div style="font-size:13px;color:var(--muted);">
      <span style="font-weight:700;color:#16a34a;"><%=mFullDay%></span> Full Day &nbsp;·&nbsp;
      <span style="font-weight:700;color:#16a34a;"><%=mPresent%></span> Present &nbsp;·&nbsp;
      <span style="font-weight:700;color:#92400e;"><%=mLate%></span> Late &nbsp;·&nbsp;
      <span style="font-weight:700;color:#1d4ed8;"><%=mHalf%></span> Half-Day &nbsp;·&nbsp;
      <span style="font-weight:700;color:#dc2626;"><%=mAbsent%></span> Absent &nbsp;·&nbsp;
      <span style="font-weight:700;color:#6d28d9;"><%=mIncomplete%></span> Incomplete &nbsp;·&nbsp;
      <span style="font-weight:700;"><%=mTotal%></span> Total Records
    </div>
  </div>
  <% } %>





  <!-- Embed staff summary data for modal -->
  <script id="staffDataScript">
  const STAFF_DATA = {};
    <%
    for (Map.Entry<String, int[]> entry : staffSummary.entrySet()) {
        String sName = entry.getKey();
        int[] c = entry.getValue();
        // Use JSON-safe key via data attribute - encode for JS string
        String jsKey = sName.replace("\\\\", "\\\\\\\\").replace("\"", "\\\"");
    %>
    STAFF_DATA["<%=jsKey%>"] = {present:<%=c[0]%>,late:<%=c[1]%>,half:<%=c[2]%>,incomplete:<%=c[3]%>,absent:<%=c[4]%>,total:<%=c[5]%>};
    <%
    }
    %>
  </script>
  <!-- Status filter pills -->
  <div class="status-filters" id="statusFilters">
    <span class="pill all active" onclick="filterByStatus('all')">All (<%=mTotal%>)</span>
    <span class="pill present" onclick="filterByStatus('present')">Present (<%=mPresent + mFullDay + mLate%>)</span>
    <span class="pill late"    onclick="filterByStatus('late')">Late (<%=mLate%>)</span>
    <span class="pill half"    onclick="filterByStatus('half_day')">Half Day (<%=mHalf%>)</span>
    <span class="pill incomplete" onclick="filterByStatus('incomplete')">Incomplete (<%=mIncomplete%>)</span>
    <span class="pill absent"  onclick="filterByStatus('absent')">Absent (<%=mAbsent%>)</span>
  </div>
  <div class="table-wrap">
    <table>
      <thead>
        <tr>
          <th>#</th>
          <th>Date</th>
          <th>Staff Name</th>
          <th>Check In</th>
          <th>Break Start</th>
          <th>Break End</th>
          <th>Check Out</th>
          <th>Total Break</th>
          <th>Working Hrs</th>
          <th>Status</th>
        </tr>
      </thead>
      <tbody id="monthlyTbody">
        <%
        if (monthlyList.isEmpty()) {
        %>
        <tr>
          <td colspan="10">
            <div class="empty">
              <i class="fa fa-calendar-xmark"></i>
              <p>No attendance records found for <%=MONTHS[selMonth]%> <%=selYear%>.</p>
            </div>
          </td>
        </tr>
        <%
        } else {
            int idx = 1;
            for (StaffAttendance a : monthlyList) {
                String sc = "badge-absent", st = "Absent";
                String status = a.getStatus() != null ? a.getStatus() : "ABSENT";
                switch (status) {
                    case "PRESENT":    sc="badge-present";    st="Present";    break;
                    case "FULL_DAY":   sc="badge-full";       st="Full Day";   break;
                    case "LATE":       sc="badge-late";        st="Late";       break;
                    case "HALF_DAY":   sc="badge-half";        st="Half Day";   break;
                    case "ABSENT":     sc="badge-absent";      st="Absent";     break;
                    case "INCOMPLETE": sc="badge-incomplete";  st="Incomplete"; break;
                }
                String initials = (a.getEmployeeName() != null && !a.getEmployeeName().isEmpty())
                    ? a.getEmployeeName().substring(0,1).toUpperCase() : "?";
        %>
        <tr data-status="<%=status.toLowerCase()%>">
          <td style="color:var(--muted);font-size:12px;"><%=idx++%></td>
          <td style="font-weight:500;white-space:nowrap;"><%=a.getAttendanceDate()%></td>
          <td>
            <div class="emp-name">
              <div class="emp-avatar"><%=initials%></div>
              <%=a.getEmployeeName() != null ? a.getEmployeeName() : "—"%>
            </div>
          </td>
          <td><%=a.getCheckIn()  != null ? a.getCheckIn().toString().substring(0,5)  : "—"%></td>
          <td><%=a.getBreakIn()  != null ? a.getBreakIn().toString().substring(0,5)  : "—"%></td>
          <td><%=a.getBreakOut() != null ? a.getBreakOut().toString().substring(0,5) : "—"%></td>
          <td><%=a.getCheckOut() != null ? a.getCheckOut().toString().substring(0,5) : "—"%></td>
          <td><%=a.getTotalBreakTime() != null ? a.getTotalBreakTime() : "0:00"%></td>
          <td style="font-weight:600;"><%=a.getWorkingHours() != null ? a.getWorkingHours() : "—"%></td>
          <td><span class="badge <%=sc%>"><%=st%></span></td>
        </tr>
        <%
            }
        }
        %>
      </tbody>
    </table>
  </div>


<!-- ── STAFF DETAIL MODAL ─────────────────────────────────────────────────── -->
<div class="modal-overlay" id="staffModal" onclick="closeModal(event)">
  <div class="modal-box">
    <div class="modal-header">
      <div class="modal-avatar" id="modalAvatar">?</div>
      <div>
        <div class="modal-name" id="modalName">—</div>
        <div class="modal-sub" id="modalSub">Monthly Report</div>
      </div>
      <button class="modal-close" onclick="document.getElementById('staffModal').classList.remove('open')"><i class="fa fa-xmark"></i></button>
    </div>
    <div class="modal-body">
      <!-- Donut ring -->
      <div class="pct-ring-wrap">
        <div class="pct-ring">
          <svg width="120" height="120" viewBox="0 0 120 120">
            <circle cx="60" cy="60" r="50" fill="none" stroke="var(--border)" stroke-width="14"/>
            <circle cx="60" cy="60" r="50" fill="none" stroke="#16a34a" stroke-width="14"
                    stroke-dasharray="314" stroke-dashoffset="314"
                    id="modalRingFill" stroke-linecap="round"/>
          </svg>
          <div class="pct-ring-label">
            <div class="pct-ring-num" id="modalPct">0%</div>
            <div class="pct-ring-txt">Attendance</div>
          </div>
        </div>
        <div class="pct-caption" id="modalCaption">0 of 0 working days present</div>
      </div>
      <!-- Stat grid -->
      <div class="stat-grid">
        <div class="stat-item" style="background:#dcfce7;">
          <div class="stat-dot" style="background:#16a34a;"></div>
          <div class="stat-info">
            <div class="stat-label">Present</div>
            <div class="stat-val" style="color:#15803d;" id="mPresent">0<span class="stat-pct" id="mPresentPct"></span></div>
          </div>
        </div>
        <div class="stat-item" style="background:#fef9c3;">
          <div class="stat-dot" style="background:#f59e0b;"></div>
          <div class="stat-info">
            <div class="stat-label">Late</div>
            <div class="stat-val" style="color:#92400e;" id="mLate">0<span class="stat-pct" id="mLatePct"></span></div>
          </div>
        </div>
        <div class="stat-item" style="background:#dbeafe;">
          <div class="stat-dot" style="background:#2563eb;"></div>
          <div class="stat-info">
            <div class="stat-label">Half Day</div>
            <div class="stat-val" style="color:#1d4ed8;" id="mHalf">0<span class="stat-pct" id="mHalfPct"></span></div>
          </div>
        </div>
        <div class="stat-item" style="background:#fee2e2;">
          <div class="stat-dot" style="background:#ef4444;"></div>
          <div class="stat-info">
            <div class="stat-label">Absent</div>
            <div class="stat-val" style="color:#dc2626;" id="mAbsent">0<span class="stat-pct" id="mAbsentPct"></span></div>
          </div>
        </div>
      </div>
      <!-- Progress bars -->
      <div class="prog-bar-wrap">
        <div class="prog-row">
          <span class="prog-label">Present</span>
          <div class="prog-track"><div class="prog-fill" id="barPresent" style="background:#16a34a;width:0%"></div></div>
          <span class="prog-count" id="barPresentN">0</span>
        </div>
        <div class="prog-row">
          <span class="prog-label">Late</span>
          <div class="prog-track"><div class="prog-fill" id="barLate" style="background:#f59e0b;width:0%"></div></div>
          <span class="prog-count" id="barLateN">0</span>
        </div>
        <div class="prog-row">
          <span class="prog-label">Half Day</span>
          <div class="prog-track"><div class="prog-fill" id="barHalf" style="background:#2563eb;width:0%"></div></div>
          <span class="prog-count" id="barHalfN">0</span>
        </div>
        <div class="prog-row">
          <span class="prog-label">Incomplete</span>
          <div class="prog-track"><div class="prog-fill" id="barIncomplete" style="background:#8b5cf6;width:0%"></div></div>
          <span class="prog-count" id="barIncompleteN">0</span>
        </div>
        <div class="prog-row">
          <span class="prog-label">Absent</span>
          <div class="prog-track"><div class="prog-fill" id="barAbsent" style="background:#ef4444;width:0%"></div></div>
          <span class="prog-count" id="barAbsentN">0</span>
        </div>
      </div>
    </div>
  </div>
</div>

</div><!-- /content -->

<script>

// ── Status filter pills ───────────────────────────────────────────────────────
function filterByStatus(status) {
  // Update active pill
  document.querySelectorAll('#statusFilters .pill').forEach(p => p.classList.remove('active'));
  event.currentTarget.classList.add('active');

  // Respect search input too
  const q = (document.getElementById('monthlySearch').value || '').toLowerCase().trim();
  const rows = document.getElementById('monthlyTbody').querySelectorAll('tr');
  rows.forEach(row => {
    const nameMatch = q === '' || row.textContent.toLowerCase().includes(q);
    const rowStatus = row.getAttribute('data-status') || '';
    let statusMatch = status === 'all';
    if (!statusMatch) {
      if (status === 'present') statusMatch = rowStatus === 'present' || rowStatus === 'full_day' || rowStatus === 'late';
      else statusMatch = rowStatus === status;
    }
    row.style.display = (nameMatch && statusMatch) ? '' : 'none';
  });
}


// ── Staff detail popup modal ─────────────────────────────────────────────────
function openStaffModal(name) {
  if (!name) return;
  const d = STAFF_DATA[name];
  if (!d) { console.warn('No data for:', name, STAFF_DATA); return; }

  const total   = d.total || 1;
  const attended = d.present + d.late;
  const pct     = Math.round(attended * 100 / total);

  // Header
  document.getElementById('modalAvatar').textContent = name.charAt(0).toUpperCase();
  document.getElementById('modalName').textContent   = name;
  document.getElementById('modalSub').textContent    = 'Monthly Attendance Report';

  // Ring (circumference ≈ 314)
  const circ  = 314;
  const color = pct >= 80 ? '#16a34a' : pct >= 60 ? '#f59e0b' : '#ef4444';
  const ring  = document.getElementById('modalRingFill');
  ring.setAttribute('stroke-dashoffset', circ - (circ * pct / 100));
  ring.setAttribute('stroke', color);
  document.getElementById('modalPct').textContent      = pct + '%';
  document.getElementById('modalPct').style.color      = color;
  document.getElementById('modalCaption').textContent  = attended + ' of ' + total + ' working days attended';

  // Stat boxes
  function setBox(valId, pctId, val) {
    document.getElementById(valId).firstChild.textContent = val;
    document.getElementById(pctId).textContent = ' (' + Math.round(val * 100 / total) + '%)';
  }
  setBox('mPresent',  'mPresentPct',  d.present);
  setBox('mLate',     'mLatePct',     d.late);
  setBox('mHalf',     'mHalfPct',     d.half);
  setBox('mAbsent',   'mAbsentPct',   d.absent);

  // Progress bars
  function setBar(barId, numId, val) {
    document.getElementById(barId).style.width = Math.round(val * 100 / total) + '%';
    document.getElementById(numId).textContent = val;
  }
  setBar('barPresent',    'barPresentN',    d.present);
  setBar('barLate',       'barLateN',       d.late);
  setBar('barHalf',       'barHalfN',       d.half);
  setBar('barIncomplete', 'barIncompleteN', d.incomplete);
  setBar('barAbsent',     'barAbsentN',     d.absent);

  document.getElementById('staffModal').classList.add('open');
}
function closeModal(e) {
  if (e.target.id === 'staffModal')
    document.getElementById('staffModal').classList.remove('open');
}
function filterByStaff(name, el) { openStaffModal(name); }

// ── Today filter pills ────────────────────────────────────────────────────────
function filterToday(status, el) {
  document.querySelectorAll('#todayFilters .pill').forEach(p => p.classList.remove('active'));
  el.classList.add('active');
  const q = (document.getElementById('todaySearch').value || '').toLowerCase().trim();
  const rows = document.getElementById('todayTbody').querySelectorAll('tr');
  rows.forEach(row => {
    const nameMatch = q === '' || row.textContent.toLowerCase().includes(q);
    const rowStatus = row.getAttribute('data-today-status') || '';
    let statusMatch = status === 'all';
    if (!statusMatch) {
      if (status === 'present') statusMatch = rowStatus === 'present' || rowStatus === 'full_day' || rowStatus === 'late';
      else statusMatch = rowStatus === status;
    }
    row.style.display = (nameMatch && statusMatch) ? '' : 'none';
  });
}
// ── Monthly search by employee name ──────────────────────────────────────────
function filterMonthly(query) {
  const q = query.toLowerCase().trim();
  const activePill = document.querySelector('#statusFilters .pill.active');
  const activeStatus = activePill ? activePill.getAttribute('onclick').match(/'([^']+)'/)[1] : 'all';
  const rows = document.getElementById('monthlyTbody').querySelectorAll('tr');
  rows.forEach(row => {
    const nameMatch = q === '' || row.textContent.toLowerCase().includes(q);
    const rowStatus = row.getAttribute('data-status') || '';
    let statusMatch = activeStatus === 'all';
    if (!statusMatch) {
      if (activeStatus === 'present') statusMatch = rowStatus === 'present' || rowStatus === 'full_day' || rowStatus === 'late';
      else statusMatch = rowStatus === activeStatus;
    }
    row.style.display = (nameMatch && statusMatch) ? '' : 'none';
  });
}
// ── Live search ──────────────────────────────────────────────────────────────
function filterTable(tbodyId, query) {
  const q = query.toLowerCase().trim();
  const rows = document.getElementById(tbodyId).querySelectorAll('tr');
  if (tbodyId === 'todayTbody') {
    const activePill = document.querySelector('#todayFilters .pill.active');
    const activeStatus = activePill ? activePill.getAttribute('onclick').match(/'([^']+)'/)[1] : 'all';
    rows.forEach(row => {
      const nameMatch = q === '' || row.textContent.toLowerCase().includes(q);
      const rowStatus = row.getAttribute('data-today-status') || '';
      let statusMatch = activeStatus === 'all';
      if (!statusMatch) {
        if (activeStatus === 'present') statusMatch = rowStatus === 'present' || rowStatus === 'full_day' || rowStatus === 'late';
        else statusMatch = rowStatus === activeStatus;
      }
      row.style.display = (nameMatch && statusMatch) ? '' : 'none';
    });
  } else {
    rows.forEach(row => {
      row.style.display = q === '' || row.textContent.toLowerCase().includes(q) ? '' : 'none';
    });
  }
}

// ── Dark mode ────────────────────────────────────────────────────────────────
function toggleDark() {
  const h = document.documentElement;
  const d = h.getAttribute('data-theme') === 'dark';
  h.setAttribute('data-theme', d ? 'light' : 'dark');
  localStorage.setItem('sibs-theme', d ? 'light' : 'dark');
}
(function(){ const t = localStorage.getItem('sibs-theme'); if(t) document.documentElement.setAttribute('data-theme',t); })();

// ── Dropdown ─────────────────────────────────────────────────────────────────
function toggleDropdown(){ document.getElementById('profileDrop').classList.toggle('open'); }
document.addEventListener('click', e => {
  if (!e.target.closest('.dropdown')) document.getElementById('profileDrop').classList.remove('open');
});
</script>
</body>
</html>
