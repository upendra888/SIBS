<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="com.sibs.model.User, com.sibs.model.StaffLeave, com.sibs.dao.StaffLeaveDAO, java.util.List" %>
<%
User user = (User) session.getAttribute("user");
if (user == null || !"ADMIN".equals(user.getRole())) {
    response.sendRedirect("login.jsp");
    return;
}

String filterParam = request.getParameter("filter");
if (filterParam == null) filterParam = "PENDING";

StaffLeaveDAO dao       = new StaffLeaveDAO();
List<StaffLeave> leaves = dao.getAll("ALL".equals(filterParam) ? null : filterParam);
int pendingCount        = dao.countAllPending();

// Null-safe display name
String displayName = user.getName() != null && !user.getName().isEmpty()
                     ? user.getName()
                     : (user.getUsername() != null ? user.getUsername() : "Admin");
String avatarLetter = displayName.substring(0, 1).toUpperCase();
%>
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Staff Leave Requests — SIBS Admin</title>
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
.topbar{margin-left:0;height:62px;background:var(--surface);border-bottom:1px solid var(--border);display:flex;align-items:center;justify-content:space-between;padding:0 24px;position:sticky;top:0;z-index:100;box-shadow:0 1px 3px rgba(0,0,0,.06);}
.topbar-left{font-weight:600;font-size:15px;}
.topbar-right{display:flex;align-items:center;gap:12px;}
.dark-btn{background:none;border:1px solid var(--border);width:34px;height:34px;border-radius:8px;cursor:pointer;color:var(--muted);}
.profile-pill{display:flex;align-items:center;gap:8px;cursor:pointer;padding:6px 10px;border-radius:8px;border:1px solid var(--border);}
.avatar{width:30px;height:30px;border-radius:50%;background:#2563eb;display:flex;align-items:center;justify-content:center;color:#fff;font-weight:700;font-size:12px;}
.profile-name{font-size:13px;font-weight:500;}
.profile-role{font-size:11px;color:var(--muted);}
.content{margin-left:0;padding:28px 24px;}
.page-title{font-size:20px;font-weight:700;margin-bottom:4px;}
.page-sub{font-size:13px;color:var(--muted);margin-bottom:24px;}
.card{background:var(--surface);border:1px solid var(--border);border-radius:14px;padding:24px;box-shadow:0 1px 4px rgba(0,0,0,.06);margin-bottom:24px;}

/* Filter tabs */
.filter-tabs{display:flex;gap:8px;margin-bottom:20px;flex-wrap:wrap;}
.filter-tab{padding:7px 16px;border-radius:8px;border:1px solid var(--border);font-size:13px;font-weight:500;cursor:pointer;text-decoration:none;color:var(--text);background:var(--surface);transition:.15s;}
.filter-tab:hover{border-color:var(--primary);color:var(--primary);}
.filter-tab.active{background:var(--primary);color:#fff;border-color:var(--primary);}
.pending-badge{background:#ef4444;color:#fff;font-size:10px;font-weight:700;padding:2px 6px;border-radius:99px;margin-left:4px;}

/* Table */
.table-wrap{overflow-x:auto;}
table{width:100%;border-collapse:collapse;font-size:13px;}
th{text-align:left;padding:10px 14px;font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:.4px;color:var(--muted);border-bottom:2px solid var(--border);}
td{padding:12px 14px;border-bottom:1px solid var(--border);vertical-align:middle;}
tr:last-child td{border-bottom:none;}
tr:hover td{background:var(--bg);}
.badge{padding:3px 10px;border-radius:99px;font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:.3px;}
.badge-pending  {background:#fef9c3;color:#92400e;}
.badge-approved {background:#dcfce7;color:#15803d;}
.badge-rejected {background:#fee2e2;color:#dc2626;}
.badge-sick      {background:#ede9fe;color:#6d28d9;}
.badge-casual    {background:#dbeafe;color:#1d4ed8;}
.badge-emergency {background:#fee2e2;color:#dc2626;}
.badge-other     {background:#f1f5f9;color:#475569;}
.btn{padding:7px 14px;border-radius:7px;border:none;font-size:12px;font-weight:600;cursor:pointer;display:inline-flex;align-items:center;gap:6px;transition:.15s;}
.btn-approve{background:#dcfce7;color:#15803d;}
.btn-approve:hover{background:#16a34a;color:#fff;}
.btn-reject{background:#fee2e2;color:#dc2626;}
.btn-reject:hover{background:#ef4444;color:#fff;}
.btn-ghost{background:none;border:1px solid var(--border);color:var(--text);}
.btn-ghost:hover{background:var(--bg);}
.btn-primary{background:var(--primary);color:#fff;}
.btn-primary:hover{background:#1d4ed8;}
.empty-state{text-align:center;padding:48px;color:var(--muted);}
.empty-state i{font-size:40px;margin-bottom:12px;display:block;}

/* Modal */
.modal-overlay{position:fixed;inset:0;background:rgba(0,0,0,.4);z-index:500;display:none;align-items:center;justify-content:center;}
.modal-overlay.open{display:flex;}
.modal{background:var(--surface);border-radius:14px;padding:28px;width:420px;max-width:95vw;box-shadow:0 20px 50px rgba(0,0,0,.25);}
.modal-title{font-size:16px;font-weight:700;margin-bottom:6px;}
.modal-sub{font-size:13px;color:var(--muted);margin-bottom:18px;}
.modal-actions{display:flex;gap:10px;justify-content:flex-end;margin-top:20px;}
textarea.modal-input{width:100%;border:1px solid var(--border);border-radius:8px;padding:9px 12px;font-size:13px;background:var(--bg);color:var(--text);resize:vertical;min-height:80px;outline:none;}
textarea.modal-input:focus{border-color:var(--primary);}
label.modal-label{font-size:12px;font-weight:600;color:var(--muted);text-transform:uppercase;letter-spacing:.4px;display:block;margin-bottom:6px;}

/* Toast */
#toast{position:fixed;bottom:24px;right:24px;padding:12px 20px;border-radius:10px;font-size:13px;font-weight:500;box-shadow:0 8px 24px rgba(0,0,0,.18);z-index:9999;display:none;align-items:center;gap:10px;max-width:340px;}
#toast.show{display:flex;}
#toast.success{background:#16a34a;color:#fff;}
#toast.error{background:#ef4444;color:#fff;}

.detail-row{display:flex;gap:8px;margin-bottom:8px;font-size:13px;}
.detail-row .dl{color:var(--muted);min-width:90px;font-weight:500;}
</style>
</head>
<body>

<!-- ── SIDEBAR (reuses admin nav pattern) ── -->
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
    <a class="nav-item active" href="<%=request.getContextPath()%>/admin-leave.jsp">
      <i class="fa fa-calendar-xmark"></i> Leave Requests
      <% if (pendingCount > 0) { %><span class="pending-badge"><%=pendingCount%></span><% } %>
    </a>
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
  <div class="topbar-left"><i class="fa fa-calendar-xmark" style="color:#2563eb;margin-right:8px;"></i>Staff Leave Requests</div>
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

<div class="content">
  <div class="page-title">Staff Leave Requests</div>
  <div class="page-sub">Review, approve, or reject staff leave applications.</div>

  <!-- Filter tabs -->
  <div class="filter-tabs">
    <a href="?filter=PENDING"  class="filter-tab <%="PENDING".equals(filterParam)  ? "active" : ""%>">
      Pending<% if (pendingCount > 0) { %> <span class="pending-badge" style="background:#f97316;"><%=pendingCount%></span><% } %>
    </a>
    <a href="?filter=APPROVED" class="filter-tab <%="APPROVED".equals(filterParam) ? "active" : ""%>">Approved</a>
    <a href="?filter=REJECTED" class="filter-tab <%="REJECTED".equals(filterParam) ? "active" : ""%>">Rejected</a>
    <a href="?filter=ALL"      class="filter-tab <%="ALL".equals(filterParam)      ? "active" : ""%>">All</a>
  </div>

  <div class="card">
    <div class="table-wrap">
      <% if (leaves.isEmpty()) { %>
      <div class="empty-state">
        <i class="fa fa-check-circle" style="color:#16a34a;"></i>
        No <%="ALL".equals(filterParam) ? "" : filterParam.toLowerCase()%> leave applications found.
      </div>
      <% } else { %>
      <table>
        <thead>
          <tr>
            <th>#</th>
            <th>Employee</th>
            <th>Type</th>
            <th>From</th>
            <th>To</th>
            <th>Days</th>
            <th>Reason</th>
            <th>Applied On</th>
            <th>Status</th>
            <th>Admin Remarks</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          <% for (StaffLeave l : leaves) { %>
          <tr>
            <td style="color:var(--muted);"><%=l.getLeaveId()%></td>
            <td style="font-weight:600;"><%=l.getEmployeeName() != null ? l.getEmployeeName() : "ID:"+l.getEmployeeId()%></td>
            <td><span class="badge badge-<%=l.getLeaveType().toLowerCase()%>"><%=l.getLeaveType()%></span></td>
            <td><%=l.getFromDate()%></td>
            <td><%=l.getToDate()%></td>
            <td style="font-weight:600;"><%=l.getDays()%></td>
            <td style="max-width:160px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;" title="<%=l.getReason()%>"><%=l.getReason()%></td>
            <td style="color:var(--muted);white-space:nowrap;"><%=l.getAppliedOn() != null ? l.getAppliedOn().toString().substring(0,16) : ""%></td>
            <td><span class="badge badge-<%=l.getStatus().toLowerCase()%>"><%=l.getStatus()%></span></td>
            <td style="max-width:130px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;color:var(--muted);" title="<%=l.getAdminRemarks() != null ? l.getAdminRemarks() : ""%>">
              <%=l.getAdminRemarks() != null && !l.getAdminRemarks().isEmpty() ? l.getAdminRemarks() : "—"%>
            </td>
            <td>
              <% if ("PENDING".equals(l.getStatus())) { %>
              <div style="display:flex;gap:6px;">
                <button class="btn btn-approve"
                        onclick="openActionModal(<%=l.getLeaveId()%>,'approve','<%=l.getEmployeeName() != null ? l.getEmployeeName().replace("'","") : ""%>')">
                  <i class="fa fa-check"></i> Approve
                </button>
                <button class="btn btn-reject"
                        onclick="openActionModal(<%=l.getLeaveId()%>,'reject','<%=l.getEmployeeName() != null ? l.getEmployeeName().replace("'","") : ""%>')">
                  <i class="fa fa-xmark"></i> Reject
                </button>
              </div>
              <% } else { %>
              <span style="color:var(--muted);font-size:12px;">—</span>
              <% } %>
            </td>
          </tr>
          <% } %>
        </tbody>
      </table>
      <% } %>
    </div>
  </div>
</div>

<!-- Action Modal -->
<div class="modal-overlay" id="actionModal">
  <div class="modal">
    <div class="modal-title" id="modalTitle">Approve Leave</div>
    <div class="modal-sub" id="modalSub">Add optional remarks before approving.</div>
    <label class="modal-label">Admin Remarks (optional)</label>
    <textarea class="modal-input" id="adminRemarks" placeholder="e.g. Approved. Please hand over duties before leave."></textarea>
    <div class="modal-actions">
      <button class="btn btn-ghost" onclick="closeModal()">Cancel</button>
      <button class="btn btn-primary" id="modalConfirmBtn">Confirm</button>
    </div>
  </div>
</div>

<!-- Toast -->
<div id="toast"></div>

<script>
let currentLeaveId = null;
let currentAction  = null;

function openActionModal(leaveId, action, empName) {
  currentLeaveId = leaveId;
  currentAction  = action;
  document.getElementById('adminRemarks').value = '';
  const isApprove = action === 'approve';
  document.getElementById('modalTitle').textContent = (isApprove ? 'Approve' : 'Reject') + ' Leave #' + leaveId;
  document.getElementById('modalSub').textContent   =
    'Employee: ' + (empName || 'Staff') + '. Add optional remarks below.';
  const btn = document.getElementById('modalConfirmBtn');
  btn.textContent = isApprove ? 'Approve' : 'Reject';
  btn.className   = 'btn ' + (isApprove ? 'btn-approve' : 'btn-reject');
  btn.style.color = isApprove ? '#15803d' : '#dc2626';
  btn.onclick     = () => submitAction();
  document.getElementById('actionModal').classList.add('open');
}
function closeModal() {
  document.getElementById('actionModal').classList.remove('open');
}

function submitAction() {
  const remarks = document.getElementById('adminRemarks').value.trim();
  const data = new URLSearchParams({
    action:       currentAction,
    leaveId:      currentLeaveId,
    adminRemarks: remarks
  });
  closeModal();
  fetch('<%=request.getContextPath()%>/staffLeave', { method:'POST', body:data })
    .then(r => r.json())
    .then(j => {
      showToast(j.ok ? j.message : j.error, j.ok ? 'success' : 'error');
      if (j.ok) setTimeout(() => location.reload(), 1000);
    })
    .catch(() => showToast('Network error. Please try again.', 'error'));
}

function showToast(msg, type) {
  const t = document.getElementById('toast');
  t.className = 'show ' + type;
  t.innerHTML = '<i class="fa fa-' + (type === 'success' ? 'check-circle' : 'circle-xmark') + '"></i> ' + msg;
  setTimeout(() => t.className = '', 3500);
}
function toggleTheme() {
  const h = document.documentElement;
  h.dataset.theme = h.dataset.theme === 'dark' ? 'light' : 'dark';
}
</script>
</body>
</html>
