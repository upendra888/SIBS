<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="com.sibs.model.User, com.sibs.model.SupportComplaint, com.sibs.model.Order, com.sibs.model.Payment, com.sibs.model.DeliveryBoy, java.util.List" %>
<%
/* ── Auth guard ───────────────────────────────────────────── */
User staff = (User) session.getAttribute("user");
if (staff == null) {
    response.sendRedirect(request.getContextPath() + "/login.jsp");
    return;
}

/* ── Flash message ────────────────────────────────────────── */
String flashMsg = (String) session.getAttribute("supportMsg");
session.removeAttribute("supportMsg");

/* ── View mode: list vs single ticket ─────────────────────── */
SupportComplaint complaint   = (SupportComplaint) request.getAttribute("complaint");
List<SupportComplaint> tickets = (List<SupportComplaint>) request.getAttribute("tickets");
boolean showAll   = Boolean.TRUE.equals(request.getAttribute("showAll"));
String  errorAttr = (String) request.getAttribute("error");

boolean singleView = (complaint != null);

/* ── Linked order / payment / delivery boys (single view) ── */
Order          linkedOrder   = (Order)   request.getAttribute("linkedOrder");
Payment        linkedPayment = (Payment) request.getAttribute("linkedPayment");
@SuppressWarnings("unchecked")
List<DeliveryBoy> deliveryBoys = (List<DeliveryBoy>) request.getAttribute("deliveryBoys");
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Support Complaints — SIBS Staff</title>
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

/* ── Layout ── */
.content-area{margin-left:240px;padding:30px;}
.page-header{margin-bottom:24px;}
.page-header h1{font-size:22px;font-weight:700;display:flex;align-items:center;gap:10px;}
.page-header h1 i{color:var(--primary);}
.page-header p{color:var(--muted);font-size:14px;margin-top:4px;}

