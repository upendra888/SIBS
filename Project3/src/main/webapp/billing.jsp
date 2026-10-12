<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.util.*,com.sibs.dao.ProductDAO,com.sibs.model.Product,com.sibs.model.User" %>
<%
User user = (User) session.getAttribute("user");
if (user == null) { response.sendRedirect("login.jsp"); return; }
String role = user.getRole();
if (!"STAFF".equals(role) && !"ADMIN".equals(role)) { response.sendRedirect("login.jsp"); return; }

ProductDAO pdao = new ProductDAO();
List<Product> products = pdao.getAllProducts();
%>
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Billing — SIBS</title>
<link href="https://fonts.googleapis.com/css2?family=Syne:wght@600;700;800&family=Nunito:wght@400;500;600;700&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<style>
:root{
  --bg:#f4f7ff;--surface:#fff;--border:#e4eaff;--text:#0d1321;--muted:#6b7a99;
  --primary:#3a5bef;--primary-dark:#2a47d4;--primary-light:#eef1ff;
  --success:#16a34a;--success-light:#f0fdf4;--danger:#ef4444;
  --orange:#ea6c00;--orange-light:#fff7ed;
}
[data-theme="dark"]{
  --bg:#0d1017;--surface:#141b2d;--border:#1e2a45;--text:#e8eeff;--muted:#5a6a8a;
  --primary:#5878f5;--primary-light:#1a2040;--success-light:#0a2018;--orange-light:#1a1000;
}
*{margin:0;padding:0;box-sizing:border-box;}
body{font-family:'Nunito',sans-serif;background:var(--bg);color:var(--text);min-height:100vh;}

/* Topbar */
.topbar{background:var(--surface);border-bottom:1px solid var(--border);
  height:58px;display:flex;align-items:center;justify-content:space-between;
  padding:0 24px;position:sticky;top:0;z-index:50;}
.topbar-left{display:flex;align-items:center;gap:12px;}
.topbar-left a{color:var(--muted);text-decoration:none;font-size:13px;display:flex;align-items:center;gap:5px;}
.topbar-left a:hover{color:var(--primary);}
.sep{color:var(--border);}
.page-title{font-family:'Syne',sans-serif;font-weight:700;font-size:16px;}
.dark-btn{background:none;border:1px solid var(--border);width:34px;height:34px;
  border-radius:8px;cursor:pointer;color:var(--muted);font-size:13px;
  display:flex;align-items:center;justify-content:center;}

/* Layout */
.layout{display:grid;grid-template-columns:1fr 360px;gap:20px;padding:24px;max-width:1300px;margin:0 auto;}
@media(max-width:900px){.layout{grid-template-columns:1fr;}}

/* Section heading */
.section-head{font-family:'Syne',sans-serif;font-weight:700;font-size:14px;
  color:var(--muted);text-transform:uppercase;letter-spacing:.6px;margin-bottom:12px;}

/* Product search */
.search-bar{display:flex;gap:8px;margin-bottom:16px;}
.search-bar input{flex:1;padding:10px 14px;border:1.5px solid var(--border);
  border-radius:10px;background:var(--surface);color:var(--text);font-family:'Nunito',sans-serif;
  font-size:13px;outline:none;}
.search-bar input:focus{border-color:var(--primary);}

/* Product grid */
.product-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(160px,1fr));gap:12px;}
.prod-card{background:var(--surface);border:1.5px solid var(--border);border-radius:14px;
  padding:14px;cursor:pointer;transition:.15s;position:relative;user-select:none;}
.prod-card:hover{border-color:var(--primary);box-shadow:0 4px 20px rgba(58,91,239,.1);}
.prod-card.selected{border-color:var(--primary);background:var(--primary-light);}
.prod-card.out-of-stock{opacity:.45;cursor:not-allowed;}
.prod-img{width:48px;height:48px;border-radius:10px;object-fit:cover;margin-bottom:8px;
  background:var(--bg);display:flex;align-items:center;justify-content:center;font-size:24px;}
