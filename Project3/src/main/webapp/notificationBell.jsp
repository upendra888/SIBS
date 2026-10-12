<%--
  notificationBell.jsp  ─  Drop-in bell widget for any dashboard.
  
  USAGE — include at the top of the page's <head> CSS block and again
  where you want the bell button rendered in the topbar:

      <%@ include file="/includes/notificationBell.jsp" %>

  The fragment auto-detects the logged-in role from session:
    • "customer"       → User   (customer notifications)
    • "user"           → User   (staff/admin notifications)
    • "deliveryBoyId"  → Integer (delivery boy notifications)

  If none of those is set the bell is hidden (not an error).

  DEPENDENCIES
    • Font Awesome 6 already loaded by the host page.
    • GetNotificationsServlet mapped to /getNotifications.
    • NotificationDAO on the classpath.
--%>
<%@ page import="com.sibs.model.User, com.sibs.model.DeliveryBoy, com.sibs.dao.NotificationDAO" %>
<%
// ── Detect recipient & initial unread count ───────────────────────────
int _bellUnread = 0;
String _bellRole = "none";

User _cust = (User) session.getAttribute("customer");
if (_cust != null) {
    _bellRole = "customer";
    try { _bellUnread = new NotificationDAO().countUnreadForCustomer(_cust.getId()); } catch (Exception _e) {}
}

if ("none".equals(_bellRole)) {
    User _staff = (User) session.getAttribute("user");
    if (_staff != null) {
        _bellRole = "staff";
        try { _bellUnread = new NotificationDAO().countUnreadForStaff(_staff.getId()); } catch (Exception _e) {}
    }
}

if ("none".equals(_bellRole)) {
    Object _dbId = session.getAttribute("deliveryBoy");
    if (_dbId instanceof DeliveryBoy) {
        _bellRole = "delivery";
        try { _bellUnread = new NotificationDAO().countUnreadForDeliveryBoy(((DeliveryBoy)_dbId).getId()); } catch (Exception _e) {}
    }
}

boolean _showBell = !"none".equals(_bellRole);
int _bellUnreadFinal = _bellUnread;
%>

