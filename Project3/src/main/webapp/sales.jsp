<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.util.*,java.sql.*,com.sibs.model.User,com.sibs.util.DBConnection" %>
<%
User user = (User) session.getAttribute("user");
if (user == null || !"ADMIN".equals(user.getRole())) {
    response.sendRedirect("login.jsp"); return;
}

// ── All report data pulled directly via SQL ──────────────────
// ✅ FIXED: Connection is now wrapped in try-finally so it always closes.
//           Previously if any query threw an exception the connection leaked
//           and the page showed a blank/error screen.

int totalOrders=0, confirmedOrders=0, pendingOrders=0, failedOrders=0;
double totalRevenue=0;
Map<String,Integer> paymentMethodMap = new LinkedHashMap<>();
List<String>  topProductNames = new ArrayList<>();
List<Integer> topProductQtys  = new ArrayList<>();
List<Double>  topProductRevs  = new ArrayList<>();
List<String>  dayLabels       = new ArrayList<>();
List<Double>  dayRevenues     = new ArrayList<>();
List<String>  lowStockNames   = new ArrayList<>();
List<Integer> lowStockQtys    = new ArrayList<>();
List<String[]> recentOrders   = new ArrayList<>();

Connection con = null;
try {
    con = DBConnection.getConnection();
    PreparedStatement ps;
    ResultSet rs;

    // 1. Summary stats
    ps = con.prepareStatement(
        "SELECT COUNT(*) AS total, " +
        "SUM(CASE WHEN status='Confirmed' OR payment_status='PAID' THEN 1 ELSE 0 END) AS confirmed, " +
        "SUM(CASE WHEN status='Pending' THEN 1 ELSE 0 END) AS pending, " +
        "SUM(CASE WHEN status='Failed' THEN 1 ELSE 0 END) AS failed, " +
        "SUM(CASE WHEN payment_status='PAID' THEN total ELSE 0 END) AS revenue " +
        "FROM orders");
    rs = ps.executeQuery();
    if(rs.next()){
        totalOrders     = rs.getInt("total");
        confirmedOrders = rs.getInt("confirmed");
        pendingOrders   = rs.getInt("pending");
        failedOrders    = rs.getInt("failed");
        totalRevenue    = rs.getDouble("revenue");
    }
    rs.close(); ps.close();

    // 2. Orders by payment method
    ps = con.prepareStatement(
        "SELECT payment_method, COUNT(*) AS cnt FROM orders GROUP BY payment_method ORDER BY cnt DESC");
    rs = ps.executeQuery();
    while(rs.next()) paymentMethodMap.put(rs.getString("payment_method"), rs.getInt("cnt"));
    rs.close(); ps.close();

    // 3. Top 5 selling products
    ps = con.prepareStatement(
        "SELECT p.name, SUM(o.quantity) AS total_qty, SUM(o.total) AS total_rev " +
        "FROM orders o JOIN products p ON o.product_id=p.id " +
        "WHERE o.status='Confirmed' OR o.payment_status='PAID' " +
        "GROUP BY p.name ORDER BY total_qty DESC LIMIT 5");
    rs = ps.executeQuery();
    while(rs.next()){
        topProductNames.add(rs.getString("name"));
        topProductQtys.add(rs.getInt("total_qty"));
        topProductRevs.add(rs.getDouble("total_rev"));
    }
    rs.close(); ps.close();

    // 4. Revenue last 7 days
    ps = con.prepareStatement(
        "SELECT DATE(order_date) AS day, SUM(total) AS rev " +
        "FROM orders WHERE payment_status='PAID' " +
        "AND order_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY) " +
        "GROUP BY DATE(order_date) ORDER BY day ASC");
    rs = ps.executeQuery();
    while(rs.next()){
        dayLabels.add(rs.getString("day"));
        dayRevenues.add(rs.getDouble("rev"));
    }
    rs.close(); ps.close();

    // 5. Low stock products
    ps = con.prepareStatement(
        "SELECT name, quantity FROM products WHERE quantity <= 10 ORDER BY quantity ASC LIMIT 8");
    rs = ps.executeQuery();
    while(rs.next()){
        lowStockNames.add(rs.getString("name"));
        lowStockQtys.add(rs.getInt("quantity"));
    }
    rs.close(); ps.close();

    // 6. Recent 5 orders
    ps = con.prepareStatement(
        "SELECT o.id, o.name, p.name AS pname, o.total, o.status, o.order_date " +
        "FROM orders o JOIN products p ON o.product_id=p.id " +
        "ORDER BY o.id DESC LIMIT 5");
    rs = ps.executeQuery();
    while(rs.next()){
        recentOrders.add(new String[]{
            rs.getString("id"), rs.getString("name"), rs.getString("pname"),
            String.valueOf((int)rs.getDouble("total")), rs.getString("status"),
            rs.getString("order_date") != null ? rs.getString("order_date").substring(0,10) : "—"
        });
    }
    rs.close(); ps.close();

} catch(Exception e) {
    e.printStackTrace();
} finally {
    // ✅ FIXED: Always close connection, even if an exception occurred
    if(con != null) try { con.close(); } catch(Exception ignored){}
}

