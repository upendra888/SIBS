<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="com.sibs.model.User, com.sibs.util.AppSettings" %>
<%
User user = (User) session.getAttribute("user");
if (user == null || !"ADMIN".equals(user.getRole())) {
    response.sendRedirect("login.jsp");
    return;
}

double currentRate = AppSettings.getPerDeliveryPay();

String flash = request.getParameter("flash");
String successMsg = "";
String errorMsg = "";
if ("saved".equals(flash))   successMsg = "Settings saved successfully!";
if ("invalid".equals(flash)) errorMsg   = "Invalid amount. Please enter a valid number greater than 0.";
%>
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>App Settings — SIBS Admin</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<style>
*{margin:0;padding:0;box-sizing:border-box;font-family:'Inter',sans-serif;}
:root{
  --bg:#f8fafc;--surface:#fff;--border:#e2e8f0;
  --text:#0f172a;--muted:#64748b;
  --brand:#6366f1;--brand-light:#ede9fe;--brand-dark:#4f46e5;
  --green:#16a34a;--green-bg:#dcfce7;
  --red:#dc2626;--red-bg:#fee2e2;
  --radius:12px;--shadow:0 1px 6px rgba(0,0,0,.07);
}
[data-theme="dark"]{
  --bg:#0f172a;--surface:#1e293b;--border:#334155;
  --text:#f1f5f9;--muted:#94a3b8;
  --brand-light:#2e1f5e;
}
body{background:var(--bg);color:var(--text);min-height:100vh;}

/* TOPBAR */
.topbar{background:var(--surface);border-bottom:1px solid var(--border);
  padding:0 24px;height:60px;display:flex;align-items:center;
  justify-content:space-between;position:sticky;top:0;z-index:50;
  box-shadow:var(--shadow);}
.topbar-left{display:flex;align-items:center;gap:12px;}
.back-btn{color:var(--muted);text-decoration:none;font-size:13px;
  display:flex;align-items:center;gap:5px;padding:6px 10px;
  border:1px solid var(--border);border-radius:8px;transition:.2s;}
.back-btn:hover{color:var(--brand);border-color:var(--brand);}
.page-title{font-weight:700;font-size:16px;}

/* CONTENT */
.content{max-width:700px;margin:32px auto;padding:0 20px;}

/* FLASH */
.flash{display:flex;align-items:center;gap:10px;padding:13px 16px;
  border-radius:var(--radius);font-size:13px;font-weight:500;margin-bottom:20px;}
.flash.success{background:var(--green-bg);color:var(--green);}
.flash.error{background:var(--red-bg);color:var(--red);}

/* CARD */
.card{background:var(--surface);border:1px solid var(--border);
  border-radius:var(--radius);box-shadow:var(--shadow);overflow:hidden;margin-bottom:20px;}
.card-header{padding:18px 20px;border-bottom:1px solid var(--border);
  display:flex;align-items:center;gap:10px;}
.card-icon{width:36px;height:36px;border-radius:9px;background:var(--brand-light);
  color:var(--brand);display:flex;align-items:center;justify-content:center;font-size:15px;}
.card-title{font-weight:700;font-size:15px;}
.card-sub{font-size:12px;color:var(--muted);margin-top:2px;}
.card-body{padding:20px;}

/* FORM */
.field-label{font-size:12px;font-weight:600;color:var(--muted);
  text-transform:uppercase;letter-spacing:.04em;margin-bottom:8px;display:block;}
.input-wrap{display:flex;align-items:center;border:2px solid var(--border);
  border-radius:9px;overflow:hidden;transition:.2s;}
.input-wrap:focus-within{border-color:var(--brand);}
.input-prefix{padding:0 14px;background:var(--bg);color:var(--brand);
  font-weight:700;font-size:18px;border-right:2px solid var(--border);height:48px;
  display:flex;align-items:center;}
.rate-input{flex:1;border:none;outline:none;padding:12px 16px;
  font-size:18px;font-weight:700;background:var(--surface);color:var(--text);}
.field-hint{font-size:12px;color:var(--muted);margin-top:8px;}

.save-btn{width:100%;padding:14px;background:var(--brand);color:#fff;
  border:none;border-radius:9px;font-size:15px;font-weight:700;cursor:pointer;
  margin-top:20px;display:flex;align-items:center;justify-content:center;gap:8px;
  transition:.2s;box-shadow:0 4px 12px rgba(99,102,241,.3);}
.save-btn:hover{background:var(--brand-dark);transform:translateY(-1px);}

/* INFO BOX */
.info-box{background:var(--brand-light);border:1px solid rgba(99,102,241,.2);
  border-radius:var(--radius);padding:16px 18px;margin-bottom:20px;}
