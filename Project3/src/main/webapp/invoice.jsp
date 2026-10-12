<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*,com.sibs.model.User,com.sibs.util.DBConnection" %>
<%
// Standalone invoice page for customers.
// Reads directly from orders + products tables using orderId from URL.

User customer = (User) session.getAttribute("customer");
if (customer == null) { response.sendRedirect("customer-login.jsp"); return; }

String orderIdStr = request.getParameter("orderId");
if (orderIdStr == null || orderIdStr.trim().isEmpty()) {
    response.sendRedirect("my-orders.jsp"); return;
}

int orderId = Integer.parseInt(orderIdStr.trim());

// Load order + all items in the same group from DB
String ordCustomer="", ordAddress="", ordPayment="", ordStatus="", ordDate="";
double ordTotal = 0;
boolean found = false;

// We'll collect all items for this order's group
java.util.List<String[]> lineItems = new java.util.ArrayList<>(); // [productName, qty, unitPrice, lineTotal]

Connection con = null;
try {
    con = DBConnection.getConnection();

    // First get the group_id for this orderId
    int groupId = -1;
    PreparedStatement gps = con.prepareStatement("SELECT group_id, name, address, payment_method, status, order_date FROM orders WHERE id = ? AND user_id = ?");
    gps.setInt(1, orderId);
    gps.setInt(2, customer.getId());
    ResultSet grs = gps.executeQuery();
    if (grs.next()) {
        found        = true;
        groupId      = grs.getInt("group_id");
        ordCustomer  = grs.getString("name")           != null ? grs.getString("name")           : customer.getUsername();
        ordAddress   = grs.getString("address")        != null ? grs.getString("address")        : "—";
        ordPayment   = grs.getString("payment_method") != null ? grs.getString("payment_method") : "N/A";
        ordStatus    = grs.getString("status")         != null ? grs.getString("status")         : "—";
        String od    = grs.getString("order_date");
        ordDate      = (od != null && od.length() >= 10) ? od.substring(0, 10) : "—";
    }
    grs.close(); gps.close();

    if (found && groupId > 0) {
        // Load all items in this group
        PreparedStatement ps = con.prepareStatement(
            "SELECT o.quantity, o.total, p.name AS pname, p.price AS pprice " +
            "FROM orders o JOIN products p ON o.product_id = p.id " +
            "WHERE o.group_id = ? AND o.user_id = ? ORDER BY o.id ASC"
        );
        ps.setInt(1, groupId);
        ps.setInt(2, customer.getId());
        ResultSet rs = ps.executeQuery();
        while (rs.next()) {
            ordTotal += rs.getDouble("total");
            lineItems.add(new String[]{
                rs.getString("pname"),
                String.valueOf(rs.getInt("quantity")),
                String.format("%.2f", rs.getDouble("pprice")),
                String.format("%.2f", rs.getDouble("total"))
            });
        }
        rs.close(); ps.close();
    }

} catch(Exception e) {
    e.printStackTrace();
} finally {
    if (con != null) try { con.close(); } catch(Exception ignored){}
}

if (!found) { response.sendRedirect("my-orders.jsp"); return; }

// Totals breakdown
double delivery   = 40.0;
double subtotal   = ordTotal - delivery; // total stored in DB already includes delivery on first item
// Re-derive cleanly: sum of (price*qty*0.90) + 40 delivery
// Since we store discounted total per row, ordTotal = sum of discounted line totals + delivery
// Show the stored total as grand total directly
double grandTotal = ordTotal;