// Build JS arrays
StringBuilder jsLabels = new StringBuilder("[");
StringBuilder jsRevs   = new StringBuilder("[");
for(int i=0;i<dayLabels.size();i++){
    jsLabels.append("'").append(dayLabels.get(i)).append("'");
    jsRevs.append(dayRevenues.get(i).intValue());
    if(i<dayLabels.size()-1){jsLabels.append(",");jsRevs.append(",");}
}
jsLabels.append("]"); jsRevs.append("]");

StringBuilder jsProdLabels = new StringBuilder("[");
StringBuilder jsProdQtys   = new StringBuilder("[");
for(int i=0;i<topProductNames.size();i++){
    jsProdLabels.append("'").append(topProductNames.get(i).replace("'","\\'")).append("'");
    jsProdQtys.append(topProductQtys.get(i));
    if(i<topProductNames.size()-1){jsProdLabels.append(",");jsProdQtys.append(",");}
}
jsProdLabels.append("]"); jsProdQtys.append("]");

StringBuilder jsPayLabels = new StringBuilder("[");
StringBuilder jsPayVals   = new StringBuilder("[");
int pi=0;
for(Map.Entry<String,Integer> e : paymentMethodMap.entrySet()){
    jsPayLabels.append("'").append(e.getKey()).append("'");
    jsPayVals.append(e.getValue());
    if(pi<paymentMethodMap.size()-1){jsPayLabels.append(",");jsPayVals.append(",");}
    pi++;
}
jsPayLabels.append("]"); jsPayVals.append("]");
%>
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Reports — SIBS</title>
<link href="https://fonts.googleapis.com/css2?family=Syne:wght@600;700;800&family=Nunito:wght@400;500;600;700&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/4.4.1/chart.umd.min.js"></script>
<style>
:root{
  --bg:#f4f7ff;--surface:#fff;--border:#e4eaff;--text:#0d1321;--muted:#6b7a99;
  --primary:#3a5bef;--primary-dark:#2a47d4;--primary-light:#eef1ff;
  --success:#16a34a;--danger:#ef4444;--warn:#f59e0b;--purple:#7c3aed;
}
[data-theme="dark"]{
  --bg:#0d1017;--surface:#141b2d;--border:#1e2a45;--text:#e8eeff;--muted:#5a6a8a;
  --primary:#5878f5;--primary-light:#1a2040;
}
*{margin:0;padding:0;box-sizing:border-box;}
body{font-family:'Nunito',sans-serif;background:var(--bg);color:var(--text);min-height:100vh;}

.topbar{background:var(--surface);border-bottom:1px solid var(--border);
  height:58px;display:flex;align-items:center;justify-content:space-between;
  padding:0 24px;position:sticky;top:0;z-index:50;}
