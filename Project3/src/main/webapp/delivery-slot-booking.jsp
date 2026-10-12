<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.util.*,com.sibs.dao.DeliverySlotDAO,com.sibs.model.DeliveryBoy,com.sibs.model.DeliverySlot" %>
<%
DeliveryBoy db = (DeliveryBoy) session.getAttribute("deliveryBoy");
if (db == null) { response.sendRedirect("delivery-login.jsp"); return; }

DeliverySlotDAO dao = new DeliverySlotDAO();

// ── Handle POST actions (book / startShift / endShift / cancel) ────────
if ("POST".equalsIgnoreCase(request.getMethod())) {
    String action = request.getParameter("action");
    if (action == null) action = "";
    String redirectMsg;

    switch (action) {
        case "book": {
            String slotIdStr = request.getParameter("slotId");
            int slotId = 0;
            try { slotId = Integer.parseInt(slotIdStr); } catch (Exception ignored) {}
            if (slotId == 0) {
                redirectMsg = "error=No+slot+selected.";
            } else {
                String result = dao.bookSlot(db.getId(), slotId);
                switch (result) {
                    case "ok":           redirectMsg = "success=Slot+booked+successfully!+Get+ready+for+your+shift."; break;
                    case "already_booked": redirectMsg = "error=You+already+have+an+active+booking+for+this+slot."; break;
                    case "slot_full":    redirectMsg = "error=This+slot+is+full.+Please+choose+another."; break;
                    default:             redirectMsg = "error=Something+went+wrong.+Please+try+again."; break;
                }
            }
            break;
        }
        case "startShift": {
            String shiftResult = dao.startShift(db.getId());
            if ("ok".equals(shiftResult)) {
                redirectMsg = "success=Shift+started!+You+are+now+on+duty.";
            } else if (shiftResult != null && shiftResult.startsWith("too_early:")) {
                String slotTime = shiftResult.split(":", 2)[1];
                redirectMsg = "error=Too+early!+Your+slot+starts+at+" + slotTime.replace(":", "%3A") + ".+Please+wait+until+then.";
            } else if ("not_found".equals(shiftResult)) {
                redirectMsg = "error=No+booked+slot+found+for+today.";
            } else {
                redirectMsg = "error=Could+not+start+shift.+Please+try+again.";
            }
            break;
        }
        case "endShift": {
            boolean ok = dao.endShift(db.getId());
            redirectMsg = ok ? "success=Shift+ended.+Great+work+today!"
                             : "error=Could+not+end+shift.+No+active+shift+found.";
            break;
        }
        case "cancel": {
            String bidStr = request.getParameter("bookingId");
            boolean ok = false;
            if (bidStr != null && !bidStr.isEmpty()) {
                ok = dao.cancelBookingById(Integer.parseInt(bidStr), db.getId());
            } else {
                ok = dao.cancelBooking(db.getId());
            }
            redirectMsg = ok ? "success=Booking+cancelled.+You+can+book+another+slot."
                             : "error=Cannot+cancel+-+your+shift+may+already+be+active.";
            break;
        }
        default:
            redirectMsg = "error=Unknown+action.";
            break;
    }

    response.sendRedirect("delivery-slot-booking.jsp?" + redirectMsg);
    return;
}

// ── Load data for display ──────────────────────────────────────────────
List<DeliverySlot> slots  = dao.getSlotsForBoy(db.getId());
List<DeliverySlot> mySlots = dao.getTodayBookings(db.getId());
DeliverySlot       mySlot = mySlots.isEmpty() ? null : mySlots.get(0);

// ── Flash messages ─────────────────────────────────────────
String successMsg = request.getParameter("success") != null ? request.getParameter("success") : "";
String errorMsg   = request.getParameter("error")   != null ? request.getParameter("error")   : "";

String initials = db.getName().length() >= 2
    ? db.getName().substring(0,2).toUpperCase()
    : db.getName().toUpperCase();

