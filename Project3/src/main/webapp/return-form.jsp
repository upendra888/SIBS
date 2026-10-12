<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="jakarta.tags.core" prefix="c" %>
<%@ taglib uri="jakarta.tags.fmt"  prefix="fmt" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Return Product – SIBS</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/bootstrap.min.css">
    <style>
        :root {
            --accent:   #e84c3d;
            --accent-dk:#c0392b;
            --bg:       #f8f9fa;
            --card-bg:  #ffffff;
        }

        body { background: var(--bg); font-family: 'Segoe UI', sans-serif; }

        .return-card {
            max-width: 680px;
            margin: 40px auto;
            background: var(--card-bg);
            border-radius: 12px;
            box-shadow: 0 4px 24px rgba(0,0,0,.08);
            overflow: hidden;
        }

        .return-header {
            background: var(--accent);
            color: #fff;
            padding: 24px 32px;
        }
        .return-header h3 { margin: 0; font-weight: 700; }
        .return-header p  { margin: 4px 0 0; opacity: .85; font-size: .9rem; }

        .return-body { padding: 32px; }

        /* Product summary strip */
        .product-strip {
            display: flex;
            align-items: center;
            gap: 16px;
            background: #fdf3f2;
            border: 1px solid #f5c6c2;
            border-radius: 8px;
            padding: 16px;
            margin-bottom: 28px;
        }
        .product-strip img {
            width: 72px; height: 72px;
            object-fit: cover; border-radius: 8px;
        }
        .product-strip .info strong { display: block; font-size: 1.05rem; }
        .product-strip .info span  { font-size: .88rem; color: #666; }

        /* Form */
        label { font-weight: 600; font-size: .88rem; color: #444; margin-bottom: 4px; }

        .reason-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 10px;
            margin-bottom: 20px;
        }
        .reason-card {
            border: 2px solid #dee2e6;
            border-radius: 8px;
            padding: 12px 14px;
            cursor: pointer;
            transition: border-color .2s, background .2s;
            display: flex; align-items: center; gap: 10px;
            font-size: .9rem;
        }
        .reason-card input[type="radio"] { accent-color: var(--accent); }
        .reason-card:has(input:checked) {
            border-color: var(--accent);
            background: #fdf3f2;
        }

        textarea { resize: vertical; min-height: 100px; }
        /* Item selection grid */
        .item-select-grid {
            display: flex;
            flex-direction: column;
            gap: 10px;
        }
        .item-select-card {
            display: flex;
            align-items: center;
            gap: 14px;
            border: 2px solid #dee2e6;
            border-radius: 10px;
            padding: 12px 16px;
            cursor: pointer;
            transition: border-color .2s, background .2s;
            position: relative;
        }
        .item-select-card:has(input:checked) {
            border-color: var(--accent);
            background: #fdf3f2;
        }
        .item-select-card input[type="radio"] { display: none; }
        .item-select-card img {
            width: 60px; height: 60px;
            object-fit: cover; border-radius: 8px;
            border: 1px solid #eee;
        }
        .item-select-card .item-info { flex: 1; }
        .item-select-card .item-info strong { display: block; font-size: .95rem; }
        .item-select-card .item-info span  { font-size: .83rem; color: #666; }
        .item-select-card .item-check {
            font-size: 1.3rem; color: #dee2e6; transition: color .2s;
        }
        .item-select-card:has(input:checked) .item-check { color: var(--accent); }


        .refund-badge {
            display: inline-flex; align-items: center; gap: 6px;
            background: #e8f5e9; color: #2e7d32;
            border-radius: 20px; padding: 6px 14px;
            font-size: .85rem; font-weight: 600;
        }

        .btn-return {
            background: var(--accent);
            color: #fff;
            border: none;
            padding: 12px 32px;
            border-radius: 8px;
            font-weight: 700;
            font-size: 1rem;
            transition: background .2s;
        }
        .btn-return:hover { background: var(--accent-dk); color: #fff; }

        .policy-note {
            font-size: .82rem;
            color: #888;
            margin-top: 20px;
            border-top: 1px solid #eee;
            padding-top: 16px;
        }
    </style>
</head>
<body>

<%@ include file="/includes/customerNavbar.jsp" %>

<div class="return-card">

    <!-- Header -->
    <div class="return-header">
        <h3>📦 Request a Return</h3>
        <p>Order #<strong>${order.id}</strong> &nbsp;·&nbsp; Placed on ${order.orderDate}</p>
    </div>

    <div class="return-body">

        <!-- Error message -->
        <c:if test="${not empty error}">
            <div class="alert alert-danger">${error}</div>
        </c:if>

        <!-- Return form -->
        <form action="${pageContext.request.contextPath}/ReturnProductServlet" method="post"
              onsubmit="return validateForm()">

            <input type="hidden" name="orderId"       value="${order.id}">
            <input type="hidden" name="groupId"       value="${order.groupId}">
            <input type="hidden" name="paymentMethod" value="${order.paymentMethod}">
            <!-- productId and orderTotal will be set dynamically based on selected item -->
            <input type="hidden" name="productId"     id="selectedProductId"  value="">
            <input type="hidden" name="orderTotal"    id="selectedOrderTotal" value="">

            <!-- Item Selection -->
            <div class="mb-4">
                <label class="d-block mb-2">Select Item to Return *</label>
                <c:choose>
                    <c:when test="${not empty order.items}">
                        <div class="item-select-grid" id="itemSelectGrid">
                            <c:forEach var="item" items="${order.items}">
                                <label class="item-select-card">
                                    <input type="radio" name="selectedItemProductId" value="${item.productId}" class="item-radio" onchange="selectItem('${item.productId}', '${item.total}', '${item.productName}')">
                                    <img src="${pageContext.request.contextPath}/${not empty item.productImage ? item.productImage : 'images/default.png'}"
                                         alt="${item.productName}"
                                         onerror="this.src='${pageContext.request.contextPath}/images/placeholder.png'">
                                    <div class="item-info">
                                        <strong>${item.productName}</strong>
                                        <span>Qty: ${item.quantity > 0 ? item.quantity : 1} &nbsp;·&nbsp; ₹<fmt:formatNumber value="${item.total}" pattern="#,##0.00"/></span>
                                    </div>
                                    <span class="item-check"><i class="bi bi-check-circle-fill"></i></span>
                                </label>
                            </c:forEach>
                        </div>
                        <div id="itemError" class="text-danger small d-none mt-1">Please select an item to return.</div>
                    </c:when>
                    <c:otherwise>
                        <%-- Fallback: single item order --%>
                        <div class="product-strip">
                            <img src="${pageContext.request.contextPath}/${not empty order.productImage ? order.productImage : 'images/default.png'}"
                                 alt="${order.productName}"
                                 onerror="this.src='${pageContext.request.contextPath}/images/placeholder.png'">
                            <div class="info">
                                <strong>${not empty order.productName ? order.productName : 'Your Order'}</strong>
                                <span>Qty: ${order.quantity > 0 ? order.quantity : 1} &nbsp;·&nbsp; ₹<fmt:formatNumber value="${order.total}" pattern="#,##0.00"/></span>
                            </div>
                        </div>
                        <script>
                        document.getElementById('selectedProductId').value  = '${order.productId}';
                        document.getElementById('selectedOrderTotal').value = '${order.total}';
                        </script>
                    </c:otherwise>
                </c:choose>
            </div>

            <!-- Reason selection -->
            <div class="mb-3">
                <label>Reason for Return *</label>
                <div class="reason-grid" id="reasonGrid">
                    <label class="reason-card">
                        <input type="radio" name="reason" value="Damaged / Defective"> 🔨 Damaged / Defective
                    </label>
                    <label class="reason-card">
                        <input type="radio" name="reason" value="Wrong Item Received"> 📦 Wrong Item Received
                    </label>
                    <label class="reason-card">
                        <input type="radio" name="reason" value="Item Not As Described"> 🖼️ Not As Described
                    </label>
                    <label class="reason-card">
                        <input type="radio" name="reason" value="Quality Not Satisfactory"> 👎 Poor Quality
                    </label>
                    <label class="reason-card">
                        <input type="radio" name="reason" value="Missing Items / Parts"> 🔍 Missing Items / Parts
                    </label>
                    <label class="reason-card">
                        <input type="radio" name="reason" value="Defective / Not Working"> ⚡ Defective / Not Working
                    </label>
                    <label class="reason-card">
                        <input type="radio" name="reason" value="Changed My Mind"> 💭 Changed My Mind
                    </label>
                    <label class="reason-card">
                        <input type="radio" name="reason" value="Other"> ✏️ Other
                    </label>
                </div>
                <div id="reasonError" class="text-danger small d-none">Please select a reason.</div>
            </div>

            <!-- Description -->
            <div class="mb-4">
                <label for="description">Additional Details <span class="text-muted fw-normal">(optional)</span></label>
                <textarea id="description" name="description" class="form-control"
                          placeholder="Describe the issue in more detail…"></textarea>
            </div>

            <!-- Refund info -->
            <div class="mb-4">
                <label>Expected Refund</label><br>
                <span class="refund-badge">
                    ✅ ₹<span id="refundAmtDisplay">—</span>
                    &nbsp;–&nbsp;
                    <c:choose>
                        <c:when test="${order.paymentMethod eq 'COD'}">Wallet Credit</c:when>
                        <c:otherwise>Back to Original Payment</c:otherwise>
                    </c:choose>
                </span>
            </div>

            <!-- Submit -->
            <button type="submit" class="btn btn-return">Submit Return Request</button>
            <a href="${pageContext.request.contextPath}/my-orders.jsp"
               class="btn btn-outline-secondary ms-2">Cancel</a>

            <div class="policy-note">
                🛡️ Returns are accepted within <strong>14 days</strong> of delivery.<br>
                🚚 <strong>Return shipping is free</strong> — our delivery partner will pick up the item from your address.<br>
                💰 Refunds are processed within <strong>5–7 business days</strong> after pickup is confirmed.<br>
                ⚠️ Partial refunds may apply if the item is returned incomplete or shows signs of use beyond inspection.
            </div>
        </form>
    </div>
</div>

<script>
function selectItem(productId, total, productName) {
    document.getElementById('selectedProductId').value  = productId;
    document.getElementById('selectedOrderTotal').value = total;
    document.getElementById('refundAmtDisplay').textContent = parseFloat(total).toFixed(2);
    var err = document.getElementById('itemError');
    if (err) err.classList.add('d-none');
}

function validateForm() {
    // Check item selection (only if multi-item grid exists)
    var grid = document.getElementById('itemSelectGrid');
    if (grid) {
        var selPid = document.getElementById('selectedProductId').value;
        if (!selPid) {
            document.getElementById('itemError').classList.remove('d-none');
            return false;
        }
    }
    // Check reason selection
    const selected = document.querySelector('input[name="reason"]:checked');
    if (!selected) {
        document.getElementById('reasonError').classList.remove('d-none');
        return false;
    }
    return true;
}
</script>

<script src="${pageContext.request.contextPath}/js/bootstrap.bundle.min.js"></script>
</body>
</html>
