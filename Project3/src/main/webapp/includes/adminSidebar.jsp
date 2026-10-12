<%@ page import="com.sibs.model.User,
                 com.sibs.dao.SupportComplaintDAO,
                 com.sibs.dao.ReturnDAO,
                 com.sibs.dao.DeliveryBoyDAO,
                 com.sibs.dao.StaffLeaveDAO,
                 com.sibs.dao.NotificationDAO" %>
<%
User currentUser = (User) session.getAttribute("user");
if (currentUser == null) {
    response.sendRedirect(request.getContextPath() + "/login.jsp");
    return;
}
String role = currentUser.getRole();

// ── Live badge counts (real DB queries) ──────────────────────────────
int openComplaints   = 0;
int pendingReturns   = 0;
int pendingApprovals = 0;
int pendingLeaves    = 0;
int unreadNotifs     = 0;

try { openComplaints   = new SupportComplaintDAO().countOpen();               } catch (Exception ignored) {}
try { pendingReturns   = new ReturnDAO().countPending();                       } catch (Exception ignored) {}
try { pendingApprovals = new DeliveryBoyDAO().countPendingApprovals();         } catch (Exception ignored) {}
try { pendingLeaves    = new StaffLeaveDAO().countAllPending();                } catch (Exception ignored) {}
try { unreadNotifs     = new NotificationDAO().countUnreadForStaff(currentUser.getId()); } catch (Exception ignored) {}
%>
<style>
:root{
  --bg:#f8fafc;--surface:#fff;--border:#e2e8f0;
  --text:#0f172a;--muted:#64748b;
  --primary:#2563eb;--success:#16a34a;--danger:#ef4444;--warn:#f59e0b;
  --sidebar:#0f172a;--sidebar-text:#cbd5e1;--sidebar-hover:#1e293b;
  --shadow:0 1px 3px rgba(0,0,0,.1),0 1px 2px rgba(0,0,0,.06);
}
*{margin:0;padding:0;box-sizing:border-box;font-family:'Inter',sans-serif;}
body{background:var(--bg);color:var(--text);min-height:100vh;}
.sidebar{width:240px;height:100vh;background:var(--sidebar);position:fixed;top:0;left:0;display:flex;flex-direction:column;z-index:200;}
.sidebar-logo{padding:20px 24px;border-bottom:1px solid rgba(255,255,255,.07);display:flex;align-items:center;gap:10px;}
.sidebar-logo span{color:#fff;font-weight:700;font-size:18px;}
.sidebar-logo i{color:var(--primary);font-size:20px;}
.sidebar nav{flex:1;padding:12px 0;overflow-y:auto;}
.nav-item{display:flex;align-items:center;gap:10px;padding:11px 20px;color:var(--sidebar-text);text-decoration:none;font-size:14px;transition:.15s;border-left:3px solid transparent;}
.nav-item:hover,.nav-item.active{background:var(--sidebar-hover);color:#fff;border-left-color:var(--primary);}
.nav-item i{width:18px;text-align:center;}
/* badge */
.nav-badge{margin-left:auto;background:#ef4444;color:#fff;font-size:10px;font-weight:700;
           padding:1px 6px;border-radius:999px;min-width:18px;text-align:center;line-height:16px;}
.nav-badge.warn{background:#f59e0b;color:#1c1000;}
.sidebar-footer{padding:16px;border-top:1px solid rgba(255,255,255,.07);}
.content-area{margin-left:240px;padding:30px;}

/* Bell in sidebar footer */
.bell-wrap{position:relative;display:inline-flex;align-items:center;}
.bell-dot{position:absolute;top:-3px;right:-3px;width:8px;height:8px;background:#ef4444;border-radius:50%;border:2px solid var(--sidebar);}
</style>

<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">

<div class="sidebar" id="sidebar">
  <div class="sidebar-logo">
    <i class="fa fa-cubes"></i>
    <span>SIBS Admin</span>
  </div>
  <nav>
    <a class="nav-item" href="<%=request.getContextPath()%>/dashboard.jsp">
      <i class="fa fa-gauge-high"></i> Dashboard
    </a>

    <% if ("ADMIN".equals(role)) { %>
    <a class="nav-item" href="<%=request.getContextPath()%>/add-staff.jsp">
      <i class="fa fa-user-plus"></i> Add Staff
    </a>
    <a class="nav-item" href="<%=request.getContextPath()%>/users.jsp">
      <i class="fa fa-users"></i> Manage Users
    </a>
    <% } %>

    <a class="nav-item" href="<%=request.getContextPath()%>/products.jsp">
      <i class="fa fa-box"></i> Products
    </a>

    <a class="nav-item" href="<%=request.getContextPath()%>/admin-orders.jsp">
      <i class="fa fa-shopping-bag"></i> Orders
    </a>

    <a class="nav-item" href="<%=request.getContextPath()%>/manage-delivery-boys.jsp">
      <i class="fa fa-motorcycle"></i> Delivery Boys
    </a>

    <a class="nav-item" href="<%=request.getContextPath()%>/admin-delivery-approvals.jsp">
      <i class="fa fa-user-check"></i> Delivery Approvals
      <% if (pendingApprovals > 0) { %>
        <span class="nav-badge warn"><%=pendingApprovals%></span>
      <% } %>
    </a>

    <a class="nav-item" href="<%=request.getContextPath()%>/staff-withdrawals.jsp">
      <i class="fa fa-money-bill-wave"></i> Wallet Withdrawals
      <%
        com.sibs.dao.DeliveryBoyDAO _wdao = new com.sibs.dao.DeliveryBoyDAO();
        int _pendingWd = _wdao.countPendingWithdrawRequests();
        if (_pendingWd > 0) { %>
          <span class="nav-badge warn"><%=_pendingWd%></span>
      <% } %>
    </a>

    <a class="nav-item" href="<%=request.getContextPath()%>/delivery-monitor.jsp">
      <i class="fa fa-satellite-dish"></i> Delivery Monitor
    </a>

    <a class="nav-item" href="admin-delivery-slots.jsp">
      <i class="fa fa-calendar-check"></i> Delivery Slots
    </a>

    <a class="nav-item" href="<%=request.getContextPath()%>/AdminReturnServlet?action=list">
      <i class="fa fa-rotate-left"></i> Manage Returns
      <% if (pendingReturns > 0) { %>
        <span class="nav-badge"><%=pendingReturns%></span>
      <% } %>
    </a>

    <a class="nav-item" href="<%=request.getContextPath()%>/admin-cod-ledger.jsp">
      <i class="fa fa-money-bill-wave"></i> COD Remittance
    </a>

    <a class="nav-item" href="<%=request.getContextPath()%>/staff-cancelled-orders.jsp">
      <i class="fa fa-ban"></i> Cancelled / Not Delivered
    </a>

    <% if ("ADMIN".equals(role)) { %>
    <a class="nav-item" href="<%=request.getContextPath()%>/admin-attendance.jsp">
      <i class="fa fa-clock"></i> Staff Attendance
    </a>
    <a class="nav-item" href="<%=request.getContextPath()%>/admin-leave.jsp">
      <i class="fa fa-calendar-xmark"></i> Leave Requests
      <% if (pendingLeaves > 0) { %>
        <span class="nav-badge warn"><%=pendingLeaves%></span>
      <% } %>
    </a>
    <a class="nav-item" href="<%=request.getContextPath()%>/admin-notifications.jsp">
      <i class="fa fa-bullhorn"></i> Broadcast
    </a>
    <a class="nav-item" href="<%=request.getContextPath()%>/invoice.jsp">
      <i class="fa fa-file-invoice"></i> Billing
    </a>
    <% } %>
  </nav>

  <div class="sidebar-footer">
    <a class="nav-item bell-wrap" href="<%=request.getContextPath()%>/staff-notifications.jsp" id="adminBellLink">
      <i class="fa fa-bell"></i> Notifications
      <span id="adminBellBadge" class="nav-badge" style="display:none;"></span>
    </a>
    <a class="nav-item" href="<%=request.getContextPath()%>/support">
      <i class="fa fa-headset"></i> Support Complaints
      <% if (openComplaints > 0) { %>
        <span class="nav-badge"><%=openComplaints%></span>
      <% } %>
    </a>
    <a class="nav-item" href="<%=request.getContextPath()%>/admin-settings.jsp">
      <i class="fa fa-gear"></i> Settings
    </a>
    <a class="nav-item" href="<%=request.getContextPath()%>/logout" style="padding:0;color:#94a3b8;">
      <i class="fa fa-sign-out-alt"></i> Logout (<%=currentUser.getUsername()%>)
    </a>
  </div>
</div>
<script>
(function() {
  var badge   = document.getElementById('adminBellBadge');
  var ctx     = '<%=request.getContextPath()%>';
  function pollAdminBell() {
    fetch(ctx + '/getNotifications', { credentials: 'same-origin' })
      .then(function(r) { return r.json(); })
      .then(function(data) {
        if (data && data.unread > 0) {
          badge.textContent = data.unread > 99 ? '99+' : data.unread;
          badge.style.display = '';
        } else {
          badge.style.display = 'none';
        }
      })
      .catch(function() {});
  }
  pollAdminBell();
  setInterval(pollAdminBell, 60000);
})();
</script>
