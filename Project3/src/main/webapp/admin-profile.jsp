<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.sibs.model.User" %>
<%
User user = (User) session.getAttribute("user");
if (user == null || (!"ADMIN".equals(user.getRole()) && !"STAFF".equals(user.getRole()))) {
    response.sendRedirect("login.jsp");
    return;
}
String updated = request.getParameter("updated");
String error   = request.getParameter("error");
boolean isAdmin = "ADMIN".equals(user.getRole());
%>
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>My Profile — SIBS</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<style>
:root{--bg:#f8fafc;--surface:#fff;--border:#e2e8f0;--text:#0f172a;--muted:#64748b;--primary:#2563eb;--danger:#ef4444;--success:#16a34a;--sidebar:#0f172a;}
[data-theme="dark"]{--bg:#0f172a;--surface:#1e293b;--border:#334155;--text:#f1f5f9;--muted:#94a3b8;}
*{margin:0;padding:0;box-sizing:border-box;font-family:'Inter',sans-serif;}
body{background:var(--bg);color:var(--text);min-height:100vh;display:flex;}
/* sidebar */
.sidebar{width:240px;height:100vh;background:var(--sidebar);position:fixed;top:0;left:0;z-index:200;display:flex;flex-direction:column;}
.sidebar-logo{padding:20px 24px;border-bottom:1px solid rgba(255,255,255,.07);display:flex;align-items:center;gap:10px;}
.sidebar-logo span{color:#fff;font-weight:700;font-size:18px;}
.sidebar-logo i{color:var(--primary);font-size:20px;}
.sidebar nav{flex:1;padding:12px 0;overflow-y:auto;}
.nav-item{display:flex;align-items:center;gap:10px;padding:11px 20px;color:#cbd5e1;text-decoration:none;font-size:14px;transition:.15s;border-left:3px solid transparent;}
.nav-item:hover,.nav-item.active{background:#1e293b;color:#fff;border-left-color:var(--primary);}
.nav-item i{width:18px;text-align:center;}
.sidebar-footer{padding:16px;border-top:1px solid rgba(255,255,255,.07);}
/* main */
.main{margin-left:240px;padding:32px;flex:1;max-width:720px;}
.page-header{margin-bottom:28px;}
.page-header h1{font-size:22px;font-weight:700;display:flex;align-items:center;gap:10px;}
.page-header p{color:var(--muted);font-size:13px;margin-top:4px;}
.profile-card{background:var(--surface);border:1px solid var(--border);border-radius:16px;overflow:hidden;box-shadow:0 1px 6px rgba(0,0,0,.07);}
.profile-header{background:linear-gradient(120deg,#1e3a8a,#2563eb);padding:32px;display:flex;align-items:center;gap:20px;color:#fff;}
.avatar-circle{width:72px;height:72px;border-radius:50%;background:rgba(255,255,255,.25);display:flex;align-items:center;justify-content:center;font-size:28px;font-weight:700;flex-shrink:0;border:3px solid rgba(255,255,255,.5);}
.profile-header-info h2{font-size:20px;font-weight:700;}
.profile-header-info p{font-size:13px;opacity:.8;margin-top:4px;}
.role-badge{display:inline-flex;align-items:center;gap:5px;background:rgba(255,255,255,.2);padding:3px 10px;border-radius:20px;font-size:11px;font-weight:600;margin-top:8px;}
.profile-body{padding:28px;}
.alert{padding:10px 14px;border-radius:8px;font-size:13px;margin-bottom:16px;display:flex;align-items:center;gap:8px;}
.alert.success{background:#f0fdf4;border:1px solid #bbf7d0;color:#16a34a;}
.alert.error{background:#fef2f2;border:1px solid #fecaca;color:#dc2626;}
.section-title{font-size:11px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.6px;margin-bottom:14px;margin-top:22px;padding-bottom:8px;border-bottom:1px solid var(--border);}
.form-row{display:grid;grid-template-columns:1fr 1fr;gap:14px;}
.field{margin-bottom:13px;}
.field label{display:block;font-size:12px;font-weight:600;color:var(--muted);margin-bottom:5px;text-transform:uppercase;letter-spacing:.3px;}
.input-wrap{position:relative;}
.input-wrap i.ico{position:absolute;left:11px;top:50%;transform:translateY(-50%);color:var(--muted);font-size:12px;}
.input-wrap input{width:100%;padding:9px 12px 9px 35px;border:1px solid var(--border);border-radius:7px;background:var(--bg);color:var(--text);font-size:13px;outline:none;transition:.15s;}
.input-wrap input:focus{border-color:var(--primary);}
.input-wrap input[readonly]{opacity:.6;cursor:not-allowed;}
.eye-btn{position:absolute;right:10px;top:50%;transform:translateY(-50%);background:none;border:none;cursor:pointer;color:var(--muted);}
.pwd-msg{font-size:12px;margin-top:4px;}
.btn-row{display:flex;gap:10px;margin-top:6px;}
.submit-btn{flex:1;padding:11px;background:var(--primary);color:#fff;border:none;border-radius:8px;cursor:pointer;font-weight:600;font-size:14px;transition:.15s;display:flex;align-items:center;justify-content:center;gap:8px;}
.submit-btn:hover{background:#1d4ed8;}
@media(max-width:700px){.form-row{grid-template-columns:1fr;}.sidebar{display:none;}.main{margin-left:0;padding:16px;}}
</style>
</head>
<body>

<!-- SIDEBAR -->
<div class="sidebar">
  <div class="sidebar-logo"><i class="fa fa-cubes"></i><span>SIBS Admin</span></div>
  <nav>
    <a class="nav-item" href="dashboard.jsp"><i class="fa fa-gauge-high"></i> Dashboard</a>
    <a class="nav-item active" href="admin-profile.jsp"><i class="fa fa-user-circle"></i> My Profile</a>
    <% if (isAdmin) { %>
    <a class="nav-item" href="add-staff.jsp"><i class="fa fa-user-plus"></i> Add Staff</a>
    <a class="nav-item" href="users.jsp"><i class="fa fa-users"></i> Manage Users</a>
    <% } %>
    <a class="nav-item" href="products.jsp"><i class="fa fa-box"></i> Products</a>
    <a class="nav-item" href="admin-orders.jsp"><i class="fa fa-shopping-bag"></i> Orders</a>
    <a class="nav-item" href="manage-delivery-boys.jsp"><i class="fa fa-motorcycle"></i> Delivery Boys</a>
  </nav>
  <div class="sidebar-footer">
    <a class="nav-item" href="admin-settings.jsp"><i class="fa fa-gear"></i> Settings</a>
    <a class="nav-item" href="logout" style="color:#94a3b8;"><i class="fa fa-sign-out-alt"></i> Logout</a>
  </div>
</div>

<div class="main">
  <div class="page-header">
    <h1><i class="fa fa-user-circle" style="color:var(--primary);"></i> My Profile</h1>
    <p>Manage your account information and password</p>
  </div>

  <div class="profile-card">
    <div class="profile-header">
      <div class="avatar-circle"><%=user.getUsername().substring(0,1).toUpperCase()%></div>
      <div class="profile-header-info">
        <h2><%=user.getName() != null ? user.getName() : user.getUsername()%></h2>
        <p><%=user.getEmail()%></p>
        <div class="role-badge">
          <i class="fa fa-<%=isAdmin ? "shield-halved" : "user-tie"%>"></i>
          <%=user.getRole()%>
        </div>
      </div>
    </div>

    <div class="profile-body">

      <% if (updated != null) { %>
      <div class="alert success"><i class="fa fa-circle-check"></i> Profile updated successfully!</div>
      <% } if (error != null) { %>
      <div class="alert error"><i class="fa fa-circle-exclamation"></i> Update failed. Please try again.</div>
      <% } %>

      <form action="updateUser" method="post" onsubmit="return checkPasswords()">
        <input type="hidden" name="id"    value="<%=user.getId()%>">
        <input type="hidden" name="role"  value="<%=user.getRole()%>">
        <input type="hidden" name="redirect" value="admin-profile.jsp">

        <div class="section-title">Account Info</div>

        <div class="form-row">
          <div class="field">
            <label>Username</label>
            <div class="input-wrap"><i class="ico fa fa-user"></i>
              <input type="text" name="username" value="<%=user.getUsername()%>" required>
            </div>
          </div>
          <div class="field">
            <label>Full Name</label>
            <div class="input-wrap"><i class="ico fa fa-id-card"></i>
              <input type="text" name="name" value="<%=user.getName() != null ? user.getName() : ""%>" placeholder="Your full name">
            </div>
          </div>
        </div>

        <div class="form-row">
          <div class="field">
            <label>Email (read-only)</label>
            <div class="input-wrap"><i class="ico fa fa-envelope"></i>
              <input type="email" value="<%=user.getEmail()%>" readonly>
            </div>
          </div>
          <div class="field">
            <label>Phone</label>
            <div class="input-wrap"><i class="ico fa fa-phone"></i>
              <input type="tel" name="phone" value="<%=user.getPhone() != null ? user.getPhone() : ""%>" placeholder="Phone number">
            </div>
          </div>
        </div>

        <div class="field">
          <label>Address</label>
          <div class="input-wrap"><i class="ico fa fa-map-marker-alt"></i>
            <input type="text" name="address" value="<%=user.getAddress() != null ? user.getAddress() : ""%>" placeholder="Your address">
          </div>
        </div>

        <div class="section-title">Change Password</div>

        <div class="form-row">
          <div class="field">
            <label>New Password <span style="text-transform:none;font-weight:400;">(leave blank to keep)</span></label>
            <div class="input-wrap"><i class="ico fa fa-lock"></i>
              <input type="password" name="password" id="newPwd" placeholder="Min 6 characters" minlength="6">
              <button type="button" class="eye-btn" onclick="togglePwd('newPwd','e1')"><i class="fa fa-eye" id="e1"></i></button>
            </div>
          </div>
          <div class="field">
            <label>Confirm Password</label>
            <div class="input-wrap"><i class="ico fa fa-lock"></i>
              <input type="password" id="confPwd" placeholder="Confirm new password" oninput="checkMatch()">
              <button type="button" class="eye-btn" onclick="togglePwd('confPwd','e2')"><i class="fa fa-eye" id="e2"></i></button>
            </div>
            <div id="pwdMsg" class="pwd-msg"></div>
          </div>
        </div>

        <div class="btn-row">
          <button type="submit" class="submit-btn"><i class="fa fa-save"></i> Save Changes</button>
        </div>
      </form>

    </div>
  </div>
</div>

<script>
function toggleDark(){const h=document.documentElement,d=h.getAttribute('data-theme')==='dark';h.setAttribute('data-theme',d?'light':'dark');localStorage.setItem('sibs-theme',d?'light':'dark');}
(function(){const t=localStorage.getItem('sibs-theme');if(t)document.documentElement.setAttribute('data-theme',t);})();
function togglePwd(id,icoId){const p=document.getElementById(id),i=document.getElementById(icoId);p.type=p.type==='password'?'text':'password';i.className=p.type==='password'?'fa fa-eye':'fa fa-eye-slash';}
function checkMatch(){const p=document.getElementById('newPwd').value,c=document.getElementById('confPwd').value,msg=document.getElementById('pwdMsg');if(!c){msg.textContent='';return;}if(p===c){msg.style.color='#16a34a';msg.textContent='✓ Passwords match';}else{msg.style.color='#ef4444';msg.textContent='✗ Passwords do not match';}}
function checkPasswords(){const p=document.getElementById('newPwd').value,c=document.getElementById('confPwd').value;if(p&&p!==c){alert('Passwords do not match!');return false;}return true;}
</script>
</body>
</html>