java.time.LocalDate today = java.time.LocalDate.now();
String todayStr = today.getDayOfWeek().toString().charAt(0) +
    today.getDayOfWeek().toString().substring(1).toLowerCase() + ", " +
    today.getMonth().toString().charAt(0) +
    today.getMonth().toString().substring(1).toLowerCase() + " " + today.getDayOfMonth();
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1">
<title>My Shift Slot · SIBS</title>
<link href="https://fonts.googleapis.com/css2?family=Syne:wght@400;500;600;700;800&family=DM+Sans:wght@300;400;500;600&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<style>
:root{
  --brand:#7c3aed;--brand-light:#ede9fe;--brand-dark:#4c1d95;
  --surface:#ffffff;--bg:#f3f1fb;--bg2:#edeaf8;
  --text:#0d0d14;--muted:#6b6882;--border:rgba(124,58,237,.12);
  --green:#16a34a;--green-bg:#dcfce7;--amber:#b45309;--amber-bg:#fef3c7;
  --red:#dc2626;--red-bg:#fee2e2;--blue:#1d4ed8;--blue-bg:#eff6ff;
  --radius:14px;--radius-sm:9px;
  --shadow:0 2px 16px rgba(124,58,237,.10);--shadow-lg:0 8px 40px rgba(124,58,237,.16);
  --ff-head:'Syne',sans-serif;--ff-body:'DM Sans',sans-serif;
}
[data-theme="dark"]{
  --brand:#a78bfa;--brand-light:#2e1f5e;--brand-dark:#c4b5fd;
  --surface:#13111f;--bg:#0d0b18;--bg2:#1a1730;--text:#f0eeff;--muted:#9791b8;
  --border:rgba(167,139,250,.14);--green:#4ade80;--green-bg:#052e16;
  --amber:#fcd34d;--amber-bg:#451a03;--red:#f87171;--red-bg:#450a0a;
  --blue:#93c5fd;--blue-bg:#0c1a3d;
  --shadow:0 2px 20px rgba(0,0,0,.4);--shadow-lg:0 8px 40px rgba(0,0,0,.5);
}
*,*::before,*::after{margin:0;padding:0;box-sizing:border-box;}
html{font-family:var(--ff-body);font-size:15px;color:var(--text);background:var(--bg);}
body{min-height:100vh;padding-bottom:90px;}
a{text-decoration:none;color:inherit;}
button{font-family:var(--ff-body);cursor:pointer;}

/* TOPBAR */
.topbar{background:var(--surface);border-bottom:1px solid var(--border);padding:0 18px;height:60px;
  display:flex;align-items:center;justify-content:space-between;
  position:sticky;top:0;z-index:200;box-shadow:var(--shadow);}
.topbar-brand{display:flex;align-items:center;gap:10px;}
.brand-icon{width:36px;height:36px;background:var(--brand);border-radius:10px;
  display:flex;align-items:center;justify-content:center;color:#fff;
  font-family:var(--ff-head);font-weight:800;font-size:16px;letter-spacing:-1px;}
.brand-name{font-family:var(--ff-head);font-weight:700;font-size:15px;letter-spacing:-.3px;}
.brand-sub{font-size:10px;color:var(--muted);margin-top:-1px;}
.topbar-actions{display:flex;align-items:center;gap:8px;}
.icon-btn{width:36px;height:36px;border:1px solid var(--border);border-radius:var(--radius-sm);
  background:var(--bg);color:var(--muted);display:flex;align-items:center;justify-content:center;
  cursor:pointer;font-size:14px;border:none;transition:all .2s;}
.icon-btn:hover{background:var(--brand-light);color:var(--brand);}
.avatar-chip{display:flex;align-items:center;gap:8px;padding:5px 12px 5px 5px;
  border:1px solid var(--border);border-radius:999px;background:var(--surface);}
.avatar-circle{width:28px;height:28px;border-radius:50%;background:var(--brand);color:#fff;
  display:flex;align-items:center;justify-content:center;font-size:11px;font-weight:600;}
