<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="com.sibs.model.User" %>
<%
User admin = (User)session.getAttribute("admin");
if(admin == null){ response.sendRedirect("login.jsp"); return; }
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Live Rider Map · SIBS Admin</title>
<link href="https://fonts.googleapis.com/css2?family=Syne:wght@600;700;800&family=DM+Sans:wght@400;500;600&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/leaflet.min.css">
<script src="https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/leaflet.min.js"></script>
<style>
:root{--brand:#7c3aed;--brand-light:#ede9fe;--surface:#fff;--bg:#f3f1fb;--bg2:#edeaf8;
  --text:#0d0d14;--muted:#6b6882;--border:rgba(124,58,237,.12);--green:#16a34a;--green-bg:#dcfce7;
  --amber:#b45309;--amber-bg:#fef3c7;--red:#dc2626;--red-bg:#fee2e2;
  --radius:14px;--radius-sm:9px;--ff-head:'Syne',sans-serif;--ff-body:'DM Sans',sans-serif;}
*,*::before,*::after{margin:0;padding:0;box-sizing:border-box;}
html,body{height:100%;font-family:var(--ff-body);background:var(--bg);color:var(--text);}
.topbar{background:var(--surface);border-bottom:1px solid var(--border);padding:0 18px;height:56px;
  display:flex;align-items:center;gap:12px;position:sticky;top:0;z-index:200;
  box-shadow:0 2px 12px rgba(124,58,237,.1);}
.topbar-title{font-family:var(--ff-head);font-size:16px;font-weight:700;flex:1;}
.live-chip{background:var(--green-bg);color:var(--green);font-size:11px;font-weight:700;
  padding:4px 10px;border-radius:999px;display:flex;align-items:center;gap:5px;}
.blink{width:7px;height:7px;border-radius:50%;background:var(--green);animation:blink 1.2s infinite;}
@keyframes blink{0%,100%{opacity:1;}50%{opacity:.3;}}
.back-btn{color:var(--muted);font-size:14px;text-decoration:none;}
.layout{display:flex;height:calc(100vh - 56px);}
.sidebar{width:300px;background:var(--surface);border-right:1px solid var(--border);
  overflow-y:auto;flex-shrink:0;}
.sidebar-header{padding:14px 16px;border-bottom:1px solid var(--border);
  font-family:var(--ff-head);font-size:13px;font-weight:700;display:flex;align-items:center;justify-content:space-between;}
.rider-row{padding:12px 16px;border-bottom:1px solid var(--border);cursor:pointer;transition:background .2s;}
.rider-row:hover{background:var(--bg);}
.rider-row.selected{background:var(--brand-light);}
.rider-top{display:flex;align-items:center;gap:10px;}
.rider-avatar{width:36px;height:36px;border-radius:50%;background:var(--brand);color:#fff;
  display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:700;flex-shrink:0;}
.rider-name{font-size:13px;font-weight:600;}
.rider-meta{font-size:11px;color:var(--muted);}
.status-dot{width:8px;height:8px;border-radius:50%;flex-shrink:0;}
.dot-online{background:var(--green);}
.dot-break{background:var(--amber);}
.dot-offline{background:var(--muted);}
.rider-order{font-size:11px;padding:3px 8px;border-radius:6px;
  background:var(--brand-light);color:var(--brand);font-weight:600;margin-top:4px;display:inline-block;}
.no-location{font-size:11px;color:var(--muted);margin-top:4px;}
#map{flex:1;}
.map-legend{position:absolute;bottom:20px;right:20px;z-index:500;background:var(--surface);
  border:1px solid var(--border);border-radius:var(--radius-sm);padding:12px 14px;
  box-shadow:0 4px 16px rgba(0,0,0,.1);}
.legend-title{font-family:var(--ff-head);font-size:11px;font-weight:700;margin-bottom:8px;color:var(--muted);}
.legend-item{display:flex;align-items:center;gap:8px;font-size:12px;margin-bottom:4px;}
.legend-dot{width:10px;height:10px;border-radius:50%;}
.refresh-btn{padding:6px 14px;background:var(--brand);color:#fff;border:none;border-radius:6px;
  font-size:12px;font-weight:600;cursor:pointer;display:flex;align-items:center;gap:5px;}
