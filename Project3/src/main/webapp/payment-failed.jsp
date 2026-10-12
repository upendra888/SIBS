<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="com.sibs.model.User" %>
<%@ page import="java.sql.*,com.sibs.util.DBConnection" %>
<%
User user = (User)session.getAttribute("customer");
String error  = request.getParameter("error");
String reason = "Your payment could not be completed.";

if("missing_params".equals(error))      reason = "Payment session expired. Please try again.";
if("signature_mismatch".equals(error))  reason = "Payment verification failed. If money was debited, it will be refunded within 5–7 business days.";
if("db_update_failed".equals(error))    reason = "Payment received but order update failed. Please contact support immediately with your transaction ID.";
if("cancelled".equals(error))           reason = "Payment was cancelled by you.";
if("server_error".equals(error))        reason = "A server error occurred. Please try again or contact support.";
if("payment_failed".equals(error))      reason = "Payment was declined by your bank or UPI. Please try a different payment method.";
if("network".equals(error))             reason = "Network error during payment verification. Please check My Orders before retrying.";

// fetch user details for pre-filled WhatsApp message
String username = (user != null) ? user.getUsername() : "Customer";
String userId   = (user != null) ? String.valueOf(user.getId()) : "N/A";

Object oidObj = session.getAttribute("pendingOrderId");
String orderId = (oidObj != null) ? oidObj.toString() : "N/A";

// WhatsApp message pre-filled for staff
String waMsg = java.net.URLEncoder.encode(
    "Hi SIBS Support,\n" +
    "My payment failed. Please help me.\n\n" +
    "Name: " + username + "\n" +
    "User ID: " + userId + "\n" +
    "Order ID: " + orderId + "\n" +
    "Error: " + error + "\n" +
    "Reason: " + reason,
    "UTF-8"
);
%>
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Payment Failed — SIBS</title>
<link href="https://fonts.googleapis.com/css2?family=Syne:wght@400;600;700;800&family=DM+Sans:wght@400;500;600&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<style>
:root {
  --bg: #fdf3f3;
  --surface: #ffffff;
  --border: #fde8e8;
  --text: #1a0a0a;
  --muted: #9b7474;
  --danger: #e53e3e;
  --danger-light: #fff5f5;
  --danger-dark: #c53030;
  --primary: #2b6cb0;
  --green: #276749;
  --green-bg: #f0fff4;
  --green-border: #c6f6d5;
  --orange: #c05621;
  --orange-bg: #fffaf0;
  --orange-border: #fbd38d;
  --purple: #553c9a;
  --surface2: #fdf3f3;
}
[data-theme="dark"] {
  --bg: #130a0a;
  --surface: #1e0f0f;
  --border: #3d1515;
  --text: #fef2f2;
  --muted: #9b7474;
  --danger-light: #2d1212;
  --green-bg: #0d2018;
  --green-border: #1a4731;
  --orange-bg: #1f1208;
  --orange-border: #6b3a1a;
  --surface2: #1a0f0f;
}
* { margin: 0; padding: 0; box-sizing: border-box; }
body {
  font-family: 'DM Sans', sans-serif;
  background: var(--bg);
  color: var(--text);
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 24px 16px;
}

/* Top bar */
.topbar {
  position: fixed; top: 0; left: 0; right: 0;
  height: 52px;
  background: var(--surface);
  border-bottom: 1px solid var(--border);
  display: flex; align-items: center; justify-content: space-between;
  padding: 0 20px; z-index: 50;
}
.brand { font-family: 'Syne', sans-serif; font-weight: 800; font-size: 17px; color: var(--danger); display: flex; align-items: center; gap: 8px; }
.dark-btn { background: none; border: 1px solid var(--border); width: 34px; height: 34px; border-radius: 8px; cursor: pointer; color: var(--muted); font-size: 13px; display: flex; align-items: center; justify-content: center; }

.page { margin-top: 52px; width: 100%; max-width: 480px; padding: 32px 0 60px; }

/* --- Main card --- */
.card {
  background: var(--surface);
  border: 1.5px solid var(--border);
  border-radius: 20px;
  overflow: hidden;
  box-shadow: 0 12px 60px rgba(220,38,38,.08);
}

