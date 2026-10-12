<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="com.sibs.dao.DeliveryBoyDAO,com.sibs.model.DeliveryBoy,com.sibs.util.DBConnection,java.util.*,java.sql.*" %>
<%
DeliveryBoy db = (DeliveryBoy)session.getAttribute("deliveryBoy");
if(db == null){ response.sendRedirect("delivery-login.jsp"); return; }

DeliveryBoyDAO dbDao = new DeliveryBoyDAO();
DeliveryBoy dbFresh = dbDao.getById(db.getId());
if(dbFresh == null){ response.sendRedirect("delivery-login.jsp"); return; }
session.setAttribute("deliveryBoy", dbFresh);

double walletBalance = dbFresh.getWallet();
boolean walletOk = walletBalance >= 200.0;

// Load recent transactions
java.util.List<String[]> txns = new java.util.ArrayList<>();
try (Connection _con = DBConnection.getConnection()) {
    _con.createStatement().execute(
        "CREATE TABLE IF NOT EXISTS wallet_transactions (" +
        "  id INT AUTO_INCREMENT PRIMARY KEY," +
        "  delivery_boy_id INT NOT NULL," +
        "  amount DECIMAL(10,2) NOT NULL," +
        "  type ENUM('CREDIT','DEBIT') NOT NULL DEFAULT 'CREDIT'," +
        "  note VARCHAR(500)," +
        "  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP" +
        ")"
    );
    PreparedStatement _ps = _con.prepareStatement(
        "SELECT amount, type, note, created_at FROM wallet_transactions " +
        "WHERE delivery_boy_id=? ORDER BY created_at DESC LIMIT 20"
    );
    _ps.setInt(1, db.getId());
    ResultSet _rs = _ps.executeQuery();
    while(_rs.next()) {
        txns.add(new String[]{
            String.valueOf(_rs.getDouble("amount")),
            _rs.getString("type"),
            _rs.getString("note"),
            _rs.getString("created_at")
        });
    }
} catch(Exception _e) { /* table may not exist yet */ }

// Load withdraw requests for this delivery boy
List<String[]> withdrawRequests = dbDao.getWithdrawRequestsFor(db.getId());
boolean hasPendingWithdraw = withdrawRequests.stream().anyMatch(r -> "PENDING".equals(r[2]));

String successMsg = "";
String errorMsg   = "";
String flash = request.getParameter("flash");
if("recharged".equals(flash))            successMsg = "Wallet recharged successfully!";
if("recharge_error".equals(flash))       errorMsg   = "Recharge failed. Please try again.";
if("withdraw_requested".equals(flash))   successMsg = "Withdrawal request submitted! Staff will review shortly.";
if("insufficient".equals(flash))         errorMsg   = "Insufficient balance. Wallet must maintain ₹200 minimum.";
if("invalid_amount".equals(flash))       errorMsg   = "Invalid amount entered.";
if("pending_exists".equals(flash))       errorMsg   = "You already have a pending withdrawal request. Please wait for staff approval.";
if("error".equals(flash))                errorMsg   = "Something went wrong. Please try again.";

