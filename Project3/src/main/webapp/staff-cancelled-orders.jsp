<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.util.*,com.sibs.dao.OrderDAO,com.sibs.dao.DeliveryBoyDAO,com.sibs.model.Order,com.sibs.model.DeliveryBoy,com.sibs.model.User" %>
<%
User user = (User) session.getAttribute("user");
if(user == null || (!("ADMIN".equals(user.getRole())) && !("STAFF".equals(user.getRole())))){
    response.sendRedirect("login.jsp");
    return;
}
// ── Flash messages ────────────────────────────────────────────────
String flashSuccess = "", flashError = "";
String p = request.getParameter("success");
String e = request.getParameter("error");
if("reattempt_scheduled".equals(p)) flashSuccess = "✅ Re-delivery scheduled! Delivery boy has been notified.";
if("order_cancelled".equals(p))     flashSuccess = "✅ Order cancelled. Stock restored and delivery boy notified.";
if("missing_params".equals(e))             flashError = "⚠️ Missing required fields. Please try again.";
if("reattempt_missing_fields".equals(e))   flashError = "⚠️ Please select a delivery boy and enter an address.";
if("order_not_found".equals(e))            flashError = "⚠️ Order not found.";
if("server_error".equals(e))               flashError = "⚠️ Something went wrong. Please try again.";
OrderDAO dao = new OrderDAO();
List<DeliveryBoy> deliveryBoys = new DeliveryBoyDAO().getAllDeliveryBoys();
List<Order> cancelledOrders    = dao.getCancelledOrders();
List<Order> notDeliveredOrders = dao.getNotDeliveredOrders();

int totalCancelled    = cancelledOrders.size();
int totalNotDelivered = notDeliveredOrders.size();
int onlineCancels = 0;
double totalLostRevenue = 0;

Map<String,Integer> reasonCounts = new LinkedHashMap<>();
reasonCounts.put("Changed my mind", 0);
reasonCounts.put("Ordered by mistake", 0);
reasonCounts.put("Found better price", 0);
reasonCounts.put("Taking too long", 0);
reasonCounts.put("Other / Custom", 0);
reasonCounts.put("Not provided", 0);

for(Order o : cancelledOrders){
    String pm = o.getPaymentMethod();
    if(pm != null && (pm.equalsIgnoreCase("ONLINE") || pm.equalsIgnoreCase("Razorpay") || pm.equalsIgnoreCase("UPI") || pm.equalsIgnoreCase("Card"))) onlineCancels++;
    totalLostRevenue += o.getTotal();
    String r = o.getCancelReason();
    if(r == null || r.trim().isEmpty() || "No reason provided".equalsIgnoreCase(r.trim())){
        reasonCounts.put("Not provided", reasonCounts.get("Not provided")+1);
    } else if(r.toLowerCase().contains("mind") || r.toLowerCase().contains("changed")){
        reasonCounts.put("Changed my mind", reasonCounts.get("Changed my mind")+1);
    } else if(r.toLowerCase().contains("mistake") || r.toLowerCase().contains("accident")){
        reasonCounts.put("Ordered by mistake", reasonCounts.get("Ordered by mistake")+1);
    } else if(r.toLowerCase().contains("price") || r.toLowerCase().contains("cheap") || r.toLowerCase().contains("better")){
        reasonCounts.put("Found better price", reasonCounts.get("Found better price")+1);
    } else if(r.toLowerCase().contains("long") || r.toLowerCase().contains("delay") || r.toLowerCase().contains("slow")){
        reasonCounts.put("Taking too long", reasonCounts.get("Taking too long")+1);
    } else {
        reasonCounts.put("Other / Custom", reasonCounts.get("Other / Custom")+1);
    }
}
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Cancelled Orders — SIBS Staff</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<style>
:root{
  --bg:#f8fafc;--surface:#fff;--border:#e2e8f0;
  --text:#0f172a;--muted:#64748b;
  --primary:#2563eb;--success:#16a34a;--danger:#ef4444;--warn:#f59e0b;
  --shadow:0 1px 4px rgba(0,0,0,.08);
}
*{margin:0;padding:0;box-sizing:border-box;font-family:'Inter',sans-serif;}
body{background:var(--bg);color:var(--text);min-height:100vh;}
.page{display:flex;flex-direction:column;margin-left:0;}
.topbar{background:var(--surface);border-bottom:1px solid var(--border);padding:0 28px;height:60px;
  display:flex;align-items:center;gap:12px;box-shadow:var(--shadow);position:sticky;top:0;z-index:10;}
