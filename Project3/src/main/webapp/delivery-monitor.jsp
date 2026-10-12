<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.util.*,com.sibs.dao.DeliveryBoyDAO,com.sibs.model.DeliveryBoy,com.sibs.model.User,com.sibs.util.DBConnection,java.sql.*" %>
<%
User user = (User)session.getAttribute("user");
if(user == null || (!"STAFF".equals(user.getRole()) && !"ADMIN".equals(user.getRole()))){
    response.sendRedirect("login.jsp"); return;
}

DeliveryBoyDAO dao = new DeliveryBoyDAO();
List<DeliveryBoy> boys = dao.getAllWithStats();

// Build map of id -> shift start epoch ms directly from DB
java.util.Map<Integer,Long> shiftEpochMap = new java.util.HashMap<>();
try (java.sql.Connection _con = DBConnection.getConnection();
     java.sql.PreparedStatement _ps = _con.prepareStatement(
         "SELECT id, UNIX_TIMESTAMP(shift_started_at)*1000 AS epoch_ms FROM delivery_boys WHERE shift_started_at IS NOT NULL");
     java.sql.ResultSet _rs = _ps.executeQuery()) {
    while (_rs.next()) {
        shiftEpochMap.put(_rs.getInt("id"), _rs.getLong("epoch_ms"));
    }
} catch (Exception _e) { _e.printStackTrace(); }

int totalBoys    = boys.size();
int onlineCount  = 0, breakCount = 0, offlineCount = 0, workingCount = 0;
for(DeliveryBoy b : boys){
    String ss = b.getShiftStatus();
    if("ONLINE".equals(ss))        { onlineCount++;  if(b.getActiveOrders()>0) workingCount++; }
    else if("ON_BREAK".equals(ss)) breakCount++;
    else                            offlineCount++;
}
%>
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Delivery Monitor — SIBS Staff</title>
<link href="https://fonts.googleapis.com/css2?family=Syne:wght@500;600;700;800&family=DM+Sans:wght@300;400;500;600&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<style>
:root{
  --brand:#7c3aed;--brand-lt:#ede9fe;--brand-dk:#4c1d95;
  --surface:#fff;--bg:#f5f3ff;--bg2:#edeaf8;
  --text:#0d0d14;--muted:#6b6882;--border:rgba(124,58,237,.13);
  --green:#16a34a;--green-bg:#dcfce7;--green-border:rgba(22,163,74,.2);
  --amber:#b45309;--amber-bg:#fef3c7;--amber-border:rgba(180,83,9,.2);
  --red:#dc2626;--red-bg:#fee2e2;--red-border:rgba(220,38,38,.2);
  --blue:#1d4ed8;--blue-bg:#eff6ff;--blue-border:rgba(29,78,216,.18);
  --radius:14px;--radius-sm:9px;
  --shadow:0 2px 16px rgba(124,58,237,.10);--shadow-lg:0 8px 40px rgba(124,58,237,.16);
  --ff-head:'Syne',sans-serif;--ff:'DM Sans',sans-serif;
}
[data-theme="dark"]{
  --brand:#a78bfa;--brand-lt:#2e1f5e;--brand-dk:#c4b5fd;
  --surface:#13111f;--bg:#0d0b18;--bg2:#1a1730;--text:#f0eeff;--muted:#9791b8;
  --border:rgba(167,139,250,.14);--green:#4ade80;--green-bg:#052e16;
  --amber:#fcd34d;--amber-bg:#451a03;--red:#f87171;--red-bg:#450a0a;
  --blue:#93c5fd;--blue-bg:#0c1a3d;
  --shadow:0 2px 20px rgba(0,0,0,.4);--shadow-lg:0 8px 40px rgba(0,0,0,.5);
}
*,*::before,*::after{margin:0;padding:0;box-sizing:border-box;}
html{font-family:var(--ff);font-size:15px;color:var(--text);background:var(--bg);}
body{min-height:100vh;}
a{text-decoration:none;color:inherit;}
button{font-family:var(--ff);cursor:pointer;}

/* ── TOPBAR ── */
.topbar{background:var(--surface);border-bottom:1px solid var(--border);
  padding:0 24px;height:60px;display:flex;align-items:center;
  justify-content:space-between;position:sticky;top:0;z-index:100;
  box-shadow:var(--shadow);}
.topbar-left{display:flex;align-items:center;gap:12px;}
.back-link{display:flex;align-items:center;gap:6px;font-size:13px;
  color:var(--muted);padding:6px 10px;border-radius:var(--radius-sm);
  border:1px solid var(--border);background:var(--bg);transition:all .2s;}
