<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.util.*,java.sql.*,com.sibs.dao.OrderDAO,com.sibs.dao.OrderStatusHistoryDAO,com.sibs.dao.DeliveryRatingDAO,com.sibs.model.Order,com.sibs.model.User,com.sibs.util.DBConnection" %>
<%
User user = (User) session.getAttribute("customer");
if(user == null){ response.sendRedirect("customer-login.jsp"); return; }
OrderDAO dao = new OrderDAO();
List<Order> orders = dao.getGroupedOrdersByUser(user.getId());

Map<Integer, String>  groupOtpMap    = new HashMap<>();
Map<Integer, Integer> groupAssignMap = new HashMap<>();
try (Connection otpCon = DBConnection.getConnection();
     PreparedStatement otpPs = otpCon.prepareStatement(
         "SELECT o.group_id, da.id AS assign_id, da.otp FROM delivery_assignments da " +
         "JOIN orders o ON da.order_id = o.id " +
         "WHERE o.user_id = ? " +
         "AND UPPER(da.status) IN ('PICKED_UP','OTP_VERIFIED') " +
         "AND da.otp IS NOT NULL")) {
    otpPs.setInt(1, user.getId());
    ResultSet otpRs = otpPs.executeQuery();
    while(otpRs.next()){
        int gid = otpRs.getInt("group_id");
        groupOtpMap.put(gid,    otpRs.getString("otp"));
        groupAssignMap.put(gid, otpRs.getInt("assign_id"));
    }
} catch(Exception e){ e.printStackTrace(); }

int cntAll=0, cntPending=0, cntConfirmed=0, cntAssigned=0, cntOnWay=0, cntDelivered=0;
if(orders != null){
    cntAll = orders.size();
    for(Order o : orders){
        String sUp = o.getStatus() != null ? o.getStatus().trim().toUpperCase() : "";
        if(sUp.equals("PENDING"))                                                      cntPending++;
        else if(sUp.equals("CONFIRMED") || sUp.equals("APPROVED"))                    cntConfirmed++;
        else if(sUp.equals("ASSIGNED"))                                                cntAssigned++;
        else if(sUp.equals("SHIPPED") || sUp.equals("PICKED") || sUp.equals("ORDER_PICKED_UP") || sUp.equals("OUT FOR DELIVERY")) cntOnWay++;
        else if(sUp.equals("DELIVERED"))                                               cntDelivered++;
    }
}

/* FIX #3 — separate param names so cancel and return errors don't clash */
String cancelMsg    = request.getParameter("cancelled");
String cancelErr    = request.getParameter("error");
String cancelStatus = request.getParameter("status");

String returnSuccess = request.getParameter("return_success");
String returnErr     = request.getParameter("return_error");   /* was "error" — now distinct */
%>
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>My Orders — SIBS</title>
<link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&family=DM+Mono:wght@400;500&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<script src="https://cdnjs.cloudflare.com/ajax/libs/html5-qrcode/2.3.8/html5-qrcode.min.js"></script>
<style>
:root{
  --bg:#f0f4ff;--surface:#ffffff;--border:#e4e9f2;--text:#0d1321;--muted:#7280a0;
  --primary:#4361ee;--primary-light:#eef0fd;--success:#22c55e;--success-light:#dcfce7;
  --warn:#f59e0b;--warn-light:#fef9c3;--ship:#06b6d4;--ship-light:#cffafe;
  --purple:#7c3aed;--purple-light:#ede9fe;--danger:#ef4444;--danger-light:#fee2e2;
  --radius:14px;--card-shadow:0 2px 16px rgba(67,97,238,.07);
}
[data-theme="dark"]{
  --bg:#0b0f1a;--surface:#131929;--border:#1e2a42;--text:#e8eeff;--muted:#5a6a8a;
  --primary:#5878f5;--primary-light:#1a2040;--success-light:#0a2a14;--warn-light:#1a1300;
  --ship-light:#002030;--purple-light:#1a0a30;--danger-light:#2a0a0a;
  --card-shadow:0 2px 20px rgba(0,0,0,.3);
}
*{margin:0;padding:0;box-sizing:border-box;font-family:'DM Sans',sans-serif;}
body{background:var(--bg);color:var(--text);min-height:100vh;}
.topbar{background:var(--surface);border-bottom:1px solid var(--border);padding:0 24px;height:62px;
  display:flex;align-items:center;gap:14px;position:sticky;top:0;z-index:50;
  box-shadow:0 1px 0 var(--border);}
.back-link{display:flex;align-items:center;gap:7px;text-decoration:none;color:var(--muted);
  font-size:13px;font-weight:500;transition:.15s;padding:7px 12px;border-radius:8px;border:1px solid var(--border);}
.back-link:hover{color:var(--primary);border-color:var(--primary);background:var(--primary-light);}
.topbar-title{font-weight:700;font-size:16px;flex:1;text-align:center;}
.live-badge{display:flex;align-items:center;gap:6px;font-size:12px;color:var(--success);
  background:var(--success-light);padding:5px 10px;border-radius:99px;font-weight:600;}
.live-dot{width:7px;height:7px;background:var(--success);border-radius:50%;animation:blink 1.4s ease infinite;}
@keyframes blink{0%,100%{opacity:1;transform:scale(1);}50%{opacity:.4;transform:scale(.8);}}
.dark-btn{background:none;border:1px solid var(--border);width:36px;height:36px;border-radius:9px;
  cursor:pointer;color:var(--muted);display:flex;align-items:center;justify-content:center;
  font-size:14px;transition:.15s;}
.dark-btn:hover{border-color:var(--primary);color:var(--primary);}
.content{max-width:780px;margin:28px auto;padding:0 16px 60px;}
.stats-row{display:flex;gap:10px;flex-wrap:wrap;margin-bottom:22px;}
.stat-chip{padding:8px 16px;border-radius:99px;font-size:12px;font-weight:600;cursor:pointer;
  border:1.5px solid var(--border);background:var(--surface);color:var(--muted);transition:.15s;
  display:flex;align-items:center;gap:7px;}
