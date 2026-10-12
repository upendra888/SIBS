<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="com.sibs.model.User, com.sibs.model.DeliveryBoy, com.sibs.dao.DeliveryBoyDAO, java.time.LocalDate, java.util.List" %>
<%
/* ── Auth guard ─────────────────────────────────────────────── */
User staff = (User) session.getAttribute("user");
if (staff == null) {
    response.sendRedirect(request.getContextPath() + "/login.jsp");
    return;
}

/* ── Delivery boys list (online only) ───────────────────────── */
List<DeliveryBoy> deliveryBoys = new DeliveryBoyDAO().getOnlineDeliveryBoys();

String returnId    = request.getParameter("returnId");
String complaintId = request.getParameter("complaintId");
String errorParam  = request.getParameter("error");

String flash = (String) session.getAttribute("flash");
if (flash != null) session.removeAttribute("flash");

/* guard: both params must be present */
if (returnId == null || returnId.isBlank()) {
    response.sendRedirect(request.getContextPath() + "/support");
    return;
}

String minDate = LocalDate.now().plusDays(1).toString();
String maxDate = LocalDate.now().plusDays(7).toString();
String ctxPath = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Schedule Pickup — SIBS Staff</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<style>
:root{
  --bg:#f8fafc;--surface:#fff;--border:#e2e8f0;
  --text:#0f172a;--muted:#64748b;
  --primary:#2563eb;--success:#16a34a;--danger:#ef4444;--warn:#f59e0b;
  --sidebar:#0f172a;
}
*{margin:0;padding:0;box-sizing:border-box;font-family:'Inter',sans-serif;}
body{background:var(--bg);color:var(--text);}

/* ── layout ── */
.content-area{margin-left:240px;padding:30px;}
.page-header{margin-bottom:24px;}
.page-header h1{font-size:22px;font-weight:700;display:flex;align-items:center;gap:10px;}
.page-header h1 i{color:var(--warn);}
.page-header p{color:var(--muted);font-size:14px;margin-top:4px;}

/* ── breadcrumb ── */
.breadcrumb{display:flex;align-items:center;gap:8px;font-size:13px;color:var(--muted);margin-bottom:20px;}
.breadcrumb a{color:var(--primary);text-decoration:none;}.breadcrumb a:hover{text-decoration:underline;}
.breadcrumb i{font-size:10px;}

