<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="com.sibs.dao.CodLedgerDAO" %>
<%@ page import="com.sibs.dao.CodLedgerDAO.CodEntry" %>
<%@ page import="com.sibs.model.DeliveryBoy" %>
<%@ page import="java.util.List" %>
<%
    DeliveryBoy deliveryBoy = (DeliveryBoy) session.getAttribute("deliveryBoy");
    if (deliveryBoy == null) {
        response.sendRedirect(request.getContextPath() + "/delivery-login.jsp");
        return;
    }
    int deliveryBoyId = deliveryBoy.getId();

    CodLedgerDAO dao = new CodLedgerDAO();

    double pendingCash   = dao.getPendingTotal(deliveryBoyId); // full cash physically held (including delivery charge)
    double totalRemitted = dao.getRemittedTotal(deliveryBoyId);

    double totalCollected = 0;
    try {
        double[] summary = dao.getRemittanceSummary(deliveryBoyId);
        if (summary != null && summary.length > 0) totalCollected = summary[0];
    } catch (Exception ex) {
        totalCollected = pendingCash + totalRemitted;
    }

    List<CodEntry> entries = dao.getByDeliveryBoy(deliveryBoyId);
    int totalEntries = (entries != null) ? entries.size() : 0;
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>COD Cash Ledger - SIBS</title>
    <style>
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
        body { font-family: 'Segoe UI', Arial, sans-serif; background: #eef0f8; color: #333; min-height: 100vh; }

        .back-link { display: inline-flex; align-items: center; gap: 6px; padding: 16px 22px; font-size: 14px; color: #555; text-decoration: none; }
        .back-link:hover { color: #111; }

        h1 { text-align: center; font-size: 22px; font-weight: 700; color: #222; margin: 4px 0 28px; }

        /* ── Summary cards ── */
        .summary-row { display: flex; justify-content: center; gap: 20px; flex-wrap: wrap; padding: 0 24px; margin-bottom: 36px; }
        .card { background: #fff; border-radius: 14px; padding: 22px 36px; min-width: 190px; text-align: center; box-shadow: 0 2px 10px rgba(0,0,0,0.07); }
        .card .label { font-size: 11px; font-weight: 600; letter-spacing: 0.9px; color: #999; text-transform: uppercase; margin-bottom: 10px; }
        .card .amount { font-size: 30px; font-weight: 800; }
        .card.pending  .amount { color: #c07000; }
        .card.collected .amount { color: #1a56cc; }
        .card.remitted  .amount { color: #1a9e4a; }

        /* ── Section heading ── */
        .section-header { display: flex; align-items: center; justify-content: space-between; padding: 0 28px; margin-bottom: 14px; }
        .section-title { font-size: 15px; font-weight: 700; color: #333; }
        .entry-count { font-size: 13px; color: #888; background: #f0f0f6; border-radius: 20px; padding: 3px 12px; }

        /* ── Table ── */
        .table-wrap { padding: 0 20px 48px; overflow-x: auto; }
        table { width: 100%; border-collapse: collapse; background: #fff; border-radius: 12px; overflow: hidden; box-shadow: 0 2px 10px rgba(0,0,0,0.07); }
        thead tr { background: #f5f6fa; }
        th, td { padding: 13px 16px; font-size: 13px; text-align: left; border-bottom: 1px solid #f0f0f0; white-space: nowrap; }
        th { font-weight: 600; color: #888; text-transform: uppercase; letter-spacing: 0.5px; font-size: 11px; }
        tbody tr:last-child td { border-bottom: none; }
        tbody tr:hover { background: #fafbff; transition: background 0.15s; }

        td.order-id { font-weight: 600; color: #444; }
        td.customer { font-weight: 500; }
        td.amount-cell { font-weight: 600; color: #222; }
        td.muted { color: #aaa; font-style: italic; }

        /* ── Status badges ── */
        .badge { display: inline-block; padding: 4px 12px; border-radius: 20px; font-size: 11px; font-weight: 700; letter-spacing: 0.4px; }
        .badge.collected { background: #dbeafe; color: #1e40af; }
        .badge.remitted  { background: #d1fae5; color: #065f46; }

        /* ── Empty state ── */
        .empty-state { text-align: center; padding: 70px 20px; }
        .empty-state p { font-size: 15px; color: #aaa; margin-top: 16px; }
    </style>
</head>
<body>

<a class="back-link" href="javascript:history.back()">&#8592; Back</a>
<h1>&#128181; COD Cash Ledger</h1>

<div class="summary-row">
    <div class="card pending">
        <div class="label">Pending Cash</div>
        <div class="amount">&#8377;<%= String.format("%.0f", pendingCash) %></div>
    </div>
    <div class="card collected">
        <div class="label">Total Collected</div>
        <div class="amount">&#8377;<%= String.format("%.0f", totalCollected) %></div>
    </div>
    <div class="card remitted">
        <div class="label">Total Remitted</div>
        <div class="amount">&#8377;<%= String.format("%.0f", totalRemitted) %></div>
    </div>
</div>

<div class="section-header">
    <span class="section-title">All COD Entries</span>
    <% if (totalEntries > 0) { %>
        <span class="entry-count"><%= totalEntries %> <%= totalEntries == 1 ? "entry" : "entries" %></span>
    <% } %>
</div>

<% if (entries == null || entries.isEmpty()) { %>
    <div class="empty-state">
        <svg width="68" height="60" viewBox="0 0 68 60" fill="none" xmlns="http://www.w3.org/2000/svg">
            <ellipse cx="34" cy="54" rx="22" ry="6" fill="#ddd"/>
            <rect x="12" y="36" width="44" height="18" fill="#ddd"/>
            <ellipse cx="34" cy="36" rx="22" ry="6" fill="#ccc"/>
            <rect x="12" y="22" width="44" height="16" fill="#ccc"/>
            <ellipse cx="34" cy="22" rx="22" ry="6" fill="#bbb"/>
            <rect x="12" y="10" width="44" height="14" fill="#bbb"/>
            <ellipse cx="34" cy="10" rx="22" ry="6" fill="#aaa"/>
        </svg>
        <p>No COD entries yet.</p>
    </div>
<% } else { %>
    <div class="table-wrap">
        <table>
            <thead>
                <tr>
                    <th>#</th>
                    <th>Order ID</th>
                    <th>Customer</th>
                    <th>Product</th>
                    <th>Amount (&#8377;)</th>
                    <th>Delivery Charge (&#8377;)</th>
                    <th>Remittance (&#8377;)</th>
                    <th>Status</th>
                    <th>Collected At</th>
                    <th>Remitted At</th>
                    <th>Note</th>
                </tr>
            </thead>
            <tbody>
            <%
                int rowNum = 1;
                for (CodEntry e : entries) {
                    String badgeClass = "REMITTED".equalsIgnoreCase(e.status) ? "remitted" : "collected";
                    boolean hasNote       = e.note        != null && !e.note.isEmpty();
                    boolean hasRemittedAt = e.remittedAt  != null && !e.remittedAt.isEmpty();
                    boolean hasCustomer   = e.customerName != null && !e.customerName.isEmpty();
                    boolean hasProduct    = e.productName  != null && !e.productName.isEmpty();
                    boolean hasCollectedAt = e.collectedAt != null && !e.collectedAt.isEmpty();
            %>
                <tr>
                    <td><%= rowNum++ %></td>
                    <td class="order-id">#<%= e.orderId %></td>
                    <td class="<%= hasCustomer ? "customer" : "muted" %>"><%= hasCustomer ? e.customerName : "—" %></td>
                    <td class="<%= hasProduct  ? "" : "muted" %>"><%= hasProduct  ? e.productName  : "—" %></td>
                    <td class="amount-cell">&#8377;<%= String.format("%.2f", e.amount) %></td>
                    <td class="amount-cell">&#8377;<%= String.format("%.2f", e.deliveryCharge) %></td>
                    <td class="amount-cell">&#8377;<%= String.format("%.2f", e.remittanceAmount) %></td>
                    <td><span class="badge <%= badgeClass %>"><%= e.status %></span></td>
                    <td class="<%= hasCollectedAt ? "" : "muted" %>"><%= hasCollectedAt ? e.collectedAt : "—" %></td>
                    <td class="<%= hasRemittedAt  ? "" : "muted" %>"><%= hasRemittedAt  ? e.remittedAt  : "—" %></td>
                    <td class="<%= hasNote        ? "" : "muted" %>"><%= hasNote        ? e.note        : "—" %></td>
                </tr>
            <% } %>
            </tbody>
        </table>
    </div>
<% } %>

</body>
</html>