/* ── Toolbar ── */
.toolbar{display:flex;align-items:center;gap:10px;margin-bottom:20px;flex-wrap:wrap;}
.btn{display:inline-flex;align-items:center;gap:6px;padding:9px 16px;border-radius:8px;border:none;cursor:pointer;font-size:13px;font-weight:500;text-decoration:none;transition:.15s;}
.btn-primary{background:var(--primary);color:#fff;}  .btn-primary:hover{background:#1d4ed8;}
.btn-outline{background:var(--surface);color:var(--text);border:1px solid var(--border);}  .btn-outline:hover{background:var(--bg);}
.btn-success{background:var(--success);color:#fff;}  .btn-success:hover{filter:brightness(.9);}
.btn-danger {background:var(--danger);color:#fff;}   .btn-danger:hover{filter:brightness(.9);}
.btn-sm{padding:5px 12px;font-size:12px;}

/* ── Flash banner ── */
.banner{padding:13px 16px;border-radius:10px;font-size:14px;margin-bottom:20px;display:flex;align-items:flex-start;gap:10px;line-height:1.5;}
.banner i{margin-top:1px;flex-shrink:0;}
.banner.info   {background:#eff6ff;border:1px solid #bfdbfe;color:#1e40af;}
.banner.success{background:#f0fdf4;border:1px solid #bbf7d0;color:#166534;}
.banner.error  {background:#fef2f2;border:1px solid #fecaca;color:#991b1b;}
.banner.warn   {background:#fffbeb;border:1px solid #fde68a;color:#92400e;}

/* ── Status badges ── */
.badge{display:inline-flex;align-items:center;gap:4px;padding:4px 10px;border-radius:20px;font-size:12px;font-weight:600;white-space:nowrap;}
.badge-open        {background:#fef9c3;color:#854d0e;}
.badge-under_review{background:#dbeafe;color:#1e40af;}
.badge-resolved    {background:#dcfce7;color:#166534;}
.badge-closed      {background:#fee2e2;color:#991b1b;}

/* ── Ticket list card ── */
.card{background:var(--surface);border:1px solid var(--border);border-radius:14px;margin-bottom:24px;box-shadow:0 1px 4px rgba(0,0,0,.06);}
.card-header{padding:16px 20px;border-bottom:1px solid var(--border);display:flex;align-items:center;gap:8px;font-weight:600;font-size:15px;}
.card-header i{color:var(--primary);}
.count-tag{background:#e2e8f0;color:var(--muted);padding:2px 8px;border-radius:10px;font-size:12px;font-weight:500;margin-left:4px;}

table{width:100%;border-collapse:collapse;font-size:13px;}
th{background:#f1f5f9;padding:10px 14px;text-align:left;font-weight:600;color:var(--muted);border-bottom:1px solid var(--border);font-size:12px;text-transform:uppercase;letter-spacing:.04em;}
td{padding:12px 14px;border-bottom:1px solid var(--border);vertical-align:middle;}
tr:last-child td{border-bottom:none;}
tbody tr:hover td{background:#f8fafc;}

.ticket-link{font-weight:700;color:var(--primary);text-decoration:none;}
.ticket-link:hover{text-decoration:underline;}
.empty{text-align:center;padding:56px;color:var(--muted);}
.empty i{font-size:40px;display:block;margin-bottom:12px;opacity:.35;}

/* ── Single ticket view ── */
.detail-grid{display:grid;grid-template-columns:1fr 1fr;gap:16px;margin-bottom:20px;}
.info-box{background:var(--bg);border:1px solid var(--border);border-radius:10px;padding:18px;}
.info-box h4{font-size:11px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.06em;margin-bottom:12px;display:flex;align-items:center;gap:6px;}
.info-row{display:flex;justify-content:space-between;align-items:flex-start;font-size:13px;margin-bottom:8px;gap:8px;}
.info-row:last-child{margin-bottom:0;}
.info-row .lbl{color:var(--muted);flex-shrink:0;}
.info-row .val{font-weight:500;text-align:right;}

.desc-box{background:var(--bg);border:1px solid var(--border);border-radius:10px;padding:18px;margin-bottom:18px;font-size:13px;line-height:1.6;}
.desc-box h4{font-size:11px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.06em;margin-bottom:10px;display:flex;align-items:center;gap:6px;}
.proof-img{max-width:340px;border-radius:10px;border:1px solid var(--border);margin-top:10px;display:block;}

/* ── Delivery Boy bar ── */
.db-bar{background:#eff6ff;border:1px solid #bfdbfe;border-radius:10px;padding:14px 18px;margin-bottom:18px;display:flex;align-items:center;gap:12px;flex-wrap:wrap;}
.db-bar i{color:var(--primary);font-size:18px;flex-shrink:0;}
.db-bar .db-info{flex:1;font-size:13px;line-height:1.7;}
.db-bar .db-info strong{color:var(--text);}

/* ── Investigation notes (review form) ── */
.review-section{background:#f0fdf4;border:1px solid #bbf7d0;border-radius:12px;padding:20px;margin-bottom:18px;}
.review-section h3{font-size:14px;font-weight:700;color:#166534;margin-bottom:12px;display:flex;align-items:center;gap:8px;}
textarea{width:100%;border:1px solid var(--border);border-radius:8px;padding:10px 12px;font-size:13px;resize:vertical;min-height:90px;font-family:inherit;background:var(--surface);}
textarea:focus{border-color:var(--primary);outline:none;box-shadow:0 0 0 3px rgba(37,99,235,.08);}

/* ── Verdict section ── */
.verdict-section{background:#fff7ed;border:1px solid #fed7aa;border-radius:12px;padding:20px;}
.verdict-section h3{font-size:14px;font-weight:700;color:#9a3412;margin-bottom:6px;display:flex;align-items:center;gap:8px;}
.verdict-section p{font-size:12px;color:#c2410c;margin-bottom:14px;}
.verdict-buttons{display:flex;gap:12px;flex-wrap:wrap;margin-top:14px;}

/* ── Resolution panel (shown after Genuine clicked) ── */
.resolution-panel{display:none;margin-top:16px;border-top:1px solid #fed7aa;padding-top:16px;}
.resolution-panel.show{display:block;}
.res-tabs{display:flex;gap:0;margin-bottom:16px;border-radius:8px;overflow:hidden;border:1px solid var(--border);}
.res-tab{flex:1;padding:10px;text-align:center;font-size:13px;font-weight:600;cursor:pointer;background:#f8fafc;border:none;transition:.15s;color:var(--muted);}
.res-tab.active-redeliver{background:#dcfce7;color:#166534;}
.res-tab.active-refund{background:#dbeafe;color:#1e40af;}
.res-form{display:none;animation:fadeIn .2s ease;}
.res-form.show{display:block;}
@keyframes fadeIn{from{opacity:0;transform:translateY(-4px)}to{opacity:1;transform:translateY(0)}}
.res-label{font-size:12px;font-weight:600;color:var(--muted);text-transform:uppercase;letter-spacing:.05em;margin-bottom:6px;display:block;}
.res-input{width:100%;border:1px solid var(--border);border-radius:8px;padding:9px 12px;font-size:13px;background:#fff;margin-bottom:12px;}
.res-input:focus{outline:none;border-color:var(--primary);}
.amount-badge{display:inline-block;background:#eff6ff;color:#1e40af;padding:6px 14px;border-radius:8px;font-size:15px;font-weight:700;margin-bottom:12px;}
.cod-note{background:#fffbeb;border:1px solid #fde68a;border-radius:8px;padding:10px 12px;font-size:12px;color:#92400e;margin-bottom:12px;}

/* ── Resolved banner ── */
.resolved-banner{border-radius:12px;padding:20px;font-size:14px;display:flex;align-items:flex-start;gap:12px;}
.resolved-banner i{font-size:20px;margin-top:1px;flex-shrink:0;}
.resolved-banner.resolved{background:#f0fdf4;border:1px solid #bbf7d0;color:#166534;}
.resolved-banner.closed  {background:#fef2f2;border:1px solid #fecaca;color:#991b1b;}

@media(max-width:768px){
  .content-area{margin-left:0;padding:16px;}
  .detail-grid{grid-template-columns:1fr;}
}
</style>
</head>
<body>

<jsp:include page="/includes/adminSidebar.jsp"/>

<div class="content-area">

  <% if (singleView) { %>
    <a href="<%=request.getContextPath()%>/support" class="btn btn-outline" style="margin-bottom:16px;">
      <i class="fa fa-arrow-left"></i> All Tickets
    </a>
  <% } %>

  <div class="page-header">
    <h1>
      <i class="fa fa-headset"></i>
      <% if (singleView) { %>Ticket <%=complaint.getTicketId()%><% } else { %>Support Complaints<% } %>
    </h1>
    <p>
      <% if (singleView) { %>Review this complaint and deliver a verdict.<% }
         else { %>Manage customer support tickets.<% } %>
    </p>
  </div>

  <%-- Flash --%>
  <% if (flashMsg != null) {
       // Strip leading emoji (✅ / 🚫) so the FA icon doesn't double up
       String flashType = flashMsg.startsWith("✅") ? "success" : flashMsg.startsWith("🚫") ? "error" : "info";
       String flashIcon = flashMsg.startsWith("✅") ? "circle-check" : flashMsg.startsWith("🚫") ? "circle-xmark" : "circle-info";
       String flashText = flashMsg.replaceAll("^[✅🚫]\\s*", "");
  %>
    <div class="banner <%=flashType%>">
      <i class="fa fa-<%=flashIcon%>"></i>
      <span><%=flashText%></span>
    </div>
  <% } %>
  <% if (errorAttr != null) { %>
    <div class="banner error">
      <i class="fa fa-circle-xmark"></i>
      <span><%=errorAttr%></span>
    </div>
  <% } %>


  <%-- ═══════════════════════════════════════════════════════════
       SINGLE TICKET VIEW
       Flowchart: Staff reviews ticket (UNDER_REVIEW)
                  Track live location / Reports delivery proof
                  Staff decides outcome: Fraud or Genuine
                  Verdict → RESOLVED or CLOSED
       ═══════════════════════════════════════════════════════════ --%>
  <% if (singleView) { %>

    <%-- ── Ticket header summary ── --%>
    <div style="display:flex;align-items:center;gap:12px;margin-bottom:20px;flex-wrap:wrap;">
      <%
        String st = complaint.getStatus();
        String bc = "OPEN".equals(st)?"badge-open":"UNDER_REVIEW".equals(st)?"badge-under_review":"RESOLVED".equals(st)?"badge-resolved":"badge-closed";
      %>
      <span class="badge <%=bc%>" style="font-size:13px;padding:5px 14px;">
        <%
          switch(st){
            case "OPEN":         out.print("🟡 Open"); break;
            case "UNDER_REVIEW": out.print("🔵 Under Review"); break;
            case "RESOLVED":     out.print("✅ Resolved"); break;
            case "CLOSED":       out.print("❌ Closed"); break;
            default:             out.print(st);
          }
        %>
      </span>
      <span style="font-size:13px;color:var(--muted);">
        Raised <%=complaint.getCreatedAt() != null
          ? new java.text.SimpleDateFormat("dd MMM yyyy, h:mm a").format(complaint.getCreatedAt()) : "—"%>
      </span>
    </div>

    <%-- ── Customer + Order info ── --%>
    <div class="detail-grid">
      <div class="info-box">
        <h4><i class="fa fa-user"></i> Customer</h4>
        <div class="info-row"><span class="lbl">Name</span><span class="val"><%=complaint.getCustomerName() != null ? complaint.getCustomerName() : "—"%></span></div>
        <div class="info-row"><span class="lbl">Phone</span><span class="val"><%=complaint.getCustomerPhone() != null ? complaint.getCustomerPhone() : "—"%></span></div>
        <div class="info-row"><span class="lbl">User ID</span><span class="val">#<%=complaint.getUserId()%></span></div>
      </div>
      <div class="info-box">
        <h4><i class="fa fa-box"></i> Order Details</h4>
        <% if (complaint.getOrderId() != null) { %>
          <div class="info-row"><span class="lbl">Order ID</span><span class="val">Group #<%=linkedOrder != null ? linkedOrder.getGroupId() : complaint.getOrderId()%></span></div>
          <div class="info-row"><span class="lbl">Items</span><span class="val"><%=complaint.getOrderProducts() != null ? complaint.getOrderProducts() : "—"%></span></div>
        <% } else { %>
          <div style="color:var(--muted);font-size:13px;margin-bottom:8px;"><i class="fa fa-unlink"></i> No order linked</div>
        <% } %>
        <div class="info-row"><span class="lbl">Issue</span><span class="val"><%=complaint.getIssueType()%></span></div>
        <div class="info-row"><span class="lbl">Ticket</span><span class="val" style="color:var(--primary);font-weight:700;"><%=complaint.getTicketId()%></span></div>
      </div>
    </div>

    <%-- ── Description ── --%>
    <div class="desc-box">
      <h4><i class="fa fa-comment-dots"></i> Customer Description</h4>
      <%=complaint.getDescription() != null && !complaint.getDescription().isBlank()
        ? complaint.getDescription() : "<span style='color:var(--muted)'>No description provided.</span>"%>
    </div>

    <%-- ── Customer photo proof ── --%>
    <% if (complaint.getPhotoPath() != null && !complaint.getPhotoPath().isBlank()) { %>
    <div class="desc-box">
      <h4><i class="fa fa-image"></i> Customer Uploaded Photo</h4>
      <img src="<%=request.getContextPath()%>/<%=complaint.getPhotoPath()%>"
           alt="Complaint Photo" class="proof-img">
    </div>
    <% } %>

    <%-- ── Delivery Boy bar — GPS / OTP / photo check ── --%>
    <%-- Flowchart: "Track live location / Ping delivery boy"
                   "Reports delivery proof — OTP / photo / GPS" --%>
    <% if (complaint.getDeliveryBoyId() != null) { %>
    <div class="db-bar">
      <i class="fa fa-motorcycle"></i>
      <div class="db-info">
        <strong>Delivery Boy:</strong>
        <%=complaint.getDeliveryBoyName() != null ? complaint.getDeliveryBoyName() : "ID #"+complaint.getDeliveryBoyId()%>
        &nbsp;·&nbsp;
        <strong>Phone:</strong> <%=complaint.getDeliveryBoyPhone() != null ? complaint.getDeliveryBoyPhone() : "—"%>
      </div>
      <a href="<%=request.getContextPath()%>/Admin-live-map.jsp" target="_blank"
         class="btn btn-outline btn-sm">
        <i class="fa fa-map-location-dot"></i> Track Live Location
      </a>
    </div>
    <% } else { %>
    <div class="db-bar" style="background:#fef9c3;border-color:#fde68a;">
      <i class="fa fa-triangle-exclamation" style="color:#b45309;"></i>
      <span style="font-size:13px;color:#92400e;">No delivery boy linked to this complaint. Please assign via the order if needed.</span>
    </div>
    <% } %>

    <%-- ── Existing staff notes ── --%>
    <% if (complaint.getStaffNotes() != null && !complaint.getStaffNotes().isBlank()) { %>
    <div class="desc-box" style="border-color:#bfdbfe;background:#eff6ff;">
      <h4 style="color:#1e40af;"><i class="fa fa-note-sticky"></i> Current Staff Notes</h4>
      <div style="white-space:pre-line;"><%=complaint.getStaffNotes()%></div>
    </div>
    <% } %>

    <%-- ══════════════════════════════════════════════════════════
         ORDER NOT RECEIVED — Full Investigation Panel
         Real-life step-by-step flow shown only for this issue
         ══════════════════════════════════════════════════════════ --%>
    <% boolean isOrderNotReceived = "Order not received".equals(complaint.getIssueType()); %>
    <% boolean canAct = "OPEN".equals(complaint.getStatus()) || "UNDER_REVIEW".equals(complaint.getStatus()); %>

    <% if (isOrderNotReceived && canAct) { %>
    <div style="background:#fff;border:1px solid #e2e8f0;border-radius:14px;margin-bottom:20px;overflow:hidden;">
      <div style="background:#0f172a;padding:16px 20px;display:flex;align-items:center;gap:10px;">
        <i class="fa fa-search" style="color:#60a5fa;font-size:16px;"></i>
        <span style="color:#fff;font-weight:700;font-size:15px;">Order Not Received — Investigation Flow</span>
        <span style="margin-left:auto;background:#1e40af;color:#bfdbfe;font-size:11px;font-weight:600;padding:3px 10px;border-radius:20px;">Complete all steps before verdict</span>
      </div>

      <%-- STEP 1: Check delivery status --%>
      <div class="inv-step" id="step1">
        <div class="step-head" onclick="toggleStep('step1')">
          <div class="step-num-circle">1</div>
          <div class="step-title">Check Delivery Status in System</div>
          <div class="step-badge" id="badge-step1">Pending</div>
          <i class="fa fa-chevron-down step-chevron" id="chev-step1"></i>
        </div>
        <div class="step-body open" id="body-step1">
          <div class="step-info-grid">
            <div class="step-info-item">
              <div class="step-info-label">Order Status</div>
              <div class="step-info-value" style="color:<%=linkedOrder != null ? "#16a34a" : "#ef4444"%>;">
                <%=linkedOrder != null ? linkedOrder.getStatus() : "Order not linked"%>
              </div>
            </div>
            <div class="step-info-item">
              <div class="step-info-label">Payment Method</div>
              <div class="step-info-value"><%=linkedOrder != null ? linkedOrder.getPaymentMethod() : "—"%></div>
            </div>
            <div class="step-info-item">
              <div class="step-info-label">Order Amount</div>
              <div class="step-info-value"><%=linkedOrder != null ? "₹" + String.format("%.2f", linkedOrder.getTotal()) : "—"%></div>
            </div>
            <div class="step-info-item">
              <div class="step-info-label">Delivery Address</div>
              <div class="step-info-value"><%=linkedOrder != null && linkedOrder.getAddress() != null ? linkedOrder.getAddress() : "—"%></div>
            </div>
          </div>
          <div class="step-question">Was the order marked as "Delivered" in the system?</div>
          <div class="step-options">
            <button class="opt-btn opt-yes" onclick="markStep('step1','yes','System shows Delivered — proceeding to GPS & OTP verification')">
              ✅ Yes — marked Delivered
            </button>
            <button class="opt-btn opt-no" onclick="markStep('step1','no','System does NOT show Delivered — order may be lost in transit or mis-assigned')">
              ❌ No — not marked Delivered
            </button>
          </div>
          <div class="step-note-row">
            <input class="step-note-input" id="note-step1" placeholder="Add note for this step (optional)…">
          </div>
        </div>
      </div>

      <%-- STEP 2: GPS Check --%>
      <div class="inv-step" id="step2">
        <div class="step-head" onclick="toggleStep('step2')">
          <div class="step-num-circle">2</div>
          <div class="step-title">GPS Location Verification</div>
          <div class="step-badge" id="badge-step2">Pending</div>
          <i class="fa fa-chevron-down step-chevron" id="chev-step2"></i>
        </div>
        <div class="step-body" id="body-step2">
          <div class="step-hint">
            <i class="fa fa-location-dot" style="color:#2563eb;"></i>
            Open the live map and check if the delivery boy's GPS location matched the customer's delivery address at the time of supposed delivery.
          </div>
          <% if (complaint.getDeliveryBoyId() != null) { %>
          <a href="<%=request.getContextPath()%>/Admin-live-map.jsp" target="_blank"
             class="btn btn-primary" style="margin-bottom:14px;font-size:13px;">
            <i class="fa fa-map-location-dot"></i> Open Live GPS Map
          </a>
          <% } else { %>
          <div class="step-hint" style="background:#fef9c3;border-color:#fde68a;color:#92400e;">
            <i class="fa fa-triangle-exclamation"></i> No delivery boy linked — GPS check not possible. Note this in findings.
          </div>
          <% } %>
          <div class="step-question">Did the delivery boy's GPS reach the customer's delivery address?</div>
          <div class="step-options">
            <button class="opt-btn opt-yes" onclick="markStep('step2','yes','GPS confirms delivery boy reached customer address')">
              ✅ Yes — GPS confirms location reached
            </button>
            <button class="opt-btn opt-no" onclick="markStep('step2','no','GPS shows delivery boy did NOT reach customer address')">
              ❌ No — GPS shows different location
            </button>
            <button class="opt-btn opt-warn" onclick="markStep('step2','warn','GPS data unavailable or inconclusive')">
              ⚠️ GPS data unavailable
            </button>
          </div>
          <div class="step-note-row">
            <input class="step-note-input" id="note-step2" placeholder="Note GPS coordinates or discrepancy details…">
          </div>
        </div>
      </div>

      <%-- STEP 3: OTP Check --%>
      <div class="inv-step" id="step3">
        <div class="step-head" onclick="toggleStep('step3')">
          <div class="step-num-circle">3</div>
          <div class="step-title">OTP Verification Check</div>
          <div class="step-badge" id="badge-step3">Pending</div>
          <i class="fa fa-chevron-down step-chevron" id="chev-step3"></i>
        </div>
        <div class="step-body" id="body-step3">
          <div class="step-hint">
            <i class="fa fa-key" style="color:#2563eb;"></i>
            Check in the system whether the delivery OTP was entered and confirmed by the delivery boy. OTP confirmation = customer was physically present and received the order.
          </div>
          <div class="step-question">Was the delivery OTP entered and confirmed?</div>
          <div class="step-options">
            <button class="opt-btn opt-yes" onclick="markStep('step3','yes','OTP was confirmed — delivery boy claims handover happened')">
              ✅ Yes — OTP confirmed
            </button>
            <button class="opt-btn opt-no" onclick="markStep('step3','no','OTP was NOT entered — no proof of delivery handover')">
              ❌ No — OTP not entered
            </button>
            <button class="opt-btn opt-warn" onclick="markStep('step3','warn','OTP system data not available')">
              ⚠️ OTP data unavailable
            </button>
          </div>
          <div class="step-note-row">
            <input class="step-note-input" id="note-step3" placeholder="Note OTP status or timestamp if available…">
          </div>
        </div>
      </div>

      <%-- STEP 4: Contact Delivery Boy --%>
      <div class="inv-step" id="step4">
        <div class="step-head" onclick="toggleStep('step4')">
          <div class="step-num-circle">4</div>
          <div class="step-title">Contact Delivery Boy</div>
          <div class="step-badge" id="badge-step4">Pending</div>
          <i class="fa fa-chevron-down step-chevron" id="chev-step4"></i>
        </div>
        <div class="step-body" id="body-step4">
          <% if (complaint.getDeliveryBoyId() != null) { %>
          <div class="step-info-grid">
            <div class="step-info-item">
              <div class="step-info-label">Delivery Boy</div>
              <div class="step-info-value"><%=complaint.getDeliveryBoyName() != null ? complaint.getDeliveryBoyName() : "ID #"+complaint.getDeliveryBoyId()%></div>
            </div>
            <div class="step-info-item">
              <div class="step-info-label">Phone</div>
              <div class="step-info-value" style="color:#2563eb;font-weight:700;">
                <a href="tel:<%=complaint.getDeliveryBoyPhone()%>" style="color:#2563eb;">
                  <i class="fa fa-phone"></i> <%=complaint.getDeliveryBoyPhone() != null ? complaint.getDeliveryBoyPhone() : "—"%>
                </a>
              </div>
            </div>
          </div>
          <% } else { %>
          <div class="step-hint" style="background:#fef9c3;border-color:#fde68a;color:#92400e;">
            <i class="fa fa-triangle-exclamation"></i> No delivery boy linked to this ticket. Assign one via the order page first.
          </div>
          <% } %>
          <div class="step-hint" style="margin-top:10px;">
            <i class="fa fa-phone" style="color:#2563eb;"></i>
            Ask: Did you deliver to <strong><%=complaint.getCustomerName() != null ? complaint.getCustomerName() : "this customer"%></strong>?
            Did they answer the door? Did you hand the parcel to someone else? Did you leave it at the door?
          </div>
          <div class="step-question">What did the delivery boy say?</div>
          <div class="step-options">
            <button class="opt-btn opt-yes" onclick="markStep('step4','yes','Delivery boy confirms he delivered and customer received it')">
              ✅ Claims he delivered to customer directly
            </button>
            <button class="opt-btn opt-warn" onclick="markStep('step4','warn','Delivery boy says left at door / given to neighbour / no answer')">
              ⚠️ Left at door / neighbour / no answer
            </button>
            <button class="opt-btn opt-no" onclick="markStep('step4','no','Delivery boy admits non-delivery or unreachable')">
              ❌ Admits non-delivery / unreachable
            </button>
          </div>
          <div class="step-note-row">
            <input class="step-note-input" id="note-step4" placeholder="Record exactly what the delivery boy said…">
          </div>
        </div>
      </div>

      <%-- STEP 5: Contact Customer --%>
      <div class="inv-step" id="step5">
        <div class="step-head" onclick="toggleStep('step5')">
          <div class="step-num-circle">5</div>
          <div class="step-title">Contact Customer for Clarification</div>
          <div class="step-badge" id="badge-step5">Pending</div>
          <i class="fa fa-chevron-down step-chevron" id="chev-step5"></i>
        </div>
        <div class="step-body" id="body-step5">
          <div class="step-info-grid">
            <div class="step-info-item">
              <div class="step-info-label">Customer</div>
              <div class="step-info-value"><%=complaint.getCustomerName() != null ? complaint.getCustomerName() : "—"%></div>
            </div>
            <div class="step-info-item">
              <div class="step-info-label">Phone</div>
              <div class="step-info-value" style="color:#2563eb;font-weight:700;">
                <a href="tel:<%=complaint.getCustomerPhone()%>" style="color:#2563eb;">
                  <i class="fa fa-phone"></i> <%=complaint.getCustomerPhone() != null ? complaint.getCustomerPhone() : "—"%>
                </a>
              </div>
            </div>
          </div>
          <div class="step-hint">
            <i class="fa fa-phone" style="color:#2563eb;"></i>
            Ask: Were you home at the time? Did you check with neighbours? Did anyone else at home receive it? Did the delivery boy call you?
          </div>
          <div class="step-question">What did the customer say?</div>
          <div class="step-options">
            <button class="opt-btn opt-no" onclick="markStep('step5','no','Customer confirms was home, no delivery received, no contact from delivery boy')">
              ✅ Was home, never received, no call
            </button>
            <button class="opt-btn opt-warn" onclick="markStep('step5','warn','Customer was not home / neighbour may have received')">
              ⚠️ Was not home / checking with neighbours
            </button>
            <button class="opt-btn opt-yes" onclick="markStep('step5','yes','Customer found the parcel after all — complaint withdrawn')">
              ✅ Found the parcel — complaint resolved
            </button>
          </div>
          <div class="step-note-row">
            <input class="step-note-input" id="note-step5" placeholder="Record what the customer said…">
          </div>
        </div>
      </div>

      <%-- STEP 6: Final Investigation Summary & Verdict --%>
      <div class="inv-step" id="step6" style="border-bottom:none;">
        <div class="step-head" onclick="toggleStep('step6')">
          <div class="step-num-circle" style="background:#9a3412;">6</div>
          <div class="step-title">Final Summary & Verdict</div>
          <div class="step-badge" id="badge-step6">Pending</div>
          <i class="fa fa-chevron-down step-chevron" id="chev-step6"></i>
        </div>
        <div class="step-body" id="body-step6">
          <div class="step-hint" id="auto-summary" style="background:#f0f9ff;border-color:#bae6fd;color:#0c4a6e;white-space:pre-line;font-family:monospace;font-size:12px;">
            Complete the steps above — a summary will appear here automatically.
          </div>
          <div class="step-question">Verdict based on investigation:</div>
          <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px;margin-bottom:16px;">
            <div class="verdict-card" onclick="selectVerdict('genuine')" id="vc-genuine">
              <div style="font-size:20px;margin-bottom:6px;">✅</div>
              <div style="font-weight:700;color:#166534;font-size:13px;">Genuine Complaint</div>
              <div style="font-size:11px;color:#16a34a;margin-top:4px;">Customer did not receive — delivery boy fault or lost parcel</div>
            </div>
            <div class="verdict-card" onclick="selectVerdict('fraud')" id="vc-fraud">
              <div style="font-size:20px;margin-bottom:6px;">❌</div>
              <div style="font-weight:700;color:#991b1b;font-size:13px;">False Complaint</div>
              <div style="font-size:11px;color:#ef4444;margin-top:4px;">Evidence shows delivery was made — customer received the order</div>
            </div>
          </div>

          <%-- Resolution options shown after Genuine --%>
          <div id="genuine-resolution" style="display:none;background:#f0fdf4;border:1px solid #bbf7d0;border-radius:10px;padding:16px;margin-bottom:14px;">
            <div style="font-weight:700;color:#166534;font-size:13px;margin-bottom:12px;"><i class="fa fa-circle-check"></i> Genuine — How to resolve?</div>
            <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px;margin-bottom:14px;">
              <div class="verdict-card" onclick="selectResolution('redeliver')" id="rc-redeliver" style="border-color:#bbf7d0;">
                <div style="font-size:18px;margin-bottom:4px;">🚚</div>
                <div style="font-weight:700;font-size:13px;color:#166534;">Re-deliver</div>
                <div style="font-size:11px;color:#16a34a;margin-top:2px;">Assign delivery boy & send again</div>
              </div>
              <div class="verdict-card" onclick="selectResolution('refund')" id="rc-refund" style="border-color:#bbf7d0;">
                <div style="font-size:18px;margin-bottom:4px;">💰</div>
                <div style="font-weight:700;font-size:13px;color:#1e40af;">Refund</div>
                <div style="font-size:11px;color:#2563eb;margin-top:2px;">Return money to customer</div>
              </div>
            </div>

            <%-- Re-deliver form --%>
            <div id="form-redeliver" style="display:none;">
              <form action="<%=request.getContextPath()%>/support" method="post"
                    onsubmit="return buildFinalNotes(this) && confirm('Re-deliver this order?')">
                <input type="hidden" name="action" value="verdict">
                <input type="hidden" name="id" value="<%=complaint.getId()%>">
                <input type="hidden" name="verdict" value="GENUINE">
                <input type="hidden" name="resolution" value="REDELIVER">
                <input type="hidden" name="staffNotes" id="rdNotes">
                <label class="res-label" style="margin-top:10px;">Assign Delivery Boy</label>
                <select name="deliveryBoyId" class="res-input">
                  <option value="">— Select delivery boy —</option>
                  <% if (deliveryBoys != null) { for (DeliveryBoy db : deliveryBoys) { %>
                    <option value="<%=db.getId()%>"><%=db.getName()%> — <%=db.getPhone()%><% if ("ACTIVE".equals(db.getStatus()) || db.isOnline()) out.print(" ✅"); %></option>
                  <% } } %>
                </select>
                <label class="res-label">Delivery Address</label>
                <input type="text" name="redeliverAddress" class="res-input"
                       value="<%=linkedOrder != null && linkedOrder.getAddress() != null ? linkedOrder.getAddress() : ""%>"
                       placeholder="Leave blank to keep original address">
                <label class="res-label">Penalty for Delivery Boy?</label>
                <select name="deliveryPenalty" class="res-input">
                  <option value="none">No penalty</option>
                  <option value="warning">Formal warning issued</option>
                  <option value="fine">Fine deducted from earnings</option>
                </select>
                <button type="submit" class="btn btn-success" style="width:100%;margin-top:4px;">
                  <i class="fa fa-motorcycle"></i> Confirm Re-delivery & Close Ticket
                </button>
              </form>
            </div>

            <%-- Refund form --%>
            <div id="form-refund" style="display:none;">
              <form action="<%=request.getContextPath()%>/support" method="post"
                    onsubmit="return buildFinalNotes(this) && confirm('Process refund?')">
                <input type="hidden" name="action" value="verdict">
                <input type="hidden" name="id" value="<%=complaint.getId()%>">
                <input type="hidden" name="verdict" value="GENUINE">
                <input type="hidden" name="resolution" value="REFUND">
                <input type="hidden" name="staffNotes" id="rfNotes">
                <% if (linkedOrder != null) { %>
                  <div style="margin:10px 0 6px;font-size:12px;color:var(--muted);text-transform:uppercase;font-weight:600;letter-spacing:.05em;">Refund Amount</div>
                  <div class="amount-badge">₹<%=String.format("%.2f", linkedOrder.getTotal())%></div>
                  <% if ("COD".equalsIgnoreCase(linkedOrder.getPaymentMethod())) { %>
                    <div class="cod-note" style="margin-top:10px;"><i class="fa fa-coins"></i> <strong>COD Order</strong> — issue cash refund of ₹<%=String.format("%.2f", linkedOrder.getTotal())%> to customer manually.</div>
                  <% } else if (linkedPayment != null) { %>
                    <div style="font-size:12px;color:var(--muted);margin:10px 0;">Payment: <strong><%=linkedOrder.getPaymentMethod()%></strong> · Razorpay ID: <code><%=linkedPayment.getRazorpayPaymentId() != null ? linkedPayment.getRazorpayPaymentId() : "—"%></code></div>
                  <% } %>
                <% } %>
                <label class="res-label" style="margin-top:10px;">Penalty for Delivery Boy?</label>
                <select name="deliveryPenalty" class="res-input">
                  <option value="none">No penalty</option>
                  <option value="warning">Formal warning issued</option>
                  <option value="fine">Fine deducted from earnings</option>
                </select>
                <button type="submit" class="btn btn-primary" style="width:100%;margin-top:4px;">
                  <i class="fa fa-rotate-left"></i> Confirm Refund & Close Ticket
                </button>
              </form>
            </div>
          </div>

          <%-- False complaint form --%>
          <div id="fraud-resolution" style="display:none;background:#fef2f2;border:1px solid #fecaca;border-radius:10px;padding:16px;margin-bottom:14px;">
            <div style="font-weight:700;color:#991b1b;font-size:13px;margin-bottom:10px;"><i class="fa fa-circle-xmark"></i> False Complaint — Reject & Close</div>
            <div style="font-size:12px;color:#dc2626;margin-bottom:12px;">Evidence shows the order was delivered. The complaint will be closed and customer notified.</div>
            <form action="<%=request.getContextPath()%>/support" method="post"
                  onsubmit="return buildFinalNotes(this) && confirm('Close this ticket as a false complaint?')">
              <input type="hidden" name="action" value="verdict">
              <input type="hidden" name="id" value="<%=complaint.getId()%>">
              <input type="hidden" name="verdict" value="FRAUD">
              <input type="hidden" name="staffNotes" id="frNotes">
              <button type="submit" class="btn btn-danger" style="width:100%;">
                <i class="fa fa-circle-xmark"></i> Reject & Close Ticket
              </button>
            </form>
          </div>

          <%-- Shared final notes --%>
          <label style="font-size:12px;font-weight:600;color:var(--muted);text-transform:uppercase;letter-spacing:.05em;display:block;margin-bottom:6px;">
            Final Investigation Summary (required before submitting)
          </label>
          <textarea id="finalNotes" style="width:100%;border:1px solid #fed7aa;border-radius:8px;padding:10px 12px;font-size:13px;resize:vertical;min-height:100px;font-family:inherit;background:#fff8f1;"
                    placeholder="Summarise findings — GPS result, OTP status, delivery boy statement, customer statement, conclusion…"><%=complaint.getStaffNotes() != null ? complaint.getStaffNotes() : ""%></textarea>
        </div>
      </div>
    </div>

    <%-- CSS for the investigation panel --%>
    <style>
    .inv-step{border-bottom:1px solid #e2e8f0;}
    .step-head{display:flex;align-items:center;gap:12px;padding:14px 20px;cursor:pointer;user-select:none;}
    .step-head:hover{background:#f8fafc;}
    .step-num-circle{width:28px;height:28px;border-radius:50%;background:#2563eb;color:#fff;font-size:12px;font-weight:700;display:flex;align-items:center;justify-content:center;flex-shrink:0;}
    .step-title{flex:1;font-weight:600;font-size:14px;color:#0f172a;}
    .step-badge{font-size:11px;font-weight:700;padding:3px 10px;border-radius:20px;background:#f1f5f9;color:#64748b;white-space:nowrap;}
    .step-badge.done-yes{background:#dcfce7;color:#166534;}
    .step-badge.done-no{background:#fee2e2;color:#991b1b;}
    .step-badge.done-warn{background:#fef9c3;color:#854d0e;}
    .step-chevron{color:#94a3b8;transition:transform .2s;font-size:13px;}
    .step-chevron.open{transform:rotate(180deg);}
    .step-body{display:none;padding:0 20px 18px 60px;}
    .step-body.open{display:block;}
    .step-hint{background:#eff6ff;border:1px solid #bfdbfe;border-radius:8px;padding:10px 14px;font-size:13px;color:#1e40af;margin-bottom:14px;display:flex;align-items:flex-start;gap:8px;line-height:1.6;}
    .step-info-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(160px,1fr));gap:10px;margin-bottom:14px;}
    .step-info-item{background:#f8fafc;border:1px solid #e2e8f0;border-radius:8px;padding:10px 12px;}
    .step-info-label{font-size:11px;color:#64748b;font-weight:600;text-transform:uppercase;letter-spacing:.04em;margin-bottom:4px;}
    .step-info-value{font-size:13px;font-weight:600;color:#0f172a;}
    .step-question{font-size:13px;font-weight:600;color:#0f172a;margin-bottom:10px;}
    .step-options{display:flex;flex-wrap:wrap;gap:8px;margin-bottom:12px;}
    .opt-btn{padding:8px 14px;border-radius:8px;border:1.5px solid;font-size:13px;font-weight:600;cursor:pointer;transition:.15s;}
    .opt-btn:hover{filter:brightness(.95);}
    .opt-yes{background:#f0fdf4;border-color:#86efac;color:#166534;}
    .opt-yes.selected{background:#dcfce7;border-color:#16a34a;}
    .opt-no{background:#fef2f2;border-color:#fca5a5;color:#991b1b;}
    .opt-no.selected{background:#fee2e2;border-color:#ef4444;}
    .opt-warn{background:#fffbeb;border-color:#fcd34d;color:#854d0e;}
    .opt-warn.selected{background:#fef9c3;border-color:#f59e0b;}
    .step-note-row{margin-top:4px;}
    .step-note-input{width:100%;border:1px solid #e2e8f0;border-radius:8px;padding:8px 12px;font-size:13px;font-family:inherit;background:#fff;color:#0f172a;}
    .step-note-input:focus{outline:none;border-color:#2563eb;}
    .verdict-card{border:1.5px solid #e2e8f0;border-radius:10px;padding:14px;text-align:center;cursor:pointer;transition:.15s;background:#fff;}
    .verdict-card:hover{background:#f8fafc;}
    .verdict-card.selected-genuine{border-color:#16a34a;background:#f0fdf4;}
    .verdict-card.selected-fraud{border-color:#ef4444;background:#fef2f2;}
    .verdict-card.selected-res{border-color:#2563eb;background:#eff6ff;}
    </style>

    <script>
    var stepResults = {};

    function toggleStep(id) {
      var body = document.getElementById('body-' + id);
      var chev = document.getElementById('chev-' + id);
      var open = body.classList.contains('open');
      body.classList.toggle('open', !open);
      chev.classList.toggle('open', !open);
    }

    function markStep(stepId, result, autoNote) {
      stepResults[stepId] = { result: result, note: autoNote };
      var badge = document.getElementById('badge-' + stepId);
      badge.className = 'step-badge done-' + result;
      badge.textContent = result === 'yes' ? '✓ Done' : result === 'no' ? '✗ Issue Found' : '⚠ Note Recorded';
      document.querySelectorAll('#body-' + stepId + ' .opt-btn').forEach(function(b){ b.classList.remove('selected'); });
      event.target.classList.add('selected');
      updateAutoSummary();
      // auto-advance to next step
      var steps = ['step1','step2','step3','step4','step5','step6'];
      var idx = steps.indexOf(stepId);
      if (idx >= 0 && idx < steps.length - 1) {
        var next = steps[idx + 1];
        document.getElementById('body-' + next).classList.add('open');
        document.getElementById('chev-' + next).classList.add('open');
        document.getElementById('body-' + stepId).classList.remove('open');
        document.getElementById('chev-' + stepId).classList.remove('open');
      }
    }

    function updateAutoSummary() {
      var lines = [];
      var labels = {
        step1: 'Delivery status in system',
        step2: 'GPS verification',
        step3: 'OTP check',
        step4: 'Delivery boy statement',
        step5: 'Customer statement'
      };
      for (var s in labels) {
        if (stepResults[s]) {
          var icon = stepResults[s].result === 'yes' ? '✅' : stepResults[s].result === 'no' ? '❌' : '⚠️';
          var extra = document.getElementById('note-' + s) ? document.getElementById('note-' + s).value : '';
          lines.push(icon + ' ' + labels[s] + ': ' + stepResults[s].note + (extra ? ' — ' + extra : ''));
        }
      }
      var box = document.getElementById('auto-summary');
      box.textContent = lines.length ? lines.join('\n') : 'Complete the steps above — a summary will appear here automatically.';
      document.getElementById('finalNotes').value = lines.join('\n');
    }

    function selectVerdict(v) {
      document.getElementById('vc-genuine').className = 'verdict-card' + (v==='genuine'?' selected-genuine':'');
      document.getElementById('vc-fraud').className   = 'verdict-card' + (v==='fraud'?' selected-fraud':'');
      document.getElementById('genuine-resolution').style.display = v==='genuine' ? 'block' : 'none';
      document.getElementById('fraud-resolution').style.display   = v==='fraud'   ? 'block' : 'none';
    }

    function selectResolution(r) {
      document.getElementById('rc-redeliver').className = 'verdict-card' + (r==='redeliver'?' selected-res':'');
      document.getElementById('rc-refund').className    = 'verdict-card' + (r==='refund'?' selected-res':'');
      document.getElementById('form-redeliver').style.display = r==='redeliver' ? 'block' : 'none';
      document.getElementById('form-refund').style.display    = r==='refund'    ? 'block' : 'none';
    }

    function buildFinalNotes(form) {
      updateAutoSummary();
      var notes = document.getElementById('finalNotes').value.trim();
      if (!notes) { alert('Please complete the investigation steps and add final notes before submitting.'); return false; }
      var targets = ['rdNotes','rfNotes','frNotes'];
      targets.forEach(function(id){ var el = document.getElementById(id); if(el) el.value = notes; });
      return true;
    }
    </script>

    <% } /* end isOrderNotReceived */ %>

    <% if (canAct) { %>

      <%-- ── INVESTIGATION NOTES — hidden for Order not received (has own panel above) ── --%>
      <% if (!isOrderNotReceived) { %>
      <div class="review-section">
        <h3><i class="fa fa-magnifying-glass"></i> Investigation Notes</h3>
        <form action="<%=request.getContextPath()%>/support" method="post">
          <input type="hidden" name="action" value="review">
          <input type="hidden" name="id" value="<%=complaint.getId()%>">
          <%
            String notesPlaceholder;
            String issueTypeNotes = complaint.getIssueType() != null ? complaint.getIssueType().trim() : "";
            switch (issueTypeNotes) {
              case "Late delivery":
                notesPlaceholder = "Record notes — GPS coordinates checked, OTP status, delivery boy contacted, reason for delay, customer availability…";
                break;
              case "Wrong item delivered":
                notesPlaceholder = "Record notes — Customer photo reviewed, warehouse packing record checked, delivery boy confirmed pickup item, swap error investigated…";
                break;
              case "Damaged item":
                notesPlaceholder = "Record notes — Damage photos reviewed, packaging quality assessed, delivery handling checked, warehouse condition at dispatch…";
                break;
              case "Order not received":
                notesPlaceholder = "Record notes — GPS location verified, OTP entry status, delivery attempt confirmed, neighbour/safe-place check, delivery boy statement…";
                break;
              case "Payment issue":
                notesPlaceholder = "Record notes — Payment gateway logs checked, duplicate charge verified, Razorpay transaction ID, bank confirmation, order status cross-checked…";
                break;
              default:
                notesPlaceholder = "Record investigation notes — evidence reviewed, contacts made, findings documented…";
                break;
            }
          %>
          <textarea name="staffNotes"
                    placeholder="<%=notesPlaceholder%>"><%=complaint.getStaffNotes() != null ? complaint.getStaffNotes() : ""%></textarea>
          <div style="margin-top:10px;">
            <button type="submit" class="btn btn-primary">
              <i class="fa fa-floppy-disk"></i> Save Notes (keep Under Review)
            </button>
          </div>
        </form>
      </div>

      <%-- ── VERDICT: Genuine or Fraud ── --%>
      <%-- Flowchart: GENUINE → RESOLVED + Re-deliver OR Refund
                      FRAUD   → CLOSED  + Customer notified --%>
      <div class="verdict-section">
        <h3><i class="fa fa-gavel"></i> Deliver Final Verdict</h3>
        <%
          String issueType = complaint.getIssueType() != null ? complaint.getIssueType().trim() : "";
          String verdictGuide;
          String verdictChecklist;
          switch (issueType) {
            case "Late delivery":
              verdictGuide = "After checking GPS coordinates, OTP confirmation &amp; delivery proof photo — choose one:";
              verdictChecklist = "✅ Verify GPS logs — did the delivery boy reach the customer's area on time?<br>"
                + "✅ Check OTP — was delivery confirmed or attempted?<br>"
                + "✅ Contact delivery boy — traffic, wrong address, or unavailable customer?<br>"
                + "✅ Check promised delivery time vs actual arrival time.";
              break;
            case "Wrong item delivered":
              verdictGuide = "After verifying customer's photo evidence, checking warehouse packing records &amp; delivery boy's pickup confirmation — choose one:";
              verdictChecklist = "✅ Review customer's uploaded photo of the wrong item.<br>"
                + "✅ Check warehouse packing record for this order — what was packed?<br>"
                + "✅ Confirm with delivery boy — did they pick up the right parcel?<br>"
                + "✅ Check if another customer received this customer's order (swap error).";
              break;
            case "Damaged item":
              verdictGuide = "After reviewing damage photos, checking packaging quality &amp; courier handling records — choose one:";
              verdictChecklist = "✅ Review customer's damage photos carefully.<br>"
                + "✅ Check if packaging was adequate (fragile items labelled?).<br>"
                + "✅ Check delivery boy's handling — any reported drops or incidents?<br>"
                + "✅ Confirm item was in good condition at warehouse before dispatch.";
              break;
            case "Order not received":
              verdictGuide = "After checking GPS location proof, OTP status &amp; delivery attempt logs — choose one:";
              verdictChecklist = "✅ Check GPS — did the delivery boy reach the delivery address?<br>"
                + "✅ Check OTP — was it entered (proof of handover) or skipped?<br>"
                + "✅ Check if parcel was left with a neighbour or at the door.<br>"
                + "✅ Contact delivery boy — confirm delivery attempt details.";
              break;
            case "Payment issue":
              verdictGuide = "After verifying transaction records, bank confirmation &amp; order payment status — choose one:";
              verdictChecklist = "✅ Check payment gateway logs — was the payment captured successfully?<br>"
                + "✅ Verify if double charge occurred (check Razorpay / bank records).<br>"
                + "✅ Confirm order status — was order placed despite payment failure?<br>"
                + "✅ Cross-check customer's bank statement reference with our records.";
              break;
            default:
              verdictGuide = "After thoroughly investigating the customer's complaint — choose one:";
              verdictChecklist = "✅ Review all customer-provided evidence and description.<br>"
                + "✅ Contact the customer for any missing information if needed.<br>"
                + "✅ Check order history, delivery records, and payment status.<br>"
                + "✅ Document all findings in the investigation notes above.";
              break;
          }
        %>
        <p><%=verdictGuide%></p>
        <div style="background:#fff8f1;border:1px solid #fed7aa;border-radius:8px;padding:12px 14px;margin-bottom:14px;font-size:13px;line-height:2;color:#92400e;">
          <%=verdictChecklist%>
        </div>

        <%-- Shared notes textarea (used by both paths) --%>
        <textarea id="sharedNotes" style="width:100%;border:1px solid #fed7aa;border-radius:8px;
                  padding:10px 12px;font-size:13px;resize:vertical;min-height:80px;
                  font-family:inherit;background:#fff8f1;margin-bottom:14px;"
                  placeholder="Final verdict notes — what evidence led to this decision (required)…"
                  ><%=complaint.getStaffNotes() != null ? complaint.getStaffNotes() : ""%></textarea>

        <%-- Step 1: choose verdict --%>
        <div class="verdict-buttons" id="verdictBtns">
          <%-- GENUINE: reveals resolution panel --%>
          <button type="button" class="btn btn-success" id="genuineBtn"
                  onclick="showResolution()">
            <i class="fa fa-circle-check"></i> Genuine — Resolve
          </button>
          <%-- FRAUD: submits directly --%>
          <form action="<%=request.getContextPath()%>/support" method="post" style="display:inline;"
                onsubmit="return copyNotes(this) && confirm('Mark as FRAUD? Ticket will be CLOSED and customer notified.')">
            <input type="hidden" name="action"  value="verdict">
            <input type="hidden" name="id"      value="<%=complaint.getId()%>">
            <input type="hidden" name="verdict" value="FRAUD">
            <input type="hidden" name="staffNotes" id="fraudNotes">
            <button type="submit" class="btn btn-danger">
              <i class="fa fa-circle-xmark"></i> Fraud — Reject &amp; Close
            </button>
          </form>
        </div>

        <%-- Step 2: Resolution panel (revealed when Genuine clicked) --%>
        <div class="resolution-panel" id="resPanel">
          <div style="font-size:13px;font-weight:600;color:#166534;margin-bottom:12px;">
            <i class="fa fa-circle-check" style="margin-right:6px;"></i>
            Marked as Genuine — how would you like to resolve this?
          </div>

          <%-- Toggle tabs --%>
          <%-- Wrong item delivered: show Pickup Return tab instead of Re-deliver --%>
          <% boolean isWrongItem = "Wrong item delivered".equals(complaint.getIssueType()); %>
          <div class="res-tabs">
            <% if (!isWrongItem) { %>
            <button type="button" class="res-tab active-redeliver" id="tabRedeliver"
                    onclick="switchTab('redeliver')">
              🚚 Re-deliver
            </button>
            <% } else { %>
            <button type="button" class="res-tab active-redeliver" id="tabPickup"
                    onclick="switchTab('pickup')">
              📦 Schedule Return Pickup
            </button>
            <% } %>
            <button type="button" class="res-tab" id="tabRefund"
                    onclick="switchTab('refund')">
              💰 Refund
            </button>
          </div>

          <%-- PICKUP RETURN form — shown only for Wrong item delivered --%>
          <div class="res-form <%= isWrongItem ? "show" : "" %>" id="formPickup">
            <div style="background:#fff7ed;border:1px solid #fed7aa;border-radius:8px;padding:12px 14px;margin-bottom:14px;font-size:13px;color:#92400e;">
              <i class="fa fa-circle-info"></i>
              <strong>Wrong item return process:</strong><br>
              1. Return request auto-create + approve avutundi<br>
              2. Meeru pickup date &amp; slot choose cheyandi<br>
              3. Customer ki pickup scheduled notification vasthundi
            </div>
            <form action="<%=request.getContextPath()%>/support" method="post"
                  onsubmit="return copyNotes(this) && confirm('Wrong item return create chesి pickup schedule cheyalaa?')">
              <input type="hidden" name="action"     value="verdict">
              <input type="hidden" name="id"         value="<%=complaint.getId()%>">
              <input type="hidden" name="verdict"    value="GENUINE">
              <input type="hidden" name="resolution" value="PICKUP_RETURN">
              <input type="hidden" name="staffNotes" class="notesCopy">
              <button type="submit" class="btn btn-success" style="width:100%;">
                <i class="fa fa-box"></i> Confirm — Create Return &amp; Schedule Pickup
              </button>
            </form>
          </div>

          <%-- RE-DELIVER form --%>
          <div class="res-form <%= !isWrongItem ? "show" : "" %>" id="formRedeliver">
            <form action="<%=request.getContextPath()%>/support" method="post"
                  onsubmit="return copyNotes(this) && confirm('Re-deliver this order?')">
              <input type="hidden" name="action"     value="verdict">
              <input type="hidden" name="id"         value="<%=complaint.getId()%>">
              <input type="hidden" name="verdict"    value="GENUINE">
              <input type="hidden" name="resolution" value="REDELIVER">
              <input type="hidden" name="staffNotes" class="notesCopy">

              <label class="res-label">Assign Delivery Boy</label>
              <select name="deliveryBoyId" class="res-input">
                <option value="">— Select delivery boy —</option>
                <% if (deliveryBoys != null) {
                     for (DeliveryBoy db : deliveryBoys) { %>
                  <option value="<%=db.getId()%>">
                    <%=db.getName()%> — <%=db.getPhone()%>
                    <% if ("ACTIVE".equals(db.getStatus()) || db.isOnline()) out.print(" ✅"); %>
                  </option>
                <% } } %>
              </select>

              <label class="res-label">Delivery Address</label>
              <input type="text" name="redeliverAddress" class="res-input"
                     placeholder="Enter delivery address (leave blank to keep original)"
                     value="<%=linkedOrder != null && linkedOrder.getAddress() != null ? linkedOrder.getAddress() : ""%>">

              <button type="submit" class="btn btn-success" style="width:100%;">
                <i class="fa fa-motorcycle"></i> Confirm Re-delivery
              </button>
            </form>
          </div>

          <%-- REFUND form --%>
          <div class="res-form" id="formRefund">
            <form action="<%=request.getContextPath()%>/support" method="post"
                  onsubmit="return copyNotes(this) && confirm('Process refund?')">
              <input type="hidden" name="action"     value="verdict">
              <input type="hidden" name="id"         value="<%=complaint.getId()%>">
              <input type="hidden" name="verdict"    value="GENUINE">
              <input type="hidden" name="resolution" value="REFUND">
              <input type="hidden" name="staffNotes" class="notesCopy">

              <% if (linkedOrder != null) { %>
                <label class="res-label">Refund Amount</label>
                <div class="amount-badge">₹<%=String.format("%.2f", linkedOrder.getTotal())%></div>

                <% if ("COD".equalsIgnoreCase(linkedOrder.getPaymentMethod())) { %>
                  <div class="cod-note">
                    <i class="fa fa-coins"></i> <strong>COD Order</strong> — no online payment to reverse.
                    The system will remind you to issue a cash refund of
                    ₹<%=String.format("%.2f", linkedOrder.getTotal())%> to the customer.
                  </div>
                <% } else if (linkedPayment != null) { %>
                  <div style="font-size:12px;color:var(--muted);margin-bottom:12px;">
                    Payment method: <strong><%=linkedOrder.getPaymentMethod()%></strong>
                    &nbsp;·&nbsp; Razorpay ID: <code><%=linkedPayment.getRazorpayPaymentId() != null ? linkedPayment.getRazorpayPaymentId() : "—"%></code>
                  </div>
                <% } %>
              <% } else { %>
                <div style="font-size:13px;color:var(--muted);margin-bottom:12px;">
                  No order linked — refund must be processed manually.
                </div>
              <% } %>

              <button type="submit" class="btn btn-primary" style="width:100%;">
                <i class="fa fa-rotate-left"></i> Confirm Refund
              </button>
            </form>
          </div>

          <div style="margin-top:12px;text-align:center;">
            <button type="button" class="btn btn-outline btn-sm" onclick="hideResolution()">
              <i class="fa fa-arrow-left"></i> Back
            </button>
          </div>
        </div>
      </div>

      <script>
        function showResolution() {
          const notes = document.getElementById('sharedNotes').value.trim();
          if (!notes) { alert('Please enter verdict notes before proceeding.'); return; }
          document.getElementById('verdictBtns').style.display = 'none';
          document.getElementById('resPanel').classList.add('show');
        }
        function hideResolution() {
          document.getElementById('verdictBtns').style.display = '';
          document.getElementById('resPanel').classList.remove('show');
        }
        function switchTab(tab) {
          var fPickup    = document.getElementById('formPickup');
          var fRedeliver = document.getElementById('formRedeliver');
          var fRefund    = document.getElementById('formRefund');
          var tPickup    = document.getElementById('tabPickup');
          var tRedeliver = document.getElementById('tabRedeliver');
          if (fPickup)    fPickup.classList.toggle('show',    tab === 'pickup');
          if (fRedeliver) fRedeliver.classList.toggle('show', tab === 'redeliver');
          if (fRefund)    fRefund.classList.toggle('show',    tab === 'refund');
          if (tPickup)    tPickup.className    = 'res-tab' + (tab==='pickup'    ? ' active-redeliver' : '');
          if (tRedeliver) tRedeliver.className = 'res-tab' + (tab==='redeliver' ? ' active-redeliver' : '');
          document.getElementById('tabRefund').className     = 'res-tab' + (tab==='refund'    ? ' active-refund'    : '');
        }
        function copyNotes(form) {
          const notes = document.getElementById('sharedNotes').value.trim();
          if (!notes) { alert('Please enter verdict notes.'); return false; }
          form.querySelectorAll('.notesCopy, #fraudNotes').forEach(function(el){ el.value = notes; });
          return true;
        }
      </script>

      <% } /* end !isOrderNotReceived */ %>

    <% } else { %>
      <div class="resolved-banner <%="RESOLVED".equals(complaint.getStatus()) ? "resolved" : "closed"%>">
        <i class="fa fa-<%="RESOLVED".equals(complaint.getStatus()) ? "circle-check" : "circle-xmark"%>"></i>
        <div>
          <strong>This ticket is <%=complaint.getStatus()%>.</strong>
          <% if (complaint.getResolvedAt() != null) { %>
            Resolved on <%=new java.text.SimpleDateFormat("dd MMM yyyy, h:mm a").format(complaint.getResolvedAt())%>.
          <% } %>
          <% if ("RESOLVED".equals(complaint.getStatus())) { %>
            Please ensure re-delivery or refund has been initiated.
          <% } else { %>
            Complaint rejected — customer has been notified.
          <% } %>
        </div>
      </div>
    <% } %>


  <%-- ═══════════════════════════════════════════════════════════
       TICKET LIST VIEW
       Flowchart: Staff reviews all open tickets
       ═══════════════════════════════════════════════════════════ --%>
  <% } else { %>

    <div class="toolbar">
      <% if (!showAll) { %>
        <a href="<%=request.getContextPath()%>/support?all=true" class="btn btn-outline">
          <i class="fa fa-list"></i> Show All Tickets
        </a>
      <% } else { %>
        <a href="<%=request.getContextPath()%>/support" class="btn btn-outline">
          <i class="fa fa-filter"></i> Open &amp; Under Review Only
        </a>
      <% } %>
    </div>

    <div class="card">
      <div class="card-header">
        <i class="fa fa-ticket"></i>
        <% if (showAll) { %>All Tickets<% } else { %>Open &amp; Under Review<% } %>
        <% if (tickets != null && !tickets.isEmpty()) { %>
          <span class="count-tag"><%=tickets.size()%></span>
        <% } %>
      </div>

      <% if (tickets == null || tickets.isEmpty()) { %>
        <div class="empty">
          <i class="fa fa-inbox"></i>
          <% if (showAll) { %>No complaints found.<% } else { %>No open tickets — all caught up! 🎉<% } %>
        </div>
      <% } else { %>
      <table>
        <thead>
          <tr>
            <th>Ticket</th>
            <th>Customer</th>
            <th>Issue</th>
            <th>Order / Items</th>
            <th>Status</th>
            <th>Filed</th>
            <th>Action</th>
          </tr>
        </thead>
        <tbody>
        <% for (SupportComplaint t : tickets) {
             String ts = t.getStatus();
             String tbc = "OPEN".equals(ts)?"badge-open":"UNDER_REVIEW".equals(ts)?"badge-under_review":"RESOLVED".equals(ts)?"badge-resolved":"badge-closed";
        %>
          <tr>
            <td>
              <a href="<%=request.getContextPath()%>/support?action=view&id=<%=t.getId()%>"
                 class="ticket-link"><%=t.getTicketId()%></a>
            </td>
            <td>
              <strong><%=t.getCustomerName() != null ? t.getCustomerName() : "—"%></strong><br>
              <span style="font-size:12px;color:var(--muted);"><%=t.getCustomerPhone() != null ? t.getCustomerPhone() : ""%></span>
            </td>
            <td><%=t.getIssueType()%></td>
            <td style="font-size:12px;color:var(--muted);">
              <% if (t.getOrderId() != null) { %>Group #<%=t.getOrderGroupId() != null ? t.getOrderGroupId() : t.getOrderId()%><br><%=t.getOrderProducts() != null ? t.getOrderProducts() : ""%>
              <% } else { %>—<% } %>
            </td>
            <td>
              <span class="badge <%=tbc%>">
                <%
                  switch(ts){
                    case "OPEN":         out.print("🟡 Open"); break;
                    case "UNDER_REVIEW": out.print("🔵 Under Review"); break;
                    case "RESOLVED":     out.print("✅ Resolved"); break;
                    case "CLOSED":       out.print("❌ Closed"); break;
                    default:             out.print(ts);
                  }
                %>
              </span>
            </td>
            <td style="font-size:12px;color:var(--muted);white-space:nowrap;">
              <%=t.getCreatedAt() != null
                ? new java.text.SimpleDateFormat("dd MMM yy").format(t.getCreatedAt())
                : "—"%>
            </td>
            <td>
              <a href="<%=request.getContextPath()%>/support?action=view&id=<%=t.getId()%>"
                 class="btn btn-primary btn-sm">
                <i class="fa fa-eye"></i> Review
              </a>
            </td>
          </tr>
        <% } %>
        </tbody>
      </table>
      <% } %>
    </div>

  <% } /* end list view */ %>

</div><!-- /content-area -->
</body>
</html>
