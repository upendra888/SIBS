
<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.util.*,com.sibs.dao.DeliveryBoyDAO,com.sibs.dao.CodLedgerDAO,com.sibs.dao.DeliverySlotDAO,com.sibs.dao.NotificationDAO,com.sibs.model.DeliveryAssignment,com.sibs.model.DeliveryBoy,com.sibs.model.DeliverySlot,com.sibs.model.Notification,com.sibs.util.AppSettings,com.sibs.util.DBConnection,java.sql.*" %>
<%
DeliveryBoy dbSession = (DeliveryBoy)session.getAttribute("deliveryBoy");
if(dbSession == null){ response.sendRedirect("delivery-login.jsp"); return; }

DeliveryBoyDAO dao = new DeliveryBoyDAO();

// ── Legacy 2-state toggle (kept for backward compat) ───────────────
String toggleAction = request.getParameter("toggleOnline");
if("1".equals(toggleAction)) {
    String toggleResult = dao.setOnlineStatus(dbSession.getId(), true);
    if("LOW_WALLET".equals(toggleResult)){
        session.setAttribute("onlineError", "⚠️ Wallet balance is too low. Add at least ₹200 to go online.");
    } else {
        dao.setShiftStatus(dbSession.getId(), "ONLINE");
    }
    response.sendRedirect("delivery-dashboard.jsp");
    return;
} else if("0".equals(toggleAction)) {
    dao.setOnlineStatus(dbSession.getId(), false);
    dao.setShiftStatus(dbSession.getId(), "OFFLINE");
    response.sendRedirect("delivery-dashboard.jsp");
    return;
}

// ── Cancel ride ────────────────────────────────────────────────────
String cancelAssignIdStr = request.getParameter("cancelRide");
if(cancelAssignIdStr != null && !cancelAssignIdStr.isEmpty()){
    try {
        int cancelAssignId = Integer.parseInt(cancelAssignIdStr);
        String cancelOrderIdStr = request.getParameter("cancelOrderId");
        int cancelOrderId = Integer.parseInt(cancelOrderIdStr);
        boolean cancelled = dao.cancelRide(cancelAssignId, cancelOrderId);
        response.sendRedirect("delivery-dashboard.jsp?rideCancel=" + (cancelled ? "success" : "fail"));
        return;
    } catch(Exception e){ e.printStackTrace(); }
}

// ── Reload fresh DB record ─────────────────────────────────────────
DeliveryBoy db = dao.getById(dbSession.getId());
if(db == null){ response.sendRedirect("delivery-login.jsp"); return; }
session.setAttribute("deliveryBoy", db);

// ── Wallet ─────────────────────────────────────────────────────────
double walletBalance = db.getWallet();
boolean walletOk     = walletBalance >= 200.0;

// ── Withdraw Request Status ─────────────────────────────────────────
java.util.List<String[]> dashWithdrawReqs = dao.getWithdrawRequestsFor(db.getId());
boolean dashHasPendingWithdraw = dashWithdrawReqs.stream().anyMatch(r -> "PENDING".equals(r[2]));
String dashLatestWithdrawStatus = dashWithdrawReqs.isEmpty() ? null : dashWithdrawReqs.get(0)[2];
String dashLatestWithdrawAmt    = dashWithdrawReqs.isEmpty() ? null : dashWithdrawReqs.get(0)[1];

// ── Shift status — always read from DB object, NOT from session ────
String shiftStatus = db.getShiftStatus();
if(shiftStatus == null || shiftStatus.isEmpty())
    shiftStatus = db.isOnline() ? "ONLINE" : "OFFLINE";
session.setAttribute("shiftStatus", shiftStatus); // keep session in sync

// ── Stats ──────────────────────────────────────────────────────────
List<DeliveryAssignment> assignments = dao.getAssignments(db.getId());
int total     = dao.getTotalAssignedToday(db.getId());
int pending   = dao.getPendingToday(db.getId());
int delivered = dao.getDeliveredToday(db.getId());

double kmToday = delivered * 3.2;

// ── Today's slot booking ─────────────────────────────────────────
DeliverySlotDAO slotDao = new DeliverySlotDAO();
DeliverySlot mySlot = slotDao.getTodayBooking(db.getId());

// ── Force offline if online but no active slot ────────────────────
boolean hasActiveSlot = (mySlot != null && "ACTIVE".equals(mySlot.getStatus()));
if (!hasActiveSlot && ("ONLINE".equals(shiftStatus) || "ON_BREAK".equals(shiftStatus))) {
    dao.setOnlineStatus(db.getId(), false);
    dao.setShiftStatus(db.getId(), "OFFLINE");
    db.setOnline(false);
    db.setShiftStatus("OFFLINE");
    session.setAttribute("deliveryBoy", db);
    session.setAttribute("shiftStatus", "OFFLINE");
    shiftStatus = "OFFLINE";
}

int deliveredOnlineToday = dao.getDeliveredTodayOnline(db.getId());
int deliveredCodToday    = dao.getDeliveredTodayCod(db.getId());
// Gross earnings = (Online + COD) × per-delivery rate
double perDeliveryPay = AppSettings.getPerDeliveryPay();
int grossEarningsToday = (int)((deliveredOnlineToday + deliveredCodToday) * perDeliveryPay);

// Subtract earnings already used for COD remittances today
double earningsUsedToday = 0;
try (Connection _eu = DBConnection.getConnection()) {
    _eu.createStatement().execute(
        "CREATE TABLE IF NOT EXISTS delivery_earnings_used (" +
        "  id INT AUTO_INCREMENT PRIMARY KEY," +
        "  delivery_boy_id INT NOT NULL," +
        "  amount DECIMAL(10,2) NOT NULL," +
        "  used_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP," +
        "  note VARCHAR(500)" +
        ")"
    );
    try (PreparedStatement _ps = _eu.prepareStatement(
           "SELECT COALESCE(SUM(amount),0) FROM delivery_earnings_used " +
           "WHERE delivery_boy_id=? AND DATE(used_at)=CURDATE()")) {
        _ps.setInt(1, db.getId());
        ResultSet _rs = _ps.executeQuery();
        if(_rs.next()) earningsUsedToday = _rs.getDouble(1);
    }
} catch(Exception _e) { _e.printStackTrace(); }

int earningsToday = (int) Math.max(0, grossEarningsToday - earningsUsedToday);

int onTimeRate = total > 0 ? (int)Math.round(((double)delivered / total) * 100) : 0;
if(onTimeRate > 98) onTimeRate = 96;
int acceptRate = total > 0 ? Math.min(100, (int)Math.round(((double)(total) / (total + 1)) * 100)) : 100;

DeliveryAssignment activeAssignment = null;
for(DeliveryAssignment a : assignments){
    String s = a.getStatus() != null ? a.getStatus().toUpperCase() : "";
    if(!"DELIVERED".equals(s)){ activeAssignment = a; break; }
}

// ── COD Auto-Offline Alert ────────────────────────────────────────────────
String codOfflineAlert = null;
try (Connection _codCon = DBConnection.getConnection()) {
    try (PreparedStatement _codPs = _codCon.prepareStatement(
            "SELECT cod_offline_alert FROM delivery_boys WHERE id = ?")) {
        _codPs.setInt(1, db.getId());
        try (ResultSet _codRs = _codPs.executeQuery()) {
            if (_codRs.next()) {
                String _alert = _codRs.getString("cod_offline_alert");
                if (_alert != null && !_alert.isEmpty()) {
                    double _avail = walletBalance + earningsToday;
                    codOfflineAlert = String.format(
                        "⚠️ You were taken <strong>Offline</strong> automatically because your " +
                        "wallet + today's earnings (<strong>₹%.0f + ₹%d = ₹%.0f</strong>) are less " +
                        "than the COD order amount. Please <strong>recharge your wallet</strong> and go Online again.",
                        walletBalance, earningsToday, _avail);
                    try (PreparedStatement _clrPs = _codCon.prepareStatement(
                            "UPDATE delivery_boys SET cod_offline_alert = NULL WHERE id = ?")) {
                        _clrPs.setInt(1, db.getId());
                        _clrPs.executeUpdate();
                    }
                }
            }
        }
    }
} catch (Exception _codEx) { }

// ── Flash messages ─────────────────────────────────────────────────
String successMsg="", errorMsg="";
String sessionError   = (String)session.getAttribute("onlineError");
String sessionSuccess = (String)session.getAttribute("onlineSuccess");
if(sessionError   != null){ errorMsg   = sessionError;   session.removeAttribute("onlineError"); }
if(sessionSuccess != null){ successMsg = sessionSuccess; session.removeAttribute("onlineSuccess"); }

if("success".equals(request.getParameter("delivered")))  successMsg="Delivered successfully!";
if("success".equals(request.getParameter("pickup")))     successMsg="Pickup confirmed! Show QR to customer at doorstep.";
if("success".equals(request.getParameter("rideCancel"))) successMsg="Ride cancelled. Order returned to staff for reassignment.";
if("1".equals(request.getParameter("delivery_cancelled"))) successMsg="Order cancelled. Stock restored and customer notified.";
if("fail".equals(request.getParameter("rideCancel")))       errorMsg="Cannot cancel — order already picked up.";
if("wrong_otp".equals(request.getParameter("error")))        errorMsg="Wrong OTP. Ask the customer to scan again.";
if("otp_required".equals(request.getParameter("error")))     errorMsg="Delivery can only be confirmed by customer OTP/QR scan.";
if("shift_low_wallet".equals(request.getParameter("error"))) errorMsg="⚠️ Wallet balance below ₹200. Recharge to go online.";
if("recharged".equals(request.getParameter("flash"))) successMsg="✅ Wallet recharged successfully! You're ready to go online.";
if("reported".equals(request.getParameter("failed_delivery")))       successMsg="⚠️ Reported to staff. Customer will be contacted to reschedule.";
if("cannot_cancel_now".equals(request.getParameter("error")))         errorMsg="Cannot cancel — order is not in a cancellable state.";
if("delivery_cancel_failed".equals(request.getParameter("error")))    errorMsg="Cancel failed. Please try again or contact support.";
if("report_failed".equals(request.getParameter("error")))             errorMsg="Failed to report. Please try again or contact support.";

boolean isOnlineNow = db.isOnline();
boolean isOffline   = "OFFLINE".equals(shiftStatus);
boolean isBreak     = "ON_BREAK".equals(shiftStatus);
boolean isOnline    = "ONLINE".equals(shiftStatus);

String initials = db.getName().length() >= 2
    ? db.getName().substring(0,2).toUpperCase()
    : db.getName().toUpperCase();

int bonusTarget   = 500;
int bonusProgress = Math.min(earningsToday, bonusTarget);
int deliveriesForBonus = bonusTarget > earningsToday ? (int)Math.ceil((bonusTarget - earningsToday) / perDeliveryPay) : 0;