<% if (_showBell) { %>
<style>
/* ── Bell button (host page should already have a topbar context) ── */
.nb-bell-btn{position:relative;background:none;border:1px solid rgba(255,255,255,.2);width:38px;height:38px;border-radius:8px;cursor:pointer;color:inherit;font-size:16px;display:flex;align-items:center;justify-content:center;transition:.15s;}
.nb-bell-btn:hover{background:rgba(255,255,255,.08);}
.nb-bell-count{position:absolute;top:-5px;right:-5px;background:#ef4444;color:#fff;font-size:10px;font-weight:700;min-width:16px;height:16px;border-radius:999px;display:flex;align-items:center;justify-content:center;padding:0 3px;border:2px solid var(--surface,#1e293b);}

/* ── Panel ── */
.nb-panel{position:fixed;top:66px;right:16px;width:340px;max-height:460px;background:var(--surface,#fff);border:1px solid var(--border,#e2e8f0);border-radius:12px;box-shadow:0 8px 30px rgba(0,0,0,.18);z-index:1000;display:none;flex-direction:column;color:var(--text,#0f172a);}
.nb-panel.nb-open{display:flex;}
.nb-header{display:flex;align-items:center;justify-content:space-between;padding:14px 16px 10px;border-bottom:1px solid var(--border,#e2e8f0);}
.nb-header h4{font-size:14px;font-weight:600;margin:0;}
.nb-header-actions{display:flex;gap:8px;}
.nb-mark-all{background:none;border:none;color:#2563eb;font-size:12px;cursor:pointer;font-weight:500;}
.nb-mark-all:hover{text-decoration:underline;}
.nb-clear-all{background:none;border:none;color:#ef4444;font-size:12px;cursor:pointer;font-weight:500;}
.nb-clear-all:hover{text-decoration:underline;}
.nb-del-btn{background:none;border:none;color:#9ca3af;font-size:11px;cursor:pointer;padding:2px 4px;border-radius:4px;flex-shrink:0;opacity:0;transition:.15s;}
.nb-item:hover .nb-del-btn{opacity:1;}
.nb-del-btn:hover{color:#ef4444;background:#fee2e2;}
.nb-list{overflow-y:auto;flex:1;}
.nb-item{display:flex;gap:10px;padding:12px 16px;border-bottom:1px solid var(--border,#e2e8f0);cursor:pointer;transition:.15s;}
.nb-item:hover{background:var(--bg,#f8fafc);}
.nb-item.nb-unread{background:#eff6ff;}
.nb-icon{width:34px;height:34px;border-radius:50%;display:flex;align-items:center;justify-content:center;flex-shrink:0;font-size:14px;}
.nb-icon.ORDER    {background:#dbeafe;color:#1d4ed8;}
.nb-icon.RETURN   {background:#fef3c7;color:#b45309;}
.nb-icon.COMPLAINT{background:#fee2e2;color:#b91c1c;}
.nb-icon.DELIVERY {background:#dcfce7;color:#166534;}
.nb-icon.LEAVE    {background:#faf5ff;color:#7c3aed;}
.nb-icon.SYSTEM   {background:#f1f5f9;color:#475569;}
.nb-icon.ATTENDANCE{background:#fff7ed;color:#c2410c;}
.nb-icon.COD      {background:#ecfdf5;color:#065f46;}
.nb-icon.PAYMENT  {background:#f0fdf4;color:#15803d;}
.nb-body{flex:1;min-width:0;}
.nb-title{font-size:13px;font-weight:600;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;}
.nb-msg{font-size:12px;color:var(--muted,#64748b);margin-top:2px;overflow:hidden;display:-webkit-box;-webkit-line-clamp:2;-webkit-box-orient:vertical;}
.nb-time{font-size:11px;color:var(--muted,#64748b);margin-top:4px;}
.nb-filters{display:flex;gap:4px;padding:8px 12px;border-bottom:1px solid var(--border,#e2e8f0);overflow-x:auto;scrollbar-width:none;}
.nb-filters::-webkit-scrollbar{display:none;}
.nb-filter{background:none;border:1px solid var(--border,#e2e8f0);border-radius:20px;padding:3px 10px;font-size:11px;font-weight:600;cursor:pointer;white-space:nowrap;color:var(--muted,#64748b);transition:.15s;}
.nb-filter:hover{background:var(--bg,#f1f5f9);}
.nb-filter.nb-active{background:#2563eb;color:#fff;border-color:#2563eb;}
.nb-priority{font-size:9px;font-weight:700;padding:1px 5px;border-radius:4px;margin-left:5px;vertical-align:middle;}
.nb-priority.high{background:#fee2e2;color:#b91c1c;}
.nb-priority.med{background:#fef3c7;color:#b45309;}
.nb-dot{width:7px;height:7px;border-radius:50%;background:#2563eb;flex-shrink:0;margin-top:5px;}
.nb-empty{padding:32px;text-align:center;color:var(--muted,#64748b);font-size:13px;}
</style>

<!-- Bell button — place this inside your topbar actions row -->
<button class="nb-bell-btn" id="nbBellBtn" onclick="nbToggle()" title="Notifications">
  <i class="fa fa-bell"></i>
  <span class="nb-bell-count" id="nbCount" style="<%=_bellUnreadFinal==0?"display:none":""%>">
    <%=_bellUnreadFinal > 9 ? "9+" : (_bellUnreadFinal > 0 ? String.valueOf(_bellUnreadFinal) : "")%>
  </span>
</button>

<!-- Notification panel (rendered at body level via JS append) -->
<div class="nb-panel" id="nbPanel">
  <div class="nb-header">
    <h4>Notifications</h4>
    <div class="nb-header-actions">
      <button class="nb-mark-all" onclick="nbMarkAll()">Mark all read</button>
      <button class="nb-clear-all" onclick="nbClearAll()">Clear all</button>
    </div>
  </div>
  <div class="nb-filters" id="nbFilters">
    <button class="nb-filter nb-active" data-cat="ALL" onclick="nbSetFilter('ALL',this)">All</button>
    <button class="nb-filter" data-cat="ORDER"      onclick="nbSetFilter('ORDER',this)">Orders</button>
    <button class="nb-filter" data-cat="DELIVERY"   onclick="nbSetFilter('DELIVERY',this)">Delivery</button>
    <button class="nb-filter" data-cat="RETURN"     onclick="nbSetFilter('RETURN',this)">Returns</button>
    <button class="nb-filter" data-cat="COMPLAINT"  onclick="nbSetFilter('COMPLAINT',this)">Support</button>
    <button class="nb-filter" data-cat="ATTENDANCE" onclick="nbSetFilter('ATTENDANCE',this)">Attendance</button>
    <button class="nb-filter" data-cat="LEAVE"      onclick="nbSetFilter('LEAVE',this)">Leave</button>
    <button class="nb-filter" data-cat="COD"        onclick="nbSetFilter('COD',this)">COD</button>
    <button class="nb-filter" data-cat="PAYMENT"    onclick="nbSetFilter('PAYMENT',this)">Payment</button>
  </div>
  <div style="padding:6px 12px;border-bottom:1px solid var(--border,#e2e8f0);">
    <input id="nbSearch" type="text" placeholder="Search notifications…"
      style="width:100%;box-sizing:border-box;padding:5px 10px;border:1px solid var(--border,#e2e8f0);border-radius:6px;font-size:12px;outline:none;background:var(--bg,#f8fafc);color:var(--text,#0f172a);"
      oninput="nbDoSearch(this.value)">
  </div>
  <div class="nb-list" id="nbList">
    <div class="nb-empty">Loading…</div>
  </div>
</div>

<script>
(function() {
  const CTX = '<%=request.getContextPath()%>';
  let _open = false;
  let _allItems = [];
  let _activeFilter = 'ALL';
  const ICONS = {
    ORDER:'fa-box', RETURN:'fa-rotate-left', COMPLAINT:'fa-headset',
    DELIVERY:'fa-motorcycle', LEAVE:'fa-calendar-xmark', SYSTEM:'fa-bell',
    ATTENDANCE:'fa-user-clock', COD:'fa-money-bill-wave', PAYMENT:'fa-credit-card'
  };

  window.nbSetFilter = function(cat, btn) {
    _activeFilter = cat;
    document.querySelectorAll('.nb-filter').forEach(b => b.classList.remove('nb-active'));
    btn.classList.add('nb-active');
    const s = document.getElementById('nbSearch'); if (s) s.value = '';
    nbRender(_allItems);
  };

  window.nbDoSearch = function(q) {
    q = q.trim().toLowerCase();
    if (!q) { nbRender(_allItems); return; }
    const filtered = _allItems.filter(n =>
      (n.title && n.title.toLowerCase().includes(q)) ||
      (n.message && n.message.toLowerCase().includes(q))
    );
    nbRender(filtered);
  };

  function nbRender(items) {
    const filtered = _activeFilter === 'ALL' ? items : items.filter(n => n.category === _activeFilter);
    const list = document.getElementById('nbList');
    if (!filtered.length) {
      list.innerHTML = '<div class="nb-empty"><i class="fa fa-bell-slash" style="font-size:22px;margin-bottom:8px;display:block"></i>' +
        (_activeFilter === 'ALL' ? 'All caught up!' : 'No ' + _activeFilter.toLowerCase() + ' notifications.') + '</div>';
      return;
    }
    list.innerHTML = filtered.map(n => `
      <div class="nb-item ${n.isRead?'':'nb-unread'}" id="nbItem${n.id}" onclick="nbOpen(${n.id},'${encodeURIComponent(n.linkUrl||'')}')">
        <div class="nb-icon ${n.category}"><i class="fa ${ICONS[n.category]||'fa-bell'}"></i></div>
        <div class="nb-body">
          <div class="nb-title">${n.title} ${n.priority==='HIGH'?'<span class="nb-priority high">HIGH</span>':n.priority==='MEDIUM'?'<span class="nb-priority med">MED</span>':''}</div>
          <div class="nb-msg">${n.message}</div>
          <div class="nb-time">${n.relativeTime}</div>
        </div>
        ${n.isRead?'':'<div class="nb-dot"></div>'}
        <button class="nb-del-btn" onclick="event.stopPropagation();nbDelete(${n.id})" title="Delete"><i class="fa fa-times"></i></button>
      </div>`).join('');
  }

  window.nbToggle = function() {
    _open = !_open;
    const panel = document.getElementById('nbPanel');
    if (_open) { panel.classList.add('nb-open'); nbLoad(); }
    else {
      panel.classList.remove('nb-open');
      _activeFilter = 'ALL';
      const s = document.getElementById('nbSearch'); if (s) s.value = '';
      document.querySelectorAll('.nb-filter').forEach(b => b.classList.toggle('nb-active', b.dataset.cat === 'ALL'));
    }
  };

  document.addEventListener('click', function(e) {
    const panel = document.getElementById('nbPanel');
    const btn   = document.getElementById('nbBellBtn');
    if (_open && !panel.contains(e.target) && !btn.contains(e.target)) {
      panel.classList.remove('nb-open'); _open = false;
    }
  });

  function nbLoad() {
    fetch(CTX + '/getNotifications')
      .then(r => r.json())
      .then(data => {
        nbSetCount(data.unread);
        _allItems = data.items || [];
        nbRender(_allItems);
      })
      .catch(() => {
        document.getElementById('nbList').innerHTML =
          '<div class="nb-empty">Could not load notifications</div>';
      });
  }

  window.nbOpen = function(id, encodedUrl) {
    fetch(CTX + '/getNotifications?action=markRead&id=' + id, {method:'POST'});
    const url = decodeURIComponent(encodedUrl);
    if (url) window.location.href = CTX + url;
  };

  window.nbDelete = function(id) {
    fetch(CTX + '/getNotifications?action=delete&id=' + id, {method:'POST'})
      .then(r => r.json())
      .then(d => {
        _allItems = _allItems.filter(n => n.id !== id);
        nbSetCount(d.unread);
        nbRender(_allItems);
      });
  };

  window.nbClearAll = function() {
    if (!confirm('Delete all notifications?')) return;
    fetch(CTX + '/getNotifications?action=deleteAll', {method:'POST'})
      .then(r => r.json())
      .then(() => { nbSetCount(0); nbLoad(); });
  };

  window.nbMarkAll = function() {
    fetch(CTX + '/getNotifications?action=markAllRead', {method:'POST'})
      .then(r => r.json())
      .then(() => { nbSetCount(0); nbLoad(); });
  };

  function nbSetCount(n) {
    const el = document.getElementById('nbCount');
    if (n > 0) { el.textContent = n > 9 ? '9+' : n; el.style.display = 'flex'; }
    else        { el.style.display = 'none'; }
  }

  // Refresh badge every 60 s without full page reload
  setInterval(() => {
    fetch(CTX + '/getNotifications')
      .then(r => r.json())
      .then(d => nbSetCount(d.unread))
      .catch(() => {});
  }, 60000);
})();
</script>
<% } // end if _showBell %>
