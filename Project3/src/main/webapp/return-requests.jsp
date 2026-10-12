<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.util.*,java.sql.*,com.sibs.model.User,com.sibs.util.DBConnection" %>
<%
User user = (User) session.getAttribute("user");
if (user == null || (!"ADMIN".equals(user.getRole()) && !"STAFF".equals(user.getRole()))) {
    response.sendRedirect("login.jsp");
    return;
}

// Load all return requests with customer + order info
List<Map<String, String>> requests = new ArrayList<>();
String sql = "SELECT rr.id, rr.group_id, rr.order_id, rr.reason, rr.status AS rr_status, " +
             "       rr.admin_note, rr.requested_at, rr.refund_amount, rr.refund_method, " +
             "       u.username AS customer_name, u.email AS customer_email, " +
             "       o.payment_method, " +
             "       p.name AS product_name " +
             "FROM return_requests rr " +
             "JOIN users u    ON u.id  = rr.user_id " +
             "JOIN orders o   ON o.id  = rr.order_id " +
             "JOIN products p ON p.id  = rr.product_id " +
             "ORDER BY rr.requested_at DESC";

try (Connection con = DBConnection.getConnection();
     PreparedStatement ps = con.prepareStatement(sql);
     ResultSet rs = ps.executeQuery()) {
    while (rs.next()) {
        Map<String, String> row = new LinkedHashMap<>();
        row.put("id",             rs.getString("id"));
        row.put("groupId",        rs.getString("group_id"));
        row.put("orderId",        rs.getString("order_id"));
        row.put("reason",         rs.getString("reason"));
        row.put("rrStatus",       rs.getString("rr_status"));
        row.put("staffNote",      rs.getString("admin_note") != null ? rs.getString("admin_note") : "");
        row.put("createdAt",      rs.getString("requested_at"));
        row.put("customerName",   rs.getString("customer_name"));
        row.put("customerEmail",  rs.getString("customer_email"));
        row.put("total",          rs.getString("refund_amount"));
        row.put("paymentMethod",  rs.getString("payment_method"));
        row.put("productName",    rs.getString("product_name"));
        requests.add(row);
    }
} catch (Exception e) {
    e.printStackTrace();
}

