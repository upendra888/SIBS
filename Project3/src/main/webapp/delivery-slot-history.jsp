<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.util.*,com.sibs.dao.DeliverySlotDAO,com.sibs.model.DeliverySlot,com.sibs.model.DeliveryBoy,com.sibs.dao.DeliveryBoyDAO,java.sql.*" %>
<%
DeliveryBoy db = (DeliveryBoy) session.getAttribute("deliveryBoy");
if (db == null) { response.sendRedirect("delivery-login.jsp"); return; }

DeliveryBoyDAO dbDao = new DeliveryBoyDAO();
DeliveryBoy dbFresh  = dbDao.getById(db.getId());
if (dbFresh == null) { response.sendRedirect("delivery-login.jsp"); return; }
session.setAttribute("deliveryBoy", dbFresh);

// ── Load booking history directly via SQL ──────────────────────────────
List<DeliverySlot> history = new ArrayList<>();
try (Connection con = com.sibs.util.DBConnection.getConnection();
     PreparedStatement ps = con.prepareStatement(
         "SELECT ds.slot_id, ds.slot_name, ds.start_time, ds.end_time, " +
         "       ds.max_capacity, ds.is_active, 0 AS booked_count, " +
         "       b.booking_id, b.delivery_boy_id, b.booking_date, " +
         "       b.status, b.shift_start, b.shift_end, b.working_hours " +
         "FROM   delivery_slot_bookings b " +
         "JOIN   delivery_slots ds ON ds.slot_id = b.slot_id " +
         "WHERE  b.delivery_boy_id = ? " +
         "ORDER  BY b.booking_date DESC, ds.start_time DESC " +
         "LIMIT 100")) {
    ps.setInt(1, db.getId());
    ResultSet rs = ps.executeQuery();
    while (rs.next()) {
        DeliverySlot s = new DeliverySlot();
        s.setSlotId(rs.getInt("slot_id"));
        s.setSlotName(rs.getString("slot_name"));
        s.setStartTime(rs.getTime("start_time"));
        s.setEndTime(rs.getTime("end_time"));
        s.setMaxCapacity(rs.getInt("max_capacity"));
        s.setBookingId(rs.getInt("booking_id"));
        s.setDeliveryBoyId(rs.getInt("delivery_boy_id"));
        s.setBookingDate(rs.getDate("booking_date"));
        s.setStatus(rs.getString("status"));
        s.setShiftStart(rs.getTime("shift_start"));
        s.setShiftEnd(rs.getTime("shift_end"));
        s.setWorkingHours(rs.getString("working_hours"));
        history.add(s);
    }
} catch (Exception e) { e.printStackTrace(); }

// ── Summary counts ─────────────────────────────────────────────────────
int totalShifts    = 0, completedShifts = 0, cancelledShifts = 0;
String totalHours  = "0:00";
int totalMinutes   = 0;
for (DeliverySlot s : history) {
    totalShifts++;
    if (s.isCompleted()) {
        completedShifts++;
        if (s.getWorkingHours() != null && s.getWorkingHours().contains(":")) {
            try {
                String[] p = s.getWorkingHours().split(":");
                totalMinutes += Integer.parseInt(p[0]) * 60 + Integer.parseInt(p[1]);
            } catch (Exception ignored) {}
        }
    }
    if (s.isCancelled()) cancelledShifts++;
}
totalHours = (totalMinutes / 60) + "h " + String.format("%02d", totalMinutes % 60) + "m";

// ── Filter by month ─────────────────────────────────────────────────────
String filterMonth = request.getParameter("month"); // format: "2026-05"
List<DeliverySlot> filtered = new ArrayList<>();
for (DeliverySlot s : history) {
    if (filterMonth == null || filterMonth.isEmpty()) {
        filtered.add(s);
    } else if (s.getBookingDate() != null &&
               s.getBookingDate().toString().startsWith(filterMonth)) {
        filtered.add(s);
    }
}

String initials = dbFresh.getName().length() >= 2
    ? dbFresh.getName().substring(0, 2).toUpperCase()
    : dbFresh.getName().toUpperCase();
