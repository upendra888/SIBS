<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="com.sibs.model.User" %>
<%
User user = (User)session.getAttribute("customer");
if(user == null){ response.sendRedirect("customer-login.jsp"); return; }

// orderId and amount set by PlaceOrderServlet when payment method is UPI/Card
Object orderIdObj = session.getAttribute("pendingOrderId");
Object amountObj  = session.getAttribute("pendingAmount");

// If not set, user landed here directly — redirect back
if(orderIdObj == null || amountObj == null){
    response.sendRedirect("cartCheckout.jsp");
    return;
}

String orderId = orderIdObj.toString();
double amount  = Double.parseDouble(amountObj.toString());
long   amountPaise = Math.round(amount * 100);
%>
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Payment — SIBS</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<script src="https://checkout.razorpay.com/v1/checkout.js"></script>
<style>
:root{--bg:#f8fafc;--surface:#fff;--border:#e2e8f0;--text:#0f172a;--muted:#64748b;
  --primary:#2563eb;--success:#16a34a;--danger:#ef4444;--upi-color:#6d28d9;}
[data-theme="dark"]{--bg:#0f172a;--surface:#1e293b;--border:#334155;--text:#f1f5f9;--muted:#94a3b8;}
*{margin:0;padding:0;box-sizing:border-box;font-family:'Inter',sans-serif;}
body{background:var(--bg);color:var(--text);min-height:100vh;display:flex;flex-direction:column;}
.topbar{background:var(--surface);border-bottom:1px solid var(--border);padding:0 20px;height:58px;
  display:flex;align-items:center;gap:10px;position:sticky;top:0;z-index:50;}
.topbar a{text-decoration:none;color:var(--muted);font-size:13px;display:flex;align-items:center;gap:5px;}
.topbar a:hover{color:var(--primary);}
.title{font-weight:700;font-size:15px;}
.dark-btn{background:none;border:1px solid var(--border);width:34px;height:34px;border-radius:8px;
  cursor:pointer;color:var(--muted);margin-left:auto;}

.steps{padding:14px 20px;background:var(--surface);border-bottom:1px solid var(--border);
  display:flex;justify-content:center;gap:8px;font-size:13px;}
.step{display:flex;align-items:center;gap:6px;color:var(--muted);}
.step.done{color:var(--success);}
.step.active{color:var(--primary);font-weight:600;}
.step-num{width:22px;height:22px;border-radius:50%;border:2px solid currentColor;
  display:flex;align-items:center;justify-content:center;font-size:11px;font-weight:700;}
.step.done .step-num{background:var(--success);border-color:var(--success);color:#fff;}
.sep{color:var(--border);}

.content{max-width:520px;margin:28px auto;padding:0 16px;width:100%;}
.card{background:var(--surface);border:1px solid var(--border);border-radius:12px;padding:24px;margin-bottom:14px;}
.card-title{font-size:15px;font-weight:700;margin-bottom:18px;padding-bottom:12px;
  border-bottom:1px solid var(--border);display:flex;align-items:center;gap:8px;}
.card-title i{color:var(--primary);}

.amount-box{background:var(--bg);border-radius:10px;padding:20px;text-align:center;margin-bottom:20px;}
.amount-label{font-size:13px;color:var(--muted);margin-bottom:4px;}
.amount-value{font-size:36px;font-weight:700;color:var(--primary);}
.amount-sub{font-size:12px;color:var(--muted);margin-top:2px;}

.summary-row{display:flex;justify-content:space-between;font-size:13px;padding:7px 0;border-bottom:1px solid var(--border);}
.summary-row:last-child{border-bottom:none;font-weight:700;font-size:15px;padding-top:10px;}

/* PAYMENT METHOD TABS */
.method-tabs{display:flex;gap:0;margin-bottom:20px;border:1.5px solid var(--border);border-radius:10px;overflow:hidden;}
.method-tab{flex:1;padding:14px 10px;text-align:center;cursor:pointer;transition:.15s;
  display:flex;flex-direction:column;align-items:center;gap:6px;border:none;background:none;color:var(--text);}
.method-tab:not(:last-child){border-right:1px solid var(--border);}
.method-tab.active{background:var(--primary);color:#fff;}
.method-tab .tab-icon{font-size:22px;}
.method-tab .tab-label{font-size:12px;font-weight:700;}
.method-tab .tab-sub{font-size:10px;opacity:.75;}

/* UPI Section */
#upiSection{display:block;}
.upi-info{background:#f5f3ff;border:1px solid #c4b5fd;border-radius:8px;padding:14px;
  font-size:13px;color:#5b21b6;margin-bottom:16px;display:flex;align-items:flex-start;gap:10px;}
[data-theme="dark"] .upi-info{background:#1a1040;border-color:#4c1d95;color:#a78bfa;}
.upi-logos{display:flex;gap:8px;align-items:center;margin-bottom:14px;flex-wrap:wrap;}
.upi-logo{padding:4px 10px;background:var(--bg);border:1px solid var(--border);border-radius:6px;
  font-size:11px;font-weight:800;color:var(--text);}

/* COD Section */
#codSection{display:none;}
.cod-note{background:#fef9c3;border:1px solid #fbbf24;border-radius:8px;padding:14px;
  font-size:13px;color:#92400e;margin-bottom:16px;display:flex;align-items:flex-start;gap:10px;}
[data-theme="dark"] .cod-note{background:#1a1300;border-color:#78350f;color:#fcd34d;}
.cod-checklist{list-style:none;margin-bottom:16px;}
.cod-checklist li{font-size:13px;padding:5px 0;display:flex;align-items:center;gap:8px;color:var(--muted);}
.cod-checklist li i{color:var(--success);}

/* Buttons */
.pay-btn{width:100%;padding:14px;border:none;border-radius:10px;cursor:pointer;font-weight:700;
  font-size:15px;display:flex;align-items:center;justify-content:center;gap:8px;transition:.15s;}
.pay-upi{background:linear-gradient(135deg,#7c3aed,#2563eb);color:#fff;}
.pay-upi:hover{opacity:.9;}
.pay-cod{background:linear-gradient(135deg,#15803d,#16a34a);color:#fff;}
.pay-cod:hover{opacity:.9;}
.pay-btn:disabled{opacity:.6;cursor:not-allowed;}
.secure{font-size:11px;color:var(--muted);text-align:center;margin-top:8px;
  display:flex;align-items:center;justify-content:center;gap:4px;}

/* Loading Overlay */
#loadingOverlay{position:fixed;inset:0;background:rgba(0,0,0,.6);z-index:9999;
  display:none;align-items:center;justify-content:center;flex-direction:column;color:#fff;}
#loadingOverlay.show{display:flex;}
.spinner{width:44px;height:44px;border:4px solid rgba(255,255,255,.3);border-top-color:#fff;
  border-radius:50%;animation:spin 1s linear infinite;margin-bottom:14px;}
@keyframes spin{to{transform:rotate(360deg);}}
.ov-card{background:#1e293b;border-radius:16px;padding:32px 40px;text-align:center;}
.ov-title{font-weight:700;font-size:15px;margin-bottom:4px;}
.ov-sub{font-size:12px;opacity:.7;}

/* Trust badges */
.trust-row{display:flex;gap:12px;justify-content:center;margin-top:4px;flex-wrap:wrap;}
.trust-item{font-size:12px;color:var(--muted);display:flex;align-items:center;gap:4px;}
</style>
</head>
<body>

<div id="loadingOverlay">
  <div class="ov-card">
    <div class="spinner"></div>
    <div class="ov-title">Processing payment...</div>
    <div class="ov-sub">Please do not close this window</div>
  </div>
</div>

<!-- TOPBAR -->
<div class="topbar">
  <a href="cartCheckout.jsp"><i class="fa fa-arrow-left"></i> Back</a>
  <span style="color:var(--border);">|</span>
  <span class="title">Secure Payment</span>
  <button class="dark-btn" onclick="toggleDark()"><i class="fa fa-moon"></i></button>
</div>

<!-- STEPS -->
<div class="steps">
  <div class="step done"><div class="step-num"><i class="fa fa-check" style="font-size:9px;"></i></div> Address</div>
  <span class="sep">›</span>
  <div class="step done"><div class="step-num"><i class="fa fa-check" style="font-size:9px;"></i></div> Order</div>
  <span class="sep">›</span>
  <div class="step active"><div class="step-num">3</div> Payment</div>
</div>

<div class="content">

  <!-- ORDER SUMMARY -->
  <div class="card">
    <div class="card-title"><i class="fa fa-receipt"></i> Order Summary</div>
    <div class="amount-box">
      <div class="amount-label">Total Amount Payable</div>
      <div class="amount-value">₹<%= (int) amount %></div>
      <div class="amount-sub">Order #<%=orderId%> • Includes delivery &amp; discount</div>
    </div>
    <div class="summary-row"><span>Items (after 10% off)</span><span>₹<%= (int)(amount - 40) %></span></div>
    <div class="summary-row"><span>Delivery charge</span><span>₹40</span></div>
    <div class="summary-row"><span>Total Payable</span><span>₹<%= (int) amount %></span></div>
  </div>

  <!-- PAYMENT METHOD -->
  <div class="card">
    <div class="card-title"><i class="fa fa-credit-card"></i> Choose Payment Method</div>

    <div class="method-tabs">
      <button class="method-tab active" id="tabUpi" onclick="switchMethod('upi')">
        <span class="tab-icon">📱</span>
        <span class="tab-label">UPI / Card</span>
        <span class="tab-sub">Instant &amp; Secure</span>
      </button>
      <button class="method-tab" id="tabCod" onclick="switchMethod('cod')">
        <span class="tab-icon">💵</span>
        <span class="tab-label">Cash on Delivery</span>
        <span class="tab-sub">Pay on arrival</span>
      </button>
    </div>

    <!-- UPI / ONLINE Section -->
    <div id="upiSection">
      <div class="upi-info">
        <i class="fa fa-shield-halved" style="margin-top:2px;"></i>
        <div>Pay via <strong>UPI, Credit/Debit Card, Net Banking or Wallets</strong> via Razorpay — India's most trusted payment gateway.</div>
      </div>
      <div class="upi-logos">
        <span class="upi-logo">GPay</span>
        <span class="upi-logo">PhonePe</span>
        <span class="upi-logo">Paytm</span>
        <span class="upi-logo">BHIM</span>
        <span class="upi-logo">VISA</span>
        <span class="upi-logo">Mastercard</span>
      </div>
      <button class="pay-btn pay-upi" id="payOnlineBtn" onclick="initiateOnlinePayment()">
        <i class="fa fa-lock"></i> Pay ₹<%= (int) amount %> via UPI / Card
      </button>
      <div class="secure"><i class="fa fa-shield-halved"></i> 256-bit SSL encrypted · Powered by Razorpay</div>
    </div>

    <!-- COD Section -->
    <div id="codSection">
      <div class="cod-note">
        <i class="fa fa-info-circle" style="margin-top:2px;"></i>
        <div>
          <strong>Cash on Delivery</strong> — Pay <strong>₹<%= (int) amount %></strong>
          in cash when your order arrives at your doorstep. No prepayment needed.
        </div>
      </div>
      <ul class="cod-checklist">
        <li><i class="fa fa-circle-check"></i> No online payment required</li>
        <li><i class="fa fa-circle-check"></i> Pay when you receive your order</li>
        <li><i class="fa fa-circle-check"></i> Order can be cancelled before dispatch</li>
        <li><i class="fa fa-circle-check"></i> ₹40 delivery charge included</li>
      </ul>
      <button class="pay-btn pay-cod" id="codBtn" onclick="confirmCOD()">
        <i class="fa fa-handshake"></i> Confirm Order — Pay ₹<%= (int) amount %> on Delivery
      </button>
    </div>
  </div>

  <!-- TRUST BADGES -->
  <div class="trust-row">
    <span class="trust-item"><i class="fa fa-lock" style="color:#16a34a;"></i> Secure Checkout</span>
    <span class="trust-item"><i class="fa fa-rotate-left" style="color:#2563eb;"></i> Easy Returns</span>
    <span class="trust-item"><i class="fa fa-headset" style="color:#f59e0b;"></i> 24/7 Support</span>
  </div>

</div><!-- .content -->

<script>
/* ── Theme ─────────────────────────────────── */
function toggleDark(){const h=document.documentElement,d=h.getAttribute('data-theme')==='dark';h.setAttribute('data-theme',d?'light':'dark');localStorage.setItem('sibs-theme',d?'light':'dark');}
(function(){const t=localStorage.getItem('sibs-theme');if(t)document.documentElement.setAttribute('data-theme',t);})();

/* ── Tab switch ─────────────────────────────── */
function switchMethod(method){
  document.getElementById('upiSection').style.display = method==='upi' ? 'block' : 'none';
  document.getElementById('codSection').style.display = method==='cod' ? 'block' : 'none';
  document.getElementById('tabUpi').classList.toggle('active', method==='upi');
  document.getElementById('tabCod').classList.toggle('active', method==='cod');
}

/* ── COD Confirm ────────────────────────────── */
function confirmCOD(){
  const btn = document.getElementById('codBtn');
  btn.disabled = true;
  btn.innerHTML = '<i class="fa fa-spinner fa-spin"></i> Confirming...';
  document.getElementById('loadingOverlay').classList.add('show');

  // Submit COD confirmation to backend
  fetch('confirmCOD', {
    method: 'POST',
    headers: {'Content-Type':'application/x-www-form-urlencoded'},
    body: 'orderId=<%=orderId%>&amount=<%=(int)amount%>'
  })
  .then(function(r){
    // redirect regardless of response — servlet handles the redirect
    window.location.href = 'order-success.jsp';
  })
  .catch(function(err){
    console.error(err);
    // Fallback: still redirect to success since order was already placed
    window.location.href = 'order-success.jsp';
  });
}

/* ── Razorpay Online Payment ─────────────────── */
function initiateOnlinePayment(){
  const btn = document.getElementById('payOnlineBtn');
  btn.disabled = true;
  btn.innerHTML = '<i class="fa fa-spinner fa-spin"></i> Opening payment...';
  document.getElementById('loadingOverlay').classList.add('show');

  fetch('createPaymentOrder', {
    method: 'POST',
    headers: {'Content-Type':'application/x-www-form-urlencoded'},
    body: 'orderId=<%=orderId%>&amount=<%=amount%>'
  })
  .then(r => r.json())
  .then(data => {
    document.getElementById('loadingOverlay').classList.remove('show');

    if(data.error){
      alert('Payment error: ' + data.error);
      resetBtn(btn);
      return;
    }

    const options = {
      key:         data.keyId,
      amount:      data.amount,
      currency:    data.currency || 'INR',
      name:        'SIBS Shop',
      description: 'Order #<%=orderId%>',
      order_id:    data.razorpayOrderId,
      prefill: {
        name:    data.customerName  || '',
        email:   data.customerEmail || '',
        contact: data.customerPhone || ''
      },
      theme: { color: '#2563eb' },

      handler: function(response){
        document.getElementById('loadingOverlay').classList.add('show');
        const form = document.createElement('form');
        form.method = 'POST';
        form.action = 'verifyPayment';
        [
          ['razorpay_order_id',   response.razorpay_order_id],
          ['razorpay_payment_id', response.razorpay_payment_id],
          ['razorpay_signature',  response.razorpay_signature]
        ].forEach(([k,v])=>{
          const inp = document.createElement('input');
          inp.type='hidden'; inp.name=k; inp.value=v;
          form.appendChild(inp);
        });
        document.body.appendChild(form);
        form.submit();
      },

      modal: {
        ondismiss: function(){
          resetBtn(btn);
        }
      }
    };

    const rzp = new Razorpay(options);
    rzp.on('payment.failed', function(resp){
      fetch('paymentFailed', {
        method: 'POST',
        headers: {'Content-Type':'application/x-www-form-urlencoded'},
        body: 'error_description=' + encodeURIComponent(resp.error.description || 'Payment failed')
      }).then(()=>{
        window.location.href = 'payment-failed.jsp?reason=' + encodeURIComponent(resp.error.description || 'Payment failed');
      });
    });

    resetBtn(btn);
    rzp.open();
  })
  .catch(err => {
    document.getElementById('loadingOverlay').classList.remove('show');
    resetBtn(btn);
    alert('Network error. Please try again.');
    console.error(err);
  });
}

function resetBtn(btn){
  btn.disabled = false;
  btn.innerHTML = '<i class="fa fa-lock"></i> Pay ₹<%= (int) amount %> via UPI / Card';
}
</script>
</body>
</html>