/* Header */
.fail-hdr {
  background: linear-gradient(135deg, #9b2c2c 0%, #e53e3e 100%);
  padding: 36px 28px 32px;
  text-align: center;
  position: relative;
  overflow: hidden;
}
.fail-hdr::before {
  content: '';
  position: absolute; inset: 0;
  background: radial-gradient(circle at 20% 80%, rgba(255,255,255,.08) 0%, transparent 60%);
}
.x-wrap {
  width: 76px; height: 76px;
  margin: 0 auto 16px;
  position: relative;
}
.x-circle {
  width: 76px; height: 76px;
  border-radius: 50%;
  background: rgba(255,255,255,.15);
  border: 2px solid rgba(255,255,255,.4);
  display: flex; align-items: center; justify-content: center;
  animation: popIn .5s cubic-bezier(.34,1.56,.64,1);
}
@keyframes popIn { 0%{transform:scale(0);opacity:0;} 60%{transform:scale(1.1);} 100%{transform:scale(1);opacity:1;} }
.x-circle i { font-size: 30px; color: #fff; }
.x-ring {
  position: absolute; inset: -6px;
  border-radius: 50%;
  border: 3px solid rgba(255,255,255,.25);
  animation: ringPulse 2s ease infinite;
}
@keyframes ringPulse { 0%,100%{transform:scale(1);opacity:.7;} 50%{transform:scale(1.08);opacity:.2;} }
.fail-hdr h2 { font-family: 'Syne', sans-serif; font-size: 22px; font-weight: 800; color: #fff; margin-bottom: 6px; position: relative; }
.fail-hdr p { font-size: 13px; color: rgba(255,255,255,.75); position: relative; }

/* Body */
.body { padding: 24px; display: flex; flex-direction: column; gap: 16px; }

/* Error reason box */
.reason-box {
  background: var(--danger-light);
  border: 1.5px solid #fecaca;
  border-radius: 12px;
  padding: 14px 16px;
  display: flex; gap: 12px; align-items: flex-start;
  font-size: 13px; color: var(--danger);
}
.reason-box i { margin-top: 2px; flex-shrink: 0; }

/* Staff contact card */
.staff-card {
  background: var(--orange-bg);
  border: 1.5px solid var(--orange-border);
  border-radius: 14px;
  overflow: hidden;
}
.staff-header {
  background: linear-gradient(90deg, #c05621, #dd6b20);
  padding: 10px 16px;
  display: flex; align-items: center; gap: 8px;
  font-family: 'Syne', sans-serif;
  font-weight: 700; font-size: 12px;
  color: #fff; letter-spacing: .5px;
  text-transform: uppercase;
}
.staff-body { padding: 16px; display: flex; flex-direction: column; gap: 10px; }
.staff-intro { font-size: 12.5px; color: var(--orange); line-height: 1.6; font-weight: 500; }

.contact-row {
  display: flex; align-items: center; gap: 12px;
  padding: 10px 12px;
  background: var(--surface);
  border: 1px solid var(--orange-border);
  border-radius: 10px;
  text-decoration: none;
  color: var(--text);
  transition: .15s;
}
.contact-row:hover { border-color: #dd6b20; background: var(--orange-bg); }
.contact-icon {
  width: 36px; height: 36px;
  border-radius: 9px;
  display: flex; align-items: center; justify-content: center;
  font-size: 16px; flex-shrink: 0;
}
.icon-wa  { background: #dcfce7; color: #16a34a; }
.icon-ph  { background: #dbeafe; color: #1d4ed8; }
.icon-mail{ background: #ede9fe; color: #7c3aed; }
.contact-info { flex: 1; }
.contact-label { font-size: 10px; color: var(--muted); font-weight: 600; text-transform: uppercase; letter-spacing: .4px; }
.contact-value { font-size: 13px; font-weight: 600; margin-top: 1px; }

/* Order ID chip */
.order-chip {
  display: flex; align-items: center; justify-content: space-between;
  background: var(--surface2);
  border: 1px solid var(--border);
  border-radius: 10px;
  padding: 10px 14px;
  font-size: 12px;
}
.order-chip span:first-child { color: var(--muted); font-weight: 500; }
.order-chip span:last-child { font-weight: 700; font-size: 13px; }

/* Actions */
.actions { display: flex; flex-direction: column; gap: 10px; }
.btn {
  padding: 13px;
  border-radius: 11px;
  cursor: pointer;
  font-family: 'Syne', sans-serif;
  font-weight: 700; font-size: 13px;
  display: flex; align-items: center; justify-content: center; gap: 8px;
  text-decoration: none; border: none; transition: .15s;
}
.btn-danger  { background: var(--danger); color: #fff; }
.btn-danger:hover { background: var(--danger-dark); }
.btn-outline { background: none; border: 1.5px solid var(--border); color: var(--text); }
.btn-outline:hover { border-color: var(--primary); color: var(--primary); }

/* Divider */
.divider { display: flex; align-items: center; gap: 10px; color: var(--muted); font-size: 11px; font-weight: 600; text-transform: uppercase; letter-spacing: .5px; }
.divider::before, .divider::after { content: ''; flex: 1; height: 1px; background: var(--border); }
</style>
</head>
<body>

<div class="topbar">
  <div class="brand"><i class="fa fa-cubes"></i> SIBS</div>
  <button class="dark-btn" onclick="toggleDark()"><i class="fa fa-moon"></i></button>
</div>

<div class="page">
<div class="card">

  <!-- Header -->
  <div class="fail-hdr">
    <div class="x-wrap">
      <div class="x-circle"><i class="fa fa-xmark"></i></div>
      <div class="x-ring"></div>
    </div>
    <h2>Payment Failed</h2>
    <p>Don't worry — no money has been charged.</p>
  </div>

  <div class="body">

    <!-- Error reason -->
    <div class="reason-box">
      <i class="fa fa-triangle-exclamation"></i>
      <span><%=reason%></span>
    </div>

    <!-- Order reference -->
    <% if(!"N/A".equals(orderId)) { %>
    <div class="order-chip">
      <span><i class="fa fa-hashtag"></i> Order Reference</span>
      <span>#<%=orderId%></span>
    </div>
    <% } %>

    <!-- Retry button -->
    <div class="actions">
      <a class="btn btn-danger" href="cartCheckout.jsp">
        <i class="fa fa-rotate-right"></i> Try Again
      </a>
    </div>

    <div class="divider">Need Help?</div>

    <!-- Staff Contact Section -->
    <div class="staff-card">
      <div class="staff-header">
        <i class="fa fa-headset"></i>
        Contact Our Support Staff
      </div>
      <div class="staff-body">
        <p class="staff-intro">
          If money was deducted from your account or you need immediate help,
          please reach out to our support team directly.
        </p>

        <!-- WhatsApp -->
        <a class="contact-row"
           href="https://wa.me/918866567440?text=<%=waMsg%>"
           target="_blank">
          <div class="contact-icon icon-wa"><i class="fa-brands fa-whatsapp"></i></div>
          <div class="contact-info">
            <div class="contact-label">WhatsApp (Fastest)</div>
            <div class="contact-value">+91 88665 67440</div>
          </div>
          <i class="fa fa-arrow-up-right-from-square" style="color:var(--muted);font-size:11px;"></i>
        </a>

        <!-- Phone -->
        <a class="contact-row" href="tel:+918866567440">
          <div class="contact-icon icon-ph"><i class="fa fa-phone"></i></div>
          <div class="contact-info">
            <div class="contact-label">Call Us</div>
            <div class="contact-value">+91 88665 67440</div>
          </div>
          <i class="fa fa-arrow-up-right-from-square" style="color:var(--muted);font-size:11px;"></i>
        </a>

        <!-- Email -->
        <a class="contact-row"
           href="mailto:support@sibs.in?subject=Payment Failed - Order <%=orderId%>&body=Hi SIBS Support,%0D%0A%0D%0AMy payment failed for Order ID: <%=orderId%>.%0D%0AUser: <%=username%> (ID: <%=userId%>)%0D%0AError: <%=error%>%0D%0A%0D%0APlease help me resolve this issue.">
          <div class="contact-icon icon-mail"><i class="fa fa-envelope"></i></div>
          <div class="contact-info">
            <div class="contact-label">Email Support</div>
            <div class="contact-value">support@sibs.in</div>
          </div>
          <i class="fa fa-arrow-up-right-from-square" style="color:var(--muted);font-size:11px;"></i>
        </a>

      </div>
    </div>

    <!-- Bottom links -->
    <div class="actions">
      <a class="btn btn-outline" href="my-orders.jsp">
        <i class="fa fa-box"></i> My Orders
      </a>
      <a class="btn btn-outline" href="customer-dashboard.jsp">
        <i class="fa fa-shop"></i> Continue Shopping
      </a>
    </div>

  </div>
</div>
</div>

<script>
function toggleDark(){
  const h = document.documentElement;
  const isDark = h.getAttribute('data-theme') === 'dark';
  h.setAttribute('data-theme', isDark ? 'light' : 'dark');
  localStorage.setItem('sibs-theme', isDark ? 'light' : 'dark');
}
(function(){
  const t = localStorage.getItem('sibs-theme');
  if(t) document.documentElement.setAttribute('data-theme', t);
})();
</script>
</body>
</html>
