<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.util.*,com.sibs.dao.OrderDAO,com.sibs.model.Order,com.sibs.model.User" %>
<%
User user = (User)session.getAttribute("user");
if(user == null || !"ADMIN".equals(user.getRole())){
    response.sendRedirect("login.jsp");
    return;
}
OrderDAO dao = new OrderDAO();
List<Order> list = dao.getOrdersWithProduct();
int pending   = 0;
int approved  = 0;
int packed    = 0;
int assigned  = 0;
int picked    = 0;
int outForDel = 0;
int delivered = 0;
int rejected  = 0;
for(Order o : list){
  String s = o.getStatus();
  if("Pending".equals(s)) pending++;
  else if("Approved".equals(s)) approved++;
  else if("Packed".equals(s)) packed++;
  else if("Assigned".equals(s)) assigned++;
  else if("Picked".equals(s)) picked++;
  else if("Out for Delivery".equals(s)) outForDel++;
  else if("Delivered".equals(s)) delivered++;
  else if("Rejected".equals(s)) rejected++;
}
%>
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Order Management — SIBS</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<style>
:root{--bg:#f8fafc;--surface:#fff;--border:#e2e8f0;--text:#0f172a;--muted:#64748b;--primary:#2563eb;--success:#16a34a;--danger:#ef4444;--warn:#f59e0b;}
[data-theme="dark"]{--bg:#0f172a;--surface:#1e293b;--border:#334155;--text:#f1f5f9;--muted:#94a3b8;}
*{margin:0;padding:0;box-sizing:border-box;font-family:'Inter',sans-serif;}
body{background:var(--bg);color:var(--text);}
.topbar{background:var(--surface);border-bottom:1px solid var(--border);padding:0 24px;height:60px;display:flex;align-items:center;justify-content:space-between;position:sticky;top:0;z-index:50;box-shadow:0 1px 3px rgba(0,0,0,.06);}
.topbar-left{display:flex;align-items:center;gap:12px;}
.topbar-left a{color:var(--muted);text-decoration:none;font-size:13px;display:flex;align-items:center;gap:5px;}
.topbar-left a:hover{color:var(--primary);}
.page-title{font-weight:700;font-size:16px;}
.topbar-right{display:flex;gap:10px;align-items:center;}
.dark-btn{background:none;border:1px solid var(--border);width:34px;height:34px;border-radius:8px;cursor:pointer;color:var(--muted);}
.realtime{font-size:11px;color:#22c55e;display:flex;align-items:center;gap:5px;}
.realtime-dot{width:7px;height:7px;background:#22c55e;border-radius:50%;animation:pulse 2s infinite;}
@keyframes pulse{0%,100%{opacity:1;}50%{opacity:.4;}}
.content{padding:24px;}
.stat-row{display:grid;grid-template-columns:repeat(auto-fit,minmax(140px,1fr));gap:12px;margin-bottom:20px;}
.stat-box{background:var(--surface);border:1px solid var(--border);border-radius:10px;padding:16px;text-align:center;}
.stat-box .num{font-size:26px;font-weight:700;}
.stat-box .lbl{font-size:12px;color:var(--muted);margin-top:2px;}
.controls{display:flex;gap:10px;margin-bottom:14px;flex-wrap:wrap;}
.controls input,.controls select{padding:9px 14px;border:1px solid var(--border);border-radius:8px;background:var(--surface);color:var(--text);font-size:13px;outline:none;}
.controls input:focus,.controls select:focus{border-color:var(--primary);}
.controls input{min-width:220px;}
.table-wrap{background:var(--surface);border:1px solid var(--border);border-radius:12px;overflow:hidden;box-shadow:0 1px 3px rgba(0,0,0,.06);}
table{width:100%;border-collapse:collapse;}
thead tr{background:var(--bg);}
th{padding:13px 14px;text-align:left;font-size:12px;font-weight:600;color:var(--muted);text-transform:uppercase;letter-spacing:.4px;border-bottom:1px solid var(--border);}
td{padding:13px 14px;font-size:13px;border-bottom:1px solid var(--border);vertical-align:middle;}
tbody tr:last-child td{border-bottom:none;}
tbody tr:hover{background:var(--bg);}
.badge{padding:4px 10px;border-radius:999px;font-size:11px;font-weight:600;color:#fff;white-space:nowrap;}
.pending{background:#f59e0b;}
.approved{background:#16a34a;}
.rejected{background:#ef4444;}
.packed{background:#8b5cf6;}
.assigned{background:#0284c7;}
.picked{background:#ea580c;}
.outfordelivery{background:#ca8a04;}
.shipped{background:#2563eb;}
.delivered{background:#7c3aed;}
.monitor-tag{font-size:12px;color:var(--muted);font-style:italic;}
.delivery-boy-tag{font-size:12px;color:var(--muted);display:flex;align-items:center;gap:4px;}
.empty-row td{text-align:center;padding:40px;color:var(--muted);}
</style>
</head>
<body>

<div class="topbar">
  <div class="topbar-left">
    <a href="dashboard.jsp"><i class="fa fa-arrow-left"></i> Dashboard</a>
    <span style="color:var(--border);">|</span>
    <span class="page-title">Order Management</span>
  </div>
  <div class="topbar-right">
    <div class="realtime"><div class="realtime-dot"></div> Live</div>
    <button class="dark-btn" onclick="toggleDark()"><i class="fa fa-moon"></i></button>
  </div>
</div>

<div class="content">

  <!-- STAT SUMMARY -->
  <div class="stat-row">
    <div class="stat-box"><div class="num"><%=list.size()%></div><div class="lbl">Total Orders</div></div>
    <div class="stat-box"><div class="num" style="color:#f59e0b;"><%=pending%></div><div class="lbl">Pending</div></div>
    <div class="stat-box"><div class="num" style="color:#16a34a;"><%=approved%></div><div class="lbl">Approved</div></div>
    <div class="stat-box"><div class="num" style="color:#8b5cf6;"><%=packed%></div><div class="lbl">Packed</div></div>
    <div class="stat-box"><div class="num" style="color:#0284c7;"><%=assigned%></div><div class="lbl">Assigned</div></div>
    <div class="stat-box"><div class="num" style="color:#ea580c;"><%=picked%></div><div class="lbl">Picked</div></div>
    <div class="stat-box"><div class="num" style="color:#ca8a04;"><%=outForDel%></div><div class="lbl">Out for Delivery</div></div>
    <div class="stat-box"><div class="num" style="color:#7c3aed;"><%=delivered%></div><div class="lbl">Delivered</div></div>
    <div class="stat-box"><div class="num" style="color:#ef4444;"><%=rejected%></div><div class="lbl">Rejected</div></div>
  </div>

  <!-- CONTROLS -->
  <div class="controls">
    <input type="text" id="search" placeholder="🔍 Search orders..." oninput="applyFilters()">
    <select id="statusFilter" onchange="applyFilters()">
      <option value="All">All Status</option>
      <option>Pending</option>
      <option>Approved</option>
      <option>Packed</option>
      <option>Assigned</option>
      <option>Picked</option>
      <option>Out for Delivery</option>
      <option>Rejected</option>
      <option>Delivered</option>
    </select>
  </div>

  <!-- TABLE -->
  <div class="table-wrap">
    <table>
      <thead>
        <tr>
          <th>#</th>
          <th>Customer</th>
          <th>Phone</th>
          <th>Product</th>
          <th>Qty</th>
          <th>Total</th>
          <th>Payment</th>
          <th>Delivery Boy</th>
          <th>Status</th>
          <th>Action</th>
        </tr>
      </thead>
      <tbody id="orderTable">
      <%
      if(list == null || list.isEmpty()){
      %>
      <tr class="empty-row"><td colspan="9"><i class="fa fa-box-open"></i> No orders found</td></tr>
      <%
      } else {
        for(Order o : list){
          String status = o.getStatus();
          if(status == null) status = "Pending";
          String cls = "pending";
          if("Approved".equals(status)) cls="approved";
          else if("Rejected".equals(status)) cls="rejected";
          else if("Packed".equals(status)) cls="packed";
          else if("Assigned".equals(status)) cls="assigned";
          else if("Picked".equals(status)) cls="picked";
          else if("Out for Delivery".equals(status)) cls="outfordelivery";
          else if("Shipped".equals(status)) cls="shipped";
          else if("Delivered".equals(status)) cls="delivered";
      %>
      <tr data-status="<%=status%>">
        <td style="color:var(--muted);"><%=o.getId()%></td>
        <td><b><%=o.getName()%></b></td>
        <td><%=o.getPhone()%></td>
        <td><%=o.getProductName()%></td>
        <td><%=o.getQuantity()%></td>
        <td><b>₹<%=o.getTotal()%></b></td>
        <td><%=o.getPaymentMethod() != null ? o.getPaymentMethod() : "COD"%></td>
        <td>
          <% if(o.getDeliveryBoy() != null && !o.getDeliveryBoy().isEmpty()){ %>
            <span class="delivery-boy-tag">
              <i class="fa fa-motorcycle"></i> <%=o.getDeliveryBoy()%>
            </span>
          <% } else { %>
            <span style="font-size:12px;color:var(--muted);">—</span>
          <% } %>
        </td>
        <td><span class="badge <%=cls%>"><%=status%></span></td>
        <td>
          <% if("Pending".equals(status)){ %>
            <form method="post" action="updateOrder" style="display:inline">
              <input type="hidden" name="orderId" value="<%=o.getId()%>">
              <input type="hidden" name="status" value="Approved">
              <button type="submit" style="background:#16a34a;color:#fff;border:none;padding:5px 12px;border-radius:6px;cursor:pointer;font-size:12px;font-weight:600;margin-right:4px;">✔ Approve</button>
            </form>
            <form method="post" action="updateOrder" style="display:inline">
              <input type="hidden" name="orderId" value="<%=o.getId()%>">
              <input type="hidden" name="status" value="Rejected">
              <button type="submit" style="background:#ef4444;color:#fff;border:none;padding:5px 12px;border-radius:6px;cursor:pointer;font-size:12px;font-weight:600;" onclick="return confirm('Reject this order?')">✘ Reject</button>
            </form>
          <% } else if(!"Delivered".equals(status) && !"Rejected".equals(status)){ %>
            <form method="post" action="updateOrder" style="display:flex;align-items:center;gap:6px;">
              <input type="hidden" name="orderId" value="<%=o.getId()%>">
              <select name="status" style="padding:5px 8px;border:1px solid var(--border);border-radius:6px;background:var(--surface);color:var(--text);font-size:12px;">
                <option <%="Approved".equals(status)?"selected":""%>>Approved</option>
                <option <%="Packed".equals(status)?"selected":""%>>Packed</option>
                <option <%="Assigned".equals(status)?"selected":""%>>Assigned</option>
                <option <%="Picked".equals(status)?"selected":""%>>Picked</option>
                <option <%="Out for Delivery".equals(status)?"selected":""%>>Out for Delivery</option>
                <option <%="Delivered".equals(status)?"selected":""%>>Delivered</option>
              </select>
              <button type="submit" style="background:var(--primary);color:#fff;border:none;padding:5px 10px;border-radius:6px;cursor:pointer;font-size:12px;font-weight:600;">Update</button>
            </form>
          <% } else { %>
            <span style="font-size:12px;color:var(--muted);">—</span>
          <% } %>
        </td>
      </tr>
      <% } } %>
      </tbody>
    </table>
  </div>
</div>

<script>
function toggleDark(){
  const h=document.documentElement,d=h.getAttribute('data-theme')==='dark';
  h.setAttribute('data-theme',d?'light':'dark');
  localStorage.setItem('sibs-theme',d?'light':'dark');
}
(function(){const t=localStorage.getItem('sibs-theme');if(t)document.documentElement.setAttribute('data-theme',t);})();
function applyFilters(){
  const q=document.getElementById('search').value.toLowerCase();
  const s=document.getElementById('statusFilter').value;
  document.querySelectorAll('#orderTable tr').forEach(row=>{
    if(row.classList.contains('empty-row')){return;}
    const text=row.textContent.toLowerCase();
    const status=row.getAttribute('data-status')||'';
    const mQ=!q||text.includes(q);
    const mS=s==='All'||status===s;
    row.style.display=(mQ&&mS)?'':'none';
  });
}
setTimeout(()=>{if(!document.hidden)window.location.reload();},30000);
</script>
</body>
</html>