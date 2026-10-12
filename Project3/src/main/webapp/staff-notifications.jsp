<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="com.sibs.model.User" %>
<%
User user = (User) session.getAttribute("user");
if (user == null || (!"STAFF".equals(user.getRole()) && !"ADMIN".equals(user.getRole()))) {
    response.sendRedirect("login.jsp");
    return;
}
String displayName  = (user.getName() != null && !user.getName().isEmpty()) ? user.getName() : user.getUsername();
String avatarLetter = displayName.substring(0, 1).toUpperCase();
%>
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>My Notifications — SIBS</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<style>
:root{--bg:#f8fafc;--surface:#fff;--border:#e2e8f0;--text:#0f172a;--muted:#64748b;--primary:#2563eb;}
[data-theme="dark"]{--bg:#0f172a;--surface:#1e293b;--border:#334155;--text:#f1f5f9;--muted:#94a3b8;}
*{margin:0;padding:0;box-sizing:border-box;font-family:'Inter',sans-serif;}
body{background:var(--bg);color:var(--text);min-height:100vh;}

/* Topbar */
.topbar{height:62px;background:var(--surface);border-bottom:1px solid var(--border);
  display:flex;align-items:center;justify-content:space-between;padding:0 24px;
  position:sticky;top:0;z-index:100;box-shadow:0 1px 3px rgba(0,0,0,.06);}
.topbar-left{display:flex;align-items:center;gap:12px;}
.back-btn{display:flex;align-items:center;gap:7px;padding:7px 14px;border-radius:8px;
  border:1.5px solid var(--border);background:var(--surface);font-size:13px;font-weight:600;
  color:var(--muted);text-decoration:none;transition:.15s;}
.back-btn:hover{color:#2563eb;border-color:#2563eb;}
.topbar-title{font-size:15px;font-weight:700;display:flex;align-items:center;gap:8px;}
.topbar-right{display:flex;align-items:center;gap:10px;}
.dark-btn{background:none;border:1px solid var(--border);width:34px;height:34px;border-radius:8px;cursor:pointer;color:var(--muted);}
.avatar{width:32px;height:32px;border-radius:50%;background:#2563eb;display:flex;align-items:center;justify-content:center;color:#fff;font-weight:700;font-size:13px;}

/* Content */
.content{max-width:760px;margin:32px auto;padding:0 20px;}
.page-header{display:flex;align-items:center;justify-content:space-between;margin-bottom:20px;}
.page-title{font-size:20px;font-weight:700;}
.page-sub{font-size:13px;color:var(--muted);margin-top:3px;}
.mark-all-btn{padding:8px 16px;background:var(--primary);color:#fff;border:none;
  border-radius:8px;font-size:13px;font-weight:600;cursor:pointer;display:flex;align-items:center;gap:6px;}
.mark-all-btn:hover{background:#1d4ed8;}
.mark-all-btn:disabled{opacity:.5;cursor:not-allowed;}

/* Tabs */
.tabs{display:flex;gap:4px;border-bottom:2px solid var(--border);margin-bottom:20px;overflow-x:auto;scrollbar-width:none;}
.tabs::-webkit-scrollbar{display:none;}
.tab{padding:10px 16px;font-size:13px;font-weight:600;color:var(--muted);cursor:pointer;
  white-space:nowrap;border-bottom:2px solid transparent;margin-bottom:-2px;transition:.15s;}
.tab.active{color:var(--primary);border-bottom-color:var(--primary);}
.tab-count{display:inline-flex;align-items:center;justify-content:center;
  background:#ef4444;color:#fff;font-size:10px;font-weight:700;min-width:16px;height:16px;
  border-radius:99px;padding:0 4px;margin-left:5px;display:none;}
.tab-count.show{display:inline-flex;}

/* Notification list */
.notif-list{display:flex;flex-direction:column;gap:8px;}
.notif-item{display:flex;align-items:flex-start;gap:14px;padding:16px;
  background:var(--surface);border:1px solid var(--border);border-radius:12px;
  cursor:pointer;transition:box-shadow .15s,border-color .15s;}
.notif-item:hover{box-shadow:0 4px 16px rgba(0,0,0,.08);border-color:#93c5fd;}
.notif-item.unread{border-left:4px solid var(--primary);background:#eff6ff;}
[data-theme="dark"] .notif-item.unread{background:#1e3a5f;}
.notif-ico{width:42px;height:42px;border-radius:50%;display:flex;align-items:center;
  justify-content:center;flex-shrink:0;font-size:16px;}
.notif-body{flex:1;min-width:0;}
.notif-title{font-size:14px;font-weight:600;color:var(--text);}
.notif-msg{font-size:13px;color:var(--muted);margin-top:4px;line-height:1.5;}
.notif-time{font-size:11px;color:var(--muted);margin-top:6px;}
.notif-dot{width:8px;height:8px;border-radius:50%;background:var(--primary);flex-shrink:0;margin-top:6px;}
.priority-badge{display:inline-flex;align-items:center;gap:4px;font-size:10px;font-weight:700;
  padding:2px 8px;border-radius:99px;margin-left:8px;}
.priority-badge.HIGH{background:#fee2e2;color:#b91c1c;}
.priority-badge.MEDIUM{background:#fef3c7;color:#b45309;}
.priority-badge.LOW{background:#dcfce7;color:#166534;}

/* Empty */
.empty{text-align:center;padding:60px 20px;color:var(--muted);}
.empty i{font-size:40px;display:block;margin-bottom:14px;opacity:.3;}
.empty p{font-size:14px;}

/* Loading */
.loading{text-align:center;padding:40px;color:var(--muted);}
</style>
</head>
<body>

<!-- Topbar -->
<div class="topbar">
  <div class="topbar-left">
    <a href="staff-dashboard.jsp" class="back-btn"><i class="fa fa-arrow-left"></i> Dashboard</a>
    <div class="topbar-title"><i class="fa fa-bell" style="color:#2563eb;"></i> My Notifications</div>
  </div>
  <div class="topbar-right">
    <button class="dark-btn" onclick="toggleTheme()"><i class="fa fa-moon"></i></button>
    <div class="avatar"><%=avatarLetter%></div>
  </div>
</div>

<!-- Content -->
<div class="content">
  <div class="page-header">
    <div>
      <div class="page-title">Notifications</div>
      <div class="page-sub" id="unreadSub">Loading...</div>
    </div>
    <button class="mark-all-btn" id="markAllBtn" onclick="markAllRead()" disabled>
      <i class="fa fa-check-double"></i> Mark all read
    </button>
  </div>

  <!-- Tabs -->
  <div class="tabs">
    <div class="tab active" data-f="all"       onclick="setTab('all',this)">All <span class="tab-count" id="tc-all"></span></div>
    <div class="tab" data-f="ORDER"            onclick="setTab('ORDER',this)">Orders <span class="tab-count" id="tc-order"></span></div>
    <div class="tab" data-f="RETURN"           onclick="setTab('RETURN',this)">Returns <span class="tab-count" id="tc-return"></span></div>
    <div class="tab" data-f="COMPLAINT"        onclick="setTab('COMPLAINT',this)">Support <span class="tab-count" id="tc-complaint"></span></div>
    <div class="tab" data-f="DELIVERY"         onclick="setTab('DELIVERY',this)">Delivery <span class="tab-count" id="tc-delivery"></span></div>
    <div class="tab" data-f="LEAVE"            onclick="setTab('LEAVE',this)">Leave <span class="tab-count" id="tc-leave"></span></div>
    <div class="tab" data-f="ATTENDANCE"       onclick="setTab('ATTENDANCE',this)">Attendance <span class="tab-count" id="tc-attendance"></span></div>
    <div class="tab" data-f="SYSTEM"           onclick="setTab('SYSTEM',this)">System <span class="tab-count" id="tc-system"></span></div>
  </div>

  <!-- List -->
  <div class="notif-list" id="notifList">
    <div class="loading"><i class="fa fa-spinner fa-spin"></i>&nbsp; Loading notifications...</div>
  </div>
</div>

<script>
var _notifs = [], _filter = 'all';
var CTX = '<%=request.getContextPath()%>';

var IMAP = {
  ORDER:     {ico:'fa-shopping-bag', bg:'#fef3c7', cl:'#d97706'},
  RETURN:    {ico:'fa-rotate-left',  bg:'#e0f2fe', cl:'#0284c7'},
  COMPLAINT: {ico:'fa-headset',      bg:'#fee2e2', cl:'#dc2626'},
  LEAVE:     {ico:'fa-calendar-xmark',bg:'#fce7f3',cl:'#db2777'},
  DELIVERY:  {ico:'fa-motorcycle',   bg:'#dcfce7', cl:'#16a34a'},
  COD:       {ico:'fa-money-bill',   bg:'#fef9c3', cl:'#ca8a04'},
  ATTENDANCE:{ico:'fa-user-clock',   bg:'#fff7ed', cl:'#c2410c'},
  SYSTEM:    {ico:'fa-bell',         bg:'#ede9fe', cl:'#7c3aed'}
};

function esc(s){ return s ? s.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;') : ''; }

function setTab(f, el) {
  _filter = f;
  document.querySelectorAll('.tab').forEach(function(t){ t.classList.remove('active'); });
  el.classList.add('active');
  render();
}

function render() {
  var list = document.getElementById('notifList');
  var items = _filter === 'all' ? _notifs : _notifs.filter(function(n){ return n.category === _filter; });

  if (!items.length) {
    list.innerHTML = '<div class="empty"><i class="fa fa-bell-slash"></i><p>No notifications here</p></div>';
    return;
  }

  list.innerHTML = items.map(function(n) {
    var ic = IMAP[n.category] || IMAP.SYSTEM;
    var pri = n.priority ? '<span class="priority-badge '+esc(n.priority)+'">'+esc(n.priority)+'</span>' : '';
    return '<div class="notif-item'+(n.isRead?'':' unread')+'" onclick="markOne('+n.id+',\''+esc(n.linkUrl||'')+'\')">'+
      '<div class="notif-ico" style="background:'+ic.bg+';color:'+ic.cl+'"><i class="fa '+ic.ico+'"></i></div>'+
      '<div class="notif-body">'+
        '<div class="notif-title">'+esc(n.title)+pri+'</div>'+
        '<div class="notif-msg">'+esc(n.message)+'</div>'+
        '<div class="notif-time"><i class="fa fa-clock" style="margin-right:4px;"></i>'+esc(n.relativeTime)+'</div>'+
      '</div>'+
      (!n.isRead ? '<div class="notif-dot"></div>' : '')+
      '</div>';
  }).join('');
}

function updateCounts() {
  var cats = {all:0, ORDER:0, RETURN:0, COMPLAINT:0, DELIVERY:0, LEAVE:0, ATTENDANCE:0, SYSTEM:0};
  _notifs.forEach(function(n){
    if (!n.isRead) { cats.all++; if (cats[n.category] !== undefined) cats[n.category]++; }
  });
  Object.keys(cats).forEach(function(k) {
    var el = document.getElementById('tc-'+(k === 'all' ? 'all' : k.toLowerCase()));
    if (!el) return;
    if (cats[k] > 0) { el.textContent = cats[k]; el.classList.add('show'); }
    else { el.textContent = ''; el.classList.remove('show'); }
  });
  var sub = document.getElementById('unreadSub');
  var btn = document.getElementById('markAllBtn');
  if (cats.all > 0) {
    sub.textContent = cats.all + ' unread notification' + (cats.all > 1 ? 's' : '');
    btn.disabled = false;
  } else {
    sub.textContent = 'All caught up!';
    btn.disabled = true;
  }
}

function fetchNotifs() {
  fetch(CTX + '/getNotifications').then(function(r){ return r.json(); }).then(function(data) {
    _notifs = data.items || [];
    updateCounts();
    render();
  }).catch(function() {
    document.getElementById('notifList').innerHTML =
      '<div class="empty"><i class="fa fa-triangle-exclamation"></i><p>Could not load notifications.</p></div>';
  });
}

function markOne(id, url) {
  fetch(CTX + '/getNotifications?action=markRead&id=' + id, {method:'POST'}).then(fetchNotifs);
  if (url) setTimeout(function(){ window.location.href = url; }, 200);
}

function markAllRead() {
  fetch(CTX + '/getNotifications?action=markAllRead', {method:'POST'}).then(fetchNotifs);
}

function toggleTheme() {
  var html = document.documentElement;
  var next = html.getAttribute('data-theme') === 'dark' ? 'light' : 'dark';
  html.setAttribute('data-theme', next);
  localStorage.setItem('sibs-theme', next);
}

// Init theme
(function(){
  var t = localStorage.getItem('sibs-theme');
  if (t) document.documentElement.setAttribute('data-theme', t);
})();

fetchNotifs();
setInterval(fetchNotifs, 60000);
</script>
</body>
</html>