String success   = request.getParameter("success");
String errorMsg  = request.getParameter("error");
%>
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Return Requests — SIBS</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<style>
:root{--bg:#f8fafc;--surface:#fff;--border:#e2e8f0;--text:#0f172a;--muted:#64748b;--primary:#2563eb;--success:#16a34a;--danger:#ef4444;--warn:#f59e0b;}
[data-theme="dark"]{--bg:#0f172a;--surface:#1e293b;--border:#334155;--text:#f1f5f9;--muted:#94a3b8;}
*{margin:0;padding:0;box-sizing:border-box;font-family:'Inter',sans-serif;}
body{background:var(--bg);color:var(--text);}
.topbar{background:var(--surface);border-bottom:1px solid var(--border);padding:0 24px;height:60px;display:flex;align-items:center;justify-content:space-between;position:sticky;top:0;z-index:50;}
.topbar-left{display:flex;align-items:center;gap:12px;}
.topbar-left a{color:var(--muted);text-decoration:none;font-size:13px;display:flex;align-items:center;gap:5px;}
.topbar-left a:hover{color:var(--primary);}
.page-title{font-weight:700;font-size:16px;}
.dark-btn{background:none;border:1px solid var(--border);width:34px;height:34px;border-radius:8px;cursor:pointer;color:var(--muted);}
.content{padding:24px;max-width:1200px;margin:0 auto;}
.section-title{font-size:18px;font-weight:700;margin-bottom:16px;display:flex;align-items:center;gap:8px;}
.alert{padding:12px 18px;border-radius:10px;margin-bottom:18px;font-weight:600;font-size:13px;display:flex;align-items:center;gap:8px;}
.alert.success{background:#dcfce7;color:#15803d;border:1px solid #bbf7d0;}
.alert.error{background:#fee2e2;color:#dc2626;border:1px solid #fecaca;}
.filter-row{display:flex;gap:10px;margin-bottom:14px;flex-wrap:wrap;}
.filter-row input,.filter-row select{padding:9px 14px;border:1px solid var(--border);border-radius:8px;background:var(--surface);color:var(--text);font-size:13px;outline:none;}
.filter-row input:focus{border-color:var(--primary);}
.filter-row input{min-width:220px;}
.table-wrap{background:var(--surface);border:1px solid var(--border);border-radius:12px;overflow:hidden;}
table{width:100%;border-collapse:collapse;}
th{padding:12px 16px;text-align:left;font-size:11px;font-weight:600;color:var(--muted);text-transform:uppercase;letter-spacing:.4px;background:var(--bg);border-bottom:1px solid var(--border);}
td{padding:13px 16px;font-size:13px;border-bottom:1px solid var(--border);vertical-align:middle;}
tbody tr:last-child td{border-bottom:none;}
tbody tr:hover{background:var(--bg);}
.badge{padding:4px 10px;border-radius:999px;font-size:11px;font-weight:600;color:#fff;}
.badge-pending{background:#f59e0b;}
.badge-approved{background:#16a34a;}
.badge-rejected{background:#ef4444;}
.reason-text{max-width:220px;font-size:12px;color:var(--muted);line-height:1.4;}
.action-form{display:flex;flex-direction:column;gap:6px;}
.staff-note{width:160px;padding:5px 8px;border:1px solid var(--border);border-radius:6px;font-size:12px;background:var(--surface);color:var(--text);}
.btn-approve{padding:6px 12px;background:#16a34a;border:none;border-radius:6px;color:#fff;font-size:12px;font-weight:600;cursor:pointer;}
.btn-reject{padding:6px 12px;background:#ef4444;border:none;border-radius:6px;color:#fff;font-size:12px;font-weight:600;cursor:pointer;}
.done-note{font-size:12px;color:var(--muted);font-style:italic;}
.empty{text-align:center;padding:60px 20px;color:var(--muted);}
.empty i{font-size:40px;margin-bottom:12px;display:block;}
</style>
</head>
<body>
<div class="topbar">
  <div class="topbar-left">
    <a href="staff-orders.jsp"><i class="fa fa-arrow-left"></i> Orders</a>
    <span class="page-title"><i class="fa fa-rotate-left"></i> Return Requests</span>
  </div>
  <button class="dark-btn" onclick="toggleDark()"><i class="fa fa-moon"></i></button>
</div>

<div class="content">

  <% if ("approve".equals(success)) { %>
  <div class="alert success"><i class="fa fa-check-circle"></i> Return approved. Stock has been restored.</div>
  <% } else if ("reject".equals(success)) { %>
  <div class="alert success"><i class="fa fa-check-circle"></i> Return request rejected.</div>
  <% } else if (errorMsg != null) { %>
  <div class="alert error"><i class="fa fa-circle-exclamation"></i>
    <% if ("already_processed".equals(errorMsg)) { %>This request was already processed.
    <% } else if ("not_found".equals(errorMsg)) { %>Return request not found.
    <% } else { %>Something went wrong. Please try again.<% } %>
  </div>
  <% } %>

  <div class="section-title"><i class="fa fa-rotate-left"></i> All Return Requests</div>

  <div class="filter-row">
    <input type="text" id="search" placeholder="Search customer, product, group..." oninput="applyFilters()">
    <select id="statusFilter" onchange="applyFilters()">
      <option value="All">All Statuses</option>
      <option value="Pending">Pending</option>
      <option value="Approved">Approved</option>
      <option value="Rejected">Rejected</option>
    </select>
  </div>

  <% if (requests.isEmpty()) { %>
  <div class="empty">
    <i class="fa fa-inbox"></i>
    No return requests yet.
  </div>
  <% } else { %>
  <div class="table-wrap">
    <table>
      <thead>
        <tr>
          <th>#</th>
          <th>Customer</th>
          <th>Product</th>
          <th>Group #</th>
          <th>Amount</th>
          <th>Reason</th>
          <th>Date</th>
          <th>Status</th>
          <th>Action</th>
        </tr>
      </thead>
      <tbody id="returnTable">
      <% for (Map<String, String> r : requests) {
           String rrStatus = r.get("rrStatus");
           String badgeCls = "badge-pending";
           if ("APPROVED".equalsIgnoreCase(rrStatus)) badgeCls = "badge-approved";
           else if ("REJECTED".equalsIgnoreCase(rrStatus)) badgeCls = "badge-rejected";
           else if ("PICKUP_SCHEDULED".equalsIgnoreCase(rrStatus)) badgeCls = "badge-approved";
           else if ("PICKED_UP".equalsIgnoreCase(rrStatus)) badgeCls = "badge-approved";
           else if ("REFUNDED".equalsIgnoreCase(rrStatus)) badgeCls = "badge-approved";
      %>
      <tr data-status="<%=rrStatus%>">
        <td><%=r.get("id")%></td>
        <td>
          <div style="font-weight:600;"><%=r.get("customerName")%></div>
          <div style="font-size:11px;color:var(--muted);"><%=r.get("customerEmail")%></div>
        </td>
        <td><%=r.get("productName")%></td>
        <td><span style="font-weight:600;color:var(--primary);">#<%=r.get("groupId")%></span></td>
        <td>₹<%=String.format("%.0f", Double.parseDouble(r.get("total")))%></td>
        <td><div class="reason-text"><%=r.get("reason")%></div></td>
        <td style="font-size:12px;color:var(--muted);"><%=r.get("createdAt")%></td>
        <td><span class="badge <%=badgeCls%>"><%=rrStatus%></span></td>
        <td>
          <% if ("PENDING".equalsIgnoreCase(rrStatus)) { %>
          <div class="action-form">
            <input type="text" class="staff-note" id="note-<%=r.get("id")%>" placeholder="Staff note (optional)">
            <div style="display:flex;gap:6px;">
              <form method="post" action="processReturn" style="display:inline;">
                <input type="hidden" name="returnId" value="<%=r.get("id")%>">
                <input type="hidden" name="action" value="approve">
                <input type="hidden" name="staffNote" id="approveNote-<%=r.get("id")%>" value="">
                <button class="btn-approve" type="submit"
                  onclick="document.getElementById('approveNote-<%=r.get("id")%>').value=document.getElementById('note-<%=r.get("id")%>').value;return confirm('Approve this return? Stock will be restored.');">
                  <i class="fa fa-check"></i> Approve
                </button>
              </form>
              <form method="post" action="processReturn" style="display:inline;">
                <input type="hidden" name="returnId" value="<%=r.get("id")%>">
                <input type="hidden" name="action" value="reject">
                <input type="hidden" name="staffNote" id="rejectNote-<%=r.get("id")%>" value="">
                <button class="btn-reject" type="submit"
                  onclick="document.getElementById('rejectNote-<%=r.get("id")%>').value=document.getElementById('note-<%=r.get("id")%>').value;return confirm('Reject this return request?');">
                  <i class="fa fa-xmark"></i> Reject
                </button>
              </form>
            </div>
          </div>
          <% } else { %>
          <div class="done-note">
            <% if (r.get("staffNote") != null && !r.get("staffNote").isEmpty()) { %>
              <i class="fa fa-note-sticky"></i> <%=r.get("staffNote")%>
            <% } else { %>
              — processed —
            <% } %>
          </div>
          <% } %>
        </td>
      </tr>
      <% } %>
      </tbody>
    </table>
  </div>
  <% } %>
</div>

<script>
function toggleDark(){
  const h=document.documentElement,d=h.getAttribute('data-theme')==='dark';
  h.setAttribute('data-theme',d?'light':'dark');
  localStorage.setItem('sibs-theme',d?'light':'dark');
}
(function(){const t=localStorage.getItem('sibs-theme');if(t)document.documentElement.setAttribute('data-theme',t);})();
function applyFilters(){
  const q=document.getElementById('search').value.toLowerCase();
  const s=document.getElementById('statusFilter').value;
  document.querySelectorAll('#returnTable tr').forEach(row=>{
    const text=row.textContent.toLowerCase();
    const st=row.getAttribute('data-status')||'';
    const mQ=!q||text.includes(q);
    const mS=s==='All'||st.toLowerCase()===s.toLowerCase();
    row.style.display=(mQ&&mS)?'':'none';
  });
}
</script>
</body>
</html>
