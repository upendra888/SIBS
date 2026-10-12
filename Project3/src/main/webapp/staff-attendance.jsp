<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="com.sibs.model.User, com.sibs.model.StaffAttendance, com.sibs.dao.StaffAttendanceDAO, java.util.List" %>
<%
User user = (User) session.getAttribute("user");
if (user == null || !"STAFF".equals(user.getRole())) {
    response.sendRedirect("login.jsp");
    return;
}

StaffAttendanceDAO dao    = new StaffAttendanceDAO();
dao.autoPunchOut();
StaffAttendance today     = dao.getTodayRecord(user.getId());
List<StaffAttendance> history = dao.getMyHistoryFrom(user.getId(), "2026-05-11");

boolean canCheckIn   = (today == null);
boolean canBreakIn   = (today != null && today.isCheckedIn()  && !today.isOnBreak() && !today.isCheckedOut() && !today.isBreakLimitReached());
boolean canBreakOut  = (today != null && today.isOnBreak());
boolean canCheckOut  = (today != null && today.isCheckedIn()  && !today.isOnBreak() && !today.isCheckedOut());

// Pass time as plain "HH:MM:SS" strings — avoids timezone bugs with getTime()
String checkInStr = (today != null && today.getCheckIn()  != null) ? today.getCheckIn().toString()  : "";
String breakInStr = (today != null && today.getBreakIn()  != null && today.getBreakOut() == null)
                    ? today.getBreakIn().toString() : "";

