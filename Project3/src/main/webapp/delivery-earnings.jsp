<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.util.*,com.sibs.dao.CodLedgerDAO,com.sibs.dao.CodLedgerDAO.CodEntry,com.sibs.dao.DeliveryBoyDAO,com.sibs.model.DeliveryBoy,com.sibs.util.AppSettings,com.sibs.util.DBConnection,java.sql.*" %>
<%
DeliveryBoy db = (DeliveryBoy)session.getAttribute("deliveryBoy");
if(db == null){ response.sendRedirect("delivery-login.jsp"); return; }

DeliveryBoyDAO dbDao = new DeliveryBoyDAO();
DeliveryBoy dbFresh = dbDao.getById(db.getId());
if(dbFresh == null){ response.sendRedirect("delivery-login.jsp"); return; }
session.setAttribute("deliveryBoy", dbFresh);

CodLedgerDAO codDao = new CodLedgerDAO();
List<CodEntry> allEntries = codDao.getByDeliveryBoy(db.getId());

// Deliveries today — split by payment type
int deliveredToday       = dbDao.getDeliveredToday(db.getId());
int deliveredTodayOnline = dbDao.getDeliveredTodayOnline(db.getId()); // prepaid/online only
int deliveredTodayCod    = dbDao.getDeliveredTodayCod(db.getId());    // COD only
int totalDelivered       = dbFresh.getDeliveredTotal();

// NET EARNINGS = (ONLINE + COD) deliveries × per-delivery rate each.
double perDeliveryPay = AppSettings.getPerDeliveryPay();
double earningsToday = (deliveredTodayOnline + deliveredTodayCod) * perDeliveryPay;

// Subtract earnings already consumed for today's COD remittances
double earningsUsedToday = 0;
try (Connection _eu = DBConnection.getConnection()) {
    _eu.createStatement().execute(
        "CREATE TABLE IF NOT EXISTS delivery_earnings_used (" +
        "  id               INT AUTO_INCREMENT PRIMARY KEY," +
        "  delivery_boy_id  INT NOT NULL," +
        "  amount           DECIMAL(10,2) NOT NULL," +
        "  used_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP," +
        "  note             VARCHAR(500)" +
        ")"
    );
    try (PreparedStatement _ps2 = _eu.prepareStatement(
           "SELECT COALESCE(SUM(amount),0) FROM delivery_earnings_used " +
           "WHERE delivery_boy_id=? AND DATE(used_at)=CURDATE()")) {
        _ps2.setInt(1, db.getId());
        ResultSet _rs2 = _ps2.executeQuery();
        if(_rs2.next()) earningsUsedToday = _rs2.getDouble(1);
    }
} catch(Exception _e2) { _e2.printStackTrace(); }

// COD remittance summary
// pendingCash = total cash held from customer (e.g. ₹134)
// pendingRemittance = items amount to return to store (e.g. ₹94)
double pendingCash        = codDao.getPendingTotal(db.getId());           // total cash held
double pendingRemittance  = codDao.getPendingRemittanceTotal(db.getId()); // amount to remit
double pendingCharge      = pendingCash - pendingRemittance;              // delivery charge portion
double remittedTotal      = codDao.getRemittedTotal(db.getId());

// Net earnings = online deliveries × ₹40.
// COD delivery charges are physical cash — not tracked here.
double remittedDeliveryCharges = codDao.getRemittedDeliveryCharges(db.getId());
double netEarnings = Math.max(0, earningsToday - earningsUsedToday); // subtract already-used earnings
// ── Deposit wallet balance (CREDIT - DEBIT) ──
double depositBalance = 0;
try (Connection _con = DBConnection.getConnection();
     PreparedStatement _ps = _con.prepareStatement(
       "SELECT " +
       "  COALESCE(SUM(CASE WHEN type='CREDIT' THEN amount ELSE 0 END),0) - " +
       "  COALESCE(SUM(CASE WHEN type='DEBIT'  THEN amount ELSE 0 END),0) AS balance " +
       "FROM delivery_deposits WHERE delivery_boy_id=?")) {
    _ps.setInt(1, db.getId());
    ResultSet _rs = _ps.executeQuery();
    if(_rs.next()) depositBalance = _rs.getDouble("balance");
    if(depositBalance < 0) depositBalance = 0;
} catch(Exception _e) { /* table may not exist yet, balance stays 0 */ }

// ── Remittance logic ──
// Boy pays staff with wallet if earnings not enough.
// Payment order: earnings first → wallet for remainder
double walletBalance   = dbFresh.getWallet();
double fromCashEst     = Math.min(pendingCash, pendingRemittance);
double fromEarningsEst = Math.min(netEarnings, pendingRemittance);
double afterEarnings   = Math.max(0, pendingRemittance - fromEarningsEst);
// Use regular wallet (delivery_boys.wallet) as fallback for shortfall
double fromDepositEst  = Math.min(afterEarnings, walletBalance);
double shortfall       = Math.max(0, afterEarnings - walletBalance);
boolean canRemit       = pendingRemittance > 0
                      && (netEarnings >= pendingRemittance || walletBalance >= afterEarnings);