.topbar-left{display:flex;align-items:center;gap:12px;}
.topbar-left a{color:var(--muted);text-decoration:none;font-size:13px;display:flex;align-items:center;gap:5px;}
.topbar-left a:hover{color:var(--primary);}
.page-title{font-family:'Syne',sans-serif;font-weight:700;font-size:16px;}
.dark-btn{background:none;border:1px solid var(--border);width:34px;height:34px;
  border-radius:8px;cursor:pointer;color:var(--muted);font-size:13px;
  display:flex;align-items:center;justify-content:center;}

.content{padding:24px;max-width:1300px;margin:0 auto;}

.stats-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(200px,1fr));gap:16px;margin-bottom:24px;}
.stat-card{background:var(--surface);border:1.5px solid var(--border);border-radius:14px;
  padding:20px;position:relative;overflow:hidden;}
.stat-card::before{content:'';position:absolute;right:-20px;top:-20px;
  width:80px;height:80px;border-radius:50%;opacity:.08;}
.stat-card.blue::before{background:#3a5bef;}
.stat-card.green::before{background:#16a34a;}
.stat-card.orange::before{background:#f59e0b;}
.stat-card.red::before{background:#ef4444;}
.stat-card.purple::before{background:#7c3aed;}
.stat-icon{width:40px;height:40px;border-radius:10px;display:flex;align-items:center;
  justify-content:center;font-size:16px;margin-bottom:12px;}
.stat-card.blue .stat-icon{background:#eef1ff;color:#3a5bef;}
.stat-card.green .stat-icon{background:#f0fdf4;color:#16a34a;}
.stat-card.orange .stat-icon{background:#fff7ed;color:#f59e0b;}
.stat-card.red .stat-icon{background:#fef2f2;color:#ef4444;}
.stat-card.purple .stat-icon{background:#f5f3ff;color:#7c3aed;}
.stat-val{font-family:'Syne',sans-serif;font-size:26px;font-weight:800;margin-bottom:2px;}
.stat-label{font-size:12px;color:var(--muted);font-weight:600;}

.charts-grid{display:grid;grid-template-columns:2fr 1fr;gap:16px;margin-bottom:24px;}
@media(max-width:900px){.charts-grid{grid-template-columns:1fr;}}
.chart-card{background:var(--surface);border:1.5px solid var(--border);border-radius:14px;padding:20px;}
.card-title{font-family:'Syne',sans-serif;font-weight:700;font-size:14px;margin-bottom:16px;
  display:flex;align-items:center;gap:8px;}
.card-title i{color:var(--primary);}

.bottom-grid{display:grid;grid-template-columns:1fr 1fr 1fr;gap:16px;}
@media(max-width:1100px){.bottom-grid{grid-template-columns:1fr 1fr;}}
@media(max-width:700px){.bottom-grid{grid-template-columns:1fr;}}

.stock-item{display:flex;align-items:center;justify-content:space-between;
  padding:9px 0;border-bottom:1px solid var(--border);font-size:13px;}
.stock-item:last-child{border-bottom:none;}
.stock-bar-wrap{flex:1;margin:0 12px;height:6px;background:var(--bg);border-radius:99px;overflow:hidden;}
.stock-bar{height:100%;border-radius:99px;transition:.3s;}
.stock-qty{font-weight:700;font-size:12px;min-width:24px;text-align:right;}

.mini-table{width:100%;border-collapse:collapse;font-size:12px;}
.mini-table th{padding:7px 8px;text-align:left;color:var(--muted);font-weight:600;
  text-transform:uppercase;font-size:10px;letter-spacing:.4px;border-bottom:1px solid var(--border);}
.mini-table td{padding:9px 8px;border-bottom:1px solid var(--border);vertical-align:middle;}
.mini-table tr:last-child td{border-bottom:none;}
.badge{padding:3px 8px;border-radius:99px;font-size:10px;font-weight:700;color:#fff;}
.Confirmed,.Delivered{background:#16a34a;}
.Pending{background:#f59e0b;}
.Failed,.Rejected{background:#ef4444;}
.Packed{background:#7c3aed;}
.Shipped{background:#2563eb;}

.no-data{text-align:center;padding:28px;color:var(--muted);font-size:13px;}
.no-data i{font-size:28px;display:block;margin-bottom:8px;opacity:.35;}
</style>
</head>
<body>

<div class="topbar">
  <div class="topbar-left">
    <a href="dashboard.jsp"><i class="fa fa-arrow-left"></i> Dashboard</a>
    <span style="color:var(--border);">|</span>
    <span class="page-title"><i class="fa fa-chart-bar" style="color:var(--primary);margin-right:6px;"></i>Reports</span>
  </div>
  <button class="dark-btn" onclick="toggleDark()"><i class="fa fa-moon"></i></button>
</div>

<div class="content">

  <!-- Stat Cards -->
  <div class="stats-grid">
    <div class="stat-card blue">
      <div class="stat-icon"><i class="fa fa-bag-shopping"></i></div>
      <div class="stat-val"><%=totalOrders%></div>
      <div class="stat-label">Total Orders</div>
    </div>
    <div class="stat-card green">
      <div class="stat-icon"><i class="fa fa-circle-check"></i></div>
      <div class="stat-val"><%=confirmedOrders%></div>
      <div class="stat-label">Confirmed Orders</div>
    </div>
    <div class="stat-card orange">
      <div class="stat-icon"><i class="fa fa-clock"></i></div>
      <div class="stat-val"><%=pendingOrders%></div>
      <div class="stat-label">Pending Orders</div>
    </div>
    <div class="stat-card red">
      <div class="stat-icon"><i class="fa fa-xmark"></i></div>
      <div class="stat-val"><%=failedOrders%></div>
      <div class="stat-label">Failed Payments</div>
    </div>
    <div class="stat-card purple">
      <div class="stat-icon"><i class="fa fa-indian-rupee-sign"></i></div>
      <div class="stat-val">&#8377;<%=(int)totalRevenue%></div>
      <div class="stat-label">Total Revenue</div>
    </div>
  </div>

  <!-- Charts Row -->
  <div class="charts-grid">
    <div class="chart-card">
      <div class="card-title"><i class="fa fa-chart-line"></i> Revenue — Last 7 Days</div>
      <% if(dayLabels.isEmpty()){ %>
        <div class="no-data"><i class="fa fa-chart-line"></i>No payment data yet</div>
      <% } else { %>
        <canvas id="revenueChart" height="100"></canvas>
      <% } %>
    </div>
    <div class="chart-card">
      <div class="card-title"><i class="fa fa-credit-card"></i> Payment Methods</div>
      <% if(paymentMethodMap.isEmpty()){ %>
        <div class="no-data"><i class="fa fa-credit-card"></i>No data yet</div>
      <% } else { %>
        <canvas id="payChart" height="180"></canvas>
      <% } %>
    </div>
  </div>

  <!-- Bottom Row -->
  <div class="bottom-grid">

    <div class="chart-card">
      <div class="card-title"><i class="fa fa-trophy"></i> Top Products (by qty sold)</div>
      <% if(topProductNames.isEmpty()){ %>
        <div class="no-data"><i class="fa fa-trophy"></i>No confirmed orders yet</div>
      <% } else { %>
        <canvas id="prodChart" height="200"></canvas>
      <% } %>
    </div>

    <div class="chart-card">
      <div class="card-title"><i class="fa fa-triangle-exclamation"></i> Low Stock Alert</div>
      <% if(lowStockNames.isEmpty()){ %>
        <div class="no-data"><i class="fa fa-boxes-stacked"></i>All stock levels are fine</div>
      <% } else { %>
        <% for(int i=0;i<lowStockNames.size();i++){
             int qty = lowStockQtys.get(i);
             int pct = Math.min(100, qty * 10);
             String barColor = qty <= 3 ? "#ef4444" : qty <= 6 ? "#f59e0b" : "#16a34a";
        %>
        <div class="stock-item">
          <span style="font-weight:600;flex:0 0 120px;font-size:12px;"><%=lowStockNames.get(i)%></span>
          <div class="stock-bar-wrap">
            <div class="stock-bar" style="width:<%=pct%>%;background:<%=barColor%>;"></div>
          </div>
          <span class="stock-qty" style="color:<%=barColor%>;"><%=qty%></span>
        </div>
        <% } %>
      <% } %>
    </div>

    <div class="chart-card">
      <div class="card-title"><i class="fa fa-clock-rotate-left"></i> Recent Orders</div>
      <% if(recentOrders.isEmpty()){ %>
        <div class="no-data"><i class="fa fa-bag-shopping"></i>No orders yet</div>
      <% } else { %>
        <table class="mini-table">
          <thead><tr><th>#</th><th>Customer</th><th>Product</th><th>Total</th><th>Status</th></tr></thead>
          <tbody>
          <% for(String[] o : recentOrders){ %>
            <tr>
              <td style="color:var(--muted);"><%=o[0]%></td>
              <td style="font-weight:600;"><%=o[1]%></td>
              <td><%=o[2]%></td>
              <td><b>&#8377;<%=o[3]%></b></td>
              <td><span class="badge <%=o[4]!=null?o[4].replace(" ",""):"Pending"%>"><%=o[4]!=null?o[4]:"Pending"%></span></td>
            </tr>
          <% } %>
          </tbody>
        </table>
      <% } %>
    </div>

  </div>
</div>

<script>
<% if(!dayLabels.isEmpty()){ %>
new Chart(document.getElementById('revenueChart'), {
  type: 'line',
  data: {
    labels: <%=jsLabels%>,
    datasets:[{
      label: 'Revenue (₹)',
      data: <%=jsRevs%>,
      borderColor: '#3a5bef',
      backgroundColor: 'rgba(58,91,239,.1)',
      borderWidth: 2.5,
      pointBackgroundColor: '#3a5bef',
      pointRadius: 4,
      tension: 0.4,
      fill: true
    }]
  },
  options:{responsive:true,plugins:{legend:{display:false}},
    scales:{y:{beginAtZero:true,ticks:{callback:v=>'₹'+v}},x:{grid:{display:false}}}}
});
<% } %>

<% if(!paymentMethodMap.isEmpty()){ %>
new Chart(document.getElementById('payChart'), {
  type: 'doughnut',
  data: {
    labels: <%=jsPayLabels%>,
    datasets:[{
      data: <%=jsPayVals%>,
      backgroundColor:['#3a5bef','#16a34a','#f59e0b','#ef4444','#7c3aed'],
      borderWidth: 2,
      borderColor: 'var(--surface)'
    }]
  },
  options:{responsive:true,plugins:{legend:{position:'bottom',labels:{font:{size:11}}}}}
});
<% } %>

<% if(!topProductNames.isEmpty()){ %>
new Chart(document.getElementById('prodChart'), {
  type: 'bar',
  data: {
    labels: <%=jsProdLabels%>,
    datasets:[{
      label: 'Qty Sold',
      data: <%=jsProdQtys%>,
      backgroundColor:['#3a5bef','#16a34a','#f59e0b','#ef4444','#7c3aed'],
      borderRadius: 6
    }]
  },
  options:{responsive:true,plugins:{legend:{display:false}},
    scales:{y:{beginAtZero:true,ticks:{stepSize:1}},x:{grid:{display:false}}}}
});
<% } %>

function toggleDark(){
  var h=document.documentElement,d=h.getAttribute('data-theme')==='dark';
  h.setAttribute('data-theme',d?'light':'dark');
  localStorage.setItem('sibs-theme',d?'light':'dark');
}
(function(){var t=localStorage.getItem('sibs-theme');if(t)document.documentElement.setAttribute('data-theme',t);})();
</script>
</body>
</html>