String initials = dbFresh.getName().length() >= 2
    ? dbFresh.getName().substring(0,2).toUpperCase()
    : dbFresh.getName().toUpperCase();
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1">
<title>Wallet Recharge · SIBS</title>
<link href="https://fonts.googleapis.com/css2?family=Syne:wght@400;600;700;800&family=DM+Sans:wght@300;400;500;600&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<script src="https://checkout.razorpay.com/v1/checkout.js"></script>
<style>
:root{
  --brand:#7c3aed;--brand-light:#ede9fe;--brand-dark:#4c1d95;
  --surface:#ffffff;--bg:#f3f1fb;--bg2:#edeaf8;
  --text:#0d0d14;--muted:#6b6882;--border:rgba(124,58,237,.12);
  --green:#16a34a;--green-bg:#dcfce7;--amber:#b45309;--amber-bg:#fef3c7;
  --red:#dc2626;--red-bg:#fee2e2;--blue:#1d4ed8;--blue-bg:#eff6ff;
  --radius:14px;--radius-sm:9px;
  --shadow:0 2px 16px rgba(124,58,237,.10);--shadow-lg:0 8px 40px rgba(124,58,237,.16);
  --ff-head:'Syne',sans-serif;--ff-body:'DM Sans',sans-serif;
}
[data-theme="dark"]{
  --brand:#a78bfa;--brand-light:#2e1f5e;--brand-dark:#c4b5fd;
  --surface:#13111f;--bg:#0d0b18;--bg2:#1a1730;--text:#f0eeff;--muted:#9791b8;
  --border:rgba(167,139,250,.14);--green:#4ade80;--green-bg:#052e16;
  --amber:#fcd34d;--amber-bg:#451a03;--red:#f87171;--red-bg:#450a0a;
  --blue:#93c5fd;--blue-bg:#0c1a3d;
  --shadow:0 2px 20px rgba(0,0,0,.4);--shadow-lg:0 8px 40px rgba(0,0,0,.5);
}
*,*::before,*::after{margin:0;padding:0;box-sizing:border-box;}
html{font-family:var(--ff-body);font-size:15px;color:var(--text);background:var(--bg);}
body{min-height:100vh;padding-bottom:90px;}
a{text-decoration:none;color:inherit;}
button{font-family:var(--ff-body);cursor:pointer;}

/* TOPBAR */
.topbar{background:var(--surface);border-bottom:1px solid var(--border);padding:0 18px;height:60px;
  display:flex;align-items:center;justify-content:space-between;
  position:sticky;top:0;z-index:200;box-shadow:var(--shadow);}
.topbar-left{display:flex;align-items:center;gap:10px;}
.back-btn{width:36px;height:36px;border:1px solid var(--border);border-radius:var(--radius-sm);
  background:var(--bg);color:var(--muted);display:flex;align-items:center;justify-content:center;
  font-size:14px;transition:all .2s;text-decoration:none;}
.back-btn:hover{background:var(--brand-light);color:var(--brand);}
.topbar-title{font-family:var(--ff-head);font-size:17px;font-weight:700;}
.icon-btn{width:36px;height:36px;border:1px solid var(--border);border-radius:var(--radius-sm);
  background:var(--bg);color:var(--muted);display:flex;align-items:center;justify-content:center;
  cursor:pointer;font-size:14px;transition:all .2s;border:none;}
.icon-btn:hover{background:var(--brand-light);color:var(--brand);}

/* PAGE */
.page{padding:16px;max-width:700px;margin:0 auto;}

/* FLASH */
.flash{display:flex;align-items:center;gap:10px;padding:13px 16px;border-radius:var(--radius-sm);
  font-size:13px;font-weight:500;margin-bottom:16px;animation:slideDown .3s ease;}
.flash.success{background:var(--green-bg);color:var(--green);}
.flash.error{background:var(--red-bg);color:var(--red);}
@keyframes slideDown{from{opacity:0;transform:translateY(-6px)}to{opacity:1;transform:translateY(0)}}

/* WALLET HERO CARD */
.wallet-hero{background:linear-gradient(135deg,var(--brand-dark),var(--brand));
  border-radius:var(--radius);padding:24px;color:#fff;margin-bottom:16px;
  box-shadow:var(--shadow-lg);position:relative;overflow:hidden;}
.wallet-hero::before{content:'';position:absolute;top:-40px;right:-40px;
  width:160px;height:160px;border-radius:50%;background:rgba(255,255,255,.07);}
.wallet-hero::after{content:'';position:absolute;bottom:-60px;left:-30px;
  width:180px;height:180px;border-radius:50%;background:rgba(255,255,255,.05);}
