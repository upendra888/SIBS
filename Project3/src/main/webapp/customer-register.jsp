<%@ page language="java" contentType="text/html; charset=UTF-8" %>
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Create Account — SIBS Shop</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<style>
:root{--bg:#f8fafc;--surface:#fff;--border:#e2e8f0;--text:#0f172a;--muted:#64748b;--primary:#16a34a;}
[data-theme="dark"]{--bg:#0f172a;--surface:#1e293b;--border:#334155;--text:#f1f5f9;--muted:#94a3b8;}
*{margin:0;padding:0;box-sizing:border-box;font-family:'Inter',sans-serif;}
body{min-height:100vh;background:var(--bg);color:var(--text);display:flex;align-items:center;justify-content:center;padding:20px;}
.dark-btn{position:fixed;top:16px;right:16px;background:none;border:1px solid var(--border);width:36px;height:36px;border-radius:8px;cursor:pointer;color:var(--muted);}
.card{background:var(--surface);border:1px solid var(--border);border-radius:16px;padding:36px 32px;max-width:420px;width:100%;box-shadow:0 4px 20px rgba(0,0,0,.07);}
.logo{display:flex;align-items:center;justify-content:center;gap:8px;margin-bottom:20px;}
.logo i{font-size:22px;color:var(--primary);}
.logo span{font-size:20px;font-weight:700;}
h2{font-size:19px;font-weight:700;text-align:center;margin-bottom:4px;}
.sub{font-size:13px;color:var(--muted);text-align:center;margin-bottom:22px;}
.alert{padding:10px 14px;border-radius:8px;font-size:13px;margin-bottom:14px;display:flex;align-items:center;gap:8px;}
.alert.error{background:#fef2f2;border:1px solid #fecaca;color:#dc2626;}
.form-row{display:grid;grid-template-columns:1fr 1fr;gap:10px;margin-bottom:0;}
.field{margin-bottom:12px;}
.field label{display:block;font-size:12px;font-weight:600;color:var(--muted);margin-bottom:5px;text-transform:uppercase;letter-spacing:.3px;}
.input-wrap{position:relative;}
.input-wrap i.icon{position:absolute;left:11px;top:50%;transform:translateY(-50%);color:var(--muted);font-size:12px;}
.input-wrap input,.input-wrap select{width:100%;padding:9px 12px 9px 34px;border:1px solid var(--border);border-radius:7px;background:var(--bg);color:var(--text);font-size:13px;outline:none;transition:.15s;}
.input-wrap input:focus,.input-wrap select:focus{border-color:var(--primary);background:var(--surface);}
.input-wrap input.err{border-color:#ef4444;}
.eye-btn{position:absolute;right:8px;top:50%;transform:translateY(-50%);background:none;border:none;cursor:pointer;color:var(--muted);font-size:12px;}
.strength{height:3px;border-radius:99px;margin-top:4px;background:var(--border);overflow:hidden;}
.strength-bar{height:100%;border-radius:99px;transition:.3s;width:0;}
.submit-btn{width:100%;padding:11px;background:var(--primary);color:#fff;border:none;border-radius:8px;cursor:pointer;font-weight:600;font-size:14px;margin-top:4px;transition:.15s;display:flex;align-items:center;justify-content:center;gap:8px;}
.submit-btn:hover{opacity:.9;}
.divider{border:none;border-top:1px solid var(--border);margin:18px 0;}
.links{text-align:center;font-size:13px;color:var(--muted);}
.links a{color:var(--primary);text-decoration:none;font-weight:500;}
</style>
</head>
<body>
<button class="dark-btn" onclick="toggleDark()"><i class="fa fa-moon"></i></button>
<div class="card">
  <div class="logo"><i class="fa fa-leaf"></i><span>SIBS Shop</span></div>
  <h2>Create Account</h2>
  <p class="sub">Join SIBS Shop for fresh groceries delivered fast</p>

  <%
  String error = request.getParameter("error");
  if("password".equals(error)){  %><div class="alert error"><i class="fa fa-circle-exclamation"></i> Passwords do not match</div><%
  } else if("email".equals(error)){  %><div class="alert error"><i class="fa fa-circle-exclamation"></i> Email already exists</div><%
  } else if("username".equals(error)){  %><div class="alert error"><i class="fa fa-circle-exclamation"></i> Username already taken</div><% } %>

  <form action="CustomerRegisterServlet" method="post" onsubmit="return validateReg()">
    <div class="form-row">
      <div class="field" style="margin:0 0 12px;">
        <label>Full Name *</label>
        <div class="input-wrap"><i class="icon fa fa-user"></i><input type="text" name="name" id="rname" placeholder="Your name" required></div>
      </div>
      <div class="field" style="margin:0 0 12px;">
        <label>Phone *</label>
        <div class="input-wrap"><i class="icon fa fa-phone"></i><input type="text" name="phone" id="rphone" placeholder="10-digit" required></div>
      </div>
    </div>
    <div class="field">
      <label>Email *</label>
      <div class="input-wrap"><i class="icon fa fa-envelope"></i><input type="email" name="email" id="remail" placeholder="you@email.com" required></div>
    </div>
    <div class="field">
      <label>Password *</label>
      <div class="input-wrap">
        <i class="icon fa fa-lock"></i>
        <input type="password" name="password" id="rpwd" placeholder="Min 6 characters" required oninput="checkStrength(this.value)">
        <button type="button" class="eye-btn" onclick="togglePwd('rpwd','eye1')"><i class="fa fa-eye" id="eye1"></i></button>
      </div>
      <div class="strength"><div class="strength-bar" id="strengthBar"></div></div>
    </div>
    <div class="field">
      <label>Confirm Password *</label>
      <div class="input-wrap">
        <i class="icon fa fa-lock"></i>
        <input type="password" name="confirmPassword" id="rcpwd" placeholder="Re-enter password" required>
        <button type="button" class="eye-btn" onclick="togglePwd('rcpwd','eye2')"><i class="fa fa-eye" id="eye2"></i></button>
      </div>
    </div>
    <div class="form-row">
      <div class="field" style="margin:0 0 12px;">
        <label>Gender</label>
        <div class="input-wrap"><i class="icon fa fa-venus-mars"></i>
          <select name="gender">
            <option value="">Select</option>
            <option>Male</option><option>Female</option><option>Other</option>
          </select>
        </div>
      </div>
      <div class="field" style="margin:0 0 12px;">
        <label>Address</label>
        <div class="input-wrap"><i class="icon fa fa-map-marker-alt"></i><input type="text" name="address" placeholder="City, State"></div>
      </div>
    </div>
    <button type="submit" class="submit-btn"><i class="fa fa-user-plus"></i> Create Account</button>
  </form>
  <hr class="divider">
  <div class="links">Already have an account? <a href="customer-login.jsp">Sign in</a></div>
</div>

<script>
function toggleDark(){const h=document.documentElement,d=h.getAttribute('data-theme')==='dark';h.setAttribute('data-theme',d?'light':'dark');localStorage.setItem('sibs-theme',d?'light':'dark');}
(function(){const t=localStorage.getItem('sibs-theme');if(t)document.documentElement.setAttribute('data-theme',t);})();
function togglePwd(id,icoId){const p=document.getElementById(id),i=document.getElementById(icoId);p.type=p.type==='password'?'text':'password';i.className=p.type==='password'?'fa fa-eye':'fa fa-eye-slash';}
function checkStrength(v){
  const bar=document.getElementById('strengthBar');
  let score=0;
  if(v.length>=6) score++;
  if(v.length>=10) score++;
  if(/[A-Z]/.test(v)) score++;
  if(/[0-9]/.test(v)) score++;
  if(/[^A-Za-z0-9]/.test(v)) score++;
  const colors=['#ef4444','#f59e0b','#f59e0b','#22c55e','#16a34a'];
  bar.style.width=(score*20)+'%';
  bar.style.background=colors[score-1]||'var(--border)';
}
function validateReg(){
  const p=document.getElementById('rpwd').value;
  const cp=document.getElementById('rcpwd').value;
  if(p!==cp){document.getElementById('rcpwd').classList.add('err');alert('Passwords do not match!');return false;}
  if(p.length<6){alert('Password must be at least 6 characters');return false;}
  return true;
}
</script>
</body>
</html>
