<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.util.*,com.sibs.dao.CouponDAO,com.sibs.model.User" %>
<%
User user = (User) session.getAttribute("user");
if (user == null) { response.sendRedirect("login.jsp"); return; }

CouponDAO dao = new CouponDAO();
List<Map<String, Object>> coupons = dao.getAllCoupons();

String msg    = request.getParameter("msg");
String status = request.getParameter("status");
String today  = new java.text.SimpleDateFormat("yyyy-MM-dd").format(new java.util.Date());
%>
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Coupon Management — SIBS</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<style>
:root{--bg:#f8fafc;--surface:#fff;--border:#e2e8f0;--text:#0f172a;--muted:#64748b;
      --primary:#2563eb;--primary-light:#eff6ff;--success:#16a34a;--danger:#ef4444;--warn:#f59e0b;}
[data-theme="dark"]{--bg:#0f172a;--surface:#1e293b;--border:#334155;--text:#f1f5f9;--muted:#94a3b8;
      --primary-light:#1e3a5f;}
*{margin:0;padding:0;box-sizing:border-box;font-family:'Inter',sans-serif;}
body{background:var(--bg);color:var(--text);}

/* Topbar */
.topbar{background:var(--surface);border-bottom:1px solid var(--border);padding:0 24px;
  height:60px;display:flex;align-items:center;gap:16px;position:sticky;top:0;z-index:50;}
.back-link{color:var(--muted);text-decoration:none;font-size:13px;display:flex;
  align-items:center;gap:5px;padding:6px 12px;border:1px solid var(--border);
  border-radius:8px;transition:.15s;}
.back-link:hover{border-color:var(--primary);color:var(--primary);}
.page-title{font-weight:700;font-size:16px;}
.dark-btn{background:none;border:1px solid var(--border);width:36px;height:36px;
  border-radius:9px;cursor:pointer;color:var(--muted);display:flex;align-items:center;
  justify-content:center;font-size:14px;margin-left:auto;transition:.15s;}
.dark-btn:hover{border-color:var(--primary);color:var(--primary);}

/* Layout */
.container{max-width:1100px;margin:28px auto;padding:0 20px;}

/* Alert */
.alert{padding:12px 16px;border-radius:10px;font-size:13px;font-weight:500;
  margin-bottom:18px;display:flex;align-items:center;gap:8px;}
.alert.ok{background:#dcfce7;color:#15803d;border:1px solid #bbf7d0;}
.alert.err{background:#fee2e2;color:#b91c1c;border:1px solid #fecaca;}

/* Create form card */
.card{background:var(--surface);border:1px solid var(--border);border-radius:14px;
  padding:24px;margin-bottom:22px;box-shadow:0 1px 8px rgba(0,0,0,.04);}
.card-title{font-size:14px;font-weight:700;margin-bottom:18px;display:flex;
  align-items:center;gap:8px;color:var(--primary);}
.form-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(200px,1fr));gap:14px;}
.form-group{display:flex;flex-direction:column;gap:5px;}
.form-group label{font-size:12px;font-weight:600;color:var(--muted);text-transform:uppercase;
  letter-spacing:.4px;}
.form-group input,.form-group select{padding:9px 12px;border:1.5px solid var(--border);
  border-radius:8px;background:var(--surface);color:var(--text);font-size:13px;
  outline:none;transition:.15s;}
.form-group input:focus,.form-group select:focus{border-color:var(--primary);}
.form-group.span2{grid-column:span 2;}
.hint{font-size:11px;color:var(--muted);margin-top:2px;}
.create-btn{margin-top:16px;padding:10px 22px;background:var(--primary);color:#fff;
  border:none;border-radius:9px;font-size:13px;font-weight:600;cursor:pointer;
  display:flex;align-items:center;gap:7px;transition:.15s;}
.create-btn:hover{background:#1d4ed8;}

/* Table */
.table-wrap{background:var(--surface);border:1px solid var(--border);border-radius:14px;
  overflow:hidden;box-shadow:0 1px 8px rgba(0,0,0,.04);}
.table-header{padding:14px 20px;border-bottom:1px solid var(--border);
  display:flex;align-items:center;justify-content:space-between;}
.table-header .title{font-weight:700;font-size:14px;display:flex;align-items:center;gap:8px;}
table{width:100%;border-collapse:collapse;}
th{padding:10px 16px;text-align:left;font-size:11px;font-weight:600;color:var(--muted);
  text-transform:uppercase;letter-spacing:.4px;background:var(--bg);
  border-bottom:1px solid var(--border);}
td{padding:12px 16px;font-size:13px;border-bottom:1px solid var(--border);vertical-align:middle;}
tbody tr:last-child td{border-bottom:none;}
tbody tr:hover{background:var(--bg);}

/* Badges */
.badge{padding:3px 10px;border-radius:999px;font-size:11px;font-weight:600;}
.badge.active{background:#dcfce7;color:#15803d;}
.badge.inactive{background:#fee2e2;color:#b91c1c;}
.badge.percent{background:#dbeafe;color:#1d4ed8;}
.badge.fixed{background:#fef3c7;color:#92400e;}

/* Action buttons */
.btn-sm{padding:5px 12px;border:none;border-radius:7px;font-size:12px;font-weight:600;
  cursor:pointer;transition:.15s;}
.btn-toggle{background:#fef3c7;color:#92400e;}
.btn-toggle:hover{background:#fde68a;}
.btn-toggle.deactivate{background:#fee2e2;color:#b91c1c;}
.btn-toggle.deactivate:hover{background:#fecaca;}
.btn-del{background:#fee2e2;color:#b91c1c;}
.btn-del:hover{background:#fca5a5;}

/* Stats row */
.stats-row{display:flex;gap:14px;margin-bottom:22px;flex-wrap:wrap;}
.stat-card{background:var(--surface);border:1px solid var(--border);border-radius:12px;
  padding:16px 20px;flex:1;min-width:140px;box-shadow:0 1px 6px rgba(0,0,0,.04);}
.stat-val{font-size:24px;font-weight:700;color:var(--primary);}
.stat-lbl{font-size:12px;color:var(--muted);margin-top:2px;}
</style>
</head>
<body>

<div class="topbar">
  <a href="staff-dashboard.jsp" class="back-link"><i class="fa fa-arrow-left"></i> Dashboard</a>
  <span class="page-title"><i class="fa fa-ticket" style="color:var(--primary)"></i> Coupon Management</span>
  <button class="dark-btn" onclick="toggleDark()" title="Toggle theme"><i class="fa fa-moon"></i></button>
</div>

<div class="container">

  <%-- Alert message --%>
  <% if (msg != null && !msg.trim().isEmpty()) { %>
  <div class="alert <%= "ok".equals(status) ? "ok" : "err" %>">
    <i class="fa <%= "ok".equals(status) ? "fa-circle-check" : "fa-circle-xmark" %>"></i>
    <%= msg %>
  </div>
  <% } %>

  <%-- Stats --%>
  <%
  int totalC = coupons.size(), activeC = 0, usedC = 0;
  for (Map<String,Object> c : coupons) {
      Object ia = c.get("is_active");
      Object uc = c.get("used_count");
      int iaVal = (ia instanceof Number) ? ((Number)ia).intValue() : Integer.parseInt(String.valueOf(ia));
      int ucVal = (uc instanceof Number) ? ((Number)uc).intValue() : Integer.parseInt(String.valueOf(uc));
      if (iaVal == 1) activeC++;
      usedC += ucVal;
  }
  %>
  <div class="stats-row">
    <div class="stat-card"><div class="stat-val"><%=totalC%></div><div class="stat-lbl">Total Coupons</div></div>
    <div class="stat-card"><div class="stat-val" style="color:#16a34a"><%=activeC%></div><div class="stat-lbl">Active</div></div>
    <div class="stat-card"><div class="stat-val" style="color:#f59e0b"><%=totalC-activeC%></div><div class="stat-lbl">Inactive</div></div>
    <div class="stat-card"><div class="stat-val" style="color:#6366f1"><%=usedC%></div><div class="stat-lbl">Total Uses</div></div>
  </div>

  <%-- Create Coupon Form --%>
  <div class="card">
    <div class="card-title"><i class="fa fa-plus-circle"></i> Create New Coupon</div>
    <form method="post" action="manageCoupon" onsubmit="return validateForm()">
      <input type="hidden" name="action" value="create">
      <div class="form-grid">
        <div class="form-group">
          <label>Coupon Code *</label>
          <input type="text" name="code" id="codeInput" placeholder="e.g. SAVE20"
                 maxlength="30" required oninput="this.value=this.value.toUpperCase()">
          <span class="hint">Auto-uppercased, must be unique</span>
        </div>
        <div class="form-group">
          <label>Discount Type *</label>
          <select name="discountType" id="typeSelect" onchange="updateValueHint()">
            <option value="PERCENT">Percentage (%)</option>
            <option value="FIXED">Fixed Amount (₹)</option>
          </select>
        </div>
        <div class="form-group">
          <label>Discount Value *</label>
          <input type="number" name="discountValue" id="valueInput" min="0.01" step="0.01"
                 placeholder="e.g. 10" required>
          <span class="hint" id="valueHint">Enter % (e.g. 10 = 10% off)</span>
        </div>
        <div class="form-group">
          <label>Min Order Amount (₹)</label>
          <input type="number" name="minOrderAmount" min="0" step="1" placeholder="0 = no minimum">
        </div>
        <div class="form-group">
          <label>Max Discount (₹)</label>
          <input type="number" name="maxDiscount" min="0" step="1" placeholder="0 = no cap">
          <span class="hint">For PERCENT type only</span>
        </div>
        <div class="form-group">
          <label>Usage Limit</label>
          <input type="number" name="usageLimit" min="1" step="1" placeholder="Leave blank = unlimited">
        </div>
        <div class="form-group">
          <label>Valid From *</label>
          <input type="date" name="validFrom" value="<%=today%>" required>
        </div>
        <div class="form-group">
          <label>Valid Until *</label>
          <input type="date" name="validUntil" required>
        </div>
        <div class="form-group span2">
          <label>Description</label>
          <input type="text" name="description" placeholder="e.g. Get 10% off on orders above ₹200"
                 maxlength="200">
        </div>
      </div>
      <button type="submit" class="create-btn">
        <i class="fa fa-plus"></i> Create Coupon
      </button>
    </form>
  </div>

  <%-- Coupons Table --%>
  <div class="table-wrap">
    <div class="table-header">
      <span class="title"><i class="fa fa-list"></i> All Coupons</span>
      <input type="text" id="searchBox" placeholder="Search code..." onkeyup="filterTable()"
             style="padding:7px 12px;border:1px solid var(--border);border-radius:8px;
                    background:var(--surface);color:var(--text);font-size:13px;outline:none;width:180px;">
    </div>
    <table id="couponTable">
      <thead>
        <tr>
          <th>Code</th>
          <th>Type</th>
          <th>Value</th>
          <th>Min Order</th>
          <th>Max Disc.</th>
          <th>Used / Limit</th>
          <th>Valid Until</th>
          <th>Status</th>
          <th>Actions</th>
        </tr>
      </thead>
      <tbody>
        <% if (coupons.isEmpty()) { %>
        <tr><td colspan="9" style="text-align:center;color:var(--muted);padding:32px;">
          No coupons yet. Create your first coupon above!
        </td></tr>
        <% } %>
        <% for (Map<String,Object> c : coupons) {
            int    id        = (c.get("id") instanceof Number) ? ((Number)c.get("id")).intValue() : Integer.parseInt(String.valueOf(c.get("id")));
            String code      = (String) c.get("code");
            String dtype     = (String) c.get("discount_type");
            double dval      = (c.get("discount_value") instanceof Number) ? ((Number)c.get("discount_value")).doubleValue() : Double.parseDouble(String.valueOf(c.get("discount_value")));
            double minOrd    = (c.get("min_order_amount") instanceof Number) ? ((Number)c.get("min_order_amount")).doubleValue() : Double.parseDouble(String.valueOf(c.get("min_order_amount")));
            double maxD      = (c.get("max_discount") instanceof Number) ? ((Number)c.get("max_discount")).doubleValue() : Double.parseDouble(String.valueOf(c.get("max_discount")));
            int    limit     = (c.get("usage_limit") instanceof Number) ? ((Number)c.get("usage_limit")).intValue() : Integer.parseInt(String.valueOf(c.get("usage_limit")));
            int    used      = (c.get("used_count") instanceof Number) ? ((Number)c.get("used_count")).intValue() : Integer.parseInt(String.valueOf(c.get("used_count")));
            String until     = (String) c.get("valid_until");
            int    isActive  = (c.get("is_active") instanceof Number) ? ((Number)c.get("is_active")).intValue() : Integer.parseInt(String.valueOf(c.get("is_active")));
            String desc      = (String) c.get("description");
        %>
        <tr title="<%=desc != null ? desc : ""%>">
          <td><strong><%=code%></strong></td>
          <td><span class="badge <%="PERCENT".equals(dtype)?"percent":"fixed"%>">
            <%="PERCENT".equals(dtype)?"% Off":"₹ Off"%>
          </span></td>
          <td><%="PERCENT".equals(dtype) ? (int)dval+"%" : "₹"+(int)dval%></td>
          <td><%=minOrd>0?"₹"+(int)minOrd:"—"%></td>
          <td><%=maxD>0?"₹"+(int)maxD:"—"%></td>
          <td><%=used%> / <%=limit>0?limit:"∞"%></td>
          <td><%=until%></td>
          <td><span class="badge <%=isActive==1?"active":"inactive"%>">
            <%=isActive==1?"Active":"Inactive"%>
          </span></td>
          <td style="display:flex;gap:6px;flex-wrap:wrap;">
            <form method="post" action="manageCoupon" style="display:inline;">
              <input type="hidden" name="action" value="toggle">
              <input type="hidden" name="id" value="<%=id%>">
              <button type="submit" class="btn-sm btn-toggle <%=isActive==1?"deactivate":""%>">
                <%=isActive==1?"Deactivate":"Activate"%>
              </button>
            </form>
            <form method="post" action="manageCoupon" style="display:inline;"
                  onsubmit="return confirm('Delete coupon <%=code%>? This cannot be undone.')">
              <input type="hidden" name="action" value="delete">
              <input type="hidden" name="id" value="<%=id%>">
              <button type="submit" class="btn-sm btn-del"><i class="fa fa-trash"></i></button>
            </form>
          </td>
        </tr>
        <% } %>
      </tbody>
    </table>
  </div>
</div>

<script>
function toggleDark() {
  const h = document.documentElement;
  h.setAttribute('data-theme', h.getAttribute('data-theme') === 'dark' ? 'light' : 'dark');
}

function updateValueHint() {
  const type = document.getElementById('typeSelect').value;
  document.getElementById('valueHint').textContent =
    type === 'PERCENT' ? 'Enter % (e.g. 10 = 10% off)' : 'Enter amount in ₹ (e.g. 50)';
}

function validateForm() {
  const code = document.getElementById('codeInput').value.trim();
  if (!code || !/^[A-Z0-9_\-]{2,30}$/.test(code)) {
    alert('Coupon code must be 2–30 chars, letters/numbers/_ only.');
    return false;
  }
  return true;
}

function filterTable() {
  const q = document.getElementById('searchBox').value.toLowerCase();
  document.querySelectorAll('#couponTable tbody tr').forEach(row => {
    row.style.display = row.innerText.toLowerCase().includes(q) ? '' : 'none';
  });
}

// Auto-hide alert after 4s
const alert = document.querySelector('.alert');
if (alert) setTimeout(() => alert.style.display = 'none', 4000);
</script>
</body>
</html>
