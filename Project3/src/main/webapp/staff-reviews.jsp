<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="com.sibs.model.User, com.sibs.dao.ProductReviewDAO, java.util.List" %>
<%
User staff = (User) session.getAttribute("user");
if (staff == null || !"STAFF".equals(staff.getRole())) {
    response.sendRedirect("login.jsp");
    return;
}

String deleteId = request.getParameter("deleteId");
String deleteMsg = null;
if (deleteId != null && !deleteId.trim().isEmpty()) {
    try {
        boolean deleted = new ProductReviewDAO().deleteReview(Integer.parseInt(deleteId.trim()));
        deleteMsg = deleted ? "success" : "error";
    } catch (Exception e) { deleteMsg = "error"; }
}

ProductReviewDAO reviewDAO = new ProductReviewDAO();
List<String[]> reviews = reviewDAO.getAllReviews();

int total = reviews.size();
double avgAll = 0;
int[] starCount = new int[6];
for (String[] r : reviews) {
    int rt = 0; try { rt = Integer.parseInt(r[3]); } catch(Exception e){}
    avgAll += rt;
    if (rt >= 1 && rt <= 5) starCount[rt]++;
}
if (total > 0) avgAll = avgAll / total;
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Reviews</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<style>
*{margin:0;padding:0;box-sizing:border-box;font-family:'Inter',sans-serif;}
body{background:#f1f0ea;color:#1a1a1a;padding:24px;}
.page-header{display:flex;align-items:center;justify-content:space-between;margin-bottom:20px;flex-wrap:wrap;gap:12px;}
.page-header h2{font-size:20px;font-weight:700;display:flex;align-items:center;gap:8px;}

/* Stats */
.stats-row{display:grid;grid-template-columns:repeat(4,1fr);gap:12px;margin-bottom:20px;}
.stat-card{background:#fff;border:1px solid #e5e4dc;border-radius:12px;padding:16px 18px;}
.stat-label{font-size:11px;color:#6b7280;text-transform:uppercase;letter-spacing:.5px;margin-bottom:6px;}
.stat-val{font-size:24px;font-weight:700;}

/* Search bar */
.search-bar{background:#fff;border:1px solid #e5e4dc;border-radius:12px;padding:14px 18px;margin-bottom:16px;display:flex;gap:10px;align-items:center;flex-wrap:wrap;}
.search-bar input{flex:1;min-width:180px;border:1px solid #e5e4dc;border-radius:8px;padding:8px 12px;font-size:13px;outline:none;}
.search-bar input:focus{border-color:#4f46e5;}
.search-bar select{border:1px solid #e5e4dc;border-radius:8px;padding:8px 12px;font-size:13px;outline:none;background:#fff;}
.search-bar select:focus{border-color:#4f46e5;}
.result-count{font-size:12px;color:#6b7280;margin-left:auto;}

/* Table */
.table-wrap{background:#fff;border:1px solid #e5e4dc;border-radius:12px;overflow:hidden;}
table{width:100%;border-collapse:collapse;}
thead{background:#f8f7f4;}
th{padding:11px 14px;text-align:left;font-size:11px;font-weight:600;color:#6b7280;text-transform:uppercase;letter-spacing:.4px;border-bottom:1px solid #e5e4dc;}
td{padding:12px 14px;font-size:13px;border-bottom:1px solid #f0efe8;vertical-align:middle;}
tr:last-child td{border-bottom:none;}
tr:hover td{background:#fafaf8;}
.product-name{font-weight:600;}
.customer-name{color:#374151;}
.star-filled{color:#f59e0b;}
.star-empty{color:#d1d5db;}
.rating-badge{display:inline-flex;align-items:center;gap:5px;padding:3px 10px;border-radius:20px;font-size:12px;font-weight:700;}
.r5{background:#f0fdf4;color:#16a34a;}
.r4{background:#eff6ff;color:#2563eb;}
.r3{background:#fffbeb;color:#d97706;}
.r2,.r1{background:#fef2f2;color:#ef4444;}
.review-text{color:#6b7280;max-width:260px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;}
.date-col{color:#9ca3af;font-size:12px;white-space:nowrap;}
.del-btn{background:#fff;border:1px solid #fecaca;color:#ef4444;border-radius:7px;padding:5px 12px;font-size:12px;cursor:pointer;display:inline-flex;align-items:center;gap:5px;transition:.15s;}
.del-btn:hover{background:#fef2f2;}
.no-data{text-align:center;padding:52px;color:#9ca3af;}
.no-data i{font-size:36px;display:block;margin-bottom:12px;opacity:.25;}
.footer-row{padding:12px 16px;font-size:12px;color:#9ca3af;border-top:1px solid #f0efe8;}

/* Modal */
.modal-bg{display:none;position:fixed;inset:0;background:rgba(0,0,0,.35);z-index:900;align-items:center;justify-content:center;}
.modal-bg.open{display:flex;}
.modal{background:#fff;border-radius:14px;padding:28px 24px;max-width:360px;width:90%;text-align:center;box-shadow:0 20px 60px rgba(0,0,0,.2);}
.modal h3{font-size:16px;font-weight:700;margin:12px 0 8px;}
.modal p{font-size:13px;color:#6b7280;margin-bottom:22px;line-height:1.5;}
.modal-btns{display:flex;gap:10px;justify-content:center;}
.btn-cancel{padding:9px 22px;border:1px solid #e5e4dc;border-radius:8px;background:#fff;cursor:pointer;font-size:13px;font-weight:500;}
.btn-delete{padding:9px 22px;background:#ef4444;color:#fff;border:none;border-radius:8px;cursor:pointer;font-size:13px;font-weight:600;}

/* Toast */
.toast{position:fixed;bottom:20px;right:20px;padding:10px 18px;border-radius:10px;font-size:13px;font-weight:600;display:none;z-index:999;box-shadow:0 4px 12px rgba(0,0,0,.15);}
.toast.show{display:block;}
.toast.success{background:#dcfce7;color:#16a34a;border:1px solid #bbf7d0;}
.toast.error{background:#fef2f2;color:#ef4444;border:1px solid #fecaca;}

@media(max-width:700px){.stats-row{grid-template-columns:1fr 1fr;}.review-text{max-width:100px;}}
</style>
</head>
<body>

<div class="page-header">
  <h2><i class="fa fa-star" style="color:#f59e0b;"></i> Product Reviews</h2>
</div>

<!-- Stats -->
<div class="stats-row">
  <div class="stat-card">
    <div class="stat-label">Total Reviews</div>
    <div class="stat-val"><%=total%></div>
  </div>
  <div class="stat-card">
    <div class="stat-label">Average Rating</div>
    <div class="stat-val" style="color:#f59e0b;"><%=total>0?String.format("%.1f",avgAll):"-"%> <i class="fa fa-star" style="font-size:16px;"></i></div>
  </div>
  <div class="stat-card">
    <div class="stat-label">5★ Reviews</div>
    <div class="stat-val" style="color:#16a34a;"><%=starCount[5]%></div>
  </div>
  <div class="stat-card">
    <div class="stat-label">1★ & 2★ Reviews</div>
    <div class="stat-val" style="color:#ef4444;"><%=starCount[1]+starCount[2]%></div>
  </div>
</div>

<!-- Search & Filter -->
<div class="search-bar">
  <i class="fa fa-magnifying-glass" style="color:#9ca3af;"></i>
  <input type="text" id="searchInput" placeholder="Search by product or customer..." oninput="filterTable()">
  <select id="ratingFilter" onchange="filterTable()">
    <option value="">All Ratings</option>
    <option value="5">⭐⭐⭐⭐⭐ 5 Star</option>
    <option value="4">⭐⭐⭐⭐ 4 Star</option>
    <option value="3">⭐⭐⭐ 3 Star</option>
    <option value="2">⭐⭐ 2 Star</option>
    <option value="1">⭐ 1 Star</option>
  </select>
  <span class="result-count" id="resultCount"><%=total%> reviews</span>
</div>

<!-- Table -->
<div class="table-wrap">
  <% if (reviews.isEmpty()) { %>
  <div class="no-data">
    <i class="fa fa-star"></i>
    <p>No reviews yet.</p>
  </div>
  <% } else { %>
  <table id="reviewTable">
    <thead>
      <tr>
        <th>#</th>
        <th>Product</th>
        <th>Customer</th>
        <th>Rating</th>
        <th>Review</th>
        <th>Date</th>
        <th>Action</th>
      </tr>
    </thead>
    <tbody>
    <% int idx=0; for (String[] r : reviews) {
       idx++;
       String rId   = r[0];
       String rProd = r[1]!=null?r[1]:"";
       String rUser = r[2]!=null?r[2]:"Customer";
       int rRating  = 0; try{rRating=Integer.parseInt(r[3]);}catch(Exception e){}
       String rText = r[4]!=null?r[4]:"";
       String rDate = r[5]!=null&&r[5].length()>=10?r[5].substring(0,10):"";
    %>
    <tr data-product="<%=rProd.toLowerCase()%>" data-customer="<%=rUser.toLowerCase()%>" data-rating="<%=rRating%>">
      <td style="color:#9ca3af;font-size:12px;"><%=idx%></td>
      <td class="product-name"><%=rProd%></td>
      <td class="customer-name"><%=rUser%></td>
      <td>
        <span class="rating-badge r<%=rRating%>"><i class="fa fa-star"></i> <%=rRating%>/5</span>
        <div style="margin-top:5px;">
          <% for(int s=1;s<=5;s++){%><i class="fa fa-star <%=s<=rRating?"star-filled":"star-empty"%>" style="font-size:10px;"></i><%}%>
        </div>
      </td>
      <td><span class="review-text" title="<%=rText%>"><%=rText.isEmpty()?"<i>—</i>":rText%></span></td>
      <td class="date-col"><%=rDate%></td>
      <td>
        <button class="del-btn" onclick="openDelete('<%=rId%>','<%=rProd.replace("'","\\'")%>','<%=rUser.replace("'","\\'")%>')">
          <i class="fa fa-trash"></i> Delete
        </button>
      </td>
    </tr>
    <% } %>
    </tbody>
  </table>
  <div class="footer-row" id="footerCount">Showing <%=total%> review<%=total!=1?"s":""%></div>
  <% } %>
</div>

<!-- Delete Modal -->
<div class="modal-bg" id="delModal">
  <div class="modal">
    <i class="fa fa-triangle-exclamation" style="font-size:30px;color:#ef4444;"></i>
    <h3>Delete Review?</h3>
    <p id="delDesc"></p>
    <div class="modal-btns">
      <button class="btn-cancel" onclick="closeModal()">Cancel</button>
      <button class="btn-delete" onclick="doDelete()">Delete</button>
    </div>
  </div>
</div>

<div class="toast" id="toast"></div>

<script>
var pendingDeleteId = null;

function openDelete(id, product, user) {
  pendingDeleteId = id;
  document.getElementById('delDesc').textContent =
    'Delete ' + user + "'s review for \"" + product + '"? This cannot be undone.';
  document.getElementById('delModal').classList.add('open');
}
function closeModal() {
  document.getElementById('delModal').classList.remove('open');
  pendingDeleteId = null;
}
function doDelete() {
  if (!pendingDeleteId) return;
  window.location.href = 'staff-reviews.jsp?deleteId=' + pendingDeleteId;
}

function filterTable() {
  var search = document.getElementById('searchInput').value.toLowerCase();
  var rating = document.getElementById('ratingFilter').value;
  var rows = document.querySelectorAll('#reviewTable tbody tr');
  var count = 0;
  rows.forEach(function(row) {
    var product  = row.getAttribute('data-product') || '';
    var customer = row.getAttribute('data-customer') || '';
    var rRating  = row.getAttribute('data-rating') || '';
    var matchSearch = !search || product.includes(search) || customer.includes(search);
    var matchRating = !rating || rRating === rating;
    if (matchSearch && matchRating) {
      row.style.display = '';
      count++;
    } else {
      row.style.display = 'none';
    }
  });
  document.getElementById('resultCount').textContent = count + ' review' + (count!==1?'s':'');
  document.getElementById('footerCount').textContent = 'Showing ' + count + ' review' + (count!==1?'s':'');
}

// Toast
<% if (deleteMsg != null) { %>
var t = document.getElementById('toast');
t.textContent = '<%="success".equals(deleteMsg) ? "Review deleted." : "Failed to delete."%>';
t.className = 'toast show <%=deleteMsg%>';
setTimeout(function(){ t.className='toast'; }, 3000);
<% } %>
</script>
</body>
</html>