%>
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1">
<title>Slot History · SIBS</title>
<link href="https://fonts.googleapis.com/css2?family=Syne:wght@400;600;700;800&family=DM+Sans:wght@300;400;500;600&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<style>
:root{
  --brand:#7c3aed;--brand-light:#ede9fe;
  --surface:#fff;--bg:#f3f1fb;--bg2:#edeaf8;
  --text:#0d0d14;--muted:#6b6882;--border:rgba(124,58,237,.12);
  --green:#16a34a;--green-bg:#dcfce7;
  --amber:#b45309;--amber-bg:#fef3c7;
  --red:#dc2626;--red-bg:#fee2e2;
  --blue:#1d4ed8;--blue-bg:#eff6ff;
  --radius:14px;--radius-sm:9px;
  --ff-head:'Syne',sans-serif;--ff-body:'DM Sans',sans-serif;
  --shadow:0 2px 16px rgba(124,58,237,.10);
}
[data-theme="dark"]{
  --brand:#a78bfa;--brand-light:#2e1f5e;
  --surface:#13111f;--bg:#0d0b18;--bg2:#1a1730;
  --text:#f0eeff;--muted:#9791b8;--border:rgba(167,139,250,.14);
  --green:#4ade80;--green-bg:#052e16;
  --amber:#fcd34d;--amber-bg:#451a03;
  --red:#f87171;--red-bg:#450a0a;
  --blue:#93c5fd;--blue-bg:#0c1a3d;
  --shadow:0 2px 20px rgba(0,0,0,.4);
}
*,*::before,*::after{margin:0;padding:0;box-sizing:border-box;}
html{font-family:var(--ff-body);font-size:15px;color:var(--text);background:var(--bg);}
body{min-height:100vh;padding-bottom:90px;}
a{text-decoration:none;color:inherit;}

/* TOPBAR */
.topbar{background:var(--surface);border-bottom:1px solid var(--border);
  padding:0 18px;height:60px;display:flex;align-items:center;
  justify-content:space-between;position:sticky;top:0;z-index:200;box-shadow:var(--shadow);}
.topbar-brand{display:flex;align-items:center;gap:10px;}
.brand-icon{width:36px;height:36px;background:var(--brand);border-radius:10px;
  display:flex;align-items:center;justify-content:center;
  color:#fff;font-family:var(--ff-head);font-weight:800;font-size:16px;}
.brand-name{font-family:var(--ff-head);font-weight:700;font-size:15px;}
.brand-sub{font-size:10px;color:var(--muted);margin-top:-1px;}
.topbar-actions{display:flex;align-items:center;gap:8px;}
.icon-btn{width:36px;height:36px;border:none;border-radius:var(--radius-sm);
  background:var(--bg);color:var(--muted);display:flex;align-items:center;
  justify-content:center;cursor:pointer;font-size:14px;transition:all .2s;}
.icon-btn:hover{background:var(--brand-light);color:var(--brand);}
.avatar-chip{display:flex;align-items:center;gap:8px;padding:5px 12px 5px 5px;
  border:1px solid var(--border);border-radius:999px;}
.avatar-circle{width:28px;height:28px;border-radius:50%;background:var(--brand);
  color:#fff;display:flex;align-items:center;justify-content:center;
  font-size:11px;font-weight:600;}
.avatar-name{font-size:12px;font-weight:500;}
.logout-link{padding:6px 14px;background:var(--brand);color:#fff;border:none;
  border-radius:var(--radius-sm);font-size:12px;font-weight:600;}

/* PAGE */
.page{padding:16px;max-width:700px;margin:0 auto;}

/* SUMMARY CARDS */
.summary-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:10px;margin-bottom:20px;}
.summary-card{background:var(--surface);border:1.5px solid var(--border);
  border-radius:var(--radius);padding:16px 14px;text-align:center;box-shadow:var(--shadow);}
.summary-val{font-family:var(--ff-head);font-size:22px;font-weight:800;color:var(--brand);}
.summary-lbl{font-size:11px;color:var(--muted);margin-top:3px;}

/* FILTER BAR */
.filter-bar{display:flex;align-items:center;gap:10px;margin-bottom:16px;flex-wrap:wrap;}
.filter-bar label{font-size:12px;font-weight:600;color:var(--muted);}
.filter-select{padding:8px 12px;border:1.5px solid var(--border);border-radius:var(--radius-sm);
  background:var(--surface);color:var(--text);font-size:13px;font-family:var(--ff-body);
  cursor:pointer;outline:none;}
.filter-select:focus{border-color:var(--brand);}
.count-badge{margin-left:auto;font-size:11px;padding:4px 12px;border-radius:999px;
  background:var(--brand-light);color:var(--brand);font-weight:600;}

/* HISTORY LIST */
.history-list{display:flex;flex-direction:column;gap:10px;}
.history-card{background:var(--surface);border:1.5px solid var(--border);
  border-radius:var(--radius);overflow:hidden;box-shadow:var(--shadow);}
.history-card-top{padding:14px 16px;display:flex;align-items:center;
  justify-content:space-between;gap:12px;}
