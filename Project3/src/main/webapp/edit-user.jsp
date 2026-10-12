<%@ page import="com.sibs.model.User, com.sibs.dao.UserDAO" %>
<%
User sessionUser = (User)session.getAttribute("user");
if(sessionUser == null || !"ADMIN".equals(sessionUser.getRole())){
    response.sendRedirect("login.jsp");
    return;
}
String idStr = request.getParameter("id");
if(idStr == null){ response.sendRedirect("users.jsp"); return; }
int id = Integer.parseInt(idStr);
UserDAO dao  = new UserDAO();
User user    = dao.getUserById(id);
if(user == null){ response.sendRedirect("users.jsp"); return; }
String success = request.getParameter("success");
String error   = request.getParameter("error");
%>
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Edit User — SIBS</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<style>
:root{--bg:#f8fafc;--surface:#fff;--border:#e2e8f0;--text:#0f172a;--muted:#64748b;--primary:#2563eb;--success:#16a34a;--warn:#f59e0b;}
[data-theme="dark"]{--bg:#0f172a;--surface:#1e293b;--border:#334155;--text:#f1f5f9;--muted:#94a3b8;}
*{margin:0;padding:0;box-sizing:border-box;font-family:'Inter',sans-serif;}
body{background:var(--bg);color:var(--text);min-height:100vh;}
.topbar{background:var(--surface);border-bottom:1px solid var(--border);padding:0 24px;height:60px;display:flex;align-items:center;gap:10px;position:sticky;top:0;z-index:50;}
.topbar a{color:var(--muted);text-decoration:none;font-size:13px;display:flex;align-items:center;gap:5px;}
.topbar a:hover{color:var(--primary);}
.page-title{font-weight:700;font-size:16px;}
.dark-btn{background:none;border:1px solid var(--border);width:34px;height:34px;border-radius:8px;cursor:pointer;color:var(--muted);margin-left:auto;}
.wrap{max-width:480px;margin:32px auto;padding:0 16px;}
.user-header{background:var(--surface);border:1px solid var(--border);border-radius:12px;padding:20px;text-align:center;margin-bottom:16px;}
.avatar{width:60px;height:60px;border-radius:50%;background:var(--primary);color:#fff;font-size:22px;font-weight:700;display:inline-flex;align-items:center;justify-content:center;margin-bottom:10px;}
.user-header h3{font-size:15px;font-weight:700;}
.user-header span{font-size:12px;color:var(--muted);}
.card{background:var(--surface);border:1px solid var(--border);border-radius:12px;padding:24px;}
.card h3{font-size:14px;font-weight:700;margin-bottom:18px;padding-bottom:10px;border-bottom:1px solid var(--border);}
.field{margin-bottom:14px;}
.field label{display:block;font-size:12px;font-weight:600;color:var(--muted);margin-bottom:6px;text-transform:uppercase;letter-spacing:.4px;}
.iw{position:relative;}
.iw i{position:absolute;left:11px;top:50%;transform:translateY(-50%);color:var(--muted);font-size:12px;}
.iw input,.iw select{width:100%;padding:9px 12px 9px 34px;border:1px solid var(--border);border-radius:7px;background:var(--bg);color:var(--text);font-size:13px;outline:none;transition:.15s;}
.iw input:focus,.iw select:focus{border-color:var(--primary);background:var(--surface);}
.submit-btn{width:100%;padding:11px;background:var(--warn);color:#fff;border:none;border-radius:8px;cursor:pointer;font-weight:700;font-size:14px;margin-top:4px;transition:.15s;display:flex;align-items:center;justify-content:center;gap:8px;}
.submit-btn:hover{background:#d97706;}
.alert{padding:10px 14px;border-radius:8px;font-size:13px;margin-bottom:14px;display:flex;align-items:center;gap:8px;}
.alert.success{background:#f0fdf4;border:1px solid #bbf7d0;color:#16a34a;}
.alert.error  {background:#fef2f2;border:1px solid #fecaca;color:#dc2626;}
</style>
</head>
<body>
<div class="topbar">
  <a href="users.jsp"><i class="fa fa-arrow-left"></i> Users</a>
  <span style="color:var(--border);">|</span>
  <span class="page-title">Edit User</span>
  <button class="dark-btn" onclick="toggleDark()"><i class="fa fa-moon"></i></button>
</div>
<div class="wrap">
  <% if(success != null){ %><div class="alert success"><i class="fa fa-circle-check"></i> User updated successfully!</div><% } %>
  <% if(error   != null){ %><div class="alert error">  <i class="fa fa-circle-exclamation"></i> Update failed. Try again.</div><% } %>

  <div class="user-header">
    <div class="avatar"><%=user.getUsername().substring(0,1).toUpperCase()%></div>
    <h3><%=user.getUsername()%></h3>
    <span>User ID: #<%=user.getId()%> &nbsp;·&nbsp; <%=user.getEmail()%></span>
  </div>

  <div class="card">
    <h3><i class="fa fa-pen" style="color:var(--warn);margin-right:6px;"></i> Edit Details</h3>
    <form action="updateUser" method="post">
      <input type="hidden" name="id" value="<%=user.getId()%>">

      <div class="field">
        <label>Username *</label>
        <div class="iw"><i class="fa fa-user"></i><input type="text" name="username" value="<%=user.getUsername()%>" required></div>
      </div>
      <div class="field">
        <label>Email *</label>
        <div class="iw"><i class="fa fa-envelope"></i><input type="email" name="email" value="<%=user.getEmail()%>" required></div>
      </div>
      <div class="field">
        <label>Role *</label>
        <div class="iw">
          <i class="fa fa-user-shield"></i>
          <select name="role" required>
            <option value="ADMIN" <%="ADMIN".equals(user.getRole())?"selected":""%>>Admin</option>
            <option value="STAFF" <%="STAFF".equals(user.getRole())?"selected":""%>>Staff</option>
          </select>
        </div>
      </div>
      <div class="field">
        <label>Status *</label>
        <div class="iw">
          <i class="fa fa-toggle-on"></i>
          <select name="status" required>
            <option value="ACTIVE"   <%="ACTIVE".equalsIgnoreCase(user.getStatus())  ?"selected":""%>>Active</option>
            <option value="INACTIVE" <%="INACTIVE".equalsIgnoreCase(user.getStatus())?"selected":""%>>Inactive</option>
          </select>
        </div>
      </div>

      <button type="submit" class="submit-btn"><i class="fa fa-floppy-disk"></i> Save Changes</button>
    </form>
  </div>
</div>
<script>
function toggleDark(){const h=document.documentElement,d=h.getAttribute('data-theme')==='dark';h.setAttribute('data-theme',d?'light':'dark');localStorage.setItem('sibs-theme',d?'light':'dark');}
(function(){const t=localStorage.getItem('sibs-theme');if(t)document.documentElement.setAttribute('data-theme',t);})();
</script>
</body>
</html>
