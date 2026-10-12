<%@ page import="java.sql.*,com.sibs.util.DBConnection,com.sibs.model.User" %>
<%@ page contentType="text/html;charset=UTF-8" %>
<%
User user = (User)session.getAttribute("customer");
if(user == null){ response.sendRedirect("customer-login.jsp"); return; }

Connection con = null; PreparedStatement ps = null; ResultSet rs = null;
String name="", phone="", address="", payment="", status="Pending";
double total = 0, deliveryCharge = 0;
int orderId = 0, groupId = 0;

try {
    con = DBConnection.getConnection();

    // Step 1: get the latest group_id for this user
    ps = con.prepareStatement(
        "SELECT group_id FROM orders WHERE user_id=? ORDER BY id DESC LIMIT 1");
    ps.setInt(1, user.getId());
    rs = ps.executeQuery();
    if(rs.next()) groupId = rs.getInt("group_id");
    rs.close(); ps.close();

    // Step 2: get group total and details
    ps = con.prepareStatement(
        "SELECT MIN(id) as first_id, name, phone, address, payment_method, status, " +
        "SUM(total) as group_total, MAX(delivery_charge) as delivery_charge " +
        "FROM orders WHERE group_id=? GROUP BY name, phone, address, payment_method, status");
    ps.setInt(1, groupId);
    rs = ps.executeQuery();
    if(rs.next()){
        orderId       = rs.getInt("first_id");
        name          = rs.getString("name");    if(name==null)name="";
        phone         = rs.getString("phone");   if(phone==null)phone="";
        address       = rs.getString("address"); if(address==null)address="";
        payment       = rs.getString("payment_method"); if(payment==null)payment="Cash on Delivery";
        total         = rs.getDouble("group_total");
        deliveryCharge= rs.getDouble("delivery_charge");
        total         = total + deliveryCharge;  // ← add delivery to get true grand total
        status        = rs.getString("status");  if(status==null)status="Pending";
    }
} finally {
    if(rs!=null)try{rs.close();}catch(Exception e){}
    if(ps!=null)try{ps.close();}catch(Exception e){}
    if(con!=null)try{con.close();}catch(Exception e){}
}

double savedAmount = (total - deliveryCharge) / 9.0; // 10% of original subtotal = group_items_total / 9
boolean isApproved = "Confirmed".equals(status)||"Assigned".equals(status)||"Shipped".equals(status)||"Picked".equals(status)||"ORDER_PICKED_UP".equals(status)||"Delivered".equals(status);
boolean isShipped  = "Shipped".equals(status)||"Picked".equals(status)||"ORDER_PICKED_UP".equals(status)||"Delivered".equals(status);
boolean isDelivered= "Delivered".equals(status);
%>
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Order Confirmed — SIBS</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<style>
:root{
  --bg:#f0f4ff;--surface:#fff;--border:#e2e8f5;
  --text:#0d1321;--muted:#64748b;
  --primary:#4361ee;--primary-dark:#3451d6;--primary-light:#eef0fd;
  --success:#16a34a;--success-light:#dcfce7;
  --warn:#f59e0b;--warn-light:#fef9c3;
  --purple:#7c3aed;
}
[data-theme="dark"]{
  --bg:#0b0f1a;--surface:#131929;--border:#1e2a42;
  --text:#e8eeff;--muted:#5a6a8a;
  --primary:#5878f5;--primary-light:#1a2040;
  --success-light:#0a2a14;--warn-light:#1a1300;
}
*{margin:0;padding:0;box-sizing:border-box;font-family:'Inter',sans-serif;}
body{background:var(--bg);color:var(--text);min-height:100vh;}
.topbar{background:var(--surface);border-bottom:1px solid var(--border);
  padding:0 20px;height:56px;display:flex;align-items:center;justify-content:space-between;
  position:sticky;top:0;z-index:50;}
.brand{font-weight:800;font-size:16px;color:var(--primary);display:flex;align-items:center;gap:8px;}
.dark-btn{background:none;border:1px solid var(--border);width:36px;height:36px;
  border-radius:9px;cursor:pointer;color:var(--muted);font-size:14px;
  display:flex;align-items:center;justify-content:center;transition:.15s;}
.dark-btn:hover{border-color:var(--primary);color:var(--primary);}
.page{display:flex;justify-content:center;padding:28px 16px 60px;}
.card{background:var(--surface);border:1.5px solid var(--border);
  border-radius:20px;max-width:520px;width:100%;
  box-shadow:0 8px 40px rgba(67,97,238,.1);overflow:hidden;}
