<%@ page contentType="text/html; charset=UTF-8" %>
<%@ page import="java.util.*, com.sibs.dao.ProductDAO, com.sibs.model.Product, com.sibs.model.User" %>
<%
User user = (User)session.getAttribute("user");
if(user == null || (!"ADMIN".equals(user.getRole()) && !"STAFF".equals(user.getRole()))){
    response.sendRedirect("login.jsp");
    return;
}
boolean isAdmin = "ADMIN".equals(user.getRole());
ProductDAO dao  = new ProductDAO();
List<Product> products = dao.getAllProducts();
int totalProducts = (products != null) ? products.size() : 0;
double totalValue = 0;
int lowStock = 0;
if(products != null){
    for(Product p : products){
        totalValue += p.getPrice() * p.getQuantity();
        if(p.getQuantity() < 5) lowStock++;
    }
}
%>
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Products — SIBS</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<style>
:root{--bg:#f8fafc;--surface:#fff;--border:#e2e8f0;--text:#0f172a;--muted:#64748b;--primary:#2563eb;--success:#16a34a;--danger:#ef4444;--warn:#f59e0b;}
[data-theme="dark"]{--bg:#0f172a;--surface:#1e293b;--border:#334155;--text:#f1f5f9;--muted:#94a3b8;}
*{margin:0;padding:0;box-sizing:border-box;font-family:'Inter',sans-serif;}
body{background:var(--bg);color:var(--text);}
.topbar{background:var(--surface);border-bottom:1px solid var(--border);padding:0 24px;height:60px;display:flex;align-items:center;gap:12px;position:sticky;top:0;z-index:50;box-shadow:0 1px 3px rgba(0,0,0,.06);}
.topbar-left{display:flex;align-items:center;gap:10px;}
.topbar-left a{text-decoration:none;color:var(--muted);font-size:13px;display:flex;align-items:center;gap:5px;}
.topbar-left a:hover{color:var(--primary);}
.page-title{font-weight:700;font-size:16px;}
.topbar-right{margin-left:auto;display:flex;gap:10px;align-items:center;}
.icon-btn{background:none;border:1px solid var(--border);height:34px;padding:0 12px;border-radius:7px;cursor:pointer;color:var(--muted);font-size:13px;display:flex;align-items:center;gap:6px;text-decoration:none;font-weight:500;}
.icon-btn:hover{background:var(--bg);color:var(--text);}
.icon-btn.add{background:var(--primary);color:#fff;border-color:var(--primary);}
.icon-btn.add:hover{background:#1d4ed8;}
.content{padding:24px;max-width:1400px;margin:0 auto;}
.stat-row{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:12px;margin-bottom:20px;}
.stat-box{background:var(--surface);border:1px solid var(--border);border-radius:10px;padding:16px;text-align:center;}
.stat-box .num{font-size:24px;font-weight:700;}
.stat-box .lbl{font-size:12px;color:var(--muted);margin-top:2px;}
.alert-banner{background:#fef3c7;border:1px solid #fbbf24;border-radius:8px;padding:12px 16px;margin-bottom:16px;display:flex;align-items:center;gap:8px;font-size:13px;color:#92400e;}
.controls{display:flex;gap:10px;margin-bottom:14px;flex-wrap:wrap;align-items:center;}
.controls input{padding:9px 14px;border:1px solid var(--border);border-radius:8px;background:var(--surface);color:var(--text);font-size:13px;outline:none;min-width:220px;}
.controls input:focus{border-color:var(--primary);}
.cat-pills{display:flex;gap:6px;flex-wrap:wrap;}
.cat-pill{padding:5px 12px;border:1px solid var(--border);border-radius:999px;background:none;cursor:pointer;font-size:12px;font-weight:500;color:var(--muted);transition:.15s;}
.cat-pill:hover,.cat-pill.active{border-color:var(--primary);color:var(--primary);background:#eff6ff;}
.table-wrap{background:var(--surface);border:1px solid var(--border);border-radius:12px;overflow:hidden;box-shadow:0 1px 3px rgba(0,0,0,.06);}
table{width:100%;border-collapse:collapse;}
th{padding:12px 16px;text-align:left;font-size:11px;font-weight:600;color:var(--muted);text-transform:uppercase;letter-spacing:.5px;background:var(--bg);border-bottom:1px solid var(--border);}
td{padding:13px 16px;font-size:13px;border-bottom:1px solid var(--border);vertical-align:middle;}
tbody tr:last-child td{border-bottom:none;}
tbody tr:hover{background:var(--bg);}
.prod-img{width:44px;height:44px;border-radius:8px;object-fit:contain;background:var(--bg);padding:4px;}
.cat-badge{padding:3px 9px;border-radius:999px;font-size:11px;font-weight:600;color:#fff;}
.cat-vegetables{background:#16a34a;} .cat-fruits{background:#f59e0b;} .cat-dairy{background:#2563eb;}
.cat-beverages{background:#06b6d4;} .cat-electronics{background:#6366f1;} .cat-clothing{background:#ec4899;}
.cat-snacks{background:#f97316;} .cat-non-veg{background:#ef4444;}
.stock-badge{padding:3px 9px;border-radius:999px;font-size:11px;font-weight:600;}
.in-stock{background:#dcfce7;color:#16a34a;}
.low-stock{background:#fee2e2;color:#ef4444;}
.action-btn{padding:6px 12px;border:none;border-radius:6px;color:#fff;cursor:pointer;font-size:12px;font-weight:500;transition:.15s;text-decoration:none;display:inline-block;}
.btn-edit{background:#2563eb;} .btn-edit:hover{background:#1d4ed8;}
.btn-del{background:none;border:1px solid var(--border);color:var(--danger);padding:6px 12px;border-radius:6px;cursor:pointer;font-size:12px;font-weight:500;}
.btn-del:hover{background:#fef2f2;border-color:var(--danger);}
/* MODAL */
.modal-overlay{position:fixed;inset:0;background:rgba(0,0,0,.5);z-index:1000;display:none;align-items:center;justify-content:center;}
.modal-overlay.open{display:flex;}
.modal{background:var(--surface);border-radius:14px;padding:28px;max-width:360px;width:90%;box-shadow:0 20px 60px rgba(0,0,0,.3);}
.modal h3{font-size:16px;font-weight:700;margin-bottom:8px;}
.modal p{font-size:13px;color:var(--muted);margin-bottom:20px;}
.modal-actions{display:flex;gap:10px;justify-content:flex-end;}
.modal-cancel{padding:8px 16px;background:var(--bg);border:1px solid var(--border);border-radius:7px;cursor:pointer;font-size:13px;}
.modal-confirm{padding:8px 16px;background:var(--danger);color:#fff;border:none;border-radius:7px;cursor:pointer;font-size:13px;font-weight:500;}
</style>
</head>
<body>

<div class="topbar">
  <div class="topbar-left">
    <a href="<%=isAdmin?"dashboard.jsp":"staff-dashboard.jsp"%>"><i class="fa fa-arrow-left"></i> Dashboard</a>
    <span style="color:var(--border);">|</span>
    <span class="page-title">Products</span>
  </div>
  <div class="topbar-right">
    <button class="icon-btn" onclick="toggleDark()"><i class="fa fa-moon"></i></button>
    <% if(isAdmin){ %>
    <a class="icon-btn add" href="add-product.jsp"><i class="fa fa-plus"></i> Add Product</a>
    <% } %>
  </div>
</div>

<div class="content">
  <div class="stat-row">
    <div class="stat-box"><div class="num"><%=totalProducts%></div><div class="lbl">Total Products</div></div>
    <div class="stat-box"><div class="num">₹<%=String.format("%.0f",totalValue)%></div><div class="lbl">Inventory Value</div></div>
    <div class="stat-box"><div class="num" style="color:var(--danger);"><%=lowStock%></div><div class="lbl">Low Stock</div></div>
  </div>

  <% if(lowStock > 0){ %>
  <div class="alert-banner"><i class="fa fa-triangle-exclamation"></i> <b><%=lowStock%> product(s)</b> have low stock (less than 5 units). Consider restocking soon.</div>
  <% } %>

  <div class="controls">
    <input type="text" id="searchInput" placeholder="🔍 Search products..." oninput="applyFilters()">
    <div class="cat-pills">
      <button class="cat-pill active" onclick="setCategory('ALL',this)">All</button>
      <button class="cat-pill" onclick="setCategory('vegetables',this)">🥦 Veg</button>
      <button class="cat-pill" onclick="setCategory('fruits',this)">🍎 Fruits</button>
      <button class="cat-pill" onclick="setCategory('non-veg',this)">🍗 Non-Veg</button>
      <button class="cat-pill" onclick="setCategory('dairy',this)">🥛 Dairy</button>
      <button class="cat-pill" onclick="setCategory('beverages',this)">🥤 Drinks</button>
      <button class="cat-pill" onclick="setCategory('electronics',this)">💡 Electronics</button>
      <button class="cat-pill" onclick="setCategory('clothing',this)">👕 Clothing</button>
      <button class="cat-pill" onclick="setCategory('snacks',this)">🍿 Snacks</button>
    </div>
  </div>

  <div class="table-wrap">
    <table>
      <thead>
        <tr>
          <th>#</th>
          <th>Image</th>
          <th>Product</th>
          <th>Price</th>
          <th>Qty</th>
          <th>Category</th>
          <th>Weight</th>
          <th>Status</th>
          <% if(isAdmin){ %><th>Actions</th><% } %>
        </tr>
      </thead>
      <tbody id="productTable">
      <%
      if(products != null){
        for(Product p : products){
          String cat = (p.getCategory() != null) ? p.getCategory().toLowerCase().trim() : "";
          if(cat.equals("veg")||cat.equals("vegetable")) cat="vegetables";
          if(cat.equals("nonveg")||cat.equals("non veg")) cat="non-veg";
          if(cat.equals("drink")||cat.equals("drinks")) cat="beverages";
          String imgSrc = (p.getImagePath()!=null&&!p.getImagePath().isEmpty())
              ? request.getContextPath()+"/"+p.getImagePath().replaceFirst("^/","")
              : request.getContextPath()+"/images/default.png";
          String unit = (p.getUnit()!=null)?p.getUnit().toLowerCase().trim():"";
          String wDisplay = "-";
          if(p.getWeight()>0){
            double w=p.getWeight();
            String wv=(w%1==0)?String.valueOf((int)w):String.valueOf(w);
            if("kg".equals(unit)) wDisplay=wv+"kg";
            else if("g".equals(unit)) wDisplay=wv+"g";
            else if("l".equals(unit)) wDisplay=wv+"L";
            else if("ml".equals(unit)) wDisplay=wv+"ml";
            else if("pcs".equals(unit)) wDisplay=wv+" pcs";
            else wDisplay=wv;
          }
      %>
      <tr data-category="<%=cat%>" data-name="<%=p.getName().toLowerCase()%>">
        <td style="color:var(--muted);font-size:12px;"><%=p.getId()%></td>
        <td><img class="prod-img" src="<%=imgSrc%>" onerror="this.src='images/default.png'" alt="<%=p.getName()%>"></td>
        <td><b><%=p.getName()%></b></td>
        <td><b>₹<%=String.format("%.2f",p.getPrice())%></b></td>
        <td><%=p.getQuantity()%></td>
        <td><span class="cat-badge cat-<%=cat.replace(" ","-")%>"><%=p.getCategory()%></span></td>
        <td><span style="font-size:12px;color:var(--muted);"><%=wDisplay%></span></td>
        <td>
          <% if(p.getQuantity() < 5){ %>
          <span class="stock-badge low-stock"><i class="fa fa-triangle-exclamation"></i> Low</span>
          <% } else { %>
          <span class="stock-badge in-stock">In Stock</span>
          <% } %>
        </td>
        <% if(isAdmin){ %>
        <td>
          <a class="action-btn btn-edit" href="edit-product.jsp?id=<%=p.getId()%>"><i class="fa fa-pen"></i> Edit</a>
          <button class="btn-del" onclick="confirmDelete(<%=p.getId()%>,'<%=p.getName()%>')"><i class="fa fa-trash"></i></button>
        </td>
        <% } %>
      </tr>
      <% } } %>
      </tbody>
    </table>
  </div>
</div>

<!-- DELETE MODAL -->
<div class="modal-overlay" id="deleteModal">
  <div class="modal">
    <h3>Delete Product</h3>
    <p id="deleteMsg">Are you sure you want to delete this product?</p>
    <div class="modal-actions">
      <button class="modal-cancel" onclick="closeModal()">Cancel</button>
      <a id="deleteLink" href="#"><button class="modal-confirm" type="button">Delete</button></a>
    </div>
  </div>
</div>

<script>
function toggleDark(){
  const h=document.documentElement,d=h.getAttribute('data-theme')==='dark';
  h.setAttribute('data-theme',d?'light':'dark');
  localStorage.setItem('sibs-theme',d?'light':'dark');
}
(function(){const t=localStorage.getItem('sibs-theme');if(t)document.documentElement.setAttribute('data-theme',t);})();

let activeCategory = 'ALL';
function setCategory(cat, btn){
  activeCategory = cat;
  document.querySelectorAll('.cat-pill').forEach(b=>b.classList.remove('active'));
  btn.classList.add('active');
  applyFilters();
}
function applyFilters(){
  const q = document.getElementById('searchInput').value.toLowerCase();
  document.querySelectorAll('#productTable tr').forEach(row=>{
    const name = row.getAttribute('data-name')||'';
    const cat  = row.getAttribute('data-category')||'';
    const mQ = !q || name.includes(q);
    const mC = activeCategory==='ALL' || cat===activeCategory;
    row.style.display = (mQ && mC) ? '' : 'none';
  });
}
function confirmDelete(id, name){
  document.getElementById('deleteMsg').textContent = 'Delete "'+name+'"? This action cannot be undone.';
  document.getElementById('deleteLink').href = '<%=request.getContextPath()%>/deleteProduct?id='+id;
  document.getElementById('deleteModal').classList.add('open');
}
function closeModal(){document.getElementById('deleteModal').classList.remove('open');}
document.getElementById('deleteModal').addEventListener('click',function(e){if(e.target===this)closeModal();});
</script>
</body>
</html>
