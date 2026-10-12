<%-- ================================================================
     SNIPPET: Add this inside your existing myOrders.jsp
     inside the per-order action buttons section.

     Condition: show "Return" button only when:
       - order.status == "Delivered"
       - order.returnStatus is null (no existing request)
     ================================================================ --%>

<%@ taglib uri="jakarta.tags.core" prefix="c" %>

<%-- Inside your <c:forEach var="order" items="${orders}"> loop --%>

<c:if test="${order.status eq 'Delivered' and empty order.returnStatus}">
    <a href="${pageContext.request.contextPath}/ReturnProductServlet?orderId=${order.id}"
       class="btn btn-sm btn-outline-warning"
       title="Request a return for this item">
        ↩️ Return
    </a>
</c:if>

<c:if test="${not empty order.returnStatus}">
    <span class="badge bg-warning text-dark" style="font-size:.78rem; padding:5px 10px;">
        Return: ${order.returnStatus}
    </span>
</c:if>


<%-- ================================================================
     ALSO ADD: Navigation link to "My Returns" page
     In your customer navbar / sidebar:
     ================================================================ --%>
<li class="nav-item">
    <a class="nav-link" href="${pageContext.request.contextPath}/customer/myReturns.jsp">
        ↩️ My Returns
    </a>
</li>


<%-- ================================================================
     ALSO ADD: Admin sidebar entry for managing returns
     In your admin sidebar include (both admin AND staff see this):
     ================================================================ --%>
<li>
    <a href="${pageContext.request.contextPath}/AdminReturnServlet?action=list">
        ↩️ Manage Returns
    </a>
</li>

<%-- ================================================================
     STAFF SIDEBAR: same link — staff can view & process returns
     but the "Process Refund" button is hidden for staff in the UI
     ================================================================ --%>
