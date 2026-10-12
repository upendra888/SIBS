<%@ page language="java" contentType="text/html; charset=UTF-8" %>
<%@ page import="java.sql.*,com.sibs.util.DBConnection,com.sibs.model.User" %>
<%
User user = (User)session.getAttribute("customer");
if(user == null){
    response.sendRedirect("customer-login.jsp");
    return;
}
Connection con = null; PreparedStatement ps = null; ResultSet rs = null;
double total = 0;
java.util.List<Object[]> items = new java.util.ArrayList<>();
try {
    con = DBConnection.getConnection();
    ps = con.prepareStatement(
        "SELECT c.id, c.product_id, p.name, c.quantity, c.price, c.image_path " +
        "FROM cart c JOIN products p ON c.product_id=p.id WHERE c.user_id=?"
    );
    ps.setInt(1, user.getId());
    rs = ps.executeQuery();
    while(rs.next()){
        Object[] row = {
            rs.getInt("id"),
            rs.getInt("product_id"),
            rs.getString("name"),
            rs.getInt("quantity"),
            rs.getDouble("price"),
            rs.getString("image_path")
        };
        items.add(row);
        total += (double)row[4] * (int)row[3];
    }
} finally {
    if(rs != null) try{rs.close();}catch(Exception e){}
    if(ps != null) try{ps.close();}catch(Exception e){}
    if(con != null) try{con.close();}catch(Exception e){}
}
double discount  = total * 0.10;
double delivery  = total > 0 ? 40 : 0;
double finalTotal = total - discount + delivery;
int itemCount = items.size();
%>
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Shopping Cart — SIBS</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<style>
:root{--bg:#f8fafc;--surface:#fff;--border:#e2e8f0;--text:#0f172a;--muted:#64748b;--primary:#2563eb;--danger:#ef4444;--success:#16a34a;}
[data-theme="dark"]{--bg:#0f172a;--surface:#1e293b;--border:#334155;--text:#f1f5f9;--muted:#94a3b8;}
*{margin:0;padding:0;box-sizing:border-box;font-family:'Inter',sans-serif;}
body{background:var(--bg);color:var(--text);}
.topbar{background:var(--surface);border-bottom:1px solid var(--border);padding:0 20px;height:58px;display:flex;align-items:center;gap:12px;position:sticky;top:0;z-index:50;box-shadow:0 1px 4px rgba(0,0,0,.07);}
.topbar a{text-decoration:none;color:var(--muted);font-size:13px;display:flex;align-items:center;gap:5px;}
.topbar a:hover{color:var(--primary);}
.topbar .title{font-weight:700;font-size:15px;margin-left:8px;color:var(--text);}
.dark-btn{background:none;border:1px solid var(--border);width:34px;height:34px;border-radius:8px;cursor:pointer;color:var(--muted);margin-left:auto;}
.layout{max-width:1000px;margin:28px auto;padding:0 16px;display:grid;grid-template-columns:1fr 340px;gap:20px;}
@media(max-width:768px){.layout{grid-template-columns:1fr;}}
.section-title{font-weight:700;font-size:15px;margin-bottom:14px;}

/* SELECT ALL ROW */
.select-all-row{display:flex;align-items:center;gap:10px;background:var(--surface);border:1px solid var(--border);border-radius:10px;padding:10px 16px;margin-bottom:12px;}
.select-all-row label{font-size:13px;font-weight:600;cursor:pointer;color:var(--text);}
.sel-count{font-size:12px;color:var(--muted);margin-left:auto;}

/* ITEM CARD */
.item{background:var(--surface);border:1px solid var(--border);border-radius:12px;padding:16px;display:flex;gap:14px;margin-bottom:10px;align-items:flex-start;transition:.2s;}
.item.selected{border-color:var(--primary);box-shadow:0 0 0 2px rgba(37,99,235,.12);}
.item-checkbox{width:18px;height:18px;accent-color:var(--primary);cursor:pointer;margin-top:32px;flex-shrink:0;}
.item-img-wrap{flex-shrink:0;text-align:center;}
.item-img{width:80px;height:80px;border-radius:8px;object-fit:contain;background:var(--bg);padding:6px;display:block;}
.item-discount-badge{display:inline-flex;align-items:center;gap:3px;background:#dcfce7;color:#15803d;border-radius:999px;font-size:9px;font-weight:700;padding:2px 6px;margin-top:5px;white-space:nowrap;}
.item-info{flex:1;}
.item-name{font-weight:600;font-size:14px;margin-bottom:3px;}
.item-price{font-size:12px;color:var(--muted);}
.item-price span{font-weight:600;color:var(--danger);font-size:13px;}
.qty-row{display:flex;align-items:center;gap:6px;margin:8px 0;}
.qty-btn{width:28px;height:28px;border:1px solid var(--border);background:var(--bg);cursor:pointer;border-radius:6px;font-size:15px;display:flex;align-items:center;justify-content:center;transition:.15s;}
.qty-btn:hover{border-color:var(--primary);}
.qty-val{font-weight:600;font-size:13px;min-width:24px;text-align:center;}
.item-actions{display:flex;gap:8px;margin-top:6px;}
.buy-btn{padding:7px 14px;background:var(--primary);color:#fff;border:none;border-radius:6px;cursor:pointer;font-size:12px;font-weight:500;transition:.15s;}
.buy-btn:hover{background:#1d4ed8;}
.remove-btn{background:none;border:1px solid var(--border);color:var(--muted);cursor:pointer;font-size:12px;display:flex;align-items:center;gap:4px;padding:7px 12px;border-radius:6px;transition:.15s;}
.remove-btn:hover{color:var(--danger);border-color:var(--danger);}
.item-total{font-weight:700;font-size:14px;text-align:right;min-width:60px;}
.item-total-orig{font-size:11px;color:var(--muted);text-decoration:line-through;}
.item-total-final{color:var(--primary);}

/* SUMMARY */
.summary-card{background:var(--surface);border:1px solid var(--border);border-radius:12px;padding:20px;position:sticky;top:74px;height:fit-content;}
.summary-row{display:flex;justify-content:space-between;font-size:13px;margin-bottom:8px;}
.summary-row.total{font-weight:700;font-size:16px;margin-top:4px;padding-top:10px;border-top:1px solid var(--border);}
.discount-row{color:var(--success);}
.savings-box{background:#f0fdf4;border:1px solid #bbf7d0;border-radius:8px;padding:9px 12px;font-size:12px;color:#16a34a;font-weight:600;margin:10px 0;display:flex;align-items:center;gap:6px;}
.checkout-btn{width:100%;padding:12px;background:var(--primary);color:#fff;border:none;border-radius:8px;cursor:pointer;font-weight:600;font-size:14px;margin-top:14px;transition:.15s;display:flex;align-items:center;justify-content:center;gap:8px;}
.checkout-btn:hover:not(:disabled){background:#1d4ed8;}
.checkout-btn:disabled{background:#94a3b8;cursor:not-allowed;}
.none-selected-note{font-size:11px;color:var(--muted);text-align:center;margin-top:8px;display:none;}
.empty-cart{text-align:center;padding:60px;color:var(--muted);}
.empty-cart i{font-size:44px;margin-bottom:14px;}
.continue-btn{padding:10px 20px;background:var(--primary);color:#fff;border:none;border-radius:8px;cursor:pointer;font-weight:500;margin-top:12px;}

/* TOAST */
.toast{position:fixed;bottom:24px;right:24px;background:#1e293b;color:#fff;padding:10px 18px;border-radius:8px;font-size:13px;z-index:999;opacity:0;transition:.3s;pointer-events:none;}
.toast.show{opacity:1;}
</style>
</head>
<body>

<div class="topbar">
  <a href="customer-dashboard.jsp"><i class="fa fa-arrow-left"></i> Continue Shopping</a>
  <span class="title">🛒 Shopping Cart</span>
  <button class="dark-btn" onclick="toggleDark()"><i class="fa fa-moon"></i></button>
</div>

<div class="layout">
  <div>
    <div class="section-title">Cart Items (<span id="cartItemCount"><%=itemCount%></span>)</div>

    <% if(items.isEmpty()){ %>
    <div class="empty-cart">
      <i class="fa fa-cart-shopping"></i>
      <p>Your cart is empty</p>
      <button class="continue-btn" onclick="location.href='customer-dashboard.jsp'">Browse Products</button>
    </div>
    <% } else { %>

    <!-- SELECT ALL ROW -->
    <div class="select-all-row" id="selectAllRow">
      <input type="checkbox" id="selectAll" class="item-checkbox" style="margin-top:0;" onchange="toggleAll(this)">
      <label for="selectAll">Select All</label>
      <span class="sel-count" id="selCount">0 of <%=itemCount%> selected</span>
    </div>

    <div id="itemsContainer">
    <%
       for(Object[] row : items){
         int cartId   = (int)row[0];
         int productId= (int)row[1];
         String name  = (String)row[2];
         int qty      = (int)row[3];
         double price = (double)row[4];
         String imgPath=(String)row[5];
         double iTotal    = price * qty;
         double iDiscount = iTotal * 0.10;
         double iFinal    = iTotal - iDiscount;
         String finalImg  = (imgPath!=null && !imgPath.trim().isEmpty())
             ? request.getContextPath()+"/"+imgPath : null;
    %>
    <div class="item" id="cartRow_<%=cartId%>" data-cart-id="<%=cartId%>" data-pid="<%=productId%>" data-qty="<%=qty%>" data-price="<%=price%>">
      <input type="checkbox" class="item-checkbox item-check" onchange="updateSummary()"
             data-pid="<%=productId%>" data-qty="<%=qty%>" data-price="<%=price%>">

      <div class="item-img-wrap">
        <% if(finalImg!=null){ %>
        <img class="item-img" src="<%=finalImg%>" onerror="this.src='images/default.png'" alt="<%=name%>">
        <% } else { %>
        <div style="width:80px;height:80px;border-radius:8px;background:var(--bg);display:flex;align-items:center;justify-content:center;font-size:28px;"><i class="fa fa-box"></i></div>
        <% } %>
        <div class="item-discount-badge"><i class="fa fa-tag" style="font-size:8px;"></i> 10% OFF</div>
      </div>

      <div class="item-info">
        <div class="item-name"><%=name%></div>
        <div class="item-price">Unit price: <span>₹<%=(int)price%></span></div>
        <div class="qty-row">
          <form action="updateCart" method="post" style="display:contents;">
            <input type="hidden" name="cartId" value="<%=cartId%>">
            <input type="hidden" name="action" value="decrease">
            <button class="qty-btn" type="submit">−</button>
          </form>
          <span class="qty-val"><%=qty%></span>
          <form action="updateCart" method="post" style="display:contents;">
            <input type="hidden" name="cartId" value="<%=cartId%>">
            <input type="hidden" name="action" value="increase">
            <button class="qty-btn" type="submit">+</button>
          </form>
        </div>
        <div class="item-actions">
          <form action="buyNow" method="post" style="display:contents;">
            <input type="hidden" name="productId" value="<%=productId%>">
            <input type="hidden" name="qty" value="<%=qty%>">
            <button type="submit" class="buy-btn"><i class="fa fa-bolt"></i> Buy Now</button>
          </form>
          <form action="removeCart" method="post" style="display:contents;">
            <input type="hidden" name="cartId" value="<%=cartId%>">
            <button type="submit" class="remove-btn"><i class="fa fa-trash"></i> Remove</button>
          </form>
        </div>
      </div>

      <div class="item-total">
        <div class="item-total-orig">₹<%=(int)iTotal%></div>
        <div class="item-total-final">₹<%=(int)iFinal%></div>
        <div style="font-size:10px;color:var(--success);">-₹<%=(int)iDiscount%></div>
      </div>
    </div>
    <% } } %>
    </div><!-- end itemsContainer -->
  </div>

  <!-- SUMMARY -->
  <div>
    <div class="summary-card">
      <div class="section-title">Order Summary</div>
      <div class="summary-row"><span>Subtotal (<span id="sumItemCount">0</span> items)</span><span>₹<span id="sumSubtotal">0</span></span></div>
      <div class="summary-row discount-row"><span><i class="fa fa-tag"></i> Discount (10%)</span><span>−₹<span id="sumDiscount">0</span></span></div>
      <div class="summary-row"><span>Delivery</span><span id="sumDelivery">₹0</span></div>
      <div class="summary-row total"><span>Total</span><span>₹<span id="sumTotal">0</span></span></div>
      <% if(!items.isEmpty()){ %>
      <div class="savings-box"><i class="fa fa-circle-check"></i> You save ₹<span id="sumSavings">0</span> on this order!</div>
      <button class="checkout-btn" id="checkoutBtn" onclick="proceedToCheckout()" disabled>
        <i class="fa fa-lock"></i> Proceed to Checkout
      </button>
      <div class="none-selected-note" id="noneNote">☝ Please select at least one item</div>
      <% } %>
      <div style="font-size:11px;color:var(--muted);margin-top:12px;text-align:center;display:flex;align-items:center;justify-content:center;gap:5px;"><i class="fa fa-shield-halved"></i> 100% Secure checkout</div>
    </div>
  </div>
</div>

<div class="toast" id="toast"></div>

<!-- Hidden form for selected checkout -->
<form id="checkoutForm" action="selectedCheckout" method="post" style="display:none;">
  <div id="checkoutInputs"></div>
</form>

<script>
function toggleDark(){
  const h=document.documentElement,d=h.getAttribute('data-theme')==='dark';
  h.setAttribute('data-theme',d?'light':'dark');
  localStorage.setItem('sibs-theme',d?'light':'dark');
}
(function(){const t=localStorage.getItem('sibs-theme');if(t)document.documentElement.setAttribute('data-theme',t);})();

function showToast(msg){
  const t=document.getElementById('toast');
  t.textContent=msg; t.classList.add('show');
  setTimeout(()=>t.classList.remove('show'),2500);
}

// ── Select All ────────────────────────────────────────────────────────────
function toggleAll(cb){
  document.querySelectorAll('.item-check').forEach(c=>{ c.checked=cb.checked; });
  updateSummary();
}

// ── Update summary based on checked items ─────────────────────────────────
function updateSummary(){
  const checks  = document.querySelectorAll('.item-check');
  const checked = document.querySelectorAll('.item-check:checked');
  const selAll  = document.getElementById('selectAll');

  if(selAll){
    selAll.indeterminate = checked.length > 0 && checked.length < checks.length;
    selAll.checked = checks.length > 0 && checked.length === checks.length;
  }

  checks.forEach(c => c.closest('.item').classList.toggle('selected', c.checked));

  let subtotal = 0;
  checked.forEach(c => { subtotal += parseFloat(c.dataset.price) * parseInt(c.dataset.qty); });

  const discount   = subtotal * 0.10;
  const delivery   = subtotal > 0 ? 40 : 0;
  const finalTotal = subtotal - discount + delivery;

  document.getElementById('sumItemCount').textContent = checked.length;
  document.getElementById('sumSubtotal').textContent  = Math.round(subtotal);
  document.getElementById('sumDiscount').textContent  = Math.round(discount);
  document.getElementById('sumDelivery').textContent  = subtotal > 0 ? '₹40' : '₹0';
  document.getElementById('sumTotal').textContent     = Math.round(finalTotal);
  document.getElementById('sumSavings').textContent   = Math.round(discount);

  const totalItems = document.querySelectorAll('.item').length;
  const selCountEl = document.getElementById('selCount');
  if(selCountEl) selCountEl.textContent = checked.length + ' of ' + totalItems + ' selected';

  const btn  = document.getElementById('checkoutBtn');
  const note = document.getElementById('noneNote');
  if(btn)  btn.disabled = checked.length === 0;
  if(note) note.style.display = checked.length === 0 ? 'block' : 'none';
}

// ── Proceed to checkout with selected items ───────────────────────────────
function proceedToCheckout(){
  const checked = document.querySelectorAll('.item-check:checked');
  if(checked.length === 0) return;
  const container = document.getElementById('checkoutInputs');
  container.innerHTML = '';
  checked.forEach(c => {
    const i1 = document.createElement('input');
    i1.type='hidden'; i1.name='selectedProductIds'; i1.value=c.dataset.pid;
    const i2 = document.createElement('input');
    i2.type='hidden'; i2.name='selectedQtys'; i2.value=c.dataset.qty;
    container.appendChild(i1); container.appendChild(i2);
  });
  document.getElementById('checkoutForm').submit();
}

updateSummary();
</script>
</body>
</html>