.stat-chip:hover{border-color:var(--primary);color:var(--primary);}
.stat-chip.active{border-color:var(--primary);color:var(--primary);background:var(--primary-light);}
.stat-chip .cnt{font-size:11px;background:var(--border);padding:1px 7px;border-radius:99px;font-weight:700;}
.stat-chip.active .cnt{background:var(--primary);color:#fff;}
.order-card{background:var(--surface);border:1.5px solid var(--border);border-radius:var(--radius);
  margin-bottom:14px;transition:.2s;box-shadow:var(--card-shadow);overflow:hidden;}
.order-card:hover{box-shadow:0 6px 28px rgba(67,97,238,.12);border-color:var(--primary);}
.card-header{display:flex;align-items:center;gap:14px;padding:16px 18px;cursor:pointer;}
/* FIX #1 — placeholder shown instead of invisible broken image */
.prod-thumb{width:58px;height:58px;border-radius:10px;object-fit:contain;
  background:var(--bg);border:1px solid var(--border);padding:4px;flex-shrink:0;}
.header-info{flex:1;min-width:0;}
.prod-name{font-weight:700;font-size:15px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;}
.order-sub{font-size:12px;color:var(--muted);margin-top:3px;display:flex;gap:10px;flex-wrap:wrap;}
.order-sub span{display:flex;align-items:center;gap:4px;}
.header-right{display:flex;flex-direction:column;align-items:flex-end;gap:8px;flex-shrink:0;}
.badge{padding:5px 12px;border-radius:99px;font-size:11px;font-weight:700;letter-spacing:.3px;}
.badge-pending{background:var(--warn-light);color:#92400e;}
.badge-confirmed{background:var(--success-light);color:#15803d;}
.badge-assigned{background:#e0f2fe;color:#0369a1;}
.badge-onway{background:var(--purple-light);color:#7c3aed;}
.badge-delivered{background:#f0fdf4;color:#15803d;border:1px solid #bbf7d0;}
.badge-cancelled{background:#fef2f2;color:#991b1b;border:1px solid #fecaca;}
.badge-return{background:#fff7ed;color:#c2410c;border:1px solid #fed7aa;}
.chevron{font-size:12px;color:var(--muted);transition:transform .25s;}
.order-card.open .chevron{transform:rotate(180deg);}
.card-body{display:none;border-top:1px solid var(--border);}
.order-card.open .card-body{display:block;}
.meta-strip{display:flex;gap:0;border-bottom:1px solid var(--border);}
.meta-item{flex:1;padding:12px 16px;text-align:center;border-right:1px solid var(--border);}
.meta-item:last-child{border-right:none;}
.meta-label{font-size:10px;font-weight:600;color:var(--muted);text-transform:uppercase;letter-spacing:.5px;margin-bottom:3px;}
.meta-value{font-size:13px;font-weight:700;}
.meta-value.blue{color:var(--primary);}
.timeline-wrap{padding:20px 18px 6px;}
.tl-title{font-size:11px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.6px;margin-bottom:14px;display:flex;align-items:center;gap:6px;}
.timeline{display:flex;position:relative;align-items:flex-start;}
.timeline-track{position:absolute;top:18px;left:18px;right:18px;height:3px;background:var(--border);border-radius:99px;z-index:0;}
.tl-fill{height:3px;background:linear-gradient(90deg,var(--success),var(--primary));border-radius:99px;transition:width .5s ease;}
.tl-step{flex:1;display:flex;flex-direction:column;align-items:center;position:relative;z-index:1;}
.tl-icon{width:36px;height:36px;border-radius:50%;border:2.5px solid var(--border);
  background:var(--surface);display:flex;align-items:center;justify-content:center;
  font-size:13px;margin-bottom:7px;transition:.3s;}
.tl-icon.done{border-color:var(--success);background:var(--success);color:#fff;}
.tl-icon.active{border-color:var(--primary);background:var(--primary);color:#fff;
  box-shadow:0 0 0 5px var(--primary-light);animation:pulse 2s ease infinite;}
.tl-icon.idle{border-color:var(--border);background:var(--surface);color:var(--muted);}
@keyframes pulse{0%,100%{box-shadow:0 0 0 5px var(--primary-light);}50%{box-shadow:0 0 0 9px transparent;}}
.tl-name{font-size:10px;font-weight:600;color:var(--muted);text-align:center;line-height:1.3;}
.tl-name.done-lbl{color:var(--success);}
.tl-name.active-lbl{color:var(--primary);font-weight:700;}
.tl-date{font-size:9px;color:var(--muted);text-align:center;margin-top:2px;}
.qr-scan-box{margin:14px 18px;background:linear-gradient(135deg,#1e1b4b,#312e81);
  border-radius:16px;padding:20px;color:#fff;text-align:center;}
.qr-scan-title{font-size:13px;font-weight:700;letter-spacing:.4px;margin-bottom:4px;}
.qr-scan-sub{font-size:11px;opacity:.65;margin-bottom:16px;}
.qr-scan-btn{background:#fff;color:#1e1b4b;border:none;border-radius:10px;
  padding:11px 22px;font-size:13px;font-weight:700;cursor:pointer;
  display:inline-flex;align-items:center;gap:8px;transition:.15s;}
.qr-scan-btn:hover{opacity:.9;}
.qr-reader-wrap{background:#fff;border-radius:12px;overflow:hidden;margin:14px 0;max-width:260px;margin-left:auto;margin-right:auto;}
.qr-status{font-size:12px;opacity:.75;margin-top:10px;}
.qr-status.success{color:#86efac;font-weight:700;}
.qr-status.error{color:#fca5a5;font-weight:700;}
.otp-fallback-box{margin-top:14px;background:rgba(255,255,255,.1);border-radius:10px;padding:10px 16px;}
.otp-fallback-label{font-size:10px;opacity:.55;letter-spacing:.5px;margin-bottom:4px;}
.otp-fallback-digits{font-size:28px;font-weight:800;letter-spacing:10px;font-family:monospace;}
.otp-fallback-note{font-size:10px;opacity:.45;margin-top:4px;}
.addr-section{padding:14px 18px;border-top:1px solid var(--border);
  display:flex;justify-content:space-between;align-items:flex-start;gap:12px;flex-wrap:wrap;}
.addr-box{background:var(--bg);border-radius:10px;padding:12px 14px;flex:1;min-width:200px;}
.addr-tag{font-size:10px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.5px;margin-bottom:5px;}
.addr-val{font-size:13px;font-weight:500;line-height:1.5;}
.card-actions{display:flex;gap:8px;flex-wrap:wrap;padding:14px 18px;border-top:1px solid var(--border);}
.act-btn{padding:8px 16px;border-radius:8px;font-size:12px;font-weight:600;cursor:pointer;
  border:1.5px solid var(--border);background:none;color:var(--muted);
  display:flex;align-items:center;gap:6px;text-decoration:none;transition:.15s;}
.act-btn:hover{border-color:var(--primary);color:var(--primary);background:var(--primary-light);}
.act-btn.green{border-color:var(--success);color:var(--success);}
.act-btn.green:hover{background:var(--success-light);}
.act-btn.red{border-color:var(--danger);color:var(--danger);}
.act-btn.red:hover{background:var(--danger-light);}
.eta-badge{display:inline-flex;align-items:center;gap:5px;font-size:11px;font-weight:600;
  color:var(--primary);background:var(--primary-light);padding:4px 10px;border-radius:99px;}
.items-section{padding:14px 18px;border-bottom:1px solid var(--border);}
.items-title{font-size:11px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.5px;margin-bottom:10px;}
.item-row{display:flex;align-items:center;gap:12px;padding:8px 0;border-bottom:1px solid var(--border);}
.item-row:last-child{border-bottom:none;}
.item-img{width:42px;height:42px;border-radius:8px;object-fit:contain;background:var(--bg);border:1px solid var(--border);padding:3px;}
.item-name{font-size:13px;font-weight:600;}
.item-qty{font-size:11px;color:var(--muted);}
.item-price{font-size:13px;font-weight:700;color:var(--primary);margin-left:auto;}
.empty{text-align:center;padding:70px 20px;color:var(--muted);}
.empty-icon{width:80px;height:80px;background:var(--primary-light);border-radius:50%;
  display:inline-flex;align-items:center;justify-content:center;font-size:32px;
  color:var(--primary);margin-bottom:16px;}
.empty h3{font-size:17px;font-weight:700;color:var(--text);margin-bottom:6px;}
.empty p{font-size:13px;margin-bottom:20px;}
.shop-btn{padding:11px 24px;background:var(--primary);color:#fff;border:none;border-radius:10px;
  cursor:pointer;font-weight:600;font-size:14px;text-decoration:none;display:inline-block;}
.alert-msg{padding:12px 18px;border-radius:10px;margin-bottom:16px;font-weight:600;font-size:13px;display:flex;align-items:center;gap:8px;}
.alert-msg.success{background:var(--success-light);color:#15803d;border:1px solid #bbf7d0;}
.alert-msg.error{background:var(--danger-light);color:#dc2626;border:1px solid #fecaca;}
.sibs-toast{position:fixed;bottom:24px;left:50%;transform:translateX(-50%);
  padding:14px 22px;border-radius:14px;font-size:13px;font-weight:600;
  display:flex;align-items:center;gap:10px;z-index:9999;
  box-shadow:0 8px 32px rgba(0,0,0,.18);animation:slideUp .3s ease;min-width:280px;max-width:90vw;}
.sibs-toast.success{background:#16a34a;color:#fff;}
.sibs-toast.warn{background:#f97316;color:#fff;}
.sibs-toast.info{background:#4361ee;color:#fff;}
@keyframes slideUp{from{transform:translateX(-50%) translateY(40px);opacity:0;}to{transform:translateX(-50%) translateY(0);opacity:1;}}
</style>
</head>
<body>

<div class="topbar">
  <a class="back-link" href="customer-dashboard.jsp"><i class="fa fa-arrow-left"></i> Shop</a>
  <span class="topbar-title">My Orders</span>
  <div class="live-badge"><div class="live-dot"></div> Live</div>
  <button class="dark-btn" onclick="toggleDark()"><i class="fa fa-moon"></i></button>
</div>

<div class="content">

  <%-- Cancel result messages --%>
  <% if("1".equals(request.getParameter("rated"))) { %>
  <div class="alert-msg success"><i class="fa fa-star"></i> Thank you for your rating! Your feedback has been submitted.</div>
  <% } %>
  <% if("dup".equals(request.getParameter("rated"))) { %>
  <div class="alert-msg error"><i class="fa fa-info-circle"></i> You have already rated this delivery.</div>
  <% } %>
  <% if("1".equals(cancelMsg)) { %>
  <div class="alert-msg success">
    <i class="fa fa-check-circle"></i> Order cancelled successfully.
    If you paid online, your refund will be processed within 5–7 business days.
  </div>
  <% } %>

  <%-- Return result messages --%>
  <% if("1".equals(returnSuccess)) { %>
  <div class="alert-msg success">
    <i class="fa fa-rotate-left"></i> Return request submitted! Our team will review it shortly.
  </div>
  <% } %>
  <%-- FIX #3 — returnErr now reads "return_error" param, not "error" --%>
  <% if("return_exists".equals(returnErr)) { %>
  <div class="alert-msg error">
    <i class="fa fa-circle-exclamation"></i> A return request already exists for this order.
  </div>
  <% } %>
  <% if("window_expired".equals(returnErr)) { %>
  <div class="flash flash-err"><i class="fa fa-clock"></i> Return window has expired. Returns are only accepted within 14 days of delivery.</div>
<% } %>
<% if("return_not_delivered".equals(returnErr)) { %>
  <div class="alert-msg error">
    <i class="fa fa-circle-exclamation"></i> Returns are only allowed for delivered orders.
  </div>
  <% } %>
  <% if("return_failed".equals(returnErr)) { %>
  <div class="alert-msg error">
    <i class="fa fa-circle-exclamation"></i> Something went wrong with your return request. Please try again.
  </div>
  <% } %>

  <% if("cannot_cancel".equals(cancelErr)) { %>
  <div class="alert-msg error">
    <i class="fa fa-circle-exclamation"></i>
    Orders can only be cancelled before dispatch. This order is already
    <strong>&nbsp;<%=cancelStatus != null ? cancelStatus : "in progress"%></strong>.
    Please contact support if you need help.
  </div>
  <% } %>

  <% if("cancel_failed".equals(cancelErr)) { %>
  <div class="alert-msg error">
    <i class="fa fa-circle-exclamation"></i> Something went wrong. Please try again.
  </div>
  <% } %>

  <div class="stats-row" id="filters">
    <div class="stat-chip active" onclick="filter('ALL',this)">
      <i class="fa fa-list"></i> All <span class="cnt"><%=cntAll%></span>
    </div>
    <div class="stat-chip" onclick="filter('PENDING',this)">
      <i class="fa fa-clock"></i> Pending <span class="cnt"><%=cntPending%></span>
    </div>
    <div class="stat-chip" onclick="filter('CONFIRMED',this)">
      <i class="fa fa-check-circle"></i> Confirmed <span class="cnt"><%=cntConfirmed%></span>
    </div>
    <div class="stat-chip" onclick="filter('ASSIGNED',this)">
      <i class="fa fa-user-check"></i> Assigned <span class="cnt"><%=cntAssigned%></span>
    </div>
    <div class="stat-chip" onclick="filter('ONWAY',this)">
      <i class="fa fa-motorcycle"></i> Out for Delivery <span class="cnt"><%=cntOnWay%></span>
    </div>
    <div class="stat-chip" onclick="filter('DELIVERED',this)">
      <i class="fa fa-house"></i> Delivered <span class="cnt"><%=cntDelivered%></span>
    </div>
  </div>

  <div id="orderList">
  <%
  if(orders == null || orders.isEmpty()){
  %>
  <div class="empty">
    <div class="empty-icon"><i class="fa fa-box-open"></i></div>
    <h3>No orders yet</h3>
    <p>You haven't placed any orders. Start shopping!</p>
    <a class="shop-btn" href="customer-dashboard.jsp"><i class="fa fa-store"></i> Browse Products</a>
  </div>
  <%
  } else {
    int idx = 0;
    for(Order o : orders){
      String s    = o.getStatus();
      String sUp  = (s != null) ? s.trim().toUpperCase() : "PENDING";

      List<Order> items = o.getItems();
      StringBuilder prodNames = new StringBuilder();
      int totalQty = 0;
      double totalAmt = 0;

      /* FIX #2 — compute displayItemCount from items OR fall back to order-level data */
      int displayItemCount;
      if(!items.isEmpty()){
          for(Order item : items){
              if(prodNames.length() > 0) prodNames.append(", ");
              prodNames.append(item.getProductName());
              totalQty += item.getQuantity();
              totalAmt += item.getTotal();
          }
          displayItemCount = items.size();
          // Add delivery charge from the first item (delivery_charge is stored on first item row only)
          totalAmt += o.getDeliveryCharge();
      } else {
          prodNames.append(o.getProductName() != null ? o.getProductName() : "Order");
          totalQty = o.getQuantity();
          totalAmt = o.getTotal() + o.getDeliveryCharge();
          displayItemCount = 1;   /* fall back to 1, not 0 */
      }

      String badgeCls, icon, displayStatus, filterKey;
      if(sUp.equals("DELIVERED")){
          badgeCls="badge-delivered"; icon="fa-house-circle-check"; displayStatus="Delivered"; filterKey="DELIVERED";
      } else if(sUp.equals("ORDER_PICKED_UP") || sUp.equals("SHIPPED") || sUp.equals("PICKED") || sUp.equals("OUT FOR DELIVERY")){
          badgeCls="badge-onway"; icon="fa-motorcycle"; displayStatus="Out for Delivery"; filterKey="ONWAY";
      } else if(sUp.equals("ASSIGNED")){
          badgeCls="badge-assigned"; icon="fa-user-check"; displayStatus="Assigned"; filterKey="ASSIGNED";
      } else if(sUp.equals("CONFIRMED") || sUp.equals("APPROVED")){
          badgeCls="badge-confirmed"; icon="fa-check-circle"; displayStatus="Confirmed"; filterKey="CONFIRMED";
      } else if(sUp.equals("CANCELLED")){
          badgeCls="badge-cancelled"; icon="fa-ban"; displayStatus="Cancelled"; filterKey="CANCELLED";
      } else {
          badgeCls="badge-pending"; icon="fa-clock"; displayStatus="Pending"; filterKey="PENDING";
      }

      boolean st1 = true;
      boolean st2 = sUp.equals("CONFIRMED") || sUp.equals("APPROVED") || sUp.equals("ASSIGNED")
                 || sUp.equals("SHIPPED")   || sUp.equals("PICKED")   || sUp.equals("ORDER_PICKED_UP")
                 || sUp.equals("OUT FOR DELIVERY") || sUp.equals("DELIVERED");
      boolean st3 = sUp.equals("ASSIGNED")
                 || sUp.equals("SHIPPED") || sUp.equals("PICKED") || sUp.equals("ORDER_PICKED_UP")
                 || sUp.equals("OUT FOR DELIVERY") || sUp.equals("DELIVERED");
      boolean st4 = sUp.equals("SHIPPED") || sUp.equals("PICKED") || sUp.equals("ORDER_PICKED_UP")
                 || sUp.equals("OUT FOR DELIVERY") || sUp.equals("DELIVERED");
      boolean st5 = sUp.equals("DELIVERED");

      int progressPct = 0;
      if(st5)      progressPct = 100;
      else if(st4) progressPct = 75;
      else if(st3) progressPct = 50;
      else if(st2) progressPct = 25;

      String eta;
      String rawEta = o.getEstimatedDelivery();
      if (st5) {
          eta = "Delivered";
      } else if (rawEta != null && !rawEta.isEmpty()) {
          try {
              java.time.LocalDate etaDate = java.time.LocalDate.parse(rawEta.substring(0, 10));
              java.time.LocalDate today   = java.time.LocalDate.now();
              long days = java.time.temporal.ChronoUnit.DAYS.between(today, etaDate);
              if      (days <= 0)  eta = "Arriving today";
              else if (days == 1)  eta = "Est. tomorrow";
              else                 eta = "Est. " + etaDate.format(java.time.format.DateTimeFormatter.ofPattern("d MMM"));
          } catch (Exception ex) {
              eta = "Est. 5-7 days";
          }
      } else if (st4)      eta = "Arriving today";
        else if (st3)      eta = "Est. 1-2 days";
        else if (st2)      eta = "Est. 3-5 days";
        else               eta = "Est. 5-7 days";

      /* FIX #1 — try items image first, then order-level image, then null (show placeholder via onerror) */
      String finalImg = null;
      if(!items.isEmpty() && items.get(0).getProductImage() != null && !items.get(0).getProductImage().isEmpty()){
          finalImg = request.getContextPath() + "/" + items.get(0).getProductImage();
      } else if(o.getProductImage() != null && !o.getProductImage().isEmpty()){
          finalImg = request.getContextPath() + "/" + o.getProductImage();
      } else {
          finalImg = request.getContextPath() + "/images/default.png";
      }

      String  customerOtp      = groupOtpMap.get(o.getGroupId());
      Integer customerAssignId = groupAssignMap.get(o.getGroupId());
      int     realAssignId     = (customerAssignId != null) ? customerAssignId : 0;

      Map<String, String> hist = new OrderStatusHistoryDAO().getHistoryByGroup(o.getGroupId());
      String histPlaced    = hist.getOrDefault("Placed",    "");
      String histConfirmed = hist.containsKey("Approved") ? hist.get("Approved")
                           : hist.getOrDefault("Confirmed", "");
      String histAssigned  = hist.getOrDefault("Assigned", "");
      String histPicked    = hist.containsKey("Picked") ? hist.get("Picked")
                           : hist.getOrDefault("Out for Delivery", "");
      String histDelivered = hist.getOrDefault("Delivered", "");

      String returnStatus = o.getReturnStatus();
      boolean hasReturn   = (returnStatus != null && !returnStatus.trim().isEmpty());
      boolean hasRated    = new DeliveryRatingDAO().hasRated(o.getId(), user.getId());
  %>

  <div class="order-card" data-status="<%=filterKey%>" data-group="<%=o.getGroupId()%>" data-current-status="<%=sUp%>" data-current-da="" id="card<%=idx%>">

    <div class="card-header" onclick="toggleCard(<%=idx%>)">
      <%-- FIX #1 — onerror shows emoji placeholder instead of invisible broken image --%>
      <img class="prod-thumb"
           src="<%=finalImg%>"
           onerror="this.onerror=null;this.src='data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 width=%2258%22 height=%2258%22 viewBox=%220 0 58 58%22%3E%3Crect width=%2258%22 height=%2258%22 rx=%2210%22 fill=%22%23eef0fd%22/%3E%3Ctext x=%2229%22 y=%2235%22 text-anchor=%22middle%22 font-size=%2224%22%3E%F0%9F%93%A6%3C/text%3E%3C/svg%3E'"
           alt="product">
      <div class="header-info">
        <div class="prod-name"><%=prodNames.toString()%></div>
        <div class="order-sub">
          <span><i class="fa fa-hashtag"></i> Group #<%=o.getGroupId()%></span>
          <%-- FIX #2 — use displayItemCount instead of items.size() --%>
          <span><i class="fa fa-box"></i> <%=displayItemCount%> item<%=displayItemCount>1?"s":""%> · Qty: <%=totalQty%></span>
          <span><i class="fa fa-wallet"></i> <%=o.getPaymentMethod()!=null?o.getPaymentMethod():"COD"%></span>
        </div>
        <% if(!st5){ %>
        <div style="margin-top:6px;">
          <span class="eta-badge"><i class="fa fa-calendar-clock"></i> <%=eta%></span>
        </div>
        <% } %>
      </div>
      <div class="header-right">
        <span class="badge order-badge <%=badgeCls%>"><i class="fa <%=icon%>"></i> <%=displayStatus%></span>
        <span style="font-size:15px;font-weight:700;color:var(--primary);">&#8377;<%=(int)totalAmt%></span>
        <i class="fa fa-chevron-down chevron"></i>
      </div>
    </div>

    <div class="card-body">

      <!-- ITEMS LIST -->
      <div class="items-section">
        <div class="items-title"><i class="fa fa-basket-shopping"></i> Items in this order</div>
        <% if(!items.isEmpty()){
             for(Order item : items){
               String iImg = (item.getProductImage()!=null && !item.getProductImage().isEmpty())
                   ? request.getContextPath()+"/"+item.getProductImage()
                   : request.getContextPath()+"/images/default.png";
        %>
        <div class="item-row">
          <img class="item-img" src="<%=iImg%>"
               onerror="this.onerror=null;this.src='data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 width=%2242%22 height=%2242%22 viewBox=%220 0 42 42%22%3E%3Crect width=%2242%22 height=%2242%22 rx=%228%22 fill=%22%23eef0fd%22/%3E%3Ctext x=%2221%22 y=%2227%22 text-anchor=%22middle%22 font-size=%2218%22%3E%F0%9F%93%A6%3C/text%3E%3C/svg%3E'"
               alt="">
          <div>
            <div class="item-name"><%=item.getProductName()%></div>
            <div class="item-qty">Qty: <%=item.getQuantity()%></div>
          </div>
          <div class="item-price">&#8377;<%=(int)item.getTotal()%></div>
        </div>
        <% } } else { %>
        <%-- FIX #2 — show order-level product when items list is empty --%>
        <div class="item-row">
          <img class="item-img" src="<%=finalImg%>"
               onerror="this.onerror=null;this.src='data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 width=%2242%22 height=%2242%22 viewBox=%220 0 42 42%22%3E%3Crect width=%2242%22 height=%2242%22 rx=%228%22 fill=%22%23eef0fd%22/%3E%3Ctext x=%2221%22 y=%2227%22 text-anchor=%22middle%22 font-size=%2218%22%3E%F0%9F%93%A6%3C/text%3E%3C/svg%3E'"
               alt="">
          <div>
            <div class="item-name"><%=o.getProductName() != null ? o.getProductName() : "Product"%></div>
            <div class="item-qty">Qty: <%=o.getQuantity()%></div>
          </div>
          <div class="item-price">&#8377;<%=(int)o.getTotal()%></div>
        </div>
        <% } %>
      </div>

      <!-- META STRIP -->
      <div class="meta-strip">
        <div class="meta-item">
          <div class="meta-label">Order Total</div>
          <div class="meta-value blue">&#8377;<%=(int)totalAmt%></div>
        </div>
        <% if(o.getDeliveryCharge() > 0) { %>
        <div class="meta-item">
          <div class="meta-label">Delivery</div>
          <div class="meta-value">&#8377;<%=(int)o.getDeliveryCharge()%></div>
        </div>
        <% } %>
        <div class="meta-item">
          <div class="meta-label">Items</div>
          <%-- FIX #2 — use displayItemCount --%>
          <div class="meta-value"><%=displayItemCount%> item<%=displayItemCount>1?"s":""%></div>
        </div>
        <div class="meta-item">
          <div class="meta-label">Payment</div>
          <div class="meta-value"><%=o.getPaymentMethod()!=null?o.getPaymentMethod():"COD"%></div>
        </div>
        <div class="meta-item">
          <div class="meta-label">Status</div>
          <div class="meta-value"><span class="badge <%=badgeCls%>"><%=displayStatus%></span></div>
        </div>
      </div>

      <!-- 5-STEP TIMELINE -->
      <div class="timeline-wrap">
        <div class="tl-title"><i class="fa fa-route"></i> Order Journey</div>
        <div class="timeline">
          <div class="timeline-track">
            <div class="tl-fill" style="width:<%=progressPct%>%;"></div>
          </div>

          <!-- Step 1: Placed — always done -->
          <div class="tl-step">
            <div class="tl-icon done"><i class="fa fa-check"></i></div>
            <div class="tl-name done-lbl">Placed</div>
            <div class="tl-date"><%=histPlaced.isEmpty() ? "Done" : histPlaced%></div>
          </div>

          <%-- FIX #4 — Confirmed: active ONLY when st1 is the current active step (not yet confirmed),
               i.e. status is PENDING. Use explicit pending check instead of !st2&&st1 which was always true. --%>
          <div class="tl-step">
            <div class="tl-icon <%=st2?"done":sUp.equals("PENDING")?"active":"idle"%>">
              <i class="fa <%=st2?"fa-check":"fa-check-circle"%>"></i>
            </div>
            <div class="tl-name <%=st2?"done-lbl":sUp.equals("PENDING")?"active-lbl":""%>">Confirmed</div>
            <div class="tl-date"><%=!histConfirmed.isEmpty() ? histConfirmed : (st2?"Done":"Pending")%></div>
          </div>

          <div class="tl-step">
            <div class="tl-icon <%=st3?"done":st2&&!st3?"active":"idle"%>">
              <i class="fa <%=st3?"fa-check":"fa-user-check"%>"></i>
            </div>
            <div class="tl-name <%=st3?"done-lbl":st2&&!st3?"active-lbl":""%>">Assigned</div>
            <div class="tl-date"><%=!histAssigned.isEmpty() ? histAssigned : (st3?"Done":st2?"Soon":"—")%></div>
          </div>

          <div class="tl-step">
            <div class="tl-icon <%=st5?"done":st4&&!st5?"active":st3&&!st4?"active":"idle"%>">
              <i class="fa fa-motorcycle"></i>
            </div>
            <div class="tl-name <%=st5?"done-lbl":st4&&!st5?"active-lbl":st3&&!st4?"active-lbl":""%>">On the Way</div>
            <div class="tl-date"><%=!histPicked.isEmpty() ? histPicked : (st4||st5?"Done":st3?"Soon":"—")%></div>
          </div>

          <div class="tl-step">
            <div class="tl-icon <%=st5?"done":"idle"%>">
              <i class="fa <%=st5?"fa-check":"fa-house"%>"></i>
            </div>
            <div class="tl-name <%=st5?"done-lbl":""%>">Delivered</div>
            <div class="tl-date"><%=!histDelivered.isEmpty() ? histDelivered : (st5?"Completed":"—")%></div>
          </div>

        </div>
      </div>

      <!-- QR SCANNER -->
      <% if((st4 || st3) && !st5 && customerOtp != null){ %>
      <div class="qr-scan-box" id="qrbox-<%=o.getGroupId()%>">
        <div class="qr-scan-title"><i class="fa fa-qrcode"></i> &nbsp;DELIVERY CONFIRMATION</div>
        <div class="qr-scan-sub">Delivery boy is at your door — scan their QR code to confirm</div>
        <button class="qr-scan-btn" onclick="startScan(<%=o.getGroupId()%>, <%=o.getId()%>, '<%=customerOtp%>', <%=realAssignId%>)">
          <i class="fa fa-camera"></i> Scan QR Code
        </button>
        <div id="reader-<%=o.getGroupId()%>" class="qr-reader-wrap" style="display:none;"></div>
        <div id="qrstatus-<%=o.getGroupId()%>" class="qr-status"></div>
        <div class="otp-fallback-box">
          <div class="otp-fallback-label">OR ENTER OTP MANUALLY</div>
          <%-- FIX #5 — submit all 4 individual digit fields so verifyOtp servlet gets otp1..otp4 --%>
          <form action="verifyOtp" method="post" style="display:inline;">
            <input type="hidden" name="assignmentId" value="<%=realAssignId%>">
            <input type="hidden" name="orderId"      value="<%=o.getId()%>">
            <input type="hidden" name="otp1" id="fallback-otp1-<%=o.getGroupId()%>" value="">
            <input type="hidden" name="otp2" id="fallback-otp2-<%=o.getGroupId()%>" value="">
            <input type="hidden" name="otp3" id="fallback-otp3-<%=o.getGroupId()%>" value="">
            <input type="hidden" name="otp4" id="fallback-otp4-<%=o.getGroupId()%>" value="">
            <input type="text" maxlength="4" placeholder="_ _ _ _"
              style="font-size:26px;font-weight:800;letter-spacing:8px;font-family:monospace;
                     text-align:center;border:none;border-radius:8px;padding:6px 12px;
                     width:130px;background:rgba(255,255,255,.15);color:#fff;outline:none;
                     margin-bottom:8px;display:block;margin:8px auto;"
              oninput="this.value=this.value.replace(/\D/g,'').slice(0,4);"
              onchange="splitOtp(this.value, <%=o.getGroupId()%>)">
            <button type="submit"
              style="background:#fff;color:#1e1b4b;border:none;border-radius:8px;
                     padding:7px 18px;font-weight:700;font-size:12px;cursor:pointer;margin-top:4px;">
              <i class="fa fa-check"></i> Confirm
            </button>
          </form>
          <div class="otp-fallback-note">Ask the delivery boy for the 4-digit code</div>
        </div>
      </div>
      <% } %>

      <!-- ADDRESS -->
      <div class="addr-section">
        <div class="addr-box">
          <div class="addr-tag"><i class="fa fa-location-dot"></i> Delivery Address</div>
          <div class="addr-val"><%=o.getAddress()!=null?o.getAddress():"—"%></div>
        </div>
        <% if(!st5){ %>
        <div class="addr-box" style="max-width:180px;text-align:center;">
          <div class="addr-tag"><i class="fa fa-calendar-clock"></i> Estimated Delivery</div>
          <div class="addr-val" style="color:var(--primary);font-weight:700;"><%=eta%></div>
        </div>
        <% } %>
      </div>

      <!-- ACTIONS -->
      <div class="card-actions">
        <a class="act-btn green" href="my-orders.jsp"><i class="fa fa-rotate"></i> Refresh Status</a>
        <a class="act-btn" href="customer-dashboard.jsp"><i class="fa fa-repeat"></i> Reorder</a>
        <a class="act-btn" href="invoice.jsp?orderId=<%=o.getId()%>"><i class="fa fa-file-invoice"></i> Invoice</a>
        <% if(sUp.equals("PENDING") || sUp.equals("CONFIRMED") || sUp.equals("APPROVED") || sUp.equals("PACKED")){ %>
        <a class="act-btn red" href="javascript:void(0)"
           onclick="openCancelModal(<%=o.getGroupId()%>, '<%=o.getPaymentMethod()!=null?o.getPaymentMethod().toUpperCase():"COD"%>', <%=(int)totalAmt%>)">
          <i class="fa fa-xmark"></i> Cancel Order
        </a>
        <% } %>
        <% if(sUp.equals("DELIVERED")){ %>
          <% if(!hasReturn){ %>
          <a class="act-btn" href="ReturnProductServlet?orderId=<%=o.getId()%>"
             style="background:#7c3aed;color:#fff;border-color:#7c3aed;">
            <i class="fa fa-rotate-left"></i> Request Return
          </a>
          <% } else { %>
          <span class="badge badge-return" style="padding:8px 14px;font-size:11px;">
            <i class="fa fa-rotate-left"></i> Return: <%=returnStatus%>
          </span>
          <% } %>
        <% } %>
        <% if(sUp.equals("DELIVERED") && !hasRated){ %>
        <a class="act-btn" href="customer-rate-rider.jsp?orderId=<%=o.getId()%>"
           style="background:#f59e0b;color:#fff;border-color:#f59e0b;">
          <i class="fa fa-star"></i> Rate Delivery
        </a>
        <% } else if(sUp.equals("DELIVERED") && hasRated){ %>
        <span class="act-btn" style="background:#f0fdf4;color:#16a34a;border-color:#bbf7d0;cursor:default;">
          <i class="fa fa-star"></i> Rated &#10003;
        </span>
        <% } %>
        <% if(sUp.equals("DELIVERED") && o.getProductId() > 0){ %>
        <a class="act-btn" href="product-reviews.jsp?productId=<%=o.getProductId()%>"
           style="background:#7c3aed;color:#fff;border-color:#7c3aed;">
          <i class="fa fa-pen-to-square"></i> Review Product
        </a>
        <% } %>
      </div>

    </div>
  </div>
  <% idx++; } } %>
  </div>
</div>

<script>
var activeScanner = null;

/* FIX #5 — split 4-digit OTP string into individual digit hidden fields */
function splitOtp(val, groupId){
  for(var i=1;i<=4;i++){
    var el = document.getElementById('fallback-otp'+i+'-'+groupId);
    if(el) el.value = val.charAt(i-1) || '';
  }
}

function startScan(groupId, orderId, expectedOtp, assignmentId){
  if(activeScanner){ activeScanner.stop().catch(()=>{}); activeScanner = null; }
  var readerId = 'reader-' + groupId;
  var statusId = 'qrstatus-' + groupId;
  var readerEl = document.getElementById(readerId);
  var statusEl = document.getElementById(statusId);
  readerEl.style.display = 'block';
  statusEl.textContent = '📷 Point camera at delivery boy\'s screen...';
  statusEl.className = 'qr-status';
  activeScanner = new Html5Qrcode(readerId);
  activeScanner.start(
    { facingMode: "environment" },
    { fps: 10, qrbox: { width: 200, height: 200 } },
    function(decodedText){
      if(decodedText.startsWith('SIBS-DELIVER|')){
        var parts = {};
        decodedText.split('|').slice(1).forEach(function(p){
          var kv = p.split('='); parts[kv[0]] = kv[1];
        });
        var realAssignId = (parts.assignId && parts.assignId !== '0') ? parts.assignId : assignmentId;
        if(parts.otp === expectedOtp){
          activeScanner.stop().catch(()=>{});
          statusEl.textContent = '✅ QR matched! Confirming delivery...';
          statusEl.className = 'qr-status success';
          var form = document.createElement('form');
          form.method = 'POST'; form.action = 'verifyOtp';
          var fields = {
            assignmentId: realAssignId,
            orderId: orderId,
            otp1: parts.otp[0],
            otp2: parts.otp[1],
            otp3: parts.otp[2],
            otp4: parts.otp[3]
          };
          Object.keys(fields).forEach(function(k){
            var inp = document.createElement('input');
            inp.type='hidden'; inp.name=k; inp.value=fields[k];
            form.appendChild(inp);
          });
          document.body.appendChild(form);
          setTimeout(function(){ form.submit(); }, 800);
        } else {
          statusEl.textContent = '❌ Wrong QR. Make sure delivery boy has picked up YOUR order.';
          statusEl.className = 'qr-status error';
        }
      }
    },
    function(err){}
  ).catch(function(err){
    statusEl.textContent = '⚠️ Camera access denied. Use the OTP below instead.';
    statusEl.className = 'qr-status error';
  });
}

function toggleCard(i){ document.getElementById('card'+i).classList.toggle('open'); }
function filter(status, btn){
  document.querySelectorAll('.stat-chip').forEach(b=>b.classList.remove('active'));
  btn.classList.add('active');
  document.querySelectorAll('.order-card').forEach(c=>{
    c.style.display=(status==='ALL'||c.dataset.status===status)?'':'none';
  });
}
function toggleDark(){
  const h=document.documentElement,d=h.getAttribute('data-theme')==='dark';
  h.setAttribute('data-theme',d?'light':'dark');
  localStorage.setItem('sibs-theme',d?'light':'dark');
}
(function(){
  const t=localStorage.getItem('sibs-theme');
  if(t) document.documentElement.setAttribute('data-theme',t);
  const first=document.querySelector('.order-card');
  if(first && first.dataset.status !== 'CANCELLED') first.classList.add('open');
})();

var STATUS_LABEL = {
  'PENDING':         {text:'Pending',          cls:'badge-pending',   icon:'fa-clock'},
  'CONFIRMED':       {text:'Confirmed',         cls:'badge-confirmed', icon:'fa-check-circle'},
  'APPROVED':        {text:'Confirmed',         cls:'badge-confirmed', icon:'fa-check-circle'},
  'ASSIGNED':        {text:'Assigned',          cls:'badge-assigned',  icon:'fa-user-check'},
  'SHIPPED':         {text:'Out for Delivery',  cls:'badge-onway',     icon:'fa-motorcycle'},
  'ORDER_PICKED_UP': {text:'Out for Delivery',  cls:'badge-onway',     icon:'fa-motorcycle'},
  'OUT FOR DELIVERY':{text:'Out for Delivery',  cls:'badge-onway',     icon:'fa-motorcycle'},
  'PICKED':          {text:'Out for Delivery',  cls:'badge-onway',     icon:'fa-motorcycle'},
  'DELIVERED':       {text:'Delivered',         cls:'badge-delivered', icon:'fa-house-circle-check'},
  'CANCELLED':       {text:'Cancelled',         cls:'badge-cancelled', icon:'fa-ban'}
};

function playPing(){
  try {
    var ctx = new (window.AudioContext||window.webkitAudioContext)();
    var o = ctx.createOscillator(); var g = ctx.createGain();
    o.connect(g); g.connect(ctx.destination);
    o.frequency.value = 880; o.type = 'sine';
    g.gain.setValueAtTime(0, ctx.currentTime);
    g.gain.linearRampToValueAtTime(0.3, ctx.currentTime+0.05);
    g.gain.linearRampToValueAtTime(0, ctx.currentTime+0.5);
    o.start(ctx.currentTime); o.stop(ctx.currentTime+0.5);
  } catch(e){}
}

function showToast(msg, type){
  var t = document.getElementById('sibs-toast');
  if(!t){ t=document.createElement('div'); t.id='sibs-toast'; document.body.appendChild(t); }
  t.className = 'sibs-toast ' + (type||'info');
  t.innerHTML = msg; t.style.display = 'flex';
  clearTimeout(t._timer);
  t._timer = setTimeout(function(){ t.style.display='none'; }, 5000);
}

function applyUpdate(order){
  var sUp = order.status ? order.status.trim().toUpperCase() : 'PENDING';
  var daUp = order.daStatus ? order.daStatus.trim().toUpperCase() : '';
  var card = document.querySelector('.order-card[data-group="' + order.groupId + '"]');
  if(!card) return;
  var prev = card.dataset.currentStatus || '';
  if(prev === sUp && card.dataset.currentDa === daUp) return;
  var isNewPickup = (daUp === 'PICKED_UP' && card.dataset.currentDa !== 'PICKED_UP');
  var isDelivered = (sUp === 'DELIVERED' && prev !== '' && prev !== 'DELIVERED');
  card.dataset.currentStatus = sUp;
  card.dataset.currentDa = daUp;
  var info = STATUS_LABEL[sUp] || STATUS_LABEL['PENDING'];
  var badgeEl = card.querySelector('.order-badge');
  if(badgeEl){ badgeEl.className='badge order-badge '+info.cls; badgeEl.innerHTML='<i class="fa '+info.icon+'"></i> '+info.text; }
  var filterKey='PENDING';
  if(sUp==='DELIVERED') filterKey='DELIVERED';
  else if(sUp==='ORDER_PICKED_UP'||sUp==='SHIPPED'||sUp==='PICKED'||sUp==='OUT FOR DELIVERY') filterKey='ONWAY';
  else if(sUp==='ASSIGNED') filterKey='ASSIGNED';
  else if(sUp==='CONFIRMED'||sUp==='APPROVED') filterKey='CONFIRMED';
  else if(sUp==='CANCELLED') filterKey='CANCELLED';
  card.dataset.status = filterKey;
  if(isNewPickup){ playPing(); showToast('<i class="fa fa-motorcycle"></i> &nbsp;<b>Delivery boy has arrived!</b> Open your door and scan the QR code.','warn'); card.classList.add('open'); }
  if(isDelivered){ playPing(); showToast('<i class="fa fa-house-circle-check"></i> &nbsp;<b>Order Delivered!</b> Thank you for shopping with us.','success'); }
}

var _sseActive = false;
var _sseRetryDelay = 300000; /* start at 5 min */
function connectSSE(){
  if(!window.EventSource || _sseActive) return;
  _sseActive = true;
  var es = new EventSource('orderStatus');
  es.onmessage = function(e){
    _sseRetryDelay = 300000; /* reset backoff on success */
    try { var orders=JSON.parse(e.data); orders.forEach(function(o){ applyUpdate(o); }); } catch(ex){}
  };
  es.onerror = function(){
    es.close();
    _sseActive = false;
    /* exponential backoff: 5min → 10min → 20min → cap at 30min */
    setTimeout(function(){
      if(!document.hidden) connectSSE();
    }, _sseRetryDelay);
    _sseRetryDelay = Math.min(_sseRetryDelay * 2, 1800000);
  };
}
if(!document.hidden){ connectSSE(); }
document.addEventListener('visibilitychange', function(){
  if(!document.hidden && !_sseActive) connectSSE();
});
</script>

<!-- ══════════════════════════════════════════════
     CANCEL ORDER MODAL
     ══════════════════════════════════════════════ -->
<style>
.cancel-overlay{
  position:fixed;inset:0;background:rgba(0,0,0,.45);z-index:1000;
  display:flex;align-items:center;justify-content:center;
  opacity:0;pointer-events:none;transition:opacity .2s;
}
.cancel-overlay.show{opacity:1;pointer-events:all;}
.cancel-modal{
  background:var(--surface);border-radius:18px;padding:28px 26px 22px;
  width:min(420px,92vw);box-shadow:0 20px 60px rgba(0,0,0,.25);
  transform:translateY(20px);transition:transform .25s;
}
.cancel-overlay.show .cancel-modal{transform:translateY(0);}
.cancel-modal-icon{
  width:54px;height:54px;border-radius:50%;background:#fee2e2;
  display:flex;align-items:center;justify-content:center;
  font-size:22px;color:#dc2626;margin:0 auto 14px;
}
.cancel-modal h3{text-align:center;font-size:17px;font-weight:700;margin-bottom:6px;}
.cancel-modal p{text-align:center;font-size:13px;color:var(--muted);margin-bottom:18px;line-height:1.5;}
.cancel-reason-label{font-size:12px;font-weight:600;color:var(--text);margin-bottom:6px;display:block;}
.cancel-reason-chips{display:flex;flex-wrap:wrap;gap:7px;margin-bottom:12px;}
.reason-chip{
  padding:6px 13px;border-radius:99px;border:1.5px solid var(--border);
  font-size:12px;font-weight:500;cursor:pointer;background:none;color:var(--text);
  transition:.15s;
}
.reason-chip:hover,.reason-chip.selected{
  border-color:#dc2626;background:#fee2e2;color:#dc2626;
}
.cancel-reason-input{
  width:100%;border:1.5px solid var(--border);border-radius:10px;
  padding:10px 13px;font-size:13px;color:var(--text);background:var(--surface);
  resize:none;font-family:inherit;outline:none;transition:.15s;
  min-height:80px;
}
.cancel-reason-input:focus{border-color:#dc2626;}
.cancel-char-count{font-size:10px;color:var(--muted);text-align:right;margin-top:4px;}
.cancel-modal-err{
  font-size:12px;color:#dc2626;font-weight:600;margin-top:8px;display:none;
}
.cancel-modal-actions{display:flex;gap:10px;margin-top:18px;}
.cancel-btn-go{
  flex:1;padding:11px;border-radius:10px;border:none;
  background:#dc2626;color:#fff;font-weight:700;font-size:14px;cursor:pointer;
  transition:.15s;
}
.cancel-btn-go:hover{background:#b91c1c;}
.cancel-btn-go:disabled{opacity:.55;cursor:not-allowed;}
.cancel-btn-back{
  flex:1;padding:11px;border-radius:10px;
  border:1.5px solid var(--border);background:none;
  color:var(--muted);font-weight:600;font-size:14px;cursor:pointer;
  transition:.15s;
}
.cancel-btn-back:hover{border-color:var(--primary);color:var(--primary);}
</style>

<div class="cancel-overlay" id="cancelOverlay" onclick="closeCancelModal(event)">
  <div class="cancel-modal">
    <div class="cancel-modal-icon"><i class="fa fa-xmark"></i></div>
    <h3>Cancel this order?</h3>
    <p>Please tell us why you're cancelling.<br>This helps us serve you better.</p>

    <!-- Payment-aware refund notice -->
    <div id="cancelRefundNotice" style="border-radius:12px;padding:13px 15px;margin-bottom:16px;font-size:13px;font-weight:500;line-height:1.5;display:flex;align-items:flex-start;gap:10px;"></div>

    <label class="cancel-reason-label">Quick reasons</label>
    <div class="cancel-reason-chips" id="reasonChips">
      <button class="reason-chip" onclick="selectChip(this,'Changed my mind')">Changed my mind</button>
      <button class="reason-chip" onclick="selectChip(this,'Ordered by mistake')">Ordered by mistake</button>
      <button class="reason-chip" onclick="selectChip(this,'Found a better price')">Found better price</button>
      <button class="reason-chip" onclick="selectChip(this,'Delivery taking too long')">Taking too long</button>
      <button class="reason-chip" onclick="selectChip(this,'Other')">Other</button>
    </div>

    <label class="cancel-reason-label" for="cancelReasonText">Details <span style="font-weight:400;color:var(--muted)">(optional)</span></label>
    <textarea class="cancel-reason-input" id="cancelReasonText"
              placeholder="Add more details here…" maxlength="300"
              oninput="updateCharCount()"></textarea>
    <div class="cancel-char-count"><span id="cancelCharCount">0</span>/300</div>
    <div class="cancel-modal-err" id="cancelErr">Please select a reason before cancelling.</div>

    <div class="cancel-modal-actions">
      <button class="cancel-btn-back" onclick="closeCancelModal()">Keep Order</button>
      <button class="cancel-btn-go"   id="cancelSubmitBtn" onclick="submitCancel()">
        <i class="fa fa-xmark"></i> Yes, Cancel
      </button>
    </div>
  </div>
</div>

<script>
var _cancelGroupId = null;
var _selectedChip  = null;

function openCancelModal(groupId, paymentMethod, amount){
  _cancelGroupId = groupId;
  _selectedChip  = null;
  document.getElementById('cancelReasonText').value = '';
  document.getElementById('cancelCharCount').textContent = '0';
  document.getElementById('cancelErr').style.display = 'none';
  document.querySelectorAll('.reason-chip').forEach(function(c){ c.classList.remove('selected'); });

  // Show payment-aware refund notice
  var notice = document.getElementById('cancelRefundNotice');
  var isOnline = paymentMethod === 'ONLINE' || paymentMethod === 'RAZORPAY';
  if(isOnline){
    notice.style.background = '#eff6ff';
    notice.style.border = '1.5px solid #bfdbfe';
    notice.style.color = '#1e40af';
    notice.innerHTML =
      '<i class="fa fa-rotate-left" style="margin-top:2px;color:#2563eb;flex-shrink:0;"></i>' +
      '<span><b>Refund notice:</b> Since you paid ₹' + amount + ' online, your money will be ' +
      'refunded to your original payment method within <b>5–7 business days</b> after cancellation.</span>';
  } else {
    notice.style.background = '#f0fdf4';
    notice.style.border = '1.5px solid #bbf7d0';
    notice.style.color = '#166534';
    notice.innerHTML =
      '<i class="fa fa-circle-check" style="margin-top:2px;color:#16a34a;flex-shrink:0;"></i>' +
      '<span><b>No payment made.</b> Since this was a Cash on Delivery order, ' +
      'no refund is needed — you haven\'t paid anything yet.</span>';
  }

  document.getElementById('cancelOverlay').classList.add('show');
}

function closeCancelModal(evt){
  if(evt && evt.target !== document.getElementById('cancelOverlay')) return;
  document.getElementById('cancelOverlay').classList.remove('show');
  _cancelGroupId = null;
  _selectedChip  = null;
}

function selectChip(el, val){
  document.querySelectorAll('.reason-chip').forEach(function(c){ c.classList.remove('selected'); });
  el.classList.add('selected');
  _selectedChip = val;
  document.getElementById('cancelErr').style.display = 'none';
  // Auto-fill textarea only if empty or was a previous chip
  var ta = document.getElementById('cancelReasonText');
  if(!ta.value.trim() || ta.dataset.fromChip === '1'){
    ta.value = (val === 'Other') ? '' : val;
    ta.dataset.fromChip = '1';
    updateCharCount();
  }
}

function updateCharCount(){
  var len = document.getElementById('cancelReasonText').value.length;
  document.getElementById('cancelCharCount').textContent = len;
  document.getElementById('cancelReasonText').dataset.fromChip = '0';
}

function submitCancel(){
  var reason = document.getElementById('cancelReasonText').value.trim();
  if(!_selectedChip && !reason){
    document.getElementById('cancelErr').style.display = 'block';
    return;
  }
  var finalReason = reason || _selectedChip;

  var btn = document.getElementById('cancelSubmitBtn');
  btn.disabled = true;
  btn.innerHTML = '<i class="fa fa-spinner fa-spin"></i> Cancelling…';

  window.location.href = 'cancelOrder?source=customer&id=' + _cancelGroupId
                       + '&reason=' + encodeURIComponent(finalReason);
}
</script>
</body>
</html>
