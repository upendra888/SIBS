<%@ page language="java" contentType="text/html; charset=UTF-8" %>
<%
String msg   = (String) session.getAttribute("msg");
String error = request.getParameter("error");
%>
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Customer Login — SIBS</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<style>
:root{--bg:#f8fafc;--surface:#fff;--border:#e2e8f0;--text:#0f172a;--muted:#64748b;--primary:#16a34a;}
[data-theme="dark"]{--bg:#0f172a;--surface:#1e293b;--border:#334155;--text:#f1f5f9;--muted:#94a3b8;}
*{margin:0;padding:0;box-sizing:border-box;font-family:'Inter',sans-serif;}
body{min-height:100vh;display:flex;align-items:center;justify-content:center;background:var(--bg);padding:20px;}
.dark-btn{position:fixed;top:16px;right:16px;background:none;border:1px solid var(--border);width:36px;height:36px;border-radius:8px;cursor:pointer;color:var(--muted);}
.card{background:var(--surface);border:1px solid var(--border);border-radius:16px;padding:36px 32px;max-width:380px;width:100%;box-shadow:0 4px 20px rgba(0,0,0,.07);}
.logo{display:flex;align-items:center;justify-content:center;gap:8px;margin-bottom:24px;}
.logo i{font-size:24px;color:var(--primary);}
.logo span{font-size:22px;font-weight:700;color:var(--text);}
h2{font-size:20px;font-weight:700;text-align:center;margin-bottom:4px;}
.sub{font-size:13px;color:var(--muted);text-align:center;margin-bottom:24px;}
.alert{padding:10px 14px;border-radius:8px;font-size:13px;margin-bottom:14px;display:flex;align-items:center;gap:8px;}
.alert.error{background:#fef2f2;border:1px solid #fecaca;color:#dc2626;}
.alert.success{background:#f0fdf4;border:1px solid #bbf7d0;color:#16a34a;}
.field{margin-bottom:14px;}
.field label{display:block;font-size:12px;font-weight:600;color:var(--muted);margin-bottom:6px;text-transform:uppercase;letter-spacing:.4px;}
.input-wrap{position:relative;}
.input-wrap i.icon{position:absolute;left:12px;top:50%;transform:translateY(-50%);color:var(--muted);font-size:13px;}
.input-wrap input{width:100%;padding:10px 40px 10px 38px;border:1px solid var(--border);border-radius:8px;background:var(--bg);color:var(--text);font-size:13px;outline:none;transition:.15s;}
.input-wrap input:focus{border-color:var(--primary);background:var(--surface);}
.eye-btn{position:absolute;right:10px;top:50%;transform:translateY(-50%);background:none;border:none;cursor:pointer;color:var(--muted);}
.submit-btn{width:100%;padding:11px;background:var(--primary);color:#fff;border:none;border-radius:8px;cursor:pointer;font-weight:600;font-size:14px;margin-top:6px;transition:.15s;display:flex;align-items:center;justify-content:center;gap:8px;}
.submit-btn:hover{opacity:.9;}
.divider{border:none;border-top:1px solid var(--border);margin:20px 0;}
.links{text-align:center;font-size:13px;color:var(--muted);}
.links a{color:var(--primary);text-decoration:none;font-weight:500;}
.admin-link{display:block;text-align:center;font-size:12px;color:var(--muted);margin-top:12px;}
.admin-link a{color:var(--muted);text-decoration:none;}
.admin-link a:hover{color:var(--text);}
</style>
</head>
<body>
<button class="dark-btn" onclick="toggleDark()"><i class="fa fa-moon"></i></button>

<div class="card">
  <div class="logo"><i class="fa fa-leaf"></i><span>SIBS Shop</span></div>
  <h2>Customer Login</h2>
  <p class="sub">Welcome back! Sign in to continue shopping.</p>

  <% if(msg != null){ %>
  <div class="alert success"><i class="fa fa-circle-check"></i> <%=msg%></div>
  <% session.removeAttribute("msg"); } %>

  <% if("1".equals(error)){ %>
  <div class="alert error"><i class="fa fa-circle-exclamation"></i> Invalid username or password</div>
  <% } %>

  <form action="CustomerLoginServlet" method="post">
    <div class="field">
      <label>Username or Email</label>
      <div class="input-wrap">
        <i class="icon fa fa-user"></i>
        <input type="text" name="username" placeholder="Enter username or email" required autocomplete="username">
      </div>
    </div>
    <div class="field">
      <label>Password</label>
      <div class="input-wrap">
        <i class="icon fa fa-lock"></i>
        <input type="password" name="password" id="pwd" placeholder="Enter password" required autocomplete="current-password">
        <button type="button" class="eye-btn" onclick="togglePwd()"><i class="fa fa-eye" id="eyeIcon"></i></button>
      </div>
    </div>
    <button type="submit" class="submit-btn"><i class="fa fa-sign-in-alt"></i> Sign In</button>
  </form>

  <hr class="divider">
  <div class="links">New here? <a href="customer-register.jsp">Create an account</a></div>

</div>

<script>
function toggleDark(){
  const h=document.documentElement,d=h.getAttribute('data-theme')==='dark';
  h.setAttribute('data-theme',d?'light':'dark');
  localStorage.setItem('sibs-theme',d?'light':'dark');
}
(function(){const t=localStorage.getItem('sibs-theme');if(t)document.documentElement.setAttribute('data-theme',t);})();
function togglePwd(){
  const p=document.getElementById('pwd'),i=document.getElementById('eyeIcon');
  p.type=p.type==='password'?'text':'password';
  i.className=p.type==='password'?'fa fa-eye':'fa fa-eye-slash';
}
</script>
</body>
</html>
