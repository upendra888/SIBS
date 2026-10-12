<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, com.sibs.dao.ProductDAO, com.sibs.model.Product, com.sibs.model.User" %>
<%
User user = (User)session.getAttribute("customer");
if(user == null){
    response.sendRedirect("customer-login.jsp");
    return;
}
String query = request.getParameter("q");
if(query == null) query = "";
query = query.trim();

ProductDAO dao = new ProductDAO();
List<Product> all = dao.getAllProducts();
List<Product> results = new ArrayList<>();
if(!query.isEmpty() && all != null){
    String ql = query.toLowerCase();
    for(Product p : all){
        if((p.getName() != null && p.getName().toLowerCase().contains(ql)) ||
           (p.getCategory() != null && p.getCategory().toLowerCase().contains(ql))){
            results.add(p);
        }
    }
}
%>
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Search: <%=query%> — SIBS</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<style>
:root{--bg:#f8fafc;--surface:#fff;--border:#e2e8f0;--text:#0f172a;--muted:#64748b;--primary:#2563eb;--danger:#ef4444;--success:#16a34a;}
[data-theme="dark"]{--bg:#0f172a;--surface:#1e293b;--border:#334155;--text:#f1f5f9;--muted:#94a3b8;}
*{margin:0;padding:0;box-sizing:border-box;font-family:'Inter',sans-serif;}
body{background:var(--bg);color:var(--text);}
.topbar{background:var(--surface);border-bottom:1px solid var(--border);padding:0 20px;height:58px;display:flex;align-items:center;gap:12px;position:sticky;top:0;z-index:50;box-shadow:0 1px 4px rgba(0,0,0,.07);}
.logo{font-weight:700;font-size:18px;color:var(--primary);white-space:nowrap;text-decoration:none;}
.search-form{flex:1;max-width:500px;display:flex;gap:8px;}
.search-form input{flex:1;padding:9px 14px;border:1px solid var(--border);border-radius:8px;background:var(--bg);color:var(--text);font-size:13px;outline:none;}
.search-form input:focus{border-color:var(--primary);}
.search-form button{padding:9px 16px;background:var(--primary);color:#fff;border:none;border-radius:8px;cursor:pointer;font-size:13px;font-weight:500;}
.topbar-right{margin-left:auto;display:flex;gap:8px;align-items:center;}
.dark-btn{background:none;border:1px solid var(--border);width:34px;height:34px;border-radius:8px;cursor:pointer;color:var(--muted);}

.content{max-width:1100px;margin:28px auto;padding:0 20px;}
.result-meta{font-size:14px;color:var(--muted);margin-bottom:20px;}
.result-meta b{color:var(--text);}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(185px,1fr));gap:16px;}
.card{background:var(--surface);border:1px solid var(--border);border-radius:12px;overflow:hidden;transition:.2s;}
.card:hover{box-shadow:0 6px 20px rgba(0,0,0,.1);transform:translateY(-2px);}
.card-img{height:140px;display:flex;align-items:center;justify-content:center;background:var(--bg);padding:10px;}
.card-img img{max-height:120px;max-width:100%;object-fit:contain;}
.card-body{padding:12px;}
.card-name{font-size:13px;font-weight:600;margin-bottom:3px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;}
.card-cat{font-size:11px;color:var(--muted);margin-bottom:6px;}
.card-price{font-size:16px;font-weight:700;color:var(--danger);margin-bottom:8px;}
.btn-add{width:100%;padding:8px;background:var(--primary);color:#fff;border:none;border-radius:7px;cursor:pointer;font-size:12px;font-weight:500;transition:.15s;}
.btn-add:hover{background:#1d4ed8;}
.empty{text-align:center;padding:60px;color:var(--muted);}
.empty i{font-size:40px;margin-bottom:14px;}
.empty h3{font-size:16px;margin-bottom:6px;}
#toast{position:fixed;bottom:24px;right:24px;padding:12px 18px;border-radius:8px;font-size:13px;font-weight:500;display:none;z-index:9999;background:#16a34a;color:#fff;box-shadow:0 4px 12px rgba(0,0,0,.2);}
</style>
</head>
<body>
<div class="topbar">
  <a class="logo" href="customer-dashboard.jsp"><i class="fa fa-cubes"></i> SIBS</a>
  <form class="search-form" action="search.jsp" method="get">
    <input type="text" name="q" value="<%=query%>" placeholder="Search products..." autofocus>
    <button type="submit"><i class="fa fa-search"></i> Search</button>
  </form>
  <div class="topbar-right">
    <a href="cart.jsp" style="color:var(--primary);font-size:13px;font-weight:500;text-decoration:none;"><i class="fa fa-cart-shopping"></i> Cart</a>
    <button class="dark-btn" onclick="toggleDark()"><i class="fa fa-moon"></i></button>
  </div>
</div>

<div class="content">
  <% if(!query.isEmpty()){ %>
  <div class="result-meta">
    Showing <b><%=results.size()%></b> result(s) for "<b><%=query%></b>"
    &nbsp;·&nbsp; <a href="customer-dashboard.jsp" style="color:var(--primary);font-size:13px;">Back to Shop</a>
  </div>
  <% } %>

  <% if(query.isEmpty()){ %>
  <div class="empty"><i class="fa fa-search"></i><h3>Search for products</h3><p>Type a product name or category above</p></div>
  <% } else if(results.isEmpty()){ %>
  <div class="empty">
    <i class="fa fa-box-open"></i>
    <h3>No results for "<%=query%>"</h3>
    <p style="margin-bottom:16px;">Try a different keyword or browse all products</p>
    <a href="customer-dashboard.jsp" style="color:var(--primary);font-weight:600;">Browse All Products →</a>
  </div>
  <% } else { %>
  <div class="grid">
  <%
  for(Product p : results){
  %>
    <div class="card">
      <div class="card-img">
        <% if(p.getImagePath() != null && !p.getImagePath().isEmpty()){ %>
        <img src="<%=p.getImagePath()%>" alt="<%=p.getName()%>">
        <% } else { %>
        <i class="fa fa-box" style="font-size:50px;color:var(--border);"></i>
        <% } %>
      </div>
      <div class="card-body">
        <div class="card-name"><%=p.getName()%></div>
        <div class="card-cat"><%=p.getCategory() != null ? p.getCategory() : "—"%></div>
        <div class="card-price">₹<%=String.format("%.2f", p.getPrice())%></div>
        <% if(p.getQuantity() > 0){ %>
        <form action="addToCart" method="post" onsubmit="handleCart(event,this)">
          <input type="hidden" name="productId" value="<%=p.getId()%>">
          <input type="hidden" name="quantity" value="1">
          <input type="hidden" name="price" value="<%=p.getPrice()%>">
          <button type="submit" class="btn-add"><i class="fa fa-cart-plus"></i> Add to Cart</button>
        </form>
        <% } else { %>
        <button class="btn-add" disabled style="background:var(--muted);cursor:not-allowed;">Out of Stock</button>
        <% } %>
      </div>
    </div>
  <%  } %>
  </div>
  <% } %>
</div>

<div id="toast"></div>
<script>
function toggleDark(){
  const h=document.documentElement,d=h.getAttribute('data-theme')==='dark';
  h.setAttribute('data-theme',d?'light':'dark');
  localStorage.setItem('sibs-theme',d?'light':'dark');
}
(function(){const t=localStorage.getItem('sibs-theme');if(t)document.documentElement.setAttribute('data-theme',t);})();
function showToast(msg){
  const t=document.getElementById('toast');
  t.textContent=msg; t.style.display='block';
  setTimeout(()=>t.style.display='none',3000);
}
function handleCart(e,form){
  e.preventDefault();
  const fd=new FormData(form);
  fetch('addToCart',{method:'POST',body:new URLSearchParams(fd)})
    .then(r=>{if(r.ok||r.redirected)showToast('Added to cart!');})
    .catch(()=>showToast('Added to cart!'));
}
</script>
</body>
</html>
