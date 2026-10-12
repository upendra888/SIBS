<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="com.sibs.model.User, com.sibs.model.StaffLeave, com.sibs.dao.StaffLeaveDAO, java.util.List" %>
<%
User user = (User) session.getAttribute("user");
if (user == null || !"STAFF".equals(user.getRole())) {
    response.sendRedirect("login.jsp");
    return;
}

StaffLeaveDAO dao       = new StaffLeaveDAO();
List<StaffLeave> leaves = dao.getByEmployee(user.getId());

// Null-safe display name — fall back to username, then "Staff"
String displayName = user.getName() != null && !user.getName().isEmpty()
                     ? user.getName()
                     : (user.getUsername() != null ? user.getUsername() : "Staff");
String avatarLetter = displayName.substring(0, 1).toUpperCase();

// Today's date as string for the min-date constraint on the date picker
java.time.LocalDate today = java.time.LocalDate.now();
String todayStr = today.toString();
%>
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>My Leave Applications — SIBS</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<style>
:root{--bg:#f8fafc;--surface:#fff;--border:#e2e8f0;--text:#0f172a;--muted:#64748b;--primary:#2563eb;--success:#16a34a;--danger:#ef4444;--warn:#f59e0b;--sidebar:#0f172a;--sidebar-text:#cbd5e1;--sidebar-hover:#1e293b;}
[data-theme="dark"]{--bg:#0f172a;--surface:#1e293b;--border:#334155;--text:#f1f5f9;--muted:#94a3b8;--sidebar:#020617;--sidebar-hover:#0f172a;}
*{margin:0;padding:0;box-sizing:border-box;font-family:'Inter',sans-serif;}
body{background:var(--bg);color:var(--text);}

/* ── SIDEBAR ── */
.sidebar{width:240px;height:100vh;background:var(--sidebar);position:fixed;top:0;left:0;display:flex;flex-direction:column;z-index:200;}
.sidebar-logo{padding:20px 24px;border-bottom:1px solid rgba(255,255,255,.07);display:flex;align-items:center;gap:10px;}
.sidebar-logo span{color:#fff;font-weight:700;font-size:17px;}
.sidebar-logo i{color:#f97316;font-size:19px;}
.sidebar nav{flex:1;padding:12px 0;overflow-y:auto;}
.nav-item{display:flex;align-items:center;gap:10px;padding:11px 20px;color:var(--sidebar-text);text-decoration:none;font-size:14px;transition:.15s;border-left:3px solid transparent;}
.nav-item:hover,.nav-item.active{background:var(--sidebar-hover);color:#fff;border-left-color:#f97316;}
.nav-item i{width:18px;text-align:center;}
.sidebar-footer{padding:16px;border-top:1px solid rgba(255,255,255,.07);}

/* ── TOPBAR ── */
.topbar{margin-left:240px;height:62px;background:var(--surface);border-bottom:1px solid var(--border);display:flex;align-items:center;justify-content:space-between;padding:0 24px;position:sticky;top:0;z-index:100;box-shadow:0 1px 3px rgba(0,0,0,.06);}
.topbar-left{font-weight:600;font-size:15px;}
.topbar-right{display:flex;align-items:center;gap:12px;}
.dark-btn{background:none;border:1px solid var(--border);width:34px;height:34px;border-radius:8px;cursor:pointer;color:var(--muted);}
.profile-pill{display:flex;align-items:center;gap:8px;cursor:pointer;padding:6px 10px;border-radius:8px;border:1px solid var(--border);}
.avatar{width:30px;height:30px;border-radius:50%;background:#f97316;display:flex;align-items:center;justify-content:center;color:#fff;font-weight:700;font-size:12px;}
.profile-name{font-size:13px;font-weight:500;}
.profile-role{font-size:11px;color:var(--muted);}

/* ── CONTENT ── */
.content{margin-left:240px;padding:28px 24px;}
.page-title{font-size:20px;font-weight:700;margin-bottom:4px;}
.page-sub{font-size:13px;color:var(--muted);margin-bottom:24px;}

/* ── APPLY CARD ── */
.card{background:var(--surface);border:1px solid var(--border);border-radius:14px;padding:24px;box-shadow:0 1px 4px rgba(0,0,0,.06);margin-bottom:28px;}
.card-title{font-size:15px;font-weight:600;margin-bottom:18px;display:flex;align-items:center;gap:8px;}
.form-grid{display:grid;grid-template-columns:1fr 1fr;gap:16px;}
.form-group{display:flex;flex-direction:column;gap:6px;}
.form-group.full{grid-column:1/-1;}
label{font-size:12px;font-weight:600;color:var(--muted);text-transform:uppercase;letter-spacing:.4px;}
input,select,textarea{background:var(--bg);border:1px solid var(--border);border-radius:8px;padding:9px 12px;font-size:13px;color:var(--text);width:100%;outline:none;transition:.15s;}
input:focus,select:focus,textarea:focus{border-color:var(--primary);box-shadow:0 0 0 3px rgba(37,99,235,.12);}
textarea{resize:vertical;min-height:80px;}
.btn{padding:9px 20px;border-radius:8px;border:none;font-size:13px;font-weight:600;cursor:pointer;display:inline-flex;align-items:center;gap:7px;transition:.15s;}
.btn-primary{background:var(--primary);color:#fff;}
.btn-primary:hover{background:#1d4ed8;}
.btn-danger{background:var(--danger);color:#fff;}
.btn-danger:hover{background:#dc2626;}
.btn:disabled{opacity:.5;cursor:not-allowed;}

/* ── HISTORY TABLE ── */
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
.empty-state{text-align:center;padding:40px;color:var(--muted);}
.empty-state i{font-size:36px;margin-bottom:10px;display:block;}

/* ── TOAST ── */
#toast{position:fixed;bottom:24px;right:24px;padding:12px 20px;border-radius:10px;font-size:13px;font-weight:500;box-shadow:0 8px 24px rgba(0,0,0,.18);z-index:9999;display:none;align-items:center;gap:10px;max-width:340px;}
#toast.show{display:flex;}
#toast.success{background:#16a34a;color:#fff;}
#toast.error{background:#ef4444;color:#fff;}

/* ── MODAL ── */
.modal-overlay{position:fixed;inset:0;background:rgba(0,0,0,.4);z-index:500;display:none;align-items:center;justify-content:center;}
.modal-overlay.open{display:flex;}
.modal{background:var(--surface);border-radius:14px;padding:28px;width:380px;max-width:95vw;box-shadow:0 20px 50px rgba(0,0,0,.25);}
.modal-title{font-size:16px;font-weight:700;margin-bottom:6px;}
.modal-sub{font-size:13px;color:var(--muted);margin-bottom:20px;}
.modal-actions{display:flex;gap:10px;justify-content:flex-end;margin-top:20px;}
.btn-ghost{background:none;border:1px solid var(--border);color:var(--text);}
.btn-ghost:hover{background:var(--bg);}
</style>
</head>
<body>

<!-- ── SIDEBAR ── -->
<div class="sidebar">
  <div class="sidebar-logo">
    <i class="fa fa-fire-burner"></i>
    <span>SIBS</span>
  </div>
  <nav>
    <a class="nav-item" href="staff-dashboard.jsp"><i class="fa fa-gauge-high"></i> Dashboard</a>
    <a class="nav-item" href="staff-attendance.jsp"><i class="fa fa-clock"></i> My Attendance</a>
    <a class="nav-item active" href="staff-leave.jsp"><i class="fa fa-calendar-xmark"></i> My Leaves</a>
    <a class="nav-item" href="staff-orders.jsp"><i class="fa fa-shopping-bag"></i> Orders</a>
    <a class="nav-item" href="staff-cancelled-orders.jsp"><i class="fa fa-ban"></i> Cancelled Orders</a>
  </nav>
  <div class="sidebar-footer">
    <a class="nav-item" href="logout" style="padding:0;color:#94a3b8;">
      <i class="fa fa-sign-out-alt"></i> Logout (<%=user.getUsername() != null ? user.getUsername() : displayName%>)
    </a>
  </div>
</div>

<!-- ── TOPBAR ── -->
<div class="topbar">
  <div class="topbar-left"><i class="fa fa-calendar-xmark" style="color:#f97316;margin-right:8px;"></i>My Leave Applications</div>
  <div class="topbar-right">
    <button class="dark-btn" onclick="toggleTheme()" title="Toggle dark mode"><i class="fa fa-moon"></i></button>
    <%@ include file="/includes/staffNotificationBell.jsp" %>
      <div class="avatar"><%=avatarLetter%></div>
      <div>
        <div class="profile-name"><%=displayName%></div>
        <div class="profile-role">Staff</div>
      </div>
    </div>
  </div>
</div>

<!-- ── MAIN CONTENT ── -->
<div class="content">
  <div class="page-title">My Leave Applications</div>
  <div class="page-sub">Apply for leave and track the status of your requests.</div>

  <!-- Apply Form Card -->
  <div class="card">
    <div class="card-title"><i class="fa fa-plus-circle" style="color:#2563eb;"></i> Apply for Leave</div>
    <div class="form-grid">
      <div class="form-group">
        <label>Leave Type</label>
        <select id="leaveType">
          <option value="CASUAL">Casual Leave</option>
          <option value="SICK">Sick Leave</option>
          <option value="EMERGENCY">Emergency Leave</option>
          <option value="OTHER">Other</option>
        </select>
      </div>
      <div class="form-group" style="align-self:end;"><!-- spacer --></div>
      <div class="form-group">
        <label>From Date</label>
        <input type="date" id="fromDate" min="<%=todayStr%>">
      </div>
      <div class="form-group">
        <label>To Date</label>
        <input type="date" id="toDate" min="<%=todayStr%>">
      </div>
      <div class="form-group full">
        <label>Reason</label>
        <textarea id="reason" placeholder="Briefly describe the reason for your leave..."></textarea>
      </div>
    </div>
    <div style="margin-top:16px;">
      <button class="btn btn-primary" id="submitBtn" onclick="applyLeave()">
        <i class="fa fa-paper-plane"></i> Submit Application
      </button>
    </div>
  </div>

  <!-- History Table Card -->
  <div class="card">
    <div class="card-title"><i class="fa fa-list-check" style="color:#f97316;"></i> My Leave History</div>
    <div class="table-wrap">
      <% if (leaves.isEmpty()) { %>
      <div class="empty-state">
        <i class="fa fa-inbox"></i>
        No leave applications yet.
      </div>
      <% } else { %>
      <table>
        <thead>
          <tr>
            <th>#</th>
            <th>Type</th>
            <th>From</th>
            <th>To</th>
            <th>Days</th>
            <th>Reason</th>
            <th>Applied On</th>
            <th>Status</th>
            <th>Admin Remarks</th>
            <th>Action</th>
          </tr>
        </thead>
        <tbody>
          <% for (StaffLeave l : leaves) { %>
          <tr>
            <td style="color:var(--muted);"><%=l.getLeaveId()%></td>
            <td><span class="badge badge-<%=l.getLeaveType().toLowerCase()%>"><%=l.getLeaveType()%></span></td>
            <td><%=l.getFromDate()%></td>
            <td><%=l.getToDate()%></td>
            <td style="font-weight:600;"><%=l.getDays()%></td>
            <td style="max-width:180px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;" title="<%=l.getReason()%>"><%=l.getReason()%></td>
            <td style="color:var(--muted);white-space:nowrap;"><%=l.getAppliedOn() != null ? l.getAppliedOn().toString().substring(0,16) : ""%></td>
            <td><span class="badge badge-<%=l.getStatus().toLowerCase()%>"><%=l.getStatus()%></span></td>
            <td style="color:var(--muted);max-width:140px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;" title="<%=l.getAdminRemarks() != null ? l.getAdminRemarks() : ""%>">
              <%=l.getAdminRemarks() != null ? l.getAdminRemarks() : "—"%>
            </td>
            <td>
              <% if ("PENDING".equals(l.getStatus())) { %>
              <button class="btn btn-danger" style="padding:5px 12px;font-size:12px;"
                      onclick="confirmCancel(<%=l.getLeaveId()%>)">
                <i class="fa fa-xmark"></i> Cancel
              </button>
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

<!-- Cancel Confirm Modal -->
<div class="modal-overlay" id="cancelModal">
  <div class="modal">
    <div class="modal-title">Cancel Leave Application?</div>
    <div class="modal-sub">This will permanently remove your pending leave request.</div>
    <div class="modal-actions">
      <button class="btn btn-ghost" onclick="closeModal()">Keep it</button>
      <button class="btn btn-danger" id="confirmCancelBtn">Yes, Cancel</button>
    </div>
  </div>
</div>

<!-- Toast -->
<div id="toast"></div>

<script>
let pendingCancelId = null;

function applyLeave() {
  const leaveType = document.getElementById('leaveType').value;
  const fromDate  = document.getElementById('fromDate').value;
  const toDate    = document.getElementById('toDate').value;
  const reason    = document.getElementById('reason').value.trim();

  if (!fromDate || !toDate) { showToast('Please select both From and To dates.', 'error'); return; }
  if (fromDate > toDate)    { showToast('From date cannot be after To date.', 'error'); return; }
  if (!reason)              { showToast('Please enter a reason for leave.', 'error'); return; }

  const btn = document.getElementById('submitBtn');
  btn.disabled = true;

  const data = new URLSearchParams({ action:'apply', leaveType, fromDate, toDate, reason });
  fetch('<%=request.getContextPath()%>/staffLeave', { method:'POST', body:data })
    .then(r => r.json())
    .then(j => {
      if (j.ok) {
        showToast(j.message, 'success');
        setTimeout(() => location.reload(), 1200);
      } else {
        showToast(j.error, 'error');
        btn.disabled = false;
      }
    })
    .catch(() => { showToast('Network error. Please try again.', 'error'); btn.disabled = false; });
}

function confirmCancel(leaveId) {
  pendingCancelId = leaveId;
  document.getElementById('cancelModal').classList.add('open');
  document.getElementById('confirmCancelBtn').onclick = () => doCancel(leaveId);
}
function closeModal() {
  document.getElementById('cancelModal').classList.remove('open');
  pendingCancelId = null;
}
function doCancel(leaveId) {
  closeModal();
  const data = new URLSearchParams({ action:'cancel', leaveId });
  fetch('<%=request.getContextPath()%>/staffLeave', { method:'POST', body:data })
    .then(r => r.json())
    .then(j => {
      showToast(j.ok ? j.message : j.error, j.ok ? 'success' : 'error');
      if (j.ok) setTimeout(() => location.reload(), 1000);
    });
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