.slot-date{font-family:var(--ff-head);font-size:14px;font-weight:700;}
.slot-date-sub{font-size:11px;color:var(--muted);margin-top:2px;}
.slot-name-big{font-family:var(--ff-head);font-size:15px;font-weight:700;margin-bottom:3px;}
.slot-time-range{font-size:12px;color:var(--muted);}

.status-badge{display:inline-flex;align-items:center;gap:5px;
  padding:4px 12px;border-radius:999px;font-size:11px;font-weight:700;white-space:nowrap;}
.s-COMPLETED{background:var(--green-bg);color:var(--green);}
.s-ACTIVE   {background:var(--blue-bg);color:var(--blue);}
.s-BOOKED   {background:var(--amber-bg);color:var(--amber);}
.s-CANCELLED{background:var(--red-bg);color:var(--red);}

.history-card-bottom{border-top:1px solid var(--border);padding:10px 16px;
  background:var(--bg);display:flex;gap:20px;flex-wrap:wrap;}
.detail-item{font-size:12px;color:var(--muted);display:flex;align-items:center;gap:5px;}
.detail-item i{width:12px;text-align:center;}
.detail-item strong{color:var(--text);}

/* EMPTY STATE */
.empty-state{text-align:center;padding:48px 20px;background:var(--surface);
  border:1px solid var(--border);border-radius:var(--radius);}
.empty-icon{font-size:40px;opacity:.2;margin-bottom:12px;}
.empty-title{font-family:var(--ff-head);font-size:16px;font-weight:700;margin-bottom:6px;}
.empty-sub{font-size:13px;color:var(--muted);}

/* BOTTOM NAV */
.bottom-nav{position:fixed;bottom:0;left:0;right:0;background:var(--surface);
  border-top:1px solid var(--border);display:flex;justify-content:space-around;
  padding:8px 0 12px;z-index:100;box-shadow:0 -4px 20px rgba(0,0,0,.06);}
.nav-item{display:flex;flex-direction:column;align-items:center;gap:3px;
  padding:4px 12px;border-radius:var(--radius-sm);text-decoration:none;color:var(--muted);}
.nav-item.active{color:var(--brand);}
.nav-item i{font-size:18px;}
.nav-label{font-size:10px;font-weight:500;}
.nav-indicator{width:4px;height:4px;border-radius:50%;background:var(--brand);
  margin:0 auto;opacity:0;}
.nav-item.active .nav-indicator{opacity:1;}
</style>
</head>
<body>

<!-- TOPBAR -->
<div class="topbar">
  <div class="topbar-brand">
    <div class="brand-icon">S</div>
    <div>
      <div class="brand-name">SIBS Delivery</div>
      <div class="brand-sub">Slot History</div>
    </div>
  </div>
  <div class="topbar-actions">
    <button class="icon-btn" onclick="toggleDark()"><i class="fa fa-moon"></i></button>
    <div class="avatar-chip">
      <div class="avatar-circle"><%=initials%></div>
      <span class="avatar-name"><%=dbFresh.getName()%></span>
    </div>
    <a href="deliveryLogout" class="logout-link"><i class="fa fa-sign-out-alt"></i> Logout</a>
  </div>
</div>