java.text.SimpleDateFormat sdf = new java.text.SimpleDateFormat("dd MMM yyyy");
String today = sdf.format(new java.util.Date());
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Invoice #<%=orderId%> — SIBS</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<style>
*{margin:0;padding:0;box-sizing:border-box;font-family:'Inter',sans-serif;}
body{background:#f8fafc;padding:24px;color:#0f172a;}
.invoice{max-width:700px;margin:0 auto;background:#fff;border:1px solid #e2e8f0;border-radius:12px;overflow:hidden;box-shadow:0 4px 20px rgba(0,0,0,.08);}
.inv-header{background:linear-gradient(135deg,#1e3a8a,#2563eb);color:#fff;padding:28px 32px;display:flex;justify-content:space-between;align-items:flex-start;}
.inv-brand{font-size:24px;font-weight:700;}
.inv-brand p{font-size:12px;opacity:.7;margin-top:4px;font-weight:400;}
.inv-meta{text-align:right;font-size:13px;}
.inv-meta .inv-num{font-size:18px;font-weight:700;}
.inv-meta span{opacity:.7;font-size:11px;}
.inv-body{padding:28px 32px;}
.inv-details{display:grid;grid-template-columns:1fr 1fr;gap:20px;margin-bottom:24px;padding-bottom:20px;border-bottom:1px solid #e2e8f0;}
.inv-details h4{font-size:11px;font-weight:600;color:#64748b;text-transform:uppercase;letter-spacing:.5px;margin-bottom:6px;}
.inv-details p{font-size:13px;line-height:1.6;}
table{width:100%;border-collapse:collapse;margin-bottom:20px;}
th{background:#f8fafc;padding:10px 14px;text-align:left;font-size:11px;font-weight:600;color:#64748b;text-transform:uppercase;letter-spacing:.4px;border-bottom:2px solid #e2e8f0;}
td{padding:12px 14px;font-size:13px;border-bottom:1px solid #f1f5f9;vertical-align:middle;}
td:last-child,th:last-child{text-align:right;}
.totals{display:flex;justify-content:flex-end;}
.totals-box{min-width:280px;}
.total-row{display:flex;justify-content:space-between;padding:7px 0;font-size:13px;border-bottom:1px solid #f1f5f9;}
.total-row:last-child{border-bottom:none;font-size:16px;font-weight:700;padding-top:10px;}
.discount{color:#16a34a;}
.status-badge{display:inline-block;padding:4px 12px;border-radius:99px;font-size:11px;font-weight:700;}
.status-Confirmed,.status-Delivered{background:#dcfce7;color:#15803d;}
.status-Pending{background:#fef9c3;color:#92400e;}
.status-Shipped,.status-Assigned{background:#cffafe;color:#0e7490;}
.status-Failed{background:#fee2e2;color:#b91c1c;}
.inv-footer{background:#f8fafc;padding:16px 32px;border-top:1px solid #e2e8f0;display:flex;justify-content:space-between;align-items:center;}
.inv-footer p{font-size:12px;color:#64748b;}
.print-btn,.back-btn{padding:9px 18px;border-radius:7px;cursor:pointer;font-size:13px;font-weight:600;border:none;transition:.15s;}
.print-btn{background:#0f172a;color:#fff;}
.print-btn:hover{background:#1e293b;}
.download-btn{background:#4361ee;color:#fff;padding:9px 18px;border-radius:7px;cursor:pointer;font-size:13px;font-weight:600;border:none;transition:.15s;margin-right:8px;}
.download-btn:hover{background:#3451d1;}
.back-btn{background:none;border:1px solid #e2e8f0;color:#0f172a;margin-right:8px;text-decoration:none;display:inline-block;}
.back-btn:hover{background:#f1f5f9;}
@media print{
  body{background:#fff;padding:0;}
  .invoice{box-shadow:none;border:none;}
  .inv-footer .back-btn,.inv-footer .print-btn,.inv-footer .download-btn{display:none;}
}
</style>
</head>
<body>
<div class="invoice">
  <div class="inv-header">
    <div class="inv-brand">SIBS<p>Smart Inventory &amp; Billing System</p></div>
    <div class="inv-meta">
      <div class="inv-num">Order Invoice #<%=orderId%></div>
      <span>Date: <%=today%></span>
    </div>
  </div>

  <div class="inv-body">
    <div class="inv-details">
      <div>
        <h4>Bill From</h4>
        <p><b>SIBS Store</b><br>Kurnool, Andhra Pradesh<br>India — 518001<br>support@sibs.in</p>
      </div>
      <div>
        <h4>Bill To</h4>
        <p><b><%=ordCustomer%></b><br><%=ordAddress.replace(",","<br>")%></p>
      </div>
    </div>

    <table>
      <thead>
        <tr><th>#</th><th>Product</th><th>Qty</th><th>Unit Price</th><th>Total</th></tr>
      </thead>
      <tbody>
        <% int rowNum = 1; for(String[] item : lineItems){ %>
        <tr>
          <td style="color:#94a3b8;"><%=rowNum++%></td>
          <td><%=item[0]%></td>
          <td><%=item[1]%></td>
          <td>&#8377;<%=item[2]%></td>
          <td>&#8377;<%=item[3]%></td>
        </tr>
        <% } %>
      </tbody>
    </table>

    <div class="totals">
      <div class="totals-box">
        <div class="total-row"><span>Delivery Charge</span><span>&#8377;<%=String.format("%.2f", delivery)%></span></div>
        <div class="total-row"><span><b>Grand Total</b></span><span><b>&#8377;<%=String.format("%.2f", grandTotal)%></b></span></div>
      </div>
    </div>

    <div style="margin-top:20px;padding-top:16px;border-top:1px solid #e2e8f0;display:flex;gap:24px;font-size:13px;flex-wrap:wrap;">
      <div><span style="color:#64748b;font-weight:600;">Order Date:</span> <%=ordDate%></div>
      <div><span style="color:#64748b;font-weight:600;">Payment:</span> <%=ordPayment%></div>
      <div><span style="color:#64748b;font-weight:600;">Status:</span>
        <span class="status-badge status-<%=ordStatus%>"><%=ordStatus%></span>
      </div>
    </div>
  </div>

  <div class="inv-footer">
    <p>Thank you for shopping with SIBS! 🌿</p>
    <div>
      <a class="back-btn" href="my-orders.jsp"><i class="fa fa-arrow-left"></i> Back to Orders</a>
      <button class="download-btn" onclick="downloadPDF()"><i class="fa fa-file-arrow-down"></i> Download PDF</button>
      <button class="print-btn" onclick="window.print()"><i class="fa fa-print"></i> Print</button>
    </div>
  </div>
</div>
<script>
function downloadPDF() {
  // Use print-to-PDF: set a suggested filename via document.title, then trigger print
  // The browser "Save as PDF" destination is the standard cross-browser approach
  // without any server-side dependency.
  var original = document.title;
  document.title = 'SIBS-Invoice-' + (new URLSearchParams(window.location.search).get('orderId') || 'order');
  window.print();
  document.title = original;
}
</script>
</body>
</html>
