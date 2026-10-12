<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.util.*,com.sibs.dao.OrderDAO,com.sibs.dao.DeliveryBoyDAO,com.sibs.model.Order,com.sibs.model.User,com.sibs.model.DeliveryBoy" %>
<%
User user = (User)session.getAttribute("user");
if(user == null || !"STAFF".equals(user.getRole())){
    response.sendRedirect("login.jsp");
    return;
}
OrderDAO dao = new OrderDAO();
DeliveryBoyDAO dbDao = new DeliveryBoyDAO();
List<Order> list = dao.getGroupedOrders();
List<DeliveryBoy> deliveryBoys = dbDao.getAllWithStats();
%>
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Staff Orders — SIBS</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<style>
:root{--bg:#f8fafc;--surface:#fff;--border:#e2e8f0;--text:#0f172a;--muted:#64748b;--primary:#2563eb;--success:#16a34a;--danger:#ef4444;--warn:#f59e0b;}
[data-theme="dark"]{--bg:#0f172a;--surface:#1e293b;--border:#334155;--text:#f1f5f9;--muted:#94a3b8;}
*{margin:0;padding:0;box-sizing:border-box;font-family:'Inter',sans-serif;}
body{background:var(--bg);color:var(--text);}
.topbar{background:var(--surface);border-bottom:1px solid var(--border);padding:0 24px;height:60px;display:flex;align-items:center;justify-content:space-between;position:sticky;top:0;z-index:50;}
.topbar-left{display:flex;align-items:center;gap:10px;}
.topbar-left a{color:var(--muted);text-decoration:none;font-size:13px;display:flex;align-items:center;gap:5px;}
.topbar-left a:hover{color:var(--primary);}
.page-title{font-weight:700;font-size:16px;}
.topbar-right{display:flex;gap:10px;align-items:center;}
.dark-btn{background:none;border:1px solid var(--border);width:34px;height:34px;border-radius:8px;cursor:pointer;color:var(--muted);}
.realtime{font-size:11px;color:#22c55e;display:flex;align-items:center;gap:5px;}
.realtime-dot{width:7px;height:7px;background:#22c55e;border-radius:50%;animation:pulse 2s infinite;}
@keyframes pulse{0%,100%{opacity:1;}50%{opacity:.4;}}
.content{padding:24px;}
.controls{display:flex;gap:10px;margin-bottom:14px;flex-wrap:wrap;}
.controls input,.controls select{padding:9px 14px;border:1px solid var(--border);border-radius:8px;background:var(--surface);color:var(--text);font-size:13px;outline:none;}
.controls input:focus{border-color:var(--primary);}
.controls input{min-width:220px;}
.top-row{display:flex;justify-content:space-between;align-items:center;margin-bottom:16px;flex-wrap:wrap;gap:10px;}
.manage-btn{padding:9px 16px;background:#f97316;color:#fff;border:none;border-radius:8px;font-size:13px;font-weight:600;cursor:pointer;text-decoration:none;}
.table-wrap{background:var(--surface);border:1px solid var(--border);border-radius:12px;overflow:hidden;}
table{width:100%;border-collapse:collapse;}
th{padding:12px 16px;text-align:left;font-size:11px;font-weight:600;color:var(--muted);text-transform:uppercase;letter-spacing:.4px;background:var(--bg);border-bottom:1px solid var(--border);}
td{padding:13px 16px;font-size:13px;border-bottom:1px solid var(--border);vertical-align:middle;}
tbody tr:last-child td{border-bottom:none;}
tbody tr:hover{background:var(--bg);}
.badge{padding:4px 10px;border-radius:999px;font-size:11px;font-weight:600;color:#fff;}
.pending{background:#f59e0b;}.approved{background:#16a34a;}.packed{background:#8b5cf6;}
.assigned{background:#0284c7;}.picked{background:#ea580c;}.outfordelivery{background:#ca8a04;}
.shipped{background:#2563eb;}.delivered{background:#7c3aed;}.rejected{background:#ef4444;}.cancelled{background:#6b7280;}
.action-btn{padding:6px 12px;border:none;border-radius:6px;color:#fff;cursor:pointer;font-size:12px;font-weight:500;transition:.15s;}
.btn-approve{background:#16a34a;}
.btn-reject{background:#ef4444;}
.btn-pack{background:#8b5cf6;}
.btn-assign{background:#0284c7;}
.btn-picked{background:#ea580c;}
.btn-outfordelivery{background:#ca8a04;}
.btn-ship{background:#2563eb;}
.btn-deliver{background:#16a34a;}
.btn-cancel{background:#6b7280;}
.action-btn:hover{opacity:.85;}
/* Cancel Modal */
.modal-overlay{display:none;position:fixed;inset:0;background:rgba(0,0,0,.45);z-index:200;align-items:center;justify-content:center;}
.modal-overlay.active{display:flex;}
.modal-box{background:var(--surface);border-radius:14px;padding:28px 28px 22px;min-width:340px;max-width:440px;width:90%;box-shadow:0 20px 60px rgba(0,0,0,.25);}
.modal-title{font-weight:700;font-size:16px;margin-bottom:14px;color:var(--text);}
.modal-box textarea{width:100%;border:1px solid var(--border);border-radius:8px;padding:10px;font-size:13px;color:var(--text);background:var(--surface);resize:vertical;min-height:80px;outline:none;}
.modal-box textarea:focus{border-color:var(--primary);}
.modal-actions{display:flex;gap:10px;margin-top:14px;justify-content:flex-end;}
.modal-cancel-btn{padding:8px 18px;border:1px solid var(--border);border-radius:8px;background:none;color:var(--text);cursor:pointer;font-size:13px;}
.modal-confirm-btn{padding:8px 18px;border:none;border-radius:8px;background:#ef4444;color:#fff;cursor:pointer;font-size:13px;font-weight:600;}
.delivery-form{display:flex;gap:6px;flex-wrap:wrap;align-items:center;}
.delivery-select{padding:6px 10px;border:1px solid var(--border);border-radius:6px;font-size:12px;background:var(--surface);color:var(--text);min-width:160px;}
.delivery-input{padding:6px 10px;border:1px solid var(--border);border-radius:6px;font-size:12px;width:130px;background:var(--surface);color:var(--text);}
.delivery-boy-tag{font-size:12px;color:var(--muted);display:flex;align-items:center;gap:4px;}
.no-db-msg{font-size:12px;color:#ef4444;}
.btn-redeliver{background:#f97316;}
.redeliver-modal-title{font-weight:700;font-size:16px;margin-bottom:6px;color:var(--text);}
.redeliver-field{margin-bottom:12px;}
.redeliver-field label{display:block;font-size:12px;color:var(--muted);margin-bottom:5px;font-weight:500;}
.redeliver-field input,.redeliver-field select,.redeliver-field textarea{width:100%;border:1px solid var(--border);border-radius:8px;padding:9px 11px;font-size:13px;color:var(--text);background:var(--surface);outline:none;}
.redeliver-field input:focus,.redeliver-field select:focus,.redeliver-field textarea:focus{border-color:#f97316;}
.redeliver-field textarea{resize:none;min-height:60px;}
.snb-empty i{font-size:24px;display:block;margin-bottom:8px;opacity:.4;}
.snb-footer{padding:10px 16px;border-top:1px solid var(--border);text-align:center;}
.snb-footer-link{font-size:12px;color:#2563eb;cursor:pointer;font-weight:600;}
</style>
</head>
<body>
<div class="topbar">
  <div class="topbar-left">
    <a href="staff-dashboard.jsp"><i class="fa fa-arrow-left"></i> Dashboard</a>
    <span style="color:var(--border);">|</span>
    <span class="page-title">Order Panel</span>
  </div>
  <div class="topbar-right">
    <div class="realtime"><div class="realtime-dot"></div> Live</div>
    <button class="dark-btn" onclick="toggleDark()"><i class="fa fa-moon"></i></button>
    <%@ include file="includes/staffNotificationBell.jsp" %>
  </div>
</div>

<div class="content">
  <div class="top-row">
    <div class="controls">
      <input type="text" id="search" placeholder="🔍 Search orders..." oninput="applyFilters()">
      <select id="statusFilter" onchange="applyFilters()">
        <option value="All">All Status</option>
        <option>Pending</option><option>Approved</option><option>Packed</option>
        <option>Assigned</option><option>Picked</option><option>Out for Delivery</option>
        <option>Delivered</option><option>Rejected</option><option>Cancelled</option>
      </select>
    </div>
    <a href="manage-delivery-boys.jsp" class="manage-btn">
      <i class="fa fa-motorcycle"></i> Manage Delivery Boys
    </a>
  </div>

  <div class="table-wrap">
    <table>
      <thead>
        <tr>
          <th>#</th><th>Customer</th><th>Phone</th><th>Product</th>
          <th>Qty</th><th>Total</th><th>Status</th><th>Delivery Boy</th><th>Action</th>
        </tr>
      </thead>
      <tbody id="orderTable">
      <%
      for(Order o : list){
        String rawStatus = o.getStatus();
        if(rawStatus==null) rawStatus="Pending";
        String status = rawStatus;
        if("Shipped".equalsIgnoreCase(status)) status = "Assigned";

        String cls="pending";
        if("Approved".equalsIgnoreCase(status))             cls="approved";
        else if("Packed".equalsIgnoreCase(status))           cls="packed";
        else if("Assigned".equalsIgnoreCase(status))         cls="assigned";
        else if("Picked".equalsIgnoreCase(status))           cls="picked";
        else if("Out for Delivery".equalsIgnoreCase(status)) cls="outfordelivery";
        else if("Delivered".equalsIgnoreCase(status))        cls="delivered";
        else if("Rejected".equalsIgnoreCase(status))         cls="rejected";
        else if("Cancelled".equalsIgnoreCase(status))        cls="cancelled";

        int itemCount = o.getItems().size();
        StringBuilder products = new StringBuilder();
        double groupTotal = 0;
        for(Order item : o.getItems()){
            if(products.length()>0) products.append(", ");
            products.append(item.getProductName()).append(" × ").append(item.getQuantity());
            groupTotal += item.getTotal();
        }
        groupTotal += o.getDeliveryCharge(); // include delivery charge in total
        if(itemCount == 0){ products.append(o.getProductName()); groupTotal = o.getTotal() + o.getDeliveryCharge(); }
        int displayId = o.getGroupId() > 0 ? o.getGroupId() : o.getId();
        int actionOrderId = (itemCount > 0) ? o.getItems().get(0).getId() : o.getId();
      %>
      <tr data-status="<%=status%>">
        <td style="color:var(--muted);">#<%=displayId%>
          <% if(itemCount > 1){ %><span style="font-size:10px;background:#e0f2fe;color:#0369a1;padding:1px 5px;border-radius:4px;margin-left:3px;"><%=itemCount%> items</span><% } %>
        </td>
        <td><b><%=o.getName()%></b></td>
        <td><%=o.getPhone()%></td>
        <td><%=products.toString()%></td>
        <td><%=itemCount > 0 ? "—" : o.getQuantity()%></td>
        <td><b>₹<%=(int)groupTotal%></b></td>
        <td><span class="badge <%=cls%>"><%=status%></span>
          <% if("Cancelled".equalsIgnoreCase(rawStatus)){
               String cr = o.getCancelReason();
               if(cr != null && !cr.trim().isEmpty() && !"No reason provided".equals(cr.trim())){ %>
            <div style="margin-top:5px;font-size:11px;color:#b91c1c;background:#fee2e2;
                        border-radius:6px;padding:4px 8px;max-width:180px;word-break:break-word;">
              <i class="fa fa-comment-dots"></i> <%=cr.trim()%>
            </div>
          <% }} %></td>
        <td>
          <% if(o.getDeliveryBoy() != null && !o.getDeliveryBoy().isEmpty()){ %>
            <span class="delivery-boy-tag">
              <i class="fa fa-motorcycle"></i> <%=o.getDeliveryBoy()%>
            </span>
          <% } else { %>
            <span style="font-size:12px;color:var(--muted);">—</span>
          <% } %>
        </td>
        <td>
          <% if("Pending".equalsIgnoreCase(status)){ %>
            <form action="updateOrder" method="post" style="display:inline;">
              <input type="hidden" name="orderId" value="<%=actionOrderId%>">
              <input type="hidden" name="groupId" value="<%=displayId%>">
              <input type="hidden" name="status" value="Approved">
              <button class="action-btn btn-approve" type="submit">
                <i class="fa fa-check"></i> Approve
              </button>
            </form>
            <form action="updateOrder" method="post" style="display:inline;margin-left:4px;">
              <input type="hidden" name="orderId" value="<%=actionOrderId%>">
              <input type="hidden" name="groupId" value="<%=displayId%>">
              <input type="hidden" name="status" value="Rejected">
              <button class="action-btn btn-reject" type="submit">
                <i class="fa fa-times"></i> Reject
              </button>
            </form>
            <button class="action-btn btn-cancel" style="margin-left:4px;"
                    onclick="openCancelModal('<%=displayId%>')">
              <i class="fa fa-ban"></i> Cancel
            </button>
          <% } else if("Approved".equalsIgnoreCase(status)){ %>
            <form action="updateOrder" method="post" style="display:inline;">
              <input type="hidden" name="orderId" value="<%=actionOrderId%>">
              <input type="hidden" name="groupId" value="<%=displayId%>">
              <input type="hidden" name="status" value="Packed">
              <button class="action-btn btn-pack" type="submit">
                <i class="fa fa-box"></i> Mark Packed
              </button>
            </form>
            <button class="action-btn btn-cancel" style="margin-left:4px;"
                    onclick="openCancelModal('<%=displayId%>')">
              <i class="fa fa-ban"></i> Cancel
            </button>
          <% } else if("Packed".equalsIgnoreCase(status)){ %>
            <%
                boolean hasOnline = false;
                for(DeliveryBoy dbCheck : deliveryBoys){
                    if(dbCheck.isOnline() && dbDao.hasActiveSlotToday(dbCheck.getId())){
                        hasOnline=true; break;
                    }
                }
            %>
            <% if(deliveryBoys.isEmpty()){ %>
              <span class="no-db-msg">
                <i class="fa fa-triangle-exclamation"></i>
                No delivery boys! <a href="manage-delivery-boys.jsp">Add one</a>
              </span>
            <% } else if(!hasOnline){ %>
              <span class="no-db-msg" style="color:#b45309;">
                <i class="fa fa-circle-exclamation"></i>
                No delivery boys online with an active slot right now.
              </span>
            <% } else { %>
              <form action="AssignDeliveryServlet" method="post" class="delivery-form">
                <input type="hidden" name="orderId" value="<%=actionOrderId%>">
                <input type="hidden" name="groupId" value="<%=displayId%>">
                <select name="deliveryBoyId" class="delivery-select" required>
                  <option value="">-- Select Online Delivery Boy --</option>
                  <%
                    boolean anyOnline = false;
                    for(DeliveryBoy db : deliveryBoys){
                        if(!db.isOnline()) continue;
                        if(!dbDao.hasActiveSlotToday(db.getId())) continue; // must have a slot today
                        anyOnline = true;
                        String workLabel = db.getActiveOrders() > 0
                            ? " (" + db.getActiveOrders() + " active)"
                            : " (free)";
                  %>
                    <option value="<%=db.getId()%>">
                      <%=db.getName()%> — <%=db.getPhone()%><%=workLabel%>
                    </option>
                  <% } %>
                  <% if(!anyOnline){ %>
                    <option value="" disabled>No delivery boys online right now</option>
                  <% } %>
                </select>
                <input type="text" name="deliveryNote" class="delivery-input"
                       placeholder="Note (optional)">
                <button class="action-btn btn-assign" type="submit">
                  <i class="fa fa-motorcycle"></i> Assign to Delivery
                </button>
              </form>
            <% } %>
            <div style="margin-top:6px;">
              <button class="action-btn btn-cancel"
                      onclick="openCancelModal('<%=displayId%>')">
                <i class="fa fa-ban"></i> Cancel Order
              </button>
            </div>
          <% } else if("Assigned".equalsIgnoreCase(status)){ %>
            <span style="font-size:12px;color:#0284c7;display:flex;align-items:center;gap:5px;">
              <i class="fa fa-clock"></i> Awaiting Pickup by Delivery Boy
            </span>
          <% } else if("Picked".equalsIgnoreCase(status)){ %>
            <form action="updateOrder" method="post" style="display:inline;">
              <input type="hidden" name="orderId" value="<%=actionOrderId%>">
              <input type="hidden" name="groupId" value="<%=displayId%>">
              <input type="hidden" name="status" value="Out for Delivery">
              <button class="action-btn btn-outfordelivery" type="submit">
                <i class="fa fa-truck-fast"></i> Out for Delivery
              </button>
            </form>
          <% } else if("Out for Delivery".equalsIgnoreCase(status)){ %>
            <form action="updateOrder" method="post" style="display:inline;">
              <input type="hidden" name="orderId" value="<%=actionOrderId%>">
              <input type="hidden" name="groupId" value="<%=displayId%>">
              <input type="hidden" name="status" value="Delivered">
              <button class="action-btn btn-deliver" type="submit">
                <i class="fa fa-circle-check"></i> Mark Delivered
              </button>
            </form>
          <% } else if("Delivered".equalsIgnoreCase(status)) { %>
            <button class="action-btn btn-redeliver"
              onclick="openRedeliverModal('<%=displayId%>','<%=o.getName()%>','<%=o.getPhone()%>')">
              <i class="fa fa-rotate-right"></i> Re-deliver
            </button>
          <% } else { %>
            <span style="font-size:12px;color:var(--muted);">— Done —</span>
          <% } %>
        </td>
      </tr>
      <% } %>
      </tbody>
    </table>
  </div>
</div>

<!-- Re-deliver Modal -->
<div class="modal-overlay" id="redeliverModal">
  <div class="modal-box" style="max-width:480px;">
    <div class="redeliver-modal-title"><i class="fa fa-rotate-right" style="color:#f97316;margin-right:7px;"></i>Re-deliver Order</div>
    <p style="font-size:13px;color:var(--muted);margin-bottom:16px;">Update the delivery address and reassign a delivery boy.</p>
    <form action="RedeliverServlet" method="post">
      <input type="hidden" name="groupId" id="rdGroupId">
      <div class="redeliver-field">
        <label>Customer Name</label>
        <input type="text" name="customerName" id="rdName" readonly style="background:var(--bg);">
      </div>
      <div class="redeliver-field">
        <label>Customer Phone</label>
        <input type="text" name="customerPhone" id="rdPhone" readonly style="background:var(--bg);">
      </div>
      <div class="redeliver-field">
        <label>New Delivery Address <span style="color:#ef4444;">*</span></label>
        <textarea name="newAddress" id="rdAddress" placeholder="Enter correct delivery address..." required></textarea>
      </div>
      <div class="redeliver-field">
        <label>Assign Delivery Boy <span style="color:#ef4444;">*</span></label>
        <select name="deliveryBoyId" required>
          <option value="">-- Select Delivery Boy --</option>
          <%
            for(DeliveryBoy db : deliveryBoys){
          %>
            <option value="<%=db.getId()%>"><%=db.getName()%> — <%=db.getPhone()%><%= db.isOnline() ? " (Online)" : " (Offline)" %></option>
          <% } %>
        </select>
      </div>
      <div class="redeliver-field">
        <label>Note (optional)</label>
        <input type="text" name="note" placeholder="e.g. Ring doorbell, 2nd floor...">
      </div>
      <div class="modal-actions">
        <button type="button" class="modal-cancel-btn" onclick="closeRedeliverModal()">Cancel</button>
        <button type="submit" class="modal-confirm-btn" style="background:#f97316;">
          <i class="fa fa-rotate-right"></i> Confirm Re-delivery
        </button>
      </div>
    </form>
  </div>
</div>

<!-- Cancel Order Modal -->
<div class="modal-overlay" id="cancelModal">
  <div class="modal-box">
    <div class="modal-title"><i class="fa fa-ban" style="color:#ef4444;margin-right:7px;"></i>Cancel Order</div>
    <p style="font-size:13px;color:var(--muted);margin-bottom:12px;">Please provide a reason for cancellation (shown to customer).</p>
    <form action="cancelOrder" method="post">
      <input type="hidden" name="source" value="staff">
      <input type="hidden" name="id" id="cancelGroupId">
      <textarea name="reason" placeholder="e.g. Item out of stock, Customer requested cancellation..." required></textarea>
      <div class="modal-actions">
        <button type="button" class="modal-cancel-btn" onclick="closeCancelModal()">Back</button>
        <button type="submit" class="modal-confirm-btn"><i class="fa fa-ban"></i> Confirm Cancel</button>
      </div>
    </form>
  </div>
</div>

<script>
function openRedeliverModal(groupId, name, phone){
  document.getElementById('rdGroupId').value = groupId;
  document.getElementById('rdName').value = name;
  document.getElementById('rdPhone').value = phone;
  document.getElementById('rdAddress').value = '';
  document.getElementById('redeliverModal').classList.add('active');
}
function closeRedeliverModal(){
  document.getElementById('redeliverModal').classList.remove('active');
}
document.getElementById('redeliverModal').addEventListener('click', function(e){
  if(e.target===this) closeRedeliverModal();
});
function openCancelModal(groupId){
  document.getElementById('cancelGroupId').value = groupId;
  document.getElementById('cancelModal').classList.add('active');
}
function closeCancelModal(){
  document.getElementById('cancelModal').classList.remove('active');
}
document.getElementById('cancelModal').addEventListener('click', function(e){
  if(e.target===this) closeCancelModal();
});
function toggleDark(){
  const h=document.documentElement,d=h.getAttribute('data-theme')==='dark';
  h.setAttribute('data-theme',d?'light':'dark');
  localStorage.setItem('sibs-theme',d?'light':'dark');
}
(function(){const t=localStorage.getItem('sibs-theme');if(t)document.documentElement.setAttribute('data-theme',t);})();
function applyFilters(){
  const q=document.getElementById('search').value.toLowerCase();
  const s=document.getElementById('statusFilter').value;
  document.querySelectorAll('#orderTable tr').forEach(row=>{
    const text=row.textContent.toLowerCase();
    const status=row.getAttribute('data-status')||'';
    const mQ=!q||text.includes(q);
    const mS=s==='All'||status.toLowerCase()===s.toLowerCase();
    row.style.display=(mQ&&mS)?'':'none';
  });
}
setTimeout(()=>{if(!document.hidden)window.location.reload();},20000);
</script>
</body>
</html>