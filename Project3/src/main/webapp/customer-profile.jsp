<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.sibs.model.User" %>
<%
User user = (User) session.getAttribute("customer");
if (user == null) {
    response.sendRedirect("customer-login.jsp");
    return;
}
String updated = request.getParameter("updated");
String error   = request.getParameter("error");
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
:root{--bg:#f8fafc;--surface:#fff;--border:#e2e8f0;--text:#0f172a;--muted:#64748b;--primary:#2563eb;--danger:#ef4444;--success:#16a34a;}
[data-theme="dark"]{--bg:#0f172a;--surface:#1e293b;--border:#334155;--text:#f1f5f9;--muted:#94a3b8;}
*{margin:0;padding:0;box-sizing:border-box;font-family:'Inter',sans-serif;}
body{background:var(--bg);color:var(--text);min-height:100vh;}
.topbar{background:var(--surface);border-bottom:1px solid var(--border);padding:0 20px;height:58px;display:flex;align-items:center;gap:12px;position:sticky;top:0;z-index:50;box-shadow:0 1px 4px rgba(0,0,0,.07);}
.topbar a{text-decoration:none;color:var(--primary);font-size:13px;font-weight:500;display:flex;align-items:center;gap:6px;}
.topbar .title{font-weight:700;font-size:15px;flex:1;text-align:center;}
.dark-btn{background:none;border:1px solid var(--border);width:34px;height:34px;border-radius:8px;cursor:pointer;color:var(--muted);}
.content{max-width:640px;margin:32px auto;padding:0 16px;}
.profile-card{background:var(--surface);border:1px solid var(--border);border-radius:16px;overflow:hidden;box-shadow:0 1px 6px rgba(0,0,0,.07);}
.profile-header{background:linear-gradient(120deg,#1e3a8a,#2563eb);padding:32px;text-align:center;color:#fff;position:relative;}
.avatar-circle{width:80px;height:80px;border-radius:50%;background:rgba(255,255,255,.25);display:flex;align-items:center;justify-content:center;font-size:32px;font-weight:700;margin:0 auto 14px;border:3px solid rgba(255,255,255,.5);}
.profile-header h2{font-size:20px;font-weight:700;}
.profile-header p{font-size:13px;opacity:.8;margin-top:4px;}
.role-badge{display:inline-flex;align-items:center;gap:5px;background:rgba(255,255,255,.2);padding:3px 10px;border-radius:20px;font-size:11px;font-weight:600;margin-top:8px;}
.profile-body{padding:24px;}
.alert{padding:10px 14px;border-radius:8px;font-size:13px;margin-bottom:16px;display:flex;align-items:center;gap:8px;}
.alert.success{background:#f0fdf4;border:1px solid #bbf7d0;color:#16a34a;}
.alert.error{background:#fef2f2;border:1px solid #fecaca;color:#dc2626;}
.quick-links{display:grid;grid-template-columns:repeat(3,1fr);gap:10px;margin-bottom:20px;}
.quick-link{background:var(--bg);border:1px solid var(--border);border-radius:10px;padding:14px;text-align:center;text-decoration:none;color:var(--text);transition:.15s;}
.quick-link:hover{border-color:var(--primary);color:var(--primary);}
.quick-link i{font-size:18px;color:var(--primary);margin-bottom:6px;display:block;}
.quick-link span{font-size:11px;font-weight:500;}
.section-title{font-size:11px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.6px;margin-bottom:14px;margin-top:20px;padding-bottom:8px;border-bottom:1px solid var(--border);}
.form-row{display:grid;grid-template-columns:1fr 1fr;gap:13px;}
.field{margin-bottom:13px;}
.field label{display:block;font-size:12px;font-weight:600;color:var(--muted);margin-bottom:5px;text-transform:uppercase;letter-spacing:.3px;}
.input-wrap{position:relative;}
.input-wrap i.ico{position:absolute;left:11px;top:50%;transform:translateY(-50%);color:var(--muted);font-size:12px;}
.input-wrap input,.input-wrap select{width:100%;padding:9px 12px 9px 35px;border:1px solid var(--border);border-radius:7px;background:var(--bg);color:var(--text);font-size:13px;outline:none;transition:.15s;}
.input-wrap input:focus{border-color:var(--primary);}
.input-wrap input[readonly]{opacity:.6;cursor:not-allowed;}
.eye-btn{position:absolute;right:10px;top:50%;transform:translateY(-50%);background:none;border:none;cursor:pointer;color:var(--muted);}
.pwd-msg{font-size:12px;margin-top:4px;}
.btn-row{display:flex;gap:10px;margin-top:6px;}
.submit-btn{flex:1;padding:11px;background:var(--primary);color:#fff;border:none;border-radius:8px;cursor:pointer;font-weight:600;font-size:14px;transition:.15s;display:flex;align-items:center;justify-content:center;gap:8px;}
.submit-btn:hover{background:#1d4ed8;}
.divider{border:none;border-top:1px solid var(--border);margin:20px 0;}
.logout-link{display:block;text-align:center;margin-top:16px;font-size:13px;}
.logout-link a{color:var(--danger);text-decoration:none;font-weight:500;}
@media(max-width:500px){.form-row,.quick-links{grid-template-columns:1fr 1fr;}}
</style>
</head>
<body>

<div class="topbar">
  <a href="customer-dashboard.jsp"><i class="fa fa-arrow-left"></i> Shop</a>
  <span class="title">My Profile</span>
  <button class="dark-btn" onclick="toggleDark()"><i class="fa fa-moon"></i></button>
</div>

<div class="content">
  <div class="profile-card">
    <div class="profile-header">
      <div class="avatar-circle"><%=user.getUsername().substring(0,1).toUpperCase()%></div>
      <h2><%=user.getName() != null && !user.getName().isEmpty() ? user.getName() : user.getUsername()%></h2>
      <p><%=user.getEmail()%></p>
      <div class="role-badge"><i class="fa fa-user"></i> Customer</div>
    </div>

    <div class="profile-body">

      <% if (updated != null) { %>
      <div class="alert success"><i class="fa fa-circle-check"></i> Profile updated successfully!</div>
      <% } if (error != null) { %>
      <div class="alert error"><i class="fa fa-circle-exclamation"></i> Update failed. Please try again.</div>
      <% } %>

      <!-- QUICK LINKS -->
      <div class="quick-links">
        <a class="quick-link" href="my-orders.jsp"><i class="fa fa-shopping-bag"></i><span>My Orders</span></a>
        <a class="quick-link" href="myreturns.jsp"><i class="fa fa-rotate-left"></i><span>Returns</span></a>
        <a class="quick-link" href="wishlist.jsp"><i class="fa fa-heart" style="color:#e11d48;"></i><span>Wishlist</span></a>
        <a class="quick-link" href="customer-wallet.jsp"><i class="fa fa-wallet"></i><span>My Wallet</span></a>
        <a class="quick-link" href="cart.jsp"><i class="fa fa-cart-shopping"></i><span>My Cart</span></a>
        <a class="quick-link" href="editaddress.jsp"><i class="fa fa-map-marker-alt"></i><span>Addresses</span></a>
        <a class="quick-link" href="payment-history.jsp"><i class="fa fa-credit-card"></i><span>Payments</span></a>
        <a class="quick-link" href="customer-support.jsp"><i class="fa fa-headset"></i><span>Support</span></a>
      </div>

      <!-- EDIT FORM -->
      <form action="updateUser" method="post" onsubmit="return checkPasswords()">
        <input type="hidden" name="id"       value="<%=user.getId()%>">
        <input type="hidden" name="role"     value="customer">
        <input type="hidden" name="redirect" value="customer-profile.jsp">

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
          <label>Default Address</label>
          <div class="input-wrap"><i class="ico fa fa-map-marker-alt"></i>
            <input type="text" name="address" value="<%=user.getAddress() != null ? user.getAddress() : ""%>" placeholder="Your delivery address">
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

      <div class="divider"></div>
      <div class="logout-link"><a href="logout"><i class="fa fa-sign-out-alt"></i> Sign Out</a></div>
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
