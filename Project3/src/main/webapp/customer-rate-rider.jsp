<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="com.sibs.model.User, com.sibs.dao.DeliveryRatingDAO" %>
<%
User user = (User) session.getAttribute("customer");
if (user == null) { response.sendRedirect("customer-login.jsp"); return; }

String orderIdStr = request.getParameter("orderId");
if (orderIdStr == null) { response.sendRedirect("my-orders.jsp"); return; }

int orderId = 0;
try { orderId = Integer.parseInt(orderIdStr.trim()); }
catch (NumberFormatException e) { response.sendRedirect("my-orders.jsp"); return; }

// Already rated?
DeliveryRatingDAO ratingDao = new DeliveryRatingDAO();
if (ratingDao.hasRated(orderId, user.getId())) {
    response.sendRedirect("my-orders.jsp?rated=dup");
    return;
}

String err = request.getParameter("err");
%>
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Rate Your Delivery – SIBS</title>
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<style>
:root{--primary:#2563eb;--primary-light:#eff6ff;--bg:#f8fafc;--surface:#fff;--border:#e2e8f0;
  --text:#0f172a;--muted:#64748b;--success:#16a34a;--danger:#ef4444;--warn:#f59e0b;}
*,*::before,*::after{margin:0;padding:0;box-sizing:border-box;font-family:'Inter',system-ui,sans-serif;}
body{background:var(--bg);color:var(--text);min-height:100vh;display:flex;flex-direction:column;align-items:center;justify-content:center;padding:24px;}

.card{background:var(--surface);border:1px solid var(--border);border-radius:16px;padding:36px 32px;width:100%;max-width:440px;box-shadow:0 4px 24px rgba(0,0,0,.07);}
.back-link{display:inline-flex;align-items:center;gap:6px;color:var(--muted);font-size:13px;text-decoration:none;margin-bottom:20px;}
.back-link:hover{color:var(--primary);}

.header{text-align:center;margin-bottom:28px;}
.header .icon{width:64px;height:64px;background:var(--primary-light);border-radius:50%;display:flex;align-items:center;justify-content:center;margin:0 auto 14px;font-size:28px;color:var(--primary);}
.header h2{font-size:20px;font-weight:700;margin-bottom:6px;}
.header p{font-size:13px;color:var(--muted);}
.order-badge{display:inline-block;background:var(--bg);border:1px solid var(--border);border-radius:99px;padding:4px 12px;font-size:12px;font-weight:600;color:var(--muted);margin-top:8px;}

/* Star rating */
.stars-wrap{display:flex;justify-content:center;gap:10px;margin:20px 0 8px;flex-direction:row-reverse;}
.stars-wrap input[type=radio]{display:none;}
.stars-wrap label{font-size:38px;color:#cbd5e1;cursor:pointer;transition:color .15s,transform .15s;}
.stars-wrap label:hover,.stars-wrap label:hover~label,
.stars-wrap input:checked~label{color:#f59e0b;}
.stars-wrap label:hover{transform:scale(1.15);}
.star-label{text-align:center;font-size:13px;font-weight:600;color:var(--muted);margin-bottom:20px;min-height:20px;}

/* Comment */
.field{margin-bottom:18px;}
.field label{display:block;font-size:12px;font-weight:600;color:var(--muted);text-transform:uppercase;letter-spacing:.4px;margin-bottom:6px;}
.field textarea{width:100%;padding:10px 13px;border:1px solid var(--border);border-radius:8px;background:var(--bg);color:var(--text);font-size:13px;outline:none;resize:vertical;min-height:90px;transition:.15s;font-family:inherit;}
.field textarea:focus{border-color:var(--primary);}

.submit-btn{width:100%;padding:13px;background:var(--primary);color:#fff;border:none;border-radius:10px;font-size:14px;font-weight:600;cursor:pointer;transition:.15s;display:flex;align-items:center;justify-content:center;gap:8px;}
.submit-btn:hover{background:#1d4ed8;}
.submit-btn:disabled{opacity:.6;cursor:not-allowed;}

.error-msg{background:#fef2f2;border:1px solid #fecaca;color:#991b1b;border-radius:8px;padding:10px 14px;font-size:13px;margin-bottom:16px;display:flex;align-items:center;gap:8px;}
</style>
</head>
<body>

<div style="width:100%;max-width:440px;">
  <a class="back-link" href="my-orders.jsp"><i class="fa fa-arrow-left"></i> Back to My Orders</a>

  <div class="card">
    <div class="header">
      <div class="icon"><i class="fa fa-star"></i></div>
      <h2>Rate Your Delivery</h2>
      <p>How was your delivery experience?</p>
      <span class="order-badge">Order #<%=orderId%></span>
    </div>

    <% if ("invalid_stars".equals(err)) { %>
    <div class="error-msg"><i class="fa fa-circle-exclamation"></i> Please select a star rating before submitting.</div>
    <% } %>

    <form action="<%=request.getContextPath()%>/submitRating" method="post" onsubmit="return validateForm()">
      <input type="hidden" name="orderId" value="<%=orderId%>">

      <!-- Star picker (CSS-only, right-to-left trick) -->
      <div class="stars-wrap">
        <input type="radio" name="stars" id="s5" value="5"><label for="s5" title="Excellent">&#9733;</label>
        <input type="radio" name="stars" id="s4" value="4"><label for="s4" title="Good">&#9733;</label>
        <input type="radio" name="stars" id="s3" value="3"><label for="s3" title="Average">&#9733;</label>
        <input type="radio" name="stars" id="s2" value="2"><label for="s2" title="Poor">&#9733;</label>
        <input type="radio" name="stars" id="s1" value="1"><label for="s1" title="Terrible">&#9733;</label>
      </div>
      <div class="star-label" id="starLabel">Tap a star to rate</div>

      <div class="field">
        <label>Comment <span style="font-weight:400;text-transform:none;">(optional)</span></label>
        <textarea name="comment" placeholder="Share your experience with this delivery..."></textarea>
      </div>

      <button class="submit-btn" type="submit" id="submitBtn">
        <i class="fa fa-paper-plane"></i> Submit Rating
      </button>
    </form>
  </div>
</div>

<script>
const labels = ['Terrible','Poor','Average','Good','Excellent'];
const radios  = document.querySelectorAll('input[name=stars]');
const lbl     = document.getElementById('starLabel');

radios.forEach(r => {
  r.addEventListener('change', () => {
    lbl.textContent = labels[parseInt(r.value) - 1];
    lbl.style.color = '#f59e0b';
  });
});

function validateForm() {
  const checked = document.querySelector('input[name=stars]:checked');
  if (!checked) {
    lbl.textContent = 'Please select a star rating!';
    lbl.style.color = '#ef4444';
    return false;
  }
  document.getElementById('submitBtn').disabled = true;
  document.getElementById('submitBtn').innerHTML = '<i class="fa fa-spinner fa-spin"></i> Submitting...';
  return true;
}
</script>
</body>
</html>
