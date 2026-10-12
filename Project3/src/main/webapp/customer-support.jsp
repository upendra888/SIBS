<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="com.sibs.model.User, com.sibs.model.SupportComplaint,
                 com.sibs.dao.SupportComplaintDAO, java.util.List" %>
<%
User customer = (User) session.getAttribute("customer");
if (customer == null) {
    response.sendRedirect(request.getContextPath() + "/customer-login.jsp");
    return;
}
List<com.sibs.model.Order> customerOrders = new com.sibs.dao.OrderDAO().getDeliveredOrdersByUser(customer.getId());

List<SupportComplaint> complaints = new java.util.ArrayList<>();
try {
    complaints = new SupportComplaintDAO().getByUserId(customer.getId());
} catch (Exception e) { }

String successMsg = (String) session.getAttribute("supportMsg");
String errorMsg   = (String) session.getAttribute("supportError");
session.removeAttribute("supportMsg");
session.removeAttribute("supportError");

// Count unread notifications (RESOLVED or CLOSED tickets updated recently)
int unreadCount = 0;
for (SupportComplaint c : complaints) {
    if (("RESOLVED".equals(c.getStatus()) || "CLOSED".equals(c.getStatus()))
        && c.getResolvedAt() != null) {
        long diffHours = (System.currentTimeMillis() - c.getResolvedAt().getTime()) / (1000 * 60 * 60);
        if (diffHours < 72) unreadCount++;
    }
}
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Help &amp; Support — SIBS</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<style>
:root{
  --bg:#f8fafc;--surface:#fff;--border:#e2e8f0;
  --text:#0f172a;--muted:#64748b;
  --primary:#2563eb;--success:#16a34a;--danger:#ef4444;--warn:#f59e0b;
}
*{margin:0;padding:0;box-sizing:border-box;font-family:'Inter',sans-serif;}
body{background:var(--bg);color:var(--text);}
.page-wrap{max-width:900px;margin:0 auto;padding:24px 16px 60px;}

/* ── Page header ── */
.page-head{display:flex;align-items:center;justify-content:space-between;margin-bottom:6px;flex-wrap:wrap;gap:10px;}
.back-btn{display:inline-flex;align-items:center;gap:8px;font-size:14px;font-weight:600;color:var(--text);text-decoration:none;padding:8px 14px;border:1px solid var(--border);border-radius:9px;background:var(--surface);transition:.15s;}
.back-btn:hover{background:var(--bg);color:var(--primary);}
.back-btn i{font-size:13px;}
.page-head h1{font-size:20px;font-weight:700;display:flex;align-items:center;gap:8px;}
.page-head h1 i{color:var(--primary);}
.sub{color:var(--muted);font-size:14px;margin-bottom:24px;}

