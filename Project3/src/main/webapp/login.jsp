<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>SIBS — Admin Login</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<style>
:root{
  --bg:#f0f4ff;--surface:#ffffff;--border:#e2e8f5;
  --text:#0d1321;--muted:#64748b;
  --primary:#4361ee;--primary-dark:#3451d6;--primary-light:#eef0fd;
  --success:#16a34a;--danger:#dc2626;
  --input-bg:#f8faff;
}
[data-theme="dark"]{
  --bg:#0b0f1a;--surface:#131929;--border:#1e2a42;
  --text:#e8eeff;--muted:#5a6a8a;
  --primary:#5878f5;--primary-dark:#4361ee;--primary-light:#1a2040;
  --input-bg:#0f1626;
}
*{margin:0;padding:0;box-sizing:border-box;font-family:'Inter',sans-serif;}

body{
  min-height:100vh;display:grid;
  grid-template-columns:1fr 480px;
  background:var(--bg);color:var(--text);
}
@media(max-width:768px){body{grid-template-columns:1fr;}}

/* ── LEFT PANEL ── */
.left{
  background:linear-gradient(145deg,#1a237e 0%,#4361ee 60%,#7c3aed 100%);
  display:flex;flex-direction:column;justify-content:center;
  padding:60px 64px;position:relative;overflow:hidden;
}
@media(max-width:768px){.left{display:none;}}

/* decorative circles */
.left::before,.left::after{
  content:'';position:absolute;border-radius:50%;
  background:rgba(255,255,255,.06);
}
.left::before{width:400px;height:400px;top:-120px;right:-120px;}
.left::after{width:300px;height:300px;bottom:-80px;left:-80px;}

.brand{display:flex;align-items:center;gap:12px;margin-bottom:48px;position:relative;}
.brand-icon{width:46px;height:46px;background:rgba(255,255,255,.2);
  border-radius:12px;display:flex;align-items:center;justify-content:center;
  font-size:20px;color:#fff;border:1px solid rgba(255,255,255,.3);}
.brand-name{font-size:22px;font-weight:800;color:#fff;letter-spacing:-.5px;}
.brand-name span{opacity:.7;font-weight:400;font-size:13px;display:block;margin-top:1px;}

.left h1{
  font-size:38px;font-weight:800;color:#fff;
  line-height:1.15;letter-spacing:-.5px;
  margin-bottom:16px;position:relative;
}
.left h1 em{font-style:normal;color:#a5b4fc;}

.left p{font-size:15px;color:rgba(255,255,255,.7);line-height:1.7;max-width:360px;margin-bottom:40px;position:relative;}

.feature-list{display:flex;flex-direction:column;gap:16px;position:relative;}
.feat{display:flex;align-items:center;gap:14px;}
.feat-icon{
  width:38px;height:38px;border-radius:10px;
  background:rgba(255,255,255,.12);border:1px solid rgba(255,255,255,.2);
  display:flex;align-items:center;justify-content:center;
  font-size:14px;color:#fff;flex-shrink:0;
}
.feat-text{font-size:13px;color:rgba(255,255,255,.85);font-weight:500;}

/* floating stats */
.stats-row{display:flex;gap:12px;margin-top:44px;position:relative;}
.stat-box{background:rgba(255,255,255,.1);border:1px solid rgba(255,255,255,.15);
  border-radius:12px;padding:12px 16px;flex:1;}
.stat-num{font-size:22px;font-weight:800;color:#fff;}
.stat-lbl{font-size:11px;color:rgba(255,255,255,.6);margin-top:2px;}

/* ── RIGHT PANEL ── */
.right{
  background:var(--surface);
  display:flex;flex-direction:column;align-items:center;
  justify-content:center;padding:40px 48px;
  position:relative;border-left:1px solid var(--border);
}
@media(max-width:768px){.right{padding:40px 24px;min-height:100vh;}}

.theme-btn{
  position:absolute;top:20px;right:20px;
  background:none;border:1px solid var(--border);
  width:38px;height:38px;border-radius:10px;
  cursor:pointer;color:var(--muted);font-size:15px;
  display:flex;align-items:center;justify-content:center;
  transition:.15s;
}
.theme-btn:hover{border-color:var(--primary);color:var(--primary);}

.form-wrap{width:100%;max-width:360px;}

.form-logo{
  display:flex;align-items:center;gap:10px;
  margin-bottom:32px;
}
.form-logo-icon{
  width:42px;height:42px;background:var(--primary);
  border-radius:11px;display:flex;align-items:center;
  justify-content:center;font-size:18px;color:#fff;
}
.form-logo-text{font-size:18px;font-weight:800;letter-spacing:-.3px;}
.form-logo-sub{font-size:11px;color:var(--muted);font-weight:400;margin-top:1px;}

.form-heading{font-size:26px;font-weight:800;letter-spacing:-.5px;margin-bottom:4px;}
.form-sub{font-size:13px;color:var(--muted);margin-bottom:28px;line-height:1.5;}

/* ROLE SELECTOR TABS — replaces boring dropdown */
.role-tabs{display:grid;grid-template-columns:1fr 1fr;gap:8px;margin-bottom:22px;}
.role-tab{
  padding:12px;border:1.5px solid var(--border);border-radius:10px;
  cursor:pointer;text-align:center;transition:.15s;
  background:var(--input-bg);position:relative;
}
.role-tab:hover{border-color:var(--primary);}
.role-tab.active{border-color:var(--primary);background:var(--primary-light);}
.role-tab input{position:absolute;opacity:0;width:0;height:0;}
.role-tab i{font-size:18px;color:var(--muted);margin-bottom:5px;display:block;}
.role-tab.active i{color:var(--primary);}
.role-tab span{font-size:12px;font-weight:600;color:var(--muted);}
.role-tab.active span{color:var(--primary);}
.role-tab .check{
  position:absolute;top:6px;right:6px;
  width:16px;height:16px;border-radius:50%;
  background:var(--primary);color:#fff;
  font-size:9px;display:none;
  align-items:center;justify-content:center;
}
.role-tab.active .check{display:flex;}

.field-label{
  font-size:11px;font-weight:700;color:var(--muted);
  text-transform:uppercase;letter-spacing:.5px;
  display:block;margin-bottom:6px;
}
.field{margin-bottom:16px;}
.input-wrap{position:relative;}
.input-wrap .icon{
  position:absolute;left:13px;top:50%;transform:translateY(-50%);
  color:var(--muted);font-size:13px;pointer-events:none;
}
.input-wrap input{
  width:100%;padding:11px 42px;
  border:1.5px solid var(--border);border-radius:10px;
  background:var(--input-bg);color:var(--text);
  font-size:13px;font-weight:500;outline:none;
  transition:.15s;
}
.input-wrap input:focus{border-color:var(--primary);background:var(--surface);}
.input-wrap input::placeholder{color:var(--muted);font-weight:400;}
.eye-btn{
  position:absolute;right:12px;top:50%;transform:translateY(-50%);
  background:none;border:none;cursor:pointer;
  color:var(--muted);font-size:13px;padding:4px;
}
.eye-btn:hover{color:var(--primary);}

.row-between{display:flex;justify-content:space-between;align-items:center;margin-bottom:20px;}
.remember{display:flex;align-items:center;gap:7px;font-size:13px;color:var(--muted);cursor:pointer;}
.remember input{accent-color:var(--primary);width:14px;height:14px;}
.forgot-link{font-size:12px;color:var(--primary);text-decoration:none;font-weight:500;}
.forgot-link:hover{text-decoration:underline;}

.sign-btn{
  width:100%;padding:13px;
  background:var(--primary);color:#fff;
  border:none;border-radius:10px;
  cursor:pointer;font-weight:700;font-size:14px;
  display:flex;align-items:center;justify-content:center;gap:9px;
  transition:.2s;letter-spacing:.2px;
}
.sign-btn:hover{background:var(--primary-dark);transform:translateY(-1px);box-shadow:0 6px 20px rgba(67,97,238,.35);}
.sign-btn:active{transform:translateY(0);}

/* alert */
.alert{
  padding:11px 14px;border-radius:9px;
  font-size:13px;margin-bottom:18px;
  display:flex;align-items:center;gap:9px;font-weight:500;
}
.alert.error{background:#fef2f2;border:1.5px solid #fecaca;color:var(--danger);}
.alert.success{background:#f0fdf4;border:1.5px solid #bbf7d0;color:var(--success);}

.divider{
  display:flex;align-items:center;gap:12px;
  margin:22px 0;color:var(--border);
}
.divider::before,.divider::after{content:'';flex:1;height:1px;background:var(--border);}
.divider span{font-size:12px;color:var(--muted);white-space:nowrap;}

.register-link{
  text-align:center;font-size:13px;color:var(--muted);
}
.register-link a{color:var(--primary);text-decoration:none;font-weight:600;}
.register-link a:hover{text-decoration:underline;}

.footer-note{
  margin-top:28px;text-align:center;font-size:11px;color:var(--muted);
}
</style>
</head>
<body>

<!-- ── LEFT ── -->
<div class="left">
  <div class="brand">
    <div class="brand-icon"><i class="fa fa-cubes"></i></div>
    <div>
      <div class="brand-name">SIBS</div>
      <div style="font-size:11px;color:rgba(255,255,255,.6);margin-top:1px;">Smart Inventory & Billing</div>
    </div>
  </div>

  <h1>Manage your<br>business <em>smarter</em></h1>
  <p>A powerful real-time platform for inventory, orders, billing, and multi-role access — all in one place.</p>

  <div class="feature-list">
    <div class="feat">
      <div class="feat-icon"><i class="fa fa-boxes-stacked"></i></div>
      <div class="feat-text">Real-time inventory & stock alerts</div>
    </div>
    <div class="feat">
      <div class="feat-icon"><i class="fa fa-chart-line"></i></div>
      <div class="feat-text">Sales analytics & live dashboard</div>
    </div>
    <div class="feat">
      <div class="feat-icon"><i class="fa fa-truck-fast"></i></div>
      <div class="feat-text">Order tracking from placed to delivered</div>
    </div>
    <div class="feat">
      <div class="feat-icon"><i class="fa fa-shield-halved"></i></div>
      <div class="feat-text">Role-based access — Admin & Staff</div>
    </div>
  </div>

  <div class="stats-row">
    <div class="stat-box"><div class="stat-num">100%</div><div class="stat-lbl">Secure</div></div>
    <div class="stat-box"><div class="stat-num">Live</div><div class="stat-lbl">Real-time</div></div>
    <div class="stat-box"><div class="stat-num">Fast</div><div class="stat-lbl">Performance</div></div>
  </div>
</div>

<!-- ── RIGHT ── -->
<div class="right">
  <button class="theme-btn" onclick="toggleDark()" title="Toggle theme"><i class="fa fa-moon"></i></button>

  <div class="form-wrap">
    <div class="form-logo">
      <div class="form-logo-icon"><i class="fa fa-cubes"></i></div>
      <div>
        <div class="form-logo-text">SIBS</div>
        <div class="form-logo-sub">Admin Portal</div>
      </div>
    </div>

    <div class="form-heading">Welcome back</div>
    <p class="form-sub">Sign in to manage your inventory, orders, and team.</p>

    <%
    String error   = request.getParameter("error");
    String success = request.getParameter("success");
    if(error != null){ %>
    <div class="alert error"><i class="fa fa-circle-exclamation"></i> Invalid credentials. Please check your username, password, and role.</div>
    <% } if(success != null){ %>
    <div class="alert success"><i class="fa fa-circle-check"></i> Account created successfully — please sign in.</div>
    <% } %>

    <form action="login" method="post" id="loginForm">

      <!-- ROLE SELECTOR (no boring dropdown) -->
      <label class="field-label">Select your role</label>
      <div class="role-tabs" style="margin-bottom:22px;">
        <label class="role-tab active" id="tab-admin">
          <input type="radio" name="role" value="ADMIN" checked onchange="setTab('admin')">
          <i class="fa fa-user-shield"></i>
          <span>Admin</span>
          <div class="check"><i class="fa fa-check"></i></div>
        </label>
        <label class="role-tab" id="tab-staff">
          <input type="radio" name="role" value="STAFF" onchange="setTab('staff')">
          <i class="fa fa-user-tie"></i>
          <span>Staff</span>
          <div class="check"><i class="fa fa-check"></i></div>
        </label>
      </div>

      <div class="field">
        <label class="field-label">Username or Email</label>
        <div class="input-wrap">
          <i class="icon fa fa-user"></i>
          <input type="text" name="username" placeholder="Enter username or email" required autocomplete="username">
        </div>
      </div>

      <div class="field">
        <label class="field-label">Password</label>
        <div class="input-wrap">
          <i class="icon fa fa-lock"></i>
          <input type="password" name="password" id="pwd" placeholder="Enter your password" required autocomplete="current-password">
          <button type="button" class="eye-btn" onclick="togglePwd()"><i class="fa fa-eye" id="eyeIcon"></i></button>
        </div>
      </div>

      <div class="row-between">
        <label class="remember">
          <input type="checkbox"> Remember me
        </label>
        <a class="forgot-link" href="#">Forgot password?</a>
      </div>

      <button type="submit" class="sign-btn">
        <i class="fa fa-arrow-right-to-bracket"></i> Sign In
      </button>
    </form>

    <div class="divider"><span>New to SIBS?</span></div>

    <div class="register-link">
      Don't have an admin account? <a href="admin-register.jsp">Create one</a>
    </div>

    <div class="footer-note">
      SIBS © 2026 &nbsp;·&nbsp; 
    </div>
  </div>
</div>

<script>
// THEME
function toggleDark(){
  const h=document.documentElement,d=h.getAttribute('data-theme')==='dark';
  h.setAttribute('data-theme',d?'light':'dark');
  localStorage.setItem('sibs-theme',d?'light':'dark');
}
(function(){const t=localStorage.getItem('sibs-theme');if(t)document.documentElement.setAttribute('data-theme',t);})();

// PASSWORD TOGGLE
function togglePwd(){
  const p=document.getElementById('pwd'),i=document.getElementById('eyeIcon');
  p.type=p.type==='password'?'text':'password';
  i.className=p.type==='password'?'fa fa-eye':'fa fa-eye-slash';
}

// ROLE TABS
function setTab(role){
  document.getElementById('tab-admin').classList.toggle('active', role==='admin');
  document.getElementById('tab-staff').classList.toggle('active', role==='staff');
}
// Also handle click on label
document.querySelectorAll('.role-tab').forEach(tab=>{
  tab.addEventListener('click',()=>{
    const inp=tab.querySelector('input');
    if(inp) setTab(inp.value==='ADMIN'?'admin':'staff');
  });
});
</script>
</body>
</html>