.back-link:hover{color:var(--brand);border-color:var(--brand);}
.page-title{font-family:var(--ff-head);font-size:16px;font-weight:700;
  display:flex;align-items:center;gap:8px;}
.live-chip{font-size:10px;font-weight:700;padding:3px 8px;border-radius:999px;
  background:var(--green-bg);color:var(--green);border:1px solid var(--green-border);
  display:flex;align-items:center;gap:5px;animation:livePulse 2s infinite;}
@keyframes livePulse{0%,100%{opacity:1;}50%{opacity:.6;}}
.live-dot{width:6px;height:6px;border-radius:50%;background:var(--green);}
.topbar-right{display:flex;align-items:center;gap:10px;}
.icon-btn{width:36px;height:36px;border:1px solid var(--border);border-radius:var(--radius-sm);
  background:var(--bg);color:var(--muted);display:flex;align-items:center;
  justify-content:center;font-size:14px;transition:all .2s;}
.icon-btn:hover{background:var(--brand-lt);color:var(--brand);}
.refresh-spin{animation:spin .6s linear;}
@keyframes spin{from{transform:rotate(0)}to{transform:rotate(360deg)}}
.last-updated{font-size:11px;color:var(--muted);}

/* ── CONTENT ── */
.page{padding:24px;max-width:1280px;margin:0 auto;}

/* ── SUMMARY TILES ── */
.summary-grid{display:grid;grid-template-columns:repeat(5,1fr);gap:12px;margin-bottom:24px;}
@media(max-width:900px){.summary-grid{grid-template-columns:repeat(3,1fr);}}
@media(max-width:560px){.summary-grid{grid-template-columns:repeat(2,1fr);}}
.tile{background:var(--surface);border:1px solid var(--border);border-radius:var(--radius);
  padding:16px;display:flex;align-items:center;gap:14px;
  transition:transform .2s,box-shadow .2s;cursor:pointer;}
.tile:hover{transform:translateY(-2px);box-shadow:var(--shadow);}
.tile.active-filter{outline:2px solid var(--brand);outline-offset:2px;}
.tile-icon{width:42px;height:42px;border-radius:12px;display:flex;
  align-items:center;justify-content:center;font-size:16px;flex-shrink:0;}
.tile-num{font-family:var(--ff-head);font-size:26px;font-weight:800;line-height:1;}
.tile-lbl{font-size:11px;color:var(--muted);margin-top:2px;}

/* ── CONTROLS BAR ── */
.controls{display:flex;gap:10px;margin-bottom:18px;flex-wrap:wrap;align-items:center;}
.search-wrap{flex:1;min-width:220px;position:relative;}
.search-wrap i{position:absolute;left:12px;top:50%;transform:translateY(-50%);
  color:var(--muted);font-size:13px;}
.search-input{width:100%;padding:10px 14px 10px 36px;border:1px solid var(--border);
  border-radius:var(--radius-sm);background:var(--surface);color:var(--text);
  font-family:var(--ff);font-size:13px;outline:none;transition:border-color .2s;}
.search-input:focus{border-color:var(--brand);}
.view-toggle{display:flex;border:1px solid var(--border);border-radius:var(--radius-sm);overflow:hidden;}
.view-btn{padding:9px 14px;background:var(--surface);border:none;color:var(--muted);
  font-size:13px;transition:all .2s;cursor:pointer;}
.view-btn.active{background:var(--brand);color:#fff;}

/* ── TABLE VIEW ── */
.table-wrap{background:var(--surface);border:1px solid var(--border);
  border-radius:var(--radius);overflow:hidden;box-shadow:var(--shadow);}
table{width:100%;border-collapse:collapse;}
th{padding:12px 16px;text-align:left;font-size:11px;font-weight:600;
  color:var(--muted);text-transform:uppercase;letter-spacing:.5px;
  background:var(--bg);border-bottom:1px solid var(--border);}
td{padding:14px 16px;font-size:13px;border-bottom:1px solid var(--border);
  vertical-align:middle;}
tbody tr:last-child td{border-bottom:none;}
tbody tr:hover{background:var(--bg);}
tbody tr.hidden-row{display:none;}

/* ── CARD VIEW ── */
.cards-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(300px,1fr));
  gap:14px;}
.boy-card{background:var(--surface);border:1px solid var(--border);
  border-radius:var(--radius);overflow:hidden;transition:transform .2s,box-shadow .2s;}
