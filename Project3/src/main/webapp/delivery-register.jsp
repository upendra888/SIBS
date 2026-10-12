<%@ page contentType="text/html;charset=UTF-8" %>
<%
String error = request.getParameter("error");
String msg   = request.getParameter("msg");
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Delivery Boy Register — SIBS</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<style>
*{margin:0;padding:0;box-sizing:border-box;font-family:'Inter',sans-serif;}
body{background:linear-gradient(135deg,#0f172a,#1e3a5f);min-height:100vh;display:flex;align-items:center;justify-content:center;padding:20px;}
.card{background:#fff;border-radius:16px;padding:40px;width:100%;max-width:480px;box-shadow:0 20px 60px rgba(0,0,0,.3);}
.logo{text-align:center;margin-bottom:28px;}
.logo i{font-size:42px;color:#f97316;}
.logo h2{font-size:22px;font-weight:700;color:#0f172a;margin-top:10px;}
.logo p{font-size:13px;color:#64748b;margin-top:4px;}
.form-group{margin-bottom:16px;position:relative;}
label{display:block;font-size:13px;font-weight:500;color:#374151;margin-bottom:6px;}
input,select{width:100%;padding:11px 14px 11px 38px;border:1px solid #e2e8f0;border-radius:8px;font-size:14px;outline:none;transition:.2s;background:#fff;}
input:focus,select:focus{border-color:#f97316;box-shadow:0 0 0 3px rgba(249,115,22,.1);}
.input-icon{position:absolute;left:12px;top:36px;color:#94a3b8;font-size:14px;}
.btn{width:100%;padding:12px;background:#f97316;color:#fff;border:none;border-radius:8px;font-size:15px;font-weight:600;cursor:pointer;margin-top:6px;transition:.2s;}
.btn:hover{background:#ea6c0a;}
.alert{padding:10px 14px;border-radius:8px;font-size:13px;margin-bottom:16px;display:flex;align-items:center;gap:8px;}
.alert-error{background:#fef2f2;border:1px solid #fecaca;color:#dc2626;}
.alert-success{background:#f0fdf4;border:1px solid #bbf7d0;color:#16a34a;}
.hint{font-size:11px;color:#94a3b8;margin-top:4px;}
.toggle-pwd{position:absolute;right:12px;top:36px;color:#94a3b8;cursor:pointer;font-size:14px;}
.back-link{text-align:center;margin-top:16px;font-size:13px;color:#64748b;}
.back-link a{color:#f97316;text-decoration:none;font-weight:500;}
select{padding-left:38px;}
</style>
</head>
<body>
<div class="card">
  <div class="logo">
    <i class="fa fa-motorcycle"></i>
    <h2>Delivery Partner Registration</h2>
    <p>Join SIBS delivery network</p>
  </div>

  <% if ("email".equals(error)) { %>
    <div class="alert alert-error"><i class="fa fa-circle-exclamation"></i> This email is already registered.</div>
  <% } else if ("phone".equals(error)) { %>
    <div class="alert alert-error"><i class="fa fa-circle-exclamation"></i> This phone number is already in use.</div>
  <% } else if ("password".equals(error)) { %>
    <div class="alert alert-error"><i class="fa fa-circle-exclamation"></i> Passwords do not match.</div>
  <% } else if ("failed".equals(error)) { %>
    <div class="alert alert-error"><i class="fa fa-circle-exclamation"></i> Registration failed. Please try again.</div>
  <% } else if (error != null && error.startsWith("DB Error")) { %>
    <div class="alert alert-error" style="flex-direction:column;align-items:flex-start;gap:4px;">
      <span><i class="fa fa-circle-exclamation"></i> <strong>DB Error — share this with developer:</strong></span>
      <code style="font-size:11px;word-break:break-all;background:#fef2f2;padding:6px 8px;border-radius:4px;width:100%;">
        <%= error %>
      </code>
    </div>
  <% } else if ("success".equals(msg)) { %>
    <div class="alert alert-success"><i class="fa fa-circle-check"></i> Registered successfully! You can now log in.</div>
  <% } %>

  <form id="registerForm" action="deliveryRegister" method="post" onsubmit="return validate()">
    <div class="form-group">
      <label>Full Name</label>
      <i class="fa fa-user input-icon"></i>
      <input type="text" name="name" placeholder="Enter your full name" required maxlength="100">
    </div>
    <div class="form-group">
      <label>Email Address</label>
      <i class="fa fa-envelope input-icon"></i>
      <input type="email" name="email" placeholder="Enter your email" required maxlength="150">
    </div>
    <div class="form-group">
      <label>Phone Number</label>
      <i class="fa fa-phone input-icon"></i>
      <input type="tel" name="phone" id="phone" placeholder="10-digit mobile number" required maxlength="10">
      <span class="hint">Numbers only, 10 digits</span>
    </div>
    <div class="form-group">
      <label>City</label>
      <i class="fa fa-location-dot input-icon"></i>
      <select name="city" required>
        <option value="">-- Select City --</option>
        <option>Hyderabad</option>
        <option>Bengaluru</option>
        <option>Chennai</option>
        <option>Mumbai</option>
        <option>Delhi</option>
        <option>Pune</option>
        <option>Kolkata</option>
        <option>Ahmedabad</option>
      </select>
    </div>
    <div class="form-group">
      <label>Password</label>
      <i class="fa fa-lock input-icon"></i>
      <input type="password" id="password" name="password" placeholder="Min 6 characters" required minlength="6">
      <i class="fa fa-eye toggle-pwd" onclick="togglePwd('password',this)"></i>
    </div>
    <div class="form-group">
      <label>Confirm Password</label>
      <i class="fa fa-lock input-icon"></i>
      <input type="password" id="confirmPassword" name="confirmPassword" placeholder="Re-enter password" required minlength="6">
      <i class="fa fa-eye toggle-pwd" onclick="togglePwd('confirmPassword',this)"></i>
    </div>
    <button class="btn" type="submit"><i class="fa fa-user-plus"></i> Register</button>
  </form>

  <div class="back-link" style="margin-top:16px;">
    Already have an account? <a href="delivery-login.jsp">Login here</a>
  </div>
</div>

<script>
function togglePwd(id, icon) {
  const inp = document.getElementById(id);
  if (inp.type === 'password') { inp.type = 'text'; icon.classList.replace('fa-eye','fa-eye-slash'); }
  else { inp.type = 'password'; icon.classList.replace('fa-eye-slash','fa-eye'); }
}
function validate() {
  const phone = document.getElementById('phone').value;
  const pass  = document.getElementById('password').value;
  const conf  = document.getElementById('confirmPassword').value;
  if (!/^\d{10}$/.test(phone)) { alert('Phone must be exactly 10 digits.'); return false; }
  if (pass !== conf)            { alert('Passwords do not match.');          return false; }
  return true;
}
</script>
</body>
</html>
