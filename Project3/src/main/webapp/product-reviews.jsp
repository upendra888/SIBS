<%@ page language="java" contentType="text/html; charset=UTF-8" %>
<%@ page import="java.util.*, com.sibs.dao.ProductReviewDAO, com.sibs.dao.ProductDAO, com.sibs.model.Product, com.sibs.model.User" %>
<%
User user = (User)session.getAttribute("customer");
if(user == null){ response.sendRedirect("customer-login.jsp"); return; }

String pidStr = request.getParameter("productId");
if(pidStr == null){ response.sendRedirect("customer-dashboard.jsp"); return; }

int productId = 0;
try { productId = Integer.parseInt(pidStr.trim()); } catch(Exception e){ response.sendRedirect("customer-dashboard.jsp"); return; }

ProductDAO pDao = new ProductDAO();
Product product = pDao.getProductById(productId);
if(product == null){ response.sendRedirect("customer-dashboard.jsp"); return; }

ProductReviewDAO reviewDAO = new ProductReviewDAO();
double[] ratingInfo = reviewDAO.getProductRating(productId);
List<String[]> reviews = reviewDAO.getProductReviews(productId);
List<String[]> pending = reviewDAO.getPendingReviewsForUser(user.getId());
List<String[]> myReviews = reviewDAO.getMyReviews(user.getId());

// Check if this product has a pending (unreviewed) order and get its orderId
int pendingOrderId = 0;
for(String[] pr : pending){
  if(Integer.parseInt(pr[1]) == productId){
    pendingOrderId = Integer.parseInt(pr[0]);
    break;
  }
}

// Check if already reviewed this product (any order)
boolean alreadyReviewed = false;
int myRating = 0;
String myText = "";
for(String[] mr : myReviews){
  if(Integer.parseInt(mr[0]) == productId){
    alreadyReviewed = true;
    myRating = Integer.parseInt(mr[3]);
    myText = mr[4] != null ? mr[4] : "";
    break;
  }
}

String img = (product.getImagePath() != null && !product.getImagePath().trim().isEmpty())
  ? request.getContextPath()+"/"+product.getImagePath()
  : request.getContextPath()+"/images/default.png";
