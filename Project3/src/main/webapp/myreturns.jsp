<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt"  prefix="fmt" %>
<%@ page import="com.sibs.dao.ReturnDAO, com.sibs.model.ReturnRequest, java.util.List" %>
<%
    com.sibs.model.User u = (com.sibs.model.User) session.getAttribute("user");
    if (u == null) { response.sendRedirect(request.getContextPath() + "/login.jsp"); return; }
    ReturnDAO dao = new ReturnDAO();
    List<ReturnRequest> myReturns = dao.getReturnsByUser(u.getId());
    request.setAttribute("myReturns", myReturns);
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>My Returns – SIBS</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/bootstrap.min.css">
    <style>
        body { background: #f8f9fa; font-family: 'Segoe UI', sans-serif; }
        .page-title { font-weight: 700; font-size: 1.6rem; margin: 32px 0 20px; }

        .return-table th { background: #343a40; color: #fff; font-size: .85rem; }

        /* Status badges */
        .badge-PENDING          { background:#ffc107; color:#000; }
        .badge-APPROVED         { background:#198754; color:#fff; }
        .badge-REJECTED         { background:#dc3545; color:#fff; }
        .badge-PICKUP_SCHEDULED { background:#0d6efd; color:#fff; }
        .badge-PICKED_UP        { background:#0dcaf0; color:#000; }
        .badge-REFUNDED         { background:#20c997; color:#fff; }

        .status-badge {
            padding: 4px 10px; border-radius: 20px;
            font-size: .78rem; font-weight: 600;
        }

        /* Refund ETA pill */
        .eta-pill { font-size:.75rem; color:#6c757d; margin-top:3px; }
        .eta-pill.done { color:#198754; font-weight:600; }

        /* Partial refund note */
        .partial-note { font-size:.78rem; color:#856404; background:#fff3cd;
            border:1px solid #ffc107; border-radius:6px; padding:4px 8px; margin-top:4px; display:inline-block; }

        /* Policy banner */
        .policy-banner { background:#e8f4fd; border:1px solid #b8daff; border-radius:8px;
            padding:12px 16px; margin-bottom:20px; font-size:.85rem; color:#004085; }
        .policy-banner strong { color:#0056b3; }

        .empty-state {
            text-align: center; padding: 80px 20px; color: #aaa;
        }
        .empty-state .icon { font-size: 4rem; }
    </style>
</head>
<body>

<%@ include file="/includes/customerNavbar.jsp" %>

<div class="container">
    <div class="page-title">↩️ My Return Requests</div>

    <!-- Policy banner -->
    <div class="policy-banner">
        🛡️ Returns accepted within <strong>14 days</strong> of delivery &nbsp;·&nbsp;
        🚚 <strong>Free pickup</strong> from your address &nbsp;·&nbsp;
        💰 Refunds processed in <strong>5–7 business days</strong> after pickup &nbsp;·&nbsp;
        ⚠️ Partial refunds may apply for incomplete / used items
    </div>

    <!-- Flash messages -->
    <c:if test="${not empty sessionScope.successMsg}">
        <div class="alert alert-success alert-dismissible">
            ${sessionScope.successMsg}
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
        <c:remove var="successMsg" scope="session"/>
    </c:if>
    <c:if test="${not empty sessionScope.errorMsg}">
        <div class="alert alert-danger alert-dismissible">
            ${sessionScope.errorMsg}
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
        <c:remove var="errorMsg" scope="session"/>
    </c:if>

    <c:choose>
        <c:when test="${empty myReturns}">
            <div class="empty-state">
                <div class="icon">📦</div>
                <p class="mt-3">You haven't raised any return requests yet.</p>
                <a href="${pageContext.request.contextPath}/customer/myOrders.jsp"
                   class="btn btn-outline-secondary mt-2">View My Orders</a>
            </div>
        </c:when>

        <c:otherwise>
            <div class="table-responsive">
                <table class="table table-bordered return-table align-middle">
                    <thead>
                        <tr>
                            <th>#</th>
                            <th>Product</th>
                            <th>Order ID</th>
                            <th>Reason</th>
                            <th>Refund ₹</th>
                            <th>Refund Method</th>
                            <th>Status</th>
                            <th>Refund ETA</th>
                            <th>Requested</th>
                            <th>Admin Note</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:forEach var="r" items="${myReturns}" varStatus="vs">
                        <tr>
                            <td>${vs.index + 1}</td>
                            <td>
                                <img src="${pageContext.request.contextPath}/${r.productImage}"
                                     alt="${r.productName}"
                                     style="width:42px;height:42px;object-fit:cover;border-radius:6px;"
                                     onerror="this.src='${pageContext.request.contextPath}/images/placeholder.png'">
                                <span class="ms-2 fw-semibold">${r.productName}</span>
                            </td>
                            <td>#${r.orderId}</td>
                            <td>${r.reason}</td>
                            <td>
                                ₹<fmt:formatNumber value="${r.refundAmount}" pattern="#,##0.00"/>
                                <%-- Show partial refund warning if refund < order total --%>
                                <c:if test="${r.refundAmount > 0 and r.refundAmount < r.orderTotal}">
                                    <br><span class="partial-note">⚠ Partial refund — see admin note</span>
                                </c:if>
                            </td>
                            <td>${r.refundMethod}</td>
                            <td>
                                <span class="status-badge badge-${r.status}">
                                    ${r.status}
                                </span>
                            </td>
                            <td>
                                <c:choose>
                                    <c:when test="${r.status eq 'REFUNDED'}">
                                        <span class="eta-pill done">✅ Refunded</span>
                                    </c:when>
                                    <c:when test="${r.status eq 'REJECTED'}">
                                        <span class="eta-pill" style="color:#dc3545;">Not applicable</span>
                                    </c:when>
                                    <c:when test="${r.status eq 'PICKED_UP'}">
                                        <span class="eta-pill">⏳ ~5–7 business days</span>
                                    </c:when>
                                    <c:otherwise>
                                        <span class="eta-pill">Pending pickup</span>
                                    </c:otherwise>
                                </c:choose>
                            </td>
                            <td><fmt:formatDate value="${r.requestedAt}" pattern="dd MMM yyyy"/></td>
                            <td>
                                <c:choose>
                                    <c:when test="${not empty r.adminNote}">${r.adminNote}</c:when>
                                    <c:otherwise><span class="text-muted">–</span></c:otherwise>
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

<script src="${pageContext.request.contextPath}/js/bootstrap.bundle.min.js"></script>
</body>
</html>
