<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Admin Register — SIBS</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<style>
:root{--bg:#f8fafc;--surface:#fff;--border:#e2e8f0;--text:#0f172a;--muted:#64748b;--primary:#2563eb;}
[data-theme="dark"]{--bg:#0f172a;--surface:#1e293b;--border:#334155;--text:#f1f5f9;--muted:#94a3b8;}
*{margin:0;padding:0;box-sizing:border-box;font-family:'Inter',sans-serif;}
body{min-height:100vh;display:flex;background:var(--bg);color:var(--text);}
.dark-toggle{position:fixed;top:16px;right:16px;background:none;border:1px solid var(--border);width:36px;height:36px;border-radius:8px;cursor:pointer;color:var(--muted);z-index:10;}
/* LEFT PANEL */
.left-panel{flex:1;background:linear-gradient(135deg,#1e3a8a,#2563eb);color:#fff;display:flex;flex-direction:column;justify-content:center;padding:60px 56px;}
@media(max-width:700px){.left-panel{display:none;}}
.left-panel h1{font-size:28px;font-weight:700;margin-bottom:12px;}
.left-panel p{font-size:14px;opacity:.8;line-height:1.7;max-width:340px;}
.features{margin-top:32px;display:flex;flex-direction:column;gap:12px;}
.feature{display:flex;align-items:center;gap:12px;font-size:13px;opacity:.9;}
.feature i{width:32px;height:32px;background:rgba(255,255,255,.15);border-radius:8px;display:flex;align-items:center;justify-content:center;}
/* RIGHT PANEL */
.right-panel{width:480px;flex-shrink:0;display:flex;align-items:center;justify-content:center;padding:32px;background:var(--surface);overflow-y:auto;}
@media(max-width:700px){.right-panel{width:100%;}}
.form-box{width:100%;max-width:400px;}
.logo{display:flex;align-items:center;gap:8px;margin-bottom:24px;}
.logo i{font-size:22px;color:var(--primary);}
.logo span{font-size:20px;font-weight:700;}
.form-box h2{font-size:20px;font-weight:700;margin-bottom:4px;}
.form-box p{font-size:13px;color:var(--muted);margin-bottom:22px;}
.form-row{display:grid;grid-template-columns:1fr 1fr;gap:12px;}
.field{margin-bottom:13px;}
.field label{display:block;font-size:12px;font-weight:600;color:var(--muted);margin-bottom:5px;text-transform:uppercase;letter-spacing:.4px;}
.input-wrap{position:relative;}
.input-wrap i.ico{position:absolute;left:11px;top:50%;transform:translateY(-50%);color:var(--muted);font-size:12px;}
.input-wrap input,.input-wrap select,.input-wrap textarea{width:100%;padding:9px 12px 9px 34px;border:1px solid var(--border);border-radius:7px;background:var(--bg);color:var(--text);font-size:13px;outline:none;transition:.15s;}
.input-wrap textarea{padding-left:34px;resize:vertical;min-height:60px;}
.input-wrap input:focus,.input-wrap select:focus,.input-wrap textarea:focus{border-color:var(--primary);background:var(--surface);}
.eye-btn{position:absolute;right:10px;top:50%;transform:translateY(-50%);background:none;border:none;cursor:pointer;color:var(--muted);font-size:12px;}
.submit-btn{width:100%;padding:11px;background:var(--primary);color:#fff;border:none;border-radius:8px;cursor:pointer;font-weight:600;font-size:14px;margin-top:6px;transition:.15s;display:flex;align-items:center;justify-content:center;gap:8px;}
.submit-btn:hover{background:#1d4ed8;}
.alert{padding:10px 14px;border-radius:8px;font-size:13px;margin-bottom:14px;display:flex;align-items:center;gap:8px;}
.alert.error{background:#fef2f2;border:1px solid #fecaca;color:#dc2626;}
.divider{border:none;border-top:1px solid var(--border);margin:18px 0;}
.links{text-align:center;font-size:13px;color:var(--muted);}
.links a{color:var(--primary);text-decoration:none;font-weight:500;}
</style>
</head>
<body>
<button class="dark-toggle" onclick="toggleDark()"><i class="fa fa-moon"></i></button>

<div class="left-panel">
  <h1>Admin Registration</h1>
  <p>Create your admin account to get full access to inventory, billing, orders, and staff management.</p>
  <div class="features">
    <div class="feature"><i class="fa fa-shield-halved"></i> Full admin privileges</div>
    <div class="feature"><i class="fa fa-users"></i> Manage staff & customers</div>
    <div class="feature"><i class="fa fa-box"></i> Product & inventory control</div>
    <div class="feature"><i class="fa fa-chart-line"></i> Real-time analytics</div>
  </div>
</div>

<div class="right-panel">
  <div class="form-box">
    <div class="logo"><i class="fa fa-cubes"></i><span>SIBS</span></div>
    <h2>Create Admin Account</h2>
    <p>Fill in your details to register as administrator</p>

    <%
    String error = request.getParameter("error");
    if("username".equals(error)){ %><div class="alert error"><i class="fa fa-circle-exclamation"></i> Username already exists</div><% }
    if("email".equals(error)){ %><div class="alert error"><i class="fa fa-circle-exclamation"></i> Email already registered</div><% }
    if("failed".equals(error)){ %><div class="alert error"><i class="fa fa-circle-exclamation"></i> Registration failed. Please try again.</div><% }
    %>

    <form action="register" method="post" onsubmit="return validatePwd()">
      <div class="form-row">
        <div class="field" style="margin:0 0 13px;">
          <label>First Name</label>
          <div class="input-wrap"><i class="ico fa fa-user"></i><input type="text" name="firstName" placeholder="First" required></div>
        </div>
        <div class="field" style="margin:0 0 13px;">
          <label>Last Name</label>
          <div class="input-wrap"><i class="ico fa fa-user"></i><input type="text" name="lastName" placeholder="Last" required></div>
        </div>
      </div>
      <div class="field">
        <label>Username *</label>
        <div class="input-wrap"><i class="ico fa fa-at"></i><input type="text" name="username" placeholder="admin_username" required></div>
      </div>
      <div class="field">
        <label>Email *</label>
        <div class="input-wrap"><i class="ico fa fa-envelope"></i><input type="email" name="email" placeholder="admin@email.com" required></div>
      </div>
      <div class="form-row">
        <div class="field" style="margin:0 0 13px;">
          <label>Phone</label>
          <div class="input-wrap"><i class="ico fa fa-phone"></i><input type="tel" name="phone" placeholder="Phone number"></div>
        </div>
        <div class="field" style="margin:0 0 13px;">
          <label>Date of Birth</label>
          <div class="input-wrap"><i class="ico fa fa-calendar"></i><input type="date" name="dob"></div>
        </div>
      </div>
      <div class="field">
        <label>Address</label>
        <div class="input-wrap"><i class="ico fa fa-map-marker-alt"></i><textarea name="address" placeholder="Your address"></textarea></div>
      </div>
      <div class="field">
        <label>Password *</label>
        <div class="input-wrap">
          <i class="ico fa fa-lock"></i>
          <input type="password" name="password" id="pwd" placeholder="Min 6 characters" required>
          <button type="button" class="eye-btn" onclick="togglePwd('pwd','e1')"><i class="fa fa-eye" id="e1"></i></button>
        </div>
      </div>
      <div class="field">
        <label>Confirm Password *</label>
        <div class="input-wrap">
          <i class="ico fa fa-lock"></i>
          <input type="password" id="cpwd" placeholder="Confirm password" required>
          <button type="button" class="eye-btn" onclick="togglePwd('cpwd','e2')"><i class="fa fa-eye" id="e2"></i></button>
        </div>
      </div>
      <button type="submit" class="submit-btn"><i class="fa fa-user-shield"></i> Register Admin</button>
    </form>
    <hr class="divider">
    <div class="links"><a href="login.jsp"><i class="fa fa-arrow-left"></i> Back to Login</a></div>
    <div style="text-align:center;font-size:11px;color:var(--muted);margin-top:16px;">SIBS © 2026</div>
  </div>
</div>

<script>
function toggleDark(){
  const h=document.documentElement,d=h.getAttribute('data-theme')==='dark';
  h.setAttribute('data-theme',d?'light':'dark');
  localStorage.setItem('sibs-theme',d?'light':'dark');
}
(function(){const t=localStorage.getItem('sibs-theme');if(t)document.documentElement.setAttribute('data-theme',t);})();
function togglePwd(id,icoId){
  const p=document.getElementById(id),i=document.getElementById(icoId);
  p.type=p.type==='password'?'text':'password';
  i.className=p.type==='password'?'fa fa-eye':'fa fa-eye-slash';
}
function validatePwd(){
  const p=document.getElementById('pwd').value;
  const c=document.getElementById('cpwd').value;
  if(p!==c){alert('Passwords do not match!');return false;}
  if(p.length<6){alert('Password must be at least 6 characters');return false;}
  return true;
}
</script>
</body>
</html>
