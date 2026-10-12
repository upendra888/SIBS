<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="com.sibs.model.User,java.sql.*,com.sibs.util.DBConnection" %>
<%
User user = (User)session.getAttribute("customer");
if(user == null){ response.sendRedirect("customer-login.jsp"); return; }

String orderIdStr = request.getParameter("orderId");
if(orderIdStr == null){ response.sendRedirect("my-orders.jsp"); return; }
int orderId = Integer.parseInt(orderIdStr);

// Fetch order info + destination address coords
double destLat = 0, destLng = 0;
String productName = "", orderStatus = "";
Connection con = null; PreparedStatement ps = null; ResultSet rs = null;
try {
    con = DBConnection.getConnection();
    ps = con.prepareStatement(
        "SELECT o.status, p.name AS product_name, " +
        "       COALESCE(a.latitude,0) AS dest_lat, " +
        "       COALESCE(a.longitude,0) AS dest_lng " +
        "FROM orders o " +
        "JOIN order_items oi ON oi.order_id = o.id " +
        "JOIN products p     ON oi.product_id = p.id " +
        "JOIN addresses a    ON o.address_id = a.id " +
        "WHERE o.id = ? AND o.user_id = ? LIMIT 1"
    );
    ps.setInt(1, orderId);
    ps.setInt(2, user.getId());
    rs = ps.executeQuery();
    if(rs.next()){
        orderStatus = rs.getString("status");
        productName = rs.getString("product_name");
        destLat     = rs.getDouble("dest_lat");
        destLng     = rs.getDouble("dest_lng");
    } else {
        response.sendRedirect("my-orders.jsp");
        return;
    }
} finally {
    if(rs!=null)try{rs.close();}catch(Exception e){}
    if(ps!=null)try{ps.close();}catch(Exception e){}
    if(con!=null)try{con.close();}catch(Exception e){}
}
%>
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Track Order #<%=orderId%> — SIBS</title>
<link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/leaflet.min.css">
<script src="https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/leaflet.min.js"></script>
<style>
:root{
  --bg:#eef2ff;--surface:#fff;--border:#dde3f5;--text:#0d1321;--muted:#6b7a9e;
  --primary:#4361ee;--primary-light:#eef0fd;--success:#22c55e;--success-light:#dcfce7;
  --danger:#ef4444;--brand:#4361ee;
}
[data-theme="dark"]{
  --bg:#0b0f1a;--surface:#131929;--border:#1e2a42;--text:#e8eeff;--muted:#5a6a8a;
  --primary:#5878f5;--primary-light:#1a2040;
}
*{margin:0;padding:0;box-sizing:border-box;font-family:'DM Sans',sans-serif;}
body{background:var(--bg);color:var(--text);display:flex;flex-direction:column;height:100vh;overflow:hidden;}
.topbar{background:var(--surface);border-bottom:1px solid var(--border);padding:0 16px;
  height:56px;display:flex;align-items:center;gap:12px;flex-shrink:0;
  box-shadow:0 2px 8px rgba(67,97,238,.07);}
.back-btn{width:32px;height:32px;border:1px solid var(--border);border-radius:8px;
  background:none;display:flex;align-items:center;justify-content:center;
  cursor:pointer;color:var(--muted);font-size:13px;text-decoration:none;}
.back-btn:hover{background:var(--primary-light);color:var(--primary);}
.topbar-brand{font-weight:800;font-size:15px;color:var(--primary);}
.topbar-title{font-size:13px;font-weight:600;}
.dark-btn{margin-left:auto;width:32px;height:32px;border:1px solid var(--border);
  border-radius:8px;background:none;cursor:pointer;color:var(--muted);
  display:flex;align-items:center;justify-content:center;font-size:13px;}

#trackMap{flex:1;z-index:1;}