%>
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title><%=product.getName()%> — Reviews</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<style>
:root{--bg:#f8fafc;--surface:#fff;--border:#e2e8f0;--text:#0f172a;--muted:#64748b;--primary:#2563eb;--success:#16a34a;--warn:#f59e0b;}
[data-theme="dark"]{--bg:#0f172a;--surface:#1e293b;--border:#334155;--text:#f1f5f9;--muted:#94a3b8;}
*{margin:0;padding:0;box-sizing:border-box;font-family:'Inter',sans-serif;}
body{background:var(--bg);color:var(--text);min-height:100vh;}
.topbar{background:var(--surface);border-bottom:1px solid var(--border);padding:0 20px;height:58px;display:flex;align-items:center;gap:12px;position:sticky;top:0;z-index:100;box-shadow:0 1px 4px rgba(0,0,0,.07);}
.topbar .back{display:flex;align-items:center;gap:8px;color:var(--text);text-decoration:none;font-weight:600;font-size:14px;}
.topbar .back:hover{color:var(--primary);}
.topbar h1{font-size:16px;font-weight:700;}
.dark-btn{background:none;border:1px solid var(--border);width:34px;height:34px;border-radius:8px;cursor:pointer;color:var(--muted);margin-left:auto;}
.container{max-width:640px;margin:0 auto;padding:24px 20px;}

/* Product info */
.product-card{background:var(--surface);border:1px solid var(--border);border-radius:12px;padding:16px;margin-bottom:20px;display:flex;gap:14px;align-items:center;}
.product-card img{width:64px;height:64px;object-fit:cover;border-radius:8px;border:1px solid var(--border);}
.product-name{font-size:15px;font-weight:700;}
.product-cat{font-size:12px;color:var(--muted);margin-top:2px;}

/* Rating summary */
.rating-summary{background:var(--surface);border:1px solid var(--border);border-radius:12px;padding:20px;margin-bottom:20px;display:flex;align-items:center;gap:20px;}
.big-rating{text-align:center;min-width:80px;}
.big-num{font-size:42px;font-weight:700;line-height:1;color:var(--warn);}
.stars-row{font-size:16px;margin:4px 0;}
.star-filled{color:#f59e0b;}
.star-empty{color:#d1d5db;}
.rating-count{font-size:12px;color:var(--muted);}
.rating-bars{flex:1;}
.bar-row{display:flex;align-items:center;gap:8px;margin-bottom:5px;}
.bar-label{font-size:11px;width:14px;text-align:right;color:var(--muted);}
.bar-track{flex:1;height:6px;background:var(--bg);border-radius:3px;overflow:hidden;}
.bar-fill{height:100%;background:#f59e0b;border-radius:3px;transition:.3s;}
.bar-count{font-size:11px;color:var(--muted);width:20px;}

/* Review form */
.form-card{background:var(--surface);border:1px solid var(--border);border-radius:12px;padding:20px;margin-bottom:20px;}
.form-title{font-size:14px;font-weight:700;margin-bottom:14px;display:flex;align-items:center;gap:6px;}
.star-select{display:flex;gap:6px;margin-bottom:14px;}
.star-select i{font-size:28px;cursor:pointer;color:#d1d5db;transition:.15s;}
.star-select i.active, .star-select i:hover{color:#f59e0b;}
textarea.review-input{width:100%;border:1px solid var(--border);border-radius:8px;padding:10px 12px;font-family:'Inter',sans-serif;font-size:13px;color:var(--text);background:var(--bg);resize:vertical;min-height:90px;outline:none;transition:.15s;}
textarea.review-input:focus{border-color:var(--primary);}
.submit-btn{background:var(--primary);color:#fff;border:none;border-radius:8px;padding:10px 22px;font-size:14px;font-weight:600;cursor:pointer;margin-top:10px;transition:.15s;}
.submit-btn:hover{opacity:.9;}
.login-prompt{font-size:13px;color:var(--muted);padding:12px;background:var(--bg);border-radius:8px;text-align:center;}
.login-prompt a{color:var(--primary);font-weight:600;}
.no-purchase{font-size:13px;color:var(--muted);padding:12px;background:var(--bg);border-radius:8px;text-align:center;}

/* Reviews list */
.section-title{font-size:14px;font-weight:700;margin-bottom:12px;display:flex;align-items:center;gap:6px;}
.review-item{background:var(--surface);border:1px solid var(--border);border-radius:10px;padding:14px 16px;margin-bottom:10px;}
.reviewer-row{display:flex;align-items:center;justify-content:space-between;margin-bottom:6px;}
.reviewer-name{font-size:13px;font-weight:600;}
.review-stars{font-size:13px;}
.review-text{font-size:13px;color:var(--muted);line-height:1.5;margin-top:4px;}
.review-date{font-size:11px;color:var(--muted);margin-top:6px;}
.no-reviews{text-align:center;padding:32px 20px;color:var(--muted);font-size:13px;}
.no-reviews i{font-size:28px;display:block;margin-bottom:8px;opacity:.4;}

#toast{position:fixed;bottom:24px;right:24px;background:#0f172a;color:#fff;padding:10px 16px;border-radius:10px;font-size:13px;display:none;align-items:center;gap:8px;z-index:999;}
#toast.show{display:flex;}
</style>
</head>
<body>
<div class="topbar">
  <a class="back" href="customer-dashboard.jsp"><i class="fa fa-arrow-left"></i></a>
  <h1>Product Reviews</h1>
  <button class="dark-btn" onclick="toggleDark()"><i class="fa fa-moon"></i></button>
</div>

<div class="container">

  <!-- Product Info -->
  <div class="product-card">
    <img src="<%=img%>" alt="<%=product.getName()%>" onerror="this.src='images/default.png'">
    <div>
      <div class="product-name"><%=product.getName()%></div>
      <div class="product-cat"><%=product.getCategory() != null ? product.getCategory() : ""%> · ₹<%=(int)product.getPrice()%>/<%=product.getUnit()!=null?product.getUnit():"unit"%></div>
    </div>
  </div>

  <!-- Rating Summary -->
  <%
  double avgRating = ratingInfo[0];
  int totalReviews = (int)ratingInfo[1];
  // Count per star
  int[] starCounts = new int[6]; // index 1-5
  for(String[] rv : reviews){
    int r = 0; try{ r = Integer.parseInt(rv[1]); }catch(Exception _e){}
    if(r>=1&&r<=5) starCounts[r]++;
  }
  %>
  <div class="rating-summary">
    <div class="big-rating">
      <div class="big-num"><%=totalReviews>0 ? String.format("%.1f",avgRating) : "-"%></div>
      <div class="stars-row">
        <% for(int s=1;s<=5;s++){ %>
          <i class="fa fa-star <%=(s<=Math.round(avgRating))?"star-filled":"star-empty"%>"></i>
        <% } %>
      </div>
      <div class="rating-count"><%=totalReviews%> review<%=totalReviews!=1?"s":""%></div>
    </div>
    <div class="rating-bars">
      <% for(int s=5;s>=1;s--){ int cnt = starCounts[s]; int pct = totalReviews>0?(cnt*100/totalReviews):0; %>
      <div class="bar-row">
        <span class="bar-label"><%=s%></span>
        <div class="bar-track"><div class="bar-fill" style="width:<%=pct%>%;"></div></div>
        <span class="bar-count"><%=cnt%></span>
      </div>
      <% } %>
    </div>
  </div>

  <!-- Write Review -->
  <div class="form-card">
    <div class="form-title"><i class="fa fa-pen-to-square" style="color:var(--primary);"></i>
      <%=alreadyReviewed ? "Edit Your Review" : "Write a Review"%>
    </div>
    <% if(pendingOrderId > 0 || alreadyReviewed){ %>
    <div class="star-select" id="starSelect">
      <% for(int s=1;s<=5;s++){ %>
      <i class="fa fa-star <%=(alreadyReviewed && s<=myRating)?"active":""%>" data-val="<%=s%>" onclick="selectStar(<%=s%>)"></i>
      <% } %>
    </div>
    <textarea class="review-input" id="reviewText" placeholder="Share your experience with this product..."><%=myText%></textarea>
    <br>
    <button class="submit-btn" onclick="submitReview()"><i class="fa fa-paper-plane"></i> <%=alreadyReviewed?"Update Review":"Submit Review"%></button>
    <% } else { %>
    <div class="no-purchase">
      <i class="fa fa-box" style="color:var(--muted);display:inline;"></i>
      You can only review products from <strong>delivered orders</strong>.
      <a href="my-orders.jsp">View your orders →</a>
    </div>
    <% } %>
  </div>

  <!-- Reviews List -->
  <div class="section-title"><i class="fa fa-comments" style="color:var(--muted);"></i> Customer Reviews</div>
  <% if(reviews.isEmpty()){ %>
  <div class="no-reviews">
    <i class="fa fa-star"></i>
    <p>No reviews yet. Be the first to review this product!</p>
  </div>
  <% } else { for(String[] rv : reviews){
    int rVal = 0; try{ rVal = Integer.parseInt(rv[1]); }catch(Exception _e){}
    String rvDate = rv[3] != null && rv[3].length()>=10 ? rv[3].substring(0,10) : "";
  %>
  <div class="review-item">
    <div class="reviewer-row">
      <span class="reviewer-name"><%=rv[0] != null ? rv[0] : "Customer"%></span>
      <span class="review-stars">
        <% for(int s=1;s<=5;s++){ %><i class="fa fa-star <%=s<=rVal?"star-filled":"star-empty"%>"></i><% } %>
      </span>
    </div>
    <% if(rv[2] != null && !rv[2].trim().isEmpty()){ %>
    <div class="review-text"><%=rv[2]%></div>
    <% } %>
    <div class="review-date"><%=rvDate%></div>
  </div>
  <% } } %>

</div>

<div id="toast"><i class="fa fa-check-circle"></i> <span id="toastMsg"></span></div>

<script>
var _CTX = '<%=request.getContextPath()%>';
var selectedRating = <%=alreadyReviewed ? myRating : 0%>;
var productId = <%=productId%>;
var orderId = <%=pendingOrderId > 0 ? pendingOrderId : (alreadyReviewed ? -1 : 0)%>;

function selectStar(val){
  selectedRating = val;
  document.querySelectorAll('#starSelect i').forEach((s,i)=>{
    s.classList.toggle('active', i < val);
  });
}

function submitReview(){
  if(selectedRating < 1){ showToast('Please select a star rating'); return; }
  var text = document.getElementById('reviewText').value.trim();
  // For edit mode, we need to find orderId from myReviews — send productId only, servlet handles it
  var body = 'productId='+productId+'&orderId='+(orderId>0?orderId:0)+'&rating='+selectedRating+'&reviewText='+encodeURIComponent(text);
  fetch(_CTX+'/productReview',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:body})
  .then(r=>r.json()).then(data=>{
    showToast(data.message || (data.success?'Review saved!':'Failed'));
    if(data.success) setTimeout(()=>location.reload(),1500);
  }).catch(()=>showToast('Error submitting review'));
}

function showToast(msg){
  var t=document.getElementById('toast');
  document.getElementById('toastMsg').textContent=msg;
  t.classList.add('show');
  setTimeout(()=>t.classList.remove('show'),2800);
}

function toggleDark(){
  var html = document.documentElement;
  html.setAttribute('data-theme', html.getAttribute('data-theme')==='dark'?'light':'dark');
  localStorage.setItem('sibsTheme', html.getAttribute('data-theme'));
}
document.addEventListener('DOMContentLoaded',()=>{
  var t=localStorage.getItem('sibsTheme');
  if(t) document.documentElement.setAttribute('data-theme',t);
  // Restore star selection
  if(selectedRating>0) selectStar(selectedRating);
});
</script>
</body>
</html>
