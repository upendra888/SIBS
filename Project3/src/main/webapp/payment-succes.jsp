<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="com.sibs.model.User" %>
<%@ page import="java.sql.*,com.sibs.util.DBConnection" %>
<%
User user = (User)session.getAttribute("customer");
if(user == null){ response.sendRedirect("customer-login.jsp"); return; }

Object txObj  = session.getAttribute("lastTransactionId");
Object pidObj = session.getAttribute("lastPaymentId");
Object oidObj = session.getAttribute("lastOrderId");

String transactionId = (txObj  != null) ? txObj.toString()  : "N/A";
String paymentId     = (pidObj != null) ? pidObj.toString() : "N/A";
String orderId       = (oidObj != null) ? oidObj.toString() : "N/A";
boolean isDuplicate  = "1".equals(request.getParameter("duplicate"));

// Fetch order details for display
double orderTotal = 0;
String orderAddress = "", orderPhone = "", orderName = "";
try {
    if(oidObj != null){
        Connection con2 = DBConnection.getConnection();
        // Sum all items in the group + delivery charge for correct total
        PreparedStatement ps2 = con2.prepareStatement(
            "SELECT o.name, o.phone, o.address, " +
            "       SUM(o.total) + MAX(COALESCE(o.delivery_charge,0)) AS grand_total " +
            "FROM orders o WHERE o.group_id = " +
            "  (SELECT group_id FROM orders WHERE id=? LIMIT 1) " +
            "GROUP BY o.name, o.phone, o.address LIMIT 1");
        ps2.setInt(1, Integer.parseInt(oidObj.toString()));
        ResultSet rs2 = ps2.executeQuery();
        if(rs2.next()){
            orderName    = rs2.getString("name");       if(orderName==null) orderName="";
            orderPhone   = rs2.getString("phone");      if(orderPhone==null) orderPhone="";
            orderAddress = rs2.getString("address");    if(orderAddress==null) orderAddress="";
            orderTotal   = rs2.getDouble("grand_total");
        }
        rs2.close(); ps2.close(); con2.close();
    }
} catch(Exception ignore){ ignore.printStackTrace(); }