.bottom-sheet{
  background:var(--surface);
  border-top:1px solid var(--border);
  padding:14px 16px 20px;
  flex-shrink:0;
  box-shadow:0 -4px 20px rgba(67,97,238,.08);
}
.rider-row{display:flex;align-items:center;gap:12px;margin-bottom:12px;}
.rider-avatar{width:42px;height:42px;border-radius:50%;background:var(--primary-light);
  display:flex;align-items:center;justify-content:center;font-size:18px;flex-shrink:0;}
.rider-info{flex:1;}
.rider-name{font-size:14px;font-weight:700;}
.rider-sub{font-size:12px;color:var(--muted);margin-top:2px;}
.live-chip{display:flex;align-items:center;gap:5px;font-size:11px;font-weight:600;
  color:var(--success);background:var(--success-light);padding:4px 10px;
  border-radius:999px;}
.live-dot{width:7px;height:7px;border-radius:50%;background:var(--success);
  animation:blink 1.4s infinite;}
@keyframes blink{0%,100%{opacity:1;}50%{opacity:.3;}}
.status-steps{display:flex;gap:0;background:var(--bg);border-radius:10px;
  padding:10px 14px;justify-content:space-between;}
.sstep{display:flex;flex-direction:column;align-items:center;gap:4px;flex:1;}
.sstep-dot{width:24px;height:24px;border-radius:50%;display:flex;align-items:center;
  justify-content:center;font-size:10px;font-weight:700;}
.sstep-done{background:var(--success);color:#fff;}
.sstep-active{background:var(--primary);color:#fff;box-shadow:0 0 0 4px rgba(67,97,238,.2);}
.sstep-idle{background:var(--border);color:var(--muted);}
.sstep-label{font-size:9px;color:var(--muted);text-align:center;}
.sline{flex:1;height:2px;background:var(--border);margin:0 4px;margin-bottom:14px;}
.sline-done{background:var(--success);}
.updated-row{font-size:11px;color:var(--muted);text-align:center;margin-top:10px;}
.no-gps-msg{padding:20px;text-align:center;color:var(--muted);font-size:13px;}
</style>
</head>
<body>

<div class="topbar">
  <a class="back-btn" href="my-orders.jsp"><i class="fa fa-arrow-left"></i></a>
  <span class="topbar-brand">SIBS</span>
  <span class="topbar-title">Tracking Order #<%=orderId%></span>
  <button class="dark-btn" onclick="toggleDark()"><i class="fa fa-moon"></i></button>
</div>

<div id="trackMap"></div>

<div class="bottom-sheet">
  <div class="rider-row">
    <div class="rider-avatar">🛵</div>
    <div class="rider-info">
      <div class="rider-name" id="riderName">Locating your delivery partner…</div>
      <div class="rider-sub" id="riderPhone"></div>
    </div>
    <div class="live-chip" id="liveChip" style="display:none;">
      <div class="live-dot"></div> Live
    </div>
  </div>

  <!-- Status Steps -->
  <%
    String os = orderStatus != null ? orderStatus.toUpperCase() : "";
    int ostep = 0;
    if("PICKED_UP".equals(os)||"OTP_VERIFIED".equals(os)) ostep=2;
    else if("DELIVERED".equals(os)) ostep=3;
    String os1=ostep>=1?"sstep-dot sstep-done":"sstep-dot sstep-active";
    String os2=ostep>=2?"sstep-dot sstep-done":ostep==1?"sstep-dot sstep-active":"sstep-dot sstep-idle";
    String os3=ostep>=3?"sstep-dot sstep-done":ostep==2?"sstep-dot sstep-active":"sstep-dot sstep-idle";
    String ol1=ostep>=2?"sline sline-done":"sline";
    String ol2=ostep>=3?"sline sline-done":"sline";
  %>
  <div class="status-steps">
    <div class="sstep">
      <div class="<%=os1%>"><i class="fa fa-check" style="font-size:9px;"></i></div>
      <div class="sstep-label">Order<br>Placed</div>
    </div>
    <div class="<%=ol1%>"></div>
    <div class="sstep">
      <div class="<%=os2%>"><%=ostep>=2?"<i class='fa fa-check' style='font-size:9px;'></i>":"2"%></div>
      <div class="sstep-label">Picked<br>Up</div>
    </div>
    <div class="<%=ol2%>"></div>
    <div class="sstep">
      <div class="<%=os3%>"><%=ostep>=3?"<i class='fa fa-check' style='font-size:9px;'></i>":"3"%></div>
      <div class="sstep-label">Delivered<br>to you</div>
    </div>
  </div>

  <div class="updated-row" id="updatedRow">Waiting for location data…</div>
</div>

<script>
function toggleDark(){
  const h=document.documentElement,d=h.getAttribute('data-theme')==='dark';
  h.setAttribute('data-theme',d?'light':'dark');
  localStorage.setItem('sibs-theme',d?'light':'dark');
}
(function(){const t=localStorage.getItem('sibs-theme');if(t)document.documentElement.setAttribute('data-theme',t);})();

var destLat = <%=destLat%>;
var destLng = <%=destLng%>;
var orderId = <%=orderId%>;
var hasDestCoords = destLat !== 0 && destLng !== 0;

var initLat = hasDestCoords ? destLat : 17.3850;
var initLng = hasDestCoords ? destLng : 78.4867;

var map = L.map('trackMap').setView([initLat, initLng], hasDestCoords ? 14 : 12);
L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',{
  attribution:'© OpenStreetMap contributors', maxZoom:19
}).addTo(map);