/* ── Notification bell ── */
.notif-btn{position:relative;background:var(--surface);border:1px solid var(--border);border-radius:10px;padding:9px 14px;cursor:pointer;display:flex;align-items:center;gap:8px;font-size:13px;font-weight:600;color:var(--text);transition:.15s;}
.notif-btn:hover{background:var(--bg);}
.notif-dot{position:absolute;top:-5px;right:-5px;background:#ef4444;color:#fff;border-radius:50%;width:18px;height:18px;font-size:10px;font-weight:700;display:flex;align-items:center;justify-content:center;border:2px solid var(--bg);}

/* ── Notification drawer ── */
.notif-drawer{display:none;position:fixed;top:0;right:0;width:360px;height:100vh;background:var(--surface);border-left:1px solid var(--border);z-index:1000;flex-direction:column;box-shadow:-4px 0 24px rgba(0,0,0,.1);}
.notif-drawer.open{display:flex;}
.notif-header{padding:18px 20px;border-bottom:1px solid var(--border);display:flex;align-items:center;justify-content:space-between;}
.notif-header h3{font-size:15px;font-weight:700;}
.notif-close{background:none;border:none;cursor:pointer;font-size:18px;color:var(--muted);padding:4px;}
.notif-list{flex:1;overflow-y:auto;padding:12px;}
.notif-item{border-radius:10px;padding:14px;margin-bottom:10px;border:1px solid;}
.notif-item.resolved{background:#f0fdf4;border-color:#bbf7d0;}
.notif-item.closed  {background:#fef2f2;border-color:#fecaca;}
.notif-item.review  {background:#eff6ff;border-color:#bfdbfe;}
.notif-item.open    {background:#fffbeb;border-color:#fde68a;}
.notif-icon{font-size:20px;margin-bottom:6px;}
.notif-ticket{font-size:11px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.05em;}
.notif-title{font-size:13px;font-weight:700;margin:3px 0;}
.notif-body{font-size:12px;line-height:1.6;color:var(--muted);}
.notif-time{font-size:11px;color:var(--muted);margin-top:6px;}
.notif-overlay{display:none;position:fixed;inset:0;background:rgba(0,0,0,.3);z-index:999;}
.notif-overlay.open{display:block;}

/* ── Banners ── */
.banner{padding:12px 16px;border-radius:10px;font-size:14px;margin-bottom:20px;display:flex;align-items:center;gap:10px;}
.banner.success{background:#f0fdf4;border:1px solid #bbf7d0;color:#166534;}
.banner.error  {background:#fef2f2;border:1px solid #fecaca;color:#991b1b;}

/* ── Cards ── */
.card{background:var(--surface);border:1px solid var(--border);border-radius:14px;padding:24px;margin-bottom:24px;box-shadow:0 1px 4px rgba(0,0,0,.06);}
.card-title{font-size:16px;font-weight:600;display:flex;align-items:center;gap:8px;margin-bottom:20px;}
.card-title i{color:var(--primary);}

/* ── Form ── */
.form-row{display:grid;grid-template-columns:1fr 1fr;gap:16px;margin-bottom:16px;}
.form-row.full{grid-template-columns:1fr;}
label{font-size:13px;font-weight:500;color:var(--muted);display:block;margin-bottom:6px;}
select,input,textarea{width:100%;border:1px solid var(--border);border-radius:8px;padding:10px 12px;font-size:14px;background:var(--bg);color:var(--text);outline:none;transition:.15s;}
select:focus,input:focus,textarea:focus{border-color:var(--primary);background:#fff;}
textarea{resize:vertical;min-height:90px;}
.file-hint{font-size:12px;color:var(--muted);margin-top:4px;}
.btn-submit{display:inline-flex;align-items:center;gap:8px;background:var(--primary);color:#fff;padding:11px 22px;border-radius:9px;border:none;cursor:pointer;font-size:14px;font-weight:600;transition:.15s;}
.btn-submit:hover{background:#1d4ed8;}

/* ── Issue hint box ── */
.issue-hint{display:none;background:#eff6ff;border:1px solid #bfdbfe;border-radius:8px;padding:12px 14px;font-size:13px;color:#1e40af;margin-top:10px;line-height:1.7;}
.issue-hint.show{display:block;}
.issue-hint strong{display:block;margin-bottom:4px;font-size:13px;}

/* ── Tickets section ── */
.section-head{display:flex;align-items:center;justify-content:space-between;margin-bottom:16px;}
.section-title{font-size:16px;font-weight:600;display:flex;align-items:center;gap:8px;}
.section-title i{color:var(--muted);}

/* ── Ticket cards ── */
.ticket-card{background:var(--surface);border:1px solid var(--border);border-radius:12px;margin-bottom:14px;overflow:hidden;transition:.15s;}
.ticket-card:hover{box-shadow:0 2px 12px rgba(0,0,0,.08);}
.ticket-card.resolved{border-left:4px solid #16a34a;}
.ticket-card.closed  {border-left:4px solid #ef4444;}
.ticket-card.under_review{border-left:4px solid #2563eb;}
.ticket-card.open    {border-left:4px solid #f59e0b;}

.ticket-top{padding:14px 18px;display:flex;align-items:center;gap:12px;flex-wrap:wrap;cursor:pointer;}
.ticket-id{font-weight:700;color:var(--primary);font-size:14px;white-space:nowrap;}
.ticket-issue{background:#eff6ff;color:#1e40af;padding:2px 9px;border-radius:6px;font-size:12px;font-weight:500;}
.ticket-date{font-size:12px;color:var(--muted);margin-left:auto;}

/* ── Status badges ── */
.badge{display:inline-flex;align-items:center;gap:4px;padding:3px 10px;border-radius:20px;font-size:12px;font-weight:600;white-space:nowrap;}
.badge-open        {background:#fef9c3;color:#854d0e;}
.badge-under_review{background:#dbeafe;color:#1e40af;}
.badge-resolved    {background:#dcfce7;color:#166534;}
.badge-closed      {background:#fee2e2;color:#991b1b;}

/* ── Ticket detail panel ── */
.ticket-detail{display:none;border-top:1px solid var(--border);padding:18px;}
.ticket-detail.open{display:block;}

/* ── Timeline ── */
.timeline{position:relative;padding-left:28px;margin:14px 0;}
.timeline::before{content:'';position:absolute;left:8px;top:4px;bottom:4px;width:2px;background:var(--border);}
.tl-item{position:relative;margin-bottom:16px;}
.tl-item:last-child{margin-bottom:0;}
.tl-dot{position:absolute;left:-24px;top:2px;width:12px;height:12px;border-radius:50%;border:2px solid var(--border);background:var(--surface);}
.tl-dot.done{border-color:var(--primary);background:var(--primary);}
.tl-dot.success{border-color:var(--success);background:var(--success);}
.tl-dot.danger{border-color:var(--danger);background:var(--danger);}
.tl-dot.warn{border-color:var(--warn);background:var(--warn);}
.tl-label{font-size:13px;font-weight:600;color:var(--text);}
.tl-sub{font-size:12px;color:var(--muted);margin-top:2px;line-height:1.5;}
.tl-time{font-size:11px;color:var(--muted);margin-top:2px;}

/* ── Resolution box ── */
.resolution-box{border-radius:10px;padding:14px 16px;margin-top:14px;font-size:13px;}
.resolution-box.resolved{background:#f0fdf4;border:1px solid #bbf7d0;color:#166534;}
.resolution-box.closed  {background:#fef2f2;border:1px solid #fecaca;color:#991b1b;}
.resolution-box h4{font-weight:700;margin-bottom:6px;display:flex;align-items:center;gap:6px;}
.resolution-box p{line-height:1.6;}

/* ── Empty ── */
.empty{text-align:center;padding:40px;color:var(--muted);font-size:14px;}
.empty i{font-size:32px;margin-bottom:10px;display:block;}

@media(max-width:600px){
  .form-row{grid-template-columns:1fr;}
  .ticket-date{margin-left:0;}
  .notif-drawer{width:100%;}
}
</style>
</head>
<body>

<%-- Notification overlay --%>
<div class="notif-overlay" id="notifOverlay" onclick="closeNotif()"></div>

<%-- Notification drawer --%>
<div class="notif-drawer" id="notifDrawer">
  <div class="notif-header">
    <h3><i class="fa fa-bell" style="color:var(--primary);margin-right:6px;"></i> Notifications</h3>
    <button class="notif-close" onclick="closeNotif()"><i class="fa fa-xmark"></i></button>
  </div>
  <div class="notif-list">
    <%
      boolean hasNotif = false;
      java.text.SimpleDateFormat dtf = new java.text.SimpleDateFormat("dd MMM yyyy, h:mm a");
      for (SupportComplaint c : complaints) {
        String s = c.getStatus();
        if ("RESOLVED".equals(s) || "CLOSED".equals(s) || "UNDER_REVIEW".equals(s)) {
          hasNotif = true;
          String nClass = "RESOLVED".equals(s) ? "resolved" : "CLOSED".equals(s) ? "closed" : "review";
    %>
      <div class="notif-item <%=nClass%>">
        <div class="notif-icon">
          <%="RESOLVED".equals(s) ? "✅" : "CLOSED".equals(s) ? "❌" : "🔵"%>
        </div>
        <div class="notif-ticket"><%=c.getTicketId()%> · <%=c.getIssueType()%></div>
        <div class="notif-title">
          <%="RESOLVED".equals(s) ? "Your complaint has been resolved!" :
             "CLOSED".equals(s)   ? "Your complaint was reviewed & closed" :
                                    "Your complaint is under review"%>
        </div>
        <div class="notif-body">
          <%if ("RESOLVED".equals(s)) {%>
            Our team has verified your complaint and taken action.
            <%if (c.getStaffNotes() != null && !c.getStaffNotes().isBlank()) {
                String snr = c.getStaffNotes(); String snrS = snr.length()>120?snr.substring(0,120)+"…":snr;%>
              <br><em>"<%=snrS%>"</em>
            <%}%>
          <%} else if ("CLOSED".equals(s)) {%>
            After investigation, we were unable to confirm the complaint.
            <%if (c.getStaffNotes() != null && !c.getStaffNotes().isBlank()) {
                String snc = c.getStaffNotes(); String sncS = snc.length()>120?snc.substring(0,120)+"…":snc;%>
              <br><em>"<%=sncS%>"</em>
            <%}%>
          <%} else {%>
            Our support team has picked up your complaint and is investigating.
          <%}%>
        </div>
        <div class="notif-time">
          <i class="fa fa-clock"></i>
          <%=c.getResolvedAt() != null ? dtf.format(c.getResolvedAt()) : c.getUpdatedAt() != null ? dtf.format(c.getUpdatedAt()) : dtf.format(c.getCreatedAt())%>
        </div>
      </div>
    <%  }
      } %>
    <% if (!hasNotif) { %>
      <div style="text-align:center;padding:40px 20px;color:var(--muted);font-size:13px;">
        <i class="fa fa-bell-slash" style="font-size:28px;display:block;margin-bottom:10px;opacity:.4;"></i>
        No notifications yet
      </div>
    <% } %>
  </div>
</div>

<div class="page-wrap">

  <div class="page-head">
    <a href="<%=request.getContextPath()%>/customer-dashboard.jsp" class="back-btn">
      <i class="fa fa-arrow-left"></i> Back to Home
    </a>
    <button class="notif-btn" onclick="openNotif()">
      <i class="fa fa-bell"></i> Notifications
      <% if (unreadCount > 0) { %>
        <span class="notif-dot"><%=unreadCount%></span>
      <% } %>
    </button>
  </div>
  <h1 style="font-size:22px;font-weight:700;display:flex;align-items:center;gap:10px;margin:18px 0 4px;">
    <i class="fa fa-headset" style="color:var(--primary);"></i> Help &amp; Support
  </h1>
  <p class="sub">Having an issue with your order? Raise a complaint and our team will investigate.</p>

  <%-- Flash --%>
  <% if (successMsg != null) { %>
    <div class="banner success"><i class="fa fa-circle-check"></i><%=successMsg%></div>
  <% } %>
  <% if (errorMsg != null) { %>
    <div class="banner error"><i class="fa fa-circle-xmark"></i><%=errorMsg%></div>
  <% } %>

  <%-- ═══ RAISE COMPLAINT FORM ═══ --%>
  <div class="card">
    <div class="card-title"><i class="fa fa-plus-circle"></i> Raise a New Complaint</div>

    <form action="<%=request.getContextPath()%>/raiseComplaint" method="post"
          enctype="multipart/form-data">

      <div class="form-row">
        <div>
          <label>Issue Type <span style="color:red">*</span></label>
          <select name="issueType" required onchange="showIssueHint(this.value)">
            <option value="">— Select issue —</option>
            <option value="Order not received">Order not received</option>
            <option value="Wrong item delivered">Wrong item delivered</option>
            <option value="Damaged item">Damaged item</option>
            <option value="Late delivery">Late delivery</option>
            <option value="Payment issue">Payment issue</option>
            <option value="Other">Other</option>
          </select>
          <%-- Issue-specific hint shown to customer --%>
          <div class="issue-hint" id="issueHint"></div>
        </div>
        <div>
          <label>Order <span style="color:red">*</span></label>
          <select name="orderId" required>
            <option value="">— Select your order —</option>
            <% if (customerOrders.isEmpty()) { %>
              <option value="" disabled>No delivered orders found</option>
            <% } %>
            <% for (com.sibs.model.Order o : customerOrders) {
                 // Build product names: collect from items list (same as orders page)
                 StringBuilder productNames = new StringBuilder();
                 if (o.getItems() != null && !o.getItems().isEmpty()) {
                     for (com.sibs.model.Order item : o.getItems()) {
                         if (item.getProductName() != null) {
                             if (productNames.length() > 0) productNames.append(", ");
                             productNames.append(item.getProductName());
                         }
                     }
                 }
                 if (productNames.length() == 0 && o.getProductName() != null) {
                     productNames.append(o.getProductName());
                 }
                 String label = productNames.length() > 0 ? productNames.toString() : "Order";
            %>
              <option value="<%=o.getGroupId()%>">
                Group #<%=o.getGroupId()%> · <%=label%> · <%=o.getStatus()%>
              </option>
            <% } %>
          </select>
        </div>
      </div>

      <div class="form-row full">
        <div>
          <label>Description</label>
          <textarea name="description" id="descField" placeholder="Describe your issue in detail…"></textarea>
        </div>
      </div>

      <div class="form-row">
        <div>
          <label>Attach Photo (optional)</label>
          <input type="file" name="photo" accept="image/*">
          <p class="file-hint"><i class="fa fa-image"></i> Max 5 MB · JPG / PNG / WEBP</p>
        </div>
      </div>

      <button type="submit" class="btn-submit">
        <i class="fa fa-paper-plane"></i> Submit Complaint
      </button>
    </form>
  </div>

  <%-- ═══ MY COMPLAINTS ═══ --%>
  <div class="section-head">
    <div class="section-title">
      <i class="fa fa-clock-rotate-left"></i> My Complaints
      <% if (!complaints.isEmpty()) { %>
        <span style="background:#e2e8f0;color:var(--muted);padding:2px 8px;border-radius:10px;font-size:12px;font-weight:500;"><%=complaints.size()%></span>
      <% } %>
    </div>
  </div>

  <% if (complaints.isEmpty()) { %>
    <div class="card empty">
      <i class="fa fa-inbox"></i>
      No complaints yet. If you face any issue, raise one above!
    </div>
  <% } else {
       java.text.SimpleDateFormat sdf = new java.text.SimpleDateFormat("dd MMM yyyy, h:mm a");
       for (SupportComplaint c : complaints) {
         String s = c.getStatus();
         String cardClass = "UNDER_REVIEW".equals(s) ? "under_review" : s.toLowerCase();
         String badgeClass = "UNDER_REVIEW".equals(s) ? "badge-under_review" : "badge-" + s.toLowerCase();
  %>
    <div class="ticket-card <%=cardClass%>">
      <div class="ticket-top" onclick="toggleTicket('tc-<%=c.getId()%>')">
        <span class="ticket-id"><i class="fa fa-ticket" style="margin-right:4px;"></i><%=c.getTicketId()%></span>
        <span class="ticket-issue"><%=c.getIssueType()%></span>
        <span class="badge <%=badgeClass%>">
          <%switch(s){
            case "OPEN":         out.print("🟡 Open"); break;
            case "UNDER_REVIEW": out.print("🔵 Under Review"); break;
            case "RESOLVED":     out.print("✅ Resolved"); break;
            case "CLOSED":       out.print("❌ Closed"); break;
            default:             out.print(s);
          }%>
        </span>
        <span class="ticket-date"><%=c.getCreatedAt() != null ? sdf.format(c.getCreatedAt()) : "—"%></span>
        <i class="fa fa-chevron-down" style="color:var(--muted);font-size:13px;margin-left:4px;" id="chev-tc-<%=c.getId()%>"></i>
      </div>

      <div class="ticket-detail" id="tc-<%=c.getId()%>">

        <%-- Order info --%>
        <% if (c.getOrderId() != null) { %>
        <div style="display:flex;gap:20px;flex-wrap:wrap;font-size:13px;margin-bottom:16px;padding:10px 14px;background:var(--bg);border-radius:8px;">
          <div><span style="color:var(--muted);">Order</span> <strong>#<%=c.getOrderId()%></strong></div>
          <% if (c.getOrderProducts() != null) { %>
          <div><span style="color:var(--muted);">Items:</span> <%=c.getOrderProducts()%></div>
          <% } %>
        </div>
        <% } %>

        <%-- Customer's description --%>
        <% if (c.getDescription() != null && !c.getDescription().isBlank()) { %>
        <div style="font-size:13px;color:var(--muted);margin-bottom:16px;padding:10px 14px;background:var(--bg);border-radius:8px;line-height:1.6;">
          <div style="font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:.05em;margin-bottom:4px;">Your description</div>
          <%=c.getDescription()%>
        </div>
        <% } %>

        <%-- Timeline --%>
        <div style="font-size:12px;font-weight:700;text-transform:uppercase;letter-spacing:.05em;color:var(--muted);margin-bottom:8px;">Timeline</div>
        <div class="timeline">

          <%-- Step 1: Raised --%>
          <div class="tl-item">
            <div class="tl-dot done"></div>
            <div class="tl-label">Complaint Raised</div>
            <div class="tl-sub">Your complaint was submitted successfully. Ticket ID: <strong><%=c.getTicketId()%></strong></div>
            <div class="tl-time"><i class="fa fa-clock"></i> <%=c.getCreatedAt() != null ? sdf.format(c.getCreatedAt()) : "—"%></div>
          </div>

          <%-- Step 2: Under Review --%>
          <div class="tl-item">
            <div class="tl-dot <%=!"OPEN".equals(s) ? "done" : ""%>"></div>
            <div class="tl-label" style="color:<%=!"OPEN".equals(s) ? "var(--text)" : "var(--muted)"%>;">Under Review</div>
            <div class="tl-sub">
              <% if (!"OPEN".equals(s)) { %>
                Our support team has picked up your complaint and is investigating.
              <% } else { %>
                Waiting for our team to pick this up — usually within a few hours.
              <% } %>
            </div>
            <% if (c.getUpdatedAt() != null && !"OPEN".equals(s)) { %>
            <div class="tl-time"><i class="fa fa-clock"></i> <%=sdf.format(c.getUpdatedAt())%></div>
            <% } %>
          </div>

          <%-- Step 3: Investigation --%>
          <div class="tl-item">
            <div class="tl-dot <%="RESOLVED".equals(s)||"CLOSED".equals(s) ? "done" : ""%>"></div>
            <div class="tl-label" style="color:<%="RESOLVED".equals(s)||"CLOSED".equals(s) ? "var(--text)" : "var(--muted)"%>;">Investigation</div>
            <div class="tl-sub">
              <% if ("UNDER_REVIEW".equals(s)) { %>
                Staff is currently verifying GPS logs, OTP records, and delivery details for your complaint.
              <% } else if ("RESOLVED".equals(s) || "CLOSED".equals(s)) { %>
                Investigation completed. Verdict has been delivered.
              <% } else { %>
                Staff will verify all evidence related to your complaint.
              <% } %>
            </div>
          </div>

          <%-- Step 4: Verdict --%>
          <div class="tl-item">
            <div class="tl-dot <%="RESOLVED".equals(s) ? "success" : "CLOSED".equals(s) ? "danger" : ""%>"></div>
            <div class="tl-label" style="color:<%="RESOLVED".equals(s)||"CLOSED".equals(s) ? "var(--text)" : "var(--muted)"%>;">
              <%if ("RESOLVED".equals(s)) { %>✅ Resolved
              <%} else if ("CLOSED".equals(s)) { %>❌ Closed
              <%} else { %>Verdict Pending<%}%>
            </div>
            <% if (c.getResolvedAt() != null) { %>
            <div class="tl-time"><i class="fa fa-clock"></i> <%=sdf.format(c.getResolvedAt())%></div>
            <% } %>
          </div>
        </div>

        <%-- Resolution box --%>
        <% if ("RESOLVED".equals(s)) { %>
        <div class="resolution-box resolved">
          <h4><i class="fa fa-circle-check"></i> Your complaint has been resolved</h4>
          <p>
            Our team has verified your complaint and taken the necessary action —
            either a re-delivery has been arranged or a refund has been initiated to your original payment method.
            <br><br>
            If you haven't received your re-delivery or refund within 5–7 business days, please raise a new complaint.
          </p>
          <% if (c.getStaffNotes() != null && !c.getStaffNotes().isBlank()) { %>
          <div style="margin-top:10px;padding-top:10px;border-top:1px solid #bbf7d0;font-size:12px;">
            <strong>Staff note:</strong> <%=c.getStaffNotes()%>
          </div>
          <% } %>
        </div>
        <% } else if ("CLOSED".equals(s)) { %>
        <div class="resolution-box closed">
          <h4><i class="fa fa-circle-xmark"></i> Complaint closed</h4>
          <p>
            After thorough investigation including GPS verification, OTP records, and delivery logs,
            our team was unable to confirm the complaint. The ticket has been closed.
          </p>
          <% if (c.getStaffNotes() != null && !c.getStaffNotes().isBlank()) { %>
          <div style="margin-top:10px;padding-top:10px;border-top:1px solid #fecaca;font-size:12px;">
            <strong>Staff finding:</strong> <%=c.getStaffNotes()%>
          </div>
          <% } %>
          <div style="margin-top:10px;font-size:12px;">
            If you believe this is incorrect, please contact us directly or raise a new complaint with additional evidence.
          </div>
        </div>
        <% } else if ("UNDER_REVIEW".equals(s)) { %>
        <div style="background:#eff6ff;border:1px solid #bfdbfe;border-radius:10px;padding:14px 16px;margin-top:14px;font-size:13px;color:#1e40af;">
          <h4 style="display:flex;align-items:center;gap:6px;font-size:13px;margin-bottom:6px;"><i class="fa fa-magnifying-glass"></i> We're on it</h4>
          <p style="line-height:1.6;">Our support team is actively investigating your complaint. You'll be notified here and via a notification as soon as a verdict is reached — usually within 24–48 hours.</p>
        </div>
        <% } else { %>
        <div style="background:#fffbeb;border:1px solid #fde68a;border-radius:10px;padding:14px 16px;margin-top:14px;font-size:13px;color:#92400e;">
          <h4 style="display:flex;align-items:center;gap:6px;font-size:13px;margin-bottom:6px;"><i class="fa fa-hourglass-half"></i> In queue</h4>
          <p style="line-height:1.6;">Your complaint is in our support queue. A staff member will pick it up shortly.</p>
        </div>
        <% } %>

      </div>
    </div>
  <% } } %>

</div>

<script>
function openNotif() {
  document.getElementById('notifDrawer').classList.add('open');
  document.getElementById('notifOverlay').classList.add('open');
}
function closeNotif() {
  document.getElementById('notifDrawer').classList.remove('open');
  document.getElementById('notifOverlay').classList.remove('open');
}

function toggleTicket(id) {
  var el = document.getElementById(id);
  var chev = document.getElementById('chev-' + id);
  var open = el.classList.contains('open');
  el.classList.toggle('open', !open);
  if (chev) chev.style.transform = open ? '' : 'rotate(180deg)';
}

var issueHints = {
  'Order not received': '<strong>📦 What to include:</strong> Mention the order ID, when it was supposed to arrive, and whether you checked with neighbours or building security. Attach any screenshots if available.',
  'Wrong item delivered': '<strong>🔄 What to include:</strong> Tell us what you ordered vs what you received. Attach a clear photo of the wrong item — this speeds up the investigation significantly.',
  'Damaged item': '<strong>💔 What to include:</strong> Do NOT throw away the item or packaging. Attach clear photos showing the damage. Mention if the packaging was already damaged when you received it.',
  'Late delivery': '<strong>⏰ What to include:</strong> Mention your expected delivery time and the actual arrival time. Include your order ID so we can check the delivery logs.',
  'Payment issue': '<strong>💳 What to include:</strong> Mention whether it was a double charge, failed payment, or wrong amount. Include your bank transaction reference if possible.',
  'Other': '<strong>💬 What to include:</strong> Describe the issue clearly. Our team will review and get back to you within 24 hours.'
};

function showIssueHint(val) {
  var box = document.getElementById('issueHint');
  var desc = document.getElementById('descField');
  if (issueHints[val]) {
    box.innerHTML = issueHints[val];
    box.classList.add('show');
    var placeholders = {
      'Order not received': 'e.g. My order #1042 was supposed to arrive by 6 PM on 25 May but I never received it. I checked with my neighbours and building security — nothing.',
      'Wrong item delivered': 'e.g. I ordered Apple and Banana but received Bread and Eggs instead. Photo attached.',
      'Damaged item': 'e.g. The Nandhini milk packet was torn and leaking when I received it. The outer bag also had a hole. Photos attached.',
      'Late delivery': 'e.g. My order was promised by 5 PM but arrived at 9 PM. Delivery boy did not call.',
      'Payment issue': 'e.g. I was charged twice for order #1042. My bank shows two debits of ₹250 on 25 May.',
      'Other': 'Describe your issue in as much detail as possible…'
    };
    desc.placeholder = placeholders[val] || 'Describe your issue in detail…';
  } else {
    box.classList.remove('show');
    desc.placeholder = 'Describe your issue in detail…';
  }
}

// Auto-open latest resolved/closed ticket on load if coming from a notification
<% if (successMsg != null && !complaints.isEmpty()) { %>
window.onload = function() {
  var first = document.querySelector('.ticket-card');
  if (first) {
    var detail = first.querySelector('.ticket-detail');
    var chev = first.querySelector('[id^="chev-"]');
    if (detail) detail.classList.add('open');
    if (chev) chev.style.transform = 'rotate(180deg)';
  }
};
<% } %>
</script>
</body>
</html>