.boy-card:hover{transform:translateY(-3px);box-shadow:var(--shadow-lg);}
.boy-card.hidden-row{display:none;}
.card-top{padding:16px 16px 12px;display:flex;align-items:center;gap:12px;
  border-bottom:1px solid var(--border);}
.avatar{width:44px;height:44px;border-radius:50%;background:linear-gradient(135deg,#6d28d9,#4c1d95);
  display:flex;align-items:center;justify-content:center;
  color:#fff;font-weight:700;font-size:16px;flex-shrink:0;position:relative;}
.presence-ring{position:absolute;inset:-3px;border-radius:50%;border:2.5px solid transparent;}
.ring-online{border-color:var(--green);}
.ring-break{border-color:var(--amber);}
.ring-offline{border-color:var(--muted);}
.boy-info{flex:1;}
.boy-name{font-family:var(--ff-head);font-size:14px;font-weight:700;}
.boy-phone{font-size:12px;color:var(--muted);margin-top:1px;}
.card-body{padding:12px 16px;}
.card-row{display:flex;justify-content:space-between;align-items:center;
  padding:6px 0;border-bottom:1px solid var(--border);font-size:12px;}
.card-row:last-child{border-bottom:none;}
.card-row-label{color:var(--muted);display:flex;align-items:center;gap:6px;}
.card-row-val{font-weight:600;}
.card-footer{padding:10px 16px;background:var(--bg);display:flex;
  gap:8px;border-top:1px solid var(--border);}

/* ── SHARED BADGES ── */
.shift-badge{display:inline-flex;align-items:center;gap:5px;padding:4px 10px;
  border-radius:999px;font-size:11px;font-weight:700;}
.shift-online{background:var(--green-bg);color:var(--green);border:1px solid var(--green-border);}
.shift-break{background:var(--amber-bg);color:var(--amber);border:1px solid var(--amber-border);}
.shift-offline{background:var(--bg2);color:var(--muted);border:1px solid var(--border);}
.shift-working{background:var(--blue-bg);color:var(--blue);border:1px solid var(--blue-border);}
.dot{width:7px;height:7px;border-radius:50%;flex-shrink:0;}
.dot-green{background:var(--green);}
.dot-amber{background:var(--amber);}
.dot-muted{background:var(--muted);}
.dot-blue{background:var(--blue);}

.shift-timer{font-family:var(--ff-head);font-weight:700;
  font-size:13px;color:var(--brand);letter-spacing:.5px;}

.orders-chip{display:inline-flex;align-items:center;gap:4px;padding:3px 9px;
  border-radius:999px;font-size:11px;font-weight:600;
  background:var(--brand-lt);color:var(--brand);}

/* action buttons */
.btn-sm{padding:6px 12px;border-radius:7px;font-size:12px;font-weight:600;
  border:none;display:inline-flex;align-items:center;gap:5px;transition:all .2s;cursor:pointer;}
.btn-view{background:var(--brand-lt);color:var(--brand);}
.btn-view:hover{background:var(--brand);color:#fff;}
.btn-call{background:var(--green-bg);color:var(--green);}
.btn-call:hover{background:var(--green);color:#fff;}

/* avatar / name cell in table */
.name-cell{display:flex;align-items:center;gap:10px;}
.tbl-avatar{width:34px;height:34px;border-radius:50%;background:linear-gradient(135deg,#6d28d9,#4c1d95);
  display:flex;align-items:center;justify-content:center;
  color:#fff;font-size:12px;font-weight:700;flex-shrink:0;}

/* ── EMPTY STATE ── */
.empty-state{text-align:center;padding:64px 20px;color:var(--muted);}
.empty-icon{font-size:48px;opacity:.2;display:block;margin-bottom:12px;}
.empty-title{font-family:var(--ff-head);font-size:16px;font-weight:700;
  color:var(--text);margin-bottom:6px;}

/* ── MODAL (Activity Log) ── */
.modal-overlay{display:none;position:fixed;inset:0;background:rgba(0,0,0,.5);
  z-index:300;align-items:center;justify-content:center;padding:20px;}
.modal-overlay.open{display:flex;}
.modal-box{background:var(--surface);border-radius:var(--radius);
  max-width:500px;width:100%;box-shadow:var(--shadow-lg);
  animation:modalIn .25s ease;overflow:hidden;}
@keyframes modalIn{from{opacity:0;transform:scale(.95);}to{opacity:1;transform:none;}}
.modal-header{padding:18px 20px;border-bottom:1px solid var(--border);
  display:flex;justify-content:space-between;align-items:center;}
.modal-title{font-family:var(--ff-head);font-size:15px;font-weight:700;}
.modal-close{width:30px;height:30px;border-radius:7px;border:1px solid var(--border);
  background:var(--bg);color:var(--muted);display:flex;align-items:center;
  justify-content:center;cursor:pointer;font-size:14px;}
.modal-body{padding:20px;}
.stat-row-modal{display:grid;grid-template-columns:1fr 1fr;gap:10px;margin-bottom:16px;}
.stat-chip{background:var(--bg);border:1px solid var(--border);border-radius:var(--radius-sm);
  padding:12px 14px;}
.stat-chip-num{font-family:var(--ff-head);font-size:20px;font-weight:700;}
.stat-chip-lbl{font-size:11px;color:var(--muted);margin-top:2px;}
.info-row{display:flex;justify-content:space-between;padding:8px 0;
  border-bottom:1px solid var(--border);font-size:13px;}
.info-row:last-child{border-bottom:none;}
.info-label{color:var(--muted);}
.info-val{font-weight:600;}

@media(max-width:640px){
  .summary-grid{grid-template-columns:repeat(2,1fr);}
  .topbar{padding:0 14px;}
  .page{padding:14px;}
}
</style>
</head>
<body>

<div class="topbar">
  <div class="topbar-left">
    <a href="staff-dashboard.jsp" class="back-link">
      <i class="fa fa-arrow-left"></i> Dashboard
    </a>
    <div class="page-title">
      <i class="fa fa-motorcycle" style="color:var(--brand);"></i>
      Delivery Monitor
      <span class="live-chip"><span class="live-dot"></span>LIVE</span>
    </div>
  </div>
  <div class="topbar-right">
    <span class="last-updated" id="lastUpdatedLbl">
      Updated: <span id="lastUpdatedTime">just now</span>
    </span>
    <button class="icon-btn" onclick="manualRefresh()" title="Refresh">
      <i class="fa fa-rotate" id="refreshIcon"></i>
    </button>
    <button class="icon-btn" onclick="toggleDark()" title="Dark mode">
      <i class="fa fa-moon"></i>
    </button>
  </div>
</div>

<div class="page">

  <!-- ═══ SUMMARY TILES ═══ -->
  <div class="summary-grid">
    <div class="tile" onclick="filterTile('ALL')" id="tile-ALL">
      <div class="tile-icon" style="background:var(--brand-lt);">
        <i class="fa fa-users" style="color:var(--brand);"></i>
      </div>
      <div>
        <div class="tile-num"><%=totalBoys%></div>
        <div class="tile-lbl">Total Partners</div>
      </div>
    </div>
    <div class="tile" onclick="filterTile('WORKING')" id="tile-WORKING">
      <div class="tile-icon" style="background:var(--blue-bg);">
        <i class="fa fa-person-biking" style="color:var(--blue);"></i>
      </div>
      <div>
        <div class="tile-num" style="color:var(--blue);"><%=workingCount%></div>
        <div class="tile-lbl">On Delivery</div>
      </div>
    </div>
    <div class="tile" onclick="filterTile('ONLINE')" id="tile-ONLINE">
      <div class="tile-icon" style="background:var(--green-bg);">
        <i class="fa fa-circle-check" style="color:var(--green);"></i>
      </div>
      <div>
        <div class="tile-num" style="color:var(--green);"><%=onlineCount%></div>
        <div class="tile-lbl">Online (Idle)</div>
      </div>
    </div>
    <div class="tile" onclick="filterTile('ON_BREAK')" id="tile-ON_BREAK">
      <div class="tile-icon" style="background:var(--amber-bg);">
        <i class="fa fa-pause-circle" style="color:var(--amber);"></i>
      </div>
      <div>
        <div class="tile-num" style="color:var(--amber);"><%=breakCount%></div>
        <div class="tile-lbl">On Break</div>
      </div>
    </div>
    <div class="tile" onclick="filterTile('OFFLINE')" id="tile-OFFLINE">
      <div class="tile-icon" style="background:var(--bg2);">
        <i class="fa fa-moon" style="color:var(--muted);"></i>
      </div>
      <div>
        <div class="tile-num" style="color:var(--muted);"><%=offlineCount%></div>
        <div class="tile-lbl">Offline</div>
      </div>
    </div>
  </div>

  <!-- ═══ CONTROLS ═══ -->
  <div class="controls">
    <div class="search-wrap">
      <i class="fa fa-magnifying-glass"></i>
      <input type="text" class="search-input" id="searchBox"
             placeholder="Search by name or phone…"
             oninput="applyFilters()">
    </div>
    <div class="view-toggle">
      <button class="view-btn active" id="viewTable" onclick="switchView('table')">
        <i class="fa fa-table-list"></i>
      </button>
      <button class="view-btn" id="viewCard" onclick="switchView('card')">
        <i class="fa fa-grip"></i>
      </button>
    </div>
  </div>

  <!-- ═══ TABLE VIEW ═══ -->
  <div id="tableView">
    <div class="table-wrap">
      <table>
        <thead>
          <tr>
            <th>Delivery Boy</th>
            <th>Shift Status</th>
            <th>Shift Timer</th>
            <th>Active Orders</th>
            <th>Delivered (All Time)</th>
            <th>Last Seen</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody id="tableBody">
        <% if(boys.isEmpty()){ %>
          <tr>
            <td colspan="7">
              <div class="empty-state">
                <span class="empty-icon"><i class="fa fa-motorcycle"></i></span>
                <div class="empty-title">No delivery boys found</div>
                <div>Add partners from the Manage Delivery Boys page.</div>
              </div>
            </td>
          </tr>
        <% } else { for(DeliveryBoy b : boys){
          String ss = b.getShiftStatus();
          boolean isWorking = "ONLINE".equals(ss) && b.getActiveOrders() > 0;
          String badgeCls, badgeDot, badgeTxt;
          if(isWorking){
              badgeCls="shift-badge shift-working"; badgeDot="dot dot-blue"; badgeTxt="On Delivery";
          } else if("ONLINE".equals(ss)){
              badgeCls="shift-badge shift-online"; badgeDot="dot dot-green"; badgeTxt="Online";
          } else if("ON_BREAK".equals(ss)){
              badgeCls="shift-badge shift-break"; badgeDot="dot dot-amber"; badgeTxt="On Break";
          } else {
              badgeCls="shift-badge shift-offline"; badgeDot="dot dot-muted"; badgeTxt="Offline";
          }
          String initials = b.getName().length()>=2
              ? b.getName().substring(0,2).toUpperCase()
              : b.getName().toUpperCase();
          String shiftStart = b.getShiftStartedAt() != null ? b.getShiftStartedAt() : null;
          Long shiftEpochMs = shiftEpochMap.get(b.getId());
        %>
          <tr class="boy-row"
              data-ss="<%=ss%>"
              data-working="<%=isWorking%>"
              data-text="<%=b.getName().toLowerCase()%> <%=b.getPhone()%>">
            <td>
              <div class="name-cell">
                <div class="tbl-avatar"><%=initials%></div>
                <div>
                  <div style="font-weight:600;"><%=b.getName()%></div>
                  <div style="font-size:11px;color:var(--muted);"><%=b.getPhone()%></div>
                </div>
              </div>
            </td>
            <td><span class="<%=badgeCls%>"><span class="<%=badgeDot%>"></span><%=badgeTxt%></span></td>
            <td>
              <% if(!"OFFLINE".equals(ss)){ %>
                <span class="shift-timer" data-shift-start="<%=shiftEpochMs != null ? shiftEpochMs : ""%>" data-shift-status="<%=ss%>">—</span>
              <% } else { %>
                <span style="color:var(--muted);font-size:12px;">—</span>
              <% } %>
            </td>
            <td>
              <% if(b.getActiveOrders()>0){ %>
                <span class="orders-chip"><i class="fa fa-box"></i> <%=b.getActiveOrders()%></span>
              <% } else { %>
                <span style="color:var(--muted);font-size:12px;">None</span>
              <% } %>
            </td>
            <td>
              <span style="font-weight:600;"><%=b.getDeliveredTotal()%></span>
              <span style="color:var(--muted);font-size:11px;"> deliveries</span>
            </td>
            <td style="font-size:12px;color:var(--muted);">
              <%=b.getLastSeen()!=null?b.getLastSeen():"—"%>
            </td>
            <td>
              <div style="display:flex;gap:6px;">
                <button class="btn-sm btn-view"
                  onclick="openModal(
                    '<%=b.getName()%>',
                    '<%=b.getPhone()%>',
                    '<%=badgeTxt%>',
                    '<%=b.getActiveOrders()%>',
                    '<%=b.getDeliveredTotal()%>',
                    '<%=b.getLastSeen()!=null?b.getLastSeen():"—"%>',
                    '<%=shiftEpochMs!=null?shiftEpochMs:"—"%>',
                    '<%=ss%>'
                  )">
                  <i class="fa fa-eye"></i> View
                </button>
                <a href="tel:<%=b.getPhone()%>" class="btn-sm btn-call">
                  <i class="fa fa-phone"></i>
                </a>
              </div>
            </td>
          </tr>
        <% } } %>
        </tbody>
      </table>
    </div>
  </div><!-- /tableView -->

  <!-- ═══ CARD VIEW ═══ -->
  <div id="cardView" style="display:none;">
    <div class="cards-grid" id="cardsGrid">
    <% if(boys.isEmpty()){ %>
      <div class="empty-state" style="grid-column:1/-1;">
        <span class="empty-icon"><i class="fa fa-motorcycle"></i></span>
        <div class="empty-title">No delivery boys found</div>
      </div>
    <% } else { for(DeliveryBoy b : boys){
      String ss = b.getShiftStatus();
      boolean isWorking = "ONLINE".equals(ss) && b.getActiveOrders() > 0;
      String badgeCls, badgeDot, badgeTxt, ringCls;
      if(isWorking){
          badgeCls="shift-badge shift-working"; badgeDot="dot dot-blue"; badgeTxt="On Delivery"; ringCls="ring-online";
      } else if("ONLINE".equals(ss)){
          badgeCls="shift-badge shift-online"; badgeDot="dot dot-green"; badgeTxt="Online"; ringCls="ring-online";
      } else if("ON_BREAK".equals(ss)){
          badgeCls="shift-badge shift-break"; badgeDot="dot dot-amber"; badgeTxt="On Break"; ringCls="ring-break";
      } else {
          badgeCls="shift-badge shift-offline"; badgeDot="dot dot-muted"; badgeTxt="Offline"; ringCls="ring-offline";
      }
      String initials = b.getName().length()>=2
          ? b.getName().substring(0,2).toUpperCase()
          : b.getName().toUpperCase();
      String shiftStart = b.getShiftStartedAt() != null ? b.getShiftStartedAt() : null;
      Long shiftEpochMs = shiftEpochMap.get(b.getId());
    %>
      <div class="boy-card"
           data-ss="<%=ss%>"
           data-working="<%=isWorking%>"
           data-text="<%=b.getName().toLowerCase()%> <%=b.getPhone()%>">
        <div class="card-top">
          <div class="avatar">
            <%=initials%>
            <div class="presence-ring <%=ringCls%>"></div>
          </div>
          <div class="boy-info">
            <div class="boy-name"><%=b.getName()%></div>
            <div class="boy-phone"><%=b.getPhone()%></div>
          </div>
          <span class="<%=badgeCls%>"><span class="<%=badgeDot%>"></span><%=badgeTxt%></span>
        </div>
        <div class="card-body">
          <div class="card-row">
            <span class="card-row-label"><i class="fa fa-stopwatch"></i> Shift Timer</span>
            <% if(!"OFFLINE".equals(ss)){ %>
              <span class="shift-timer card-row-val"
                    data-shift-start="<%=shiftEpochMs != null ? shiftEpochMs : ""%>"
                    data-shift-status="<%=ss%>">—</span>
            <% } else { %>
              <span class="card-row-val" style="color:var(--muted);">—</span>
            <% } %>
          </div>
          <div class="card-row">
            <span class="card-row-label"><i class="fa fa-box"></i> Active Orders</span>
            <span class="card-row-val">
              <% if(b.getActiveOrders()>0){ %>
                <span class="orders-chip"><%=b.getActiveOrders()%></span>
              <% } else { %>
                <span style="color:var(--muted);">None</span>
              <% } %>
            </span>
          </div>
          <div class="card-row">
            <span class="card-row-label"><i class="fa fa-circle-check"></i> Total Delivered</span>
            <span class="card-row-val"><%=b.getDeliveredTotal()%></span>
          </div>
          <div class="card-row">
            <span class="card-row-label"><i class="fa fa-clock"></i> Last Seen</span>
            <span class="card-row-val" style="font-size:12px;color:var(--muted);">
              <%=b.getLastSeen()!=null?b.getLastSeen():"—"%>
            </span>
          </div>
        </div>
        <div class="card-footer">
          <button class="btn-sm btn-view" style="flex:1;justify-content:center;"
            onclick="openModal(
              '<%=b.getName()%>',
              '<%=b.getPhone()%>',
              '<%=badgeTxt%>',
              '<%=b.getActiveOrders()%>',
              '<%=b.getDeliveredTotal()%>',
              '<%=b.getLastSeen()!=null?b.getLastSeen():"—"%>',
              '<%=shiftEpochMs!=null?shiftEpochMs:"—"%>',
              '<%=ss%>'
            )">
            <i class="fa fa-eye"></i> Details
          </button>
          <a href="tel:<%=b.getPhone()%>" class="btn-sm btn-call" style="flex:1;justify-content:center;">
            <i class="fa fa-phone"></i> Call
          </a>
        </div>
      </div>
    <% } } %>
    </div>
  </div><!-- /cardView -->

</div><!-- /page -->

<!-- ═══ DETAIL MODAL ═══ -->
<div class="modal-overlay" id="detailModal">
  <div class="modal-box">
    <div class="modal-header">
      <div class="modal-title" id="modalTitle">Partner Details</div>
      <button class="modal-close" onclick="closeModal()"><i class="fa fa-xmark"></i></button>
    </div>
    <div class="modal-body">
      <div style="display:flex;align-items:center;gap:12px;margin-bottom:16px;">
        <div class="tbl-avatar" style="width:48px;height:48px;font-size:16px;" id="modalAvatar">—</div>
        <div>
          <div style="font-family:var(--ff-head);font-size:16px;font-weight:700;" id="modalName"></div>
          <div style="font-size:12px;color:var(--muted);" id="modalPhone"></div>
        </div>
        <span id="modalBadge" class="shift-badge" style="margin-left:auto;"></span>
      </div>

      <div class="stat-row-modal">
        <div class="stat-chip">
          <div class="stat-chip-num" id="modalActive" style="color:var(--brand);">0</div>
          <div class="stat-chip-lbl">Active Orders</div>
        </div>
        <div class="stat-chip">
          <div class="stat-chip-num" id="modalDelivered" style="color:var(--green);">0</div>
          <div class="stat-chip-lbl">All-Time Delivered</div>
        </div>
      </div>

      <div style="background:var(--bg);border:1px solid var(--border);border-radius:var(--radius-sm);padding:12px;">
        <div class="info-row">
          <span class="info-label"><i class="fa fa-stopwatch"></i> Shift Status</span>
          <span class="info-val" id="modalShiftState"></span>
        </div>
        <div class="info-row">
          <span class="info-label"><i class="fa fa-play"></i> Shift Started</span>
          <span class="info-val" id="modalShiftStart"></span>
        </div>
        <div class="info-row">
          <span class="info-label"><i class="fa fa-hourglass-half"></i> Time on Shift</span>
          <span class="info-val shift-timer" id="modalTimer" data-shift-start="" data-shift-status=""></span>
        </div>
        <div class="info-row">
          <span class="info-label"><i class="fa fa-clock"></i> Last Seen</span>
          <span class="info-val" id="modalLastSeen"></span>
        </div>
      </div>
    </div>
  </div>
</div>

<script>
// ── Dark mode ──
function toggleDark(){
  const h=document.documentElement,d=h.getAttribute('data-theme')==='dark';
  h.setAttribute('data-theme',d?'light':'dark');
  localStorage.setItem('sibs-monitor-theme',d?'light':'dark');
}
(function(){
  const t=localStorage.getItem('sibs-monitor-theme');
  if(t) document.documentElement.setAttribute('data-theme',t);
})();

// ── View toggle ──
function switchView(v){
  document.getElementById('tableView').style.display = v==='table'?'':'none';
  document.getElementById('cardView').style.display  = v==='card' ?'':'none';
  document.getElementById('viewTable').classList.toggle('active', v==='table');
  document.getElementById('viewCard').classList.toggle('active',  v==='card');
}

// ── Tile filter ──
let currentTileFilter = 'ALL';
function filterTile(f){
  currentTileFilter = f;
  document.querySelectorAll('.tile').forEach(t=>{
    t.classList.remove('active-filter');
  });
  document.getElementById('tile-'+f).classList.add('active-filter');
  applyFilters();
}

// ── Search + tile filter combined ──
function applyFilters(){
  const q = document.getElementById('searchBox').value.toLowerCase();
  const f = currentTileFilter;

  // table rows
  document.querySelectorAll('.boy-row').forEach(row=>{
    const matchSearch = !q || (row.dataset.text||'').includes(q);
    const matchTile   = matchTile_check(row, f);
    row.classList.toggle('hidden-row', !(matchSearch && matchTile));
  });

  // cards
  document.querySelectorAll('.boy-card').forEach(card=>{
    const matchSearch = !q || (card.dataset.text||'').includes(q);
    const matchTile   = matchTile_check(card, f);
    card.classList.toggle('hidden-row', !(matchSearch && matchTile));
  });
}

function matchTile_check(el, f){
  if(f==='ALL') return true;
  if(f==='WORKING') return el.dataset.working==='true';
  return el.dataset.ss === f;
}

// ── Shift Timer ──
// Each element with class "shift-timer" that has data-shift-start="HH:mm"
// shows how long that person has been on shift since today at HH:mm.
function tickShiftTimers(){
  document.querySelectorAll('.shift-timer').forEach(el=>{
    const start = el.dataset.shiftStart;
    const st    = el.dataset.shiftStatus;
    if(!start || start==='—' || st==='OFFLINE'){ el.textContent='—'; return; }

    // use epoch milliseconds directly — no timezone issues at all
    const epochMs = parseInt(start, 10);
    if(isNaN(epochMs) || epochMs === 0){ el.textContent='—'; return; }
    const now = new Date();
    let diff = Math.max(0, Math.floor((now.getTime() - epochMs) / 1000));

    const h = Math.floor(diff/3600).toString().padStart(2,'0');
    const m = Math.floor((diff%3600)/60).toString().padStart(2,'0');
    const s = (diff%60).toString().padStart(2,'0');
    el.textContent = h+':'+m+':'+s;

    // Dim the timer if on break
    if(st==='ON_BREAK'){
      el.style.color='var(--amber)';
    }
  });
}
setInterval(tickShiftTimers, 1000);
tickShiftTimers();

// ── Auto-refresh (every 30 seconds) ──
let autoRefreshTimer;
function scheduleAutoRefresh(){
  autoRefreshTimer = setTimeout(function(){
    window.location.reload();
  }, 30000);
}
scheduleAutoRefresh();

function manualRefresh(){
  clearTimeout(autoRefreshTimer);
  const icon = document.getElementById('refreshIcon');
  icon.classList.add('refresh-spin');
  setTimeout(()=>{ window.location.reload(); }, 300);
}

// Update "last updated" clock
(function(){
  function pad(n){ return String(n).padStart(2,'0'); }
  function updateClock(){
    const d = new Date();
    document.getElementById('lastUpdatedTime').textContent =
      pad(d.getHours())+':'+pad(d.getMinutes())+':'+pad(d.getSeconds());
  }
  updateClock();
  setInterval(updateClock, 1000);
})();

// ── Detail Modal ──
function openModal(name, phone, statusTxt, active, delivered, lastSeen, shiftStart, shiftState){
  document.getElementById('modalName').textContent   = name;
  document.getElementById('modalPhone').textContent  = phone;
  document.getElementById('modalActive').textContent = active;
  document.getElementById('modalDelivered').textContent = delivered;
  document.getElementById('modalLastSeen').textContent  = lastSeen;
  document.getElementById('modalShiftStart').textContent = shiftStart !== '—' ? shiftStart : '—';
  document.getElementById('modalShiftState').textContent = statusTxt;

  // Avatar initials
  const initials = name.length>=2 ? name.substring(0,2).toUpperCase() : name.toUpperCase();
  document.getElementById('modalAvatar').textContent = initials;
  document.getElementById('modalTitle').textContent  = name + ' · Activity';

  // Badge
  const badge = document.getElementById('modalBadge');
  badge.className = 'shift-badge';
  badge.textContent = statusTxt;
  if(statusTxt==='On Delivery')      badge.classList.add('shift-working');
  else if(statusTxt==='Online')      badge.classList.add('shift-online');
  else if(statusTxt==='On Break')    badge.classList.add('shift-break');
  else                               badge.classList.add('shift-offline');

  // Wire up modal timer
  const mt = document.getElementById('modalTimer');
  mt.dataset.shiftStart  = shiftStart;
  mt.dataset.shiftStatus = shiftState;
  tickShiftTimers();

  document.getElementById('detailModal').classList.add('open');
}

function closeModal(){
  document.getElementById('detailModal').classList.remove('open');
}
document.getElementById('detailModal').addEventListener('click', function(e){
  if(e.target===this) closeModal();
});

// default tile highlight
document.getElementById('tile-ALL').classList.add('active-filter');
</script>
</body>
</html>
