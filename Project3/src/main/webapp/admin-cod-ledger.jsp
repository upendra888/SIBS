<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.util.*,com.sibs.dao.CodLedgerDAO,com.sibs.dao.CodLedgerDAO.CodEntry,com.sibs.model.User" %>
<%
User user = (User)session.getAttribute("user");
if(user == null || (!"STAFF".equals(user.getRole()) && !"ADMIN".equals(user.getRole()))){
    response.sendRedirect("login.jsp"); return;
}

CodLedgerDAO dao = new CodLedgerDAO();
List<CodEntry> pending = dao.getAllPending();

// Get all entries for full history
String sql2 = "SELECT cl.*, db.name AS rider_name, o.name AS cname " +
              "FROM cod_ledger cl " +
              "JOIN delivery_boys db ON db.id = cl.delivery_boy_id " +
              "JOIN orders o ON o.id = cl.order_id " +
              "ORDER BY cl.collected_at DESC";
List<CodEntry> allEntries = new ArrayList<>();
double totalCollected = 0, totalRemitted = 0, totalPending = 0;

try {
    java.sql.Connection con = com.sibs.util.DBConnection.getConnection();
    java.sql.PreparedStatement ps = con.prepareStatement(sql2);
    java.sql.ResultSet rs = ps.executeQuery();
    while(rs.next()){
        CodEntry e = new CodEntry();
        e.id            = rs.getInt("id");
        e.orderId       = rs.getInt("order_id");
        e.deliveryBoyId = rs.getInt("delivery_boy_id");
        e.amount        = rs.getDouble("amount");
        e.status        = rs.getString("status");
        e.collectedAt   = rs.getString("collected_at");
        e.remittedAt    = rs.getString("remitted_at");
        e.customerName  = rs.getString("cname");
        e.note          = rs.getString("rider_name"); // reuse note field for rider name display
        if("COLLECTED".equals(e.status)) totalPending   += e.amount;
        if("REMITTED".equals(e.status))  totalRemitted  += e.amount;
        totalCollected += e.amount;
        allEntries.add(e);
    }
    rs.close(); ps.close(); con.close();
} catch(Exception ex){ ex.printStackTrace(); }
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>COD Remittance — SIBS Admin</title>
<%@ include file="includes/adminSidebar.jsp" %>
<style>
.page-header{display:flex;align-items:center;justify-content:space-between;margin-bottom:24px;}
.page-title{font-size:22px;font-weight:700;}
.summary-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:16px;margin-bottom:28px;}
.s-card{background:#fff;border:1px solid var(--border);border-radius:12px;padding:20px;text-align:center;box-shadow:var(--shadow);}
.s-label{font-size:12px;color:var(--muted);text-transform:uppercase;letter-spacing:.5px;margin-bottom:8px;}
.s-value{font-size:28px;font-weight:700;}
.card{background:#fff;border:1px solid var(--border);border-radius:12px;box-shadow:var(--shadow);overflow:hidden;}
.card-header{padding:16px 20px;border-bottom:1px solid var(--border);font-weight:600;font-size:15px;display:flex;align-items:center;gap:8px;}
table{width:100%;border-collapse:collapse;}
th{padding:11px 16px;text-align:left;font-size:11px;font-weight:600;color:var(--muted);text-transform:uppercase;letter-spacing:.4px;background:#f8fafc;border-bottom:1px solid var(--border);}
td{padding:13px 16px;font-size:13px;border-bottom:1px solid var(--border);}
tbody tr:last-child td{border-bottom:none;}
tbody tr:hover{background:#f8fafc;}
.badge{padding:3px 10px;border-radius:999px;font-size:11px;font-weight:600;}
.b-collected{background:#fef3c7;color:#b45309;}
.b-remitted{background:#dcfce7;color:#16a34a;}
.empty{text-align:center;padding:48px;color:var(--muted);}
</style>
</head>
<body>
<div class="content-area">
  <div class="page-header">
    <div class="page-title"><i class="fa fa-money-bill-wave" style="color:#16a34a;"></i> COD Remittance Tracker</div>
  </div>

  <div class="summary-grid">
    <div class="s-card">
      <div class="s-label">Total Collected</div>
      <div class="s-value" style="color:#1d4ed8;">₹<%=String.format("%.0f",totalCollected)%></div>
    </div>
    <div class="s-card">
      <div class="s-label">Pending (Not Remitted)</div>
      <div class="s-value" style="color:#b45309;">₹<%=String.format("%.0f",totalPending)%></div>
    </div>
    <div class="s-card">
      <div class="s-label">Total Remitted</div>
      <div class="s-value" style="color:#16a34a;">₹<%=String.format("%.0f",totalRemitted)%></div>
    </div>
  </div>

  <div class="card">
    <div class="card-header"><i class="fa fa-list"></i> All COD Transactions</div>
    <% if(allEntries.isEmpty()){ %>
      <div class="empty"><i class="fa fa-coins" style="font-size:36px;opacity:.2;display:block;margin-bottom:10px;"></i>No COD entries yet.</div>
    <% } else { %>
    <table>
      <thead>
        <tr>
          <th>#</th>
          <th>Order</th>
          <th>Customer</th>
          <th>Rider</th>
          <th>Amount</th>
          <th>Status</th>
          <th>Collected At</th>
          <th>Remitted At</th>
          <th>Note</th>
        </tr>
      </thead>
      <tbody>
      <% for(CodEntry e : allEntries){ %>
        <tr>
          <td style="color:var(--muted);"><%=e.id%></td>
          <td><strong>#<%=e.orderId%></strong></td>
          <td><%=e.customerName!=null?e.customerName:"–"%></td>
          <td><%=e.note!=null?e.note:"–"%></td>
          <td style="font-weight:700;">₹<%=String.format("%.0f",e.amount)%></td>
          <td><span class="badge <%="COLLECTED".equals(e.status)?"b-collected":"b-remitted"%>"><%=e.status%></span></td>
          <td style="color:var(--muted);font-size:12px;"><%=e.collectedAt!=null?e.collectedAt.substring(0,16):"–"%></td>
          <td style="color:var(--muted);font-size:12px;"><%=e.remittedAt!=null?e.remittedAt.substring(0,16):"–"%></td>
          <td style="color:var(--muted);font-size:12px;"><%=e.remittedAt!=null&&e.note!=null?"":e.note!=null?"":""  %>&nbsp;</td>
        </tr>
      <% } %>
      </tbody>
    </table>
    <% } %>
  </div>
</div>
</body>
</html>
