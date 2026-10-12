<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.sibs.model.DeliveryBoy" %>
<%
DeliveryBoy db = (DeliveryBoy) session.getAttribute("deliveryBoy");
if (db == null) {
    response.sendRedirect("delivery-login.jsp");
    return;
}
String updated = request.getParameter("updated");
String error   = request.getParameter("error");
boolean isOnline = "ONLINE".equals(db.getShiftStatus());
%>
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>My Profile — SIBS Delivery</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<style>
:root{--bg:#f8fafc;--surface:#fff;--border:#e2e8f0;--text:#0f172a;--muted:#64748b;--primary:#f97316;--primary-dark:#ea6c0a;--danger:#ef4444;--success:#16a34a;}
[data-theme="dark"]{--bg:#0f172a;--surface:#1e293b;--border:#334155;--text:#f1f5f9;--muted:#94a3b8;}
*{margin:0;padding:0;box-sizing:border-box;font-family:'Inter',sans-serif;}
body{background:var(--bg);color:var(--text);min-height:100vh;}
.topbar{background:#0f172a;padding:0 20px;height:58px;display:flex;align-items:center;gap:12px;position:sticky;top:0;z-index:50;}
.topbar a{text-decoration:none;color:#cbd5e1;font-size:13px;font-weight:500;display:flex;align-items:center;gap:6px;}
.topbar a:hover{color:#f97316;}
.topbar .title{font-weight:700;font-size:15px;flex:1;text-align:center;color:#fff;}
.dark-btn{background:none;border:1px solid rgba(255,255,255,.15);width:34px;height:34px;border-radius:8px;cursor:pointer;color:#94a3b8;}
.content{max-width:600px;margin:32px auto;padding:0 16px;}
.profile-card{background:var(--surface);border:1px solid var(--border);border-radius:16px;overflow:hidden;box-shadow:0 1px 6px rgba(0,0,0,.07);}
.profile-header{background:linear-gradient(120deg,#7c2d12,#f97316);padding:28px;display:flex;align-items:center;gap:20px;color:#fff;}
.avatar-circle{width:72px;height:72px;border-radius:50%;background:rgba(255,255,255,.25);display:flex;align-items:center;justify-content:center;font-size:28px;font-weight:700;flex-shrink:0;border:3px solid rgba(255,255,255,.5);}
.profile-header-info h2{font-size:20px;font-weight:700;}
.profile-header-info p{font-size:13px;opacity:.8;margin-top:3px;}
.status-pill{display:inline-flex;align-items:center;gap:6px;padding:4px 12px;border-radius:20px;font-size:11px;font-weight:700;margin-top:8px;}
.status-pill.online{background:rgba(22,163,74,.25);color:#86efac;}
.status-pill.offline{background:rgba(100,116,139,.2);color:#cbd5e1;}
.profile-body{padding:24px;}
.stats-row{display:grid;grid-template-columns:repeat(3,1fr);gap:10px;margin-bottom:4px;}
.stat-box{background:var(--bg);border:1px solid var(--border);border-radius:10px;padding:14px;text-align:center;}
.stat-box .num{font-size:22px;font-weight:700;color:var(--primary);}
.stat-box .lbl{font-size:11px;color:var(--muted);font-weight:500;margin-top:3px;}
.alert{padding:10px 14px;border-radius:8px;font-size:13px;margin-bottom:16px;display:flex;align-items:center;gap:8px;}
.alert.success{background:#f0fdf4;border:1px solid #bbf7d0;color:#16a34a;}
.alert.error{background:#fef2f2;border:1px solid #fecaca;color:#dc2626;}
.section-title{font-size:11px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.6px;margin-bottom:14px;margin-top:20px;padding-bottom:8px;border-bottom:1px solid var(--border);}
.quick-links{display:grid;grid-template-columns:repeat(3,1fr);gap:10px;margin-bottom:4px;}
.quick-link{background:var(--bg);border:1px solid var(--border);border-radius:10px;padding:12px;text-align:center;text-decoration:none;color:var(--text);transition:.15s;}
.quick-link:hover{border-color:var(--primary);color:var(--primary);}
.quick-link i{font-size:16px;color:var(--primary);margin-bottom:5px;display:block;}
.quick-link span{font-size:11px;font-weight:500;}
.form-row{display:grid;grid-template-columns:1fr 1fr;gap:13px;}
.field{margin-bottom:13px;}
.field label{display:block;font-size:12px;font-weight:600;color:var(--muted);margin-bottom:5px;text-transform:uppercase;letter-spacing:.3px;}
.input-wrap{position:relative;}
.input-wrap i.ico{position:absolute;left:11px;top:50%;transform:translateY(-50%);color:var(--muted);font-size:12px;}
.input-wrap input{width:100%;padding:9px 12px 9px 35px;border:1px solid var(--border);border-radius:7px;background:var(--bg);color:var(--text);font-size:13px;outline:none;transition:.15s;}
.input-wrap input:focus{border-color:var(--primary);box-shadow:0 0 0 3px rgba(249,115,22,.1);}
.input-wrap input[readonly]{opacity:.6;cursor:not-allowed;}
.eye-btn{position:absolute;right:10px;top:50%;transform:translateY(-50%);background:none;border:none;cursor:pointer;color:var(--muted);}
.pwd-msg{font-size:12px;margin-top:4px;}
.btn-row{display:flex;gap:10px;margin-top:6px;}
.submit-btn{flex:1;padding:11px;background:var(--primary);color:#fff;border:none;border-radius:8px;cursor:pointer;font-weight:600;font-size:14px;transition:.15s;display:flex;align-items:center;justify-content:center;gap:8px;}
.submit-btn:hover{background:var(--primary-dark);}
.wallet-banner{background:linear-gradient(120deg,#0f172a,#1e3a5f);border-radius:10px;padding:16px 20px;display:flex;align-items:center;justify-content:space-between;margin-bottom:4px;color:#fff;}
.wallet-banner .amount{font-size:24px;font-weight:700;color:#f97316;}
.wallet-banner .lbl{font-size:12px;color:#94a3b8;margin-top:2px;}
.wallet-banner a{background:#f97316;color:#fff;text-decoration:none;padding:8px 16px;border-radius:7px;font-size:13px;font-weight:600;}
.divider{border:none;border-top:1px solid var(--border);margin:20px 0;}
.logout-link{display:block;text-align:center;font-size:13px;}
.logout-link a{color:var(--danger);text-decoration:none;font-weight:500;}
@media(max-width:500px){.form-row,.stats-row,.quick-links{grid-template-columns:1fr 1fr;}}
</style>
</head>
<body>

<div class="topbar">
  <a href="delivery-dashboard.jsp"><i class="fa fa-arrow-left"></i> Dashboard</a>
  <span class="title"><i class="fa fa-motorcycle"></i> My Profile</span>
  <button class="dark-btn" onclick="toggleDark()"><i class="fa fa-moon"></i></button>
</div>

<div class="content">
  <div class="profile-card">
    <div class="profile-header">
      <div class="avatar-circle"><%=db.getName().substring(0,1).toUpperCase()%></div>
      <div class="profile-header-info">
        <h2><%=db.getName()%></h2>
        <p><%=db.getEmail()%></p>
        <div class="status-pill <%=isOnline ? "online" : "offline"%>">
          <i class="fa fa-circle" style="font-size:7px;"></i>
          <%=isOnline ? "ONLINE" : "OFFLINE"%>
        </div>
      </div>
    </div>

    <div class="profile-body">

      <!-- Wallet banner -->
      <div class="wallet-banner">
        <div>
          <div class="amount">₹<%=String.format("%.2f", db.getWallet())%></div>
          <div class="lbl">Wallet Balance</div>
        </div>
        <a href="delivery-wallet.jsp"><i class="fa fa-wallet"></i> Manage</a>
      </div>

      <!-- Stats -->
      <div class="section-title">Your Stats</div>
      <div class="stats-row">
        <div class="stat-box">
          <div class="num"><%=db.getDeliveredTotal()%></div>
          <div class="lbl">Total Delivered</div>
        </div>
        <div class="stat-box">
          <div class="num"><%=db.getActiveOrders()%></div>
          <div class="lbl">Active Orders</div>
        </div>
        <div class="stat-box">
          <div class="num" style="color:<%="APPROVED".equals(db.getStatus())?"#16a34a":"#f59e0b"%>;font-size:13px;">
            <%=db.getStatus() != null ? db.getStatus() : "PENDING"%>
          </div>
          <div class="lbl">Account Status</div>
        </div>
      </div>

      <!-- Quick links -->
      <div class="section-title">Quick Access</div>
      <div class="quick-links">
        <a class="quick-link" href="delivery-dashboard.jsp"><i class="fa fa-gauge-high"></i><span>Dashboard</span></a>
        <a class="quick-link" href="delivery-earnings.jsp"><i class="fa fa-indian-rupee-sign"></i><span>Earnings</span></a>
        <a class="quick-link" href="delivery-slot-history.jsp"><i class="fa fa-calendar"></i><span>Slot History</span></a>
        <a class="quick-link" href="delivery-documents.jsp"><i class="fa fa-file-alt"></i><span>Documents</span></a>
        <a class="quick-link" href="delivery-ratings.jsp"><i class="fa fa-star"></i><span>Ratings</span></a>
        <a class="quick-link" href="delivery-notifications.jsp"><i class="fa fa-bell"></i><span>Notifications</span></a>
      </div>

      <% if (updated != null) { %>
      <div class="alert success"><i class="fa fa-circle-check"></i> Profile updated successfully!</div>
      <% } if (error != null) { %>
      <div class="alert error"><i class="fa fa-circle-exclamation"></i> Update failed. Please try again.</div>
      <% } %>

      <!-- Edit form -->
      <form action="updateDeliveryBoy" method="post" onsubmit="return checkPasswords()">
        <input type="hidden" name="id"       value="<%=db.getId()%>">
        <input type="hidden" name="redirect" value="delivery-profile.jsp">

        <div class="section-title">Account Info</div>

        <div class="form-row">
          <div class="field">
            <label>Full Name</label>
            <div class="input-wrap"><i class="ico fa fa-user"></i>
              <input type="text" name="name" value="<%=db.getName()%>" required>
            </div>
          </div>
          <div class="field">
            <label>Phone</label>
            <div class="input-wrap"><i class="ico fa fa-phone"></i>
              <input type="tel" name="phone" value="<%=db.getPhone() != null ? db.getPhone() : ""%>" placeholder="10-digit number" maxlength="10">
            </div>
          </div>
        </div>

        <div class="field">
          <label>Email (read-only)</label>
          <div class="input-wrap"><i class="ico fa fa-envelope"></i>
            <input type="email" value="<%=db.getEmail()%>" readonly>
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
      <div class="logout-link"><a href="deliveryLogout"><i class="fa fa-sign-out-alt"></i> Sign Out</a></div>
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
