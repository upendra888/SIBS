<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*, com.sibs.util.DBConnection" %>
<%@ include file="includes/adminSidebar.jsp" %>
<%
if (!"ADMIN".equals(role) && !"STAFF".equals(role)) {
    response.sendRedirect(request.getContextPath() + "/dashboard.jsp");
    return;
}
String msg   = request.getParameter("msg");
String error = request.getParameter("error");
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Delivery Boy Approvals — SIBS</title>
</head>
<body>
<div class="content-area">

  <!-- Header -->
  <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:28px;">
    <div>
      <h1 style="font-size:22px;font-weight:700;color:var(--text);">
        <i class="fa fa-motorcycle" style="color:var(--primary);"></i> Delivery Boy Approvals
      </h1>
      <p style="color:var(--muted);font-size:14px;margin-top:4px;">Review submitted applications and approve or reject</p>
    </div>
  </div>

  <% if ("approved".equals(msg)) { %>
    <div style="background:#f0fdf4;border:1px solid #bbf7d0;color:#16a34a;padding:12px 16px;border-radius:8px;margin-bottom:20px;display:flex;align-items:center;gap:8px;">
      <i class="fa fa-circle-check"></i> Delivery boy approved and notified by email.
    </div>
  <% } else if ("rejected".equals(msg)) { %>
    <div style="background:#fef2f2;border:1px solid #fecaca;color:#dc2626;padding:12px 16px;border-radius:8px;margin-bottom:20px;display:flex;align-items:center;gap:8px;">
      <i class="fa fa-circle-xmark"></i> Application rejected. Delivery boy notified.
    </div>
  <% } else if ("err".equals(error)) { %>
    <div style="background:#fef2f2;border:1px solid #fecaca;color:#dc2626;padding:12px 16px;border-radius:8px;margin-bottom:20px;">
      <i class="fa fa-triangle-exclamation"></i> Action failed. Please try again.
    </div>
  <% } %>

  <%
  /* ── Tabs: PENDING | APPROVED | REJECTED ── */
  String tab = request.getParameter("tab");
  if (tab == null) tab = "PENDING";
  String statusFilter = tab.toUpperCase();
  %>

  <!-- Tabs -->
  <div style="display:flex;gap:4px;margin-bottom:24px;border-bottom:2px solid var(--border);padding-bottom:0;">
    <% String[] tabs = {"PENDING","ACTIVE","REJECTED","UNDER_REVIEW"};
       String[] labels = {"⏳ Pending","✅ Approved","❌ Rejected","🔍 Under Review"};
       for (int t=0;t<tabs.length;t++) {
           boolean active = tabs[t].equals(statusFilter); %>
    <a href="?tab=<%= tabs[t] %>"
       style="padding:10px 20px;font-size:13px;font-weight:600;text-decoration:none;border-radius:8px 8px 0 0;
              color:<%= active ? "#fff" : "var(--muted)" %>;
              background:<%= active ? "var(--primary)" : "transparent" %>;
              border-bottom:<%= active ? "2px solid var(--primary)" : "none" %>;">
      <%= labels[t] %>
    </a>
    <% } %>
  </div>

  <%
  /* ── Query: delivery boys + their documents ── */
  String sql = "SELECT db.id, db.name, db.email, db.phone, db.city, db.status, db.created_at, "
             + "d.aadhaar_path, d.pan_path, d.licence_path, d.rc_path, d.photo_path, "
             + "d.bank_name, d.account_holder_name, d.account_number, d.ifsc_code, d.submitted_at "
             + "FROM delivery_boys db "
             + "LEFT JOIN delivery_documents d ON db.id = d.delivery_boy_id "
             + "WHERE db.status = ? "
             + "ORDER BY db.created_at DESC";

  try (Connection con = DBConnection.getConnection();
       PreparedStatement ps = con.prepareStatement(sql)) {

    ps.setString(1, statusFilter);
    ResultSet rs = ps.executeQuery();
    boolean hasRows = false;
  %>

  <div style="display:flex;flex-direction:column;gap:20px;">
  <% while (rs.next()) { hasRows = true;
       int    dbId       = rs.getInt("id");
       String dbName     = rs.getString("name");
       String dbEmail    = rs.getString("email");
       String dbPhone    = rs.getString("phone");
       String dbCity     = rs.getString("city");
       String dbStatus   = rs.getString("status");
       String aadhaar    = rs.getString("aadhaar_path");
       String pan        = rs.getString("pan_path");
       String licence    = rs.getString("licence_path");
       String rc         = rs.getString("rc_path");
       String photo      = rs.getString("photo_path");
       String bankName   = rs.getString("bank_name");
       String bankHolder = rs.getString("account_holder_name");
       String bankAcct   = rs.getString("account_number");
       String ifsc       = rs.getString("ifsc_code");
       String submitted  = rs.getString("submitted_at");
  %>
    <div style="background:#fff;border:1px solid var(--border);border-radius:14px;overflow:hidden;box-shadow:var(--shadow);">

      <!-- Card header -->
      <div style="display:flex;align-items:center;justify-content:space-between;padding:18px 24px;background:#f8fafc;border-bottom:1px solid var(--border);">
        <div style="display:flex;align-items:center;gap:14px;">
          <% if (photo != null) { %>
            <img src="<%= request.getContextPath() + "/" + photo %>"
                 style="width:52px;height:52px;border-radius:50%;object-fit:cover;border:2px solid var(--border);">
          <% } else { %>
            <div style="width:52px;height:52px;border-radius:50%;background:#e2e8f0;display:flex;align-items:center;justify-content:center;">
              <i class="fa fa-user" style="color:#94a3b8;font-size:22px;"></i>
            </div>
          <% } %>
          <div>
            <div style="font-size:16px;font-weight:700;color:var(--text);"><%= dbName %></div>
            <div style="font-size:13px;color:var(--muted);margin-top:2px;">
              <i class="fa fa-envelope" style="font-size:11px;"></i> <%= dbEmail %> &nbsp;
              <i class="fa fa-phone" style="font-size:11px;"></i> <%= dbPhone %>
              <% if (dbCity != null) { %> &nbsp;<i class="fa fa-location-dot" style="font-size:11px;"></i> <%= dbCity %><% } %>
            </div>
          </div>
        </div>
        <div>
          <span style="padding:5px 14px;border-radius:20px;font-size:12px;font-weight:700;
            background:<%= "PENDING".equals(dbStatus) ? "#fef9c3" : "ACTIVE".equals(dbStatus) ? "#f0fdf4" : "REJECTED".equals(dbStatus) ? "#fef2f2" : "#eff6ff" %>;
            color:<%= "PENDING".equals(dbStatus) ? "#92400e" : "ACTIVE".equals(dbStatus) ? "#16a34a" : "REJECTED".equals(dbStatus) ? "#dc2626" : "#2563eb" %>;">
            <%= dbStatus %>
          </span>
        </div>
      </div>

      <!-- Documents grid -->
      <div style="padding:20px 24px;">
        <% if (aadhaar != null) { %>
        <div style="font-size:12px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.4px;margin-bottom:12px;">
          <i class="fa fa-folder-open" style="color:var(--primary);"></i> Submitted Documents
          <% if (submitted != null) { %><span style="font-weight:400;margin-left:8px;">— <%= submitted.substring(0,10) %></span><% } %>
        </div>
        <div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(130px,1fr));gap:10px;margin-bottom:18px;">
          <% String[][] docs = {
              {"Aadhaar Card", aadhaar, "fa-address-card"},
              {"PAN Card", pan, "fa-credit-card"},
              {"Driving Licence", licence, "fa-id-badge"},
              {"Vehicle RC", rc, "fa-car"},
              {"Profile Photo", photo, "fa-camera"}
          };
          for (String[] doc : docs) {
              if (doc[1] == null) continue;
              boolean isImg = doc[1].matches(".*\\.(jpg|jpeg|png|gif|webp)$");
          %>
          <a href="<%= request.getContextPath() + "/" + doc[1] %>" target="_blank"
             style="display:flex;flex-direction:column;align-items:center;gap:6px;padding:12px;border:1px solid var(--border);
                    border-radius:10px;background:#fafafa;text-decoration:none;color:var(--text);transition:.15s;"
             onmouseover="this.style.borderColor='var(--primary)'"
             onmouseout="this.style.borderColor='var(--border)'">
            <% if (isImg) { %>
              <img src="<%= request.getContextPath() + "/" + doc[1] %>"
                   style="width:60px;height:60px;object-fit:cover;border-radius:8px;">
            <% } else { %>
              <i class="fa fa-file-pdf" style="font-size:36px;color:#ef4444;"></i>
            <% } %>
            <span style="font-size:11px;font-weight:500;text-align:center;"><%= doc[0] %></span>
            <span style="font-size:10px;color:var(--primary);"><i class="fa fa-arrow-up-right-from-square"></i> View</span>
          </a>
          <% } %>
        </div>

        <!-- Bank details -->
        <div style="background:#f8fafc;border:1px solid var(--border);border-radius:10px;padding:14px;margin-bottom:18px;">
          <div style="font-size:12px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.4px;margin-bottom:10px;">
            <i class="fa fa-building-columns" style="color:var(--primary);"></i> Bank Details
          </div>
          <div style="display:grid;grid-template-columns:1fr 1fr;gap:8px;font-size:13px;">
            <div><span style="color:var(--muted);">Bank:</span> <strong><%= bankName != null ? bankName : "—" %></strong></div>
            <div><span style="color:var(--muted);">Account Holder:</span> <strong><%= bankHolder != null ? bankHolder : "—" %></strong></div>
            <div><span style="color:var(--muted);">Account No:</span> <strong><%= bankAcct != null ? bankAcct : "—" %></strong></div>
            <div><span style="color:var(--muted);">IFSC:</span> <strong><%= ifsc != null ? ifsc : "—" %></strong></div>
          </div>
        </div>
        <% } else { %>
        <div style="color:var(--muted);font-size:13px;padding:8px 0;">
          <i class="fa fa-circle-info"></i> No documents uploaded yet.
        </div>
        <% } %>

        <!-- Action buttons (only for PENDING / UNDER_REVIEW) -->
        <% if ("PENDING".equals(dbStatus) || "UNDER_REVIEW".equals(dbStatus)) { %>
        <div style="display:flex;gap:10px;flex-wrap:wrap;">
          <form action="<%= request.getContextPath() %>/deliveryApproval" method="post" style="display:inline;">
            <input type="hidden" name="deliveryBoyId" value="<%= dbId %>">
            <input type="hidden" name="action" value="approve">
            <button type="submit"
                    style="padding:9px 22px;background:#16a34a;color:#fff;border:none;border-radius:8px;font-size:13px;font-weight:600;cursor:pointer;">
              <i class="fa fa-check"></i> Approve
            </button>
          </form>
          <form action="<%= request.getContextPath() %>/deliveryApproval" method="post" style="display:inline;">
            <input type="hidden" name="deliveryBoyId" value="<%= dbId %>">
            <input type="hidden" name="action" value="review">
            <button type="submit"
                    style="padding:9px 22px;background:#2563eb;color:#fff;border:none;border-radius:8px;font-size:13px;font-weight:600;cursor:pointer;">
              <i class="fa fa-magnifying-glass"></i> Mark Under Review
            </button>
          </form>
          <form action="<%= request.getContextPath() %>/deliveryApproval" method="post" style="display:inline;"
                onsubmit="return confirm('Reject this application?')">
            <input type="hidden" name="deliveryBoyId" value="<%= dbId %>">
            <input type="hidden" name="action" value="reject">
            <button type="submit"
                    style="padding:9px 22px;background:#ef4444;color:#fff;border:none;border-radius:8px;font-size:13px;font-weight:600;cursor:pointer;">
              <i class="fa fa-xmark"></i> Reject
            </button>
          </form>
        </div>
        <% } %>
      </div>
    </div>
  <% } // end while

  if (!hasRows) { %>
    <div style="text-align:center;padding:60px 20px;color:var(--muted);">
      <i class="fa fa-inbox" style="font-size:48px;margin-bottom:12px;display:block;opacity:.3;"></i>
      <p style="font-size:15px;">No <strong><%= statusFilter %></strong> applications at the moment.</p>
    </div>
  <% } %>
  </div>

  <% } catch (Exception e) { e.printStackTrace(); } %>
</div>
</body>
</html>