// ── CHANGE 1: Load real notifications from DB ──────────────────────
NotificationDAO notifDao = new NotificationDAO();
int unreadCount = notifDao.countUnreadForDeliveryBoy(db.getId());
List<Notification> recentNotifs = notifDao.getForDeliveryBoy(db.getId(), 5);
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1">
<title>Delivery Partner · SIBS</title>
<link href="https://fonts.googleapis.com/css2?family=Syne:wght@400;500;600;700;800&family=DM+Sans:wght@300;400;500;600&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/leaflet.min.css">
<script src="https://cdnjs.cloudflare.com/ajax/libs/qrcodejs/1.0.0/qrcode.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/leaflet.min.js"></script>
<style>
:root {
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
body{min-height:100vh;padding-bottom:80px;}
a{text-decoration:none;color:inherit;}
button{font-family:var(--ff-body);cursor:pointer;}

/* TOPBAR */
.topbar{background:var(--surface);border-bottom:1px solid var(--border);padding:0 18px;height:60px;
  display:flex;align-items:center;justify-content:space-between;
  position:sticky;top:0;z-index:200;box-shadow:var(--shadow);}
.topbar-brand{display:flex;align-items:center;gap:10px;}
.brand-icon{width:36px;height:36px;background:var(--brand);border-radius:10px;
  display:flex;align-items:center;justify-content:center;color:#fff;
  font-family:var(--ff-head);font-weight:800;font-size:16px;letter-spacing:-1px;}
.brand-name{font-family:var(--ff-head);font-weight:700;font-size:15px;letter-spacing:-.3px;}
.brand-sub{font-size:10px;color:var(--muted);margin-top:-1px;}
.topbar-actions{display:flex;align-items:center;gap:8px;}

/* ── 3-State shift toggle ── */
.shift-toggle-group{display:flex;align-items:center;gap:2px;background:var(--bg);
  border:1px solid var(--border);border-radius:999px;padding:3px;}
.shift-btn{padding:5px 10px;border-radius:999px;font-size:11px;font-weight:700;
  border:none;cursor:pointer;background:transparent;color:var(--muted);
  transition:all .2s;display:flex;align-items:center;gap:3px;white-space:nowrap;}
.shift-btn.active-online {background:var(--green);color:#fff;}
.shift-btn.active-break  {background:var(--amber);color:#fff;}
.shift-btn.active-offline{background:var(--red);color:#fff;}
.shift-btn.shift-disabled{opacity:.4;cursor:not-allowed;pointer-events:none;}

.icon-btn{width:36px;height:36px;border:1px solid var(--border);border-radius:var(--radius-sm);
  background:var(--bg);color:var(--muted);display:flex;align-items:center;justify-content:center;
  cursor:pointer;font-size:14px;transition:all .2s;position:relative;}
.icon-btn:hover{background:var(--brand-light);color:var(--brand);}
.notif-badge{position:absolute;top:-4px;right:-4px;width:16px;height:16px;border-radius:50%;
  background:var(--red);color:#fff;font-size:9px;font-weight:700;
  display:flex;align-items:center;justify-content:center;border:2px solid var(--surface);}
.avatar-chip{display:flex;align-items:center;gap:8px;padding:5px 12px 5px 5px;
  border:1px solid var(--border);border-radius:999px;background:var(--surface);cursor:pointer;}
.avatar-circle{width:28px;height:28px;border-radius:50%;background:var(--brand);color:#fff;
  display:flex;align-items:center;justify-content:center;font-size:11px;font-weight:600;}
.avatar-name{font-size:12px;font-weight:500;}
.logout-link{padding:6px 14px;background:var(--brand);color:#fff;border:none;
  border-radius:var(--radius-sm);font-size:12px;font-weight:600;transition:opacity .2s;}
.logout-link:hover{opacity:.85;}

/* PAGE */
.page{padding:16px 16px 0;max-width:960px;margin:0 auto;}

/* FLASH */
.flash{display:flex;align-items:center;gap:10px;padding:13px 16px;border-radius:var(--radius-sm);
  font-size:13px;font-weight:500;margin-bottom:16px;animation:slideDown .3s ease;}
@keyframes slideDown{from{opacity:0;transform:translateY(-8px);}to{opacity:1;transform:none;}}
.flash-success{background:var(--green-bg);color:var(--green);border:1px solid rgba(22,163,74,.2);}
.flash-error  {background:var(--red-bg);color:var(--red);border:1px solid rgba(220,38,38,.2);}

/* ── WALLET BAR ── */
.wallet-bar{display:flex;align-items:center;justify-content:space-between;
  background:var(--surface);border:1px solid var(--border);border-radius:var(--radius);
  padding:12px 16px;margin-bottom:14px;gap:14px;flex-wrap:wrap;}
.wallet-left{display:flex;align-items:center;gap:12px;}
.wallet-icon-wrap{width:38px;height:38px;border-radius:10px;
  background:linear-gradient(135deg,#064e3b,#16a34a);
  display:flex;align-items:center;justify-content:center;font-size:16px;flex-shrink:0;}
.wallet-label{font-size:11px;color:var(--muted);text-transform:uppercase;letter-spacing:.05em;}
.wallet-amount{font-family:var(--ff-head);font-size:20px;font-weight:700;line-height:1.1;color:var(--green);}
.wallet-warn{display:inline-flex;align-items:center;gap:5px;margin-top:3px;
  font-size:11px;color:var(--red);font-weight:600;}
.wallet-recharge-btn{padding:8px 16px;background:var(--brand);color:#fff;border:none;
  border-radius:var(--radius-sm);font-size:12px;font-weight:700;cursor:pointer;
  white-space:nowrap;flex-shrink:0;text-decoration:none;
  display:inline-flex;align-items:center;gap:6px;}
.wallet-recharge-btn:hover{opacity:.88;}

/* EARNINGS BANNER */
.earnings-banner{background:linear-gradient(135deg,#2e1065,#4c1d95,#6d28d9);
  border-radius:var(--radius);padding:20px;margin-bottom:14px;
  display:flex;align-items:center;justify-content:space-between;gap:16px;
  flex-wrap:wrap;color:#fff;overflow:hidden;position:relative;}
.earnings-banner::before{content:'';position:absolute;right:-40px;top:-40px;
  width:160px;height:160px;border-radius:50%;background:rgba(255,255,255,.04);}
.earn-main{position:relative;z-index:1;}
.earn-greeting{font-size:11px;opacity:.6;margin-bottom:3px;letter-spacing:.4px;
  text-transform:uppercase;font-family:var(--ff-head);}
.earn-amount{font-family:var(--ff-head);font-size:32px;font-weight:800;letter-spacing:-1px;line-height:1;}
.earn-sub{font-size:11px;opacity:.55;margin-top:5px;}
.earn-stats{display:flex;gap:0;position:relative;z-index:1;}
.earn-stat{text-align:center;padding:8px 20px;border-left:1px solid rgba(255,255,255,.12);}
.earn-stat:first-child{border-left:none;}
.earn-stat-num{font-family:var(--ff-head);font-size:20px;font-weight:700;color:#e9d5ff;}
.earn-stat-lbl{font-size:10px;opacity:.5;margin-top:2px;text-transform:uppercase;letter-spacing:.4px;}

/* BONUS STRIP */
.bonus-strip{background:var(--surface);border:1px solid var(--border);border-radius:var(--radius);
  padding:14px 16px;margin-bottom:14px;display:flex;align-items:center;gap:14px;}
.bonus-icon{width:38px;height:38px;border-radius:10px;background:linear-gradient(135deg,#f59e0b,#d97706);
  display:flex;align-items:center;justify-content:center;font-size:16px;flex-shrink:0;}
.bonus-info{flex:1;}
.bonus-title{font-size:13px;font-weight:700;font-family:var(--ff-head);}
.bonus-sub{font-size:11px;color:var(--muted);margin-top:2px;}
.bonus-bar-track{height:6px;background:var(--bg2);border-radius:999px;margin-top:8px;overflow:hidden;}
.bonus-bar-fill{height:100%;border-radius:999px;background:linear-gradient(90deg,#f59e0b,#d97706);transition:width .6s ease;}
.bonus-pct{font-family:var(--ff-head);font-size:13px;font-weight:700;color:#d97706;flex-shrink:0;}

/* STATS */
.stat-row{display:grid;grid-template-columns:repeat(4,1fr);gap:10px;margin-bottom:14px;}
.stat-card{background:var(--surface);border:1px solid var(--border);border-radius:var(--radius);
  padding:14px;transition:transform .2s,box-shadow .2s;}
.stat-card:hover{transform:translateY(-2px);box-shadow:var(--shadow);}
.stat-icon{width:32px;height:32px;border-radius:9px;display:flex;align-items:center;
  justify-content:center;font-size:14px;margin-bottom:10px;}
.stat-num{font-family:var(--ff-head);font-size:24px;font-weight:700;line-height:1;}
.stat-lbl{font-size:11px;color:var(--muted);margin-top:4px;}

/* QUICK STATS */
.quick-stats{display:grid;grid-template-columns:1fr 1fr 1fr;gap:10px;margin-bottom:14px;}
.qs-card{background:var(--surface);border:1px solid var(--border);border-radius:var(--radius);
  padding:13px 16px;display:flex;align-items:center;gap:12px;}
.qs-icon{width:36px;height:36px;border-radius:10px;display:flex;align-items:center;
  justify-content:center;font-size:15px;flex-shrink:0;}
.qs-label{font-size:11px;color:var(--muted);}
.qs-value{font-family:var(--ff-head);font-size:18px;font-weight:700;margin-top:1px;}

/* SECTION LABEL */
.section-label{display:flex;align-items:center;justify-content:space-between;margin-bottom:10px;}
.section-label h2{font-family:var(--ff-head);font-size:14px;font-weight:700;letter-spacing:-.2px;}
.badge-count{font-size:11px;font-weight:600;padding:3px 9px;border-radius:999px;
  background:var(--brand-light);color:var(--brand);}

/* FILTER BAR */
.filter-bar{display:flex;gap:8px;margin-bottom:14px;flex-wrap:wrap;}
.search-wrap{flex:1;min-width:200px;position:relative;}
.search-wrap i{position:absolute;left:12px;top:50%;transform:translateY(-50%);color:var(--muted);font-size:13px;}
.search-input{width:100%;padding:10px 14px 10px 36px;border:1px solid var(--border);
  border-radius:var(--radius-sm);background:var(--surface);color:var(--text);
  font-family:var(--ff-body);font-size:13px;outline:none;transition:border-color .2s;}
.search-input:focus{border-color:var(--brand);}
.filter-select{padding:10px 14px;border:1px solid var(--border);border-radius:var(--radius-sm);
  background:var(--surface);color:var(--text);font-family:var(--ff-body);font-size:13px;outline:none;cursor:pointer;}

/* ACTIVE SPOTLIGHT */
.active-spotlight{background:var(--surface);border:2px solid var(--brand);border-radius:var(--radius);
  overflow:hidden;margin-bottom:14px;animation:borderPulse 3s ease-in-out infinite;}
@keyframes borderPulse{0%,100%{box-shadow:0 0 0 4px rgba(124,58,237,.06);}50%{box-shadow:0 0 0 6px rgba(124,58,237,.12);}}
.spotlight-header{background:linear-gradient(90deg,#4c1d95,#6d28d9);padding:12px 16px;
  display:flex;justify-content:space-between;align-items:center;}
.spotlight-title{font-family:var(--ff-head);font-size:13px;font-weight:700;color:#fff;
  display:flex;align-items:center;gap:8px;}
.live-dot-anim{width:8px;height:8px;background:#a3e635;border-radius:50%;display:inline-block;
  animation:blink 1.4s ease-in-out infinite;}
@keyframes blink{0%,100%{opacity:1;transform:scale(1);}50%{opacity:.4;transform:scale(.8);}}
.spotlight-meta{display:flex;gap:8px;align-items:center;}
.spotlight-badge{font-size:11px;padding:3px 10px;border-radius:999px;font-weight:600;
  background:rgba(255,255,255,.15);color:#fff;}
.spotlight-body{padding:16px;display:grid;grid-template-columns:1fr auto;gap:16px;}
@media(max-width:600px){.spotlight-body{grid-template-columns:1fr;}}

/* ETA STRIP */
.eta-strip{display:flex;gap:10px;margin-bottom:12px;}
.eta-chip{flex:1;background:var(--bg);border:1px solid var(--border);border-radius:var(--radius-sm);
  padding:8px 12px;display:flex;align-items:center;gap:8px;}
.eta-chip i{color:var(--brand);font-size:13px;}
.eta-label{font-size:10px;color:var(--muted);}
.eta-val{font-size:13px;font-weight:700;font-family:var(--ff-head);}

/* PROGRESS */
.progress-track{display:flex;align-items:center;background:var(--bg);border-radius:var(--radius-sm);
  padding:12px 14px;margin-bottom:14px;gap:0;}
.prog-step{display:flex;flex-direction:column;align-items:center;gap:4px;flex-shrink:0;}
.prog-circle{width:28px;height:28px;border-radius:50%;display:flex;align-items:center;
  justify-content:center;font-size:11px;font-weight:700;transition:all .3s;}
.prog-done  {background:var(--green);color:#fff;}
.prog-active{background:var(--brand);color:#fff;box-shadow:0 0 0 4px rgba(124,58,237,.2);}
.prog-idle  {background:var(--bg2);color:var(--muted);border:1.5px solid var(--border);}
.prog-label {font-size:9px;color:var(--muted);text-align:center;white-space:nowrap;}
.prog-line  {flex:1;height:2px;background:var(--border);margin:0 4px;margin-bottom:14px;transition:background .3s;}
.prog-line-done{background:var(--green);}

/* CUSTOMER ROW */
.cust-row{display:flex;align-items:center;gap:12px;margin-bottom:12px;}
.cust-avatar{width:42px;height:42px;border-radius:50%;background:var(--brand-light);
  display:flex;align-items:center;justify-content:center;font-size:14px;font-weight:700;
  color:var(--brand);flex-shrink:0;}
.cust-info{flex:1;}
.cust-name{font-size:14px;font-weight:600;}
.cust-phone{font-size:12px;color:var(--muted);margin-top:1px;}

/* ADDRESS BOX */
.addr-box{display:flex;align-items:flex-start;gap:8px;background:var(--bg);
  border:1px solid var(--border);border-radius:var(--radius-sm);
  padding:10px 12px;margin-bottom:12px;font-size:12px;color:var(--muted);}
.addr-box i{color:var(--brand);margin-top:1px;flex-shrink:0;}
.maps-btn{margin-left:auto;font-size:11px;font-weight:600;color:var(--brand);
  background:var(--brand-light);border:1px solid rgba(124,58,237,.2);
  padding:4px 10px;border-radius:6px;white-space:nowrap;flex-shrink:0;
  display:flex;align-items:center;gap:4px;cursor:pointer;}

/* NAV MAP */
.nav-map-panel{display:none;margin-top:10px;border-radius:var(--radius-sm);overflow:hidden;border:1px solid var(--border);}
.nav-map-el{width:100%;height:260px;}
.nav-map-actions{display:flex;gap:8px;padding:10px;background:var(--surface);border-top:1px solid var(--border);}

/* BUTTONS */
.btn{padding:11px 20px;border:none;border-radius:var(--radius-sm);font-size:13px;font-weight:600;
  font-family:var(--ff-body);display:inline-flex;align-items:center;justify-content:center;
  gap:7px;transition:all .2s;cursor:pointer;}
.btn:hover{transform:translateY(-1px);}
.btn:active{transform:scale(.97);}
.btn-brand  {background:var(--brand);color:#fff;flex:2;}
.btn-brand:hover{background:#6d28d9;}
.btn-ghost  {background:var(--bg);color:var(--text);border:1px solid var(--border);flex:1;}
.btn-ghost:hover{background:var(--bg2);}
.btn-danger {background:var(--red-bg);color:var(--red);border:1px solid rgba(220,38,38,.2);}
.btn-danger:hover{background:#fecaca;}
.btn-success{background:var(--green-bg);color:var(--green);border:1px solid rgba(22,163,74,.2);flex:2;}
.btn-success:hover{background:#bbf7d0;}
.action-row {display:flex;gap:8px;flex-wrap:wrap;}

/* PHOTO PROOF */
.proof-section{margin-bottom:12px;}
.proof-label{font-size:11px;color:var(--muted);font-weight:600;margin-bottom:8px;display:flex;align-items:center;gap:6px;}
.proof-upload-area{border:2px dashed var(--border);border-radius:var(--radius-sm);
  padding:16px;text-align:center;cursor:pointer;transition:all .2s;background:var(--bg);}
.proof-upload-area:hover{border-color:var(--brand);background:var(--brand-light);}
.proof-upload-icon{font-size:22px;color:var(--muted);margin-bottom:6px;}
.proof-upload-text{font-size:12px;color:var(--muted);}
.proof-preview{display:none;position:relative;}
.proof-preview img{width:100%;border-radius:var(--radius-sm);max-height:180px;object-fit:cover;}
.proof-retake{position:absolute;bottom:8px;right:8px;background:rgba(0,0,0,.65);color:#fff;
  border:none;border-radius:6px;padding:5px 10px;font-size:11px;font-weight:600;cursor:pointer;}
.proof-status{font-size:11px;margin-top:6px;color:var(--green);font-weight:500;display:none;}
#proofInput{display:none;}

/* QR PANEL */
.qr-panel{background:linear-gradient(160deg,#1e1b4b,#2e1065);border-radius:var(--radius);
  padding:16px;text-align:center;min-width:200px;}
.qr-panel-title{font-family:var(--ff-head);font-size:11px;font-weight:700;color:#c4b5fd;
  letter-spacing:.6px;text-transform:uppercase;margin-bottom:4px;}
.qr-panel-sub{font-size:10px;color:rgba(196,181,253,.5);margin-bottom:12px;}
.qr-box-wrap{background:#fff;border-radius:10px;padding:12px;display:inline-block;margin-bottom:12px;}
.qr-hint{font-size:10px;color:rgba(196,181,253,.5);margin-bottom:10px;}
.otp-fallback{background:rgba(255,255,255,.06);border-radius:9px;padding:10px 12px;}
.otp-label{font-size:9px;color:rgba(196,181,253,.4);letter-spacing:.5px;text-transform:uppercase;margin-bottom:4px;}
.otp-digits{font-size:26px;font-weight:800;font-family:'Syne',monospace;letter-spacing:8px;color:#a78bfa;}
.otp-sub{font-size:9px;color:rgba(196,181,253,.3);margin-top:3px;}

/* PAID ONLINE BANNER */
.paid-online-banner{background:var(--green-bg);border:1px solid rgba(22,163,74,.2);
  border-radius:var(--radius-sm);padding:12px 14px;margin-bottom:12px;
  display:flex;align-items:center;gap:10px;}
.paid-online-banner i{color:var(--green);font-size:18px;}
.paid-online-text{font-size:12px;}
.paid-online-text strong{display:block;color:var(--green);font-size:13px;margin-bottom:1px;}
.paid-online-text span{color:#166534;opacity:.8;}

/* CANCEL */
.cancel-row{margin-top:8px;display:flex;flex-direction:column;gap:4px;}
.cancel-hint{font-size:10px;color:var(--muted);text-align:center;}

/* ORDER CARDS */
.orders-list{display:flex;flex-direction:column;gap:10px;}
.order-card{background:var(--surface);border:1px solid var(--border);
  border-radius:var(--radius);overflow:hidden;transition:box-shadow .2s,transform .2s;}
.order-card:hover{box-shadow:var(--shadow);transform:translateY(-1px);}
.order-card.active-border{border-color:rgba(124,58,237,.4);}
.card-header{padding:12px 16px;display:flex;justify-content:space-between;
  align-items:center;border-bottom:1px solid var(--border);gap:10px;}
.card-header-left{flex:1;}
.order-num{font-family:var(--ff-head);font-size:14px;font-weight:700;}
.order-product{font-size:12px;color:var(--muted);margin-top:1px;}
.card-header-right{display:flex;align-items:center;gap:8px;flex-shrink:0;}
.order-amount{font-family:var(--ff-head);font-size:15px;font-weight:700;color:var(--brand);}
.status-badge{padding:4px 10px;border-radius:999px;font-size:11px;font-weight:600;white-space:nowrap;}
.s-assigned {background:var(--amber-bg);color:var(--amber);}
.s-picked   {background:var(--blue-bg);color:var(--blue);}
.s-delivered{background:var(--green-bg);color:var(--green);}
.card-body  {padding:14px 16px;}
.compact-cust{display:flex;align-items:center;gap:10px;margin-bottom:10px;}
.compact-avtr{width:34px;height:34px;border-radius:50%;background:var(--bg);
  border:1px solid var(--border);display:flex;align-items:center;justify-content:center;
  font-size:11px;font-weight:700;color:var(--muted);flex-shrink:0;}
.compact-cust-info{flex:1;}
.compact-cust-name{font-size:13px;font-weight:500;}
.compact-cust-phone{font-size:11px;color:var(--muted);}
.payment-chip{font-size:10px;font-weight:600;padding:3px 8px;border-radius:6px;
  background:var(--bg);color:var(--muted);border:1px solid var(--border);}
.payment-chip.cod   {background:var(--amber-bg);color:var(--amber);}
.payment-chip.online{background:var(--blue-bg);color:var(--blue);}
.delivered-row{display:flex;align-items:center;gap:6px;font-size:12px;color:var(--green);font-weight:500;}
.completed-meta{display:flex;gap:10px;flex-wrap:wrap;margin-top:8px;}
.completed-chip{font-size:11px;padding:4px 10px;border-radius:6px;
  background:var(--bg);color:var(--muted);border:1px solid var(--border);
  display:flex;align-items:center;gap:5px;}

/* EMPTY STATE */
.empty-state{text-align:center;padding:60px 20px;color:var(--muted);}
.empty-icon{font-size:48px;opacity:.25;margin-bottom:12px;display:block;}
.empty-title{font-family:var(--ff-head);font-size:16px;font-weight:700;margin-bottom:6px;color:var(--text);}

/* OFFLINE BANNER */
.offline-banner{background:var(--red-bg);border:1px solid rgba(220,38,38,.2);
  border-radius:var(--radius);padding:16px 20px;display:flex;align-items:center;gap:12px;margin-bottom:14px;}
.offline-banner i{font-size:20px;color:var(--red);}
.offline-title{font-size:14px;font-weight:600;color:var(--red);}
.offline-sub{font-size:12px;color:var(--muted);margin-top:2px;}

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
  max-width:360px;width:100%;box-shadow:var(--shadow-lg);animation:modalIn .25s ease;}
@keyframes modalIn{from{opacity:0;transform:scale(.95);}to{opacity:1;transform:none;}}
.modal-icon{font-size:36px;text-align:center;margin-bottom:12px;}
.modal-title{font-family:var(--ff-head);font-size:17px;font-weight:700;text-align:center;margin-bottom:6px;}
.modal-sub{font-size:13px;color:var(--muted);text-align:center;margin-bottom:20px;}
.modal-actions{display:flex;gap:10px;}
.modal-actions .btn{flex:1;}
.wallet-low-body{background:var(--red-bg);border-radius:var(--radius-sm);
  padding:12px 14px;margin-bottom:16px;font-size:13px;color:var(--red);
  display:flex;align-items:center;gap:8px;}

/* ── CHANGE 2: NOTIFICATION PANEL — dynamic styles ── */
.notif-panel{display:none;position:fixed;top:68px;right:16px;z-index:250;
  background:var(--surface);border:1px solid var(--border);border-radius:var(--radius);
  width:320px;box-shadow:var(--shadow-lg);animation:modalIn .2s ease;}
.notif-panel.open{display:block;}
.notif-header{padding:12px 16px;border-bottom:1px solid var(--border);
  display:flex;justify-content:space-between;align-items:center;}
.notif-header-title{font-family:var(--ff-head);font-size:13px;font-weight:700;}
.notif-clear{font-size:11px;color:var(--brand);cursor:pointer;font-weight:600;}
.notif-item{padding:12px 16px;border-bottom:1px solid var(--border);
  display:flex;gap:10px;align-items:flex-start;cursor:pointer;transition:background .15s;
  text-decoration:none;color:inherit;}
.notif-item:hover{background:var(--bg);}
.notif-item.unread{background:rgba(124,58,237,.04);border-left:3px solid var(--brand);}
.notif-item:last-child{border-bottom:none;}
.notif-dot{width:8px;height:8px;border-radius:50%;background:var(--brand);flex-shrink:0;margin-top:4px;}
.notif-dot.read{background:var(--border);}
.notif-text{font-size:12px;line-height:1.5;font-weight:500;}
.notif-msg{font-size:11px;color:var(--muted);margin-top:2px;line-height:1.4;}
.notif-time{font-size:10px;color:var(--muted);margin-top:3px;}
.notif-empty{padding:28px 16px;text-align:center;color:var(--muted);font-size:13px;}
.notif-footer{padding:10px 16px;border-top:1px solid var(--border);text-align:center;}
.notif-footer a{font-size:12px;color:var(--brand);font-weight:600;}

/* SOS BUTTON */
.sos-btn{position:fixed;bottom:90px;right:16px;z-index:150;width:50px;height:50px;
  border-radius:50%;background:var(--red);color:#fff;border:none;font-size:11px;
  font-weight:800;font-family:var(--ff-head);box-shadow:0 4px 16px rgba(220,38,38,.4);
  cursor:pointer;display:flex;flex-direction:column;align-items:center;justify-content:center;
  gap:1px;transition:transform .2s,box-shadow .2s;letter-spacing:.5px;}
.sos-btn:hover{transform:scale(1.08);box-shadow:0 6px 24px rgba(220,38,38,.55);}
.shift-running{animation:shiftPulse 2s ease-in-out infinite;}
@keyframes shiftPulse{0%,100%{opacity:1;}50%{opacity:.65;}}

@media(max-width:640px){
  .stat-row{grid-template-columns:repeat(2,1fr);}
  .earn-stats{display:none;}
  .topbar-actions .avatar-chip .avatar-name{display:none;}
  .sos-btn{bottom:86px;}
  .quick-stats{grid-template-columns:1fr 1fr;}
  .quick-stats .qs-card:last-child{grid-column:1/-1;}
}
</style>
</head>
<body>

<!-- ══════════ TOPBAR ══════════ -->
<div class="topbar">
  <div class="topbar-brand">
    <div class="brand-icon">S</div>
    <div>
      <div class="brand-name">SIBS Delivery</div>
      <div class="brand-sub">Partner App</div>
    </div>
  </div>
  <div class="topbar-actions">

    <div class="shift-toggle-group">
      <button type="button"
              class="shift-btn <%=isOnline?"active-online":""%> <%=!walletOk?"shift-disabled":""%>"
              onclick="setShift('ONLINE')"
              title="<%=!walletOk?"Recharge wallet (min ₹200) to go online":"Go Online"%>">
        <i class="fa fa-circle" style="font-size:8px;"></i>Online
      </button>
      <button type="button"
              class="shift-btn <%=isBreak?"active-break":""%>"
              onclick="setShift('ON_BREAK')">
        <i class="fa fa-pause" style="font-size:8px;"></i>Break
      </button>
      <button type="button"
              class="shift-btn <%=isOffline?"active-offline":""%>"
              onclick="setShift('OFFLINE')">
        <i class="fa fa-moon" style="font-size:8px;"></i>Offline
      </button>
    </div>

    <%-- CHANGE 2: Bell shows real unread count from DB --%>
    <button class="icon-btn" onclick="toggleNotifPanel()" id="notifBtn" title="Notifications">
      <i class="fa fa-bell"></i>
      <span class="notif-badge" id="notifBadge" style="<%=unreadCount==0?"display:none;":""%>">
        <%=unreadCount > 99 ? "99+" : unreadCount%>
      </span>
    </button>
    <button class="icon-btn" onclick="toggleDark()"><i class="fa fa-moon"></i></button>
    <div class="avatar-chip" onclick="window.location='delivery-profile.jsp'">
      <div class="avatar-circle"><%=initials%></div>
      <span class="avatar-name"><%=db.getName()%></span>
    </div>
    <a href="deliveryLogout" class="logout-link"><i class="fa fa-sign-out-alt"></i> Logout</a>
  </div>
</div>

<%-- CHANGE 3: Notification Panel — real data from DB + dynamic polling --%>
<div class="notif-panel" id="notifPanel">
  <div class="notif-header">
    <span class="notif-header-title">🔔 Notifications</span>
    <span class="notif-clear" onclick="markAllRead()">Mark all read</span>
  </div>
  <div id="notifList">
    <%
      java.util.Map<String,String> catIcons = new java.util.LinkedHashMap<>();
      catIcons.put("DELIVERY","🛵"); catIcons.put("ORDER","📦");
      catIcons.put("PAYMENT","💰"); catIcons.put("ACCOUNT","👤");
      catIcons.put("COMPLAINT","📣"); catIcons.put("LEAVE","🏖️");

      if(recentNotifs == null || recentNotifs.isEmpty()){
    %>
      <div class="notif-empty">
        <div style="font-size:28px;margin-bottom:8px;">🔕</div>
        No notifications yet
      </div>
    <% } else {
        for(Notification n : recentNotifs){
          String ic = catIcons.containsKey(n.getCategory()) ? catIcons.get(n.getCategory()) : "🔔";
          String linkHref = (n.getLinkUrl() != null && !n.getLinkUrl().isEmpty()) ? n.getLinkUrl() : "#";
    %>
      <a href="<%=linkHref%>"
         class="notif-item <%=!n.isRead()?"unread":""%>"
         onclick="<%=!n.isRead()?"markOneRead("+n.getId()+",this);":""%>">
        <span class="notif-dot <%=n.isRead()?"read":""%>"></span>
        <div style="flex:1;min-width:0;">
          <div style="display:flex;align-items:center;gap:6px;">
            <span><%=ic%></span>
            <span class="notif-text"><%=n.getTitle()%></span>
          </div>
          <div class="notif-msg"><%=n.getMessage()%></div>
          <div class="notif-time"><%=n.getRelativeTime()%></div>
        </div>
      </a>
    <%  }
      } %>
  </div>
  <div class="notif-footer">
    <a href="delivery-notifications.jsp">View all notifications →</a>
  </div>
</div>

<!-- ══════════ PAGE ══════════ -->
<div class="page">

  <% if(!successMsg.isEmpty()){ %>
    <div class="flash flash-success"><i class="fa fa-circle-check"></i> <%=successMsg%></div>
  <% } %>
  <% if(!errorMsg.isEmpty()){ %>
    <div class="flash flash-error"><i class="fa fa-circle-xmark"></i> <%=errorMsg%></div>
  <% } %>

  <% if(codOfflineAlert != null){ %>
  <div class="cod-offline-alert" style="
      background:#fff3cd;border:1.5px solid #ffc107;border-radius:12px;
      padding:14px 16px;margin-bottom:14px;display:flex;align-items:flex-start;gap:12px;">
    <i class="fa fa-triangle-exclamation" style="color:#e65c00;font-size:20px;margin-top:2px;flex-shrink:0;"></i>
    <div style="flex:1;">
      <div style="font-weight:700;color:#7a3800;font-size:14px;margin-bottom:4px;">
        💸 Insufficient Funds — You've been taken Offline
      </div>
      <div style="font-size:13px;color:#5a3200;line-height:1.5;"><%=codOfflineAlert%></div>
      <a href="delivery-wallet.jsp" style="
          display:inline-block;margin-top:10px;padding:8px 18px;
          background:#e65c00;color:#fff;border-radius:8px;font-weight:600;
          font-size:13px;text-decoration:none;">
        <i class="fa fa-wallet"></i> Recharge Wallet &amp; Go Online
      </a>
    </div>
  </div>
  <% } %>

  <% if(!isOnlineNow){ %>
  <div class="offline-banner">
    <i class="fa fa-wifi-slash"></i>
    <div>
      <div class="offline-title">You are Offline</div>
      <div class="offline-sub">
        <%=!walletOk
          ? "Recharge your wallet to at least ₹200, then tap Online to start receiving orders."
          : "Tap Online above to start receiving new delivery orders."%>
      </div>
    </div>
  </div>
  <% } %>

  <!-- ── WALLET BAR ─────────────────────────────────────── -->
  <div class="wallet-bar">
    <div class="wallet-left">
      <div class="wallet-icon-wrap"><i class="fa fa-wallet" style="color:#fff;"></i></div>
      <div>
        <div class="wallet-label">Wallet Balance</div>
        <div class="wallet-amount">₹<%= String.format("%.2f", walletBalance) %></div>
        <% if(!walletOk){ %>
        <div class="wallet-warn"><i class="fa fa-exclamation-circle"></i> Min ₹200 required to go online</div>
        <% } %>
        <% if(dashHasPendingWithdraw) { %>
        <div style="margin-top:4px;font-size:11px;color:var(--amber);display:flex;align-items:center;gap:4px;font-weight:600;">
          <i class="fa fa-clock"></i> Withdraw pending staff approval
        </div>
        <% } else if("APPROVED".equals(dashLatestWithdrawStatus)) { %>
        <div style="margin-top:4px;font-size:11px;color:var(--green);display:flex;align-items:center;gap:4px;font-weight:600;">
          <i class="fa fa-check-circle"></i> Last withdraw approved ✅
        </div>
        <% } %>
      </div>
    </div>
    <div style="display:flex;flex-direction:column;gap:6px;align-items:flex-end;">
      <a href="delivery-wallet.jsp" class="wallet-recharge-btn">
        <i class="fa fa-plus"></i> Recharge
      </a>
      <% if(!dashHasPendingWithdraw && walletBalance > 200) { %>
      <a href="delivery-wallet.jsp#withdraw" style="padding:5px 12px;background:transparent;color:var(--brand);border:1.5px solid var(--brand);border-radius:var(--radius-sm);font-size:11px;font-weight:700;text-decoration:none;display:flex;align-items:center;gap:5px;">
        <i class="fa fa-paper-plane"></i> Withdraw
      </a>
      <% } else if(dashHasPendingWithdraw) { %>
      <span style="padding:5px 12px;background:var(--amber-bg);color:var(--amber);border-radius:var(--radius-sm);font-size:11px;font-weight:700;display:flex;align-items:center;gap:5px;">
        <i class="fa fa-clock"></i> Pending
      </span>
      <% } %>
    </div>
  </div>

  <!-- ── EARNINGS BANNER ───────────────────────────────── -->
  <div class="earnings-banner">
    <div class="earn-main">
      <div class="earn-greeting">Today's Earnings</div>
      <div class="earn-amount">₹<%=earningsToday%></div>
      <div class="earn-sub"><%=delivered>0?"🎯 Great work today!":"Complete deliveries to start earning"%></div>
    </div>
    <div class="earn-stats">
      <div class="earn-stat"><div class="earn-stat-num"><%=total%></div><div class="earn-stat-lbl">Trips</div></div>
      <div class="earn-stat"><div class="earn-stat-num"><%=acceptRate%>%</div><div class="earn-stat-lbl">Accept rate</div></div>
      <div class="earn-stat"><div class="earn-stat-num">⭐ <%=delivered>0?"4.9":"–"%></div><div class="earn-stat-lbl">Rating</div></div>
    </div>
  </div>

  <!-- ── BONUS STRIP ───────────────────────────────────── -->
  <div class="bonus-strip">
    <div class="bonus-icon">🎯</div>
    <div class="bonus-info">
      <div class="bonus-title">Daily Bonus Goal</div>
      <div class="bonus-sub">
        <% if(deliveriesForBonus>0){ %>Deliver <%=deliveriesForBonus%> more to earn ₹50 bonus! (₹<%=earningsToday%>/₹<%=bonusTarget%>)
        <% } else { %>🎉 Bonus unlocked! You've hit ₹<%=bonusTarget%> today.<% } %>
      </div>
      <div class="bonus-bar-track">
        <div class="bonus-bar-fill" style="width:<%=(int)Math.min(100,(bonusProgress*100.0/bonusTarget))%>%;"></div>
      </div>
    </div>
    <div class="bonus-pct"><%=(int)Math.min(100,(bonusProgress*100.0/bonusTarget))%>%</div>
  </div>

  <!-- ── STATS GRID ────────────────────────────────────── -->
  <div class="stat-row">
    <div class="stat-card">
      <div class="stat-icon" style="background:var(--brand-light);"><i class="fa fa-clipboard-list" style="color:var(--brand);"></i></div>
      <div class="stat-num"><%=total%></div><div class="stat-lbl">Total Assigned</div>
    </div>
    <div class="stat-card">
      <div class="stat-icon" style="background:var(--amber-bg);"><i class="fa fa-clock" style="color:var(--amber);"></i></div>
      <div class="stat-num" style="color:var(--amber);"><%=pending%></div><div class="stat-lbl">Pending</div>
    </div>
    <div class="stat-card">
      <div class="stat-icon" style="background:var(--green-bg);"><i class="fa fa-circle-check" style="color:var(--green);"></i></div>
      <div class="stat-num" style="color:var(--green);"><%=delivered%></div><div class="stat-lbl">Delivered</div>
    </div>
    <div class="stat-card">
      <div class="stat-icon" style="background:var(--blue-bg);"><i class="fa fa-route" style="color:var(--blue);"></i></div>
      <div class="stat-num" style="color:var(--blue);"><%=onTimeRate>0?onTimeRate+"%":"–"%></div><div class="stat-lbl">On-Time Rate</div>
    </div>
  </div>

  <!-- ── QUICK STATS ────────────────────────────────────── -->
  <div class="quick-stats">
    <div class="qs-card">
      <div class="qs-icon" style="background:var(--orange-bg);"><i class="fa fa-gas-pump" style="color:var(--orange);"></i></div>
      <div>
        <div class="qs-label">Distance Today</div>
        <div class="qs-value" style="color:var(--orange);"><%=String.format("%.1f",kmToday)%> km</div>
      </div>
    </div>
    <div class="qs-card">
      <div class="qs-icon" style="background:var(--brand-light);"><i class="fa fa-stopwatch" style="color:var(--brand);"></i></div>
      <div>
        <div class="qs-label">Shift Timer</div>
        <div class="qs-value shift-running" id="shiftTimer" style="color:var(--brand);">
          <%=isOffline?"––:––:––":"00:00:00"%>
        </div>
      </div>
    </div>
    <div class="qs-card">
      <div class="qs-icon" style="background:var(--amber-bg);"><i class="fa fa-mug-hot" style="color:var(--amber);"></i></div>
      <div>
        <div class="qs-label">Break Time</div>
        <div class="qs-value" id="breakTimer" style="color:var(--amber);">
          <%=isOffline?"––:––:––":"00:00:00"%>
        </div>
      </div>
    </div>
  </div>

  <%-- TODAY'S SLOT CARD --%>
  <% if(mySlot != null) {
       String slotBg    = "ACTIVE".equals(mySlot.getStatus())  ? "var(--green-bg)"  :
                          "BOOKED".equals(mySlot.getStatus())  ? "var(--blue-bg)"   : "var(--amber-bg)";
       String slotColor = "ACTIVE".equals(mySlot.getStatus())  ? "var(--green)"     :
                          "BOOKED".equals(mySlot.getStatus())  ? "var(--blue)"      : "var(--amber)";
  %>
  <div style="margin-bottom:14px;padding:14px 16px;background:var(--surface);
       border-radius:var(--radius);border:1px solid var(--border);
       display:flex;align-items:center;justify-content:space-between;gap:10px;">
    <div style="display:flex;align-items:center;gap:12px;">
      <div style="width:40px;height:40px;background:var(--brand-light);border-radius:10px;
           flex-shrink:0;display:flex;align-items:center;justify-content:center;">
        <i class="fa fa-calendar-check" style="color:var(--brand);font-size:16px;"></i>
      </div>
      <div>
        <div style="font-size:11px;color:var(--muted);font-weight:500;margin-bottom:2px;">Today's Slot</div>
        <div style="font-size:14px;font-weight:700;"><%=mySlot.getSlotName()%>
          <span style="font-size:11px;color:var(--muted);font-weight:400;">
            &nbsp;<%=mySlot.getStartTime()%> – <%=mySlot.getEndTime()%>
          </span>
        </div>
      </div>
    </div>
    <div style="display:flex;align-items:center;gap:8px;flex-shrink:0;">
      <span style="padding:4px 12px;border-radius:999px;font-size:11px;font-weight:700;
           background:<%=slotBg%>;color:<%=slotColor%>;"><%=mySlot.getStatus()%></span>
      <a href="delivery-slot-booking.jsp"
         style="font-size:11px;font-weight:600;color:var(--brand);white-space:nowrap;">Change →</a>
    </div>
  </div>
  <% } else { %>
  <div style="margin-bottom:14px;padding:12px 16px;background:var(--bg2);
       border-radius:var(--radius);border:1.5px dashed var(--border);
       display:flex;align-items:center;justify-content:space-between;gap:10px;">
    <div style="display:flex;align-items:center;gap:10px;">
      <i class="fa fa-calendar-xmark" style="color:var(--muted);font-size:18px;"></i>
      <span style="font-size:13px;color:var(--muted);">No delivery slot booked for today</span>
    </div>
    <a href="delivery-slot-booking.jsp"
       style="padding:6px 14px;background:var(--brand);color:#fff;border-radius:var(--radius-sm);
              font-size:12px;font-weight:700;text-decoration:none;white-space:nowrap;">
      Book Slot
    </a>
  </div>
  <% } %>

  <!-- ═══ ACTIVE SPOTLIGHT ═══ -->
  <% if(activeAssignment != null) {
    String statusUpper = activeAssignment.getStatus() != null ? activeAssignment.getStatus().toUpperCase() : "";
    boolean isCOD = "COD".equals(activeAssignment.getPaymentMethod());
    boolean activeIsReturnPickup = activeAssignment.isReturnPickup();
    int step = 0;
    if("PICKED_UP".equals(statusUpper)||"OTP_VERIFIED".equals(statusUpper)) step=2;
    else if("DELIVERED".equals(statusUpper)) step=3;
    String qrData="";
    if(isCOD && activeAssignment.getOtp()!=null && step==2)
        qrData="SIBS-DELIVER|orderId="+activeAssignment.getOrderId()+"|assignId="+activeAssignment.getId()+"|otp="+activeAssignment.getOtp();
    String activeInit=activeAssignment.getCustomerName().length()>=2?activeAssignment.getCustomerName().substring(0,2).toUpperCase():activeAssignment.getCustomerName().toUpperCase();
    String stepLabel="Assigned"; String badgeCls="s-assigned";
    if("PICKED_UP".equals(statusUpper)){stepLabel="Picked Up";badgeCls="s-picked";}
    if("OTP_VERIFIED".equals(statusUpper)){stepLabel="Awaiting Scan";badgeCls="s-picked";}
    double aLat=activeAssignment.getDestLat(),aLng=activeAssignment.getDestLng();
    boolean hasCoords=aLat!=0&&aLng!=0;
    int etaMin=5; double estKm=2.4;
    String c1="prog-circle prog-done";
    String c2,c3,c4,l1,l2,l3;
    if(isCOD){
      c2=step>=2?"prog-circle prog-done":step==0?"prog-circle prog-active":"prog-circle prog-idle";
      c3=step>=3?"prog-circle prog-done":step==2?"prog-circle prog-active":"prog-circle prog-idle";
      c4=step>=3?"prog-circle prog-done":"prog-circle prog-idle";
      l1=step>=2?"prog-line prog-line-done":"prog-line"; l2=step>=3?"prog-line prog-line-done":"prog-line"; l3=l2;
    } else {
      c2=step>=2?"prog-circle prog-done":step==0?"prog-circle prog-active":"prog-circle prog-idle";
      c3=step>=3?"prog-circle prog-done":step==2?"prog-circle prog-active":"prog-circle prog-idle";
      c4=""; l1=step>=2?"prog-line prog-line-done":"prog-line"; l2=step>=3?"prog-line prog-line-done":"prog-line"; l3="";
    }
  %>
  <div class="section-label" style="margin-bottom:8px;">
    <h2><span class="live-dot-anim" style="display:inline-block;margin-right:6px;"></span>Active Order</h2>
  </div>
  <div class="active-spotlight">
    <div class="spotlight-header">
      <div class="spotlight-title"><span class="live-dot-anim"></span>
        <% if(activeIsReturnPickup){ %><span style="background:#fef3c7;color:#92400e;font-size:10px;padding:2px 7px;border-radius:999px;margin-right:6px;font-weight:700;">📦 RETURN PICKUP</span><% } %>
        Order #<%=activeAssignment.getOrderId()%> · <%=activeAssignment.getProductName()%> ×<%=activeAssignment.getQuantity()%></div>
      <div class="spotlight-meta">
        <span class="spotlight-badge">₹<%=(int)activeAssignment.getAmount()%></span>
        <span class="spotlight-badge"><%=stepLabel%></span>
      </div>
    </div>
    <div class="spotlight-body">
      <div class="spotlight-left">
        <div class="eta-strip">
          <div class="eta-chip"><i class="fa fa-clock"></i><div><div class="eta-label">Est. ETA</div><div class="eta-val"><%=etaMin%> min</div></div></div>
          <div class="eta-chip"><i class="fa fa-road"></i><div><div class="eta-label">Distance</div><div class="eta-val">~<%=String.format("%.1f",estKm)%> km</div></div></div>
          <div class="eta-chip"><i class="fa fa-indian-rupee-sign"></i><div><div class="eta-label">Order Value</div><div class="eta-val">₹<%=(int)activeAssignment.getAmount()%></div></div></div>
        </div>
        <div class="progress-track">
          <div class="prog-step"><div class="<%=c1%>"><i class="fa fa-check" style="font-size:10px;"></i></div><div class="prog-label">Assigned</div></div>
          <div class="<%=l1%>"></div>
          <div class="prog-step"><div class="<%=c2%>"><%=step>=2?"<i class='fa fa-check' style='font-size:10px;'></i>":"2"%></div><div class="prog-label">Picked Up</div></div>
          <% if(isCOD){ %>
            <div class="<%=l2%>"></div>
            <div class="prog-step"><div class="<%=c3%>"><%=step>=3?"<i class='fa fa-check' style='font-size:10px;'></i>":"3"%></div><div class="prog-label">Scan</div></div>
            <div class="<%=l3%>"></div>
            <div class="prog-step"><div class="<%=c4%>"><%=step>=3?"<i class='fa fa-check' style='font-size:10px;'></i>":"4"%></div><div class="prog-label">Delivered</div></div>
          <% } else { %>
            <div class="<%=l2%>"></div>
            <div class="prog-step"><div class="<%=c3%>"><%=step>=3?"<i class='fa fa-check' style='font-size:10px;'></i>":"3"%></div><div class="prog-label">Delivered</div></div>
          <% } %>
        </div>
        <div class="cust-row">
          <div class="cust-avatar"><%=activeInit%></div>
          <div class="cust-info">
            <div class="cust-name"><%=activeAssignment.getCustomerName()%></div>
            <div class="cust-phone"><%=activeAssignment.getCustomerPhone()%></div>
          </div>
        </div>
        <div class="addr-box">
          <i class="fa fa-location-dot"></i>
          <span><%=activeAssignment.getDeliveryAddress()%></span>
          <% if(hasCoords){ %>
            <button type="button" class="maps-btn" onclick="toggleNavMap('navSpotlight',<%=aLat%>,<%=aLng%>,<%=activeAssignment.getOrderId()%>)">
              <i class="fa fa-map-location-dot"></i> Navigate
            </button>
          <% } else { String encA=java.net.URLEncoder.encode(activeAssignment.getDeliveryAddress(),"UTF-8"); %>
            <a href="https://www.google.com/maps/search/?api=1&query=<%=encA%>" target="_blank" class="maps-btn"><i class="fa fa-map-location-dot"></i> Maps</a>
          <% } %>
        </div>
        <div class="nav-map-panel" id="navSpotlight">
          <div class="nav-map-el" id="navMapSpotlight"></div>
          <div class="nav-map-actions">
            <button class="btn btn-ghost" onclick="toggleNavMap('navSpotlight',0,0,0)" style="flex:1;"><i class="fa fa-xmark"></i> Close</button>
            <a id="extLinkSpotlight" href="#" target="_blank" class="btn btn-brand" style="flex:2;justify-content:center;"><i class="fa fa-diamond-turn-right"></i> Google Maps</a>
          </div>
        </div>
        <% if("ASSIGNED".equals(statusUpper)){ %>
          <div class="action-row">
            <form action="confirmPickup" method="post" style="flex:2;display:flex;">
              <input type="hidden" name="assignmentId" value="<%=activeAssignment.getId()%>">
              <% if(activeIsReturnPickup){ %><input type="hidden" name="returnId" value="<%=activeAssignment.getReturnId()%>"><% } %>
              <button class="btn btn-brand" type="submit" style="width:100%;">
                <i class="fa fa-box"></i>
                <%=activeIsReturnPickup ? "Collect Wrong Item from Customer" : "Confirm Pickup"%>
              </button>
            </form>
            <a href="tel:<%=activeAssignment.getCustomerPhone()%>" class="btn btn-ghost"><i class="fa fa-phone"></i> Call</a>
          </div>
          <div class="cancel-row">
            <button class="btn btn-danger" onclick="showCancelModal(<%=activeAssignment.getId()%>,<%=activeAssignment.getOrderId()%>)" style="width:100%;"><i class="fa fa-ban"></i> Cancel Ride</button>
            <span class="cancel-hint">Only cancel if you cannot complete this delivery.</span>
          </div>
        <% } else if("PICKED_UP".equals(statusUpper)||"OTP_VERIFIED".equals(statusUpper)){ %>
          <% if(!isCOD){ %>
            <div class="paid-online-banner"><i class="fa fa-circle-check"></i><div class="paid-online-text"><strong>Payment Done Online</strong><span>Just hand over and mark done.</span></div></div>
            <div class="proof-section">
              <div class="proof-label"><i class="fa fa-camera" style="color:var(--brand);"></i> Photo Proof of Delivery</div>
              <div class="proof-upload-area" id="proofArea" onclick="document.getElementById('proofInput').click()">
                <div class="proof-upload-icon"><i class="fa fa-camera"></i></div>
                <div class="proof-upload-text">Tap to take a photo at doorstep</div>
              </div>
              <div class="proof-preview" id="proofPreview"><img id="proofImg" src="" alt="Proof"><button class="proof-retake" onclick="retakeProof()"><i class="fa fa-rotate-right"></i> Retake</button></div>
              <div class="proof-status" id="proofStatus"><i class="fa fa-circle-check"></i> Photo captured</div>
              <input type="file" id="proofInput" accept="image/*" capture="environment" onchange="previewProof(this)">
            </div>
            <div class="action-row">
              <form action="markDelivered" method="post" style="flex:2;display:flex;">
                <input type="hidden" name="assignmentId" value="<%=activeAssignment.getId()%>">
                <input type="hidden" name="orderId" value="<%=activeAssignment.getOrderId()%>">
                <% if(activeIsReturnPickup){ %><input type="hidden" name="returnId" value="<%=activeAssignment.getReturnId()%>"><% } %>
                <button class="btn btn-success" type="submit"
                  onclick="return confirm('<%=activeIsReturnPickup ? "Confirm item received from customer?" : "Mark as delivered?"%>')"
                  style="width:100%;">
                  <i class="fa fa-circle-check"></i>
                  <%=activeIsReturnPickup ? "Confirm Item Received" : "Mark as Delivered"%>
                </button>
              </form>
              <a href="tel:<%=activeAssignment.getCustomerPhone()%>" class="btn btn-ghost"><i class="fa fa-phone"></i> Call</a>
            </div>
          <% } else { %>
            <div class="action-row"><a href="tel:<%=activeAssignment.getCustomerPhone()%>" class="btn btn-ghost" style="flex:1;justify-content:center;"><i class="fa fa-phone"></i> Call Customer</a></div>
          <% } %>
          <div class="cancel-row" style="margin-top:8px;">
            <button class="btn btn-danger" onclick="showFailedModal(<%=activeAssignment.getId()%>,<%=activeAssignment.getOrderId()%>)" style="width:100%;"><i class="fa fa-user-slash"></i> Customer Not Responding</button>
            <span class="cancel-hint">Use if customer is unreachable or not at address.</span>
          </div>
          <div class="cancel-row" style="margin-top:4px;">
            <button class="btn btn-danger" onclick="showDeliveryCancelModal(<%=activeAssignment.getId()%>,<%=activeAssignment.getOrderId()%>)" style="width:100%;"><i class="fa fa-circle-xmark"></i> Cancel Order</button>
            <span class="cancel-hint">Wrong address, customer refused, etc.</span>
          </div>
        <% } %>
      </div>
      <% if(isCOD&&!qrData.isEmpty()){ %>
      <div class="spotlight-right">
        <div class="qr-panel">
          <div class="qr-panel-title"><i class="fa fa-qrcode"></i> Show to Customer</div>
          <div class="qr-panel-sub">Customer scans to confirm</div>
          <div class="qr-box-wrap" id="qrSpotlight"></div>
          <div class="qr-hint"><i class="fa fa-mobile-screen" style="font-size:12px;margin-right:4px;"></i>My Orders → Scan QR</div>
          <div class="otp-fallback"><div class="otp-label">Fallback OTP</div><div class="otp-digits"><%=activeAssignment.getOtp()%></div><div class="otp-sub">If scan fails, type this</div></div>
        </div>
      </div>
      <script>new QRCode(document.getElementById("qrSpotlight"),{text:"<%=qrData%>",width:150,height:150,colorDark:"#1e1b4b",colorLight:"#ffffff",correctLevel:QRCode.CorrectLevel.H});</script>
      <% } %>
    </div>
  </div>
  <% } %>

  <!-- ═══ ALL ASSIGNMENTS ═══ -->
  <div style="margin-top:18px;">
    <div class="section-label">
      <h2>All Assignments</h2>
      <span class="badge-count"><%=total%> today</span>
    </div>
    <div class="filter-bar">
      <div class="search-wrap"><i class="fa fa-magnifying-glass"></i><input type="text" class="search-input" id="search" placeholder="Search orders, customers…" oninput="applyFilters()"></div>
      <select class="filter-select" id="statusFilter" onchange="applyFilters()">
        <option value="All">All Status</option>
        <option value="ASSIGNED">Assigned</option>
        <option value="PICKED_UP">Picked Up</option>
        <option value="DELIVERED">Delivered</option>
      </select>
    </div>
    <div class="orders-list" id="assignTable">
    <% if(assignments.isEmpty()){ %>
      <div class="empty-state"><i class="fa fa-box-open empty-icon"></i><div class="empty-title">No assignments yet</div><div class="empty-sub">Your deliveries will appear here once assigned.</div></div>
    <% } else { for(DeliveryAssignment da:assignments){
        String su=da.getStatus()!=null?da.getStatus().toUpperCase():"";
        boolean isActive=!"DELIVERED".equals(su);
        boolean daCOD="COD".equals(da.getPaymentMethod());
        boolean daIsReturnPickup=da.isReturnPickup();
        int dStep=0;String dBadge="s-assigned",dLabel="Assigned";
        if("PICKED_UP".equals(su)){dStep=2;dBadge="s-picked";dLabel="Picked Up";}
        else if("OTP_VERIFIED".equals(su)){dStep=2;dBadge="s-picked";dLabel="Awaiting Scan";}
        else if("DELIVERED".equals(su)){dStep=3;dBadge="s-delivered";dLabel="Delivered";}
        String daInit=da.getCustomerName().length()>=2?da.getCustomerName().substring(0,2).toUpperCase():da.getCustomerName().toUpperCase();
        String daQr="";
        if(daCOD&&da.getOtp()!=null&&dStep==2) daQr="SIBS-DELIVER|orderId="+da.getOrderId()+"|assignId="+da.getId()+"|otp="+da.getOtp();
        double dLat=da.getDestLat(),dLng=da.getDestLng();
        boolean dHas=dLat!=0&&dLng!=0;
        String mpId="navMap"+da.getId(),meId="navMapEl"+da.getId();
        String dc1="prog-circle prog-done";
        String dc2=dStep>=2?"prog-circle prog-done":dStep==0?"prog-circle prog-active":"prog-circle prog-idle";
        String dc3=dStep>=3?"prog-circle prog-done":dStep==2?"prog-circle prog-active":"prog-circle prog-idle";
        String dl1=dStep>=2?"prog-line prog-line-done":"prog-line";
        String dl2=dStep>=3?"prog-line prog-line-done":"prog-line";
    %>
      <div class="<%=isActive?"order-card active-border":"order-card"%>"
           data-status="<%=su%>"
           data-text="<%=da.getCustomerName().toLowerCase()%> <%=da.getOrderId()%> <%=da.getProductName().toLowerCase()%>">
        <div class="card-header">
          <div class="card-header-left">
            <% if(daIsReturnPickup){ %><div style="font-size:10px;color:#92400e;background:#fef3c7;padding:2px 7px;border-radius:999px;font-weight:700;margin-bottom:3px;display:inline-block;">📦 RETURN PICKUP</div><% } %>
            <div class="order-num">#<%=da.getOrderId()%></div><div class="order-product"><%=da.getProductName()%> × <%=da.getQuantity()%></div></div>
          <div class="card-header-right"><div class="order-amount">₹<%=(int)da.getAmount()%></div><span class="status-badge <%=dBadge%>"><%=dLabel%></span></div>
        </div>
        <div class="card-body">
          <div class="progress-track" style="padding:10px;margin-bottom:12px;">
            <div class="prog-step"><div class="<%=dc1%>" style="width:22px;height:22px;font-size:9px;"><i class="fa fa-check"></i></div><div class="prog-label">Assigned</div></div>
            <div class="<%=dl1%>"></div>
            <div class="prog-step"><div class="<%=dc2%>" style="width:22px;height:22px;font-size:9px;"><%=dStep>=2?"<i class='fa fa-check'></i>":"2"%></div><div class="prog-label">Picked Up</div></div>
            <% if(daCOD){ String dc3b=dStep>=3?"prog-circle prog-done":dStep==2?"prog-circle prog-active":"prog-circle prog-idle"; String dl3b=dStep>=3?"prog-line prog-line-done":"prog-line"; String dc4b=dStep>=3?"prog-circle prog-done":"prog-circle prog-idle"; %>
              <div class="<%=dl2%>"></div>
              <div class="prog-step"><div class="<%=dc3b%>" style="width:22px;height:22px;font-size:9px;"><%=dStep>=3?"<i class='fa fa-check'></i>":"3"%></div><div class="prog-label">Scan</div></div>
              <div class="<%=dl3b%>"></div>
              <div class="prog-step"><div class="<%=dc4b%>" style="width:22px;height:22px;font-size:9px;"><%=dStep>=3?"<i class='fa fa-check'></i>":"4"%></div><div class="prog-label">Done</div></div>
            <% } else { %>
              <div class="<%=dl2%>"></div>
              <div class="prog-step"><div class="<%=dc3%>" style="width:22px;height:22px;font-size:9px;"><%=dStep>=3?"<i class='fa fa-check'></i>":"3"%></div><div class="prog-label">Delivered</div></div>
            <% } %>
          </div>
          <div class="compact-cust">
            <div class="compact-avtr"><%=daInit%></div>
            <div class="compact-cust-info"><div class="compact-cust-name"><%=da.getCustomerName()%></div><div class="compact-cust-phone"><%=da.getCustomerPhone()%></div></div>
            <span class="<%=daCOD?"payment-chip cod":"payment-chip online"%>"><%=daCOD?"💵 COD":"💳 Online"%></span>
          </div>
          <div class="addr-box">
            <i class="fa fa-location-dot"></i>
            <span><%=da.getDeliveryAddress()%></span>
            <% if(dHas){ %>
              <button type="button" class="maps-btn" onclick="toggleNavMap('<%=mpId%>',<%=dLat%>,<%=dLng%>,<%=da.getOrderId()%>,'<%=meId%>','extLink<%=da.getId()%>')"><i class="fa fa-map-location-dot"></i> Navigate</button>
            <% } else { String encD=java.net.URLEncoder.encode(da.getDeliveryAddress(),"UTF-8"); %>
              <a href="https://www.google.com/maps/search/?api=1&query=<%=encD%>" target="_blank" class="maps-btn"><i class="fa fa-map-location-dot"></i> Maps</a>
            <% } %>
          </div>
          <div class="nav-map-panel" id="<%=mpId%>">
            <div class="nav-map-el" id="<%=meId%>"></div>
            <div class="nav-map-actions">
              <button class="btn btn-ghost" onclick="toggleNavMap('<%=mpId%>',0,0,0,'<%=meId%>','extLink<%=da.getId()%>')" style="flex:1;"><i class="fa fa-xmark"></i> Close</button>
              <a id="extLink<%=da.getId()%>" href="#" target="_blank" class="btn btn-brand" style="flex:2;justify-content:center;"><i class="fa fa-diamond-turn-right"></i> Google Maps</a>
            </div>
          </div>
          <% if("ASSIGNED".equals(su)){ %>
            <div class="action-row">
              <form action="confirmPickup" method="post" style="flex:2;display:flex;">
                <input type="hidden" name="assignmentId" value="<%=da.getId()%>">
                <% if(daIsReturnPickup){ %><input type="hidden" name="returnId" value="<%=da.getReturnId()%>"><% } %>
                <button class="btn btn-brand" type="submit" style="width:100%;">
                  <i class="fa fa-box"></i>
                  <%=daIsReturnPickup ? "Collect Wrong Item from Customer" : "Confirm Pickup"%>
                </button>
              </form>
              <a href="tel:<%=da.getCustomerPhone()%>" class="btn btn-ghost"><i class="fa fa-phone"></i> Call</a>
            </div>
            <div class="cancel-row"><button class="btn btn-danger" onclick="showCancelModal(<%=da.getId()%>,<%=da.getOrderId()%>)" style="width:100%;"><i class="fa fa-ban"></i> Cancel Ride</button><span class="cancel-hint">Only cancel if you cannot deliver.</span></div>
          <% } else if(("PICKED_UP".equals(su)||"OTP_VERIFIED".equals(su))&&!daCOD){ %>
            <% if(!daIsReturnPickup){ %>
            <div class="paid-online-banner"><i class="fa fa-circle-check"></i><div class="paid-online-text"><strong>Payment Done Online</strong><span>Just hand over and mark delivered.</span></div></div>
            <% } %>
            <div class="action-row">
              <form action="markDelivered" method="post" style="flex:2;display:flex;">
                <input type="hidden" name="assignmentId" value="<%=da.getId()%>">
                <input type="hidden" name="orderId" value="<%=da.getOrderId()%>">
                <% if(daIsReturnPickup){ %><input type="hidden" name="returnId" value="<%=da.getReturnId()%>"><% } %>
                <button class="btn btn-success" type="submit"
                  onclick="return confirm('<%=daIsReturnPickup ? "Confirm item received from customer?" : "Mark as delivered?"%>')"
                  style="width:100%;">
                  <i class="fa fa-circle-check"></i>
                  <%=daIsReturnPickup ? "Confirm Item Received" : "Mark as Delivered"%>
                </button>
              </form>
              <a href="tel:<%=da.getCustomerPhone()%>" class="btn btn-ghost"><i class="fa fa-phone"></i> Call</a>
            </div>
            <div class="cancel-row" style="margin-top:8px;"><button class="btn btn-danger" onclick="showFailedModal(<%=da.getId()%>,<%=da.getOrderId()%>)" style="width:100%;"><i class="fa fa-user-slash"></i> Customer Not Responding</button><span class="cancel-hint">Customer unreachable or not at address.</span></div>
            <div class="cancel-row" style="margin-top:4px;"><button class="btn btn-danger" onclick="showDeliveryCancelModal(<%=da.getId()%>,<%=da.getOrderId()%>)" style="width:100%;"><i class="fa fa-circle-xmark"></i> Cancel Order</button><span class="cancel-hint">Wrong address, customer refused, etc.</span></div>
          <% } else if(("PICKED_UP".equals(su)||"OTP_VERIFIED".equals(su))&&daCOD&&!daQr.isEmpty()){ %>
            <div class="qr-panel" style="margin-bottom:10px;">
              <div class="qr-panel-title"><i class="fa fa-qrcode"></i> Show QR to Customer</div>
              <div class="qr-panel-sub">Customer scans to confirm delivery</div>
              <div class="qr-box-wrap" id="qr-<%=da.getId()%>"></div>
              <div class="qr-hint"><i class="fa fa-mobile-screen" style="font-size:12px;margin-right:4px;"></i>My Orders → Scan QR</div>
              <div class="otp-fallback"><div class="otp-label">Fallback OTP</div><div class="otp-digits"><%=da.getOtp()%></div><div class="otp-sub">Type this if scan fails</div></div>
            </div>
            <div class="action-row"><a href="tel:<%=da.getCustomerPhone()%>" class="btn btn-ghost" style="flex:1;justify-content:center;"><i class="fa fa-phone"></i> Call Customer</a></div>
            <div class="cancel-row" style="margin-top:8px;"><button class="btn btn-danger" onclick="showFailedModal(<%=da.getId()%>,<%=da.getOrderId()%>)" style="width:100%;"><i class="fa fa-user-slash"></i> Customer Not Responding</button><span class="cancel-hint">Customer unreachable or not at address.</span></div>
            <div class="cancel-row" style="margin-top:4px;"><button class="btn btn-danger" onclick="showDeliveryCancelModal(<%=da.getId()%>,<%=da.getOrderId()%>)" style="width:100%;"><i class="fa fa-circle-xmark"></i> Cancel Order</button><span class="cancel-hint">Wrong address, customer refused, etc.</span></div>
            <script>(function(){new QRCode(document.getElementById("qr-<%=da.getId()%>"),{text:"<%=daQr%>",width:150,height:150,colorDark:"#1e1b4b",colorLight:"#ffffff",correctLevel:QRCode.CorrectLevel.H});})();</script>
          <% } else if("DELIVERED".equals(su)){ %>
            <div class="delivered-row"><i class="fa fa-circle-check"></i> Delivered on <%=da.getDeliveredAt()!=null?da.getDeliveredAt():"today"%></div>
            <div class="completed-meta">
              <div class="completed-chip"><i class="fa fa-road"></i> ~3.2 km</div>
              <div class="completed-chip"><i class="fa fa-clock"></i> ~18 min</div>
              <div class="completed-chip"><i class="fa fa-indian-rupee-sign"></i> ₹<%= (int)perDeliveryPay %> earned</div>
            </div>
          <% } %>
        </div>
      </div>
    <% } } %>
    </div>
  </div>

</div><!-- /page -->

<!-- SOS -->
<button class="sos-btn" onclick="showSOSModal()" title="Emergency SOS">
  <i class="fa fa-triangle-exclamation"></i><span>SOS</span>
</button>

<!-- BOTTOM NAV -->
<nav class="bottom-nav">
  <a href="delivery-dashboard.jsp"    class="nav-item active"><i class="fa fa-house"></i><span class="nav-label">Home</span><div class="nav-indicator"></div></a>
  <a href="delivery-orders.jsp"       class="nav-item"><i class="fa fa-receipt"></i><span class="nav-label">Orders</span><div class="nav-indicator"></div></a>
  <a href="delivery-slot-booking.jsp" class="nav-item"><i class="fa fa-calendar-check"></i><span class="nav-label">Slots</span><div class="nav-indicator"></div></a>
  <a href="delivery-earnings.jsp"     class="nav-item"><i class="fa fa-wallet"></i><span class="nav-label">Earnings</span><div class="nav-indicator"></div></a>
  <a href="delivery-cash-ledger.jsp"  class="nav-item"><i class="fa fa-coins"></i><span class="nav-label">COD</span><div class="nav-indicator"></div></a>
  <a href="delivery-ratings.jsp"      class="nav-item"><i class="fa fa-star"></i><span class="nav-label">Ratings</span><div class="nav-indicator"></div></a>
  <a href="delivery-profile.jsp"      class="nav-item"><i class="fa fa-user"></i><span class="nav-label">Profile</span><div class="nav-indicator"></div></div></a>
</nav>

<!-- ════ MODALS ════ -->
<div class="modal-overlay" id="cancelModal">
  <div class="modal-box">
    <div class="modal-icon">🚫</div><div class="modal-title">Cancel this ride?</div>
    <div class="modal-sub">The order will be returned to staff for reassignment.</div>
    <div class="modal-actions">
      <button class="btn btn-ghost" onclick="closeModal('cancelModal')">Never mind</button>
      <form action="delivery-dashboard.jsp" method="post" style="flex:1;display:flex;">
        <input type="hidden" name="cancelRide"    id="modalCancelAssign">
        <input type="hidden" name="cancelOrderId" id="modalCancelOrder">
        <button class="btn btn-danger" type="submit" style="width:100%;"><i class="fa fa-ban"></i> Yes, Cancel</button>
      </form>
    </div>
  </div>
</div>

<div class="modal-overlay" id="failedDeliveryModal">
  <div class="modal-box">
    <div class="modal-icon">📵</div><div class="modal-title">Customer Not Responding?</div>
    <div class="modal-sub">Staff will contact the customer and reschedule or cancel.</div>
    <form action="reportFailedDelivery" method="post" style="width:100%;">
      <input type="hidden" name="assignmentId" id="failedAssignmentId">
      <input type="hidden" name="orderId"      id="failedOrderId">
      <textarea name="note" placeholder="Optional details…"
        style="width:100%;margin:12px 0;padding:10px;border-radius:8px;border:1.5px solid var(--border);font-size:13px;resize:none;font-family:inherit;background:var(--surface);color:var(--text);" rows="3"></textarea>
      <div class="modal-actions">
        <button type="button" class="btn btn-ghost" onclick="closeModal('failedDeliveryModal')">Go Back</button>
        <button type="submit" class="btn btn-danger" style="flex:2;"><i class="fa fa-user-slash"></i> Report &amp; Notify Staff</button>
      </div>
    </form>
  </div>
</div>

<div class="modal-overlay" id="deliveryCancelModal">
  <div class="modal-box">
    <div class="modal-icon">🚫</div><div class="modal-title">Cancel This Order?</div>
    <div class="modal-sub">Stock will be restored and the customer will be notified.</div>
    <form action="deliveryCancelOrder" method="post" style="width:100%;">
      <input type="hidden" name="assignmentId" id="dcAssignmentId">
      <input type="hidden" name="orderId"      id="dcOrderId">
      <select name="reason" id="dcReason" required
        style="width:100%;margin:12px 0 8px;padding:10px;border-radius:8px;border:1.5px solid var(--border);font-size:13px;font-family:inherit;background:var(--surface);color:var(--text);">
        <option value="" disabled selected>-- Select a reason --</option>
        <option>Wrong Address / Location not found</option>
        <option>Customer Not Available at Doorstep</option>
        <option>Customer Not Responding (Calls &amp; Doorbell)</option>
        <option>Customer Refused to Accept Delivery</option>
        <option>Unsafe Delivery Location</option>
        <option>Other</option>
      </select>
      <textarea name="note" placeholder="Optional details…"
        style="width:100%;margin-bottom:12px;padding:10px;border-radius:8px;border:1.5px solid var(--border);font-size:13px;resize:none;font-family:inherit;background:var(--surface);color:var(--text);" rows="3"></textarea>
      <div class="modal-actions">
        <button type="button" class="btn btn-ghost" onclick="closeModal('deliveryCancelModal')">Go Back</button>
        <button type="submit" class="btn btn-danger" style="flex:2;"
          onclick="if(!document.getElementById('dcReason').value){alert('Please select a reason.');return false;}return confirm('Cancel this order?');">
          <i class="fa fa-circle-xmark"></i> Cancel Order
        </button>
      </div>
    </form>
  </div>
</div>

<div class="modal-overlay" id="walletLowModal">
  <div class="modal-box">
    <div class="modal-icon">💳</div>
    <div class="modal-title">Wallet Balance Too Low</div>
    <div class="wallet-low-body">
      <i class="fa fa-exclamation-triangle"></i>
      <span>Current balance: <strong>₹<%= String.format("%.2f", walletBalance) %></strong>. You need at least <strong>₹200</strong> to go online.</span>
    </div>
    <div class="modal-actions">
      <button class="btn btn-ghost" onclick="closeModal('walletLowModal')">Later</button>
      <a href="delivery-wallet.jsp" class="btn btn-brand" style="justify-content:center;text-decoration:none;"><i class="fa fa-plus"></i> Recharge Now</a>
    </div>
  </div>
</div>

<div class="modal-overlay" id="sosModal">
  <div class="modal-box">
    <div class="modal-icon">🚨</div><div class="modal-title">Emergency SOS</div>
    <div class="modal-sub">Your location will be shared with the SIBS team.</div>
    <div style="display:flex;flex-direction:column;gap:10px;">
      <button class="btn btn-danger" onclick="sendSOS('accident')" style="width:100%;"><i class="fa fa-car-burst"></i> Accident / Injury</button>
      <button class="btn btn-danger" onclick="sendSOS('theft')"    style="width:100%;"><i class="fa fa-shield-halved"></i> Theft / Robbery</button>
      <button class="btn btn-danger" onclick="sendSOS('breakdown')" style="width:100%;"><i class="fa fa-wrench"></i> Vehicle Breakdown</button>
      <button class="btn btn-ghost"  onclick="closeModal('sosModal')" style="width:100%;">Cancel</button>
    </div>
  </div>
</div>

<script>
/* ── Dark mode ── */
function toggleDark(){
  const h=document.documentElement,d=h.getAttribute('data-theme')==='dark';
  h.setAttribute('data-theme',d?'light':'dark');
  localStorage.setItem('sibs-theme',d?'light':'dark');
}
(function(){const t=localStorage.getItem('sibs-theme');if(t)document.documentElement.setAttribute('data-theme',t);})();

/* ── Filters ── */
function applyFilters(){
  const q=document.getElementById('search').value.toLowerCase();
  const st=document.getElementById('statusFilter').value;
  document.querySelectorAll('#assignTable .order-card').forEach(row=>{
    const mQ=!q||(row.dataset.text||'').includes(q);
    const mS=st==='All'||(row.dataset.status||'')===st;
    row.style.display=(mQ&&mS)?'':'none';
  });
}

/* ── Generic modal helpers ── */
function openModal(id){document.getElementById(id).classList.add('open');}
function closeModal(id){document.getElementById(id).classList.remove('open');}
['cancelModal','failedDeliveryModal','deliveryCancelModal','walletLowModal','sosModal'].forEach(function(id){
  document.getElementById(id).addEventListener('click',function(e){if(e.target===this)closeModal(id);});
});
function showCancelModal(a,o){document.getElementById('modalCancelAssign').value=a;document.getElementById('modalCancelOrder').value=o;openModal('cancelModal');}
function showFailedModal(a,o){document.getElementById('failedAssignmentId').value=a;document.getElementById('failedOrderId').value=o;openModal('failedDeliveryModal');}
function showDeliveryCancelModal(a,o){document.getElementById('dcAssignmentId').value=a;document.getElementById('dcOrderId').value=o;document.getElementById('dcReason').value='';openModal('deliveryCancelModal');}
function showSOSModal(){openModal('sosModal');}

/* ── CHANGE 3: Dynamic notification panel ── */
var NOTIF_ICONS={DELIVERY:'🛵',ORDER:'📦',PAYMENT:'💰',ACCOUNT:'👤',COMPLAINT:'📣',LEAVE:'🏖️'};
function notifIcon(c){return NOTIF_ICONS[c]||'🔔';}

function toggleNotifPanel(){
  var p=document.getElementById('notifPanel');
  p.classList.toggle('open');
}
document.addEventListener('click',function(e){
  var p=document.getElementById('notifPanel'),b=document.getElementById('notifBtn');
  if(p&&b&&!p.contains(e.target)&&!b.contains(e.target)) p.classList.remove('open');
});

function setBadge(n){
  var b=document.getElementById('notifBadge');
  if(n>0){b.style.display='flex';b.textContent=n>99?'99+':n;}
  else b.style.display='none';
}

function renderNotifList(items){
  var list=document.getElementById('notifList');
  if(!items||!items.length){
    list.innerHTML='<div class="notif-empty"><div style="font-size:28px;margin-bottom:8px;">🔕</div>No notifications yet</div>';
    return;
  }
  list.innerHTML=items.map(function(n){
    return '<a href="'+(n.linkUrl||'#')+'" class="notif-item'+(n.isRead?'':' unread')+'"'+
           (n.isRead?'':' onclick="markOneRead('+n.id+',this)"')+'>'+
           '<span class="notif-dot'+(n.isRead?' read':'')+'"></span>'+
           '<div style="flex:1;min-width:0;">'+
           '<div style="display:flex;align-items:center;gap:6px;">'+
           '<span>'+notifIcon(n.category)+'</span>'+
           '<span class="notif-text">'+esc(n.title)+'</span></div>'+
           '<div class="notif-msg">'+esc(n.message)+'</div>'+
           '<div class="notif-time">'+esc(n.timeAgo)+'</div>'+
           '</div></a>';
  }).join('');
}

function markOneRead(id,el){
  fetch('delivery-notifications?action=markRead',{
    method:'POST',credentials:'same-origin',
    headers:{'Content-Type':'application/x-www-form-urlencoded'},
    body:'id='+id
  });
  if(el){el.classList.remove('unread');var dot=el.querySelector('.notif-dot');if(dot)dot.classList.add('read');}
  var b=document.getElementById('notifBadge');
  setBadge(Math.max(0,(parseInt(b.textContent)||0)-1));
}

function markAllRead(){
  fetch('delivery-notifications?action=markAll',{method:'POST',credentials:'same-origin'})
    .then(function(){setBadge(0);document.querySelectorAll('.notif-item').forEach(function(el){el.classList.remove('unread');var d=el.querySelector('.notif-dot');if(d)d.classList.add('read');});});
}

/* Poll every 15 seconds */
function pollNotifications(){
  fetch('delivery-notifications?action=poll&limit=5',{credentials:'same-origin'})
    .then(function(r){return r.status===401?null:r.json();})
    .then(function(d){
      if(!d) return;
      setBadge(d.unreadCount);
      renderNotifList(d.notifications);
    }).catch(function(){});
}
setInterval(pollNotifications,15000);

function esc(s){if(!s)return'';return s.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');}

/* ── Shift timer ── */
(function(){
  const isOffline=<%=isOffline%>;
  const el=document.getElementById('shiftTimer');
  const breakEl=document.getElementById('breakTimer');
  if(!el||isOffline) return;
  <% if(mySlot != null && !isOffline) { %>
  const slotTimeStr='<%=mySlot.getStartTime().toString().substring(0,5)%>';
  const today=new Date();
  const slotParts=slotTimeStr.split(':');
  const slotStart=new Date(today.getFullYear(),today.getMonth(),today.getDate(),parseInt(slotParts[0]),parseInt(slotParts[1]),0,0);
  const slotStartMs=slotStart.getTime();
  <% } else { %>
  const slotStartMs=Date.now();
  <% } %>
  const totalBreakSeconds=<%=db.getTotalBreakSeconds()%>;
  const isOnBreak=<%=isBreak%>;
  <% if(db.getBreakStartedAt() != null) { %>
  const _bp='<%=db.getBreakStartedAt()%>'.split(/[-T:]/);
  const breakStartedAt=new Date(parseInt(_bp[0]),parseInt(_bp[1])-1,parseInt(_bp[2]),parseInt(_bp[3]),parseInt(_bp[4]),parseInt(_bp[5]||0)).getTime();
  <% } else if(isBreak) { %>
  const breakStartedAt=Date.now();
  <% } else { %>
  const breakStartedAt=0;
  <% } %>
  function fmt(ms){
    const hh=Math.floor(ms/3600000);
    const mm=Math.floor((ms%3600000)/60000);
    const ss=Math.floor((ms%60000)/1000);
    return hh.toString().padStart(2,'0')+':'+mm.toString().padStart(2,'0')+':'+ss.toString().padStart(2,'0');
  }
  <% if(mySlot != null && mySlot.getEndTime() != null && !isOffline) { %>
  const slotEndParts='<%=mySlot.getEndTime().toString().substring(0,5)%>'.split(':');
  const slotEnd=new Date(today.getFullYear(),today.getMonth(),today.getDate(),parseInt(slotEndParts[0]),parseInt(slotEndParts[1]),0,0);
  const slotEndMs=slotEnd.getTime();
  <% } else { %>
  const slotEndMs=0;
  <% } %>
  let autoOfflineFired=false;
  function tick(){
    const nowMs=Date.now();
    if(slotEndMs>0&&nowMs>=slotEndMs&&!autoOfflineFired){
      autoOfflineFired=true;
      fetch('shiftToggle',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:'state=OFFLINE'}).then(function(){window.location.reload();});
      return;
    }
    let liveBreakMs=0;
    if(isOnBreak&&breakStartedAt>0) liveBreakMs=Math.max(0,nowMs-breakStartedAt);
    const elapsedMs=Math.max(0,nowMs-slotStartMs);
    const breakMs=(totalBreakSeconds*1000)+liveBreakMs;
    const netMs=Math.max(0,elapsedMs-breakMs);
    el.textContent=fmt(netMs);
    if(breakEl){breakEl.textContent=fmt(breakMs);breakEl.style.color=isOnBreak?'var(--amber)':'var(--muted)';}
  }
  tick();
  setInterval(tick,1000);
})();

/* ── 3-State shift toggle ── */
const walletOk=<%=walletOk%>;
function setShift(state){
  if(state==='ONLINE'&&!walletOk){openModal('walletLowModal');return;}
  fetch('shiftToggle',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:'state='+state})
  .then(r=>r.json())
  .then(function(d){
    if(d&&d.status==='NO_ACTIVE_SLOT'){alert('\u26a0\ufe0f You cannot go Online!\n\nYou must have an ACTIVE slot to go online.\n\nPlease go to My Slot page and start your shift first.');return;}
    if(d&&d.status==='LOW_WALLET'){openModal('walletLowModal');return;}
    if(d&&d.status==='COD_DEBT'){alert('\u26a0\ufe0f Cannot go Online!\n\nYou have \u20b9'+parseFloat(d.pending).toFixed(0)+' in pending COD cash to remit, but your earnings + wallet total only \u20b9'+parseFloat(d.available).toFixed(0)+'.\n\nPlease remit the COD cash to staff or recharge your wallet first.');return;}
    window.location.reload();
  })
  .catch(function(){alert('Shift update failed. Please try again.');});
}

/* ── Photo proof ── */
function previewProof(input){
  if(!input.files||!input.files[0]) return;
  const r=new FileReader();
  r.onload=function(e){
    document.getElementById('proofImg').src=e.target.result;
    document.getElementById('proofArea').style.display='none';
    document.getElementById('proofPreview').style.display='block';
    document.getElementById('proofStatus').style.display='block';
  };
  r.readAsDataURL(input.files[0]);
}
function retakeProof(){
  document.getElementById('proofArea').style.display='block';
  document.getElementById('proofPreview').style.display='none';
  document.getElementById('proofStatus').style.display='none';
  document.getElementById('proofInput').value='';
}

/* ═══ NAV MAP ═══ */
var navMaps={},navMarkers={},navDest={},navLines={},navWatch=null,navPushInterval=null;
var activePanels=new Set(),currentLat=null,currentLng=null;
function startGPSWatch(){
  if(navWatch!==null||!navigator.geolocation) return;
  navWatch=navigator.geolocation.watchPosition(p=>{currentLat=p.coords.latitude;currentLng=p.coords.longitude;activePanels.forEach(updateMyMarker);},e=>{console.warn('GPS:',e.message);},{enableHighAccuracy:true,maximumAge:5000,timeout:15000});
  navPushInterval=setInterval(function(){activePanels.forEach(function(k){var oid=navMaps[k]&&navMaps[k]._orderId;if(oid&&currentLat!==null)pushLocation(currentLat,currentLng,oid);});},10000);
}
function stopGPSWatch(){
  if(navWatch!==null){navigator.geolocation.clearWatch(navWatch);navWatch=null;}
  if(navPushInterval){clearInterval(navPushInterval);navPushInterval=null;}
}
function updateMyMarker(pid){
  if(currentLat===null) return;
  var map=navMaps[pid]; if(!map) return;
  var myI=L.divIcon({html:'<div style="background:#4361ee;width:16px;height:16px;border-radius:50%;border:3px solid #fff;box-shadow:0 2px 8px rgba(67,97,238,.6);"></div>',iconSize:[16,16],iconAnchor:[8,8]});
  if(navMarkers[pid]) navMarkers[pid].setLatLng([currentLat,currentLng]);
  else navMarkers[pid]=L.marker([currentLat,currentLng],{icon:myI}).addTo(map).bindPopup('<b>You</b>');
  if(navDest[pid]){
    if(navLines[pid]) map.removeLayer(navLines[pid]);
    navLines[pid]=L.polyline([[currentLat,currentLng],navDest[pid].getLatLng()],{color:'#7c3aed',weight:4,opacity:.7,dashArray:'8,6'}).addTo(map);
    map.fitBounds([[currentLat,currentLng],navDest[pid].getLatLng()],{padding:[40,40]});
  }
  if(map._orderId) pushLocation(currentLat,currentLng,map._orderId);
}
function toggleNavMap(panelId,destLat,destLng,orderId,mapElId,extLinkId){
  var panel=document.getElementById(panelId); if(!panel) return;
  var isOpen=panel.style.display==='block';
  if(isOpen||destLat===0){panel.style.display='none';activePanels.delete(panelId);if(activePanels.size===0)stopGPSWatch();return;}
  panel.style.display='block';activePanels.add(panelId);
  var elId=mapElId||'navMapSpotlight',extId=extLinkId||'extLinkSpotlight';
  var extLink=document.getElementById(extId);
  if(extLink) extLink.href='https://www.google.com/maps/dir/?api=1&destination='+destLat+','+destLng;
  if(!navMaps[panelId]){
    var me=document.getElementById(elId);
    navMaps[panelId]=L.map(me).setView([destLat,destLng],14);
    navMaps[panelId]._orderId=orderId;
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',{attribution:'© OpenStreetMap contributors'}).addTo(navMaps[panelId]);
    var dI=L.divIcon({html:'<div style="background:#ef4444;width:14px;height:14px;border-radius:50%;border:3px solid #fff;box-shadow:0 2px 6px rgba(0,0,0,.4);"></div>',iconSize:[14,14],iconAnchor:[7,7]});
    navDest[panelId]=L.marker([destLat,destLng],{icon:dI}).addTo(navMaps[panelId]).bindPopup('<b>Delivery Address</b>').openPopup();
  } else {navMaps[panelId]._orderId=orderId;setTimeout(()=>navMaps[panelId].invalidateSize(),200);}
  startGPSWatch();if(currentLat!==null)updateMyMarker(panelId);
}
function pushLocation(lat,lng,oid){
  fetch('updateLocation',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:'lat='+lat+'&lng='+lng+'&orderId='+oid}).catch(()=>{});
}

/* ── SOS ── */
function sendSOS(type){
  if(navigator.geolocation){
    navigator.geolocation.getCurrentPosition(function(pos){
      fetch('reportSOS',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:'type='+type+'&lat='+pos.coords.latitude+'&lng='+pos.coords.longitude}).catch(()=>{});
    });
  }
  closeModal('sosModal');
  alert('🚨 SOS sent! The SIBS team has been notified and will contact you shortly. Stay safe.');
}

/* ── Auto-refresh every 30 s ── */
setTimeout(function(){if(!document.hidden)window.location.reload();},30000);
</script>
</body>
</html>
