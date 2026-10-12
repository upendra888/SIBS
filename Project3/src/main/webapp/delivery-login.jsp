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
<title>Delivery Boy Login — SIBS</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<style>
*{margin:0;padding:0;box-sizing:border-box;font-family:'Inter',sans-serif;}
body{background:linear-gradient(135deg,#0f172a,#1e3a5f);min-height:100vh;display:flex;align-items:center;justify-content:center;}
.card{background:#fff;border-radius:16px;padding:40px;width:100%;max-width:420px;box-shadow:0 20px 60px rgba(0,0,0,.3);}
.logo{text-align:center;margin-bottom:28px;}
.logo i{font-size:40px;color:#f97316;}
.logo h2{font-size:22px;font-weight:700;color:#0f172a;margin-top:10px;}
.logo p{font-size:13px;color:#64748b;margin-top:4px;}
.form-group{margin-bottom:18px;}
label{display:block;font-size:13px;font-weight:500;color:#374151;margin-bottom:6px;}
input{width:100%;padding:11px 14px;border:1px solid #e2e8f0;border-radius:8px;font-size:14px;outline:none;transition:.2s;}
input:focus{border-color:#f97316;box-shadow:0 0 0 3px rgba(249,115,22,.1);}
.btn{width:100%;padding:12px;background:#f97316;color:#fff;border:none;border-radius:8px;font-size:15px;font-weight:600;cursor:pointer;margin-top:6px;transition:.2s;}
.btn:hover{background:#ea6c0a;}
.error{background:#fef2f2;border:1px solid #fecaca;color:#dc2626;padding:10px 14px;border-radius:8px;font-size:13px;margin-bottom:16px;display:flex;align-items:center;gap:8px;}
.back-link{text-align:center;margin-top:20px;font-size:13px;color:#64748b;}
.back-link a{color:#f97316;text-decoration:none;font-weight:500;}
</style>
</head>
<body>
<div class="card">
  <div class="logo">
    <i class="fa fa-motorcycle"></i>
    <h2>Delivery Portal</h2>
    <p>Login to see your assigned orders</p>
  </div>

  <% if ("submitted".equals(msg)) { %>
    <div style="background:#f0fdf4;border:1px solid #bbf7d0;color:#16a34a;padding:12px 14px;border-radius:8px;font-size:13px;margin-bottom:16px;display:flex;align-items:flex-start;gap:8px;">
      <i class="fa fa-circle-check" style="margin-top:1px;"></i>
      <span><strong>Application submitted!</strong> Your documents are under review (2–3 working days). You'll get an email once approved.</span>
    </div>
  <% } else if ("success".equals(msg)) { %>
    <div style="background:#f0fdf4;border:1px solid #bbf7d0;color:#16a34a;padding:10px 14px;border-radius:8px;font-size:13px;margin-bottom:16px;display:flex;align-items:center;gap:8px;">
      <i class="fa fa-circle-check"></i> Registration successful! You can now log in.
    </div>
  <% } %>
  <% if(error != null){ %>
  <div class="error"><i class="fa fa-circle-exclamation"></i> <%=error%></div>
  <% } %>

  <form action="deliveryLogin" method="post">
    <div class="form-group">
      <label>Email Address</label>
      <input type="email" name="email" placeholder="Enter your email" required>
    </div>
    <div class="form-group">
      <label>Password</label>
      <input type="password" name="password" placeholder="Enter your password" required>
    </div>
    <button class="btn" type="submit">
      <i class="fa fa-right-to-bracket"></i> Login
    </button>
  </form>

  <div class="back-link">
  
  </div>
  <div class="back-link" style="margin-top:12px;">
    New delivery partner? <a href="delivery-register.jsp"><i class="fa fa-user-plus"></i> Register here</a>
  </div>
</div>
</body>
</html>