<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="com.sibs.dao.AddressDAO, com.sibs.model.Address, com.sibs.model.User" %>
<%
User user = (User)session.getAttribute("customer");
if(user == null){ response.sendRedirect("customer-login.jsp"); return; }

String idStr = request.getParameter("id");
if(idStr == null || idStr.trim().isEmpty()){
    response.sendRedirect("cartCheckout.jsp");
    return;
}

AddressDAO dao = new AddressDAO();
Address a = dao.getAddressById(Integer.parseInt(idStr));

// Security: make sure this address belongs to the logged-in user
if(a == null || a.getUserId() != user.getId()){
    response.sendRedirect("cartCheckout.jsp?error=notfound");
    return;
}

String redirect  = request.getParameter("redirect");
if(redirect == null || redirect.trim().isEmpty()) redirect = "cartCheckout.jsp";

String msgParam  = request.getParameter("success");
String errParam  = request.getParameter("error");
%>
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Edit Address — SIBS</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<style>
:root{--bg:#f8fafc;--surface:#fff;--border:#e2e8f0;--text:#0f172a;--muted:#64748b;--primary:#2563eb;--success:#16a34a;--danger:#ef4444;}
[data-theme="dark"]{--bg:#0f172a;--surface:#1e293b;--border:#334155;--text:#f1f5f9;--muted:#94a3b8;}
*{margin:0;padding:0;box-sizing:border-box;font-family:'Inter',sans-serif;}
body{background:var(--bg);color:var(--text);min-height:100vh;}
.topbar{background:var(--surface);border-bottom:1px solid var(--border);padding:0 20px;height:58px;display:flex;align-items:center;gap:10px;position:sticky;top:0;z-index:50;}
.topbar a{text-decoration:none;color:var(--muted);font-size:13px;display:flex;align-items:center;gap:5px;}
.topbar a:hover{color:var(--primary);}
.title{font-weight:700;font-size:15px;}
.dark-btn{background:none;border:1px solid var(--border);width:34px;height:34px;border-radius:8px;cursor:pointer;color:var(--muted);margin-left:auto;}
.content{max-width:480px;margin:32px auto;padding:0 16px;}
.card{background:var(--surface);border:1px solid var(--border);border-radius:12px;padding:28px;}
.card h3{font-size:15px;font-weight:700;margin-bottom:20px;padding-bottom:12px;border-bottom:1px solid var(--border);}
.field{margin-bottom:14px;}
.field label{display:block;font-size:12px;font-weight:600;color:var(--muted);margin-bottom:6px;text-transform:uppercase;letter-spacing:.4px;}
.input-wrap{position:relative;}
.input-wrap i{position:absolute;left:11px;top:50%;transform:translateY(-50%);color:var(--muted);font-size:13px;}
.input-wrap input,.input-wrap textarea{width:100%;padding:9px 12px 9px 36px;border:1px solid var(--border);border-radius:7px;background:var(--bg);color:var(--text);font-size:13px;outline:none;transition:.15s;}
.input-wrap input:focus,.input-wrap textarea:focus{border-color:var(--primary);background:var(--surface);}
.input-wrap textarea{padding-top:10px;min-height:90px;resize:vertical;}
.input-wrap .ta-icon{top:12px;transform:none;}
.save-btn{width:100%;padding:11px;background:var(--primary);color:#fff;border:none;border-radius:8px;cursor:pointer;font-weight:600;font-size:14px;transition:.15s;display:flex;align-items:center;justify-content:center;gap:8px;margin-top:4px;}
.save-btn:hover{background:#1d4ed8;}
.alert{padding:10px 14px;border-radius:8px;font-size:13px;margin-bottom:14px;display:flex;align-items:center;gap:8px;}
.alert.success{background:#f0fdf4;border:1px solid #bbf7d0;color:#16a34a;}
.alert.error  {background:#fef2f2;border:1px solid #fecaca;color:#dc2626;}
.addr-id{font-size:11px;color:var(--muted);text-align:center;margin-top:12px;}
</style>
</head>
<body>
<div class="topbar">
  <a href="<%=redirect%>"><i class="fa fa-arrow-left"></i> Back</a>
  <span style="color:var(--border);">|</span>
  <span class="title">Edit Address</span>
  <button class="dark-btn" onclick="toggleDark()"><i class="fa fa-moon"></i></button>
</div>

<div class="content">
  <% if(msgParam != null){ %>
  <div class="alert success"><i class="fa fa-circle-check"></i> Address updated successfully!</div>
  <% } %>
  <% if(errParam != null){ %>
  <div class="alert error"><i class="fa fa-circle-exclamation"></i> Something went wrong. Please try again.</div>
  <% } %>

  <div class="card">
    <h3><i class="fa fa-map-marker-alt" style="color:var(--primary);margin-right:6px;"></i> Edit Delivery Address</h3>

    <form action="updateAddress" method="post" onsubmit="return validateForm()">
      <input type="hidden" name="id"       value="<%=a.getId()%>">
      <input type="hidden" name="redirect" value="<%=redirect%>">

      <div class="field">
        <label>Full Name *</label>
        <div class="input-wrap">
          <i class="fa fa-user"></i>
          <input type="text" name="name" id="fname"
                 value="<%=a.getName() != null ? a.getName() : ""%>"
                 placeholder="Recipient name" required>
        </div>
      </div>

      <div class="field">
        <label>Phone Number *</label>
        <div class="input-wrap">
          <i class="fa fa-phone"></i>
          <input type="text" name="phone" id="fphone"
                 value="<%=a.getPhone() != null ? a.getPhone() : ""%>"
                 placeholder="10-digit phone number" required
                 pattern="[0-9]{10,15}" title="Enter a valid phone number">
        </div>
      </div>

      <div class="field">
        <label>Full Address *</label>
        <div class="input-wrap">
          <i class="fa fa-location-dot ta-icon"></i>
          <textarea name="address" id="faddress" placeholder="Street, City, State, Pincode" required><%=a.getAddress() != null ? a.getAddress() : ""%></textarea>
        </div>
      </div>

      <button type="submit" class="save-btn">
        <i class="fa fa-floppy-disk"></i> Save Changes
      </button>
    </form>

    <div class="addr-id">Address ID: #<%=a.getId()%></div>
  </div>
</div>

<script>
function toggleDark(){
  const h=document.documentElement,d=h.getAttribute('data-theme')==='dark';
  h.setAttribute('data-theme',d?'light':'dark');
  localStorage.setItem('sibs-theme',d?'light':'dark');
}
(function(){const t=localStorage.getItem('sibs-theme');if(t)document.documentElement.setAttribute('data-theme',t);})();

function validateForm(){
  const n=document.getElementById('fname').value.trim();
  const p=document.getElementById('fphone').value.trim();
  const a=document.getElementById('faddress').value.trim();
  if(!n||!p||!a){ alert('All fields are required.'); return false; }
  if(!/^\d{10,15}$/.test(p)){ alert('Enter a valid phone number (10-15 digits).'); return false; }
  return true;
}
</script>
</body>
</html>
