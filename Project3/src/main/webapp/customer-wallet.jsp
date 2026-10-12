<%@ page language="java" contentType="text/html; charset=UTF-8" %>
<%@ page import="java.util.*, com.sibs.dao.CustomerWalletDAO, com.sibs.model.User" %>
<%
User user = (User)session.getAttribute("customer");
if(user == null){ response.sendRedirect("customer-login.jsp"); return; }

CustomerWalletDAO walletDAO = new CustomerWalletDAO();
double balance = walletDAO.getBalance(user.getId());
List<String[]> transactions = walletDAO.getTransactions(user.getId());
%>
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>My Wallet — SIBS</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<style>
:root{--bg:#f8fafc;--surface:#fff;--border:#e2e8f0;--text:#0f172a;--muted:#64748b;--primary:#2563eb;--success:#16a34a;--danger:#ef4444;}
[data-theme="dark"]{--bg:#0f172a;--surface:#1e293b;--border:#334155;--text:#f1f5f9;--muted:#94a3b8;}
*{margin:0;padding:0;box-sizing:border-box;font-family:'Inter',sans-serif;}
body{background:var(--bg);color:var(--text);min-height:100vh;}
.topbar{background:var(--surface);border-bottom:1px solid var(--border);padding:0 20px;height:58px;display:flex;align-items:center;gap:12px;position:sticky;top:0;z-index:100;box-shadow:0 1px 4px rgba(0,0,0,.07);}
.topbar .back{display:flex;align-items:center;gap:8px;color:var(--text);text-decoration:none;font-weight:600;font-size:14px;}
.topbar .back:hover{color:var(--primary);}
.topbar h1{font-size:16px;font-weight:700;margin-left:4px;}
.dark-btn{background:none;border:1px solid var(--border);width:34px;height:34px;border-radius:8px;cursor:pointer;color:var(--muted);margin-left:auto;}
.container{max-width:600px;margin:0 auto;padding:24px 20px;}

/* Balance card */
.balance-card{background:linear-gradient(135deg,#1e3a8a,#2563eb);color:#fff;border-radius:16px;padding:28px 24px;margin-bottom:24px;position:relative;overflow:hidden;}
.balance-card::before{content:'';position:absolute;top:-40px;right:-40px;width:160px;height:160px;background:rgba(255,255,255,.08);border-radius:50%;}
.balance-label{font-size:13px;opacity:.8;margin-bottom:8px;display:flex;align-items:center;gap:6px;}
.balance-amount{font-size:38px;font-weight:700;letter-spacing:-1px;}
.balance-sub{font-size:12px;opacity:.7;margin-top:6px;}

/* Info box */
.info-box{background:var(--surface);border:1px solid var(--border);border-radius:12px;padding:16px;margin-bottom:24px;display:flex;gap:12px;align-items:flex-start;}
.info-box i{color:#f59e0b;font-size:18px;margin-top:2px;flex-shrink:0;}
.info-box p{font-size:13px;line-height:1.6;color:var(--muted);}

/* Section */
.section-title{font-size:14px;font-weight:700;margin-bottom:12px;display:flex;align-items:center;gap:6px;}
.txn-list{display:flex;flex-direction:column;gap:8px;}
.txn-item{background:var(--surface);border:1px solid var(--border);border-radius:10px;padding:14px 16px;display:flex;align-items:center;gap:12px;}
.txn-icon{width:36px;height:36px;border-radius:50%;display:flex;align-items:center;justify-content:center;flex-shrink:0;font-size:14px;}
.txn-icon.CREDIT{background:#dcfce7;color:#16a34a;}
.txn-icon.DEBIT{background:#fee2e2;color:#ef4444;}
.txn-body{flex:1;min-width:0;}
.txn-reason{font-size:13px;font-weight:500;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;}
.txn-date{font-size:11px;color:var(--muted);margin-top:2px;}
.txn-amount{font-size:15px;font-weight:700;}
.txn-amount.CREDIT{color:var(--success);}
.txn-amount.DEBIT{color:var(--danger);}
.empty-txn{text-align:center;padding:40px 20px;color:var(--muted);font-size:13px;}
.empty-txn i{font-size:30px;display:block;margin-bottom:10px;opacity:.4;}
</style>
</head>
<body>
<div class="topbar">
  <a class="back" href="customer-dashboard.jsp"><i class="fa fa-arrow-left"></i></a>
  <h1><i class="fa fa-wallet" style="color:var(--primary);margin-right:6px;"></i>My Wallet</h1>
  <button class="dark-btn" onclick="toggleDark()" title="Toggle dark mode"><i class="fa fa-moon"></i></button>
</div>

<div class="container">

  <!-- Balance Card -->
  <div class="balance-card">
    <div class="balance-label"><i class="fa fa-wallet"></i> Store Credit Balance</div>
    <div class="balance-amount">₹<%= String.format("%.2f", balance) %></div>
    <div class="balance-sub">Available to use at checkout</div>
  </div>

  <!-- Info -->
  <div class="info-box">
    <i class="fa fa-circle-info"></i>
    <p>Your wallet balance is store credit earned from <strong>refunds and promotions</strong>.
       It will be automatically applied at checkout when you place your next order.
       Wallet credits cannot be withdrawn as cash.</p>
  </div>

  <!-- Transaction History -->
  <div class="section-title"><i class="fa fa-clock-rotate-left" style="color:var(--muted);"></i> Transaction History</div>

  <% if(transactions.isEmpty()){ %>
  <div class="empty-txn">
    <i class="fa fa-receipt"></i>
    <p>No transactions yet.<br>Wallet credits appear here when you receive a refund.</p>
  </div>
  <% } else { %>
  <div class="txn-list">
    <% for(String[] t : transactions){
       String type   = t[1] != null ? t[1] : "CREDIT";
       String reason = t[2] != null ? t[2] : "Wallet credit";
       String ordRef = t[3] != null ? " · Order #"+t[3] : "";
       String date   = t[4] != null ? t[4].substring(0, 16) : "";
       double amt    = 0; try { amt = Double.parseDouble(t[0]); } catch(Exception _e){}
    %>
    <div class="txn-item">
      <div class="txn-icon <%=type%>">
        <i class="fa <%="CREDIT".equals(type)?"fa-arrow-down":"fa-arrow-up"%>"></i>
      </div>
      <div class="txn-body">
        <div class="txn-reason"><%=reason%><%=ordRef%></div>
        <div class="txn-date"><%=date%></div>
      </div>
      <div class="txn-amount <%=type%>">
        <%="CREDIT".equals(type)?"+":"−"%>₹<%= String.format("%.2f", amt) %>
      </div>
    </div>
    <% } %>
  </div>
  <% } %>

</div>

<script>
function toggleDark(){
  var html = document.documentElement;
  html.setAttribute('data-theme', html.getAttribute('data-theme')==='dark'?'light':'dark');
  localStorage.setItem('sibsTheme', html.getAttribute('data-theme'));
}
document.addEventListener('DOMContentLoaded',()=>{
  var t=localStorage.getItem('sibsTheme');
  if(t) document.documentElement.setAttribute('data-theme',t);
});
</script>
</body>
</html>
