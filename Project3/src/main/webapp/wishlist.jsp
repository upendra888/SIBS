<%@ page language="java" contentType="text/html; charset=UTF-8" %>
<%@ page import="java.util.*, com.sibs.dao.WishlistDAO, com.sibs.model.Product, com.sibs.model.User" %>
<%
User user = (User)session.getAttribute("customer");
if(user == null){ response.sendRedirect("customer-login.jsp"); return; }
WishlistDAO wishDAO = new WishlistDAO();
List<Product> wishlist = wishDAO.getWishlistProducts(user.getId());
%>
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>My Wishlist — SIBS</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<style>
:root{--bg:#f8fafc;--surface:#fff;--border:#e2e8f0;--text:#0f172a;--muted:#64748b;--primary:#2563eb;--danger:#ef4444;}
[data-theme="dark"]{--bg:#0f172a;--surface:#1e293b;--border:#334155;--text:#f1f5f9;--muted:#94a3b8;}
*{margin:0;padding:0;box-sizing:border-box;font-family:'Inter',sans-serif;}
body{background:var(--bg);color:var(--text);min-height:100vh;}
.topbar{background:var(--surface);border-bottom:1px solid var(--border);padding:0 20px;height:58px;display:flex;align-items:center;gap:12px;position:sticky;top:0;z-index:100;box-shadow:0 1px 4px rgba(0,0,0,.07);}
.topbar .back{display:flex;align-items:center;gap:8px;color:var(--text);text-decoration:none;font-weight:600;font-size:14px;}
.topbar .back:hover{color:var(--primary);}
.topbar h1{font-size:16px;font-weight:700;margin-left:4px;}
.dark-btn{background:none;border:1px solid var(--border);width:34px;height:34px;border-radius:8px;cursor:pointer;color:var(--muted);margin-left:auto;}
.container{max-width:900px;margin:0 auto;padding:24px 20px;}
.page-header{display:flex;align-items:center;justify-content:space-between;margin-bottom:24px;}
.page-header h2{font-size:20px;font-weight:700;display:flex;align-items:center;gap:8px;}
.page-header h2 i{color:#e11d48;}
.count-badge{background:#fee2e2;color:#dc2626;border-radius:999px;padding:2px 10px;font-size:12px;font-weight:700;}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(200px,1fr));gap:16px;}
.card{background:var(--surface);border:1px solid var(--border);border-radius:12px;overflow:hidden;transition:.15s;}
.card:hover{box-shadow:0 4px 16px rgba(0,0,0,.1);transform:translateY(-2px);}
.card-img{height:150px;background:#f1f5f9;position:relative;overflow:hidden;}
.card-img img{width:100%;height:100%;object-fit:cover;}
.stock-badge{position:absolute;top:8px;left:8px;font-size:10px;font-weight:700;padding:2px 8px;border-radius:4px;}
.in-stock{background:#dcfce7;color:#16a34a;}
.out-stock{background:#fee2e2;color:#dc2626;}
.remove-btn{position:absolute;top:8px;right:8px;width:30px;height:30px;border-radius:50%;background:rgba(255,255,255,.9);border:none;cursor:pointer;color:#e11d48;font-size:14px;display:flex;align-items:center;justify-content:center;transition:.15s;}
.remove-btn:hover{background:#fee2e2;transform:scale(1.1);}
.card-body{padding:12px;}
.card-name{font-weight:600;font-size:13px;margin-bottom:4px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;}
.card-desc{font-size:11px;color:var(--muted);margin-bottom:6px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;}
.card-price{font-size:15px;font-weight:700;color:var(--primary);margin-bottom:10px;}
.card-price span{font-size:11px;font-weight:400;color:var(--muted);}
.card-actions{display:flex;gap:6px;}
.btn-cart{flex:1;padding:7px;border:1px solid var(--primary);color:var(--primary);background:none;border-radius:7px;font-size:12px;font-weight:600;cursor:pointer;transition:.15s;}
.btn-cart:hover:not(:disabled){background:var(--primary);color:#fff;}
.btn-cart:disabled{opacity:0.5;cursor:not-allowed;}
.btn-buy{flex:1;padding:7px;background:var(--primary);color:#fff;border:none;border-radius:7px;font-size:12px;font-weight:600;cursor:pointer;transition:.15s;}
.btn-buy:hover:not(:disabled){opacity:0.9;}
.btn-buy:disabled{opacity:0.5;cursor:not-allowed;}
.empty-state{text-align:center;padding:80px 20px;color:var(--muted);}
.empty-state i{font-size:56px;display:block;margin-bottom:16px;color:#fbbf24;}
.empty-state h3{font-size:18px;font-weight:600;margin-bottom:8px;color:var(--text);}
.empty-state p{font-size:14px;margin-bottom:20px;}
.empty-state a{display:inline-block;background:var(--primary);color:#fff;padding:10px 24px;border-radius:8px;text-decoration:none;font-weight:600;font-size:14px;}
#toast{position:fixed;bottom:24px;right:24px;background:#0f172a;color:#fff;padding:10px 16px;border-radius:10px;font-size:13px;display:none;align-items:center;gap:8px;z-index:999;box-shadow:0 4px 16px rgba(0,0,0,.25);}
#toast.show{display:flex;}
</style>
</head>
<body>
<div class="topbar">
  <a class="back" href="customer-dashboard.jsp"><i class="fa fa-arrow-left"></i></a>
  <h1><i class="fa fa-heart" style="color:#e11d48;margin-right:6px;"></i>My Wishlist</h1>
  <button class="dark-btn" onclick="toggleDark()" title="Toggle dark mode"><i class="fa fa-moon"></i></button>
</div>

<div class="container">
  <div class="page-header">
    <h2><i class="fa fa-heart"></i> Saved Items <span class="count-badge"><%=wishlist.size()%></span></h2>
  </div>

  <% if(wishlist.isEmpty()){ %>
  <div class="empty-state">
    <i class="fa fa-heart"></i>
    <h3>Your wishlist is empty</h3>
    <p>Tap the ♡ heart on any product to save it here for later.</p>
    <a href="customer-dashboard.jsp"><i class="fa fa-arrow-left"></i> Browse Products</a>
  </div>
  <% } else { %>
  <div class="grid" id="wishGrid">
  <% for(Product p : wishlist) {
    String img = (p.getImagePath() != null && !p.getImagePath().trim().isEmpty())
      ? request.getContextPath()+"/"+p.getImagePath()
      : request.getContextPath()+"/images/default.png";
    boolean inStock = p.isInStock();
  %>
    <div class="card" id="wcard_<%=p.getId()%>">
      <div class="card-img">
        <img src="<%=img%>" alt="<%=p.getName()%>" onerror="this.src='images/default.png'">
        <span class="stock-badge <%=inStock?"in-stock":"out-stock"%>">
          <%=inStock?"In Stock":"Out of Stock"%>
        </span>
        <button class="remove-btn" onclick="removeWishlist(<%=p.getId()%>)" title="Remove from wishlist">
          <i class="fa fa-heart-broken"></i>
        </button>
      </div>
      <div class="card-body">
        <div class="card-name" title="<%=p.getName()%>"><%=p.getName()%></div>
        <% if(p.getDescription() != null && !p.getDescription().trim().isEmpty()){ %>
        <div class="card-desc" title="<%=p.getDescription()%>"><%=p.getDescription()%></div>
        <% } %>
        <div class="card-price">₹<%=(int)p.getPrice()%> <span>/ <%=p.getUnit() != null ? p.getUnit() : "unit"%></span></div>
        <div class="card-actions">
          <button class="btn-cart" <%=!inStock?"disabled":""%>
            onclick="addToCart(<%=p.getId()%>,'<%=p.getName().replace("'","\'")%>',<%=p.getPrice()%>,'<%=p.getImagePath()!=null?p.getImagePath():""%>')">
            <i class="fa fa-cart-plus"></i> Cart
          </button>
          <% if(inStock){ %>
          <form action="buyNow" method="post" style="flex:1;">
            <input type="hidden" name="productId" value="<%=p.getId()%>">
            <input type="hidden" name="qty" value="1">
            <button type="submit" class="btn-buy" style="width:100%;">Buy Now</button>
          </form>
          <% } else { %>
          <button class="btn-buy" disabled style="flex:1;">Out of Stock</button>
          <% } %>
        </div>
      </div>
    </div>
  <% } %>
  </div>
  <% } %>
</div>

<div id="toast"><i class="fa fa-check-circle"></i> <span id="toastMsg"></span></div>

<script>
var _CTX = '<%=request.getContextPath()%>';

function removeWishlist(productId){
  fetch(_CTX+'/wishlist?action=toggle',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:'action=toggle&productId='+productId})
  .then(r=>r.json()).then(data=>{
    if(data.status === 'REMOVED'){
      var card = document.getElementById('wcard_'+productId);
      if(card){ card.style.opacity='0'; card.style.transform='scale(0.9)'; card.style.transition='0.3s'; setTimeout(()=>{ card.remove(); updateCount(); },300); }
      showToast('Removed from wishlist');
    }
  }).catch(()=>showToast('Error, please try again'));
}

function updateCount(){
  var cards = document.querySelectorAll('.card');
  document.querySelector('.count-badge').textContent = cards.length;
  if(cards.length === 0){
    document.getElementById('wishGrid').style.display='none';
    document.querySelector('.empty-state') && (document.querySelector('.empty-state').style.display='block');
    location.reload();
  }
}

function addToCart(id, name, price, img){
  fetch(_CTX+'/addToCart',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},
    body:'productId='+id+'&qty=1'})
  .then(r=>{ if(r.ok||r.status==200) showToast(name+' added to cart!'); else showToast('Could not add to cart'); })
  .catch(()=>showToast('Error adding to cart'));
}

function showToast(msg){
  var t = document.getElementById('toast');
  document.getElementById('toastMsg').textContent = msg;
  t.classList.add('show');
  setTimeout(()=>t.classList.remove('show'),2500);
}

function toggleDark(){
  var html = document.documentElement;
  html.setAttribute('data-theme', html.getAttribute('data-theme')==='dark'?'light':'dark');
  localStorage.setItem('sibsTheme', html.getAttribute('data-theme'));
}
document.addEventListener('DOMContentLoaded',()=>{
  var t=localStorage.getItem('sibsTheme');
  if(t) document.documentElement.setAttribute('data-theme',t);
});
</script>
</body>
</html>