double totalAvailable  = netEarnings + walletBalance;

String successMsg = "";
String errorMsg   = "";
String flash = request.getParameter("flash");
if("remitted".equals(flash))           successMsg = "Cash remitted from earnings successfully!";
if("deposited".equals(flash))          successMsg = "₹500 deposit credited to your wallet via Razorpay!";
if("cod_remitted".equals(flash))       successMsg = "COD cash remitted to staff from your earnings!";
if("remit_partial".equals(flash))      successMsg = "COD remitted — partial amount covered from your wallet.";
if("nothing_to_remit".equals(flash))   successMsg = "No pending COD cash to remit.";
if("remit_error".equals(flash))        errorMsg   = "Remittance failed. Please try again.";
if("deposit_error".equals(flash))      errorMsg   = "Deposit failed. Please try again.";
if("insufficient".equals(flash))       errorMsg   = "Not enough funds! Top up your wallet (Recharge) to cover the shortfall.";
if("force_offline".equals(flash))      errorMsg   = "\u26a0\ufe0f You've been moved OFFLINE. Your pending COD cash exceeds your total earnings + wallet balance. Recharge your wallet or remit cash to staff before going online again.";

// ── FORCE OFFLINE when boy cannot cover his COD debt ─────────────────
// If shortfall > 0 it means pendingRemittance > earnings + wallet.
// Take him offline immediately so he cannot accept new orders.
if (shortfall > 0 && pendingRemittance > 0) {
    dbDao.setShiftStatus(db.getId(), "OFFLINE");
    db.setShiftStatus("OFFLINE");
    db.setOnline(false);
    session.setAttribute("deliveryBoy", db);
    session.setAttribute("shiftStatus", "OFFLINE");
    if (errorMsg.isEmpty()) {
        errorMsg = "\u26a0\ufe0f You have been moved OFFLINE. Pending COD \u20b9"
            + String.format("%.0f", pendingRemittance)
            + " exceeds your earnings + wallet (\u20b9"
            + String.format("%.0f", totalAvailable)
            + "). Recharge your wallet or remit cash to staff to go back online.";
    }
}
// ─────────────────────────────────────────────────────────────────────

String initials = dbFresh.getName().length() >= 2
    ? dbFresh.getName().substring(0,2).toUpperCase()
    : dbFresh.getName().toUpperCase();
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1">
<title>Earnings · SIBS</title>
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
  --orange:#ea580c;--orange-bg:#fff7ed;
  --radius:14px;--radius-sm:9px;
  --shadow:0 2px 16px rgba(124,58,237,.10);--shadow-lg:0 8px 40px rgba(124,58,237,.16);
  --ff-head:'Syne',sans-serif;--ff-body:'DM Sans',sans-serif;
}
[data-theme="dark"]{
  --brand:#a78bfa;--brand-light:#2e1f5e;--brand-dark:#c4b5fd;
  --surface:#13111f;--bg:#0d0b18;--bg2:#1a1730;--text:#f0eeff;--muted:#9791b8;
  --border:rgba(167,139,250,.14);--green:#4ade80;--green-bg:#052e16;
  --amber:#fcd34d;--amber-bg:#451a03;--red:#f87171;--red-bg:#450a0a;
  --blue:#93c5fd;--blue-bg:#0c1a3d;--orange:#fb923c;--orange-bg:#431407;
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
  font-size:13px;font-weight:500;margin-bottom:16px;animation:slideDown .3s ease;
  background:var(--green-bg);color:var(--green);border:1px solid rgba(22,163,74,.2);}
@keyframes slideDown{from{opacity:0;transform:translateY(-8px);}to{opacity:1;transform:none;}}

