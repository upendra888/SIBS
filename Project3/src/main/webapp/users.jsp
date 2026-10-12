<%@ page import="java.util.*,com.sibs.dao.UserDAO,com.sibs.model.User" %>
<%
User sessionUser = (User)session.getAttribute("user");
if(sessionUser == null || !"ADMIN".equals(sessionUser.getRole())){
    response.sendRedirect("login.jsp");
    return;
}
UserDAO dao = new UserDAO();
List<User> users = dao.getAllUsers();
int totalActive = 0, totalAdmin = 0, totalStaff = 0;
for(User u : users){
    if("ACTIVE".equalsIgnoreCase(u.getStatus())) totalActive++;
    if("ADMIN".equals(u.getRole())) totalAdmin++;
    if("STAFF".equals(u.getRole())) totalStaff++;
}
%>
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Users — SIBS</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<style>
:root{--bg:#f8fafc;--surface:#fff;--border:#e2e8f0;--text:#0f172a;--muted:#64748b;--primary:#2563eb;--success:#16a34a;--danger:#ef4444;}
[data-theme="dark"]{--bg:#0f172a;--surface:#1e293b;--border:#334155;--text:#f1f5f9;--muted:#94a3b8;}
*{margin:0;padding:0;box-sizing:border-box;font-family:'Inter',sans-serif;}
body{background:var(--bg);color:var(--text);}
.topbar{background:var(--surface);border-bottom:1px solid var(--border);padding:0 24px;height:60px;display:flex;align-items:center;justify-content:space-between;position:sticky;top:0;z-index:50;}
.topbar-left{display:flex;align-items:center;gap:10px;}
.topbar-left a{color:var(--muted);text-decoration:none;font-size:13px;display:flex;align-items:center;gap:5px;}
.topbar-left a:hover{color:var(--primary);}
.page-title{font-weight:700;font-size:16px;}
.dark-btn{background:none;border:1px solid var(--border);width:34px;height:34px;border-radius:8px;cursor:pointer;color:var(--muted);}
.content{padding:24px;max-width:1200px;margin:0 auto;}
.stat-row{display:grid;grid-template-columns:repeat(auto-fit,minmax(140px,1fr));gap:12px;margin-bottom:20px;}
.stat-box{background:var(--surface);border:1px solid var(--border);border-radius:10px;padding:16px;text-align:center;}
.stat-box .num{font-size:26px;font-weight:700;}
.stat-box .lbl{font-size:12px;color:var(--muted);}
.controls{display:flex;gap:10px;margin-bottom:14px;flex-wrap:wrap;align-items:center;}
.controls input,.controls select{padding:9px 14px;border:1px solid var(--border);border-radius:8px;background:var(--surface);color:var(--text);font-size:13px;outline:none;}
.controls input:focus{border-color:var(--primary);}
.controls input{min-width:220px;}
.table-wrap{background:var(--surface);border:1px solid var(--border);border-radius:12px;overflow:hidden;}
table{width:100%;border-collapse:collapse;}
th{padding:12px 16px;text-align:left;font-size:12px;font-weight:600;color:var(--muted);text-transform:uppercase;letter-spacing:.4px;background:var(--bg);border-bottom:1px solid var(--border);}
td{padding:14px 16px;font-size:13px;border-bottom:1px solid var(--border);vertical-align:middle;}
tbody tr:last-child td{border-bottom:none;}
tbody tr:hover{background:var(--bg);}
.user-cell{display:flex;align-items:center;gap:10px;}
.avatar{width:34px;height:34px;border-radius:50%;background:var(--primary);color:#fff;display:flex;align-items:center;justify-content:center;font-weight:700;font-size:13px;flex-shrink:0;}
.user-name{font-weight:500;}
.user-email{font-size:11px;color:var(--muted);}
.role-badge{padding:3px 10px;border-radius:999px;font-size:11px;font-weight:600;color:#fff;}
.role-ADMIN{background:#7c3aed;}
.role-STAFF{background:#2563eb;}
.status-badge{padding:3px 10px;border-radius:999px;font-size:11px;font-weight:600;}
.status-active{background:#dcfce7;color:#16a34a;}
.status-inactive{background:#fee2e2;color:#ef4444;}
.action-btn{padding:6px 12px;border:none;border-radius:6px;color:#fff;cursor:pointer;font-size:12px;font-weight:500;transition:.15s;}
.btn-edit{background:#2563eb;}
.btn-delete{background:none;border:1px solid var(--border);color:var(--danger);padding:6px 12px;border-radius:6px;cursor:pointer;font-size:12px;}
.btn-edit:hover{background:#1d4ed8;}
.btn-delete:hover{background:#fef2f2;border-color:var(--danger);}
/* CONFIRM MODAL */
.modal-overlay{position:fixed;inset:0;background:rgba(0,0,0,.5);z-index:1000;display:none;align-items:center;justify-content:center;}
.modal-overlay.open{display:flex;}
.modal{background:var(--surface);border-radius:14px;padding:28px;max-width:380px;width:90%;box-shadow:0 20px 60px rgba(0,0,0,.3);}
.modal h3{font-size:16px;font-weight:700;margin-bottom:8px;}
.modal p{font-size:13px;color:var(--muted);margin-bottom:20px;}
.modal-actions{display:flex;gap:10px;justify-content:flex-end;}
.modal-cancel{padding:8px 16px;background:var(--bg);border:1px solid var(--border);border-radius:7px;cursor:pointer;font-size:13px;font-weight:500;}
.modal-confirm{padding:8px 16px;background:var(--danger);color:#fff;border:none;border-radius:7px;cursor:pointer;font-size:13px;font-weight:500;}
</style>
</head>
<body>

<div class="topbar">
  <div class="topbar-left">
    <a href="dashboard.jsp"><i class="fa fa-arrow-left"></i> Dashboard</a>
    <span style="color:var(--border);">|</span>
    <span class="page-title">Users Management</span>
  </div>
  <button class="dark-btn" onclick="toggleDark()" style="display:none;"><i class="fa fa-moon"></i></button>
</div>

<div class="content">
  <div class="stat-row">
    <div class="stat-box"><div class="num"><%=users.size()%></div><div class="lbl">Total Users</div></div>
    <div class="stat-box"><div class="num" style="color:#16a34a;"><%=totalActive%></div><div class="lbl">Active</div></div>
    <div class="stat-box"><div class="num" style="color:#7c3aed;"><%=totalAdmin%></div><div class="lbl">Admins</div></div>
    <div class="stat-box"><div class="num" style="color:#2563eb;"><%=totalStaff%></div><div class="lbl">Staff</div></div>
  </div>

  <div class="controls">
    <input type="text" id="searchInput" placeholder="🔍 Search users..." oninput="filterUsers()">
    <select id="roleFilter" onchange="filterUsers()">
      <option value="ALL">All Roles</option>
      <option value="ADMIN">Admin</option>
      <option value="STAFF">Staff</option>
    </select>
  </div>

  <div class="table-wrap">
    <table>
      <thead>
        <tr>
          <th>#</th>
          <th>User</th>
          <th>Role</th>
          <th>Status</th>
          <th>Actions</th>
        </tr>
      </thead>
      <tbody id="userTable">
      <%
      for(User u : users){
        String status = (u.getStatus() != null) ? u.getStatus().toUpperCase() : "ACTIVE";
      %>
      <tr data-name="<%=u.getUsername().toLowerCase()%>" data-email="<%=u.getEmail().toLowerCase()%>" data-role="<%=u.getRole()%>">
        <td style="color:var(--muted);font-size:12px;">#<%=u.getId()%></td>
        <td>
          <div class="user-cell">
            <div class="avatar"><%=u.getUsername().substring(0,1).toUpperCase()%></div>
            <div>
              <div class="user-name"><%=u.getUsername()%></div>
              <div class="user-email"><%=u.getEmail()%></div>
            </div>
          </div>
        </td>
        <td><span class="role-badge role-<%=u.getRole()%>"><%=u.getRole()%></span></td>
        <td><span class="status-badge status-<%="ACTIVE".equals(status)?"active":"inactive"%>"><%=status%></span></td>
        <td>
          <a href="edit-user.jsp?id=<%=u.getId()%>"><button class="action-btn btn-edit"><i class="fa fa-pen"></i> Edit</button></a>
          <button class="btn-delete" onclick="confirmDelete(<%=u.getId()%>, '<%=u.getUsername()%>')"><i class="fa fa-trash"></i> Delete</button>
        </td>
      </tr>
      <% } %>
      </tbody>
    </table>
  </div>
</div>

<!-- CONFIRM DELETE MODAL -->
<div class="modal-overlay" id="deleteModal">
  <div class="modal">
    <h3>Delete User</h3>
    <p id="deleteMsg">Are you sure you want to delete this user? This action cannot be undone.</p>
    <div class="modal-actions">
      <button class="modal-cancel" onclick="closeModal()">Cancel</button>
      <a id="confirmDeleteLink" href="#"><button class="modal-confirm" type="button">Delete</button></a>
    </div>
  </div>
</div>

<script>
function toggleDark(){
  const h=document.documentElement,d=h.getAttribute('data-theme')==='dark';
  h.setAttribute('data-theme',d?'light':'dark');
  localStorage.setItem('sibs-theme',d?'light':'dark');
}
(function(){const t=localStorage.getItem('sibs-theme');if(t)document.documentElement.setAttribute('data-theme',t);})();

function confirmDelete(id, name){
  document.getElementById('deleteMsg').textContent='Delete user "'+name+'"? This action cannot be undone.';
  document.getElementById('confirmDeleteLink').href='deleteUser?id='+id;
  document.getElementById('deleteModal').classList.add('open');
}
function closeModal(){document.getElementById('deleteModal').classList.remove('open');}
document.getElementById('deleteModal').addEventListener('click',function(e){if(e.target===this)closeModal();});

function filterUsers(){
  const q=document.getElementById('searchInput').value.toLowerCase();
  const role=document.getElementById('roleFilter').value;
  document.querySelectorAll('#userTable tr').forEach(row=>{
    const name=row.getAttribute('data-name')||'';
    const email=row.getAttribute('data-email')||'';
    const r=row.getAttribute('data-role')||'';
    const mQ=!q||name.includes(q)||email.includes(q);
    const mR=role==='ALL'||r===role;
    row.style.display=(mQ&&mR)?'':'none';
  });
}
</script>
</body>
</html>