int breakCount  = (today != null) ? today.getBreakCount() : 0;
int breaksLeft  = Math.max(0, 2 - breakCount);
%>
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>My Attendance — SIBS</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<style>
:root{--bg:#f8fafc;--surface:#fff;--border:#e2e8f0;--text:#0f172a;--muted:#64748b;--primary:#2563eb;--success:#16a34a;--danger:#ef4444;--warn:#f59e0b;--sidebar:#0f172a;--sidebar-text:#cbd5e1;--sidebar-hover:#1e293b;}
[data-theme="dark"]{--bg:#0f172a;--surface:#1e293b;--border:#334155;--text:#f1f5f9;--muted:#94a3b8;--sidebar:#020617;--sidebar-hover:#0f172a;}
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
.topbar{margin-left:240px;height:62px;background:var(--surface);border-bottom:1px solid var(--border);display:flex;align-items:center;justify-content:space-between;padding:0 24px;position:sticky;top:0;z-index:100;box-shadow:0 1px 3px rgba(0,0,0,.06);}
.topbar-left{font-weight:600;font-size:15px;}
.topbar-right{display:flex;align-items:center;gap:12px;}
.dark-btn{background:none;border:1px solid var(--border);width:34px;height:34px;border-radius:8px;cursor:pointer;color:var(--muted);}
.profile-pill{display:flex;align-items:center;gap:8px;cursor:pointer;padding:6px 10px;border-radius:8px;border:1px solid var(--border);}
.avatar{width:30px;height:30px;border-radius:50%;background:#f97316;display:flex;align-items:center;justify-content:center;color:#fff;font-weight:700;font-size:12px;}
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
.content{margin-left:240px;padding:28px 24px;}
.page-title{font-size:20px;font-weight:700;margin-bottom:4px;}
.page-sub{font-size:13px;color:var(--muted);margin-bottom:24px;}

/* ── TODAY CARD ── */
.today-card{background:var(--surface);border:1px solid var(--border);border-radius:14px;padding:24px;box-shadow:0 1px 4px rgba(0,0,0,.06);}
.today-header{display:flex;align-items:center;justify-content:space-between;margin-bottom:20px;flex-wrap:wrap;gap:12px;}
.today-date{font-size:13px;color:var(--muted);display:flex;align-items:center;gap:6px;}
.status-badge{padding:4px 14px;border-radius:99px;font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:.4px;}
.badge-present{background:#dcfce7;color:#15803d;}
.badge-late   {background:#fef9c3;color:#92400e;}
.badge-half   {background:#dbeafe;color:#1d4ed8;}
.badge-absent {background:#fee2e2;color:#dc2626;}
.badge-incomplete{background:#ede9fe;color:#6d28d9;}
.badge-none   {background:var(--bg);color:var(--muted);}

/* ── LIVE TIMER BOXES ── */
.timeline{display:grid;grid-template-columns:repeat(auto-fit,minmax(140px,1fr));gap:12px;margin-bottom:20px;}
.tl-box{background:var(--bg);border:1px solid var(--border);border-radius:10px;padding:14px;text-align:center;position:relative;}
.tl-label{font-size:11px;color:var(--muted);text-transform:uppercase;letter-spacing:.4px;margin-bottom:6px;}
.tl-value{font-size:18px;font-weight:700;}
.tl-value.green{color:#16a34a;}
.tl-value.orange{color:#f97316;}
.tl-value.primary{color:#2563eb;}
.tl-value.muted{color:var(--muted);font-size:14px;font-weight:400;}
.tl-sub{font-size:11px;color:var(--muted);margin-top:4px;min-height:16px;}
.tl-sub.live{color:#f97316;font-weight:600;}
.tl-sub.live-blue{color:#2563eb;font-weight:600;}
/* Pulse ring when timer is running */
@keyframes pulseRing{0%{transform:scale(1);opacity:.6}50%{transform:scale(1.15);opacity:.2}100%{transform:scale(1);opacity:.6}}
.tl-pulse{position:absolute;top:10px;right:10px;width:8px;height:8px;border-radius:50%;background:#f97316;animation:pulseRing 1.4s ease-in-out infinite;}
.tl-pulse.blue{background:#2563eb;}

/* ── BREAK COUNTER PILL ── */
.break-counter{display:flex;align-items:center;gap:10px;margin-bottom:16px;padding:10px 16px;background:var(--bg);border:1px solid var(--border);border-radius:10px;font-size:13px;}
.break-dots{display:flex;gap:6px;}
.break-dot{width:14px;height:14px;border-radius:50%;border:2px solid var(--border);}
.break-dot.used{background:#f59e0b;border-color:#d97706;}
.break-dot.available{background:var(--bg);border-color:#cbd5e1;}
.break-dot.on-break{background:#2563eb;border-color:#1d4ed8;animation:pulseRing 1.4s ease-in-out infinite;}

/* ── ACTION BUTTONS ── */
.btn-row{display:flex;gap:12px;flex-wrap:wrap;}
.att-btn{padding:12px 24px;border:none;border-radius:10px;font-size:14px;font-weight:600;cursor:pointer;display:flex;align-items:center;gap:8px;transition:.15s;}
.att-btn:disabled{opacity:.4;cursor:not-allowed;}
.btn-checkin {background:#16a34a;color:#fff;}
.btn-checkin:hover:not(:disabled){background:#15803d;}
.btn-breakin {background:#f59e0b;color:#fff;}
.btn-breakin:hover:not(:disabled){background:#d97706;}
.btn-breakout{background:#2563eb;color:#fff;}
.btn-breakout:hover:not(:disabled){background:#1d4ed8;}
.btn-checkout{background:#ef4444;color:#fff;}
.btn-checkout:hover:not(:disabled){background:#dc2626;}

/* ── TOAST ── */
#toast{position:fixed;bottom:24px;right:24px;padding:12px 20px;border-radius:10px;font-size:13px;font-weight:600;color:#fff;box-shadow:0 4px 14px rgba(0,0,0,.2);z-index:9999;display:none;max-width:320px;}
#toast.success{background:#16a34a;}
#toast.error  {background:#ef4444;}

/* ── HISTORY TABLE ── */
.table-wrap{overflow-x:auto;border-radius:12px;border:1px solid var(--border);}
table{width:100%;border-collapse:collapse;font-size:13px;}
thead tr{background:var(--bg);}
th{padding:12px 14px;text-align:left;font-weight:600;color:var(--muted);font-size:11px;text-transform:uppercase;letter-spacing:.4px;border-bottom:1px solid var(--border);}
td{padding:11px 14px;border-bottom:1px solid var(--border);color:var(--text);}
tr:last-child td{border-bottom:none;}
tr:hover td{background:var(--bg);}
.section-title{font-size:15px;font-weight:600;margin-bottom:14px;margin-top:28px;display:flex;align-items:center;gap:8px;}

/* ── LIVE CLOCK ── */
#live-clock{font-size:14px;font-weight:600;color:var(--primary);}
</style>
</head>
<body>

<!-- ── SIDEBAR ── -->
<div class="sidebar">
  <div class="sidebar-logo"><i class="fa fa-cubes"></i><span>SIBS Staff</span></div>
  <nav>
    <a class="nav-item" href="staff-dashboard.jsp"><i class="fa fa-gauge-high"></i> Dashboard</a>
    <a class="nav-item" href="products.jsp"><i class="fa fa-box"></i> Products</a>
    <a class="nav-item" href="staff-orders.jsp"><i class="fa fa-shopping-bag"></i> Orders</a>
    <a class="nav-item" href="manage-delivery-boys.jsp"><i class="fa fa-motorcycle"></i> Delivery Boys</a>
    <a class="nav-item active" href="staff-attendance.jsp"><i class="fa fa-clock"></i> My Attendance</a>
    <a class="nav-item" href="AdminReturnServlet?action=list"><i class="fa fa-rotate-left"></i> Manage Returns</a>
    <a class="nav-item" href="staff-cancelled-orders.jsp"><i class="fa fa-ban"></i> Cancelled Orders</a>
    <a class="nav-item" href="admin-cod-ledger.jsp"><i class="fa fa-money-bill-wave"></i> COD Remittance</a>
  </nav>
  <div class="sidebar-footer">
    <a class="nav-item" href="logout" style="padding:0;color:#94a3b8;"><i class="fa fa-sign-out-alt"></i> Logout</a>
  </div>
</div>

<!-- ── TOPBAR ── -->
<div class="topbar">
  <span class="topbar-left"><span id="live-clock">--:--:--</span></span>
  <div class="topbar-right">
    <button class="dark-btn" onclick="toggleDark()"><i class="fa fa-moon"></i></button>
    <%@ include file="/includes/staffNotificationBell.jsp" %>
      <div class="profile-pill" onclick="toggleDropdown()">
        <div class="avatar"><%=user.getUsername().substring(0,1).toUpperCase()%></div>
        <div>
          <div class="profile-name"><%=user.getUsername()%></div>
          <div class="profile-role">Staff</div>
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

<!-- ── CONTENT ── -->
<div class="content">
  <div class="page-title">My Attendance</div>
  <div class="page-sub">Track your daily check-in, breaks, and check-out.</div>

  <!-- TODAY CARD -->
  <div class="today-card">
    <div class="today-header">
      <div>
        <div style="font-size:16px;font-weight:700;margin-bottom:4px;">Today's Record</div>
        <div class="today-date">
          <i class="fa fa-calendar-day"></i>
          <span id="today-date-str"></span>
        </div>
      </div>
      <div>
        <%
          String statusClass = "badge-none", statusText = "Not Checked In";
          if (today != null) {
              switch (today.getStatus()) {
                  case "PRESENT":    statusClass = "badge-present";    statusText = "Present";    break;
                  case "LATE":       statusClass = "badge-late";        statusText = "Late";        break;
                  case "HALF_DAY":   statusClass = "badge-half";        statusText = "Half Day";    break;
                  case "ABSENT":     statusClass = "badge-absent";      statusText = "Absent";      break;
                  case "INCOMPLETE": statusClass = "badge-incomplete";  statusText = "Incomplete";  break;
                  default:           statusClass = "badge-none";        statusText = today.getStatus();
              }
          }
        %>
        <span class="status-badge <%=statusClass%>"><%=statusText%></span>
      </div>
    </div>

    <!-- Timeline boxes with live timers -->
    <div class="timeline">

      <!-- Check In -->
      <div class="tl-box">
        <% if (!checkInStr.isEmpty() && today != null && !today.isCheckedOut()) { %>
          <div class="tl-pulse"></div>
        <% } %>
        <div class="tl-label"><i class="fa fa-sign-in-alt"></i> Check In</div>
        <div class="tl-value green">
          <%=(today != null && today.getCheckIn() != null) ? today.getCheckIn().toString().substring(0,5) : "&mdash;"%>
        </div>
        <div class="tl-sub live" id="checkin-elapsed"></div>
      </div>

      <!-- Break Start -->
      <div class="tl-box">
        <div class="tl-label"><i class="fa fa-coffee"></i> Break Start</div>
        <div class="tl-value orange">
          <%=(today != null && today.getBreakIn() != null) ? today.getBreakIn().toString().substring(0,5) : "&mdash;"%>
        </div>
        <div class="tl-sub" id="break-elapsed">
          <% if (today != null && today.isOnBreak()) { %><span style="color:#2563eb;font-weight:600;">On Break</span><% } %>
        </div>
      </div>

      <!-- Break End -->
      <div class="tl-box">
        <div class="tl-label"><i class="fa fa-play"></i> Break End</div>
        <div class="tl-value primary">
          <%=(today != null && today.getBreakOut() != null) ? today.getBreakOut().toString().substring(0,5) : "&mdash;"%>
        </div>
        <div class="tl-sub"></div>
      </div>

      <!-- Check Out -->
      <div class="tl-box">
        <div class="tl-label"><i class="fa fa-sign-out-alt"></i> Check Out</div>
        <div class="tl-value" style="color:var(--danger);">
          <%=(today != null && today.getCheckOut() != null) ? today.getCheckOut().toString().substring(0,5) : "&mdash;"%>
        </div>
        <div class="tl-sub"></div>
      </div>

      <!-- Total Break -->
      <div class="tl-box">
        <div class="tl-label"><i class="fa fa-mug-hot"></i> Total Break</div>
        <div class="tl-value orange" id="total-break-display">
          <%=(today != null && today.getTotalBreakTime() != null) ? today.getTotalBreakTime() : "0:00"%>
        </div>
        <div class="tl-sub"></div>
      </div>

      <!-- Working Hrs -->
      <div class="tl-box">
        <% if (!checkInStr.isEmpty() && today != null && !today.isCheckedOut()) { %>
          <div class="tl-pulse"></div>
        <% } %>
        <div class="tl-label"><i class="fa fa-business-time"></i> Working Hrs</div>
        <div class="tl-value green" id="working-hrs-display">
          <%=(today != null && today.getWorkingHours() != null) ? today.getWorkingHours() : "&mdash;"%>
        </div>
        <div class="tl-sub live" id="working-live"></div>
      </div>

    </div>

    <!-- Break Counter -->
    <% if (today != null && today.isCheckedIn() && !today.isCheckedOut()) { %>
    <div class="break-counter">
      <i class="fa fa-mug-hot" style="color:#f59e0b;"></i>
      <span style="font-weight:600;">Breaks today:</span>
      <div class="break-dots">
        <% for (int i = 0; i < 2; i++) {
             String dotClass;
             if (i < breakCount && today.isOnBreak() && i == breakCount - 1) dotClass = "break-dot on-break";
             else if (i < breakCount) dotClass = "break-dot used";
             else dotClass = "break-dot available";
        %>
          <div class="<%=dotClass%>" title="Break <%=(i+1)%>"></div>
        <% } %>
      </div>
      <% if (today.isBreakLimitReached()) { %>
        <span style="color:#ef4444;font-size:12px;font-weight:600;margin-left:4px;">
          <i class="fa fa-lock"></i> Limit reached (2/2)
        </span>
      <% } else { %>
        <span style="color:var(--muted);font-size:12px;"><%=breaksLeft%> break<%=breaksLeft!=1?"s":""%> remaining</span>
      <% } %>
    </div>
    <% } %>

    <!-- Action Buttons -->
    <div class="btn-row">
      <button class="att-btn btn-checkin"
              <%=canCheckIn  ? "" : "disabled title=\"Already checked in today\""%>
              onclick="doAction('checkIn')">
        <i class="fa fa-sign-in-alt"></i> Check In
      </button>
      <button class="att-btn btn-breakin"
              <%=canBreakIn  ? "" : "disabled title=\"" + (today != null && today.isBreakLimitReached() ? "Break limit reached (2/2)" : "Check in first, already on break, or checked out") + "\""%>
              onclick="doAction('breakIn')">
        <i class="fa fa-coffee"></i> Start Break
      </button>
      <button class="att-btn btn-breakout"
              <%=canBreakOut ? "" : "disabled title=\"No active break to end\""%>
              onclick="doAction('breakOut')">
        <i class="fa fa-play"></i> End Break
      </button>
      <button class="att-btn btn-checkout"
              <%=canCheckOut ? "" : "disabled title=\"Check in first, end your break, or already checked out\""%>
              onclick="doAction('checkOut')">
        <i class="fa fa-sign-out-alt"></i> Check Out
      </button>
    </div>

    <% if (today != null && today.isOnBreak()) { %>
    <div style="margin-top:14px;font-size:12px;color:var(--warn);display:flex;align-items:center;gap:6px;">
      <i class="fa fa-triangle-exclamation"></i>
      You are currently on a break. Please end your break before checking out.
    </div>
    <% } %>
    <% if (today != null && today.isBreakLimitReached() && !today.isOnBreak() && !today.isCheckedOut()) { %>
    <div style="margin-top:14px;font-size:12px;color:#ef4444;display:flex;align-items:center;gap:6px;">
      <i class="fa fa-lock"></i>
      You have used all 2 allowed breaks for today. No further breaks can be started.
    </div>
    <% } %>
  </div>

  <!-- HISTORY TABLE -->
  <div class="section-title" style="margin-top:32px;">
    <i class="fa fa-history" style="color:#f97316;"></i>
    History from 11 May 2026
  </div>

  <div class="table-wrap">
    <table>
      <thead>
        <tr>
          <th>Date</th>
          <th>Check In</th>
          <th>Break Start</th>
          <th>Break End</th>
          <th>Check Out</th>
          <th>Break Time</th>
          <th>Breaks</th>
          <th>Working Hrs</th>
          <th>Status</th>
        </tr>
      </thead>
      <tbody>
        <% if (history.isEmpty()) { %>
        <tr>
          <td colspan="9" style="text-align:center;color:var(--muted);padding:30px;">
            No attendance records found.
          </td>
        </tr>
        <% } else {
          for (StaffAttendance a : history) {
            String sc = "badge-none", st = a.getStatus() != null ? a.getStatus() : "&mdash;";
            if      ("PRESENT".equals(a.getStatus()))    { sc="badge-present";    st="Present"; }
            else if ("LATE".equals(a.getStatus()))       { sc="badge-late";       st="Late"; }
            else if ("HALF_DAY".equals(a.getStatus()))   { sc="badge-half";       st="Half Day"; }
            else if ("ABSENT".equals(a.getStatus()))     { sc="badge-absent";     st="Absent"; }
            else if ("INCOMPLETE".equals(a.getStatus())) { sc="badge-incomplete"; st="Incomplete"; }
        %>
        <tr>
          <td style="font-weight:500;"><%=a.getAttendanceDate()%></td>
          <td><%=a.getCheckIn()  != null ? a.getCheckIn().toString().substring(0,5)  : "&mdash;"%></td>
          <td><%=a.getBreakIn()  != null ? a.getBreakIn().toString().substring(0,5)  : "&mdash;"%></td>
          <td><%=a.getBreakOut() != null ? a.getBreakOut().toString().substring(0,5) : "&mdash;"%></td>
          <td><%=a.getCheckOut() != null ? a.getCheckOut().toString().substring(0,5) : "&mdash;"%></td>
          <td><%=a.getTotalBreakTime() != null ? a.getTotalBreakTime() : "0:00"%></td>
          <td style="text-align:center;">
            <% if (a.getCheckIn() != null) { %>
              <span style="font-size:12px;background:var(--bg);padding:2px 8px;border-radius:99px;border:1px solid var(--border);">
                <%=a.getBreakCount()%>/2
              </span>
            <% } else { %>
              &mdash;
            <% } %>
          </td>
          <td style="font-weight:600;"><%=a.getWorkingHours() != null ? a.getWorkingHours() : "&mdash;"%></td>
          <td><span class="status-badge <%=sc%>"><%=st%></span></td>
        </tr>
        <% } } %>
      </tbody>
    </table>
  </div>
</div>

<!-- TOAST -->
<div id="toast"></div>

<script>
// ── Server-side time strings (HH:MM:SS) — no timezone issues ──
const CHECK_IN_STR   = '<%=checkInStr%>';    // e.g. "09:04:00" or ""
const BREAK_IN_STR   = '<%=breakInStr%>';    // e.g. "09:24:00" or "" (only if on active break)
const IS_CHECKED_OUT = <%=(today != null && today.isCheckedOut()) ? "true" : "false"%>;

// Parse "HH:MM:SS" into today's epoch ms using the browser's local clock
function timeStrToEpoch(str) {
  if (!str) return -1;
  const parts = str.split(':');
  const h = parseInt(parts[0]||0), m = parseInt(parts[1]||0), s = parseInt(parts[2]||0);
  const now = new Date();
  return new Date(now.getFullYear(), now.getMonth(), now.getDate(), h, m, s, 0).getTime();
}

const checkInEpoch = timeStrToEpoch(CHECK_IN_STR);
const breakInEpoch = timeStrToEpoch(BREAK_IN_STR);

// Stored total_break_time already in DB (seconds) — excludes current ongoing break
const STORED_BREAK_SEC = (function() {
  const raw = '<%=(today != null && today.getTotalBreakTime() != null) ? today.getTotalBreakTime() : "0:00"%>';
  const parts = raw.split(':');
  return parseInt(parts[0]||0)*3600 + parseInt(parts[1]||0)*60 + parseInt(parts[2]||0);
})();

// ── Helpers ──
function fmtHMS(sec) {
  sec = Math.max(0, Math.floor(sec));
  const h = Math.floor(sec / 3600);
  const m = Math.floor((sec % 3600) / 60);
  const s = sec % 60;
  if (h > 0) return h + 'h ' + String(m).padStart(2,'0') + 'm ' + String(s).padStart(2,'0') + 's';
  return String(m).padStart(2,'0') + 'm ' + String(s).padStart(2,'0') + 's';
}

function fmtHM(sec) {
  sec = Math.max(0, Math.floor(sec));
  const h = Math.floor(sec / 3600);
  const m = Math.floor((sec % 3600) / 60);
  return h + ':' + String(m).padStart(2,'0');
}

// ── Live clock ──
function tick() {
  const now = new Date();
  document.getElementById('live-clock').textContent = now.toLocaleTimeString();
  document.getElementById('today-date-str').textContent = now.toLocaleDateString('en-IN',
    {weekday:'long', year:'numeric', month:'long', day:'numeric'});

  if (!IS_CHECKED_OUT && checkInEpoch > 0) {
    const nowMs  = Date.now();
    const totalElapsed = (nowMs - checkInEpoch) / 1000; // seconds since check-in

    // Current break duration (if on break right now)
    const currentBreakSec = (breakInEpoch > 0) ? (nowMs - breakInEpoch) / 1000 : 0;

    // Net working seconds = total elapsed - all break time
    const totalBreakSec = STORED_BREAK_SEC + currentBreakSec;
    const workSec = Math.max(0, totalElapsed - totalBreakSec);

    // Check-in elapsed
    const ciEl = document.getElementById('checkin-elapsed');
    if (ciEl) ciEl.textContent = 'Working ' + fmtHMS(workSec);

    // Working hours live
    const whEl = document.getElementById('working-live');
    if (whEl) whEl.textContent = fmtHM(workSec);

    // If on break: show break timer + update total break display
    const brEl = document.getElementById('break-elapsed');
    const tbEl = document.getElementById('total-break-display');
    if (breakInEpoch > 0) {
      if (brEl) brEl.innerHTML = '<span style="color:#2563eb;font-weight:600;">⏱ ' + fmtHMS(currentBreakSec) + '</span>';
      if (tbEl) tbEl.textContent = fmtHM(totalBreakSec);
    }
  }
}
tick(); setInterval(tick, 1000);

// ── Attendance action ──
function doAction(action) {
  fetch('staffAttendance?action=' + action, {method:'POST'})
    .then(r => r.json())
    .then(data => {
      if (data.ok) {
        showToast(data.message, 'success');
        setTimeout(() => location.reload(), 1200);
      } else {
        showToast(data.error || 'Action failed. Please refresh and try again.', 'error');
      }
    })
    .catch(() => showToast('Network error. Please try again.', 'error'));
}

// ── Toast helper ──
function showToast(msg, type) {
  const t = document.getElementById('toast');
  t.textContent = msg;
  t.className   = type;
  t.style.display = 'block';
  clearTimeout(t._timer);
  t._timer = setTimeout(() => { t.style.display='none'; }, 4000);
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
</script>
</body>
</html>
