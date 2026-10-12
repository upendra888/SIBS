<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="jakarta.tags.core" prefix="c" %>
<%@ taglib uri="jakarta.tags.fmt"  prefix="fmt" %>
<%@ taglib uri="jakarta.tags.functions" prefix="fn" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Manage Returns – SIBS</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.3.2/css/bootstrap.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
    <style>
        body { background: #f1f3f5; font-family: 'Inter', sans-serif; }
        .content-area { margin-left: 0; padding: 30px; }
        .page-header { display:flex;align-items:center;justify-content:space-between;margin-bottom:24px; }
        .page-title  { font-weight:700;font-size:1.45rem;margin:0; }
        .role-badge  { font-size:.75rem;font-weight:600;padding:4px 12px;border-radius:20px;letter-spacing:.5px;text-transform:uppercase; }
        .role-badge.staff { background:#dbeafe;color:#1d4ed8; }
        .role-badge.admin { background:#fef9c3;color:#92400e; }

        /* Workflow bar */
        .workflow-bar { display:flex;align-items:center;gap:0;background:#fff;border:1px solid #e2e8f0;border-radius:12px;padding:16px 24px;margin-bottom:24px;overflow-x:auto; }
        .wf-step { display:flex;flex-direction:column;align-items:center;min-width:90px;text-align:center; }
        .wf-icon { width:40px;height:40px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:1rem;margin-bottom:6px;border:2px solid transparent; }
        .wf-label { font-size:.7rem;font-weight:600;color:#64748b;white-space:nowrap; }
        .wf-arrow { color:#cbd5e1;font-size:1.1rem;margin:0 4px;margin-bottom:18px; }
        .wf-step.active .wf-icon  { background:#dbeafe;color:#2563eb;border-color:#93c5fd; }
        .wf-step.active .wf-label { color:#2563eb; }
        .wf-step.done .wf-icon    { background:#dcfce7;color:#16a34a;border-color:#86efac; }
        .wf-step.done .wf-label   { color:#16a34a; }
        .wf-step.pending .wf-icon { background:#f1f5f9;color:#94a3b8;border-color:#e2e8f0; }

        /* Filter tabs */
        .filter-tabs .btn { border-radius:20px;font-size:.82rem; }
        .filter-tabs .active { font-weight:700; }

        /* Table */
        .returns-table th { background:#0f172a;color:#fff;font-size:.78rem;white-space:nowrap;font-weight:500;letter-spacing:.3px; }
        .returns-table td { vertical-align:middle;font-size:.85rem; }
        .returns-table tbody tr:hover { background:#f8fafc; }

        /* Status badges */
        .status-badge { padding:4px 10px;border-radius:20px;font-size:.73rem;font-weight:700;display:inline-block;text-transform:uppercase;letter-spacing:.4px; }
        .badge-PENDING          { background:#fef3c7;color:#92400e; }
        .badge-APPROVED         { background:#dcfce7;color:#166534; }
        .badge-REJECTED         { background:#fee2e2;color:#991b1b; }
        .badge-PICKUP_SCHEDULED { background:#dbeafe;color:#1d4ed8; }
        .badge-PICKED_UP        { background:#e0f2fe;color:#075985; }
        .badge-REFUNDED         { background:#d1fae5;color:#065f46; }

        /* Actions */
        .actions { min-width:165px; }
        .actions .btn { font-size:.76rem;padding:4px 10px;margin:2px 1px;white-space:nowrap; }
        .monitor-pill { display:inline-block;font-size:.72rem;padding:3px 9px;border-radius:20px;background:#f1f5f9;color:#64748b;border:1px solid #e2e8f0;font-weight:500; }
        .next-hint { font-size:.71rem;color:#2563eb;font-weight:600;display:flex;align-items:center;gap:4px;margin-bottom:3px; }

        /* Modal */
        .modal-header { background:#0f172a;color:#fff; }

        /* Stat cards */
        .stat-cards { display:flex;gap:12px;margin-bottom:24px;flex-wrap:wrap; }
        .stat-card  { flex:1;min-width:130px;background:#fff;border:1px solid #e2e8f0;border-radius:10px;padding:14px 18px;text-align:center; }
        .stat-card .val { font-size:1.6rem;font-weight:700; }
        .stat-card .lbl { font-size:.73rem;color:#64748b;text-transform:uppercase;letter-spacing:.4px;margin-top:2px; }
        .stat-pending { color:#d97706; } .stat-approved { color:#2563eb; }
        .stat-pickedup{ color:#0891b2; } .stat-refunded { color:#16a34a; }
        .empty-state { text-align:center;padding:80px;color:#aaa; }
    </style>
</head>
<body>
<%@ include file="/includes/adminSidebar.jsp" %>

<div class="content-area">

    <!-- Page header -->
    <div class="page-header">
        <h1 class="page-title"><i class="fa fa-rotate-left me-2 text-primary"></i>Return Requests</h1>
        <c:choose>
            <c:when test="${fn:toLowerCase(currentUser.role) eq 'staff'}">
                <span class="role-badge staff"><i class="fa fa-user-check me-1"></i>Staff – Full Actions</span>
            </c:when>
            <c:otherwise>
                <span class="role-badge admin"><i class="fa fa-eye me-1"></i>Admin – Monitor Only</span>
            </c:otherwise>
        </c:choose>
    </div>

    <!-- Flash messages -->
    <c:if test="${not empty sessionScope.successMsg}">
        <div class="alert alert-success alert-dismissible d-flex align-items-center gap-2">
            <i class="fa fa-circle-check"></i> ${sessionScope.successMsg}
            <button type="button" class="btn-close ms-auto" data-bs-dismiss="alert"></button>
        </div>
        <c:remove var="successMsg" scope="session"/>
    </c:if>
    <c:if test="${not empty sessionScope.errorMsg}">
        <div class="alert alert-danger alert-dismissible d-flex align-items-center gap-2">
            <i class="fa fa-circle-exclamation"></i> ${sessionScope.errorMsg}
            <button type="button" class="btn-close ms-auto" data-bs-dismiss="alert"></button>
        </div>
        <c:remove var="errorMsg" scope="session"/>
    </c:if>

    <!-- Workflow stepper (staff only) -->
    <c:if test="${fn:toLowerCase(currentUser.role) eq 'staff'}">
    <div class="workflow-bar">
        <div class="wf-step done">
            <div class="wf-icon"><i class="fa fa-inbox"></i></div>
            <div class="wf-label">Customer<br>Requests</div>
        </div>
        <div class="wf-arrow"><i class="fa fa-chevron-right"></i></div>
        <div class="wf-step active">
            <div class="wf-icon"><i class="fa fa-check-circle"></i></div>
            <div class="wf-label">Approve /<br>Reject</div>
        </div>
        <div class="wf-arrow"><i class="fa fa-chevron-right"></i></div>
        <div class="wf-step active">
            <div class="wf-icon"><i class="fa fa-person-biking"></i></div>
            <div class="wf-label">Assign<br>Delivery Boy</div>
        </div>
        <div class="wf-arrow"><i class="fa fa-chevron-right"></i></div>
        <div class="wf-step active">
            <div class="wf-icon"><i class="fa fa-box-open"></i></div>
            <div class="wf-label">Boy Picks<br>Up Item</div>
        </div>
        <div class="wf-arrow"><i class="fa fa-chevron-right"></i></div>
        <div class="wf-step active">
            <div class="wf-icon"><i class="fa fa-indian-rupee-sign"></i></div>
            <div class="wf-label">Process<br>Refund</div>
        </div>
        <div class="wf-arrow"><i class="fa fa-chevron-right"></i></div>
        <div class="wf-step pending">
            <div class="wf-icon"><i class="fa fa-circle-check"></i></div>
            <div class="wf-label">Done &<br>Notified</div>
        </div>
    </div>
    </c:if>

    <!-- Stat cards -->
    <div class="stat-cards">
        <div class="stat-card">
            <div class="val stat-pending">
                <c:set var="cntP" value="0"/>
                <c:forEach var="r" items="${returns}"><c:if test="${r.status eq 'PENDING'}"><c:set var="cntP" value="${cntP+1}"/></c:if></c:forEach>
                ${cntP}
            </div>
            <div class="lbl">Pending</div>
        </div>
        <div class="stat-card">
            <div class="val stat-approved">
                <c:set var="cntA" value="0"/>
                <c:forEach var="r" items="${returns}"><c:if test="${r.status eq 'APPROVED' or r.status eq 'PICKUP_SCHEDULED'}"><c:set var="cntA" value="${cntA+1}"/></c:if></c:forEach>
                ${cntA}
            </div>
            <div class="lbl">Approved</div>
        </div>
        <div class="stat-card">
            <div class="val stat-pickedup">
                <c:set var="cntK" value="0"/>
                <c:forEach var="r" items="${returns}"><c:if test="${r.status eq 'PICKED_UP'}"><c:set var="cntK" value="${cntK+1}"/></c:if></c:forEach>
                ${cntK}
            </div>
            <div class="lbl">Awaiting Refund</div>
        </div>
        <div class="stat-card">
            <div class="val stat-refunded">
                <c:set var="cntR" value="0"/>
                <c:forEach var="r" items="${returns}"><c:if test="${r.status eq 'REFUNDED'}"><c:set var="cntR" value="${cntR+1}"/></c:if></c:forEach>
                ${cntR}
            </div>
            <div class="lbl">Refunded</div>
        </div>
    </div>

    <!-- Filter tabs -->
    <div class="filter-tabs d-flex gap-2 flex-wrap mb-3">
        <a href="AdminReturnServlet?action=list"                         class="btn btn-outline-dark   ${empty filterStatus ? 'active' : ''}">All</a>
        <a href="AdminReturnServlet?action=list&status=PENDING"          class="btn btn-outline-warning ${filterStatus eq 'PENDING'          ? 'active' : ''}"><i class="fa fa-clock me-1"></i>Pending</a>
        <a href="AdminReturnServlet?action=list&status=APPROVED"         class="btn btn-outline-success ${filterStatus eq 'APPROVED'         ? 'active' : ''}"><i class="fa fa-check me-1"></i>Approved</a>
        <a href="AdminReturnServlet?action=list&status=REJECTED"         class="btn btn-outline-danger  ${filterStatus eq 'REJECTED'         ? 'active' : ''}"><i class="fa fa-xmark me-1"></i>Rejected</a>
        <a href="AdminReturnServlet?action=list&status=PICKUP_SCHEDULED" class="btn btn-outline-primary ${filterStatus eq 'PICKUP_SCHEDULED' ? 'active' : ''}"><i class="fa fa-truck me-1"></i>Pickup Scheduled</a>
        <a href="AdminReturnServlet?action=list&status=PICKED_UP"        class="btn btn-outline-info    ${filterStatus eq 'PICKED_UP'        ? 'active' : ''}"><i class="fa fa-box-open me-1"></i>Picked Up</a>
        <a href="AdminReturnServlet?action=list&status=REFUNDED"         class="btn btn-outline-success ${filterStatus eq 'REFUNDED'         ? 'active' : ''}"><i class="fa fa-indian-rupee-sign me-1"></i>Refunded</a>
    </div>

    <!-- Table -->
    <c:choose>
        <c:when test="${empty returns}">
            <div class="empty-state">
                <i class="fa fa-inbox fa-3x mb-3" style="color:#e2e8f0;"></i>
                <p class="mb-0">No return requests found.</p>
            </div>
        </c:when>
        <c:otherwise>
            <div class="table-responsive bg-white rounded-3 border" style="border-color:#e2e8f0!important;">
                <table class="table table-bordered returns-table mb-0">
                    <thead>
                        <tr>
                            <th>#</th><th>Customer</th><th>Product</th><th>Order</th>
                            <th>Reason</th><th>Refund</th><th>Method</th><th>Payment</th>
                            <th>Status</th><th>Requested</th><th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                    <c:forEach var="r" items="${returns}" varStatus="vs">
                    <tr>
                        <td class="text-muted">${vs.index+1}</td>
                        <td>
                            <strong>${r.customerName}</strong><br>
                            <small class="text-muted">${r.customerEmail}</small>
                        </td>
                        <td>
                            <div class="d-flex align-items-center gap-2">
                                <img src="${pageContext.request.contextPath}/${r.productImage}" alt="${r.productName}"
                                     style="width:36px;height:36px;object-fit:cover;border-radius:6px;border:1px solid #e2e8f0;">
                                <small>${r.productName}</small>
                            </div>
                        </td>
                        <td><span class="text-muted">#</span><strong>${r.orderId}</strong></td>
                        <td><small>${r.reason}</small></td>
                        <td><strong>&#8377;<fmt:formatNumber value="${r.refundAmount}" pattern="#,##0.00"/></strong></td>
                        <td><small>${r.refundMethod}</small></td>
                        <td><small>${r.paymentMethod}</small></td>
                        <td><span class="status-badge badge-${r.status}">${r.status}</span></td>
                        <td><small><fmt:formatDate value="${r.requestedAt}" pattern="dd MMM yy"/></small></td>

                        <td class="actions">
                            <!-- Detail (all roles) -->
                            <button class="btn btn-sm btn-outline-secondary"
                                    onclick="showDetail(${r.id},'${fn:escapeXml(r.productName)}',
                                             '${fn:escapeXml(r.reason)}','${fn:escapeXml(r.description)}',
                                             '${fn:escapeXml(r.adminNote)}',${r.refundAmount},
                                             '${r.refundMethod}','${r.status}')">
                                <i class="fa fa-eye"></i> Detail
                            </button>

                            <c:choose>
                                <c:when test="${fn:toLowerCase(currentUser.role) eq 'staff'}">

                                    <%-- STEP 1: PENDING --%>
                                    <c:if test="${r.status eq 'PENDING'}">
                                        <div class="next-hint mt-1"><i class="fa fa-arrow-right"></i>Step 1: Review</div>
                                        <button class="btn btn-sm btn-success" onclick="openApproveModal(${r.id},${r.refundAmount},'${r.refundMethod}')">
                                            <i class="fa fa-check"></i> Approve
                                        </button>
                                        <button class="btn btn-sm btn-danger" onclick="openRejectModal(${r.id})">
                                            <i class="fa fa-xmark"></i> Reject
                                        </button>
                                    </c:if>

                                    <%-- STEP 2: APPROVED --%>
                                    <c:if test="${r.status eq 'APPROVED'}">
                                        <div class="next-hint mt-1"><i class="fa fa-arrow-right"></i>Step 2: Assign Delivery Boy</div>
                                        <button type="button" class="btn btn-sm btn-primary"
                                                onclick="openScheduleModal(${r.id})">
                                            <i class="fa fa-truck"></i> Schedule Pickup
                                        </button>
                                    </c:if>

                                    <%-- STEP 3: PICKUP_SCHEDULED --%>
                                    <c:if test="${r.status eq 'PICKUP_SCHEDULED'}">
                                        <div class="next-hint mt-1"><i class="fa fa-arrow-right"></i>Step 3: Awaiting Delivery Boy Pickup</div>
                                        <span class="badge" style="background:#dbeafe;color:#1d4ed8;font-size:.75rem;padding:5px 10px;border-radius:20px;">
                                            <i class="fa fa-person-biking me-1"></i>Delivery Boy Assigned
                                        </span>
                                        <div class="small text-muted mt-1">Waiting for delivery boy to pick up</div>
                                    </c:if>

                                    <%-- STEP 4: PICKED_UP --%>
                                    <c:if test="${r.status eq 'PICKED_UP'}">
                                        <div class="next-hint mt-1"><i class="fa fa-arrow-right"></i>Step 4: Refund</div>
                                        <div class="small text-muted mb-1">
                                            <i class="fa fa-indian-rupee-sign"></i>
                                            <strong><fmt:formatNumber value="${r.refundAmount}" pattern="#,##0.00"/></strong>
                                            via <strong>${r.refundMethod}</strong>
                                        </div>
                                        <form method="post" action="${pageContext.request.contextPath}/AdminReturnServlet"
                                              style="display:inline"
                                              onsubmit="return confirm('Process refund of \u20B9${r.refundAmount} to ${r.customerName}?\nThis will trigger the actual refund and email the customer.')">
                                            <input type="hidden" name="action"   value="refund">
                                            <input type="hidden" name="returnId" value="${r.id}">
                                            <button type="submit" class="btn btn-sm btn-success">
                                                <i class="fa fa-indian-rupee-sign"></i> Process Refund
                                            </button>
                                        </form>
                                    </c:if>

                                    <%-- STEP 5: REFUNDED --%>
                                    <c:if test="${r.status eq 'REFUNDED'}">
                                        <span class="badge bg-success"><i class="fa fa-circle-check"></i> Completed</span>
                                    </c:if>

                                    <%-- REJECTED --%>
                                    <c:if test="${r.status eq 'REJECTED'}">
                                        <span class="badge bg-secondary">Closed</span>
                                    </c:if>

                                </c:when>
                                <c:otherwise>
                                    <span class="monitor-pill"><i class="fa fa-eye me-1"></i>Monitoring</span>
                                </c:otherwise>
                            </c:choose>
                        </td>
                    </tr>
                    </c:forEach>
                    </tbody>
                </table>
            </div>
        </c:otherwise>
    </c:choose>
</div>

<!-- Approve Modal -->
<div class="modal fade" id="approveModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title"><i class="fa fa-check-circle me-2"></i>Approve Return</h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
            </div>
            <form method="post" action="${pageContext.request.contextPath}/AdminReturnServlet">
                <input type="hidden" name="action"   value="approve">
                <input type="hidden" name="returnId" id="approveReturnId">
                <div class="modal-body">
                    <div class="alert alert-info small py-2 mb-3">
                        <i class="fa fa-info-circle me-1"></i>
                        After approval the next step will be to <strong>Schedule Pickup</strong>.
                    </div>
                    <div class="mb-3">
                        <label class="form-label fw-semibold">Refund Amount (&#8377;)</label>
                        <input type="number" step="0.01" min="0" class="form-control" name="refundAmount" id="approveRefundAmount" required>
                    </div>
                    <div class="mb-3">
                        <label class="form-label fw-semibold">Refund Method</label>
                        <select class="form-select" name="refundMethod" id="approveRefundMethod">
                            <option value="ORIGINAL_PAYMENT">Original Payment Method</option>
                            <option value="WALLET">Wallet Credit</option>
                            <option value="NA">N/A (Cash On Delivery)</option>
                        </select>
                    </div>
                    <div class="mb-3">
                        <label class="form-label fw-semibold">Note to Customer <span class="text-muted fw-normal">(optional)</span></label>
                        <textarea class="form-control" name="adminNote" rows="2"
                                  placeholder="e.g. Your return has been approved. Please keep the product ready for pickup."></textarea>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                    <button type="submit" class="btn btn-success"><i class="fa fa-check me-1"></i>Approve Return</button>
                </div>
            </form>
        </div>
    </div>
</div>

<!-- Reject Modal -->
<div class="modal fade" id="rejectModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title"><i class="fa fa-xmark-circle me-2"></i>Reject Return</h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
            </div>
            <form method="post" action="${pageContext.request.contextPath}/AdminReturnServlet">
                <input type="hidden" name="action"   value="reject">
                <input type="hidden" name="returnId" id="rejectReturnId">
                <div class="modal-body">
                    <div class="alert alert-warning small py-2 mb-3">
                        <i class="fa fa-triangle-exclamation me-1"></i>
                        This will permanently reject the return and notify the customer.
                    </div>
                    <div class="mb-3">
                        <label class="form-label fw-semibold">Reason for Rejection <span class="text-danger">*</span></label>
                        <textarea class="form-control" name="adminNote" rows="3" required
                                  placeholder="e.g. Return window has expired. Product shows signs of use."></textarea>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                    <button type="submit" class="btn btn-danger"><i class="fa fa-xmark me-1"></i>Reject Return</button>
                </div>
            </form>
        </div>
    </div>
</div>

<!-- Detail Modal -->
<div class="modal fade" id="detailModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="detailTitle">Return Detail</h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body" id="detailBody"></div>
            <div class="modal-footer">
                <button class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
            </div>
        </div>
    </div>
</div>

<!-- Schedule Pickup Modal -->
<div class="modal fade" id="schedulePickupModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title"><i class="fa fa-truck me-2"></i>Schedule Return Pickup</h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
            </div>
            <form method="post" action="${pageContext.request.contextPath}/AdminReturnServlet">
                <input type="hidden" name="action"   value="schedulePickup">
                <input type="hidden" name="returnId" id="scheduleReturnId">
                <div class="modal-body">
                    <div class="alert alert-info small py-2 mb-3">
                        <i class="fa fa-info-circle me-1"></i>
                        Assign a delivery boy. They will collect the item from the customer and press <strong>Confirm Pickup</strong> in their app.
                    </div>
                    <div class="mb-3">
                        <label class="form-label fw-semibold">Assign Delivery Boy <span class="text-danger">*</span></label>
                        <select class="form-select" name="deliveryBoyId" id="scheduleDeliveryBoy" required>
                            <option value="">-- Select Delivery Boy --</option>
                            <c:forEach var="db" items="${deliveryBoys}">
                                <c:if test="${db.status eq 'ACTIVE'}">
                                    <option value="${db.id}">
                                        ${db.name}
                                        <c:if test="${not empty db.phone}"> (${db.phone})</c:if>
                                        <c:if test="${db.online}"> ● Online</c:if>
                                    </option>
                                </c:if>
                            </c:forEach>
                        </select>
                        <div class="form-text text-muted">Only ACTIVE delivery boys are shown.</div>
                    </div>
                    <div class="alert alert-warning small py-2">
                        <i class="fa fa-triangle-exclamation me-1"></i>
                        Once assigned, the delivery boy will see a <strong>"Collect Wrong Item from Customer"</strong> button in their app.
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                    <button type="submit" class="btn btn-primary">
                        <i class="fa fa-truck me-1"></i>Assign &amp; Schedule Pickup
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

<script src="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.3.2/js/bootstrap.bundle.min.js"></script>
<script>
function openScheduleModal(returnId) {
    document.getElementById('scheduleReturnId').value = returnId;
    new bootstrap.Modal(document.getElementById('schedulePickupModal')).show();
}
function openApproveModal(returnId, refundAmount, refundMethod) {
    document.getElementById('approveReturnId').value     = returnId;
    document.getElementById('approveRefundAmount').value = refundAmount;
    const sel = document.getElementById('approveRefundMethod');
    for (let opt of sel.options) { if (opt.value === refundMethod) { opt.selected = true; break; } }
    new bootstrap.Modal(document.getElementById('approveModal')).show();
}
function openRejectModal(returnId) {
    document.getElementById('rejectReturnId').value = returnId;
    new bootstrap.Modal(document.getElementById('rejectModal')).show();
}
function showDetail(id, product, reason, desc, adminNote, amount, method, status) {
    const bg  = {PENDING:'#fef3c7',APPROVED:'#dcfce7',REJECTED:'#fee2e2',PICKUP_SCHEDULED:'#dbeafe',PICKED_UP:'#e0f2fe',REFUNDED:'#d1fae5'};
    const col = {PENDING:'#92400e',APPROVED:'#166534',REJECTED:'#991b1b',PICKUP_SCHEDULED:'#1d4ed8',PICKED_UP:'#075985',REFUNDED:'#065f46'};
    document.getElementById('detailTitle').textContent = 'Return #' + id + ' – ' + product;
    document.getElementById('detailBody').innerHTML =
        '<table class="table table-sm table-bordered">' +
        '<tr><th style="width:140px">Reason</th><td>' + (reason||'–') + '</td></tr>' +
        '<tr><th>Description</th><td>' + (desc||'–') + '</td></tr>' +
        '<tr><th>Refund Amount</th><td><strong>&#8377;' + parseFloat(amount).toFixed(2) + '</strong></td></tr>' +
        '<tr><th>Refund Method</th><td>' + (method||'–') + '</td></tr>' +
        '<tr><th>Status</th><td><span style="padding:3px 10px;border-radius:20px;font-weight:700;font-size:.75rem;background:'+(bg[status]||'#eee')+';color:'+(col[status]||'#333')+'">' + status + '</span></td></tr>' +
        '<tr><th>Staff Note</th><td>' + (adminNote||'–') + '</td></tr>' +
        '</table>';
    new bootstrap.Modal(document.getElementById('detailModal')).show();
}
</script>
</body>
</html>
