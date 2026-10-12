<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="com.sibs.model.User" %>
<%
User user = (User) session.getAttribute("user");
if (user == null || !"ADMIN".equals(user.getRole())) {
    response.sendRedirect("login.jsp");
    return;
}
String displayName  = (user.getName() != null && !user.getName().isEmpty()) ? user.getName() : user.getUsername();
String avatarLetter = displayName.substring(0, 1).toUpperCase();
String successMsg   = request.getParameter("broadcast");
String errorMsg     = request.getParameter("error");
String sentCount    = request.getParameter("sent");
%>
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Broadcast Notifications — SIBS Admin</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<style>
:root{--bg:#f8fafc;--surface:#fff;--border:#e2e8f0;--text:#0f172a;--muted:#64748b;--primary:#2563eb;--success:#16a34a;--danger:#ef4444;--warn:#f59e0b;--sidebar:#0f172a;--sidebar-text:#cbd5e1;--sidebar-hover:#1e293b;}
[data-theme="dark"]{--bg:#0f172a;--surface:#1e293b;--border:#334155;--text:#f1f5f9;--muted:#94a3b8;--sidebar:#020617;--sidebar-hover:#0f172a;}
*{margin:0;padding:0;box-sizing:border-box;font-family:'Inter',sans-serif;}
body{background:var(--bg);color:var(--text);}
.sidebar{width:240px;height:100vh;background:var(--sidebar);position:fixed;top:0;left:0;display:flex;flex-direction:column;z-index:200;}
.sidebar-logo{padding:20px 24px;border-bottom:1px solid rgba(255,255,255,.07);display:flex;align-items:center;gap:10px;}
.sidebar-logo span{color:#fff;font-weight:700;font-size:17px;}
.sidebar-logo i{color:#2563eb;font-size:19px;}
.sidebar nav{flex:1;padding:12px 0;overflow-y:auto;}
.nav-item{display:flex;align-items:center;gap:10px;padding:11px 20px;color:var(--sidebar-text);text-decoration:none;font-size:14px;transition:.15s;border-left:3px solid transparent;}
.nav-item:hover,.nav-item.active{background:var(--sidebar-hover);color:#fff;border-left-color:#2563eb;}
.nav-item i{width:18px;text-align:center;}
.sidebar-footer{padding:16px;border-top:1px solid rgba(255,255,255,.07);}
.topbar{margin-left:240px;height:62px;background:var(--surface);border-bottom:1px solid var(--border);display:flex;align-items:center;justify-content:space-between;padding:0 24px;position:sticky;top:0;z-index:100;box-shadow:0 1px 3px rgba(0,0,0,.06);}
.topbar-left{font-weight:600;font-size:15px;}
.topbar-right{display:flex;align-items:center;gap:12px;}
.dark-btn{background:none;border:1px solid var(--border);width:34px;height:34px;border-radius:8px;cursor:pointer;color:var(--muted);}
.profile-pill{display:flex;align-items:center;gap:8px;cursor:pointer;padding:6px 10px;border-radius:8px;border:1px solid var(--border);}
.avatar{width:30px;height:30px;border-radius:50%;background:#2563eb;display:flex;align-items:center;justify-content:center;color:#fff;font-weight:700;font-size:12px;}
.profile-name{font-size:13px;font-weight:500;}
.profile-role{font-size:11px;color:var(--muted);}
.content{margin-left:240px;padding:28px 24px;}
.page-title{font-size:20px;font-weight:700;margin-bottom:4px;}
.page-sub{font-size:13px;color:var(--muted);margin-bottom:24px;}
.content-grid{display:grid;grid-template-columns:1fr 1fr;gap:24px;align-items:start;}
.card{background:var(--surface);border:1px solid var(--border);border-radius:14px;padding:28px;box-shadow:0 1px 4px rgba(0,0,0,.06);margin-bottom:24px;}
.card-title{font-size:15px;font-weight:600;margin-bottom:20px;display:flex;align-items:center;gap:8px;}
.form-group{margin-bottom:16px;}
.form-group label{display:block;font-size:12px;font-weight:600;color:var(--muted);text-transform:uppercase;letter-spacing:.4px;margin-bottom:6px;}
.form-group input,.form-group textarea{width:100%;padding:10px 12px;border:1px solid var(--border);border-radius:8px;font-size:14px;font-family:inherit;color:var(--text);background:var(--bg);outline:none;transition:.15s;}
.form-group input:focus,.form-group textarea:focus{border-color:var(--primary);background:var(--surface);}
.form-group textarea{resize:vertical;min-height:100px;}
.target-grid{display:grid;grid-template-columns:1fr 1fr;gap:10px;}
.target-card{border:2px solid var(--border);border-radius:10px;padding:14px;cursor:pointer;transition:.15s;text-align:center;background:var(--bg);}
.target-card:hover{border-color:#93c5fd;background:#eff6ff;}
.target-card input[type=radio]{display:none;}
.target-card.selected{border-color:var(--primary);background:#eff6ff;}
.target-card i{font-size:22px;color:var(--primary);display:block;margin-bottom:6px;}
.target-card span{font-size:13px;font-weight:600;color:var(--text);}
.target-card small{font-size:11px;color:var(--muted);display:block;margin-top:2px;}
.priority-row{display:flex;gap:10px;}
.priority-btn{flex:1;padding:8px;border:2px solid var(--border);border-radius:8px;background:none;cursor:pointer;font-size:12px;font-weight:600;transition:.15s;}
.priority-btn.high{color:#b91c1c;} .priority-btn.high.sel{border-color:#ef4444;background:#fee2e2;}
.priority-btn.med {color:#b45309;} .priority-btn.med.sel{border-color:#f59e0b;background:#fef3c7;}
.priority-btn.low {color:#166534;} .priority-btn.low.sel{border-color:#22c55e;background:#dcfce7;}
.btn-send{width:100%;padding:12px;background:var(--primary);color:#fff;border:none;border-radius:8px;font-size:15px;font-weight:600;cursor:pointer;display:flex;align-items:center;justify-content:center;gap:8px;transition:.15s;margin-top:8px;}
.btn-send:hover{background:#1d4ed8;}
.alert{padding:12px 16px;border-radius:8px;margin-bottom:20px;font-size:14px;font-weight:500;display:flex;align-items:center;gap:8px;}
.alert.success{background:#dcfce7;color:#166534;border:1px solid #bbf7d0;}
.alert.error  {background:#fee2e2;color:#991b1b;border:1px solid #fecaca;}
</style>
</head>
<body>

<!-- ── SIDEBAR ── -->
<div class="sidebar">
  <div class="sidebar-logo">
    <i class="fa fa-cubes"></i>
    <span>SIBS Admin</span>
  </div>
  <nav>
    <a class="nav-item" href="<%=request.getContextPath()%>/dashboard.jsp"><i class="fa fa-gauge-high"></i> Dashboard</a>
    <a class="nav-item" href="<%=request.getContextPath()%>/add-staff.jsp"><i class="fa fa-user-plus"></i> Add Staff</a>
    <a class="nav-item" href="<%=request.getContextPath()%>/users.jsp"><i class="fa fa-users"></i> Manage Users</a>
    <a class="nav-item" href="<%=request.getContextPath()%>/products.jsp"><i class="fa fa-box"></i> Products</a>
    <a class="nav-item" href="<%=request.getContextPath()%>/admin-orders.jsp"><i class="fa fa-shopping-bag"></i> Orders</a>
    <a class="nav-item" href="<%=request.getContextPath()%>/manage-delivery-boys.jsp"><i class="fa fa-motorcycle"></i> Delivery Boys</a>
    <a class="nav-item" href="<%=request.getContextPath()%>/admin-delivery-approvals.jsp"><i class="fa fa-user-check"></i> Delivery Approvals</a>
    <a class="nav-item" href="<%=request.getContextPath()%>/delivery-monitor.jsp"><i class="fa fa-satellite-dish"></i> Delivery Monitor</a>
    <a class="nav-item" href="admin-delivery-slots.jsp"><i class="fa fa-calendar-check"></i> Delivery Slots</a>
    <a class="nav-item" href="<%=request.getContextPath()%>/AdminReturnServlet?action=list"><i class="fa fa-rotate-left"></i> Manage Returns</a>
    <a class="nav-item" href="<%=request.getContextPath()%>/admin-cod-ledger.jsp"><i class="fa fa-money-bill-wave"></i> COD Remittance</a>
    <a class="nav-item" href="<%=request.getContextPath()%>/staff-cancelled-orders.jsp"><i class="fa fa-ban"></i> Cancelled Orders</a>
    <a class="nav-item" href="<%=request.getContextPath()%>/admin-attendance.jsp"><i class="fa fa-clock"></i> Staff Attendance</a>
    <a class="nav-item" href="<%=request.getContextPath()%>/admin-leave.jsp"><i class="fa fa-calendar-xmark"></i> Leave Requests</a>
    <a class="nav-item active" href="<%=request.getContextPath()%>/admin-notifications.jsp"><i class="fa fa-bullhorn"></i> Broadcast</a>
    <a class="nav-item" href="<%=request.getContextPath()%>/invoice.jsp"><i class="fa fa-file-invoice"></i> Billing</a>
  </nav>
  <div class="sidebar-footer">
    <a class="nav-item" href="<%=request.getContextPath()%>/logout" style="padding:0;color:#94a3b8;">
      <i class="fa fa-sign-out-alt"></i> Logout (<%=user.getUsername() != null ? user.getUsername() : displayName%>)
    </a>
  </div>
</div>

<!-- ── TOPBAR ── -->
<div class="topbar">
  <div class="topbar-left"><i class="fa fa-bullhorn" style="color:#2563eb;margin-right:8px;"></i>Broadcast Notifications</div>
  <div class="topbar-right">
    <button class="dark-btn" onclick="toggleTheme()" title="Toggle dark mode"><i class="fa fa-moon"></i></button>
    <div class="profile-pill">
      <div class="avatar"><%=avatarLetter%></div>
      <div>
        <div class="profile-name"><%=displayName%></div>
        <div class="profile-role">Admin</div>
      </div>
    </div>
  </div>
</div>

<!-- ── CONTENT ── -->
<div class="content">
  <div class="page-title">Send Broadcast</div>
  <div class="page-sub">Send a custom announcement to staff, customers, delivery boys, or everyone.</div>

  <% if ("success".equals(successMsg)) { %>
  <div class="alert success"><i class="fa fa-circle-check"></i>
    Broadcast sent successfully to <%=sentCount != null ? sentCount : "all"%> recipient(s)!
  </div>
  <% } else if (errorMsg != null) { %>
  <div class="alert error"><i class="fa fa-circle-exclamation"></i>
    <% if ("missing_fields".equals(errorMsg)) { %>Missing required fields. Please fill in title and message.
    <% } else { %>Failed to send broadcast. Please try again.<% } %>
  </div>
  <% } %>

  <div class="content-grid">

    <!-- LEFT: Form -->
    <div class="card">
      <div class="card-title"><i class="fa fa-paper-plane" style="color:#2563eb;"></i> New Announcement</div>

      <form method="post" action="<%=request.getContextPath()%>/adminBroadcast">

        <div class="form-group">
          <label>Send To</label>
          <div class="target-grid">
            <label class="target-card selected" onclick="selectTarget(this)">
              <input type="radio" name="target" value="staff" checked>
              <i class="fa fa-users"></i>
              <span>All Staff</span>
              <small>Admin + Staff members</small>
            </label>
            <label class="target-card" onclick="selectTarget(this)">
              <input type="radio" name="target" value="customers">
              <i class="fa fa-user-group"></i>
              <span>All Customers</span>
              <small>Every registered customer</small>
            </label>
            <label class="target-card" onclick="selectTarget(this)">
              <input type="radio" name="target" value="delivery">
              <i class="fa fa-motorcycle"></i>
              <span>Delivery Boys</span>
              <small>All approved partners</small>
            </label>
            <label class="target-card" onclick="selectTarget(this)">
              <input type="radio" name="target" value="all">
              <i class="fa fa-globe"></i>
              <span>Everyone</span>
              <small>Staff + Customers + Delivery</small>
            </label>
          </div>
        </div>

        <div class="form-group">
          <label>Priority</label>
          <div class="priority-row">
            <button type="button" class="priority-btn high" onclick="setPriority('HIGH',this)">🔴 HIGH</button>
            <button type="button" class="priority-btn med sel" onclick="setPriority('MEDIUM',this)">🟡 MEDIUM</button>
            <button type="button" class="priority-btn low" onclick="setPriority('LOW',this)">🟢 LOW</button>
          </div>
          <input type="hidden" name="priority" id="priorityInput" value="MEDIUM">
        </div>

        <div class="form-group">
          <label>Notification Title</label>
          <input type="text" name="title" placeholder="e.g. Scheduled Maintenance Tonight" maxlength="120" required>
        </div>

        <div class="form-group">
          <label>Message</label>
          <textarea name="message" placeholder="Write your announcement here…" maxlength="500" required></textarea>
        </div>

        <button type="submit" class="btn-send">
          <i class="fa fa-paper-plane"></i> Send Broadcast
        </button>
      </form>
    </div>

    <!-- RIGHT: Info panel -->
    <div>
      <div class="card" style="margin-bottom:16px;">
        <div class="card-title"><i class="fa fa-circle-info" style="color:#2563eb;"></i> How it works</div>
        <div style="font-size:13px;color:var(--muted);line-height:1.8;">
          <p style="margin-bottom:10px;">Broadcast notifications appear instantly in the bell icon of each recipient's dashboard.</p>
          <div style="display:flex;flex-direction:column;gap:8px;">
            <div style="display:flex;align-items:center;gap:10px;padding:10px;background:var(--bg);border-radius:8px;border:1px solid var(--border);">
              <i class="fa fa-users" style="color:#2563eb;width:18px;"></i>
              <div><b style="color:var(--text);">All Staff</b> — 1 broadcast row, all staff see it</div>
            </div>
            <div style="display:flex;align-items:center;gap:10px;padding:10px;background:var(--bg);border-radius:8px;border:1px solid var(--border);">
              <i class="fa fa-user-group" style="color:#7c3aed;width:18px;"></i>
              <div><b style="color:var(--text);">All Customers</b> — individual row per customer</div>
            </div>
            <div style="display:flex;align-items:center;gap:10px;padding:10px;background:var(--bg);border-radius:8px;border:1px solid var(--border);">
              <i class="fa fa-motorcycle" style="color:#16a34a;width:18px;"></i>
              <div><b style="color:var(--text);">Delivery Boys</b> — approved partners only</div>
            </div>
            <div style="display:flex;align-items:center;gap:10px;padding:10px;background:var(--bg);border-radius:8px;border:1px solid var(--border);">
              <i class="fa fa-globe" style="color:#ea580c;width:18px;"></i>
              <div><b style="color:var(--text);">Everyone</b> — all three groups combined</div>
            </div>
          </div>
        </div>
      </div>

      <div class="card">
        <div class="card-title"><i class="fa fa-shield-halved" style="color:#f59e0b;"></i> Priority Guide</div>
        <div style="display:flex;flex-direction:column;gap:10px;font-size:13px;">
          <div style="padding:12px;border-radius:8px;background:#fee2e2;border:1px solid #fecaca;">
            <b style="color:#b91c1c;">🔴 HIGH</b>
            <p style="color:#7f1d1d;margin-top:4px;">Urgent alerts — system outage, security issues, immediate action required</p>
          </div>
          <div style="padding:12px;border-radius:8px;background:#fef3c7;border:1px solid #fde68a;">
            <b style="color:#b45309;">🟡 MEDIUM</b>
            <p style="color:#78350f;margin-top:4px;">Important updates — new policy, schedule changes, feature updates</p>
          </div>
          <div style="padding:12px;border-radius:8px;background:#dcfce7;border:1px solid #bbf7d0;">
            <b style="color:#166534;">🟢 LOW</b>
            <p style="color:#14532d;margin-top:4px;">General info — tips, reminders, non-urgent announcements</p>
          </div>
        </div>
      </div>
    </div>

  </div><!-- /content-grid -->
</div>

<script>
function selectTarget(el) {
  document.querySelectorAll('.target-card').forEach(c => c.classList.remove('selected'));
  el.classList.add('selected');
  el.querySelector('input[type=radio]').checked = true;
}
function setPriority(val, btn) {
  document.querySelectorAll('.priority-btn').forEach(b => b.classList.remove('sel'));
  btn.classList.add('sel');
  document.getElementById('priorityInput').value = val;
}
function toggleTheme() {
  const html = document.documentElement;
  html.setAttribute('data-theme', html.getAttribute('data-theme') === 'dark' ? 'light' : 'dark');
}
</script>
</body>
</html>