.wh-label{font-size:11px;text-transform:uppercase;letter-spacing:.08em;opacity:.75;font-weight:600;}
.wh-amount{font-family:var(--ff-head);font-size:42px;font-weight:800;line-height:1.1;margin:6px 0 4px;}
.wh-sub{font-size:13px;opacity:.8;}
.wh-badge{display:inline-flex;align-items:center;gap:5px;margin-top:12px;
  padding:5px 12px;border-radius:20px;font-size:12px;font-weight:600;}
.wh-badge.ok{background:rgba(34,197,94,.25);color:#bbf7d0;}
.wh-badge.low{background:rgba(239,68,68,.25);color:#fecaca;}

/* QUICK AMOUNTS */
.section-title{font-family:var(--ff-head);font-size:15px;font-weight:700;margin-bottom:12px;}
.quick-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:10px;margin-bottom:16px;}
.quick-btn{padding:12px 8px;border:2px solid var(--border);border-radius:var(--radius-sm);
  background:var(--surface);font-family:var(--ff-head);font-size:15px;font-weight:700;
  color:var(--text);cursor:pointer;transition:all .2s;text-align:center;}
.quick-btn:hover,.quick-btn.active{border-color:var(--brand);background:var(--brand-light);color:var(--brand);}
.quick-btn small{display:block;font-size:10px;font-weight:400;color:var(--muted);margin-top:2px;font-family:var(--ff-body);}

/* CUSTOM AMOUNT INPUT */
.custom-wrap{background:var(--surface);border-radius:var(--radius);padding:16px;
  border:1px solid var(--border);margin-bottom:16px;box-shadow:var(--shadow);}
.input-label{font-size:12px;color:var(--muted);font-weight:500;margin-bottom:6px;display:block;}
.input-row{display:flex;align-items:center;gap:10px;}
.rupee-prefix{font-family:var(--ff-head);font-size:22px;font-weight:700;color:var(--brand);}
.amount-input{flex:1;border:2px solid var(--border);border-radius:var(--radius-sm);
  padding:10px 14px;font-family:var(--ff-head);font-size:22px;font-weight:700;
  background:var(--bg);color:var(--text);transition:border-color .2s;}
.amount-input:focus{outline:none;border-color:var(--brand);}
.input-hint{font-size:11px;color:var(--muted);margin-top:6px;}

/* RECHARGE BUTTON */
.recharge-btn{width:100%;padding:15px;background:linear-gradient(135deg,var(--brand),var(--brand-dark));
  color:#fff;border:none;border-radius:var(--radius);font-family:var(--ff-head);
  font-size:17px;font-weight:700;cursor:pointer;display:flex;align-items:center;
  justify-content:center;gap:10px;transition:all .2s;margin-bottom:20px;
  box-shadow:0 4px 20px rgba(124,58,237,.35);}
.recharge-btn:hover{transform:translateY(-1px);box-shadow:0 6px 24px rgba(124,58,237,.45);}
.recharge-btn:disabled{opacity:.55;cursor:not-allowed;transform:none;}

/* TRANSACTIONS */
.tx-card{background:var(--surface);border-radius:var(--radius);
  border:1px solid var(--border);box-shadow:var(--shadow);overflow:hidden;}
.tx-header{padding:14px 16px;border-bottom:1px solid var(--border);
  font-family:var(--ff-head);font-size:14px;font-weight:700;}
.tx-item{display:flex;align-items:center;gap:12px;padding:13px 16px;
  border-bottom:1px solid var(--border);}
.tx-item:last-child{border-bottom:none;}
.tx-icon{width:36px;height:36px;border-radius:10px;display:flex;align-items:center;
  justify-content:center;font-size:14px;flex-shrink:0;}
.tx-icon.credit{background:var(--green-bg);color:var(--green);}
.tx-icon.debit{background:var(--red-bg);color:var(--red);}
.tx-info{flex:1;min-width:0;}
.tx-label{font-size:13px;font-weight:500;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;}
.tx-date{font-size:11px;color:var(--muted);margin-top:2px;}
.tx-amount{font-family:var(--ff-head);font-size:15px;font-weight:700;}
.tx-amount.credit{color:var(--green);}
.tx-amount.debit{color:var(--red);}
.tx-empty{padding:32px;text-align:center;color:var(--muted);font-size:13px;}

/* BOTTOM NAV */
.bottom-nav{position:fixed;bottom:0;left:0;right:0;height:64px;
  background:var(--surface);border-top:1px solid var(--border);
  display:flex;align-items:center;justify-content:space-around;
  box-shadow:0 -4px 20px rgba(124,58,237,.08);z-index:100;}
.nav-item{display:flex;flex-direction:column;align-items:center;gap:3px;
  color:var(--muted);font-size:10px;font-weight:500;text-decoration:none;
  padding:4px 12px;border-radius:var(--radius-sm);transition:color .2s;cursor:pointer;}
.nav-item.active,.nav-item:hover{color:var(--brand);}
.nav-item i{font-size:18px;}

/* MODAL */
.modal-overlay{position:fixed;inset:0;background:rgba(0,0,0,.5);
  display:none;align-items:flex-end;justify-content:center;z-index:500;}
.modal-overlay.open{display:flex;}
.modal{background:var(--surface);border-radius:var(--radius) var(--radius) 0 0;
  padding:24px;width:100%;max-width:500px;animation:slideUp .3s ease;}
@keyframes slideUp{from{transform:translateY(40px);opacity:0}to{transform:translateY(0);opacity:1}}
.modal-title{font-family:var(--ff-head);font-size:18px;font-weight:700;margin-bottom:4px;}
.modal-sub{font-size:13px;color:var(--muted);margin-bottom:20px;}
.modal-amount{font-family:var(--ff-head);font-size:32px;font-weight:800;color:var(--brand);margin-bottom:20px;}
.modal-btns{display:flex;gap:10px;}
.btn-ghost{flex:1;padding:12px;border:2px solid var(--border);border-radius:var(--radius-sm);
  background:transparent;color:var(--text);font-family:var(--ff-head);font-size:15px;font-weight:600;cursor:pointer;}
.btn-brand{flex:2;padding:12px;background:var(--brand);color:#fff;border:none;
  border-radius:var(--radius-sm);font-family:var(--ff-head);font-size:15px;font-weight:700;cursor:pointer;}
</style>
</head>
<body>

<!-- TOPBAR -->
<div class="topbar">
  <div class="topbar-left">
    <a href="delivery-dashboard.jsp" class="back-btn"><i class="fa fa-arrow-left"></i></a>
    <span class="topbar-title">💳 Wallet Recharge</span>
  </div>
  <button class="icon-btn" onclick="toggleTheme()" title="Toggle theme">
    <i class="fa fa-moon" id="themeIcon"></i>
  </button>
</div>

<div class="page">

  <!-- FLASH MESSAGES -->
  <% if(!successMsg.isEmpty()){ %>
  <div class="flash success"><i class="fa fa-check-circle"></i> <%=successMsg%></div>
  <% } %>
  <% if(!errorMsg.isEmpty()){ %>
  <div class="flash error"><i class="fa fa-exclamation-circle"></i> <%=errorMsg%></div>
  <% } %>

  <!-- WALLET HERO -->
  <div class="wallet-hero">
    <div class="wh-label">Your Wallet Balance</div>
    <div class="wh-amount">₹<%= String.format("%.2f", walletBalance) %></div>
    <div class="wh-sub">Operational wallet · used to go online</div>
    <% if(walletOk){ %>
    <div class="wh-badge ok"><i class="fa fa-check-circle"></i> Ready to go online</div>
    <% } else { %>
    <div class="wh-badge low"><i class="fa fa-exclamation-triangle"></i> Min ₹200 required to go online</div>
    <% } %>
  </div>

  <!-- QUICK AMOUNTS -->
  <div class="section-title">Quick Recharge</div>
  <div class="quick-grid">
    <button class="quick-btn" onclick="setAmount(200)">₹200 <small>Min required</small></button>
    <button class="quick-btn" onclick="setAmount(500)">₹500 <small>Popular</small></button>
    <button class="quick-btn" onclick="setAmount(1000)">₹1000 <small>Best value</small></button>
    <button class="quick-btn" onclick="setAmount(1500)">₹1500</button>
    <button class="quick-btn" onclick="setAmount(2000)">₹2000</button>
    <button class="quick-btn" onclick="setAmount(5000)">₹5000</button>
  </div>

  <!-- CUSTOM AMOUNT -->
  <div class="custom-wrap">
    <label class="input-label">Or enter custom amount</label>
    <div class="input-row">
      <span class="rupee-prefix">₹</span>
      <input type="number" class="amount-input" id="amountInput" min="200" step="50"
             placeholder="200" oninput="onAmountInput(this.value)">
    </div>
    <div class="input-hint">Minimum recharge: ₹200</div>
  </div>

  <!-- RECHARGE BUTTON -->
  <button class="recharge-btn" id="rechargeBtn" onclick="startRecharge()" disabled>
    <i class="fa fa-bolt"></i> Recharge Wallet via Razorpay
  </button>

  <!-- ═══════════════════════════════════════════════════════════ -->
  <!-- WITHDRAW REQUEST SECTION -->
  <!-- ═══════════════════════════════════════════════════════════ -->
  <div class="section-title" style="margin-top:24px">💸 Withdraw Funds</div>
  <div style="background:var(--surface);border-radius:var(--radius);border:1px solid var(--border);padding:18px;box-shadow:var(--shadow);margin-bottom:18px;">

    <% if(hasPendingWithdraw) { %>
    <!-- Pending withdraw banner -->
    <div style="background:var(--amber-bg);border:1px solid #fde68a;border-radius:var(--radius-sm);padding:14px 16px;display:flex;align-items:center;gap:12px;">
      <i class="fa fa-clock" style="color:var(--amber);font-size:20px;"></i>
      <div>
        <div style="font-weight:700;color:var(--amber);font-size:14px;">Withdrawal Request Pending</div>
        <div style="font-size:12px;color:var(--muted);margin-top:2px;">Staff is reviewing your request. You will be notified once approved or rejected.</div>
      </div>
    </div>
    <% } else { %>
    <!-- Withdraw form -->
    <div style="font-size:13px;color:var(--muted);margin-bottom:14px;">
      Request a withdrawal from your wallet. Staff will approve it and the amount will be debited. Wallet must maintain a ₹200 minimum balance.
    </div>
    <div style="display:flex;gap:10px;flex-wrap:wrap;align-items:flex-end;">
      <div style="flex:1;min-width:160px;">
        <label style="font-size:11px;font-weight:600;color:var(--muted);display:block;margin-bottom:5px;text-transform:uppercase;letter-spacing:.05em;">Withdraw Amount (₹)</label>
        <input type="number" id="withdrawAmtInput" min="1" step="1" placeholder="Enter amount"
          style="width:100%;padding:11px 14px;border:1.5px solid var(--border);border-radius:var(--radius-sm);font-size:15px;font-weight:600;color:var(--text);background:var(--bg);outline:none;font-family:var(--ff-body);"
          oninput="validateWithdraw()" onfocus="this.style.borderColor='var(--brand)'" onblur="this.style.borderColor='var(--border)'">
        <div id="withdrawHint" style="font-size:11px;color:var(--muted);margin-top:4px;">
          Available: ₹<%= String.format("%.2f", Math.max(0, walletBalance - 200)) %> (after ₹200 reserve)
        </div>
      </div>
      <button id="withdrawBtn" onclick="submitWithdraw()" disabled
        style="padding:11px 20px;background:linear-gradient(135deg,#7c3aed,#4c1d95);color:#fff;border:none;border-radius:var(--radius-sm);font-size:14px;font-weight:700;cursor:pointer;font-family:var(--ff-body);white-space:nowrap;transition:all .2s;opacity:.5;">
        <i class="fa fa-paper-plane"></i> Request Withdrawal
      </button>
    </div>
    <% } %>
  </div>

  <!-- Withdraw request history -->
  <% if(!withdrawRequests.isEmpty()) { %>
  <div class="section-title" style="margin-top:4px;font-size:13px;color:var(--muted);font-weight:600;">Withdraw Request History</div>
  <div style="background:var(--surface);border-radius:var(--radius);border:1px solid var(--border);overflow:hidden;margin-bottom:18px;">
    <% for(String[] wr : withdrawRequests) {
         String wrAmt    = wr[1];
         String wrStatus = wr[2];
         String wrNote   = wr[3] != null ? wr[3] : "";
         String wrReqAt  = wr[4] != null ? wr[4].substring(0, Math.min(16, wr[4].length())) : "";
         double wrAmtD   = 0; try { wrAmtD = Double.parseDouble(wrAmt); } catch(Exception ig){}
    %>
    <div style="display:flex;align-items:center;gap:12px;padding:13px 16px;border-bottom:1px solid var(--border);">
      <div style="width:36px;height:36px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:15px;flex-shrink:0;
        background:<%= "PENDING".equals(wrStatus) ? "var(--amber-bg)" : "APPROVED".equals(wrStatus) ? "var(--green-bg)" : "var(--red-bg)" %>;">
        <i class="fa <%= "PENDING".equals(wrStatus) ? "fa-clock" : "APPROVED".equals(wrStatus) ? "fa-check" : "fa-times" %>"
           style="color:<%= "PENDING".equals(wrStatus) ? "var(--amber)" : "APPROVED".equals(wrStatus) ? "var(--green)" : "var(--red)" %>"></i>
      </div>
      <div style="flex:1;">
        <div style="font-weight:600;font-size:13px;">₹<%= String.format("%.2f", wrAmtD) %> Withdrawal</div>
        <div style="font-size:11px;color:var(--muted);">
          <%= wrReqAt %>
          <% if(!wrNote.isBlank()) { %> · <em><%= wrNote %></em><% } %>
        </div>
      </div>
      <span style="font-size:11px;font-weight:700;padding:4px 10px;border-radius:999px;
        background:<%= "PENDING".equals(wrStatus) ? "var(--amber-bg)" : "APPROVED".equals(wrStatus) ? "var(--green-bg)" : "var(--red-bg)" %>;
        color:<%= "PENDING".equals(wrStatus) ? "var(--amber)" : "APPROVED".equals(wrStatus) ? "var(--green)" : "var(--red)" %>;">
        <%= wrStatus %>
      </span>
    </div>
    <% } %>
  </div>
  <% } %>

  <!-- TRANSACTION HISTORY -->
  <div class="section-title">Recent Transactions</div>
  <div class="tx-card">
    <div class="tx-header"><i class="fa fa-history" style="color:var(--brand);margin-right:6px;"></i>Wallet History</div>
    <% if(txns.isEmpty()){ %>
    <div class="tx-empty"><i class="fa fa-wallet" style="font-size:28px;margin-bottom:8px;display:block;"></i>No transactions yet.<br>Make your first recharge to get started!</div>
    <% } else { for(String[] tx : txns) {
        double txAmt = Double.parseDouble(tx[0]);
        String txType = tx[1];
        String txNote = tx[2] != null ? tx[2] : "";
        String txDate = tx[3] != null ? tx[3] : "";
        String displayNote = txNote.contains("Razorpay") ? "Wallet Recharge via Razorpay" : txNote;
        if(displayNote.length() > 40) displayNote = displayNote.substring(0, 40) + "…";
    %>
    <div class="tx-item">
      <div class="tx-icon <%="CREDIT".equals(txType)?"credit":"debit"%>">
        <i class="fa <%="CREDIT".equals(txType)?"fa-arrow-down":"fa-arrow-up"%>"></i>
      </div>
      <div class="tx-info">
        <div class="tx-label"><%=displayNote%></div>
        <div class="tx-date"><%=txDate%></div>
      </div>
      <div class="tx-amount <%="CREDIT".equals(txType)?"credit":"debit"%>">
        <%="CREDIT".equals(txType)?"+":"−"%>₹<%= String.format("%.0f", txAmt) %>
      </div>
    </div>
    <% }} %>
  </div>

</div><!-- /page -->

<!-- CONFIRM MODAL -->
<div class="modal-overlay" id="confirmModal">
  <div class="modal">
    <div class="modal-title">Confirm Recharge</div>
    <div class="modal-sub">You are about to recharge your wallet with</div>
    <div class="modal-amount" id="modalAmount">₹0</div>
    <div class="modal-btns">
      <button class="btn-ghost" onclick="closeModal()">Cancel</button>
      <button class="btn-brand" onclick="proceedRecharge()"><i class="fa fa-bolt"></i> Pay Now</button>
    </div>
  </div>
</div>

<!-- BOTTOM NAV -->
<nav class="bottom-nav">
  <a href="delivery-dashboard.jsp" class="nav-item"><i class="fa fa-home"></i><span>Home</span></a>
  <a href="delivery-dashboard.jsp#orders" class="nav-item"><i class="fa fa-list-alt"></i><span>Orders</span></a>
  <a href="delivery-earnings.jsp" class="nav-item"><i class="fa fa-wallet"></i><span>Earnings</span></a>
  <a href="delivery-cash-ledger.jsp" class="nav-item"><i class="fa fa-money-bill"></i><span>COD</span></a>
  <a href="delivery-ratings.jsp" class="nav-item"><i class="fa fa-star"></i><span>Ratings</span></a>
</nav>

<script>
let selectedAmount = 0;

function setAmount(amt) {
  selectedAmount = amt;
  document.getElementById('amountInput').value = amt;
  document.querySelectorAll('.quick-btn').forEach(b => b.classList.remove('active'));
  event.target.closest('.quick-btn').classList.add('active');
  updateBtn();
}

function onAmountInput(val) {
  selectedAmount = parseFloat(val) || 0;
  document.querySelectorAll('.quick-btn').forEach(b => b.classList.remove('active'));
  updateBtn();
}

function updateBtn() {
  const btn = document.getElementById('rechargeBtn');
  btn.disabled = selectedAmount < 200;
}

function startRecharge() {
  if (selectedAmount < 200) return;
  document.getElementById('modalAmount').textContent = '₹' + selectedAmount.toFixed(0);
  document.getElementById('confirmModal').classList.add('open');
}

function closeModal() {
  document.getElementById('confirmModal').classList.remove('open');
}

function proceedRecharge() {
  closeModal();
  const btn = document.getElementById('rechargeBtn');
  btn.disabled = true;
  btn.innerHTML = '<i class="fa fa-spinner fa-spin"></i> Creating order…';

  fetch('walletRecharge?step=createOrder&amount=' + selectedAmount)
    .then(r => r.json())
    .then(data => {
      if (data.error) { alert('Error: ' + data.error); resetBtn(); return; }

      const options = {
        key: data.keyId,
        amount: data.amount,
        currency: 'INR',
        name: 'SIBS Wallet Recharge',
        description: 'Operational Wallet Top-Up',
        order_id: data.razorpayOrderId,
        handler: function(response) {
          // Submit to servlet
          const form = document.createElement('form');
          form.method = 'POST';
          form.action = 'walletRecharge';
          ['razorpay_payment_id','razorpay_order_id','razorpay_signature'].forEach(k => {
            const inp = document.createElement('input');
            inp.type = 'hidden'; inp.name = k; inp.value = response[k];
            form.appendChild(inp);
          });
          const amtInp = document.createElement('input');
          amtInp.type = 'hidden'; amtInp.name = 'amount'; amtInp.value = selectedAmount;
          form.appendChild(amtInp);
          document.body.appendChild(form);
          form.submit();
        },
        prefill: { name: '<%=dbFresh.getName()%>', contact: '<%=dbFresh.getPhone()%>' },
        theme: { color: '#7c3aed' },
        modal: { ondismiss: function() { resetBtn(); } }
      };

      const rzp = new Razorpay(options);
      rzp.on('payment.failed', function(resp) {
        alert('Payment failed: ' + resp.error.description);
        resetBtn();
      });
      rzp.open();
    })
    .catch(err => { console.error(err); alert('Network error. Try again.'); resetBtn(); });
}

function resetBtn() {
  const btn = document.getElementById('rechargeBtn');
  btn.disabled = false;
  btn.innerHTML = '<i class="fa fa-bolt"></i> Recharge Wallet via Razorpay';
}

// Dark mode
function toggleTheme() {
  const isDark = document.documentElement.getAttribute('data-theme') === 'dark';
  document.documentElement.setAttribute('data-theme', isDark ? '' : 'dark');
  document.getElementById('themeIcon').className = isDark ? 'fa fa-moon' : 'fa fa-sun';
  localStorage.setItem('theme', isDark ? 'light' : 'dark');
}
(function() {
  const t = localStorage.getItem('theme');
  if (t === 'dark') {
    document.documentElement.setAttribute('data-theme','dark');
    document.addEventListener('DOMContentLoaded', function() {
      const ic = document.getElementById('themeIcon');
      if(ic) ic.className = 'fa fa-sun';
    });
  }
})();

// Close modal on outside click
document.getElementById('confirmModal').addEventListener('click', function(e) {
  if(e.target === this) closeModal();
});

// ── WITHDRAW REQUEST ─────────────────────────────────────────────
const MAX_WITHDRAWABLE = <%= Math.max(0, walletBalance - 200) %>;

function validateWithdraw() {
  const input = document.getElementById('withdrawAmtInput');
  const btn   = document.getElementById('withdrawBtn');
  const hint  = document.getElementById('withdrawHint');
  if(!input || !btn) return;
  const val = parseFloat(input.value);
  if(isNaN(val) || val <= 0) {
    btn.disabled = true; btn.style.opacity = '.5';
    hint.textContent = 'Available: ₹' + MAX_WITHDRAWABLE.toFixed(2) + ' (after ₹200 reserve)';
    hint.style.color = 'var(--muted)';
  } else if(val > MAX_WITHDRAWABLE) {
    btn.disabled = true; btn.style.opacity = '.5';
    hint.textContent = '⚠ Maximum you can withdraw: ₹' + MAX_WITHDRAWABLE.toFixed(2);
    hint.style.color = 'var(--red)';
  } else {
    btn.disabled = false; btn.style.opacity = '1';
    hint.textContent = 'After withdrawal: ₹' + (<%= walletBalance %> - val).toFixed(2) + ' will remain';
    hint.style.color = 'var(--green)';
  }
}

function submitWithdraw() {
  const val = parseFloat(document.getElementById('withdrawAmtInput').value);
  if(isNaN(val) || val <= 0 || val > MAX_WITHDRAWABLE) return;
  if(!confirm('Request withdrawal of ₹' + val.toFixed(2) + '?\nStaff will review and approve.')) return;
  document.getElementById('withdrawAmtHidden').value = val;
  document.getElementById('withdrawForm').submit();
}
</script>

<!-- Withdraw hidden form -->
<form id="withdrawForm" method="POST" action="walletWithdraw" style="display:none">
  <input type="hidden" name="amount" id="withdrawAmtHidden">
</form>
</body>
</html>