.avatar-name{font-size:12px;font-weight:500;}
.logout-link{padding:6px 14px;background:var(--brand);color:#fff;border:none;
  border-radius:var(--radius-sm);font-size:12px;font-weight:600;transition:opacity .2s;}
.logout-link:hover{opacity:.85;}

/* PAGE */
.page{padding:16px 16px 0;max-width:700px;margin:0 auto;}

/* FLASH */
.flash{display:flex;align-items:flex-start;gap:10px;padding:13px 16px;border-radius:var(--radius-sm);
  font-size:13px;font-weight:500;margin-bottom:16px;animation:slideDown .3s ease;line-height:1.5;}
@keyframes slideDown{from{opacity:0;transform:translateY(-8px);}to{opacity:1;transform:none;}}
.flash-success{background:var(--green-bg);color:var(--green);border:1px solid rgba(22,163,74,.2);}
.flash-error  {background:var(--red-bg);color:var(--red);border:1px solid rgba(220,38,38,.2);}

/* HERO DATE */
.date-hero{background:linear-gradient(135deg,#2e1065,#4c1d95,#6d28d9);
  border-radius:var(--radius);padding:20px 24px;margin-bottom:16px;
  display:flex;align-items:center;justify-content:space-between;color:#fff;}
.date-label{font-size:11px;opacity:.55;letter-spacing:.4px;text-transform:uppercase;
  font-family:var(--ff-head);margin-bottom:3px;}
.date-value{font-family:var(--ff-head);font-size:20px;font-weight:700;}
.date-badge{font-size:11px;background:rgba(255,255,255,.15);border-radius:999px;
  padding:4px 12px;font-weight:600;}

/* CURRENT BOOKING CARD */
.booking-card{background:var(--surface);border:2px solid var(--brand);
  border-radius:var(--radius);overflow:hidden;margin-bottom:16px;box-shadow:var(--shadow);}
.booking-card-header{background:linear-gradient(90deg,#4c1d95,#6d28d9);
  padding:13px 16px;display:flex;align-items:center;justify-content:space-between;}
.booking-card-title{font-family:var(--ff-head);font-size:13px;font-weight:700;color:#fff;
  display:flex;align-items:center;gap:8px;}
.live-dot{width:8px;height:8px;background:#a3e635;border-radius:50%;display:inline-block;
  animation:blink 1.4s ease-in-out infinite;}
@keyframes blink{0%,100%{opacity:1;}50%{opacity:.3;}}
.booking-status-badge{font-size:11px;padding:3px 10px;border-radius:999px;font-weight:700;
  background:rgba(255,255,255,.15);color:#fff;}
.booking-card-body{padding:18px;}
.booking-info-grid{display:grid;grid-template-columns:1fr 1fr;gap:12px;margin-bottom:16px;}
.booking-info-item{background:var(--bg);border-radius:var(--radius-sm);padding:12px;}
.booking-info-label{font-size:10px;color:var(--muted);text-transform:uppercase;letter-spacing:.04em;margin-bottom:4px;}
.booking-info-value{font-family:var(--ff-head);font-size:16px;font-weight:700;}
.shift-actions{display:flex;gap:10px;flex-wrap:wrap;}

/* NO BOOKING PROMPT */
.no-booking-prompt{background:var(--surface);border:1px solid var(--border);
  border-radius:var(--radius);padding:24px;text-align:center;margin-bottom:16px;}
.no-booking-icon{font-size:40px;margin-bottom:12px;opacity:.25;}
.no-booking-title{font-family:var(--ff-head);font-size:16px;font-weight:700;margin-bottom:6px;}
.no-booking-sub{font-size:13px;color:var(--muted);}

/* SECTION HEADING */
.section-heading{display:flex;align-items:center;justify-content:space-between;margin-bottom:12px;}
.section-heading h2{font-family:var(--ff-head);font-size:14px;font-weight:700;letter-spacing:-.2px;}
.slot-count-badge{font-size:11px;padding:3px 10px;border-radius:999px;
  background:var(--brand-light);color:var(--brand);font-weight:600;}

/* SLOT CARDS */
.slots-grid{display:flex;flex-direction:column;gap:10px;}
.slot-card{background:var(--surface);border:1.5px solid var(--border);
  border-radius:var(--radius);overflow:hidden;transition:all .2s;}
.slot-card:hover{box-shadow:var(--shadow);}
.slot-card.slot-available{border-color:rgba(124,58,237,.25);}
.slot-card.slot-full{opacity:.65;}
.slot-card.slot-expired{opacity:.45;filter:grayscale(.4);border-style:dashed;}
.slot-card.slot-booked-mine{border-color:var(--green);background:var(--green-bg);}
.slot-card.slot-active-mine{border-color:var(--brand);box-shadow:0 0 0 3px rgba(124,58,237,.1);}
.slot-card.slot-completed-mine{border-color:#94a3b8;opacity:.8;}

.slot-inner{display:flex;align-items:center;gap:14px;padding:14px 16px;}
.slot-time-block{flex-shrink:0;text-align:center;min-width:80px;}
.slot-time{font-family:var(--ff-head);font-size:15px;font-weight:700;line-height:1.2;}
.slot-end-time{font-size:11px;color:var(--muted);margin-top:2px;}
.slot-divider{width:1px;height:40px;background:var(--border);flex-shrink:0;}
.slot-info{flex:1;}
.slot-name{font-family:var(--ff-head);font-size:14px;font-weight:700;}
.slot-capacity-row{display:flex;align-items:center;gap:6px;margin-top:5px;}
.slot-bar-track{flex:1;height:5px;background:var(--bg2);border-radius:999px;overflow:hidden;}
.slot-bar-fill{height:100%;border-radius:999px;background:linear-gradient(90deg,var(--brand),#a78bfa);transition:width .5s;}
.slot-bar-fill.full{background:linear-gradient(90deg,var(--red),#f87171);}
.slot-seats{font-size:11px;color:var(--muted);white-space:nowrap;}
.slot-right{flex-shrink:0;display:flex;align-items:center;gap:8px;}
.slot-status-tag{font-size:11px;font-weight:700;padding:4px 10px;border-radius:999px;white-space:nowrap;}
.tag-available {background:var(--brand-light);color:var(--brand);}
.tag-full      {background:var(--bg2);color:var(--muted);}
.tag-expired   {background:#f3f4f6;color:#9ca3af;}
.tag-mine-booked  {background:var(--green-bg);color:var(--green);}
.tag-mine-active  {background:var(--brand-light);color:var(--brand);}
.tag-mine-done    {background:var(--bg2);color:var(--muted);}
.tag-mine-cancelled{background:var(--red-bg);color:var(--red);}

/* BUTTONS */
.btn{padding:11px 20px;border:none;border-radius:var(--radius-sm);font-size:13px;font-weight:600;
  font-family:var(--ff-body);display:inline-flex;align-items:center;justify-content:center;
  gap:7px;transition:all .2s;cursor:pointer;}
.btn:hover{transform:translateY(-1px);}
.btn:active{transform:scale(.97);}
.btn-brand  {background:var(--brand);color:#fff;}
.btn-brand:hover{background:#6d28d9;}
.btn-ghost  {background:var(--bg);color:var(--text);border:1px solid var(--border);}
.btn-ghost:hover{background:var(--bg2);}
.btn-danger {background:var(--red-bg);color:var(--red);border:1px solid rgba(220,38,38,.2);}
.btn-danger:hover{background:#fecaca;}
.btn-success{background:var(--green-bg);color:var(--green);border:1px solid rgba(22,163,74,.2);}
.btn-success:hover{background:#bbf7d0;}
.btn-sm{padding:8px 14px;font-size:12px;}

/* BOTTOM NAV */
.bottom-nav{position:fixed;bottom:0;left:0;right:0;background:var(--surface);
  border-top:1px solid var(--border);display:flex;justify-content:space-around;
  padding:8px 0 12px;z-index:100;box-shadow:0 -4px 20px rgba(0,0,0,.06);}
.nav-item{display:flex;flex-direction:column;align-items:center;gap:3px;cursor:pointer;
  padding:4px 12px;border-radius:var(--radius-sm);transition:all .2s;text-decoration:none;color:var(--muted);}
.nav-item.active{color:var(--brand);}
.nav-item i{font-size:18px;}
.nav-label{font-size:10px;font-weight:500;}
.nav-indicator{width:4px;height:4px;border-radius:50%;background:var(--brand);margin:0 auto;opacity:0;}
.nav-item.active .nav-indicator{opacity:1;}

/* MODAL */
.modal-overlay{display:none;position:fixed;inset:0;background:rgba(0,0,0,.5);z-index:300;
  align-items:center;justify-content:center;padding:20px;}
.modal-overlay.open{display:flex;}
.modal-box{background:var(--surface);border-radius:var(--radius);padding:24px;
  max-width:360px;width:100%;box-shadow:var(--shadow-lg);animation:modalIn .25s ease;}
@keyframes modalIn{from{opacity:0;transform:scale(.95);}to{opacity:1;transform:none;}}
.modal-icon{font-size:36px;text-align:center;margin-bottom:12px;}
.modal-title{font-family:var(--ff-head);font-size:17px;font-weight:700;text-align:center;margin-bottom:6px;}
.modal-sub{font-size:13px;color:var(--muted);text-align:center;margin-bottom:20px;}
.modal-actions{display:flex;gap:10px;}
.modal-actions .btn{flex:1;}

@media(max-width:480px){
  .booking-info-grid{grid-template-columns:1fr;}
  .slot-inner{flex-wrap:wrap;gap:10px;}
  .slot-time-block{min-width:auto;}
}
</style>
</head>
<body>

<!-- ══════════ TOPBAR ══════════ -->
<div class="topbar">
  <div class="topbar-brand">
    <div class="brand-icon">S</div>
    <div>
      <div class="brand-name">SIBS Delivery</div>
      <div class="brand-sub">Slot Booking</div>
    </div>
  </div>
  <div class="topbar-actions">
    <button class="icon-btn" onclick="toggleDark()" title="Toggle dark mode"><i class="fa fa-moon"></i></button>
    <div class="avatar-chip">
      <div class="avatar-circle"><%=initials%></div>
      <span class="avatar-name"><%=db.getName()%></span>
    </div>
    <a href="deliveryLogout" class="logout-link"><i class="fa fa-sign-out-alt"></i> Logout</a>
  </div>
</div>

<!-- ══════════ PAGE ══════════ -->
<div class="page">

  <%-- Flash messages --%>
  <% if (!successMsg.isEmpty()) { %>
    <div class="flash flash-success"><i class="fa fa-circle-check"></i> <%=successMsg%></div>
  <% } %>
  <% if (!errorMsg.isEmpty()) { %>
    <div class="flash flash-error"><i class="fa fa-circle-xmark"></i> <%=errorMsg%></div>
  <% } %>

  <!-- Date hero -->
  <div class="date-hero">
    <div>
      <div class="date-label">Today's Schedule</div>
      <div class="date-value"><%=todayStr%></div>
    </div>
    <div class="date-badge"><i class="fa fa-clock"></i> Slots</div>
  </div>

  <%-- ── MY BOOKING CARDS ─────────────────────────────────── --%>
  <% for (DeliverySlot ms : mySlots) {
      String statusLabel = "BOOKED".equals(ms.getStatus())    ? "Booked"
                         : "ACTIVE".equals(ms.getStatus())    ? "On Shift"
                         : "COMPLETED".equals(ms.getStatus()) ? "Completed"
                         : "Cancelled";
  %>
  <div class="booking-card">
    <div class="booking-card-header">
      <div class="booking-card-title">
        <% if ("ACTIVE".equals(ms.getStatus())) { %><span class="live-dot"></span><% } %>
        My Slot for Today
      </div>
      <span class="booking-status-badge"><%=statusLabel%></span>
    </div>
    <div class="booking-card-body">
      <div class="booking-info-grid">
        <div class="booking-info-item">
          <div class="booking-info-label">Slot</div>
          <div class="booking-info-value"><%=ms.getSlotName()%></div>
        </div>
        <div class="booking-info-item">
          <div class="booking-info-label">Time Window</div>
          <div class="booking-info-value" style="font-size:13px;">
            <%=ms.getStartTime().toString().substring(0,5)%> – <%=ms.getEndTime().toString().substring(0,5)%>
          </div>
        </div>
        <% if (ms.getShiftStart() != null) { %>
        <div class="booking-info-item">
          <div class="booking-info-label">Shift Started</div>
          <div class="booking-info-value"><%=ms.getShiftStart().toString().substring(0,5)%></div>
        </div>
        <% } %>
        <% if (ms.getShiftEnd() != null) { %>
        <div class="booking-info-item">
          <div class="booking-info-label">Shift Ended</div>
          <div class="booking-info-value"><%=ms.getShiftEnd().toString().substring(0,5)%></div>
        </div>
        <% } %>
        <% if (ms.getWorkingHours() != null) { %>
        <div class="booking-info-item">
          <div class="booking-info-label">Hours Worked</div>
          <div class="booking-info-value" style="color:var(--green);"><%=ms.getWorkingHours()%> hrs</div>
        </div>
        <% } %>
      </div>

      <%-- Action buttons depending on status --%>
      <div class="shift-actions">
        <% if ("BOOKED".equals(ms.getStatus())) { %>
          <form action="slotAction" method="post" style="flex:2;display:flex;">
            <input type="hidden" name="action" value="startShift">
            <input type="hidden" name="bookingId" value="<%=ms.getBookingId() != null ? ms.getBookingId() : ""%>">
            <button class="btn btn-brand" type="submit" style="width:100%;">
              <i class="fa fa-play"></i> Start Shift
            </button>
          </form>
          <button class="btn btn-danger btn-sm" onclick="document.getElementById('cancelBookingId').value='<%=ms.getBookingId()%>';openModal('cancelModal')">
            <i class="fa fa-ban"></i> Cancel
          </button>
        <% } else if ("ACTIVE".equals(ms.getStatus())) { %>
          <form action="slotAction" method="post" style="flex:1;display:flex;">
            <input type="hidden" name="action" value="endShift">
            <button class="btn btn-success" type="submit"
                    onclick="return confirm('End your shift now?')" style="width:100%;">
              <i class="fa fa-stop"></i> End Shift &amp; Clock Out
            </button>
          </form>
        <% } else if ("COMPLETED".equals(ms.getStatus())) { %>
          <div style="display:flex;align-items:center;gap:8px;color:var(--green);font-size:13px;font-weight:600;">
            <i class="fa fa-circle-check"></i> Shift completed — great work today!
          </div>
        <% } else if ("CANCELLED".equals(ms.getStatus())) { %>
          <%-- FIX: Allow re-booking after cancellation --%>
          <a href="delivery-slot-booking.jsp" class="btn btn-brand" style="width:100%;">
            <i class="fa fa-calendar-plus"></i> Book Another Slot
          </a>
        <% } %>
      </div>
    </div>
  </div>

  <% } // end for mySlots

  if (mySlots.isEmpty()) { %>

  <!-- No booking yet -->
  <div class="no-booking-prompt">
    <div class="no-booking-icon">📋</div>
    <div class="no-booking-title">No slot booked yet</div>
    <div class="no-booking-sub">Choose a slot below to reserve your shift for today.</div>
  </div>

  <% } %>

  <!-- ── AVAILABLE SLOTS ─────────────────────────────────── -->
  <%
  java.time.LocalTime nowLocal = java.time.LocalTime.now();
  %>
  <div class="section-heading">
    <h2>Today's Delivery Slots</h2>
    <span class="slot-count-badge"><%=slots.size()%> slots</span>
  </div>

  <div class="slots-grid">
  <% for (DeliverySlot s : slots) {
      boolean isMine  = s.getBookingId() != null && !s.isCancelled();
      boolean isPast  = s.getEndTime() != null
                     && s.getEndTime().toLocalTime().isBefore(nowLocal);
      boolean isAvail = s.isAvailable() && !isMine && !isPast;
      boolean isFull  = !s.isAvailable() && !isMine && !isPast;
      int fillPct = s.getMaxCapacity() > 0
          ? Math.min(100, (int) Math.round(s.getBookedCount() * 100.0 / s.getMaxCapacity()))
          : 0;
      String cardCls = isMine && s.isBooked()    ? "slot-booked-mine"
                     : isMine && s.isOnShift()   ? "slot-active-mine"
                     : isMine && s.isCompleted() ? "slot-completed-mine"
                     : isPast                    ? "slot-expired"
                     : isFull                    ? "slot-full"
                     : "slot-available";
      String tagCls  = isMine && s.isBooked()    ? "tag-mine-booked"
                     : isMine && s.isOnShift()   ? "tag-mine-active"
                     : isMine && s.isCompleted() ? "tag-mine-done"
                     : isMine && s.isCancelled() ? "tag-mine-cancelled"
                     : isPast                    ? "tag-expired"
                     : isFull                    ? "tag-full"
                     : "tag-available";
      String tagLbl  = isMine && s.isBooked()    ? "✔ My Slot"
                     : isMine && s.isOnShift()   ? "🟢 On Shift"
                     : isMine && s.isCompleted() ? "✔ Done"
                     : isMine && s.isCancelled() ? "Cancelled"
                     : isPast                    ? "⏰ Expired"
                     : isFull                    ? "Full"
                     : s.getRemainingCapacity() + " left";
  %>
    <div class="slot-card <%=cardCls%>">
      <div class="slot-inner">
        <div class="slot-time-block">
          <div class="slot-time" style="<%=isPast && !isMine ? "color:var(--muted);" : ""%>">
            <%=s.getStartTime().toString().substring(0,5)%></div>
          <div class="slot-end-time">– <%=s.getEndTime().toString().substring(0,5)%></div>
        </div>
        <div class="slot-divider"></div>
        <div class="slot-info">
          <div class="slot-name" style="<%=isPast && !isMine ? "color:var(--muted);" : ""%>">
            <%=s.getSlotName()%></div>
          <div class="slot-capacity-row">
            <div class="slot-bar-track">
              <div class="slot-bar-fill <%=(isFull||isPast)?"full":""%>" style="width:<%=fillPct%>%;"></div>
            </div>
            <span class="slot-seats"><%=s.getBookedCount()%>/<%=s.getMaxCapacity()%></span>
          </div>
        </div>
        <div class="slot-right">
          <span class="slot-status-tag <%=tagCls%>"><%=tagLbl%></span>
          <% if (isAvail) { %>
            <button class="btn btn-brand btn-sm"
              onclick="showBookModal(<%=s.getSlotId()%>,'<%=s.getSlotName()%>','<%=s.getStartTime().toString().substring(0,5)%>','<%=s.getEndTime().toString().substring(0,5)%>')">
              Book
            </button>
          <% } else if (isPast && !isMine) { %>
            <button class="btn btn-sm" disabled
              style="opacity:.4;cursor:not-allowed;background:var(--bg2);color:var(--muted);border:1px solid var(--border);">
              Closed
            </button>
          <% } %>
        </div>
      </div>
    </div>
  <% } %>
  </div>

</div><!-- /page -->

<!-- BOTTOM NAV -->
<nav class="bottom-nav">
  <a href="delivery-dashboard.jsp"    class="nav-item"><i class="fa fa-house"></i><span class="nav-label">Home</span><div class="nav-indicator"></div></a>
  <a href="delivery-slot-booking.jsp" class="nav-item active"><i class="fa fa-calendar-check"></i><span class="nav-label">My Slot</span><div class="nav-indicator"></div></a>
  <a href="delivery-earnings.jsp"     class="nav-item"><i class="fa fa-wallet"></i><span class="nav-label">Earnings</span><div class="nav-indicator"></div></a>
  <a href="delivery-cash-ledger.jsp"  class="nav-item"><i class="fa fa-coins"></i><span class="nav-label">COD</span><div class="nav-indicator"></div></a>
  <a href="delivery-ratings.jsp"      class="nav-item"><i class="fa fa-star"></i><span class="nav-label">Ratings</span><div class="nav-indicator"></div></a>
  <a href="delivery-profile.jsp"      class="nav-item"><i class="fa fa-user"></i><span class="nav-label">Profile</span><div class="nav-indicator"></div></a>
</nav>

<!-- BOOK CONFIRM MODAL -->
<div class="modal-overlay" id="bookModal">
  <div class="modal-box">
    <div class="modal-icon">📅</div>
    <div class="modal-title">Confirm Booking</div>
    <div class="modal-sub">
      Book the <strong id="modalSlotName"></strong> slot<br>
      <span id="modalSlotTime" style="font-size:14px;font-weight:600;color:var(--brand);"></span>?
    </div>
    <form action="slotAction" method="post">
      <input type="hidden" name="action" value="book">
      <input type="hidden" name="slotId" id="modalSlotId">
      <div class="modal-actions">
        <button type="button" class="btn btn-ghost" onclick="closeModal('bookModal')">Cancel</button>
        <button type="submit" class="btn btn-brand"><i class="fa fa-calendar-check"></i> Confirm</button>
      </div>
    </form>
  </div>
</div>

<!-- CANCEL BOOKING MODAL -->
<div class="modal-overlay" id="cancelModal">
  <div class="modal-box">
    <div class="modal-icon">🚫</div>
    <div class="modal-title">Cancel Booking?</div>
    <div class="modal-sub">Your slot will be freed up for other delivery partners.</div>
    <form action="slotAction" method="post">
      <input type="hidden" name="action" value="cancel">
      <input type="hidden" name="bookingId" id="cancelBookingId" value="">
      <div class="modal-actions">
        <button type="button" class="btn btn-ghost" onclick="closeModal('cancelModal')">Keep It</button>
        <button type="submit" class="btn btn-danger"><i class="fa fa-ban"></i> Cancel Booking</button>
      </div>
    </form>
  </div>
</div>

<script>
/* ── Dark mode ── */
function toggleDark(){
  const h=document.documentElement,d=h.getAttribute('data-theme')==='dark';
  h.setAttribute('data-theme',d?'light':'dark');
  localStorage.setItem('sibs-theme',d?'light':'dark');
}
(function(){const t=localStorage.getItem('sibs-theme');if(t)document.documentElement.setAttribute('data-theme',t);})();

/* ── Modals ── */
function openModal(id){document.getElementById(id).classList.add('open');}
function closeModal(id){document.getElementById(id).classList.remove('open');}
['bookModal','cancelModal'].forEach(function(id){
  var el=document.getElementById(id);
  if(el)el.addEventListener('click',function(e){if(e.target===this)closeModal(id);});
});

function showBookModal(slotId, name, start, end){
  document.getElementById('modalSlotId').value   = slotId;
  document.getElementById('modalSlotName').textContent = name;
  document.getElementById('modalSlotTime').textContent = start + ' – ' + end;
  openModal('bookModal');
}
</script>
</body>
</html>
