<%@ page import="java.sql.*,com.sibs.util.DBConnection,com.sibs.model.User" %>
<%
User user = (User)session.getAttribute("customer");
if(user == null){
    response.sendRedirect("customer-login.jsp");
    return;
}
int productId = (int)request.getAttribute("productId");
int qty       = (int)request.getAttribute("qty");

Connection con = null; PreparedStatement ps = null; ResultSet rs = null;
String name=""; double price=0; String img="";
try{
    con = DBConnection.getConnection();
    ps  = con.prepareStatement("SELECT * FROM products WHERE id=?");
    ps.setInt(1, productId); rs = ps.executeQuery();
    if(rs.next()){ name=rs.getString("name"); price=rs.getDouble("price"); img=rs.getString("image_path"); }
} finally {
    if(rs!=null)try{rs.close();}catch(Exception e){}
    if(ps!=null)try{ps.close();}catch(Exception e){}
    if(con!=null)try{con.close();}catch(Exception e){}
}
double subtotal   = price * qty;
double discount   = subtotal * 0.10;
double delivery   = 40;
double finalTotal = subtotal - discount + delivery;
String finalImg   = (img!=null&&!img.trim().isEmpty()) ? request.getContextPath()+"/"+img : request.getContextPath()+"/images/default.png";
%>
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Buy Now — SIBS</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<style>
:root{--bg:#f8fafc;--surface:#fff;--border:#e2e8f0;--text:#0f172a;--muted:#64748b;--primary:#2563eb;--danger:#ef4444;}
[data-theme="dark"]{--bg:#0f172a;--surface:#1e293b;--border:#334155;--text:#f1f5f9;--muted:#94a3b8;}
*{margin:0;padding:0;box-sizing:border-box;font-family:'Inter',sans-serif;}
body{background:var(--bg);color:var(--text);}
.topbar{background:var(--surface);border-bottom:1px solid var(--border);padding:0 20px;height:58px;display:flex;align-items:center;gap:10px;position:sticky;top:0;z-index:50;}
.topbar a{text-decoration:none;color:var(--muted);font-size:13px;display:flex;align-items:center;gap:5px;}
.topbar a:hover{color:var(--primary);}
.topbar .title{font-weight:700;font-size:15px;}
.dark-btn{background:none;border:1px solid var(--border);width:34px;height:34px;border-radius:8px;cursor:pointer;color:var(--muted);margin-left:auto;}
.layout{max-width:900px;margin:28px auto;padding:0 16px;display:grid;grid-template-columns:1fr 320px;gap:20px;}
@media(max-width:700px){.layout{grid-template-columns:1fr;}}
.card{background:var(--surface);border:1px solid var(--border);border-radius:12px;padding:22px;}
.section-title{font-size:15px;font-weight:700;margin-bottom:16px;padding-bottom:10px;border-bottom:1px solid var(--border);}
/* PRODUCT PREVIEW */
.prod-row{display:flex;gap:14px;align-items:center;background:var(--bg);border-radius:10px;padding:12px;margin-bottom:20px;}
.prod-img{width:80px;height:80px;object-fit:contain;border-radius:8px;}
.prod-name{font-weight:600;font-size:14px;}
.prod-meta{font-size:13px;color:var(--muted);margin-top:3px;}
.prod-price{font-size:16px;font-weight:700;color:var(--danger);margin-top:3px;}
/* FORM */
.form-row{display:grid;grid-template-columns:1fr 1fr;gap:12px;margin-bottom:12px;}
@media(max-width:480px){.form-row{grid-template-columns:1fr;}}
.field{margin-bottom:12px;}
.field label{display:block;font-size:12px;font-weight:600;color:var(--muted);margin-bottom:5px;text-transform:uppercase;letter-spacing:.3px;}
.field input,.field select,.field textarea{width:100%;padding:9px 12px;border:1px solid var(--border);border-radius:7px;background:var(--bg);color:var(--text);font-size:13px;outline:none;transition:.15s;}
.field input:focus,.field select:focus,.field textarea:focus{border-color:var(--primary);background:var(--surface);}
.field textarea{resize:vertical;min-height:80px;}
/* SUMMARY */
.summary-row{display:flex;justify-content:space-between;font-size:13px;margin-bottom:8px;}
.summary-row.total{font-weight:700;font-size:16px;padding-top:10px;border-top:1px solid var(--border);margin-top:4px;}
.summary-row.green{color:#16a34a;}
.place-btn{width:100%;padding:12px;background:var(--primary);color:#fff;border:none;border-radius:8px;cursor:pointer;font-weight:600;font-size:14px;margin-top:14px;transition:.15s;}
.place-btn:hover{background:#1d4ed8;}
.secure-note{font-size:11px;color:var(--muted);text-align:center;margin-top:10px;display:flex;align-items:center;justify-content:center;gap:5px;}
</style>
</head>
<body>
<div class="topbar">
  <a href="customer-dashboard.jsp"><i class="fa fa-arrow-left"></i> Shop</a>
  <span style="color:var(--border);">|</span>
  <span class="title">Buy Now</span>
  <button class="dark-btn" onclick="toggleDark()"><i class="fa fa-moon"></i></button>
</div>

<form action="placeOrder" method="post">
<input type="hidden" name="productId" value="<%=productId%>">
<input type="hidden" name="qty"       value="<%=qty%>">
<input type="hidden" name="total"     value="<%=finalTotal%>">

<div class="layout">
  <!-- LEFT: DELIVERY DETAILS -->
  <div class="card">
    <div class="prod-row">
      <img class="prod-img" src="<%=finalImg%>" onerror="this.src='images/default.png'" alt="<%=name%>">
      <div>
        <div class="prod-name"><%=name%></div>
        <div class="prod-meta">Qty: <%=qty%></div>
        <div class="prod-price">₹<%=(int)price%> / unit</div>
      </div>
    </div>

    <div class="section-title">Delivery Details</div>
    <div class="form-row">
      <div class="field" style="margin:0;"><label>Full Name *</label><input type="text" name="name" value="<%=user.getUsername()%>" required></div>
      <div class="field" style="margin:0;"><label>Phone *</label><input type="text" name="phone" value="<%=user.getPhone()!=null?user.getPhone():""%>" required></div>
    </div>
    <div class="form-row">
      <div class="field" style="margin:0;"><label>Email *</label><input type="email" name="email" value="<%=user.getEmail()%>" required></div>
      <div class="field" style="margin:0;"><label>Alternate Phone</label><input type="text" name="altPhone" placeholder="Optional"></div>
    </div>
    <div class="field"><label>Full Address *</label><textarea name="address" required><%=user.getAddress()!=null?user.getAddress():""%></textarea></div>

    <div class="section-title" style="margin-top:4px;">Payment Method</div>
    <div class="field">
      <select name="paymentMethod">
        <option value="COD">Cash on Delivery</option>
        <option value="UPI">UPI</option>
        <option value="Card">Card</option>
      </select>
    </div>
  </div>

  <!-- RIGHT: ORDER SUMMARY -->
  <div>
    <div class="card" style="position:sticky;top:74px;">
      <div class="section-title">Order Summary</div>
      <div class="summary-row"><span><%=name%> × <%=qty%></span><span>₹<%=(int)subtotal%></span></div>
      <div class="summary-row green"><span>Discount (10%)</span><span>−₹<%=(int)discount%></span></div>
      <div class="summary-row"><span>Delivery</span><span>₹<%=(int)delivery%></span></div>
      <div class="summary-row total"><span>Total</span><span>₹<%=(int)finalTotal%></span></div>
      <button type="submit" class="place-btn"><i class="fa fa-lock"></i> Place Order</button>
      <div class="secure-note"><i class="fa fa-shield-halved"></i> Secure checkout</div>
    </div>
  </div>
</div>
</form>

<script>
function toggleDark(){
  const h=document.documentElement,d=h.getAttribute('data-theme')==='dark';
  h.setAttribute('data-theme',d?'light':'dark');
  localStorage.setItem('sibs-theme',d?'light':'dark');
}
(function(){const t=localStorage.getItem('sibs-theme');if(t)document.documentElement.setAttribute('data-theme',t);})();
</script>
</body>
</html>