.topbar h1{font-size:17px;font-weight:700;flex:1;}
.badge-count{border-radius:99px;padding:3px 12px;font-size:12px;font-weight:700;color:#fff;}
.main{padding:28px;flex:1;}
.stats-grid{display:grid;grid-template-columns:repeat(4,1fr);gap:16px;margin-bottom:28px;}
.stat-card{background:var(--surface);border-radius:14px;padding:20px 22px;border:1px solid var(--border);
  box-shadow:var(--shadow);display:flex;align-items:center;gap:16px;}
.stat-icon{width:46px;height:46px;border-radius:12px;display:flex;align-items:center;justify-content:center;font-size:18px;flex-shrink:0;}
.stat-icon.red{background:#fee2e2;color:var(--danger);}
.stat-icon.orange{background:#fff7ed;color:#ea580c;}
.stat-icon.blue{background:#eff6ff;color:var(--primary);}
.stat-icon.purple{background:#f5f3ff;color:#7c3aed;}
.stat-label{font-size:11px;color:var(--muted);font-weight:600;text-transform:uppercase;letter-spacing:.4px;margin-bottom:3px;}
.stat-val{font-size:24px;font-weight:800;}
.breakdown-card{background:var(--surface);border-radius:14px;border:1px solid var(--border);
  box-shadow:var(--shadow);margin-bottom:28px;padding:22px 26px;}
.breakdown-title{font-size:12px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.5px;
  margin-bottom:18px;display:flex;align-items:center;gap:7px;}
.reason-bars{display:flex;flex-direction:column;gap:12px;}
.reason-bar-row{display:flex;align-items:center;gap:14px;}
.reason-bar-label{width:175px;font-size:12px;font-weight:600;flex-shrink:0;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;}
.reason-bar-track{flex:1;height:10px;background:#f1f5f9;border-radius:99px;overflow:hidden;}
.reason-bar-fill{height:100%;border-radius:99px;background:linear-gradient(90deg,#ef4444,#f87171);}
.reason-bar-fill.gray{background:linear-gradient(90deg,#94a3b8,#cbd5e1);}
.reason-bar-pct{width:34px;text-align:right;font-size:11px;font-weight:700;color:var(--muted);}
.section{background:var(--surface);border-radius:14px;border:1px solid var(--border);
  box-shadow:var(--shadow);margin-bottom:28px;overflow:hidden;}
.section-header{padding:18px 24px;border-bottom:1px solid var(--border);display:flex;align-items:center;gap:10px;}
.section-header h2{font-size:15px;font-weight:700;flex:1;}
.pill{padding:3px 11px;border-radius:99px;font-size:11px;font-weight:700;}
.pill-red{background:#fee2e2;color:var(--danger);}
.pill-orange{background:#fff7ed;color:#ea580c;}
.toolbar{padding:12px 20px;border-bottom:1px solid var(--border);background:#f8fafc;
  display:flex;align-items:center;gap:10px;flex-wrap:wrap;}
.search-input{padding:8px 14px;border-radius:8px;border:1.5px solid var(--border);
  font-size:13px;background:var(--surface);color:var(--text);outline:none;width:260px;}
.search-input:focus{border-color:var(--primary);}
.filter-sel{padding:8px 12px;border-radius:8px;border:1.5px solid var(--border);
  font-size:13px;background:var(--surface);color:var(--text);outline:none;cursor:pointer;}
.export-btn{margin-left:auto;padding:8px 16px;border-radius:8px;border:1.5px solid var(--border);
  background:var(--surface);font-size:12px;font-weight:600;cursor:pointer;display:flex;align-items:center;gap:6px;
  color:var(--muted);transition:.15s;}
.export-btn:hover{border-color:var(--primary);color:var(--primary);}
table{width:100%;border-collapse:collapse;}
thead th{padding:11px 16px;text-align:left;font-size:11px;font-weight:700;color:var(--muted);
  text-transform:uppercase;letter-spacing:.5px;border-bottom:1px solid var(--border);background:#f8fafc;white-space:nowrap;}
tbody td{padding:14px 16px;border-bottom:1px solid var(--border);font-size:13px;vertical-align:top;}
tbody tr:last-child td{border-bottom:none;}
tbody tr:hover{background:#f8fafc;}
.reason-box{background:#fff5f5;border:1.5px solid #fecaca;border-radius:10px;
  padding:9px 13px;max-width:260px;display:flex;align-items:flex-start;gap:8px;}
.reason-box i{color:#dc2626;margin-top:1px;flex-shrink:0;}
.reason-box-text{font-size:12px;color:#7f1d1d;font-weight:500;line-height:1.5;word-break:break-word;}
.reason-none{font-size:12px;color:var(--muted);font-style:italic;display:flex;align-items:center;gap:5px;}
.pay-badge{padding:3px 9px;border-radius:6px;font-size:10px;font-weight:700;letter-spacing:.3px;}
.pay-online{background:#eff6ff;color:var(--primary);}
.pay-cod{background:#f0fdf4;color:var(--success);}
.status-pill{display:inline-flex;align-items:center;gap:5px;padding:4px 10px;border-radius:99px;font-size:11px;font-weight:600;}
.s-assigned{background:#e0f2fe;color:#0369a1;}
.s-picked{background:#ede9fe;color:#7c3aed;}
.s-shipped{background:#fef9c3;color:#92400e;}
.empty-row td{text-align:center;color:var(--muted);padding:48px;font-size:14px;}
</style>
</head>
<body>
<% if(!flashSuccess.isEmpty()){ %>
<div id="flashToast" style="position:fixed;top:20px;right:24px;z-index:99999;background:#16a34a;color:#fff;padding:13px 20px;border-radius:10px;font-size:13px;font-weight:600;box-shadow:0 4px 16px rgba(0,0,0,0.18);max-width:360px;">
  <%=flashSuccess%>
</div>
<% } else if(!flashError.isEmpty()){ %>
<div id="flashToast" style="position:fixed;top:20px;right:24px;z-index:99999;background:#dc2626;color:#fff;padding:13px 20px;border-radius:10px;font-size:13px;font-weight:600;box-shadow:0 4px 16px rgba(0,0,0,0.18);max-width:360px;">
  <%=flashError%>
</div>
<% } %>
<script>var t=document.getElementById('flashToast');if(t)setTimeout(function(){t.style.display='none';},4000);</script>


<div class="page">
  <div class="topbar">
    <a href="staff-dashboard.jsp" style="display:flex;align-items:center;gap:7px;padding:7px 14px;border-radius:8px;border:1.5px solid var(--border);background:var(--surface);font-size:13px;font-weight:600;color:var(--muted);text-decoration:none;margin-right:8px;transition:.15s;" onmouseover="this.style.color='#f97316';this.style.borderColor='#f97316';" onmouseout="this.style.color='var(--muted)';this.style.borderColor='var(--border)';">
      <i class="fa fa-arrow-left"></i> Dashboard
    </a>
    <i class="fa fa-ban" style="color:var(--danger);font-size:18px;"></i>
    <h1>Cancelled Orders &amp; Reasons</h1>
    <% if(totalCancelled > 0){ %>
    <span class="badge-count" style="background:var(--danger);"><i class="fa fa-ban"></i> <%=totalCancelled%> cancelled</span>
    <% } %>
    <% if(totalNotDelivered > 0){ %>
    <span class="badge-count" style="background:#ea580c;margin-left:4px;"><i class="fa fa-truck"></i> <%=totalNotDelivered%> in transit</span>
    <% } %>
  </div>

  <div class="main">

    <!-- STATS -->
    <div class="stats-grid">
      <div class="stat-card">
        <div class="stat-icon red"><i class="fa fa-ban"></i></div>
        <div>
          <div class="stat-label">Total Cancelled</div>
          <div class="stat-val" style="color:var(--danger);"><%=totalCancelled%></div>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon orange"><i class="fa fa-truck"></i></div>
        <div>
          <div class="stat-label">In Transit</div>
          <div class="stat-val" style="color:#ea580c;"><%=totalNotDelivered%></div>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon blue"><i class="fa fa-credit-card"></i></div>
        <div>
          <div class="stat-label">Online Cancels</div>
          <div class="stat-val"><%=onlineCancels%></div>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon purple"><i class="fa fa-indian-rupee-sign"></i></div>
        <div>
          <div class="stat-label">Revenue Lost</div>
          <div class="stat-val">&#8377;<%=(int)totalLostRevenue%></div>
        </div>
      </div>
    </div>

    <!-- REASON BREAKDOWN -->
    <% if(totalCancelled > 0){ %>
    <div class="breakdown-card">
      <div class="breakdown-title"><i class="fa fa-chart-bar"></i> Why Customers Are Cancelling</div>
      <div class="reason-bars">
        <% for(Map.Entry<String,Integer> entry : reasonCounts.entrySet()){
             if(entry.getValue() == 0) continue;
             int pct = (entry.getValue() * 100 / totalCancelled);
             boolean isGray = "Not provided".equals(entry.getKey()); %>
        <div class="reason-bar-row">
          <div class="reason-bar-label" title="<%=entry.getKey()%>"><%=entry.getKey()%></div>
          <div class="reason-bar-track">
            <div class="reason-bar-fill <%=isGray?"gray":""%>" style="width:<%=pct%>%;"></div>
          </div>
          <div class="reason-bar-pct"><%=entry.getValue()%></div>
        </div>
        <% } %>
      </div>
    </div>
    <% } %>

    <!-- CANCELLED ORDERS TABLE -->
    <div class="section">
      <div class="section-header">
        <i class="fa fa-ban" style="color:var(--danger);"></i>
        <h2>Cancelled Orders with Reasons</h2>
        <span class="pill pill-red"><%=totalCancelled%> orders</span>
      </div>
      <div class="toolbar">
        <input class="search-input" type="text" id="cancelSearch"
               placeholder="Search name, email, reason…"
               oninput="filterCancelled()">
        <select class="filter-sel" id="payFilter" onchange="filterCancelled()">
          <option value="">All Payments</option>
          <option value="ONLINE">Online</option>
          <option value="COD">COD</option>
        </select>
        <select class="filter-sel" id="reasonFilter" onchange="filterCancelled()">
          <option value="">All Reasons</option>
          <option value="provided">Has Reason</option>
          <option value="missing">No Reason</option>
        </select>
        <button class="export-btn" onclick="exportCSV()"><i class="fa fa-download"></i> Export CSV</button>
      </div>
      <table id="cancelTable">
        <thead>
          <tr>
            <th>#</th>
            <th>Group</th>
            <th>Customer</th>
            <th>Products</th>
            <th>Amount</th>
            <th>Payment</th>
            <th>Date</th>
            <th>Cancellation Reason</th>
          </tr>
        </thead>
        <tbody>
          <% if(cancelledOrders.isEmpty()){ %>
          <tr class="empty-row">
            <td colspan="8"><i class="fa fa-circle-check" style="color:var(--success);font-size:24px;display:block;margin-bottom:8px;"></i>No cancelled orders — all good!</td>
          </tr>
          <% } else { int n=1; for(Order o : cancelledOrders){
               String pm = o.getPaymentMethod();
               boolean isOnline = pm!=null&&(pm.equalsIgnoreCase("ONLINE")||pm.equalsIgnoreCase("Razorpay")||pm.equalsIgnoreCase("UPI")||pm.equalsIgnoreCase("Card"));
               String reason = o.getCancelReason();
               boolean hasReason = reason != null && !reason.trim().isEmpty()
                                   && !"No reason provided".equalsIgnoreCase(reason.trim());
               String dateStr = o.getOrderDate()!=null ? o.getOrderDate().toString() : "—";
               if(dateStr.length()>10) dateStr = dateStr.substring(0,10);
          %>
          <tr data-pay="<%=isOnline?"ONLINE":"COD"%>" data-hasreason="<%=hasReason?"yes":"no"%>">
            <td style="color:var(--muted);font-size:12px;"><%=n++%></td>
            <td style="font-weight:700;color:var(--primary);">#<%=o.getGroupId()%></td>
            <td>
              <div style="font-weight:600;"><%=o.getName()!=null?o.getName():"—"%></div>
              <div style="font-size:11px;color:var(--muted);"><%=o.getEmail()!=null?o.getEmail():""%></div>
              <div style="font-size:11px;color:var(--muted);"><%=o.getPhone()!=null?o.getPhone():""%></div>
            </td>
            <td style="max-width:160px;font-size:12px;color:var(--muted);"><%=o.getProductName()!=null?o.getProductName():"—"%></td>
            <td style="font-weight:700;">&#8377;<%=(int)o.getTotal()%></td>
            <td><span class="pay-badge <%=isOnline?"pay-online":"pay-cod"%>"><%=isOnline?"ONLINE":"COD"%></span></td>
            <td style="font-size:11px;color:var(--muted);white-space:nowrap;"><%=dateStr%></td>
            <td>
              <% if(hasReason){ %>
              <div class="reason-box">
                <i class="fa fa-comment-dots"></i>
                <span class="reason-box-text"><%=reason.trim()%></span>
              </div>
              <% } else { %>
              <span class="reason-none"><i class="fa fa-minus"></i> Not provided</span>
              <% } %>
            </td>
          </tr>
          <% }} %>
        </tbody>
      </table>
    </div>

    <!-- NOT DELIVERED TABLE -->
    <div class="section">
      <div class="section-header">
        <i class="fa fa-truck" style="color:#ea580c;"></i>
        <h2>Not Yet Delivered — In Transit</h2>
        <span class="pill pill-orange"><%=totalNotDelivered%> orders</span>
      </div>
      <div class="toolbar">
        <input class="search-input" type="text"
               placeholder="Search name, delivery boy, status…"
               oninput="filterTable('notDelivTable',this.value)">
      </div>
      <table id="notDelivTable">
        <thead>
          <tr>
            <th>#</th><th>Group</th><th>Customer</th><th>Products</th>
            <th>Amount</th><th>Payment</th><th>Status</th><th>Delivery Boy</th><th>Date</th>
          </tr>
        </thead>
        <tbody>
          <% if(notDeliveredOrders.isEmpty()){ %>
          <tr class="empty-row">
            <td colspan="10"><i class="fa fa-circle-check" style="color:var(--success);font-size:24px;display:block;margin-bottom:8px;"></i>All orders delivered!</td>
          </tr>
          <% } else { int n=1; for(Order o : notDeliveredOrders){
               String st = o.getStatus()!=null ? o.getStatus() : "";
               String stCls = st.equalsIgnoreCase("Assigned")?"s-assigned":
                 (st.equalsIgnoreCase("Order_Picked_Up")||st.equalsIgnoreCase("Picked"))?"s-picked":"s-shipped";
               String stLabel = st.equalsIgnoreCase("Order_Picked_Up")?"Picked Up":st.replace("_"," ");
               String pm2 = o.getPaymentMethod();
               boolean isOnl2 = pm2!=null&&(pm2.equalsIgnoreCase("ONLINE")||pm2.equalsIgnoreCase("Razorpay"));
               String d2 = o.getOrderDate()!=null?o.getOrderDate().toString():"—";
               if(d2.length()>10) d2=d2.substring(0,10);
          %>
          <tr>
            <td style="color:var(--muted);font-size:12px;"><%=n++%></td>
            <td style="font-weight:700;color:var(--primary);">#<%=o.getGroupId()%></td>
            <td>
              <div style="font-weight:600;"><%=o.getName()!=null?o.getName():"—"%></div>
              <div style="font-size:11px;color:var(--muted);"><%=o.getPhone()!=null?o.getPhone():""%></div>
            </td>
            <td style="max-width:140px;font-size:12px;color:var(--muted);"><%=o.getProductName()!=null?o.getProductName():"—"%></td>
            <td style="font-weight:700;">&#8377;<%=(int)o.getTotal()%></td>
            <td><span class="pay-badge <%=isOnl2?"pay-online":"pay-cod"%>"><%=isOnl2?"ONLINE":"COD"%></span></td>
            <td><span class="status-pill <%=stCls%>"><i class="fa fa-circle" style="font-size:7px;"></i> <%=stLabel%></span></td>
            <td style="font-size:13px;font-weight:500;">
              <% String db=o.getDeliveryBoy(); %>
              <% if(db!=null&&!db.isEmpty()){ %><i class="fa fa-motorcycle" style="color:var(--muted);margin-right:4px;"></i><%=db%>
              <% }else{ %><span style="color:var(--muted);font-style:italic;">Unassigned</span><% } %>
            </td>
            <td style="font-size:11px;color:var(--muted);white-space:nowrap;"><%=d2%></td>
            <td>
              <div style="display:flex;flex-direction:column;gap:6px;min-width:180px;">
                <% String ph2 = o.getPhone(); %>
                <% if(ph2!=null&&!ph2.isEmpty()){ %>
                <a href="tel:<%=ph2%>"
                   style="display:flex;align-items:center;justify-content:center;gap:5px;padding:5px 10px;background:#f0fdf4;color:#16a34a;border:1px solid #86efac;border-radius:7px;font-size:12px;font-weight:600;text-decoration:none;">
                  <i class="fa fa-phone"></i> Call Customer
                </a>
                <% } %>
                <!-- Reassign delivery boy -->
                <form method="post" action="AssignDeliveryServlet"
                      onsubmit="return confirm('Reassign this order to a new delivery boy?')">
                  <input type="hidden" name="groupId" value="<%=o.getGroupId()%>">
                  <button type="submit"
                          style="width:100%;padding:5px 10px;background:#eff6ff;color:#1d4ed8;border:1px solid #93c5fd;border-radius:7px;font-size:12px;font-weight:600;cursor:pointer;">
                    <i class="fa fa-person-biking"></i> Reassign Boy
                  </button>
                </form>

              </div>
            </td>
          </tr>
          <% }} %>
        </tbody>
      </table>
    </div>

    <!-- CUSTOMER NOT RESPONDING TABLE -->
    <%
    java.util.List<Order> noResponseOrders = dao.getOrdersByStatus("Customer_Not_Responding");
    int totalNoResponse = noResponseOrders.size();
    %>
    <div class="section" style="border-left:4px solid #7c3aed;">
      <div class="section-header">
        <i class="fa fa-user-slash" style="color:#7c3aed;font-size:18px;"></i>
        <h2>Customer Not Responding</h2>
        <span class="pill" style="background:#f5f3ff;color:#7c3aed;"><%=totalNoResponse%> orders</span>
        <span style="font-size:12px;color:var(--muted);margin-left:auto;">Delivery attempted but customer unreachable — take action below</span>
      </div>
      <div class="toolbar">
        <input class="search-input" type="text"
               placeholder="Search name, phone, delivery boy…"
               oninput="filterTable('noRespTable',this.value)">
      </div>
      <table id="noRespTable">
        <thead>
          <tr>
            <th>#</th><th>Group</th><th>Customer</th><th>Products</th>
            <th>Amount</th><th>Payment</th><th>Delivery Boy</th><th>Date</th><th>Action</th>
          </tr>
        </thead>
        <tbody>
          <% if(noResponseOrders.isEmpty()){ %>
          <tr class="empty-row">
            <td colspan="9"><i class="fa fa-thumbs-up" style="color:var(--success);font-size:24px;display:block;margin-bottom:8px;"></i>No unresponsive customers — all good!</td>
          </tr>
          <% } else { int n=1; for(Order o : noResponseOrders){
               String pm3 = o.getPaymentMethod();
               boolean isOnl3 = pm3!=null&&(pm3.equalsIgnoreCase("ONLINE")||pm3.equalsIgnoreCase("Razorpay"));
               String d3 = o.getOrderDate()!=null?o.getOrderDate().toString():"—";
               if(d3.length()>10) d3=d3.substring(0,10);
          %>
          <tr>
            <td style="color:var(--muted);font-size:12px;"><%=n++%></td>
            <td style="font-weight:700;color:#7c3aed;">#<%=o.getGroupId()%></td>
            <td>
              <div style="font-weight:600;"><%=o.getName()!=null?o.getName():"—"%></div>
              <div style="font-size:11px;color:var(--muted);"><%=o.getEmail()!=null?o.getEmail():""%></div>
              <div style="font-size:11px;">
                <a href="tel:<%=o.getPhone()%>" style="color:var(--primary);font-weight:600;">
                  <i class="fa fa-phone" style="font-size:10px;"></i> <%=o.getPhone()!=null?o.getPhone():""%>
                </a>
              </div>
            </td>
            <td style="max-width:130px;font-size:12px;color:var(--muted);"><%=o.getProductName()!=null?o.getProductName():"—"%></td>
            <td style="font-weight:700;">&#8377;<%=(int)o.getTotal()%></td>
            <td><span class="pay-badge <%=isOnl3?"pay-online":"pay-cod"%>"><%=isOnl3?"ONLINE":"COD"%></span></td>
            <td style="font-size:13px;font-weight:500;">
              <% String db3=o.getDeliveryBoy(); %>
              <% if(db3!=null&&!db3.isEmpty()){ %>
                <i class="fa fa-motorcycle" style="color:var(--muted);margin-right:4px;"></i><%=db3%>
              <% }else{ %><span style="color:var(--muted);font-style:italic;">Unassigned</span><% } %>
            </td>
            <td style="font-size:11px;color:var(--muted);white-space:nowrap;"><%=d3%></td>
            <td>
              <div style="display:flex;flex-direction:column;gap:6px;min-width:160px;">
                <button type="button"
                        onclick="openActionModal(<%=o.getGroupId()%>,'<%=o.getName()!=null?o.getName().replace("'","\\'"):""%>','<%=o.getPhone()!=null?o.getPhone():""%>','<%=o.getProductName()!=null?o.getProductName().replace("'","\\'"):""%>')"
                        style="width:100%;padding:7px 10px;background:#f0fdf4;color:#16a34a;border:1px solid #86efac;border-radius:7px;font-size:12px;font-weight:600;cursor:pointer;">
                  <i class="fa fa-phone-volume"></i> Take Action
                </button>
              </div>
            </td>
          </tr>
          <% }} %>
        </tbody>
      </table>
    </div>

  </div>
</div>

<script>
function filterCancelled(){
  var q  = document.getElementById('cancelSearch').value.toLowerCase();
  var pf = document.getElementById('payFilter').value.toUpperCase();
  var rf = document.getElementById('reasonFilter').value;
  document.querySelectorAll('#cancelTable tbody tr:not(.empty-row)').forEach(function(row){
    var textOk   = !q  || row.textContent.toLowerCase().includes(q);
    var payOk    = !pf || row.dataset.pay === pf;
    var reasonOk = !rf || (rf==='provided' && row.dataset.hasreason==='yes')
                       || (rf==='missing'  && row.dataset.hasreason==='no');
    row.style.display = (textOk && payOk && reasonOk) ? '' : 'none';
  });
}
function filterTable(tid, q){
  q = q.toLowerCase();
  document.querySelectorAll('#'+tid+' tbody tr:not(.empty-row)').forEach(function(r){
    r.style.display = (!q || r.textContent.toLowerCase().includes(q)) ? '' : 'none';
  });
}
function exportCSV(){
  var rows=[['#','Group','Customer','Email','Phone','Products','Amount','Payment','Date','Reason']];
  document.querySelectorAll('#cancelTable tbody tr:not(.empty-row)').forEach(function(row){
    if(row.style.display==='none') return;
    var c=row.querySelectorAll('td');
    rows.push([
      c[0].textContent.trim(), c[1].textContent.trim(),
      c[2].querySelector('div').textContent.trim(),
      (c[2].querySelectorAll('div')[1]||{textContent:''}).textContent.trim(),
      (c[2].querySelectorAll('div')[2]||{textContent:''}).textContent.trim(),
      c[3].textContent.trim(), c[4].textContent.trim(),
      c[5].textContent.trim(), c[6].textContent.trim(),
      c[7].textContent.trim()
    ]);
  });
  var csv=rows.map(function(r){return r.map(function(c){return '"'+c.replace(/"/g,'""')+'"';}).join(',');}).join('\n');
  var a=document.createElement('a');
  a.href='data:text/csv;charset=utf-8,'+encodeURIComponent(csv);
  a.download='cancelled-orders.csv';
  a.click();
}
</script>

<!-- ══ Customer Not Responding — Staff Action Modal ══════════════════ -->
<div id="actionModal" style="display:none;position:fixed;inset:0;background:rgba(0,0,0,0.5);z-index:9999;align-items:center;justify-content:center;">
  <div style="background:#fff;border-radius:16px;padding:0;max-width:500px;width:93%;box-shadow:0 8px 40px rgba(0,0,0,0.2);overflow:hidden;">

    <!-- Header -->
    <div style="background:#7c3aed;padding:20px 24px;color:#fff;">
      <div style="font-size:15px;font-weight:700;margin-bottom:2px;">
        <i class="fa fa-user-slash" style="margin-right:8px;"></i>Customer Not Responding
      </div>
      <div id="amCustomer" style="font-size:13px;opacity:0.85;"></div>
    </div>

    <!-- Step 1: Staff confirms they called -->
    <div style="padding:20px 24px 0;">
      <div style="background:#fefce8;border:1px solid #fde047;border-radius:10px;padding:14px 16px;margin-bottom:18px;">
        <div style="font-weight:700;font-size:13px;color:#854d0e;margin-bottom:6px;">
          <i class="fa fa-phone" style="margin-right:6px;"></i>Step 1 — Contact the Customer
        </div>
        <div style="font-size:12px;color:#713f12;margin-bottom:10px;">Call the customer to confirm availability before taking action.</div>
        <a id="amCallBtn" href="#" style="display:inline-flex;align-items:center;gap:6px;background:#16a34a;color:#fff;padding:7px 16px;border-radius:7px;font-size:12px;font-weight:700;text-decoration:none;">
          <i class="fa fa-phone"></i> Call Customer
        </a>
        <label style="display:flex;align-items:center;gap:8px;margin-top:12px;font-size:12px;font-weight:600;color:#374151;cursor:pointer;">
          <input type="checkbox" id="amConfirmCall" onchange="toggleActionPanel(this.checked)"
                 style="width:16px;height:16px;accent-color:#7c3aed;">
          I have contacted / attempted to contact the customer
        </label>
      </div>

      <!-- Step 2: Actions (hidden until checkbox ticked) -->
      <div id="amActionPanel" style="display:none;">
        <div style="font-weight:700;font-size:13px;color:#374151;margin-bottom:14px;">
          <i class="fa fa-circle-question" style="margin-right:6px;color:#7c3aed;"></i>Step 2 — What did the customer say?
        </div>

        <!-- Tab buttons -->
        <div style="display:flex;gap:8px;margin-bottom:16px;">
          <button onclick="showTab('reattempt')" id="tabReattempt"
            style="flex:1;padding:9px;border-radius:8px;font-size:12px;font-weight:700;cursor:pointer;border:2px solid #16a34a;background:#f0fdf4;color:#16a34a;">
            <i class="fa fa-rotate-right"></i> Customer Responded — Reattempt
          </button>
          <button onclick="showTab('cancel')" id="tabCancel"
            style="flex:1;padding:9px;border-radius:8px;font-size:12px;font-weight:700;cursor:pointer;border:2px solid #e5e7eb;background:#fff;color:#6b7280;">
            <i class="fa fa-xmark"></i> Still Unreachable — Cancel
          </button>
        </div>

        <!-- Reattempt Panel -->
        <div id="panelReattempt">
          <form action="staffNoResponseAction" method="post">
            <input type="hidden" name="action" value="reattempt">
            <input type="hidden" name="groupId" id="amGroupIdR">
            <div style="margin-bottom:12px;">
              <label style="display:block;font-size:11px;font-weight:600;color:#6b7280;margin-bottom:5px;text-transform:uppercase;letter-spacing:.4px;">New Delivery Address <span style="color:#ef4444;">*</span></label>
              <textarea name="newAddress" required placeholder="Confirm or update the delivery address…"
                style="width:100%;border:1.5px solid #d1d5db;border-radius:8px;padding:9px 11px;font-size:13px;resize:none;min-height:58px;font-family:inherit;color:#111;"></textarea>
            </div>
            <div style="margin-bottom:12px;">
              <label style="display:block;font-size:11px;font-weight:600;color:#6b7280;margin-bottom:5px;text-transform:uppercase;letter-spacing:.4px;">Assign Delivery Boy <span style="color:#ef4444;">*</span></label>
              <select name="deliveryBoyId" required style="width:100%;border:1.5px solid #d1d5db;border-radius:8px;padding:9px 11px;font-size:13px;color:#111;background:#fff;">
                <option value="">-- Select Delivery Boy --</option>
                <% for(DeliveryBoy rdb : deliveryBoys){ %>
                  <option value="<%=rdb.getId()%>"><%=rdb.getName()%> — <%=rdb.getPhone()%><%= rdb.isOnline() ? " 🟢 Online" : " ⚫ Offline" %></option>
                <% } %>
              </select>
            </div>
            <div style="margin-bottom:16px;">
              <label style="display:block;font-size:11px;font-weight:600;color:#6b7280;margin-bottom:5px;text-transform:uppercase;letter-spacing:.4px;">Staff Note (optional)</label>
              <input type="text" name="staffNote" placeholder="e.g. Customer will be home after 5pm…"
                style="width:100%;border:1.5px solid #d1d5db;border-radius:8px;padding:9px 11px;font-size:13px;color:#111;">
            </div>
            <div style="display:flex;gap:10px;padding-bottom:20px;">
              <button type="button" onclick="closeActionModal()"
                style="flex:1;padding:10px;border:1.5px solid #d1d5db;border-radius:8px;font-size:13px;font-weight:600;background:#fff;cursor:pointer;color:#374151;">
                Cancel
              </button>
              <button type="submit"
                style="flex:2;padding:10px;background:#16a34a;color:#fff;border:none;border-radius:8px;font-size:13px;font-weight:700;cursor:pointer;">
                <i class="fa fa-rotate-right"></i> Confirm Re-delivery &amp; Notify Boy
              </button>
            </div>
          </form>
        </div>

        <!-- Cancel Panel -->
        <div id="panelCancel" style="display:none;">
          <form action="staffNoResponseAction" method="post">
            <input type="hidden" name="action" value="cancel">
            <input type="hidden" name="groupId" id="amGroupIdC">
            <div style="margin-bottom:12px;">
              <label style="display:block;font-size:11px;font-weight:600;color:#6b7280;margin-bottom:5px;text-transform:uppercase;letter-spacing:.4px;">Cancel Reason <span style="color:#ef4444;">*</span></label>
              <select name="cancelReason" required style="width:100%;border:1.5px solid #d1d5db;border-radius:8px;padding:9px 11px;font-size:13px;color:#111;background:#fff;">
                <option value="">-- Select a reason --</option>
                <option>Customer not reachable after multiple attempts</option>
                <option>Customer refused delivery</option>
                <option>Wrong address — customer uncontactable</option>
                <option>Customer requested cancellation</option>
                <option>Other</option>
              </select>
            </div>
            <div style="margin-bottom:16px;">
              <label style="display:block;font-size:11px;font-weight:600;color:#6b7280;margin-bottom:5px;text-transform:uppercase;letter-spacing:.4px;">Staff Note (optional)</label>
              <input type="text" name="staffNote" placeholder="Any additional details…"
                style="width:100%;border:1.5px solid #d1d5db;border-radius:8px;padding:9px 11px;font-size:13px;color:#111;">
            </div>
            <div style="background:#fef2f2;border:1px solid #fca5a5;border-radius:8px;padding:10px 14px;margin-bottom:14px;font-size:12px;color:#dc2626;font-weight:600;">
              <i class="fa fa-triangle-exclamation" style="margin-right:6px;"></i>
              This will cancel the order, restore stock, and notify the delivery boy and customer.
            </div>
            <div style="display:flex;gap:10px;padding-bottom:20px;">
              <button type="button" onclick="closeActionModal()"
                style="flex:1;padding:10px;border:1.5px solid #d1d5db;border-radius:8px;font-size:13px;font-weight:600;background:#fff;cursor:pointer;color:#374151;">
                Back
              </button>
              <button type="submit" onclick="return confirm('Cancel this order? This cannot be undone.')"
                style="flex:2;padding:10px;background:#dc2626;color:#fff;border:none;border-radius:8px;font-size:13px;font-weight:700;cursor:pointer;">
                <i class="fa fa-xmark"></i> Cancel Order &amp; Notify All
              </button>
            </div>
          </form>
        </div>

      </div><!-- /amActionPanel -->
    </div><!-- /padding -->
  </div>
</div>

<script>
function openActionModal(groupId, name, phone, product) {
  document.getElementById('amGroupIdR').value = groupId;
  document.getElementById('amGroupIdC').value = groupId;
  document.getElementById('amCustomer').textContent = name + ' · ' + phone + ' · ' + product;
  document.getElementById('amCallBtn').href = 'tel:' + phone;
  document.getElementById('amConfirmCall').checked = false;
  document.getElementById('amActionPanel').style.display = 'none';
  showTab('reattempt');
  document.getElementById('actionModal').style.display = 'flex';
}
function closeActionModal() {
  document.getElementById('actionModal').style.display = 'none';
}
function toggleActionPanel(checked) {
  document.getElementById('amActionPanel').style.display = checked ? 'block' : 'none';
}
function showTab(tab) {
  var isR = tab === 'reattempt';
  document.getElementById('panelReattempt').style.display = isR ? 'block' : 'none';
  document.getElementById('panelCancel').style.display    = isR ? 'none'  : 'block';
  document.getElementById('tabReattempt').style.cssText +=
    isR ? ';border-color:#16a34a;background:#f0fdf4;color:#16a34a;'
        : ';border-color:#e5e7eb;background:#fff;color:#6b7280;';
  document.getElementById('tabCancel').style.cssText +=
    !isR ? ';border-color:#dc2626;background:#fef2f2;color:#dc2626;'
         : ';border-color:#e5e7eb;background:#fff;color:#6b7280;';
}
document.getElementById('actionModal').addEventListener('click', function(e) {
  if (e.target === this) closeActionModal();
});
</script>
</body>
</html>