/* EARNINGS HERO */
.earn-hero{background:linear-gradient(135deg,#2e1065,#4c1d95,#6d28d9);
  border-radius:var(--radius);padding:24px 20px;margin-bottom:14px;color:#fff;
  position:relative;overflow:hidden;}
.earn-hero::before{content:'';position:absolute;right:-60px;top:-60px;
  width:200px;height:200px;border-radius:50%;background:rgba(255,255,255,.04);}
.earn-hero::after{content:'';position:absolute;left:-30px;bottom:-40px;
  width:140px;height:140px;border-radius:50%;background:rgba(255,255,255,.03);}
.earn-hero-label{font-size:11px;opacity:.6;text-transform:uppercase;letter-spacing:.5px;
  font-family:var(--ff-head);margin-bottom:4px;position:relative;z-index:1;}
.earn-hero-amount{font-family:var(--ff-head);font-size:44px;font-weight:800;letter-spacing:-2px;
  line-height:1;position:relative;z-index:1;}
.earn-hero-sub{font-size:12px;opacity:.55;margin-top:6px;position:relative;z-index:1;}
.earn-hero-stats{display:grid;grid-template-columns:repeat(3,1fr);gap:0;margin-top:20px;
  border-top:1px solid rgba(255,255,255,.12);padding-top:16px;position:relative;z-index:1;}
.earn-hero-stat{text-align:center;padding:0 10px;border-right:1px solid rgba(255,255,255,.1);}
.earn-hero-stat:last-child{border-right:none;}
.earn-hero-stat-num{font-family:var(--ff-head);font-size:20px;font-weight:700;color:#e9d5ff;}
.earn-hero-stat-lbl{font-size:10px;opacity:.5;margin-top:3px;text-transform:uppercase;letter-spacing:.4px;}

/* CARDS GRID */
.cards-grid{display:grid;grid-template-columns:repeat(2,1fr);gap:12px;margin-bottom:16px;}
.info-card{background:var(--surface);border:1px solid var(--border);border-radius:var(--radius);
  padding:16px;transition:transform .2s,box-shadow .2s;}
.info-card:hover{transform:translateY(-2px);box-shadow:var(--shadow);}
.info-card-icon{width:38px;height:38px;border-radius:11px;display:flex;align-items:center;
  justify-content:center;font-size:16px;margin-bottom:12px;}
.info-card-val{font-family:var(--ff-head);font-size:22px;font-weight:700;line-height:1;}
.info-card-lbl{font-size:11px;color:var(--muted);margin-top:4px;}

/* DEPOSIT CARD */
.deposit-card{background:var(--surface);border:2px solid var(--amber);border-radius:var(--radius);
  padding:18px;margin-bottom:16px;display:flex;align-items:center;gap:14px;}
.deposit-icon{width:48px;height:48px;border-radius:12px;background:var(--amber-bg);
  display:flex;align-items:center;justify-content:center;font-size:22px;flex-shrink:0;}
.deposit-info{flex:1;}
.deposit-title{font-family:var(--ff-head);font-size:15px;font-weight:700;}
.deposit-sub{font-size:12px;color:var(--muted);margin-top:3px;}
.deposit-amount{font-family:var(--ff-head);font-size:24px;font-weight:800;color:var(--amber);margin-top:4px;}
.deposit-btn{padding:10px 18px;background:linear-gradient(135deg,#f59e0b,#d97706);
  color:#fff;border:none;border-radius:var(--radius-sm);font-size:13px;font-weight:700;
  white-space:nowrap;flex-shrink:0;transition:all .2s;display:flex;align-items:center;gap:6px;}
.deposit-btn:hover{transform:translateY(-1px);box-shadow:0 4px 16px rgba(217,119,6,.4);}

/* REMIT FROM EARNINGS CARD */
.remit-card{background:var(--surface);border:2px solid var(--brand);border-radius:var(--radius);
  padding:18px;margin-bottom:16px;}
.remit-card-header{display:flex;align-items:center;gap:12px;margin-bottom:14px;}
.remit-card-icon{width:44px;height:44px;border-radius:12px;background:var(--brand-light);
  display:flex;align-items:center;justify-content:center;font-size:20px;flex-shrink:0;}
.remit-card-title{font-family:var(--ff-head);font-size:15px;font-weight:700;}
.remit-card-sub{font-size:12px;color:var(--muted);margin-top:2px;}
.remit-breakdown{background:var(--bg);border-radius:var(--radius-sm);padding:14px;margin-bottom:14px;}
.remit-row{display:flex;justify-content:space-between;align-items:center;padding:5px 0;
  font-size:13px;border-bottom:1px solid var(--border);}
.remit-row:last-child{border-bottom:none;padding-top:8px;margin-top:4px;}
.remit-row-label{color:var(--muted);}
.remit-row-val{font-weight:600;font-family:var(--ff-head);}
.remit-total-row{font-size:15px;}
.remit-total-row .remit-row-val{color:var(--brand);font-size:18px;}
.btn-remit{width:100%;padding:13px;background:var(--brand);color:#fff;border:none;
  border-radius:var(--radius-sm);font-size:14px;font-weight:700;font-family:var(--ff-body);
  display:flex;align-items:center;justify-content:center;gap:8px;transition:all .2s;}
.btn-remit:hover{background:#6d28d9;transform:translateY(-1px);}
.btn-remit:disabled{opacity:.5;cursor:not-allowed;transform:none;}

/* SECTION HEADER */
.section-h{display:flex;align-items:center;justify-content:space-between;margin-bottom:12px;}
.section-h h2{font-family:var(--ff-head);font-size:14px;font-weight:700;}
.badge-pill{font-size:11px;font-weight:600;padding:3px 10px;border-radius:999px;
  background:var(--brand-light);color:var(--brand);}

/* TRANSACTIONS TABLE */
.tx-list{display:flex;flex-direction:column;gap:8px;}
.tx-card{background:var(--surface);border:1px solid var(--border);border-radius:var(--radius);
  padding:14px 16px;display:flex;align-items:center;gap:12px;transition:box-shadow .2s;}
.tx-card:hover{box-shadow:var(--shadow);}
.tx-icon{width:40px;height:40px;border-radius:50%;display:flex;align-items:center;
  justify-content:center;font-size:15px;flex-shrink:0;}
.tx-icon.delivery{background:var(--green-bg);color:var(--green);}
.tx-icon.cod-out{background:var(--amber-bg);color:var(--amber);}
.tx-icon.cod-remit{background:var(--blue-bg);color:var(--blue);}
.tx-icon.deposit{background:var(--brand-light);color:var(--brand);}
.tx-info{flex:1;}
.tx-title{font-size:13px;font-weight:600;}
.tx-sub{font-size:11px;color:var(--muted);margin-top:2px;}
.tx-amount{font-family:var(--ff-head);font-size:15px;font-weight:700;}
.tx-amount.positive{color:var(--green);}
.tx-amount.negative{color:var(--red);}
.tx-amount.neutral{color:var(--muted);}

/* STATUS BADGE */
.status-dot{display:inline-flex;align-items:center;gap:5px;font-size:11px;font-weight:600;
  padding:3px 9px;border-radius:999px;}
.sd-collected{background:var(--amber-bg);color:var(--amber);}
.sd-remitted{background:var(--green-bg);color:var(--green);}

/* EMPTY */
.empty-state{text-align:center;padding:50px 20px;color:var(--muted);}
.empty-icon{font-size:44px;opacity:.2;margin-bottom:12px;display:block;}

/* BOTTOM NAV */
.bottom-nav{position:fixed;bottom:0;left:0;right:0;background:var(--surface);
  border-top:1px solid var(--border);display:flex;justify-content:space-around;
  padding:8px 0 12px;z-index:100;box-shadow:0 -4px 20px rgba(0,0,0,.06);}
.nav-item{display:flex;flex-direction:column;align-items:center;gap:3px;cursor:pointer;
  padding:4px 16px;border-radius:var(--radius-sm);transition:all .2s;text-decoration:none;color:var(--muted);}
.nav-item.active{color:var(--brand);}
.nav-item i{font-size:18px;}
.nav-label{font-size:10px;font-weight:500;}
.nav-indicator{width:4px;height:4px;border-radius:50%;background:var(--brand);margin:0 auto;opacity:0;transition:opacity .2s;}
.nav-item.active .nav-indicator{opacity:1;}

/* MODAL */
.modal-overlay{display:none;position:fixed;inset:0;background:rgba(0,0,0,.5);z-index:300;
  align-items:center;justify-content:center;padding:20px;}
.modal-overlay.open{display:flex;}
.modal-box{background:var(--surface);border-radius:var(--radius);padding:24px;
  max-width:380px;width:100%;box-shadow:var(--shadow-lg);animation:modalIn .25s ease;}
@keyframes modalIn{from{opacity:0;transform:scale(.95);}to{opacity:1;transform:none;}}
.modal-icon{font-size:36px;text-align:center;margin-bottom:12px;}
.modal-title{font-family:var(--ff-head);font-size:17px;font-weight:700;text-align:center;margin-bottom:6px;}
.modal-sub{font-size:13px;color:var(--muted);text-align:center;margin-bottom:18px;line-height:1.5;}
.modal-actions{display:flex;gap:10px;margin-top:16px;}
.modal-actions .btn{flex:1;}
.btn{padding:12px 20px;border:none;border-radius:var(--radius-sm);font-size:13px;font-weight:600;
  font-family:var(--ff-body);display:inline-flex;align-items:center;justify-content:center;
  gap:7px;transition:all .2s;cursor:pointer;}
.btn-brand{background:var(--brand);color:#fff;}
.btn-brand:hover{background:#6d28d9;}
.btn-ghost{background:var(--bg);color:var(--text);border:1px solid var(--border);}
.btn-ghost:hover{background:var(--bg2);}
.modal-detail-box{background:var(--bg);border-radius:var(--radius-sm);padding:14px;margin-bottom:4px;}
.modal-detail-row{display:flex;justify-content:space-between;padding:5px 0;font-size:13px;
  border-bottom:1px solid var(--border);}
.modal-detail-row:last-child{border-bottom:none;font-weight:700;}

@media(max-width:500px){
  .cards-grid{grid-template-columns:1fr 1fr;}
  .deposit-card{flex-direction:column;text-align:center;}
  .deposit-btn{width:100%;}
  .earn-hero-amount{font-size:36px;}
}
</style>
</head>
<body>

<div class="topbar">
  <div class="topbar-left">
    <a href="delivery-dashboard.jsp" class="back-btn"><i class="fa fa-arrow-left"></i></a>
    <span class="topbar-title">💰 Earnings</span>
  </div>
  <button class="icon-btn" onclick="toggleDark()"><i class="fa fa-moon"></i></button>
</div>

<div class="page">

  <% if(!successMsg.isEmpty()){ %>
    <div class="flash"><i class="fa fa-circle-check"></i> <%=successMsg%></div>
  <% } %>
  <% if(!errorMsg.isEmpty()){ %>
    <div class="flash" style="background:var(--red-bg);color:var(--red);border-color:rgba(220,38,38,.2);">
      <i class="fa fa-circle-exclamation"></i> <%=errorMsg%>
    </div>
  <% } %>

  <!-- ═══ EARNINGS HERO ═══ -->
  <div class="earn-hero">
    <div class="earn-hero-label">Today's Net Earnings</div>
    <div class="earn-hero-amount">₹<%=String.format("%.0f",netEarnings)%></div>
    <div class="earn-hero-sub">
      <%=deliveredToday > 0
        ? (pendingRemittance > 0
            ? "🎯 Gross: ₹" + String.format("%.0f", earningsToday) + " | Pending COD remittance"
            : "✅ Gross: ₹" + String.format("%.0f", earningsToday) + " | All COD remitted")
        : "Complete deliveries to earn"%>
    </div>
    <div class="earn-hero-stats">
      <div class="earn-hero-stat">
        <div class="earn-hero-stat-num"><%=deliveredToday%></div>
        <div class="earn-hero-stat-lbl">Today</div>
      </div>
      <div class="earn-hero-stat">
        <div class="earn-hero-stat-num"><%=totalDelivered%></div>
        <div class="earn-hero-stat-lbl">Lifetime</div>
      </div>
      <div class="earn-hero-stat">
        <div class="earn-hero-stat-num">₹<%=String.format("%.0f", pendingRemittance)%></div>
        <div class="earn-hero-stat-lbl">To Remit</div>
      </div>
    </div>
  </div>

  <!-- ═══ STATS CARDS ═══ -->
  <div class="cards-grid">
    <div class="info-card">
      <div class="info-card-icon" style="background:var(--green-bg);">
        <i class="fa fa-circle-check" style="color:var(--green);"></i>
      </div>
      <div class="info-card-val" style="color:var(--green);">₹<%=String.format("%.0f", remittedTotal)%></div>
      <div class="info-card-lbl">Total Remitted</div>
    </div>
    <div class="info-card">
      <div class="info-card-icon" style="background:var(--amber-bg);">
        <i class="fa fa-coins" style="color:var(--amber);"></i>
      </div>
      <div class="info-card-val" style="color:var(--amber);">₹<%=String.format("%.0f", pendingCash)%></div>
      <div class="info-card-lbl">Cash in Hand (COD)</div>
    </div>
    <div class="info-card">
      <div class="info-card-icon" style="background:var(--blue-bg);">
        <i class="fa fa-wallet" style="color:var(--blue);"></i>
      </div>
      <div class="info-card-val" style="color:var(--blue);">₹<%=String.format("%.0f", netEarnings)%></div>
      <div class="info-card-lbl">Net Earnings</div>
    </div>
    <div class="info-card">
      <div class="info-card-icon" style="background:var(--brand-light);">
        <i class="fa fa-star" style="color:var(--brand);"></i>
      </div>
      <div class="info-card-val" style="color:var(--brand);">4.9</div>
      <div class="info-card-lbl">Your Rating</div>
    </div>
    <div class="info-card" style="border:1px solid rgba(217,119,6,.3);">
      <div class="info-card-icon" style="background:var(--amber-bg);">
        <i class="fa fa-shield-halved" style="color:var(--amber);"></i>
      </div>
      <div class="info-card-val" style="color:var(--amber);">₹<%=String.format("%.0f", depositBalance)%></div>
      <div class="info-card-lbl">Deposit Wallet</div>
    </div>
  </div>

  <!-- ═══ DEPOSIT ₹500 CARD ═══ -->
  <div class="deposit-card">
    <div class="deposit-icon">🏦</div>
    <div class="deposit-info">
      <div class="deposit-title">Security Deposit</div>
      <div class="deposit-sub">Required deposit for active delivery partner</div>
      <div class="deposit-amount">₹500</div>
    </div>
    <button class="deposit-btn" onclick="showDepositModal()">
      <i class="fa fa-credit-card"></i> Pay ₹500 via Razorpay
    </button>
  </div>

  <!-- ═══ REMIT CASH FROM EARNINGS ═══ -->
  <% if(pendingCash > 0){ %>
  <div class="remit-card" style="<%= !canRemit ? "border-color:var(--red);" : "" %>">
    <div class="remit-card-header">
      <div class="remit-card-icon"><%= canRemit ? "💸" : "⚠️" %></div>
      <div>
        <div class="remit-card-title">Remit COD Cash to Staff</div>
        <div class="remit-card-sub">
          <% if(canRemit){ %>
            <%= fromDepositEst > 0
              ? "Covered from earnings + wallet"
              : "Deducted from your delivery earnings" %>
          <% } else { %>
            <span style="color:var(--red);font-weight:600;">
              Insufficient funds — shortfall ₹<%=String.format("%.0f",shortfall)%>
            </span>
          <% } %>
        </div>
      </div>
    </div>
    <div class="remit-breakdown">
      <div class="remit-row">
        <span class="remit-row-label">COD Cash Collected from Customer</span>
        <span class="remit-row-val" style="color:var(--text);">₹<%=String.format("%.0f",pendingCash)%></span>
      </div>
      <div class="remit-row">
        <span class="remit-row-label">Delivery Charge (Your Earning) 🎉</span>
        <span class="remit-row-val" style="color:var(--green);">- ₹<%=String.format("%.0f",pendingCharge)%></span>
      </div>
      <div class="remit-row remit-total-row">
        <span class="remit-row-label" style="font-weight:700;color:var(--text);">Amount to Hand to Staff</span>
        <span class="remit-row-val">₹<%=String.format("%.0f",pendingRemittance)%></span>
      </div>
      <!-- Show how remittance is covered: earnings first, deposit wallet second -->
      <% if(fromEarningsEst > 0){ %>
      <div class="remit-row" style="background:var(--green-bg);border-radius:6px;padding:6px 8px;margin-top:6px;border:none;">
        <span class="remit-row-label" style="color:var(--green);">↳ From Net Earnings</span>
        <span class="remit-row-val" style="color:var(--green);">₹<%=String.format("%.0f", fromEarningsEst)%></span>
      </div>
      <% } %>
      <% if(fromDepositEst > 0){ %>
      <div class="remit-row" style="background:var(--amber-bg);border-radius:6px;padding:6px 8px;margin-top:4px;border:none;">
        <span class="remit-row-label" style="color:var(--amber);">↳ From Wallet</span>
        <span class="remit-row-val" style="color:var(--amber);">₹<%=String.format("%.0f", fromDepositEst)%>
          <% if(shortfall > 0){ %> <span style="font-size:11px;color:var(--red);">(short ₹<%=String.format("%.0f",shortfall)%>)</span><% } %>
        </span>
      </div>
      <% } %>
    </div>
    <% if(canRemit){ %>
    <button class="btn-remit" onclick="showRemitModal()">
      <i class="fa fa-arrow-down-to-bracket"></i>
      Remit ₹<%=String.format("%.0f",pendingRemittance)%> to Staff
    </button>
    <% } else { %>
    <div style="background:var(--red-bg);border:1px solid rgba(220,38,38,.2);border-radius:var(--radius-sm);
      padding:14px;text-align:center;font-size:13px;color:var(--red);font-weight:600;">
      ⚠️ Shortfall of ₹<%=String.format("%.0f",shortfall)%> — wallet has only ₹<%=String.format("%.0f",walletBalance)%>.<br>
      <span style="font-weight:400;font-size:12px;margin-top:4px;display:block;">
        Top up your wallet via Recharge to cover the shortfall.
      </span>
    </div>
    <% } %>
  </div>
  <% } else { %>
  <div style="background:var(--green-bg);border:1px solid rgba(22,163,74,.2);border-radius:var(--radius);
    padding:16px 18px;margin-bottom:16px;display:flex;align-items:center;gap:12px;">
    <i class="fa fa-circle-check" style="color:var(--green);font-size:22px;"></i>
    <div>
      <div style="font-weight:700;color:var(--green);font-size:14px;">No Pending COD Cash</div>
      <div style="font-size:12px;color:#166534;opacity:.8;margin-top:2px;">All collected cash has been remitted to staff. ✅</div>
    </div>
  </div>
  <% } %>

  <!-- ═══ TRANSACTION HISTORY ═══ -->
  <div class="section-h" style="margin-top:8px;">
    <h2>Transaction History</h2>
    <span class="badge-pill"><%=allEntries.size()%> entries</span>
  </div>

  <div class="tx-list">
    <!-- Delivery earnings entries (per delivery) -->
    <%
    int deliveryEarnCount = 0;
    for(int i = 0; i < deliveredToday && i < 10; i++){
        deliveryEarnCount++;
    %>
    <div class="tx-card">
      <div class="tx-icon delivery"><i class="fa fa-motorcycle"></i></div>
      <div class="tx-info">
        <div class="tx-title">Delivery Completed</div>
        <div class="tx-sub">Delivery #<%=deliveryEarnCount%> · Today</div>
      </div>
      <div class="tx-amount positive">+₹40</div>
    </div>
    <% } %>

    <!-- COD entries -->
    <% for(CodEntry e : allEntries){ %>
    <div class="tx-card">
      <div class="tx-icon <%="REMITTED".equals(e.status)?"cod-remit":"cod-out"%>">
        <i class="fa <%="REMITTED".equals(e.status)?"fa-circle-check":"fa-coins"%>"></i>
      </div>
      <div class="tx-info">
        <div class="tx-title">
          COD Order #<%=e.orderId%>
          <% if(e.customerName != null){ %> · <%=e.customerName%><% } %>
        </div>
        <div class="tx-sub">
          <%=e.collectedAt != null ? e.collectedAt.substring(0,10) : "–"%>
          &nbsp;·&nbsp;
          <span class="status-dot <%="REMITTED".equals(e.status)?"sd-remitted":"sd-collected"%>">
            <%="REMITTED".equals(e.status)?"✓ Remitted":"⏳ Held"%>
          </span>
        </div>
      </div>
      <div class="tx-amount <%="REMITTED".equals(e.status)?"neutral":"negative"%>">
        <%="REMITTED".equals(e.status)?"":"–"%>₹<%=String.format("%.0f",e.amount)%>
      </div>
    </div>
    <% } %>

    <% if(allEntries.isEmpty() && deliveredToday == 0){ %>
    <div class="empty-state">
      <i class="fa fa-wallet empty-icon"></i>
      <div style="font-family:var(--ff-head);font-size:16px;font-weight:700;margin-bottom:6px;color:var(--text);">
        No transactions yet
      </div>
      <div style="font-size:13px;">Complete deliveries to see your earnings here.</div>
    </div>
    <% } %>
  </div>

</div>

<!-- ═══ DEPOSIT MODAL (Razorpay) ═══ -->
<div class="modal-overlay" id="depositModal">
  <div class="modal-box">
    <div class="modal-icon">🏦</div>
    <div class="modal-title">Deposit ₹500 via Razorpay</div>
    <div class="modal-sub">
      Pay your security deposit online. It will be credited to your wallet instantly.
    </div>
    <div class="modal-detail-box">
      <div class="modal-detail-row">
        <span style="color:var(--muted);">Deposit Amount</span>
        <span style="color:var(--amber);font-family:var(--ff-head);font-size:16px;">₹500</span>
      </div>
      <div class="modal-detail-row">
        <span style="color:var(--muted);">Partner Name</span>
        <span><%=dbFresh.getName()%></span>
      </div>
      <div class="modal-detail-row">
        <span style="color:var(--muted);">Payment Mode</span>
        <span>Razorpay (UPI / Card / Net Banking)</span>
      </div>
    </div>
    <div class="modal-actions">
      <button class="btn btn-ghost" onclick="closeDepositModal()">Cancel</button>
      <button class="btn btn-brand" onclick="startRazorpayDeposit()"
        style="flex:1;background:linear-gradient(135deg,#f59e0b,#d97706);">
        <i class="fa fa-lock"></i> Pay Securely ₹500
      </button>
    </div>
  </div>
</div>

<!-- Hidden form to POST after Razorpay success -->
<form id="depositConfirmForm" action="deliveryDeposit" method="post" style="display:none;">
  <input type="hidden" name="amount" value="500">
  <input type="hidden" name="razorpay_payment_id" id="rzp_payment_id">
  <input type="hidden" name="razorpay_order_id"   id="rzp_order_id">
  <input type="hidden" name="razorpay_signature"  id="rzp_signature">
</form>

<!-- ═══ REMIT MODAL ═══ -->
<div class="modal-overlay" id="remitModal">
  <div class="modal-box">
    <div class="modal-icon">💸</div>
    <div class="modal-title">Remit COD Cash to Staff</div>
    <div class="modal-sub">
      Hand over the collected cash to staff. You keep your ₹<%=String.format("%.0f",pendingCharge)%> delivery charge.
    </div>
    <div class="modal-detail-box">
      <div class="modal-detail-row">
        <span style="color:var(--muted);">Cash You Collected</span>
        <span style="color:var(--text);font-family:var(--ff-head);">₹<%=String.format("%.0f",pendingCash)%></span>
      </div>
      <div class="modal-detail-row">
        <span style="color:var(--muted);">Your Delivery Charge (You Keep)</span>
        <span style="color:var(--green);font-family:var(--ff-head);">₹<%=String.format("%.0f",pendingCharge)%></span>
      </div>
      <div class="modal-detail-row">
        <span style="font-weight:700;">Hand to Staff</span>
        <span style="font-family:var(--ff-head);color:var(--brand);">₹<%=String.format("%.0f",pendingRemittance)%></span>
      </div>
      <% if(fromCashEst > 0){ %>
      <div class="modal-detail-row" style="background:var(--green-bg);border-radius:6px;padding:6px 8px;">
        <span style="color:var(--green);">↳ From Cash in Hand</span>
        <span style="color:var(--green);font-family:var(--ff-head);">₹<%=String.format("%.0f",fromCashEst)%></span>
      </div>
      <% } %>
      <% if(fromDepositEst > 0){ %>
      <div class="modal-detail-row" style="background:var(--amber-bg);border-radius:6px;padding:6px 8px;">
        <span style="color:var(--amber);font-weight:600;">↳ From Wallet</span>
        <span style="color:var(--amber);font-family:var(--ff-head);">₹<%=String.format("%.0f",fromDepositEst)%></span>
      </div>
      <% } %>
    </div>
    <p style="font-size:11px;color:var(--muted);margin:10px 0 0;text-align:center;">
      Give ₹<%=String.format("%.0f",pendingRemittance)%> cash to staff.<% if(pendingCharge>0){ %> You keep ₹<%=String.format("%.0f",pendingCharge)%> delivery charge.<% } %><%=fromDepositEst>0 ? " ₹"+String.format("%.0f",fromDepositEst)+" covered from your wallet." : ""%>
    </p>
    <div class="modal-actions">
      <button class="btn btn-ghost" onclick="closeRemitModal()">Cancel</button>
      <form action="codLedger" method="post" style="flex:2;display:flex;">
        <input type="hidden" name="action" value="remitAll">
        <button class="btn btn-brand" type="submit" style="width:100%;">
          <i class="fa fa-hand-holding-dollar"></i> Confirm Remittance
        </button>
      </form>
    </div>
  </div>
</div>

<!-- BOTTOM NAV -->
<nav class="bottom-nav">
  <a href="delivery-dashboard.jsp" class="nav-item">
    <i class="fa fa-house"></i><span class="nav-label">Home</span><div class="nav-indicator"></div>
  </a>
  <a href="delivery-dashboard.jsp" class="nav-item">
    <i class="fa fa-receipt"></i><span class="nav-label">Orders</span><div class="nav-indicator"></div>
  </a>
  <a href="delivery-earnings.jsp" class="nav-item active">
    <i class="fa fa-wallet"></i><span class="nav-label">Earnings</span><div class="nav-indicator"></div>
  </a>
  <a href="delivery-cash-ledger.jsp" class="nav-item">
    <i class="fa fa-coins"></i><span class="nav-label">COD</span><div class="nav-indicator"></div>
  </a>
  <a href="delivery-ratings.jsp" class="nav-item">
    <i class="fa fa-star"></i><span class="nav-label">Ratings</span><div class="nav-indicator"></div>
  </a>
  <a href="delivery-profile.jsp" class="nav-item">
    <i class="fa fa-user"></i><span class="nav-label">Profile</span><div class="nav-indicator"></div>
  </a>
</nav>

<script>
/* Dark mode */
function toggleDark(){
  const h=document.documentElement,d=h.getAttribute('data-theme')==='dark';
  h.setAttribute('data-theme',d?'light':'dark');
  localStorage.setItem('sibs-theme',d?'light':'dark');
}
(function(){const t=localStorage.getItem('sibs-theme');if(t)document.documentElement.setAttribute('data-theme',t);})();

/* Deposit modal */
function showDepositModal(){ document.getElementById('depositModal').classList.add('open'); }
function closeDepositModal(){ document.getElementById('depositModal').classList.remove('open'); }
document.getElementById('depositModal').addEventListener('click',function(e){
  if(e.target===this) closeDepositModal();
});

/* Razorpay Deposit */
function startRazorpayDeposit(){
  // Step 1: Create Razorpay order via GET (reuses existing PaymentService)
  fetch('deliveryDeposit?step=createOrder&amount=500')
    .then(r => r.json())
    .then(order => {
      if(order.error){ alert('Error: ' + order.error); return; }
      var options = {
        key: order.keyId,
        amount: order.amount,          // in paise
        currency: "INR",
        name: "SIBS Delivery",
        description: "Security Deposit - ₹500",
        order_id: order.razorpayOrderId,
        prefill: {
          name:  "<%=dbFresh.getName()%>",
          email: "<%=dbFresh.getEmail() != null ? dbFresh.getEmail() : ""%>",
          contact: "<%=dbFresh.getPhone() != null ? dbFresh.getPhone() : ""%>"
        },
        theme: { color: "#7c3aed" },
        handler: function(response){
          // Step 2: POST back to verify & record deposit
          document.getElementById('rzp_payment_id').value = response.razorpay_payment_id;
          document.getElementById('rzp_order_id').value   = response.razorpay_order_id;
          document.getElementById('rzp_signature').value  = response.razorpay_signature;
          document.getElementById('depositConfirmForm').submit();
        }
      };
      var rzp = new Razorpay(options);
      rzp.on('payment.failed', function(resp){
        alert('Payment failed: ' + resp.error.description);
      });
      closeDepositModal();
      rzp.open();
    })
    .catch(err => {
      alert('Could not initiate payment. Please try again.');
      console.error(err);
    });
}

/* Remit modal */
function showRemitModal(){ document.getElementById('remitModal').classList.add('open'); }
function closeRemitModal(){ document.getElementById('remitModal').classList.remove('open'); }
document.getElementById('remitModal').addEventListener('click',function(e){
  if(e.target===this) closeRemitModal();
});
</script>
</body>
</html>