.success-hdr{
  background:linear-gradient(135deg,#1a237e 0%,#4361ee 55%,#7c3aed 100%);
  padding:36px 28px;text-align:center;position:relative;overflow:hidden;}
.success-hdr::before{content:'';position:absolute;inset:0;
  background:radial-gradient(circle at 80% 20%,rgba(255,255,255,.1) 0%,transparent 60%);}
.check-wrap{width:80px;height:80px;margin:0 auto 16px;position:relative;}
.check-circle{width:80px;height:80px;border-radius:50%;
  background:rgba(255,255,255,.15);border:2px solid rgba(255,255,255,.4);
  display:flex;align-items:center;justify-content:center;
  animation:popIn .5s cubic-bezier(.34,1.56,.64,1);}
@keyframes popIn{0%{transform:scale(0);opacity:0;}60%{transform:scale(1.12);}100%{transform:scale(1);opacity:1;}}
.check-circle i{font-size:34px;color:#fff;}
.check-ring{position:absolute;inset:-6px;border-radius:50%;
  border:3px solid rgba(255,255,255,.3);animation:ringPulse 2s ease infinite;}
@keyframes ringPulse{0%,100%{transform:scale(1);opacity:.7;}50%{transform:scale(1.08);opacity:.3;}}
.success-hdr h2{font-size:22px;font-weight:800;color:#fff;margin-bottom:6px;position:relative;}
.success-hdr p{font-size:13px;color:rgba(255,255,255,.75);position:relative;}
.order-pill{display:inline-flex;align-items:center;gap:8px;margin-top:14px;
  background:rgba(255,255,255,.15);border:1px solid rgba(255,255,255,.3);
  border-radius:99px;padding:7px 18px;font-size:13px;font-weight:700;
  color:#fff;letter-spacing:.3px;position:relative;}
.status-bar{background:var(--warn-light);padding:12px 20px;
  display:flex;align-items:center;justify-content:center;gap:10px;
  border-bottom:1px solid var(--border);}
.status-dot{width:9px;height:9px;border-radius:50%;background:var(--warn);
  animation:blink 1.4s ease infinite;}
@keyframes blink{0%,100%{opacity:1;}50%{opacity:.3;}}
.status-text{font-size:13px;font-weight:700;color:#92400e;}
[data-theme="dark"] .status-text{color:#fcd34d;}
.tl-section{padding:22px 24px;border-bottom:1px solid var(--border);}
.sec-label{font-size:11px;font-weight:700;color:var(--muted);text-transform:uppercase;
  letter-spacing:.6px;margin-bottom:18px;display:flex;align-items:center;gap:7px;}
.timeline{display:flex;position:relative;}
.timeline::before{content:'';position:absolute;top:20px;left:20px;right:20px;
  height:2px;background:var(--border);z-index:0;}
.tl-progress{position:absolute;top:20px;left:20px;height:2px;
  background:linear-gradient(90deg,var(--success),var(--primary));
  z-index:0;transition:width .5s ease;}
.tl-step{flex:1;display:flex;flex-direction:column;align-items:center;z-index:1;}
.tl-node{width:40px;height:40px;border-radius:50%;
  border:2.5px solid var(--border);background:var(--surface);
  display:flex;align-items:center;justify-content:center;
  font-size:14px;margin-bottom:7px;transition:.3s;}
.tl-node.done{border-color:var(--success);background:var(--success);color:#fff;}
.tl-node.cur{border-color:var(--primary);background:var(--primary);color:#fff;
  box-shadow:0 0 0 5px var(--primary-light);animation:curPulse 2s ease infinite;}
@keyframes curPulse{0%,100%{box-shadow:0 0 0 5px var(--primary-light);}50%{box-shadow:0 0 0 9px transparent;}}
.tl-label{font-size:10px;font-weight:700;color:var(--muted);text-align:center;}
.tl-label.done-l{color:var(--success);}
.tl-label.cur-l{color:var(--primary);}
.details-section{padding:20px 24px;border-bottom:1px solid var(--border);}
.detail-list{border:1.5px solid var(--border);border-radius:12px;overflow:hidden;}
.detail-item{display:flex;align-items:center;gap:14px;
  padding:13px 16px;border-bottom:1px solid var(--border);}
.detail-item:last-child{border-bottom:none;}
.di-icon{width:34px;height:34px;border-radius:9px;
  background:var(--primary-light);color:var(--primary);
  display:flex;align-items:center;justify-content:center;
  font-size:13px;flex-shrink:0;}
.di-label{font-size:11px;color:var(--muted);font-weight:500;margin-bottom:2px;}
.di-value{font-size:14px;font-weight:600;}
.total-box{margin:20px 24px 0;
  background:linear-gradient(135deg,#1a237e,#4361ee,#7c3aed);
  border-radius:14px;padding:18px 22px;
  display:flex;justify-content:space-between;align-items:center;}
.total-left-label{font-size:11px;font-weight:600;color:rgba(255,255,255,.7);
  text-transform:uppercase;letter-spacing:.5px;margin-bottom:4px;}
.total-amount{font-size:32px;font-weight:800;color:#fff;letter-spacing:-.5px;}
.total-amount span{font-size:18px;}
.paid-badge{background:rgba(255,255,255,.18);border:1px solid rgba(255,255,255,.3);
  border-radius:99px;padding:6px 14px;font-size:11px;font-weight:700;color:#fff;
  display:flex;align-items:center;gap:6px;}
.savings-bar{margin:12px 24px;background:var(--success-light);
  border-radius:10px;padding:11px 16px;
  display:flex;align-items:center;gap:9px;
  font-size:13px;font-weight:600;color:var(--success);}
[data-theme="dark"] .savings-bar{color:#4ade80;}
.actions{padding:20px 24px;}
.btn-track{width:100%;padding:13px;background:var(--primary);color:#fff;
  border:none;border-radius:11px;cursor:pointer;font-weight:700;
  font-size:14px;display:flex;align-items:center;justify-content:center;gap:9px;
  text-decoration:none;transition:.2s;margin-bottom:10px;}
.btn-track:hover{background:var(--primary-dark);transform:translateY(-1px);box-shadow:0 6px 20px rgba(67,97,238,.3);}
.btn-row{display:flex;gap:10px;}
.btn-outline{flex:1;padding:12px;background:none;
  border:1.5px solid var(--border);border-radius:11px;
  cursor:pointer;font-weight:600;font-size:13px;color:var(--text);
  display:flex;align-items:center;justify-content:center;gap:7px;
  text-decoration:none;transition:.15s;}
.btn-outline:hover{border-color:var(--primary);color:var(--primary);background:var(--primary-light);}
.confetti-wrap{position:fixed;inset:0;pointer-events:none;z-index:999;}
.cp{position:absolute;animation:fall linear forwards;}
@keyframes fall{0%{transform:translateY(-20px) rotate(0);opacity:1;}100%{transform:translateY(105vh) rotate(720deg);opacity:0;}}
@media print{.topbar,.actions,.dark-btn,.confetti-wrap{display:none!important;}}
</style>
</head>
<body>

<div class="confetti-wrap" id="confetti"></div>

<div class="topbar">
  <div class="brand"><i class="fa fa-cubes"></i> SIBS</div>
  <button class="dark-btn" onclick="toggleDark()"><i class="fa fa-moon"></i></button>
</div>

<div class="page">
<div class="card">

  <div class="success-hdr">
    <div class="check-wrap">
      <div class="check-circle"><i class="fa fa-check"></i></div>
      <div class="check-ring"></div>
    </div>
    <h2>Order Placed Successfully!</h2>
    <p>Thank you! Your order is confirmed and being processed.</p>
    <div class="order-pill"><i class="fa fa-hashtag"></i> Group #<%=groupId%></div>
  </div>

  <div class="status-bar">
    <div class="status-dot"></div>
    <div class="status-text">Current Status: <%=status%></div>
  </div>

  <div class="tl-section">
    <div class="sec-label"><i class="fa fa-route"></i> Order Progress</div>
    <div class="timeline">
      <%
      int pct = 0;
      if("Confirmed".equals(status))       pct=25;
      else if("Assigned".equals(status))   pct=50;
      else if("Shipped".equals(status)||"Picked".equals(status)||"ORDER_PICKED_UP".equals(status)) pct=75;
      else if("Delivered".equals(status))  pct=100;
      %>
      <div class="tl-progress" style="width:<%=pct%>%;"></div>

      <div class="tl-step">
        <div class="tl-node done"><i class="fa fa-check"></i></div>
        <div class="tl-label done-l">Placed</div>
      </div>
      <div class="tl-step">
        <div class="tl-node <%=isApproved?"done":"cur"%>">
          <i class="fa <%=isApproved?"fa-check":"fa-clock"%>"></i>
        </div>
        <div class="tl-label <%=isApproved?"done-l":"cur-l"%>">Confirmed</div>
      </div>
      <div class="tl-step">
        <div class="tl-node <%=isShipped?"done":isApproved&&!isShipped?"cur":""%>">
          <i class="fa <%=isShipped?"fa-check":"fa-truck"%>"></i>
        </div>
        <div class="tl-label <%=isShipped?"done-l":isApproved&&!isShipped?"cur-l":""%>">Shipped</div>
      </div>
      <div class="tl-step">
        <div class="tl-node <%=isDelivered?"done":isShipped&&!isDelivered?"cur":""%>">
          <i class="fa <%=isDelivered?"fa-check":"fa-house"%>"></i>
        </div>
        <div class="tl-label <%=isDelivered?"done-l":isShipped&&!isDelivered?"cur-l":""%>">Delivered</div>
      </div>
    </div>
  </div>

  <div class="details-section">
    <div class="sec-label"><i class="fa fa-clipboard-list"></i> Order Details</div>
    <div class="detail-list">
      <div class="detail-item">
        <div class="di-icon"><i class="fa fa-hashtag"></i></div>
        <div><div class="di-label">Order ID</div><div class="di-value">#<%=orderId%></div></div>
      </div>
      <div class="detail-item">
        <div class="di-icon"><i class="fa fa-user"></i></div>
        <div><div class="di-label">Name</div><div class="di-value"><%=name%></div></div>
      </div>
      <div class="detail-item">
        <div class="di-icon"><i class="fa fa-phone"></i></div>
        <div><div class="di-label">Phone</div><div class="di-value"><%=phone%></div></div>
      </div>
      <div class="detail-item">
        <div class="di-icon"><i class="fa fa-location-dot"></i></div>
        <div><div class="di-label">Delivery Address</div><div class="di-value"><%=address%></div></div>
      </div>
      <div class="detail-item">
        <div class="di-icon"><i class="fa fa-credit-card"></i></div>
        <div><div class="di-label">Payment Method</div><div class="di-value"><%=payment%></div></div>
      </div>
    </div>
  </div>

  <div class="total-box">
    <div>
      <div class="total-left-label">Total Paid</div>
      <div class="total-amount"><span>₹</span><%=(int)total%></div>
    </div>
    <div class="paid-badge"><i class="fa fa-shield-halved"></i> Secured</div>
  </div>

  <div class="savings-bar">
    <i class="fa fa-tag"></i>
    You saved <strong>&nbsp;₹<%=(int)savedAmount%>&nbsp;</strong> with your 10% discount on this order!
  </div>

  <div class="actions">
    <a class="btn-track" href="my-orders.jsp">
      <i class="fa fa-box-open"></i> Track My Order
    </a>
    <div class="btn-row">
      <button class="btn-outline" onclick="window.print()">
        <i class="fa fa-print"></i> Print
      </button>
      <a class="btn-outline" href="customer-dashboard.jsp">
        <i class="fa fa-store"></i> Shop More
      </a>
    </div>
  </div>

</div>
</div>

<script>
function toggleDark(){
  const h=document.documentElement,d=h.getAttribute('data-theme')==='dark';
  h.setAttribute('data-theme',d?'light':'dark');
  localStorage.setItem('sibs-theme',d?'light':'dark');
}
(function(){const t=localStorage.getItem('sibs-theme');if(t)document.documentElement.setAttribute('data-theme',t);})();

(function(){
  const colors=['#4361ee','#7c3aed','#22c55e','#f59e0b','#ef4444','#06b6d4','#ec4899','#f97316'];
  const wrap=document.getElementById('confetti');
  for(let i=0;i<70;i++){
    const el=document.createElement('div');
    el.className='cp';
    const size=Math.random()*10+5;
    const isCircle=Math.random()>.5;
    el.style.cssText=`
      left:${Math.random()*100}%;
      width:${size}px;height:${size}px;
      background:${colors[Math.floor(Math.random()*colors.length)]};
      border-radius:${isCircle?'50%':'2px'};
      animation-duration:${Math.random()*2+2}s;
      animation-delay:${Math.random()*1}s;
    `;
    wrap.appendChild(el);
  }
  setTimeout(()=>wrap.remove(),5000);
})();
</script>
</body>
</html>