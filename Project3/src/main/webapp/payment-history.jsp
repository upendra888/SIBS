<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.util.*, com.sibs.model.Payment, com.sibs.model.User" %>
<%
User user = (User)session.getAttribute("customer");
if(user == null){ response.sendRedirect("customer-login.jsp"); return; }
List<Payment> payments = (List<Payment>)request.getAttribute("payments");
if(payments == null) payments = new java.util.ArrayList<>();
%>
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Payment History — SIBS</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<style>
:root{--bg:#f8fafc;--surface:#fff;--border:#e2e8f0;--text:#0f172a;--muted:#64748b;--primary:#2563eb;}
[data-theme="dark"]{--bg:#0f172a;--surface:#1e293b;--border:#334155;--text:#f1f5f9;--muted:#94a3b8;}
*{margin:0;padding:0;box-sizing:border-box;font-family:'Inter',sans-serif;}
body{background:var(--bg);color:var(--text);}
.topbar{background:var(--surface);border-bottom:1px solid var(--border);padding:0 20px;height:58px;display:flex;align-items:center;gap:10px;position:sticky;top:0;z-index:50;}
.topbar a{text-decoration:none;color:var(--muted);font-size:13px;display:flex;align-items:center;gap:5px;}
.topbar a:hover{color:var(--primary);}
.title{font-weight:700;font-size:15px;}
.dark-btn{background:none;border:1px solid var(--border);width:34px;height:34px;border-radius:8px;cursor:pointer;color:var(--muted);margin-left:auto;}
.content{max-width:860px;margin:28px auto;padding:0 16px;}
.page-head{margin-bottom:20px;}
.page-head h2{font-size:18px;font-weight:700;}
.page-head p{font-size:13px;color:var(--muted);}
/* FILTER */
.filter-row{display:flex;gap:8px;margin-bottom:16px;flex-wrap:wrap;}
.filter-btn{padding:5px 12px;border:1px solid var(--border);border-radius:999px;background:none;cursor:pointer;font-size:12px;font-weight:500;color:var(--muted);}
.filter-btn.active{border-color:var(--primary);color:var(--primary);background:#eff6ff;}
/* TABLE */
.table-wrap{background:var(--surface);border:1px solid var(--border);border-radius:12px;overflow:hidden;}
table{width:100%;border-collapse:collapse;}
th{padding:12px 16px;text-align:left;font-size:11px;font-weight:600;color:var(--muted);text-transform:uppercase;letter-spacing:.4px;background:var(--bg);border-bottom:1px solid var(--border);}
td{padding:13px 16px;font-size:13px;border-bottom:1px solid var(--border);vertical-align:middle;}
tbody tr:last-child td{border-bottom:none;}
tbody tr:hover{background:var(--bg);}
.badge{padding:3px 10px;border-radius:999px;font-size:11px;font-weight:600;color:#fff;}
.SUCCESS {background:#16a34a;} .FAILED{background:#ef4444;}
.PENDING{background:#f59e0b;} .REFUNDED{background:#6366f1;}
.tx-id{font-size:11px;color:var(--muted);font-family:monospace;}
.empty{text-align:center;padding:50px;color:var(--muted);}
.empty i{font-size:36px;margin-bottom:10px;}
/* Dispute button */
.dispute-btn{font-size:11px;padding:3px 10px;border-radius:999px;border:1px solid #ef4444;
  color:#ef4444;background:none;cursor:pointer;white-space:nowrap;}
.dispute-btn:hover{background:#fef2f2;}
/* Info banner */
.info-banner{background:#eff6ff;border:1px solid #bfdbfe;border-radius:10px;
  padding:11px 16px;font-size:12px;color:#1e40af;margin-bottom:16px;display:flex;gap:10px;align-items:flex-start;}
</style>
</head>
<body>
<div class="topbar">
  <a href="customer-dashboard.jsp"><i class="fa fa-arrow-left"></i> Shop</a>
  <span style="color:var(--border);">|</span>
  <span class="title">Payment History</span>
  <button class="dark-btn" onclick="toggleDark()"><i class="fa fa-moon"></i></button>
</div>
<div class="content">
  <div class="page-head">
    <h2>Payment History</h2>
    <p>All your transactions in one place.</p>
  </div>

  <!-- Billing info banner -->
  <div class="info-banner">
    <i class="fa fa-circle-info" style="margin-top:1px;flex-shrink:0"></i>
    <span>
      See an incorrect charge? Click <strong>Dispute</strong> on that row to report it to our support team.
      Refunds for overcharges or duplicate payments are processed within <strong>3–5 business days</strong>.
      For coupon/discount issues, please mention the promo code when contacting support.
    </span>
  </div>

  <div class="filter-row">
    <button class="filter-btn active" onclick="filterPay('ALL',this)">All</button>
    <button class="filter-btn" onclick="filterPay('SUCCESS',this)">Success</button>
    <button class="filter-btn" onclick="filterPay('PENDING',this)">Pending</button>
    <button class="filter-btn" onclick="filterPay('FAILED',this)">Failed</button>
    <button class="filter-btn" onclick="filterPay('REFUNDED',this)">Refunded</button>
  </div>

  <div class="table-wrap">
    <% if(payments.isEmpty()){ %>
    <div class="empty"><i class="fa fa-credit-card"></i><p>No payments yet.</p></div>
    <% } else { %>
    <table>
      <thead>
        <tr>
          <th>Payment #</th>
          <th>Order #</th>
          <th>Amount</th>
          <th>Method</th>
          <th>Transaction ID</th>
          <th>Date</th>
          <th>Status</th>
          <th>Action</th>
        </tr>
      </thead>
      <tbody id="payTable">
      <% for(Payment p : payments){ %>
      <tr data-status="<%=p.getStatus()%>">
        <td><b>#<%=p.getPaymentId()%></b></td>
        <td>#<%=p.getOrderId()%></td>
        <td><b>₹<%=String.format("%.2f",p.getAmount())%></b></td>
        <td><%=p.getPaymentMethod()%></td>
        <td class="tx-id"><%=p.getRazorpayPaymentId()!=null?p.getRazorpayPaymentId():"—"%></td>
        <td style="font-size:12px;color:var(--muted);"><%=p.getPaymentDate()!=null?p.getPaymentDate().toString().substring(0,16):"—"%></td>
        <td><span class="badge <%=p.getStatus()%>"><%=p.getStatus()%></span></td>
        <td>
          <% if(!"REFUNDED".equals(p.getStatus())){ %>
          <button class="dispute-btn"
            onclick="disputePayment('<%=p.getPaymentId()%>','<%=p.getOrderId()%>','<%=String.format("%.2f",p.getAmount())%>')">
            <i class="fa fa-flag"></i> Dispute
          </button>
          <% } else { %>
          <span style="font-size:11px;color:#16a34a;">✓ Refunded</span>
          <% } %>
        </td>
      </tr>
      <% } %>
      </tbody>
    </table>
    <% } %>
  </div>
</div>
<script>
function toggleDark(){const h=document.documentElement,d=h.getAttribute('data-theme')==='dark';h.setAttribute('data-theme',d?'light':'dark');localStorage.setItem('sibs-theme',d?'light':'dark');}
(function(){const t=localStorage.getItem('sibs-theme');if(t)document.documentElement.setAttribute('data-theme',t);})();
function filterPay(status,btn){
  document.querySelectorAll('.filter-btn').forEach(b=>b.classList.remove('active'));
  btn.classList.add('active');
  document.querySelectorAll('#payTable tr').forEach(r=>{
    r.style.display=(status==='ALL'||r.getAttribute('data-status')===status)?'':'none';
  });
}
function disputePayment(payId, orderId, amount) {
  const issue = prompt(
    'Dispute Payment #' + payId + ' (Order #' + orderId + ', ₹' + amount + ')\n\n' +
    'Please describe the issue:\n' +
    '• Overcharged\n• Duplicate charge\n• Coupon/discount not applied\n• Other\n\n' +
    'Type your reason below:'
  );
  if (!issue || !issue.trim()) return;
  const msg = encodeURIComponent(
    'Billing Dispute — Payment #' + payId + ', Order #' + orderId +
    ', Amount ₹' + amount + '. Issue: ' + issue.trim()
  );
  alert('Please contact support directly. Support chat coming soon.');
}
</script>
</body>
</html>