<div class="page">

  <!-- SUMMARY CARDS -->
  <div class="summary-grid">
    <div class="summary-card">
      <div class="summary-val"><%=totalShifts%></div>
      <div class="summary-lbl">Total Bookings</div>
    </div>
    <div class="summary-card">
      <div class="summary-val" style="color:var(--green);"><%=completedShifts%></div>
      <div class="summary-lbl">Completed</div>
    </div>
    <div class="summary-card">
      <div class="summary-val" style="color:var(--brand);"><%=totalHours%></div>
      <div class="summary-lbl">Total Hours</div>
    </div>
  </div>

  <!-- FILTER BAR -->
  <form method="get" style="display:contents;">
    <div class="filter-bar">
      <label><i class="fa fa-filter"></i> Month</label>
      <select name="month" class="filter-select" onchange="this.form.submit()">
        <option value="">All Time</option>
        <%
          // Build unique months from history
          java.util.LinkedHashSet<String> months = new java.util.LinkedHashSet<>();
          for (DeliverySlot s : history) {
              if (s.getBookingDate() != null) {
                  months.add(s.getBookingDate().toString().substring(0, 7));
              }
          }
          for (String m : months) {
              String[] parts = m.split("-");
              String label = new java.text.SimpleDateFormat("MMMM yyyy")
                  .format(new java.util.GregorianCalendar(
                      Integer.parseInt(parts[0]),
                      Integer.parseInt(parts[1]) - 1, 1).getTime());
        %>
        <option value="<%=m%>" <%=m.equals(filterMonth) ? "selected" : ""%>><%=label%></option>
        <% } %>
      </select>
      <span class="count-badge"><%=filtered.size()%> records</span>
    </div>
  </form>

  <!-- HISTORY LIST -->
  <div class="history-list">
  <% if (filtered.isEmpty()) { %>
    <div class="empty-state">
      <div class="empty-icon"><i class="fa fa-calendar-xmark"></i></div>
      <div class="empty-title">No bookings found</div>
      <div class="empty-sub">Your slot booking history will appear here.</div>
    </div>
  <% } else {
    for (DeliverySlot s : filtered) {
      String statusIcon = s.isCompleted() ? "fa-circle-check"
                        : s.isOnShift()   ? "fa-circle-play"
                        : s.isBooked()    ? "fa-clock"
                        : "fa-ban";
      String statusLabel = s.isCompleted() ? "Completed"
                         : s.isOnShift()   ? "On Shift"
                         : s.isBooked()    ? "Booked"
                         : "Cancelled";
      String dateStr = s.getBookingDate() != null
          ? new java.text.SimpleDateFormat("EEE, dd MMM yyyy")
              .format(s.getBookingDate()) : "—";
  %>
    <div class="history-card">
      <div class="history-card-top">
        <div>
          <div class="slot-name-big"><%=s.getSlotName()%></div>
          <div class="slot-time-range">
            <i class="fa fa-clock" style="color:var(--muted);font-size:11px;"></i>
            <%=s.getStartTime() != null ? s.getStartTime().toString().substring(0,5) : "—"%>
            – <%=s.getEndTime() != null ? s.getEndTime().toString().substring(0,5) : "—"%>
          </div>
        </div>
        <div style="text-align:right;">
          <span class="status-badge s-<%=s.getStatus()%>">
            <i class="fa <%=statusIcon%>"></i> <%=statusLabel%>
          </span>
          <div class="slot-date" style="margin-top:6px;"><%=dateStr%></div>
        </div>
      </div>
      <% if (s.isCompleted() || s.isOnShift()) { %>
      <div class="history-card-bottom">
        <% if (s.getShiftStart() != null) { %>
        <div class="detail-item">
          <i class="fa fa-play" style="color:var(--green);"></i>
          Started: <strong><%=s.getShiftStart().toString().substring(0,5)%></strong>
        </div>
        <% } %>
        <% if (s.getShiftEnd() != null) { %>
        <div class="detail-item">
          <i class="fa fa-stop" style="color:var(--red);"></i>
          Ended: <strong><%=s.getShiftEnd().toString().substring(0,5)%></strong>
        </div>
        <% } %>
        <% if (s.getWorkingHours() != null && !s.getWorkingHours().isEmpty()) { %>
        <div class="detail-item">
          <i class="fa fa-hourglass-half" style="color:var(--brand);"></i>
          Duration: <strong><%=s.getWorkingHours()%> hrs</strong>
        </div>
        <% } %>
      </div>
      <% } %>
    </div>
  <% } } %>
  </div>

</div>

<!-- BOTTOM NAV -->
<nav class="bottom-nav">
  <a href="delivery-dashboard.jsp"    class="nav-item"><i class="fa fa-house"></i><span class="nav-label">Home</span><div class="nav-indicator"></div></a>
  <a href="delivery-slot-booking.jsp" class="nav-item"><i class="fa fa-calendar-check"></i><span class="nav-label">My Slot</span><div class="nav-indicator"></div></a>
  <a href="delivery-earnings.jsp"     class="nav-item"><i class="fa fa-wallet"></i><span class="nav-label">Earnings</span><div class="nav-indicator"></div></a>
  <a href="delivery-cash-ledger.jsp"  class="nav-item"><i class="fa fa-coins"></i><span class="nav-label">COD</span><div class="nav-indicator"></div></a>
  <a href="delivery-slot-history.jsp" class="nav-item active"><i class="fa fa-clock-rotate-left"></i><span class="nav-label">History</span><div class="nav-indicator"></div></a>
  <a href="delivery-profile.jsp"      class="nav-item"><i class="fa fa-user"></i><span class="nav-label">Profile</span><div class="nav-indicator"></div></a>
</nav>

<script>
function toggleDark(){
  const h=document.documentElement,d=h.getAttribute('data-theme')==='dark';
  h.setAttribute('data-theme',d?'light':'dark');
  localStorage.setItem('sibs-theme',d?'light':'dark');
}
(function(){const t=localStorage.getItem('sibs-theme');if(t)document.documentElement.setAttribute('data-theme',t);})();
</script>
</body>
</html>
