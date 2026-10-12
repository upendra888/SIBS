<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.util.*,com.sibs.dao.DeliveryBoyEarningsDAO,com.sibs.dao.DeliveryBoyEarningsDAO.EarningsSummary,com.sibs.model.User" %>
<%
User user = (User)session.getAttribute("user");
if(user == null || (!"STAFF".equals(user.getRole()) && !"ADMIN".equals(user.getRole()))){
    response.sendRedirect("login.jsp"); return;
}

DeliveryBoyEarningsDAO earningsDAO = new DeliveryBoyEarningsDAO();
List<EarningsSummary> summaries = earningsDAO.getAllSettlementPreview();

EarningsSummary result = (EarningsSummary) session.getAttribute("settlementResult");
if(result != null) session.removeAttribute("settlementResult");

String settled = request.getParameter("settled");
String error   = request.getParameter("error");
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Salary Remittance Settlement — SIBS Admin</title>
<%@ include file="includes/adminSidebar.jsp" %>
<style>
.page-header{display:flex;align-items:center;justify-content:space-between;margin-bottom:24px;}
.page-title{font-size:22px;font-weight:700;}
.card{background:#fff;border:1px solid var(--border);border-radius:12px;box-shadow:var(--shadow);overflow:hidden;margin-bottom:24px;}
.card-header{padding:16px 20px;border-bottom:1px solid var(--border);font-weight:600;font-size:15px;display:flex;align-items:center;gap:8px;}
table{width:100%;border-collapse:collapse;}
th,td{padding:12px 16px;text-align:left;border-bottom:1px solid var(--border);font-size:13px;}
th{background:#f8f9fa;font-weight:600;color:var(--muted);}
.badge{display:inline-block;padding:3px 10px;border-radius:20px;font-size:11px;font-weight:600;}
.badge-warn{background:#fff3cd;color:#856404;}
.badge-success{background:#d1e7dd;color:#0f5132;}
.btn{padding:8px 16px;border:none;border-radius:8px;cursor:pointer;font-size:13px;font-weight:600;}
.btn-primary{background:var(--primary,#0d6efd);color:#fff;}
.btn-sm{padding:5px 12px;font-size:12px;}
.info-box{background:#e8f4fd;border:1px solid #bee5fb;border-radius:10px;padding:16px;margin-bottom:20px;font-size:13px;}
.success-box{background:#d1e7dd;border:1px solid #badbcc;border-radius:10px;padding:16px;margin-bottom:20px;}
.error-box{background:#f8d7da;border:1px solid #f5c2c7;border-radius:10px;padding:16px;margin-bottom:20px;}
.modal-overlay{display:none;position:fixed;inset:0;background:rgba(0,0,0,.5);z-index:1000;align-items:center;justify-content:center;}
.modal-overlay.active{display:flex;}
.modal{background:#fff;border-radius:16px;padding:28px;width:480px;max-width:95vw;}
.modal h3{margin:0 0 20px;font-size:18px;}
.form-row{display:grid;grid-template-columns:1fr 1fr;gap:12px;margin-bottom:16px;}
.form-group{display:flex;flex-direction:column;gap:6px;}
.form-group label{font-size:12px;font-weight:600;color:var(--muted);}
.form-group input{border:1px solid var(--border);border-radius:8px;padding:8px 12px;font-size:13px;}
.preview-box{background:#f8f9fa;border-radius:10px;padding:16px;margin:16px 0;}
.preview-row{display:flex;justify-content:space-between;font-size:13px;padding:4px 0;}
.preview-row.total{font-weight:700;font-size:15px;border-top:2px solid #dee2e6;margin-top:8px;padding-top:10px;}
.green{color:#198754;}
.red{color:#dc3545;}
</style>
</head>
<body>
<div class="main-content">

  <div class="page-header">
    <span class="page-title">💰 Salary Remittance Settlement</span>
  </div>

  <div class="info-box">
    <strong>How it works:</strong>
    Customer pays full COD amount (product + delivery charge).
    Only the <strong>product price (remittance amount)</strong> is deducted from the boy's salary.
    The <strong>delivery charge</strong> is company income and is <strong>NOT deducted</strong>.<br><br>
    Example: Customer pays <strong>Rs.100</strong>
    → Delivery Charge <strong>Rs.40</strong> (company keeps)
    → Deduct only <strong>Rs.60</strong> from salary ✅
  </div>

  <% if("1".equals(settled) && result != null) { %>
  <div class="success-box">
    ✅ <strong>Settlement done!</strong>
    Final salary = <strong>Rs.<%= String.format("%.2f", result.finalPayout) %></strong>
    (Rs.<%= String.format("%.2f", result.baseSalary) %> base
    − Rs.<%= String.format("%.2f", result.totalRemittance) %> remittance deduction).
    All COD entries marked as REMITTED.
  </div>
  <% } %>

  <% if("settlement_failed".equals(error)) { %>
  <div class="error-box">❌ Settlement failed. Please try again.</div>
  <% } %>

  <div class="card">
    <div class="card-header">📋 Pending Remittance — All Delivery Boys</div>
    <table>
      <thead>
        <tr>
          <th>Delivery Boy</th>
          <th>COD Orders</th>
          <th>Cash Held</th>
          <th>Delivery Charges</th>
          <th>Remittance to Deduct</th>
          <th>Action</th>
        </tr>
      </thead>
      <tbody>
        <% if(summaries.isEmpty()) { %>
        <tr>
          <td colspan="6" style="text-align:center;padding:32px;color:var(--muted);">
            No pending remittance — all settled ✅
          </td>
        </tr>
        <% } %>
        <% for(EarningsSummary s : summaries) { %>
        <tr>
          <td><strong><%= s.riderName %></strong></td>
          <td><%= s.ordersCount %></td>
          <td>Rs.<%= String.format("%.2f", s.totalCashCollected) %></td>
          <td class="green">
            Rs.<%= String.format("%.2f", s.totalDeliveryCharge) %>
            <span class="badge badge-success">Company Income</span>
          </td>
          <td class="red" style="font-weight:700;">
            Rs.<%= String.format("%.2f", s.totalRemittance) %>
            <span class="badge badge-warn">Deduct from Salary</span>
          </td>
          <td>
            <button class="btn btn-primary btn-sm"
              onclick="openSettle(
                <%= s.deliveryBoyId %>,
                '<%= s.riderName %>',
                <%= s.totalCashCollected %>,
                <%= s.totalDeliveryCharge %>,
                <%= s.totalRemittance %>)">
              Settle Salary
            </button>
          </td>
        </tr>
        <% } %>
      </tbody>
    </table>
  </div>

</div>

<!-- Settlement Modal -->
<div class="modal-overlay" id="settleModal">
  <div class="modal">
    <h3>💼 Process Salary Settlement</h3>
    <p style="font-size:13px;color:#666;margin-bottom:16px;">
      Rider: <strong id="modalName"></strong>
    </p>

    <div class="preview-box">
      <div class="preview-row">
        <span>Cash Held by Boy</span>
        <span id="pCashHeld">—</span>
      </div>
      <div class="preview-row green">
        <span>Delivery Charges (Company Income)</span>
        <span id="pDeliveryCharge">—</span>
      </div>
      <div class="preview-row red">
        <span>Remittance Deduction (Product Only)</span>
        <span id="pRemittance">—</span>
      </div>
      <div class="preview-row">
        <span>Base Salary</span>
        <span id="pBaseSalary">Enter below ↓</span>
      </div>
      <div class="preview-row total green">
        <span>✅ Final Payout to Boy</span>
        <span id="pFinalPayout">—</span>
      </div>
    </div>

    <form method="post" action="remittanceSettlement">
      <input type="hidden" name="deliveryBoyId" id="modalBoyId">
      <div class="form-row">
        <div class="form-group">
          <label>Base Salary (Rs.)</label>
          <input type="number" name="baseSalary" id="modalSalary"
            placeholder="e.g. 15000" min="0" step="0.01"
            oninput="updatePreview()" required>
        </div>
        <div class="form-group">
          <label>Note</label>
          <input type="text" name="note" placeholder="e.g. May 2026 salary">
        </div>
      </div>
      <div style="display:flex;gap:10px;justify-content:flex-end;margin-top:8px;">
        <button type="button" class="btn" style="background:#e9ecef;"
          onclick="closeModal()">Cancel</button>
        <button type="submit" class="btn btn-primary">✅ Confirm Settlement</button>
      </div>
    </form>
  </div>
</div>

<script>
let modalData = {};

function openSettle(boyId, name, cashHeld, deliveryCharge, remittance) {
  modalData = { cashHeld, deliveryCharge, remittance };
  document.getElementById('modalBoyId').value  = boyId;
  document.getElementById('modalName').textContent = name;
  document.getElementById('pCashHeld').textContent = 'Rs.' + cashHeld.toFixed(2);
  document.getElementById('pDeliveryCharge').textContent = 'Rs.' + deliveryCharge.toFixed(2);
  document.getElementById('pRemittance').textContent = 'Rs.' + remittance.toFixed(2);
  document.getElementById('pFinalPayout').textContent = '—';
  document.getElementById('pBaseSalary').textContent = 'Enter below ↓';
  document.getElementById('modalSalary').value = '';
  document.getElementById('settleModal').classList.add('active');
}

function closeModal() {
  document.getElementById('settleModal').classList.remove('active');
}

function updatePreview() {
  const base   = parseFloat(document.getElementById('modalSalary').value) || 0;
  const payout = Math.max(base - modalData.remittance, 0);
  document.getElementById('pBaseSalary').textContent = 'Rs.' + base.toFixed(2);
  document.getElementById('pFinalPayout').textContent = 'Rs.' + payout.toFixed(2);
}

document.getElementById('settleModal').addEventListener('click', function(e) {
  if(e.target === this) closeModal();
});
</script>

</body>
</html>