// Destination marker
var destIcon = L.divIcon({
  html:'<div style="background:#ef4444;width:16px;height:16px;border-radius:50% 50% 50% 0;transform:rotate(-45deg);border:3px solid #fff;box-shadow:0 2px 8px rgba(239,68,68,.5);"></div>',
  iconSize:[16,16],iconAnchor:[8,16]
});
if(hasDestCoords){
  L.marker([destLat,destLng],{icon:destIcon})
    .addTo(map).bindPopup('<b>Your Address</b>').openPopup();
}

// Rider marker
var riderIcon = L.divIcon({
  html:'<div style="background:#4361ee;width:20px;height:20px;border-radius:50%;border:3px solid #fff;box-shadow:0 2px 10px rgba(67,97,238,.7);display:flex;align-items:center;justify-content:center;font-size:10px;">🛵</div>',
  iconSize:[20,20],iconAnchor:[10,10]
});
var riderMarker = null;
var routeLine   = null;

function fetchLocation(){
  fetch('getDeliveryLocation?orderId='+orderId)
    .then(function(r){return r.json();})
    .then(function(d){
      if(d.error) return;

      document.getElementById('riderName').textContent   = d.name;
      document.getElementById('riderPhone').textContent  = d.phone || '';
      document.getElementById('liveChip').style.display  = 'flex';
      document.getElementById('updatedRow').textContent  = 'Last updated: ' + d.updatedAt;

      var rLat = parseFloat(d.lat);
      var rLng = parseFloat(d.lng);

      if(riderMarker){
        riderMarker.setLatLng([rLat,rLng]);
      } else {
        riderMarker = L.marker([rLat,rLng],{icon:riderIcon})
          .addTo(map).bindPopup('<b>'+d.name+'</b><br>Your delivery partner');
      }

      // Draw route line
      if(hasDestCoords){
        if(routeLine) map.removeLayer(routeLine);
        routeLine = L.polyline([[rLat,rLng],[destLat,destLng]],{
          color:'#4361ee',weight:4,opacity:.7,dashArray:'8,6'
        }).addTo(map);
        map.fitBounds([[rLat,rLng],[destLat,destLng]],{padding:[50,50]});
      } else {
        map.setView([rLat,rLng],15);
      }
    })
    .catch(function(){});
}

fetchLocation();
setInterval(fetchLocation, 8000);
</script>
</body>
</html>