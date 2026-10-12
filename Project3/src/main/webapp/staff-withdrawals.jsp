<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.util.*,com.sibs.dao.DeliveryBoyDAO,com.sibs.model.User" %>
<%
User user = (User)session.getAttribute("user");
if(user == null || (!"STAFF".equals(user.getRole()) && !"ADMIN".equals(user.getRole()))){
    response.sendRedirect("login.jsp");
    return;
}

DeliveryBoyDAO dao = new DeliveryBoyDAO();
List<String[]> requests = dao.getAllWithdrawRequests();

String flash = request.getParameter("flash");
%>
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Wallet Withdraw Requests — SIBS</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<style>
:root{--bg:#f8fafc;--surface:#fff;--border:#e2e8f0;--text:#0f172a;--muted:#64748b;--primary:#2563eb;--success:#16a34a;--danger:#ef4444;--warn:#f59e0b;--violet:#7c3aed;}
[data-theme="dark"]{--bg:#0f172a;--surface:#1e293b;--border:#334155;--text:#f1f5f9;--muted:#94a3b8;}
*{margin:0;padding:0;box-sizing:border-box;font-family:'Inter',sans-serif;}
body{background:var(--bg);color:var(--text);}
/* TOPBAR */
.topbar{background:var(--surface);border-bottom:1px solid var(--border);padding:0 24px;height:60px;display:flex;align-items:center;justify-content:space-between;position:sticky;top:0;z-index:50;}
.topbar-left{display:flex;align-items:center;gap:10px;}
.topbar-left a{color:var(--muted);text-decoration:none;font-size:13px;display:flex;align-items:center;gap:5px;}
.topbar-left a:hover{color:var(--primary);}
.page-title{font-weight:700;font-size:16px;}
.topbar-right{display:flex;gap:10px;align-items:center;}
.dark-btn{background:none;border:1px solid var(--border);width:34px;height:34px;border-radius:8px;cursor:pointer;color:var(--muted);}
/* ALERT */
.alert{padding:12px 18px;border-radius:10px;font-size:13px;font-weight:500;margin-bottom:16px;display:flex;align-items:center;gap:10px;}
.alert-success{background:#dcfce7;color:#15803d;border:1px solid #bbf7d0;}
.alert-danger{background:#fee2e2;color:#b91c1c;border:1px solid #fecaca;}
.alert-warn{background:#fef3c7;color:#92400e;border:1px solid #fde68a;}
/* CONTENT */
.content{padding:24px;max-width:1100px;margin:0 auto;}
.top-row{display:flex;justify-content:space-between;align-items:center;margin-bottom:18px;flex-wrap:wrap;gap:10px;}
.section-title{font-size:18px;font-weight:700;}
.section-sub{font-size:13px;color:var(--muted);margin-top:2px;}
/* STATS */
.stats-row{display:flex;gap:12px;margin-bottom:20px;flex-wrap:wrap;}
.stat-card{background:var(--surface);border:1px solid var(--border);border-radius:12px;padding:16px 20px;flex:1;min-width:140px;}
.stat-label{font-size:11px;font-weight:600;text-transform:uppercase;letter-spacing:.05em;color:var(--muted);}
.stat-value{font-size:24px;font-weight:700;margin-top:4px;}
.stat-value.pending{color:var(--warn);}
.stat-value.approved{color:var(--success);}
.stat-value.rejected{color:var(--danger);}
/* FILTER */
.controls{display:flex;gap:10px;margin-bottom:14px;flex-wrap:wrap;}
.controls input,.controls select{padding:9px 14px;border:1px solid var(--border);border-radius:8px;background:var(--surface);color:var(--text);font-size:13px;outline:none;}
.controls input:focus,.controls select:focus{border-color:var(--primary);}
/* TABLE */
.table-wrap{background:var(--surface);border:1px solid var(--border);border-radius:12px;overflow:hidden;}
table{width:100%;border-collapse:collapse;}
th{padding:12px 16px;text-align:left;font-size:11px;font-weight:600;color:var(--muted);text-transform:uppercase;letter-spacing:.4px;background:var(--bg);border-bottom:1px solid var(--border);}
td{padding:13px 16px;font-size:13px;border-bottom:1px solid var(--border);vertical-align:middle;}
tbody tr:last-child td{border-bottom:none;}
tbody tr:hover{background:var(--bg);}
.empty-row td{text-align:center;padding:40px;color:var(--muted);}
/* BADGES */
.badge{padding:4px 10px;border-radius:999px;font-size:11px;font-weight:600;display:inline-flex;align-items:center;gap:5px;}
.badge-pending{background:#fef3c7;color:#92400e;}
.badge-approved{background:#dcfce7;color:#15803d;}
.badge-rejected{background:#fee2e2;color:#b91c1c;}
/* AMOUNT */
.amount{font-weight:700;font-size:14px;color:var(--violet);}
/* ACTION BTNS */
.btn{padding:6px 14px;border:none;border-radius:7px;cursor:pointer;font-size:12px;font-weight:600;transition:.15s;}
.btn-approve{background:#16a34a;color:#fff;}
.btn-reject{background:#ef4444;color:#fff;}
.btn:hover{opacity:.85;transform:translateY(-1px);}
.btn:disabled{opacity:.45;cursor:not-allowed;transform:none;}
.actions{display:flex;gap:6px;flex-wrap:wrap;}
/* MODAL */
.modal-overlay{display:none;position:fixed;inset:0;background:rgba(0,0,0,.45);z-index:200;align-items:center;justify-content:center;}
.modal-overlay.active{display:flex;}
.modal-box{background:var(--surface);border-radius:14px;padding:28px;min-width:340px;max-width:440px;width:90%;box-shadow:0 20px 60px rgba(0,0,0,.25);}
.modal-title{font-weight:700;font-size:15px;margin-bottom:6px;}
.modal-sub{font-size:13px;color:var(--muted);margin-bottom:14px;}
.modal-highlight{font-size:22px;font-weight:700;color:var(--violet);margin-bottom:14px;}
.modal-box textarea{width:100%;border:1px solid var(--border);border-radius:8px;padding:10px;font-size:13px;color:var(--text);background:var(--surface);resize:vertical;min-height:70px;outline:none;}
.modal-box textarea:focus{border-color:var(--primary);}
.modal-box label{font-size:12px;font-weight:600;color:var(--muted);display:block;margin-bottom:6px;}
.modal-actions{display:flex;gap:10px;margin-top:16px;justify-content:flex-end;}
.modal-close-btn{padding:8px 18px;border:1px solid var(--border);border-radius:8px;background:none;color:var(--text);cursor:pointer;font-size:13px;}
.modal-confirm-btn{padding:8px 20px;border:none;border-radius:8px;color:#fff;cursor:pointer;font-size:13px;font-weight:600;}
.modal-confirm-btn.approve{background:#16a34a;}
.modal-confirm-btn.reject{background:#ef4444;}
/* DB INFO */
.db-name{font-weight:600;}
.db-phone{font-size:11px;color:var(--muted);margin-top:2px;}
/* NOTE */
.staff-note{font-size:11px;color:var(--muted);font-style:italic;max-width:180px;}
/* RESPONSIVE */
@media(max-width:700px){
  .content{padding:14px;}
  th:nth-child(4),td:nth-child(4),th:nth-child(7),td:nth-child(7){display:none;}
}
</style>
</head>
<body>

<!-- TOPBAR -->
<div class="topbar">
  <div class="topbar-left">
    <a href="staff-dashboard.jsp"><i class="fa fa-chevron-left"></i> Dashboard</a>
    <span style="color:var(--border)">|</span>
    <span class="page-title"><i class="fa fa-wallet" style="color:var(--violet)"></i> Withdraw Requests</span>
  </div>
  <div class="topbar-right">
    <button class="dark-btn" onclick="toggleDark()" title="Toggle dark mode"><i class="fa fa-moon"></i></button>
    <%@ include file="includes/staffNotificationBell.jsp" %>
  </div>
</div>

<div class="content">

  <!-- FLASH MESSAGES -->
  <% if("approved".equals(flash)) { %>
    <div class="alert alert-success"><i class="fa fa-check-circle"></i> Withdrawal approved and wallet debited successfully.</div>
  <% } else if("rejected".equals(flash)) { %>
    <div class="alert alert-danger"><i class="fa fa-times-circle"></i> Withdrawal request rejected.</div>
  <% } else if("insufficient".equals(flash)) { %>
    <div class="alert alert-warn"><i class="fa fa-exclamation-triangle"></i> Insufficient wallet balance — delivery boy's wallet would drop below ₹200 minimum.</div>
  <% } else if("not_found".equals(flash)) { %>
    <div class="alert alert-warn"><i class="fa fa-question-circle"></i> Request not found or already processed.</div>
  <% } else if("error".equals(flash)) { %>
    <div class="alert alert-danger"><i class="fa fa-exclamation-circle"></i> An error occurred. Please try again.</div>
  <% } %>

  <!-- HEADER -->
  <div class="top-row">
    <div>
      <div class="section-title">Wallet Withdraw Requests</div>
      <div class="section-sub">Review and approve or reject delivery boy withdrawal requests.</div>
    </div>
  </div>

  <!-- STATS -->
  <%
    long pendingCount  = requests.stream().filter(r -> "PENDING".equals(r[5])).count();
    long approvedCount = requests.stream().filter(r -> "APPROVED".equals(r[5])).count();
    long rejectedCount = requests.stream().filter(r -> "REJECTED".equals(r[5])).count();
    double totalApproved = requests.stream()
        .filter(r -> "APPROVED".equals(r[5]))
        .mapToDouble(r -> { try { return Double.parseDouble(r[4]); } catch(Exception e){ return 0; } })
        .sum();
  %>
  <div class="stats-row">
    <div class="stat-card">
      <div class="stat-label">Pending</div>
      <div class="stat-value pending"><%= pendingCount %></div>
    </div>
    <div class="stat-card">
      <div class="stat-label">Approved</div>
      <div class="stat-value approved"><%= approvedCount %></div>
    </div>
    <div class="stat-card">
      <div class="stat-label">Rejected</div>
      <div class="stat-value rejected"><%= rejectedCount %></div>
    </div>
    <div class="stat-card">
      <div class="stat-label">Total Disbursed</div>
      <div class="stat-value" style="color:var(--violet)">₹<%= String.format("%.0f", totalApproved) %></div>
    </div>
  </div>

  <!-- FILTER -->
  <div class="controls">
    <input type="text" id="searchInput" placeholder="🔍 Search by name or phone..." oninput="filterTable()">
    <select id="statusFilter" onchange="filterTable()">
      <option value="">All Statuses</option>
      <option value="PENDING">Pending</option>
      <option value="APPROVED">Approved</option>
      <option value="REJECTED">Rejected</option>
    </select>
  </div>

  <!-- TABLE -->
  <div class="table-wrap">
    <table id="mainTable">
      <thead>
        <tr>
          <th>#</th>
          <th>Delivery Boy</th>
          <th>Amount</th>
          <th>Requested At</th>
          <th>Status</th>
          <th>Staff Note</th>
          <th>Actions</th>
        </tr>
      </thead>
      <tbody>
      <% if(requests.isEmpty()) { %>
        <tr class="empty-row">
          <td colspan="7">
            <i class="fa fa-inbox" style="font-size:28px;display:block;margin-bottom:8px;opacity:.3"></i>
            No withdrawal requests yet.
          </td>
        </tr>
      <% } %>
      <% for(String[] r : requests) {
           String reqId    = r[0];
           String dbName   = r[1];
           String dbPhone  = r[2];
           String dbId     = r[3];
           String amtStr   = r[4];
           String status   = r[5];
           String sNote    = r[6] != null ? r[6] : "";
           String reqAt    = r[7] != null ? r[7].replace("T"," ").substring(0, Math.min(16,r[7].length())) : "";
           double amt      = 0;
           try { amt = Double.parseDouble(amtStr); } catch(Exception ignored){}
      %>
        <tr data-name="<%= dbName.toLowerCase() %>" data-phone="<%= dbPhone != null ? dbPhone : "" %>" data-status="<%= status %>">
          <td style="color:var(--muted);font-size:12px">#<%= reqId %></td>
          <td>
            <div class="db-name"><%= dbName %></div>
            <div class="db-phone"><i class="fa fa-phone" style="font-size:10px"></i> <%= dbPhone != null ? dbPhone : "—" %></div>
          </td>
          <td><span class="amount">₹<%= String.format("%.2f", amt) %></span></td>
          <td style="color:var(--muted);font-size:12px"><%= reqAt %></td>
          <td>
            <% if("PENDING".equals(status)) { %>
              <span class="badge badge-pending"><i class="fa fa-clock"></i> Pending</span>
            <% } else if("APPROVED".equals(status)) { %>
              <span class="badge badge-approved"><i class="fa fa-check"></i> Approved</span>
            <% } else { %>
              <span class="badge badge-rejected"><i class="fa fa-times"></i> Rejected</span>
            <% } %>
          </td>
          <td>
            <% if(!sNote.isBlank()) { %>
              <span class="staff-note"><%= sNote %></span>
            <% } else { %>
              <span style="color:var(--muted);font-size:12px">—</span>
            <% } %>
          </td>
          <td>
            <% if("PENDING".equals(status)) { %>
              <div class="actions">
                <button class="btn btn-approve"
                  onclick="openModal('approve', '<%= reqId %>', '<%= dbName.replace("'","\\\'") %>', '<%= String.format("%.2f", amt) %>')">
                  <i class="fa fa-check"></i> Approve
                </button>
                <button class="btn btn-reject"
                  onclick="openModal('reject', '<%= reqId %>', '<%= dbName.replace("'","\\\'") %>', '<%= String.format("%.2f", amt) %>')">
                  <i class="fa fa-times"></i> Reject
                </button>
              </div>
            <% } else { %>
              <span style="color:var(--muted);font-size:12px">Done</span>
            <% } %>
          </td>
        </tr>
      <% } %>
      </tbody>
    </table>
  </div>
</div>

<!-- APPROVE/REJECT MODAL -->
<div class="modal-overlay" id="actionModal">
  <div class="modal-box">
    <div class="modal-title" id="modalTitle">Confirm Action</div>
    <div class="modal-sub" id="modalSub"></div>
    <div class="modal-highlight" id="modalAmount"></div>
    <label for="staffNote">Note / Reason (optional)</label>
    <textarea id="staffNote" placeholder="Add a note for the delivery boy..."></textarea>
    <div class="modal-actions">
      <button class="modal-close-btn" onclick="closeModal()">Cancel</button>
      <button class="modal-confirm-btn" id="modalConfirmBtn" onclick="submitAction()">Confirm</button>
    </div>
  </div>
</div>

<!-- Hidden form -->
<form id="actionForm" method="POST" action="staffWithdraw">
  <input type="hidden" name="action"    id="formAction">
  <input type="hidden" name="requestId" id="formRequestId">
  <input type="hidden" name="staffNote" id="formStaffNote">
</form>

<script>
let currentAction = '';

function openModal(action, requestId, name, amount) {
  currentAction = action;
  document.getElementById('formAction').value    = action;
  document.getElementById('formRequestId').value = requestId;
  document.getElementById('staffNote').value     = '';

  const isApprove = action === 'approve';
  document.getElementById('modalTitle').textContent =
    isApprove ? '✅ Approve Withdrawal' : '❌ Reject Withdrawal';
  document.getElementById('modalSub').textContent =
    isApprove
      ? `Approve and debit ₹${amount} from ${name}'s wallet?`
      : `Reject withdrawal request from ${name}?`;
  document.getElementById('modalAmount').textContent = `₹${amount}`;

  const btn = document.getElementById('modalConfirmBtn');
  btn.textContent = isApprove ? 'Approve & Debit' : 'Reject Request';
  btn.className   = 'modal-confirm-btn ' + (isApprove ? 'approve' : 'reject');

  document.getElementById('actionModal').classList.add('active');
}

function closeModal() {
  document.getElementById('actionModal').classList.remove('active');
}

function submitAction() {
  document.getElementById('formStaffNote').value = document.getElementById('staffNote').value;
  document.getElementById('actionForm').submit();
}

// Close modal on overlay click
document.getElementById('actionModal').addEventListener('click', function(e){
  if(e.target === this) closeModal();
});

// Filter
function filterTable() {
  const search = document.getElementById('searchInput').value.toLowerCase();
  const status = document.getElementById('statusFilter').value;
  document.querySelectorAll('#mainTable tbody tr:not(.empty-row)').forEach(row => {
    const name  = row.getAttribute('data-name') || '';
    const phone = row.getAttribute('data-phone') || '';
    const st    = row.getAttribute('data-status') || '';
    const matchSearch = name.includes(search) || phone.includes(search);
    const matchStatus = !status || st === status;
    row.style.display = (matchSearch && matchStatus) ? '' : 'none';
  });
}

// Dark mode
function toggleDark() {
  const html = document.documentElement;
  html.setAttribute('data-theme', html.getAttribute('data-theme') === 'dark' ? 'light' : 'dark');
}
</script>
</body>
</html>
