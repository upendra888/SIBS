<%@ page import="com.sibs.model.User" %>
<%
User user=(User)session.getAttribute("user");
if(user==null || !"ADMIN".equals(user.getRole())){ response.sendRedirect("login.jsp"); return; }
%>
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Add Staff — SIBS</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<style>
:root{--bg:#f8fafc;--surface:#fff;--border:#e2e8f0;--text:#0f172a;--muted:#64748b;--primary:#2563eb;--success:#16a34a;}
[data-theme="dark"]{--bg:#0f172a;--surface:#1e293b;--border:#334155;--text:#f1f5f9;--muted:#94a3b8;}
*{margin:0;padding:0;box-sizing:border-box;font-family:'Inter',sans-serif;}
body{background:var(--bg);color:var(--text);min-height:100vh;}
.topbar{background:var(--surface);border-bottom:1px solid var(--border);padding:0 24px;height:60px;display:flex;align-items:center;gap:10px;position:sticky;top:0;z-index:50;}
.topbar a{color:var(--muted);text-decoration:none;font-size:13px;display:flex;align-items:center;gap:5px;}
.topbar a:hover{color:var(--primary);}
.page-title{font-weight:700;font-size:16px;}
.dark-btn{background:none;border:1px solid var(--border);width:34px;height:34px;border-radius:8px;cursor:pointer;color:var(--muted);margin-left:auto;}
.form-wrap{max-width:480px;margin:32px auto;padding:0 16px;}
.form-card{background:var(--surface);border:1px solid var(--border);border-radius:12px;padding:28px;}
.form-card h3{font-size:15px;font-weight:700;margin-bottom:20px;padding-bottom:12px;border-bottom:1px solid var(--border);}
.field{margin-bottom:14px;}
.field label{display:block;font-size:12px;font-weight:600;color:var(--muted);margin-bottom:6px;text-transform:uppercase;letter-spacing:.4px;}
.input-wrap{position:relative;}
.input-wrap i.icon{position:absolute;left:11px;top:50%;transform:translateY(-50%);color:var(--muted);font-size:13px;}
.input-wrap input,.input-wrap select{width:100%;padding:9px 12px 9px 36px;border:1px solid var(--border);border-radius:7px;background:var(--bg);color:var(--text);font-size:13px;outline:none;transition:.15s;}
.input-wrap input:focus,.input-wrap select:focus{border-color:var(--primary);background:var(--surface);}
.input-wrap input.error-field{border-color:#ef4444;}
.eye-btn{position:absolute;right:10px;top:50%;transform:translateY(-50%);background:none;border:none;cursor:pointer;color:var(--muted);}
.form-row{display:grid;grid-template-columns:1fr 1fr;gap:12px;}
.submit-btn{width:100%;padding:11px;background:var(--success);color:#fff;border:none;border-radius:8px;cursor:pointer;font-weight:600;font-size:14px;margin-top:6px;transition:.15s;display:flex;align-items:center;justify-content:center;gap:8px;}
.submit-btn:hover{background:#15803d;}
.alert{padding:10px 14px;border-radius:8px;font-size:13px;margin-bottom:14px;display:flex;align-items:center;gap:8px;}
.alert.error{background:#fef2f2;border:1px solid #fecaca;color:#dc2626;}
.alert.success{background:#f0fdf4;border:1px solid #bbf7d0;color:#16a34a;}
.field-hint{font-size:11px;color:#ef4444;margin-top:4px;display:none;}
.field-hint.show{display:block;}
</style>
</head>
<body>
<div class="topbar">
  <a href="dashboard.jsp"><i class="fa fa-arrow-left"></i> Dashboard</a>
  <span style="color:var(--border);">|</span>
  <span class="page-title">Add Staff</span>
  <button class="dark-btn" onclick="toggleDark()"><i class="fa fa-moon"></i></button>
</div>
<div class="form-wrap">
  <div class="form-card">
    <h3><i class="fa fa-user-plus" style="color:var(--success);"></i> Register New Staff</h3>
    <%
    String err = request.getParameter("error");
    String suc = request.getParameter("success");
    if("exists".equals(err)||"username".equals(err)){ %><div class="alert error"><i class="fa fa-circle-exclamation"></i> Username already exists.</div><% }
    if("email".equals(err)){ %><div class="alert error"><i class="fa fa-circle-exclamation"></i> Email already exists.</div><% }
    if("failed".equals(err)){ %><div class="alert error"><i class="fa fa-circle-exclamation"></i> Failed to add staff. Please try again.</div><% }
    if(suc != null){ %><div class="alert success"><i class="fa fa-circle-check"></i> Staff member added successfully! Login credentials have been sent to their email.</div><% } %>

    <form action="addStaff" method="post" onsubmit="return validateStaff()">
      <div class="form-row">
        <div class="field" style="margin:0;">
          <label>Username *</label>
          <div class="input-wrap"><i class="fa fa-user icon"></i><input type="text" name="username" id="suser" placeholder="staff_username" required></div>
        </div>
        <div class="field" style="margin:0;">
          <label>Email *</label>
          <div class="input-wrap"><i class="fa fa-envelope icon"></i><input type="email" name="email" id="semail" placeholder="staff@email.com" required></div>
        </div>
      </div>

      <div class="field">
        <label>Password *</label>
        <div class="input-wrap">
          <i class="fa fa-lock icon"></i>
          <input type="password" name="password" id="spwd" placeholder="Min 6 characters" required>
          <button type="button" class="eye-btn" onclick="togglePwd('spwd','eyeI1')"><i class="fa fa-eye" id="eyeI1"></i></button>
        </div>
      </div>

      <!-- NEW: Confirm Password field -->
      <div class="field">
        <label>Confirm Password *</label>
        <div class="input-wrap">
          <i class="fa fa-lock icon"></i>
          <input type="password" id="spwd2" placeholder="Re-enter password" required>
          <button type="button" class="eye-btn" onclick="togglePwd('spwd2','eyeI2')"><i class="fa fa-eye" id="eyeI2"></i></button>
        </div>
        <div class="field-hint" id="pwdHint">Passwords do not match.</div>
      </div>

      <div class="field">
        <label>Role</label>
        <div class="input-wrap">
          <i class="fa fa-user-shield icon"></i>
          <select name="role">
            <option value="STAFF">Staff</option>
            <option value="ADMIN">Admin</option>
          </select>
        </div>
      </div>
      <div class="field">
        <label>Status</label>
        <div class="input-wrap">
          <i class="fa fa-toggle-on icon"></i>
          <select name="status">
            <option value="ACTIVE">Active</option>
            <option value="INACTIVE">Inactive</option>
          </select>
        </div>
      </div>
      <button type="submit" class="submit-btn"><i class="fa fa-user-plus"></i> Add Staff Member</button>
    </form>
  </div>
</div>
<script>
function toggleDark(){const h=document.documentElement,d=h.getAttribute('data-theme')==='dark';h.setAttribute('data-theme',d?'light':'dark');localStorage.setItem('sibs-theme',d?'light':'dark');}
(function(){const t=localStorage.getItem('sibs-theme');if(t)document.documentElement.setAttribute('data-theme',t);})();

function togglePwd(fieldId, iconId){
  const p=document.getElementById(fieldId), i=document.getElementById(iconId);
  p.type=p.type==='password'?'text':'password';
  i.className=p.type==='password'?'fa fa-eye':'fa fa-eye-slash';
}

// Live confirm-password feedback
document.getElementById('spwd2').addEventListener('input', checkPwdMatch);
document.getElementById('spwd').addEventListener('input',  checkPwdMatch);
function checkPwdMatch(){
  const p1=document.getElementById('spwd').value;
  const p2=document.getElementById('spwd2').value;
  const hint=document.getElementById('pwdHint');
  const f2=document.getElementById('spwd2');
  if(p2.length === 0){ hint.classList.remove('show'); f2.classList.remove('error-field'); return; }
  if(p1 !== p2){ hint.classList.add('show'); f2.classList.add('error-field'); }
  else { hint.classList.remove('show'); f2.classList.remove('error-field'); }
}

function validateStaff(){
  const u=document.getElementById('suser').value.trim();
  const e=document.getElementById('semail').value.trim();
  const p=document.getElementById('spwd').value;
  const p2=document.getElementById('spwd2').value;
  if(!u||!e||!p||!p2){alert('All fields are required.');return false;}
  if(p.length<6){alert('Password must be at least 6 characters.');return false;}
  if(p!==p2){alert('Passwords do not match.');document.getElementById('spwd2').focus();return false;}
  return true;
}
</script>
</body>
</html>
