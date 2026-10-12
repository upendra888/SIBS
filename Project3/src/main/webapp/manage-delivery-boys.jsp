<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.util.*,com.sibs.dao.DeliveryBoyDAO,com.sibs.model.DeliveryBoy,com.sibs.model.User" %>
<%
User user = (User)session.getAttribute("user");
if(user == null || (!"STAFF".equals(user.getRole()) && !"ADMIN".equals(user.getRole()))){
    response.sendRedirect("login.jsp");
    return;
}
DeliveryBoyDAO dao = new DeliveryBoyDAO();
List<DeliveryBoy> list = dao.getAllDeliveryBoys();
String msg   = request.getParameter("msg");
String error = request.getParameter("error");
%>
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Manage Delivery Boys — SIBS</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<style>
:root{--bg:#f8fafc;--surface:#fff;--border:#e2e8f0;--text:#0f172a;--muted:#64748b;--primary:#2563eb;}
[data-theme="dark"]{--bg:#0f172a;--surface:#1e293b;--border:#334155;--text:#f1f5f9;--muted:#94a3b8;}
*{margin:0;padding:0;box-sizing:border-box;font-family:'Inter',sans-serif;}
body{background:var(--bg);color:var(--text);}
.topbar{background:var(--surface);border-bottom:1px solid var(--border);padding:0 24px;height:60px;display:flex;align-items:center;justify-content:space-between;position:sticky;top:0;z-index:50;box-shadow:0 1px 3px rgba(0,0,0,.06);}
.topbar-left{display:flex;align-items:center;gap:10px;}
.topbar-left a{color:var(--muted);text-decoration:none;font-size:13px;display:flex;align-items:center;gap:5px;}
.topbar-left a:hover{color:var(--primary);}
.page-title{font-weight:700;font-size:16px;}
.topbar-right{display:flex;gap:10px;align-items:center;}
.dark-btn{background:none;border:1px solid var(--border);width:34px;height:34px;border-radius:8px;cursor:pointer;color:var(--muted);}
.content{padding:24px;}
.top-row{display:flex;justify-content:space-between;align-items:center;margin-bottom:20px;flex-wrap:wrap;gap:10px;}
.section-title{font-size:18px;font-weight:700;}
.alert{padding:10px 16px;border-radius:8px;font-size:13px;margin-bottom:16px;display:flex;align-items:center;gap:8px;}
.alert-success{background:#f0fdf4;border:1px solid #bbf7d0;color:#16a34a;}
.alert-error{background:#fef2f2;border:1px solid #fecaca;color:#dc2626;}
.table-wrap{background:var(--surface);border:1px solid var(--border);border-radius:12px;overflow:hidden;box-shadow:0 1px 3px rgba(0,0,0,.06);}
table{width:100%;border-collapse:collapse;}
th{padding:12px 16px;text-align:left;font-size:11px;font-weight:600;color:var(--muted);text-transform:uppercase;letter-spacing:.4px;background:var(--bg);border-bottom:1px solid var(--border);}
td{padding:13px 16px;font-size:13px;border-bottom:1px solid var(--border);vertical-align:middle;}
tbody tr:last-child td{border-bottom:none;}
tbody tr:hover{background:var(--bg);}
.badge{padding:4px 10px;border-radius:999px;font-size:11px;font-weight:600;color:#fff;}
.active-badge{background:#16a34a;}
.inactive-badge{background:#ef4444;}
.avatar{width:34px;height:34px;border-radius:50%;background:#f97316;display:flex;align-items:center;justify-content:center;color:#fff;font-weight:700;font-size:14px;}
.name-cell{display:flex;align-items:center;gap:10px;}
.delete-btn{padding:6px 12px;background:#ef4444;color:#fff;border:none;border-radius:6px;font-size:12px;cursor:pointer;}
.delete-btn:hover{opacity:.85;}
.empty{text-align:center;padding:40px;color:var(--muted);}
</style>
</head>
<body>

<div class="topbar">
  <div class="topbar-left">
    <a href="staff-dashboard.jsp"><i class="fa fa-arrow-left"></i> Dashboard</a>
    <span style="color:var(--border);">|</span>
    <span class="page-title">Manage Delivery Boys</span>
  </div>
  <div class="topbar-right">
    <button class="dark-btn" onclick="toggleDark()"><i class="fa fa-moon"></i></button>
  </div>
</div>

<div class="content">

  <% if(msg != null){ %>
  <div class="alert alert-success"><i class="fa fa-circle-check"></i> <%=msg%></div>
  <% } %>
  <% if(error != null){ %>
  <div class="alert alert-error"><i class="fa fa-circle-exclamation"></i> <%=error%></div>
  <% } %>

  <div class="top-row">
    <div class="section-title">Delivery Boys (<%=list.size()%>)</div>
  </div>

  <div class="table-wrap">
    <table>
      <thead>
        <tr>
          <th>#</th>
          <th>Name</th>
          <th>Phone</th>
          <th>Email</th>
          <th>Status</th>
          <th>Joined</th>
          <th>Action</th>
        </tr>
      </thead>
      <tbody>
      <%
      if(list.isEmpty()){
      %>
        <tr><td colspan="7" class="empty"><i class="fa fa-motorcycle"></i> No delivery boys registered yet</td></tr>
      <%
      } else {
        for(DeliveryBoy db : list){
      %>
        <tr>
          <td style="color:var(--muted);"><%=db.getId()%></td>
          <td>
            <div class="name-cell">
              <div class="avatar"><%=db.getName().substring(0,1).toUpperCase()%></div>
              <b><%=db.getName()%></b>
            </div>
          </td>
          <td><%=db.getPhone()%></td>
          <td><%=db.getEmail()%></td>
          <td>
            <span class="badge <%="Active".equals(db.getStatus()) ? "active-badge" : "inactive-badge"%>">
              <%=db.getStatus()%>
            </span>
          </td>
          <td style="font-size:12px;color:var(--muted);"><%=db.getCreatedAt()%></td>
          <td>
            <form action="deleteDeliveryBoy" method="post" style="display:inline;"
                  onsubmit="return confirm('Delete <%=db.getName()%>?')">
              <input type="hidden" name="id" value="<%=db.getId()%>">
              <button class="delete-btn" type="submit">
                <i class="fa fa-trash"></i> Delete
              </button>
            </form>
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
</script>
</body>
</html>