@media(max-width:640px){.sidebar{display:none;}.layout{display:block;}.layout #map{height:calc(100vh - 56px);}}
</style>
</head>
<body>
<div class="topbar">
  <a href="dashboard.jsp" class="back-btn"><i class="fa fa-arrow-left"></i></a>
  <span class="topbar-title">🗺 Live Rider Map</span>
  <div class="live-chip"><span class="blink"></span> LIVE</div>
  <button class="refresh-btn" onclick="loadRiders()"><i class="fa fa-rotate-right"></i> Refresh</button>
</div>

<div class="layout">
  <div class="sidebar">
    <div class="sidebar-header">
      <span>Active Riders</span>
      <span id="riderCount" style="font-size:11px;color:var(--muted);font-weight:400;">Loading…</span>
    </div>
    <div id="riderList"></div>
  </div>

  <div id="map" style="position:relative;">
    <div class="map-legend">
      <div class="legend-title">RIDER STATUS</div>
      <div class="legend-item"><div class="legend-dot" style="background:#16a34a;"></div> Online</div>
      <div class="legend-item"><div class="legend-dot" style="background:#b45309;"></div> On Break</div>
      <div class="legend-item"><div class="legend-dot" style="background:#9ca3af;"></div> Offline</div>
    </div>
  </div>
</div>

<script>
var map = L.map('map').setView([17.385, 78.4867], 12); // default Hyderabad
L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',{
  attribution:'© OpenStreetMap contributors'
}).addTo(map);

var markers = {};
var allRiders = [];

function makeIcon(color){
  return L.divIcon({
    html: '<div style="width:18px;height:18px;border-radius:50%;background:'+color+';border:3px solid #fff;box-shadow:0 2px 8px rgba(0,0,0,.3);"></div>',
    iconSize:[18,18], iconAnchor:[9,9]
  });
}

function loadRiders(){
  fetch('getDeliveryLocations')
    .then(function(r){ return r.json(); })
    .then(function(data){
      allRiders = data.riders || [];
      renderSidebar(allRiders);
      updateMarkers(allRiders);
      document.getElementById('riderCount').textContent = allRiders.length + ' riders';
    })
    .catch(function(e){
      document.getElementById('riderCount').textContent = 'Error loading';
      console.error(e);
    });
}

function getColor(status){
  if(status==='ONLINE') return '#16a34a';
  if(status==='ON_BREAK') return '#b45309';
  return '#9ca3af';
}

function renderSidebar(riders){
  var list = document.getElementById('riderList');
  if(!riders.length){ list.innerHTML='<div style="padding:24px;text-align:center;color:var(--muted);font-size:13px;">No riders online.</div>'; return; }
  list.innerHTML = riders.map(function(r){
    var color = getColor(r.shiftStatus||'OFFLINE');
    var initials = r.name ? r.name.substring(0,2).toUpperCase() : 'RR';
    var hasLoc = r.lat && r.lng;
    return '<div class="rider-row" onclick="focusRider('+r.id+')" id="sr'+r.id+'">' +
      '<div class="rider-top">' +
        '<div class="rider-avatar">'+initials+'</div>' +
        '<div style="flex:1;">' +
          '<div class="rider-name">'+r.name+'</div>' +
          '<div class="rider-meta">'+r.phone+'</div>' +
        '</div>' +
        '<div class="status-dot" style="background:'+color+';"></div>' +
      '</div>' +
      (r.orderId ? '<div class="rider-order"><i class="fa fa-box"></i> Order #'+r.orderId+'</div>' : '') +
      (!hasLoc ? '<div class="no-location"><i class="fa fa-location-slash"></i> No GPS data</div>' : '') +
    '</div>';
  }).join('');
}

function updateMarkers(riders){
  // Remove stale markers
  Object.keys(markers).forEach(function(id){
    if(!riders.find(function(r){ return r.id==id; })){
      map.removeLayer(markers[id]);
      delete markers[id];
    }
  });
  riders.forEach(function(r){
    if(!r.lat || !r.lng) return;
    var color = getColor(r.shiftStatus||'OFFLINE');
    var popup = '<b>'+r.name+'</b><br>'+
                '<span style="font-size:12px;">'+( r.shiftStatus||'OFFLINE' )+'</span><br>' +
                (r.orderId ? '<span style="font-size:12px;">Order #'+r.orderId+'</span><br>' : '') +
                '<span style="font-size:11px;color:#666;">Updated: '+(r.updatedAt||'–')+'</span>';
    if(markers[r.id]){
      markers[r.id].setLatLng([r.lat, r.lng]);
      markers[r.id].setIcon(makeIcon(color));
      markers[r.id].getPopup().setContent(popup);
    } else {
      markers[r.id] = L.marker([r.lat, r.lng], {icon: makeIcon(color)})
        .addTo(map).bindPopup(popup);
    }
  });
}

function focusRider(id){
  var rider = allRiders.find(function(r){ return r.id==id; });
  if(rider && rider.lat && rider.lng){
    map.setView([rider.lat, rider.lng], 15);
    if(markers[id]) markers[id].openPopup();
  }
  document.querySelectorAll('.rider-row').forEach(function(el){ el.classList.remove('selected'); });
  var el=document.getElementById('sr'+id); if(el) el.classList.add('selected');
}

// Load on start then every 15s
loadRiders();
setInterval(loadRiders, 15000);
</script>
</body>
</html>