/* ── card ── */
.card{background:var(--surface);border:1px solid var(--border);border-radius:14px;overflow:hidden;box-shadow:0 1px 4px rgba(0,0,0,.06);max-width:640px;}
.card-header{padding:18px 22px;border-bottom:1px solid var(--border);display:flex;align-items:center;gap:12px;}
.card-header .icon{width:42px;height:42px;border-radius:10px;background:#fff7ed;display:flex;align-items:center;justify-content:center;color:var(--warn);font-size:18px;flex-shrink:0;}
.card-header-text{flex:1;}
.card-header-text h2{font-size:16px;font-weight:700;}
.card-header-text p{font-size:12px;color:var(--muted);margin-top:2px;}
.card-body{padding:22px;}

/* ── banner ── */
.banner{padding:13px 16px;border-radius:10px;font-size:13px;margin-bottom:20px;display:flex;align-items:flex-start;gap:10px;line-height:1.5;}
.banner i{margin-top:1px;flex-shrink:0;}
.banner.success{background:#f0fdf4;border:1px solid #bbf7d0;color:#166534;}
.banner.error  {background:#fef2f2;border:1px solid #fecaca;color:#991b1b;}
.banner.info   {background:#eff6ff;border:1px solid #bfdbfe;color:#1e40af;}
.banner.warn   {background:#fffbeb;border:1px solid #fde68a;color:#92400e;}

/* ── step indicator ── */
.steps{display:flex;align-items:center;gap:0;margin-bottom:24px;}
.step{flex:1;display:flex;flex-direction:column;align-items:center;position:relative;}
.step:not(:last-child)::after{content:'';position:absolute;top:14px;left:calc(50% + 14px);width:calc(100% - 28px);height:2px;background:var(--border);}
.step.done::after,.step.active::after{background:var(--primary);}
.step-circle{width:28px;height:28px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:700;background:var(--bg);border:2px solid var(--border);color:var(--muted);z-index:1;}
.step.done .step-circle{background:var(--success);border-color:var(--success);color:#fff;}
.step.active .step-circle{background:var(--primary);border-color:var(--primary);color:#fff;}
.step-label{font-size:11px;color:var(--muted);margin-top:5px;font-weight:500;text-align:center;}
.step.active .step-label{color:var(--primary);font-weight:600;}
.step.done .step-label{color:var(--success);}

/* ── section ── */
.section{margin-bottom:22px;}
.section-label{font-size:12px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.05em;margin-bottom:8px;display:flex;align-items:center;gap:6px;}

/* ── date picker row ── */
.date-row{display:flex;gap:10px;align-items:stretch;}
input[type=date]{flex:1;border:1px solid var(--border);border-radius:8px;padding:10px 12px;font-size:14px;font-family:inherit;background:var(--surface);color:var(--text);cursor:pointer;}
input[type=date]:focus{outline:none;border-color:var(--primary);box-shadow:0 0 0 3px rgba(37,99,235,.08);}

/* ── buttons ── */
.btn{display:inline-flex;align-items:center;gap:7px;padding:10px 18px;border-radius:8px;border:none;cursor:pointer;font-size:13px;font-weight:600;text-decoration:none;transition:.15s;white-space:nowrap;}
.btn-primary{background:var(--primary);color:#fff;}.btn-primary:hover{background:#1d4ed8;}
.btn-success{background:var(--success);color:#fff;}.btn-success:hover{filter:brightness(.9);}
.btn-outline{background:var(--surface);color:var(--text);border:1px solid var(--border);}.btn-outline:hover{background:var(--bg);}
.btn:disabled{opacity:.5;cursor:not-allowed;}
.btn-lg{padding:12px 22px;font-size:14px;}
.btn-full{width:100%;justify-content:center;}

/* ── slots grid ── */
.slots-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(160px,1fr));gap:10px;}
.slot-card{border:1.5px solid var(--border);border-radius:10px;padding:14px;cursor:pointer;transition:.15s;background:var(--surface);text-align:center;}
.slot-card:hover{border-color:var(--primary);background:#eff6ff;}
.slot-card.selected{border-color:var(--primary);background:#eff6ff;box-shadow:0 0 0 3px rgba(37,99,235,.12);}
.slot-card .slot-time{font-size:11px;color:var(--muted);margin-top:3px;}
.slot-card .slot-name{font-size:14px;font-weight:700;color:var(--text);}
.slot-card .slot-remaining{margin-top:6px;display:inline-block;background:#f0fdf4;color:#166534;font-size:11px;font-weight:600;padding:2px 8px;border-radius:20px;}
.slot-card.selected .slot-remaining{background:#dcfce7;}

/* ── confirm summary ── */
.confirm-box{background:#f0fdf4;border:1px solid #bbf7d0;border-radius:10px;padding:16px 18px;margin-bottom:18px;}
.confirm-box .confirm-row{display:flex;align-items:center;gap:10px;font-size:14px;}
.confirm-box .confirm-row + .confirm-row{margin-top:8px;}
.confirm-box .confirm-row i{color:var(--success);width:16px;flex-shrink:0;}
.confirm-box .confirm-row strong{color:var(--text);}
.confirm-box .hint{font-size:12px;color:#166534;margin-top:10px;padding-top:10px;border-top:1px solid #bbf7d0;}

/* ── loader ── */
.loader{display:flex;align-items:center;gap:10px;font-size:13px;color:var(--muted);padding:20px 0;}
.spinner{width:18px;height:18px;border:2px solid var(--border);border-top-color:var(--primary);border-radius:50%;animation:spin .6s linear infinite;}
@keyframes spin{to{transform:rotate(360deg)}}

/* ── empty state ── */
.empty-state{text-align:center;padding:32px 20px;color:var(--muted);}
.empty-state i{font-size:32px;display:block;margin-bottom:10px;opacity:.35;}
.empty-state p{font-size:13px;}

/* ── select ── */
.res-select{width:100%;border:1px solid var(--border);border-radius:8px;padding:10px 12px;font-size:13px;font-family:inherit;background:var(--surface);color:var(--text);}
.res-select:focus{outline:none;border-color:var(--primary);box-shadow:0 0 0 3px rgba(37,99,235,.08);}

@media(max-width:768px){
  .content-area{margin-left:0;padding:16px;}
  .slots-grid{grid-template-columns:1fr 1fr;}
}
</style>
</head>
<body>

<jsp:include page="/includes/adminSidebar.jsp"/>

<div class="content-area">

  <!-- breadcrumb -->
  <div class="breadcrumb">
    <a href="<%=ctxPath%>/support"><i class="fa fa-headset"></i> Support</a>
    <i class="fa fa-chevron-right"></i>
    <span>Schedule Pickup</span>
    <% if (complaintId != null) { %>
      <i class="fa fa-chevron-right"></i>
      <span>Complaint #<%=complaintId%></span>
    <% } %>
  </div>

  <!-- page header -->
  <div class="page-header">
    <h1><i class="fa fa-box-open"></i> Schedule Wrong Item Pickup</h1>
    <p>Return #<%=returnId%> — Return approved. Choose a pickup date &amp; slot to schedule collection.</p>
  </div>

  <!-- flash / error banners -->
  <% if (flash != null) { %>
    <div class="banner warn" style="max-width:640px;margin-bottom:20px;">
      <i class="fa fa-triangle-exclamation"></i><span><%=flash%></span>
    </div>
  <% } %>
  <% if ("1".equals(errorParam)) { %>
    <div class="banner error" style="max-width:640px;margin-bottom:20px;">
      <i class="fa fa-circle-xmark"></i><span>Pickup scheduling failed — slot may have been taken. Please try again.</span>
    </div>
  <% } %>

  <div class="card">
    <div class="card-header">
      <div class="icon"><i class="fa fa-calendar-check"></i></div>
      <div class="card-header-text">
        <h2>Pick a Date &amp; Slot</h2>
        <p>Return auto-approved ✅ — confirm the pickup window below</p>
      </div>
    </div>
    <div class="card-body">

      <!-- step indicator -->
      <div class="steps" id="stepIndicator">
        <div class="step active" id="step1">
          <div class="step-circle">1</div>
          <div class="step-label">Choose Date</div>
        </div>
        <div class="step" id="step2">
          <div class="step-circle">2</div>
          <div class="step-label">Select Slot</div>
        </div>
        <div class="step" id="step3">
          <div class="step-circle">3</div>
          <div class="step-label">Confirm</div>
        </div>
      </div>

      <!-- return approved info -->
      <div class="banner success">
        <i class="fa fa-circle-check"></i>
        <span>Return request auto-created &amp; approved. Staff needs to choose a pickup date &amp; slot — customer will be notified once confirmed.</span>
      </div>

      <!-- STEP 1: Date -->
      <div class="section">
        <div class="section-label"><i class="fa fa-calendar"></i> Pickup Date</div>
        <div class="date-row">
          <input type="date" id="pickupDate"
                 min="<%=minDate%>" max="<%=maxDate%>"
                 value="<%=minDate%>">
          <button class="btn btn-primary" onclick="loadSlots()">
            <i class="fa fa-search"></i> Check Slots
          </button>
        </div>
        <div style="font-size:12px;color:var(--muted);margin-top:6px;">
          <i class="fa fa-circle-info" style="margin-right:4px;"></i>Available: tomorrow to next 7 days
        </div>
      </div>

      <!-- STEP 2: Slot selection (hidden until loaded) -->
      <div id="slotsSection" style="display:none;">
        <div class="section">
          <div class="section-label"><i class="fa fa-clock"></i> Available Slots</div>
          <div id="loadingIndicator" class="loader" style="display:none;">
            <div class="spinner"></div><span>Loading available slots…</span>
          </div>
          <div id="slotsGrid" class="slots-grid"></div>
          <div id="noSlotsMsg" class="empty-state" style="display:none;">
            <i class="fa fa-calendar-xmark"></i>
            <p>No slots available for this date. Please try a different date.</p>
          </div>
        </div>
      </div>

      <!-- STEP 3: Confirm form (hidden until slot selected) -->
      <div id="confirmSection" style="display:none;">
        <div class="confirm-box">
          <div class="confirm-row">
            <i class="fa fa-calendar-check"></i>
            <span>Date: <strong id="summaryDate">—</strong></span>
          </div>
          <div class="confirm-row">
            <i class="fa fa-clock"></i>
            <span>Slot: <strong id="summarySlot">—</strong></span>
          </div>
          <div class="confirm-row">
            <i class="fa fa-box"></i>
            <span>Return: <strong>#<%=returnId%></strong></span>
          </div>
          <div class="hint">
            <i class="fa fa-bell"></i> Customer will receive a pickup-scheduled notification upon confirmation.
          </div>
        </div>

        <form method="post" action="<%=ctxPath%>/support" id="confirmForm">
          <input type="hidden" name="action"     value="schedulePickup">
          <input type="hidden" name="returnId"   value="<%=returnId%>">
          <input type="hidden" name="pickupDate" id="hdnDate">
          <input type="hidden" name="slotId"     id="hdnSlot">
          <% if (complaintId != null) { %>
          <input type="hidden" name="complaintId" value="<%=complaintId%>">
          <% } %>

          <!-- Delivery Boy assign -->
          <div class="section" style="margin-bottom:18px;">
            <div class="section-label"><i class="fa fa-motorcycle"></i> Assign Delivery Boy <span style="font-weight:400;text-transform:none;letter-spacing:0;color:#94a3b8;">(pickup ki)</span></div>
            <select name="deliveryBoyId" class="res-select">
              <option value="">— Select delivery boy —</option>
              <% if (deliveryBoys != null) {
                   for (DeliveryBoy db : deliveryBoys) { %>
              <option value="<%=db.getId()%>">
                <%=db.getName()%> — <%=db.getPhone()%><% if ("ACTIVE".equals(db.getStatus()) || db.isOnline()) out.print(" ✅"); %>
              </option>
              <% } } %>
            </select>
            <div style="font-size:12px;color:var(--muted);margin-top:5px;">
              <i class="fa fa-circle-info"></i> ✅ = Active/Online. Select cheyakunte manually assign cheyyali.
            </div>
          </div>

          <div style="display:flex;gap:10px;">
            <button type="submit" class="btn btn-success btn-lg flex-fill" onclick="return confirmSubmit()">
              <i class="fa fa-check-circle"></i> Confirm Pickup Schedule
            </button>
            <a href="<%=ctxPath%>/support" class="btn btn-outline btn-lg">
              Cancel
            </a>
          </div>
        </form>
      </div>

    </div><!-- /card-body -->
  </div><!-- /card -->

</div><!-- /content-area -->

<script>
const CTX     = '<%=ctxPath%>';
const RETURN_ID = '<%=returnId%>';

let selectedSlotId   = null;
let selectedSlotName = null;
let selectedSlotTime = null;

/* ── Step indicator helper ─────────────────────────── */
function setStep(n) {
  for (let i = 1; i <= 3; i++) {
    const el = document.getElementById('step' + i);
    el.className = 'step' + (i < n ? ' done' : (i === n ? ' active' : ''));
  }
}

/* ── Load slots via AJAX ───────────────────────────── */
function loadSlots() {
  const date = document.getElementById('pickupDate').value;
  if (!date) { alert('Please select a date first.'); return; }

  // Reset state
  selectedSlotId = null;
  selectedSlotName = null;
  document.getElementById('confirmSection').style.display = 'none';
  document.getElementById('slotsSection').style.display = 'block';
  document.getElementById('noSlotsMsg').style.display = 'none';
  document.getElementById('slotsGrid').innerHTML = '';
  document.getElementById('loadingIndicator').style.display = 'flex';
  setStep(2);

  fetch(CTX + '/support?action=slots&date=' + encodeURIComponent(date))
    .then(r => {
      if (!r.ok) throw new Error('HTTP ' + r.status);
      return r.json();
    })
    .then(slots => renderSlots(slots, date))
    .catch(err => {
      document.getElementById('loadingIndicator').style.display = 'none';
      document.getElementById('slotsGrid').innerHTML =
        '<div class="banner error" style="grid-column:1/-1">' +
        '<i class="fa fa-triangle-exclamation"></i>' +
        '<span>Could not load slots. Please try again. (' + err.message + ')</span></div>';
    });
}

/* ── Render slot cards ─────────────────────────────── */
function renderSlots(slots, date) {
  document.getElementById('loadingIndicator').style.display = 'none';
  const grid   = document.getElementById('slotsGrid');
  const noSlot = document.getElementById('noSlotsMsg');
  grid.innerHTML = '';

  if (!slots || slots.length === 0) {
    noSlot.style.display = 'block';
    setStep(2);
    return;
  }

  noSlot.style.display = 'none';
  slots.forEach(s => {
    const card = document.createElement('div');
    card.className = 'slot-card';
    card.innerHTML =
      '<div class="slot-name">' + escHtml(s.slot_name) + '</div>' +
      '<div class="slot-time">' + escHtml(s.start_time) + ' – ' + escHtml(s.end_time) + '</div>' +
      '<div class="slot-remaining"><i class="fa fa-check" style="margin-right:3px"></i>' +
        s.remaining + ' remaining</div>';
    card.onclick = () => selectSlot(card, s.slot_id, s.slot_name, s.start_time, s.end_time, date);
    grid.appendChild(card);
  });
}

/* ── Select a slot ─────────────────────────────────── */
function selectSlot(cardEl, slotId, slotName, startTime, endTime, date) {
  // Deselect all
  document.querySelectorAll('.slot-card').forEach(c => c.classList.remove('selected'));
  cardEl.classList.add('selected');

  selectedSlotId   = slotId;
  selectedSlotName = slotName;
  selectedSlotTime = startTime + ' – ' + endTime;

  // Populate confirm section
  document.getElementById('hdnDate').value = date;
  document.getElementById('hdnSlot').value = slotId;

  // Format date nicely
  const [y, m, d] = date.split('-');
  const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  const prettyDate = d + ' ' + months[parseInt(m)-1] + ' ' + y;

  document.getElementById('summaryDate').textContent = prettyDate;
  document.getElementById('summarySlot').textContent = slotName + ' (' + startTime + ' – ' + endTime + ')';

  document.getElementById('confirmSection').style.display = 'block';
  document.getElementById('confirmSection').scrollIntoView({behavior:'smooth', block:'nearest'});
  setStep(3);
}

/* ── Confirm before submit ─────────────────────────── */
function confirmSubmit() {
  if (!selectedSlotId) { alert('Please select a slot first.'); return false; }
  return confirm(
    '📦 Confirm Pickup Schedule?\n\n' +
    'Date: ' + document.getElementById('summaryDate').textContent + '\n' +
    'Slot: ' + document.getElementById('summarySlot').textContent + '\n\n' +
    'Customer will be notified after confirmation.'
  );
}

/* ── Escape HTML helper ────────────────────────────── */
function escHtml(s) {
  return String(s)
    .replace(/&/g,'&amp;').replace(/</g,'&lt;')
    .replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

/* ── Auto-load slots on page load ─────────────────── */
window.addEventListener('DOMContentLoaded', () => {
  loadSlots();
});
</script>
</body>
</html>