.prod-name{font-weight:700;font-size:13px;margin-bottom:3px;}
.prod-price{font-size:12px;color:var(--primary);font-weight:700;}
.prod-stock{font-size:11px;color:var(--muted);margin-top:2px;}
.prod-stock.low{color:var(--orange);}
.prod-stock.out{color:var(--danger);}
.selected-check{position:absolute;top:8px;right:8px;width:20px;height:20px;
  background:var(--primary);border-radius:50%;display:none;
  align-items:center;justify-content:center;color:#fff;font-size:10px;}
.prod-card.selected .selected-check{display:flex;}

/* Bill form (right panel) */
.bill-panel{position:sticky;top:78px;}
.bill-card{background:var(--surface);border:1.5px solid var(--border);border-radius:16px;overflow:hidden;}
.bill-header{background:linear-gradient(135deg,#1a2a6c,#3a5bef);padding:18px 20px;}
.bill-header h3{font-family:'Syne',sans-serif;font-weight:800;font-size:16px;color:#fff;margin-bottom:2px;}
.bill-header p{font-size:12px;color:rgba(255,255,255,.7);}
.bill-body{padding:16px;}

/* Cart items */
.cart-empty{text-align:center;padding:28px 16px;color:var(--muted);font-size:13px;}
.cart-empty i{font-size:32px;margin-bottom:8px;display:block;opacity:.4;}

.cart-item{display:flex;align-items:center;gap:10px;padding:10px 0;
  border-bottom:1px solid var(--border);}
.cart-item:last-child{border-bottom:none;}
.cart-item-name{flex:1;font-weight:600;font-size:13px;}
.cart-item-price{font-size:12px;color:var(--muted);}
.qty-ctrl{display:flex;align-items:center;gap:6px;}
.qty-btn{width:26px;height:26px;border:1.5px solid var(--border);border-radius:6px;
  background:none;cursor:pointer;color:var(--text);font-size:13px;font-weight:700;
  display:flex;align-items:center;justify-content:center;transition:.1s;}
.qty-btn:hover{border-color:var(--primary);color:var(--primary);}
.qty-val{font-weight:700;font-size:13px;min-width:20px;text-align:center;}
.cart-remove{background:none;border:none;color:var(--danger);cursor:pointer;font-size:13px;padding:4px;}

/* Totals */
.totals{background:var(--bg);border-radius:10px;padding:12px 14px;margin-top:12px;}
.total-row{display:flex;justify-content:space-between;font-size:13px;padding:4px 0;}
.total-row.grand{font-family:'Syne',sans-serif;font-weight:800;font-size:16px;
  border-top:1.5px solid var(--border);margin-top:6px;padding-top:8px;color:var(--primary);}
.total-row .label{color:var(--muted);}
.total-row.discount .val{color:var(--success);}

/* Customer field */
.field{margin-bottom:12px;}
.field label{display:block;font-size:12px;font-weight:700;color:var(--muted);
  text-transform:uppercase;letter-spacing:.4px;margin-bottom:5px;}
.field input, .field select{width:100%;padding:9px 12px;border:1.5px solid var(--border);
  border-radius:9px;background:var(--surface);color:var(--text);
  font-family:'Nunito',sans-serif;font-size:13px;outline:none;}
.field input:focus, .field select:focus{border-color:var(--primary);}

/* Generate button */
.gen-btn{width:100%;padding:13px;background:var(--primary);color:#fff;border:none;
  border-radius:11px;font-family:'Syne',sans-serif;font-weight:700;font-size:14px;
  cursor:pointer;display:flex;align-items:center;justify-content:center;gap:8px;
  transition:.15s;margin-top:14px;}
.gen-btn:hover{background:var(--primary-dark);}
.gen-btn:disabled{opacity:.5;cursor:not-allowed;}

/* Hidden form inputs container */
#formContainer{display:none;}
</style>
</head>
<body>

<div class="topbar">
  <div class="topbar-left">
    <% if("ADMIN".equals(role)){ %>
      <a href="dashboard.jsp"><i class="fa fa-arrow-left"></i> Dashboard</a>
    <% } else { %>
      <a href="staff-dashboard.jsp"><i class="fa fa-arrow-left"></i> Dashboard</a>
    <% } %>
    <span class="sep">|</span>
    <span class="page-title"><i class="fa fa-file-invoice-dollar" style="color:var(--primary);margin-right:6px;"></i>Billing</span>
  </div>
  <button class="dark-btn" onclick="toggleDark()"><i class="fa fa-moon"></i></button>
</div>

<div class="layout">

  <!-- LEFT: Product Selection -->
  <div>
    <div class="section-head"><i class="fa fa-boxes-stacked"></i> Select Products</div>

    <div class="search-bar">
      <input type="text" id="prodSearch" placeholder="Search products..." oninput="filterProducts()">
    </div>

    <div class="product-grid" id="productGrid">
      <% for(Product p : products) {
           boolean outOfStock = p.getQuantity() <= 0;
           boolean lowStock   = p.getQuantity() > 0 && p.getQuantity() <= 5;
      %>
      <div class="prod-card <%=outOfStock ? "out-of-stock" : ""%>"
           id="card-<%=p.getId()%>"
           data-id="<%=p.getId()%>"
           data-name="<%=p.getName()%>"
           data-price="<%=p.getPrice()%>"
           data-stock="<%=p.getQuantity()%>"
           data-search="<%=p.getName().toLowerCase()%>"
           onclick="toggleProduct(this, <%=outOfStock%>)">
        <div class="selected-check"><i class="fa fa-check"></i></div>
        <div class="prod-img">🛒</div>
        <div class="prod-name"><%=p.getName()%></div>
        <div class="prod-price">₹<%=(int)p.getPrice()%></div>
        <div class="prod-stock <%=outOfStock?"out":lowStock?"low":""%>">
          <%=outOfStock ? "Out of stock" : "Stock: " + p.getQuantity()%>
        </div>
      </div>
      <% } %>
    </div>
  </div>

  <!-- RIGHT: Bill Panel -->
  <div class="bill-panel">
    <div class="section-head"><i class="fa fa-receipt"></i> Bill Summary</div>
    <div class="bill-card">
      <div class="bill-header">
        <h3>New Bill</h3>
        <p>Add products from the left panel</p>
      </div>
      <div class="bill-body">

        <!-- Customer name -->
        <div class="field">
          <label>Customer Name</label>
          <input type="text" id="customerName" placeholder="Enter customer name">
        </div>

        <!-- Cart Items -->
        <div class="section-head" style="margin-top:4px;">Items</div>
        <div id="cartItems">
          <div class="cart-empty" id="emptyMsg">
            <i class="fa fa-cart-shopping"></i>
            No products selected yet
          </div>
        </div>

        <!-- Totals -->
        <div class="totals" id="totalsBox" style="display:none;">
          <div class="total-row">
            <span class="label">Subtotal</span>
            <span class="val" id="subtotalVal">₹0</span>
          </div>
          <div class="total-row discount">
            <span class="label">Discount (10%)</span>
            <span class="val" id="discountVal">-₹0</span>
          </div>
          <div class="total-row">
            <span class="label">GST (18%)</span>
            <span class="val" id="taxVal">₹0</span>
          </div>
          <div class="total-row grand">
            <span>Total</span>
            <span id="totalVal">₹0</span>
          </div>
        </div>

        <button class="gen-btn" id="genBtn" onclick="generateBill()" disabled>
          <i class="fa fa-file-invoice"></i> Generate Bill
        </button>

      </div>
    </div>
  </div>
</div>

<!-- Hidden form that submits to /generateBill -->
<div id="formContainer">
  <form id="billForm" action="generateBill" method="post">
    <input type="hidden" name="customerName" id="fCustomerName">
    <div id="hiddenItems"></div>
  </form>
</div>

<script>
// State
var cart = {}; // { id: {name, price, qty, stock} }

function toggleProduct(card, outOfStock) {
  if (outOfStock) return;
  var id    = card.getAttribute('data-id');
  var name  = card.getAttribute('data-name');
  var price = parseFloat(card.getAttribute('data-price'));
  var stock = parseInt(card.getAttribute('data-stock'));

  if (cart[id]) {
    delete cart[id];
    card.classList.remove('selected');
  } else {
    cart[id] = { name: name, price: price, qty: 1, stock: stock };
    card.classList.add('selected');
  }
  renderCart();
}

function changeQty(id, delta) {
  if (!cart[id]) return;
  var newQty = cart[id].qty + delta;
  if (newQty < 1) { removeItem(id); return; }
  if (newQty > cart[id].stock) { alert('Max stock: ' + cart[id].stock); return; }
  cart[id].qty = newQty;
  renderCart();
}

function removeItem(id) {
  delete cart[id];
  var card = document.getElementById('card-' + id);
  if (card) card.classList.remove('selected');
  renderCart();
}

function renderCart() {
  var keys = Object.keys(cart);
  var container = document.getElementById('cartItems');
  var emptyMsg  = document.getElementById('emptyMsg');
  var totalsBox = document.getElementById('totalsBox');
  var genBtn    = document.getElementById('genBtn');

  if (keys.length === 0) {
    container.innerHTML = '<div class="cart-empty" id="emptyMsg"><i class="fa fa-cart-shopping"></i>No products selected yet</div>';
    totalsBox.style.display = 'none';
    genBtn.disabled = true;
    return;
  }

  var html = '';
  var subtotal = 0;
  keys.forEach(function(id) {
    var item = cart[id];
    var lineTotal = item.price * item.qty;
    subtotal += lineTotal;
    html += '<div class="cart-item">' +
      '<div style="flex:1;">' +
        '<div class="cart-item-name">' + item.name + '</div>' +
        '<div class="cart-item-price">₹' + item.price + ' × ' + item.qty + ' = ₹' + lineTotal.toFixed(0) + '</div>' +
      '</div>' +
      '<div class="qty-ctrl">' +
        '<button class="qty-btn" onclick="changeQty(\'' + id + '\',-1)">−</button>' +
        '<span class="qty-val">' + item.qty + '</span>' +
        '<button class="qty-btn" onclick="changeQty(\'' + id + '\',1)">+</button>' +
      '</div>' +
      '<button class="cart-remove" onclick="removeItem(\'' + id + '\')"><i class="fa fa-trash"></i></button>' +
    '</div>';
  });

  container.innerHTML = html;

  var discount = subtotal * 0.10;
  var tax      = (subtotal - discount) * 0.18;
  var total    = subtotal - discount + tax;

  document.getElementById('subtotalVal').textContent = '₹' + subtotal.toFixed(0);
  document.getElementById('discountVal').textContent = '-₹' + discount.toFixed(0);
  document.getElementById('taxVal').textContent      = '₹' + tax.toFixed(0);
  document.getElementById('totalVal').textContent    = '₹' + total.toFixed(0);

  totalsBox.style.display = 'block';
  genBtn.disabled = false;
}

function generateBill() {
  var keys = Object.keys(cart);
  if (keys.length === 0) { alert('Please select at least one product.'); return; }

  var customerName = document.getElementById('customerName').value.trim();
  if (!customerName) { alert('Please enter customer name.'); document.getElementById('customerName').focus(); return; }

  document.getElementById('fCustomerName').value = customerName;

  // Build hidden inputs for each cart item
  var hiddenDiv = document.getElementById('hiddenItems');
  hiddenDiv.innerHTML = '';
  keys.forEach(function(id) {
    var item = cart[id];
    hiddenDiv.innerHTML +=
      '<input type="hidden" name="productName" value="' + item.name + '">' +
      '<input type="hidden" name="quantity"    value="' + item.qty  + '">';
  });

  document.getElementById('billForm').submit();
}

function filterProducts() {
  var q = document.getElementById('prodSearch').value.toLowerCase();
  document.querySelectorAll('.prod-card').forEach(function(card) {
    var name = card.getAttribute('data-search') || '';
    card.style.display = name.includes(q) ? '' : 'none';
  });
}

function toggleDark() {
  var h = document.documentElement;
  var isDark = h.getAttribute('data-theme') === 'dark';
  h.setAttribute('data-theme', isDark ? 'light' : 'dark');
  localStorage.setItem('sibs-theme', isDark ? 'light' : 'dark');
}
(function(){
  var t = localStorage.getItem('sibs-theme');
  if (t) document.documentElement.setAttribute('data-theme', t);
})();
</script>
</body>
</html>
