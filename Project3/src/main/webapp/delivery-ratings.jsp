<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.util.*,com.sibs.dao.DeliveryRatingDAO,com.sibs.dao.DeliveryRatingDAO.Rating,com.sibs.model.DeliveryBoy" %>
<%
DeliveryBoy db = (DeliveryBoy)session.getAttribute("deliveryBoy");
if(db == null){ response.sendRedirect("delivery-login.jsp"); return; }

DeliveryRatingDAO dao = new DeliveryRatingDAO();
List<Rating> ratings = dao.getRatingsForRider(db.getId());
double avg = dao.getAvgRating(db.getId());
int total = ratings.size();
int[] starCount = new int[6];
for(Rating r: ratings) if(r.stars>=1&&r.stars<=5) starCount[r.stars]++;
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>My Ratings · SIBS</title>
<link href="https://fonts.googleapis.com/css2?family=Syne:wght@600;700;800&family=DM+Sans:wght@400;500;600&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<style>
:root{--brand:#7c3aed;--brand-light:#ede9fe;--surface:#fff;--bg:#f3f1fb;--bg2:#edeaf8;
  --text:#0d0d14;--muted:#6b6882;--border:rgba(124,58,237,.12);--green:#16a34a;--green-bg:#dcfce7;
  --amber:#f59e0b;--radius:14px;--radius-sm:9px;
  --ff-head:'Syne',sans-serif;--ff-body:'DM Sans',sans-serif;}
*,*::before,*::after{margin:0;padding:0;box-sizing:border-box;}
html{font-family:var(--ff-body);background:var(--bg);color:var(--text);}
body{padding-bottom:80px;}
.topbar{background:var(--surface);border-bottom:1px solid var(--border);padding:0 18px;height:56px;
  display:flex;align-items:center;gap:12px;position:sticky;top:0;z-index:100;}
.back-btn{color:var(--muted);font-size:14px;text-decoration:none;}
.topbar-title{font-family:var(--ff-head);font-size:16px;font-weight:700;flex:1;}
.page{max-width:600px;margin:0 auto;padding:16px;}
.rating-hero{background:linear-gradient(135deg,#2e1065,#4c1d95,#6d28d9);border-radius:var(--radius);
  padding:24px;color:#fff;display:flex;align-items:center;gap:20px;margin-bottom:16px;}
.rating-num{font-family:var(--ff-head);font-size:56px;font-weight:800;line-height:1;color:#fde68a;}
.rating-info{flex:1;}
.stars-display{font-size:22px;color:#fcd34d;margin-bottom:4px;}
.rating-sub{font-size:12px;opacity:.6;}
.bars{flex:1;}
.bar-row{display:flex;align-items:center;gap:8px;margin-bottom:5px;}
.bar-lbl{font-size:11px;opacity:.7;width:12px;text-align:right;}
.bar-track{flex:1;height:6px;background:rgba(255,255,255,.15);border-radius:999px;overflow:hidden;}
.bar-fill{height:100%;background:#fcd34d;border-radius:999px;}
.bar-count{font-size:11px;opacity:.6;width:20px;}
.section-h{font-family:var(--ff-head);font-size:14px;font-weight:700;margin-bottom:10px;}
.review-card{background:var(--surface);border:1px solid var(--border);border-radius:var(--radius);
  padding:14px 16px;margin-bottom:10px;}
.review-top{display:flex;justify-content:space-between;align-items:center;margin-bottom:6px;}
.review-name{font-weight:600;font-size:13px;}
.review-stars{color:#f59e0b;font-size:13px;}
.review-date{font-size:11px;color:var(--muted);}
.review-comment{font-size:13px;color:var(--muted);line-height:1.5;}
.empty{text-align:center;padding:40px;color:var(--muted);}
/* Bottom nav */
.bottom-nav{position:fixed;bottom:0;left:0;right:0;background:var(--surface);
  border-top:1px solid var(--border);display:flex;justify-content:space-around;padding:8px 0 12px;z-index:100;}
.nav-item{display:flex;flex-direction:column;align-items:center;gap:3px;cursor:pointer;
  padding:4px 12px;color:var(--muted);text-decoration:none;}
.nav-item.active{color:var(--brand);}
.nav-item i{font-size:18px;}
.nav-label{font-size:10px;font-weight:500;}
</style>
</head>
<body>
<div class="topbar">
  <a href="delivery-dashboard.jsp" class="back-btn"><i class="fa fa-arrow-left"></i></a>
  <span class="topbar-title">My Ratings</span>
</div>

<div class="page">
  <div class="rating-hero">
    <div class="rating-num"><%=total>0?String.format("%.1f",avg):"–"%></div>
    <div class="rating-info">
      <div class="stars-display">
        <% for(int i=1;i<=5;i++){
          if(avg>=i) out.print("<i class='fa fa-star'></i>");
          else if(avg>=i-0.5) out.print("<i class='fa fa-star-half-stroke'></i>");
          else out.print("<i class='fa fa-star' style='opacity:.3;'></i>");
        }%>
      </div>
      <div style="font-size:13px;margin-top:2px;"><%=total%> rating<%=total!=1?"s":""%></div>
      <div class="rating-sub">Based on customer feedback</div>
    </div>
    <div class="bars">
      <% for(int s=5;s>=1;s--){ int pct=total>0?(int)(starCount[s]*100.0/total):0; %>
        <div class="bar-row">
          <span class="bar-lbl"><%=s%></span>
          <div class="bar-track"><div class="bar-fill" style="width:<%=pct%>%;"></div></div>
          <span class="bar-count"><%=starCount[s]%></span>
        </div>
      <% } %>
    </div>
  </div>

  <div class="section-h">Customer Reviews</div>

  <% if(ratings.isEmpty()){ %>
    <div class="empty"><i class="fa fa-star" style="font-size:40px;opacity:.2;display:block;margin-bottom:10px;"></i>
    No ratings yet. Keep delivering!</div>
  <% } else { for(Rating r : ratings){ %>
    <div class="review-card">
      <div class="review-top">
        <span class="review-name"><%=r.customerName!=null?r.customerName:"Customer"%></span>
        <span class="review-stars">
          <% for(int i=1;i<=5;i++) out.print(i<=r.stars?"<i class='fa fa-star'></i>":"<i class='fa fa-star' style='opacity:.3;'></i>"); %>
        </span>
      </div>
      <div class="review-date" style="margin-bottom:6px;"><%=r.createdAt!=null?r.createdAt.substring(0,10):""%> · Order #<%=r.orderId%></div>
      <% if(r.comment!=null&&!r.comment.isEmpty()){ %>
        <div class="review-comment">"<%=r.comment%>"</div>
      <% } else { %><div class="review-comment" style="font-style:italic;">No comment left.</div><% } %>
    </div>
  <% } } %>
</div>

<nav class="bottom-nav">
  <a href="delivery-dashboard.jsp" class="nav-item"><i class="fa fa-house"></i><span class="nav-label">Home</span></a>
  <a href="delivery-orders.jsp"    class="nav-item"><i class="fa fa-receipt"></i><span class="nav-label">Orders</span></a>
  <a href="delivery-earnings.jsp"  class="nav-item"><i class="fa fa-wallet"></i><span class="nav-label">Earnings</span></a>
  <a href="delivery-ratings.jsp"   class="nav-item active"><i class="fa fa-star"></i><span class="nav-label">Ratings</span></a>
  <a href="delivery-profile.jsp"   class="nav-item"><i class="fa fa-user"></i><span class="nav-label">Profile</span></a>
</nav>
</body>
</html>