.info-box h4{font-size:13px;font-weight:700;color:var(--brand);margin-bottom:8px;}
.info-box ul{padding-left:16px;}
.info-box li{font-size:13px;color:var(--text);margin-bottom:4px;line-height:1.5;}

/* CURRENT BADGE */
.current-badge{display:inline-flex;align-items:center;gap:6px;
  background:var(--green-bg);color:var(--green);
  padding:6px 14px;border-radius:20px;font-size:13px;font-weight:700;margin-bottom:16px;}
</style>
</head>
<body>

<div class="topbar">
  <div class="topbar-left">
    <a href="dashboard.jsp" class="back-btn"><i class="fa fa-arrow-left"></i> Dashboard</a>
    <span class="page-title">⚙️ App Settings</span>
  </div>
</div>

<div class="content">

  <% if (!successMsg.isEmpty()) { %>
  <div class="flash success"><i class="fa fa-check-circle"></i> <%= successMsg %></div>
  <% } %>
  <% if (!errorMsg.isEmpty()) { %>
  <div class="flash error"><i class="fa fa-exclamation-circle"></i> <%= errorMsg %></div>
  <% } %>

  <!-- INFO -->
  <div class="info-box">
    <h4><i class="fa fa-info-circle"></i> Per Delivery Pay అంటే ఏమిటి?</h4>
    <ul>
      <li>Delivery boy ప్రతి order successfully deliver చేసినప్పుడు earn చేసే amount.</li>
      <li>ఇది COD orders కి, Online payment orders కి రెండింటికీ apply అవుతుంది.</li>
      <li>ఇక్కడ మార్చిన rate వెంటనే అన్ని calculations లో reflect అవుతుంది.</li>
      <li>Current rate: <strong>₹<%= String.format("%.0f", currentRate) %> per delivery</strong></li>
    </ul>
  </div>

  <!-- DELIVERY PAY CARD -->
  <div class="card">
    <div class="card-header">
      <div class="card-icon"><i class="fa fa-motorcycle"></i></div>
      <div>
        <div class="card-title">Per Delivery Pay Rate</div>
        <div class="card-sub">Delivery boy కి ప్రతి delivery కి ఇచ్చే salary</div>
      </div>
    </div>
    <div class="card-body">

      <div class="current-badge">
        <i class="fa fa-check-circle"></i>
        Current Rate: ₹<%= String.format("%.0f", currentRate) %> per delivery
      </div>

      <form action="appSettings" method="POST">
        <input type="hidden" name="action" value="saveDeliveryPay">

        <label class="field-label">New Per Delivery Pay (₹)</label>
        <div class="input-wrap">
          <span class="input-prefix">₹</span>
          <input type="number" name="per_delivery_pay" class="rate-input"
                 value="<%= (int)currentRate %>"
                 min="1" step="5" required placeholder="e.g. 60">
        </div>
        <div class="field-hint">
          Minimum ₹1. Recommended: ₹40 – ₹100 per delivery.
        </div>

        <button type="submit" class="save-btn">
          <i class="fa fa-save"></i> Save Settings
        </button>
      </form>
    </div>
  </div>

  <!-- SALARY EXAMPLE CARD -->
  <div class="card">
    <div class="card-header">
      <div class="card-icon" style="background:#dcfce7;color:#16a34a;"><i class="fa fa-calculator"></i></div>
      <div>
        <div class="card-title">Salary Calculation Example</div>
        <div class="card-sub">Current rate తో calculation ఎలా ఉంటుందో చూడండి</div>
      </div>
    </div>
    <div class="card-body">
      <table style="width:100%;border-collapse:collapse;font-size:13px;">
        <tr style="background:var(--bg);">
          <th style="padding:10px 12px;text-align:left;border:1px solid var(--border);font-weight:600;color:var(--muted);">Deliveries</th>
          <th style="padding:10px 12px;text-align:right;border:1px solid var(--border);font-weight:600;color:var(--muted);">Rate</th>
          <th style="padding:10px 12px;text-align:right;border:1px solid var(--border);font-weight:600;color:var(--muted);">Total Earned</th>
        </tr>
        <%
        int[] examples = {5, 10, 15, 20, 30};
        for (int ex : examples) {
            double earned = ex * currentRate;
        %>
        <tr>
          <td style="padding:10px 12px;border:1px solid var(--border);"><%= ex %> deliveries</td>
          <td style="padding:10px 12px;text-align:right;border:1px solid var(--border);">₹<%= String.format("%.0f", currentRate) %> × <%= ex %></td>
          <td style="padding:10px 12px;text-align:right;border:1px solid var(--border);font-weight:700;color:#16a34a;">₹<%= String.format("%.0f", earned) %></td>
        </tr>
        <% } %>
      </table>
    </div>
  </div>

</div><!-- /content -->

</body>
</html>