// Clear success session attrs after reading
session.removeAttribute("lastPaymentId");
session.removeAttribute("lastTransactionId");
session.removeAttribute("lastOrderId");
session.removeAttribute("orderName");
session.removeAttribute("orderPhone");
session.removeAttribute("orderAddress");
session.removeAttribute("orderPayment");
session.removeAttribute("orderTotal");
%>
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Payment Successful — SIBS</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<style>
:root{--bg:#f0f4ff;--surface:#fff;--border:#e2e8f5;--text:#0d1321;--muted:#64748b;
  --primary:#4361ee;--primary-dark:#3451d6;--primary-light:#eef0fd;
  --success:#16a34a;--success-light:#dcfce7;}
[data-theme="dark"]{--bg:#0b0f1a;--surface:#131929;--border:#1e2a42;--text:#e8eeff;
  --muted:#5a6a8a;--primary:#5878f5;--primary-light:#1a2040;--success-light:#0a2a14;}
*{margin:0;padding:0;box-sizing:border-box;font-family:'Inter',sans-serif;}
body{background:var(--bg);color:var(--text);min-height:100vh;}
.topbar{background:var(--surface);border-bottom:1px solid var(--border);padding:0 20px;
  height:56px;display:flex;align-items:center;justify-content:space-between;
  position:sticky;top:0;z-index:50;}
.brand{font-weight:800;font-size:16px;color:var(--primary);display:flex;align-items:center;gap:8px;}
.dark-btn{background:none;border:1px solid var(--border);width:36px;height:36px;
  border-radius:9px;cursor:pointer;color:var(--muted);font-size:14px;
  display:flex;align-items:center;justify-content:center;}
.page{display:flex;justify-content:center;padding:32px 16px 60px;}
.card{background:var(--surface);border:1.5px solid var(--border);border-radius:20px;
  max-width:480px;width:100%;box-shadow:0 8px 40px rgba(67,97,238,.1);overflow:hidden;}

/* Header */
.success-hdr{background:linear-gradient(135deg,#1a237e 0%,#4361ee 55%,#16a34a 100%);
  padding:36px 28px;text-align:center;position:relative;overflow:hidden;}
.success-hdr::before{content:'';position:absolute;inset:0;
  background:radial-gradient(circle at 80% 20%,rgba(255,255,255,.1) 0%,transparent 60%);}
.check-wrap{width:80px;height:80px;margin:0 auto 16px;position:relative;}
.check-circle{width:80px;height:80px;border-radius:50%;background:rgba(255,255,255,.2);
  border:2px solid rgba(255,255,255,.5);display:flex;align-items:center;justify-content:center;
  animation:popIn .5s cubic-bezier(.34,1.56,.64,1);}
@keyframes popIn{0%{transform:scale(0);opacity:0;}60%{transform:scale(1.12);}100%{transform:scale(1);opacity:1;}}
.check-circle i{font-size:34px;color:#fff;}
.check-ring{position:absolute;inset:-6px;border-radius:50%;border:3px solid rgba(255,255,255,.3);
  animation:ringPulse 2s ease infinite;}
@keyframes ringPulse{0%,100%{transform:scale(1);opacity:.7;}50%{transform:scale(1.08);opacity:.3;}}
.success-hdr h2{font-size:22px;font-weight:800;color:#fff;margin-bottom:6px;position:relative;}
.success-hdr p{font-size:13px;color:rgba(255,255,255,.8);position:relative;}
.paid-pill{display:inline-flex;align-items:center;gap:8px;margin-top:14px;
  background:rgba(255,255,255,.2);border:1px solid rgba(255,255,255,.4);
  border-radius:99px;padding:7px 18px;font-size:13px;font-weight:700;
  color:#fff;letter-spacing:.3px;position:relative;}

/* Body */
.body-pad{padding:24px;}
.dup-note{background:#fef9c3;border:1px solid #fbbf24;border-radius:8px;padding:10px 14px;
  font-size:12px;color:#92400e;margin-bottom:14px;display:flex;align-items:center;gap:8px;}
.tx-box{background:var(--bg);border:1.5px solid var(--border);border-radius:12px;
  overflow:hidden;margin-bottom:18px;}
.tx-row{display:flex;justify-content:space-between;align-items:center;padding:11px 16px;
  border-bottom:1px solid var(--border);font-size:13px;}
.tx-row:last-child{border-bottom:none;}
.tx-label{color:var(--muted);font-weight:500;}
.tx-value{font-weight:700;max-width:240px;text-align:right;word-break:break-all;font-size:12px;}
.tx-value.green{color:var(--success);}
.total-stripe{background:linear-gradient(135deg,#1a237e,#4361ee);border-radius:12px;
  padding:16px 20px;display:flex;justify-content:space-between;align-items:center;margin-bottom:16px;}
.total-label{font-size:11px;color:rgba(255,255,255,.7);text-transform:uppercase;letter-spacing:.5px;margin-bottom:4px;}
.total-amount{font-size:28px;font-weight:800;color:#fff;}
.actions{display:flex;flex-direction:column;gap:10px;}
.btn{padding:12px;border-radius:10px;cursor:pointer;font-weight:700;font-size:13px;
  display:flex;align-items:center;justify-content:center;gap:8px;text-decoration:none;
  border:none;transition:.15s;}
.btn-primary{background:var(--primary);color:#fff;}
.btn-primary:hover{background:var(--primary-dark);}
.btn-outline{background:none;border:1.5px solid var(--border);color:var(--text);}
.btn-outline:hover{border-color:var(--primary);color:var(--primary);background:var(--primary-light);}
/* Confetti */
.confetti-wrap{position:fixed;inset:0;pointer-events:none;z-index:999;}
.cp{position:absolute;animation:fall linear forwards;}
@keyframes fall{0%{transform:translateY(-20px) rotate(0);opacity:1;}100%{transform:translateY(105vh) rotate(720deg);opacity:0;}}
@media print{.topbar,.actions,.dark-btn,.confetti-wrap{display:none!important;}.card{box-shadow:none;border:none;}}
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

  <!-- Header -->
  <div class="success-hdr">
    <div class="check-wrap">
      <div class="check-circle"><i class="fa fa-check"></i></div>
      <div class="check-ring"></div>
    </div>
    <h2>Payment Successful! 🎉</h2>
    <p>Your order is confirmed and will be delivered soon.</p>
    <div class="paid-pill"><i class="fa fa-circle-check"></i> PAID &amp; CONFIRMED</div>
  </div>

  <div class="body-pad">
    <% if(isDuplicate){ %>
    <div class="dup-note"><i class="fa fa-info-circle"></i> This payment was already processed. Your order is confirmed.</div>
    <% } %>

    <!-- Transaction Details -->
    <div class="tx-box">
      <div class="tx-row"><span class="tx-label"><i class="fa fa-hashtag"></i> Order ID</span><span class="tx-value">#<%=orderId%></span></div>
      <div class="tx-row"><span class="tx-label"><i class="fa fa-id-card"></i> Payment ID</span><span class="tx-value">#<%=paymentId%></span></div>
      <div class="tx-row"><span class="tx-label"><i class="fa fa-fingerprint"></i> Transaction ID</span><span class="tx-value" style="font-size:11px;"><%=transactionId%></span></div>
      <div class="tx-row"><span class="tx-label"><i class="fa fa-user"></i> Customer</span><span class="tx-value"><%=user.getUsername()%></span></div>
      <% if(!orderName.isEmpty()){ %>
      <div class="tx-row"><span class="tx-label"><i class="fa fa-location-dot"></i> Deliver To</span><span class="tx-value"><%=orderName%>, <%=orderPhone%></span></div>
      <% } %>
      <div class="tx-row"><span class="tx-label"><i class="fa fa-circle-check"></i> Status</span><span class="tx-value green">CONFIRMED ✔</span></div>
    </div>

    <% if(orderTotal > 0){ %>
    <div class="total-stripe">
      <div><div class="total-label">Amount Paid</div><div class="total-amount">₹<%=(int)orderTotal%></div></div>
      <div style="background:rgba(255,255,255,.2);border-radius:99px;padding:6px 14px;font-size:11px;font-weight:700;color:#fff;">
        <i class="fa fa-shield-halved"></i> Secured
      </div>
    </div>
    <% } %>

    <div class="actions">
      <a class="btn btn-primary" href="my-orders.jsp"><i class="fa fa-box-open"></i> Track My Order</a>
      <a class="btn btn-outline" href="paymentHistory"><i class="fa fa-clock-rotate-left"></i> Payment History</a>
      <button class="btn btn-outline" onclick="window.print()"><i class="fa fa-print"></i> Print Receipt</button>
      <a class="btn btn-outline" href="customer-dashboard.jsp"><i class="fa fa-shop"></i> Continue Shopping</a>
    </div>
  </div>

</div>
</div>

<script>
function toggleDark(){const h=document.documentElement,d=h.getAttribute('data-theme')==='dark';h.setAttribute('data-theme',d?'light':'dark');localStorage.setItem('sibs-theme',d?'light':'dark');}
(function(){const t=localStorage.getItem('sibs-theme');if(t)document.documentElement.setAttribute('data-theme',t);})();

// Confetti
(function(){
  const colors=['#4361ee','#16a34a','#f59e0b','#ef4444','#06b6d4','#ec4899'];
  const wrap=document.getElementById('confetti');
  for(let i=0;i<60;i++){
    const el=document.createElement('div');
    el.className='cp';
    const size=Math.random()*10+5;
    el.style.cssText=`left:${Math.random()*100}%;width:${size}px;height:${size}px;
      background:${colors[Math.floor(Math.random()*colors.length)]};
      border-radius:${Math.random()>.5?'50%':'2px'};
      animation-duration:${Math.random()*2+2}s;animation-delay:${Math.random()}s;`;
    wrap.appendChild(el);
  }
  setTimeout(()=>wrap.remove(),5000);
})();
</script>
</body>
</html>
