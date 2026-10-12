<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="com.sibs.model.DeliveryBoy, com.sibs.util.DBConnection, java.sql.*" %>
<%
// Allow both: logged-in delivery boy OR new registration flow
DeliveryBoy db = (DeliveryBoy) session.getAttribute("deliveryBoy");
Integer dbId   = (Integer) session.getAttribute("pending_delivery_boy_id");

if (db != null) {
    dbId = db.getId();
} else if (dbId == null) {
    response.sendRedirect("delivery-register.jsp");
    return;
}

// Check if documents already submitted
boolean hasDocuments = false;
String aadhaarPath = null, panPath = null, licencePath = null, rcPath = null, photoPath = null;
String bankName = null, accountHolder = null, accountNumber = null, ifscCode = null;
String docStatus = null;

try (Connection con = DBConnection.getConnection()) {
    PreparedStatement ps = con.prepareStatement(
        "SELECT * FROM delivery_documents WHERE delivery_boy_id = ? ORDER BY id DESC LIMIT 1");
    ps.setInt(1, dbId);
    ResultSet rs = ps.executeQuery();
    if (rs.next()) {
        hasDocuments  = true;
        aadhaarPath   = rs.getString("aadhaar_path");
        panPath       = rs.getString("pan_path");
        licencePath   = rs.getString("licence_path");
        rcPath        = rs.getString("rc_path");
        photoPath     = rs.getString("photo_path");
        bankName      = rs.getString("bank_name");
        accountHolder = rs.getString("account_holder_name");
        accountNumber = rs.getString("account_number");
        ifscCode      = rs.getString("ifsc_code");
    }
} catch (Exception e) { /* fallback to upload form */ }

// Also check delivery boy status
String boyStatus = (db != null) ? db.getStatus() : "PENDING";

String error = request.getParameter("error");
String msg   = request.getParameter("msg");
%>
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>My Documents — SIBS Delivery</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<style>
*{margin:0;padding:0;box-sizing:border-box;font-family:'Inter',sans-serif;}
body{background:#f8fafc;min-height:100vh;}
/* Topbar */
.topbar{background:#0f172a;padding:0 20px;height:56px;display:flex;align-items:center;gap:12px;position:sticky;top:0;z-index:50;}
.topbar a{text-decoration:none;color:#cbd5e1;font-size:13px;font-weight:500;display:flex;align-items:center;gap:6px;}
.topbar a:hover{color:#f97316;}
.topbar .title{font-weight:700;font-size:15px;flex:1;text-align:center;color:#fff;}
/* Content */
.content{max-width:640px;margin:28px auto;padding:0 16px;}
/* Status banner */
.status-banner{border-radius:12px;padding:16px 20px;margin-bottom:22px;display:flex;align-items:center;gap:14px;}
.status-banner.pending{background:#fffbeb;border:1px solid #fde68a;}
.status-banner.approved{background:#f0fdf4;border:1px solid #bbf7d0;}
.status-banner.rejected{background:#fef2f2;border:1px solid #fecaca;}
.status-banner i{font-size:24px;}
.status-banner.pending i{color:#f59e0b;}
.status-banner.approved i{color:#16a34a;}
.status-banner.rejected i{color:#ef4444;}
.status-banner h3{font-size:14px;font-weight:700;margin-bottom:2px;}
.status-banner p{font-size:12px;color:#64748b;}
/* Doc card */
.card{background:#fff;border:1px solid #e2e8f0;border-radius:14px;padding:24px;margin-bottom:18px;box-shadow:0 1px 4px rgba(0,0,0,.06);}
.card-title{font-size:13px;font-weight:700;color:#64748b;text-transform:uppercase;letter-spacing:.5px;margin-bottom:16px;display:flex;align-items:center;gap:8px;}
.card-title i{color:#f97316;}
.doc-grid{display:grid;grid-template-columns:1fr 1fr;gap:12px;}
.doc-item{background:#f8fafc;border:1px solid #e2e8f0;border-radius:10px;padding:14px;display:flex;align-items:center;gap:12px;}
.doc-item i{font-size:22px;color:#f97316;flex-shrink:0;}
.doc-item .doc-info .lbl{font-size:11px;color:#64748b;font-weight:600;text-transform:uppercase;}
.doc-item .doc-info .val{font-size:12px;font-weight:600;color:#0f172a;margin-top:3px;}
.doc-item .doc-info a{font-size:12px;color:#2563eb;text-decoration:none;font-weight:500;}
.doc-item .doc-info a:hover{text-decoration:underline;}
.check{width:20px;height:20px;background:#dcfce7;border-radius:50%;display:flex;align-items:center;justify-content:center;margin-left:auto;flex-shrink:0;}
.check i{font-size:10px;color:#16a34a;}
.bank-row{display:grid;grid-template-columns:1fr 1fr;gap:12px;}
.bank-item .lbl{font-size:11px;color:#64748b;font-weight:600;text-transform:uppercase;letter-spacing:.3px;}
.bank-item .val{font-size:14px;font-weight:600;color:#0f172a;margin-top:4px;}
/* Upload form styles */
.progress{margin-bottom:28px;}
.progress-label{display:flex;justify-content:space-between;font-size:12px;color:#64748b;margin-bottom:6px;}
.progress-bar{height:6px;background:#e2e8f0;border-radius:6px;overflow:hidden;}
.progress-fill{height:100%;width:100%;background:linear-gradient(90deg,#f97316,#fb923c);border-radius:6px;}
.upload-grid{display:grid;grid-template-columns:1fr 1fr;gap:14px;}
.upload-box{border:2px dashed #e2e8f0;border-radius:12px;padding:16px;text-align:center;cursor:pointer;transition:.2s;position:relative;background:#fafafa;}
.upload-box:hover{border-color:#f97316;background:#fff7ed;}
.upload-box.has-file{border-color:#16a34a;background:#f0fdf4;}
.upload-box input[type=file]{position:absolute;inset:0;opacity:0;cursor:pointer;width:100%;height:100%;}
.upload-box i{font-size:22px;color:#94a3b8;margin-bottom:6px;display:block;}
.upload-box.has-file i{color:#16a34a;}
.upload-box span{font-size:12px;color:#64748b;font-weight:500;display:block;}
.upload-box .fname{font-size:11px;color:#16a34a;margin-top:4px;word-break:break-all;display:none;}
.upload-box.has-file .fname{display:block;}
.form-group{margin-bottom:14px;position:relative;}
label{display:block;font-size:13px;font-weight:500;color:#374151;margin-bottom:5px;}
input[type=text]{width:100%;padding:10px 12px 10px 36px;border:1px solid #e2e8f0;border-radius:8px;font-size:14px;outline:none;transition:.2s;}
input[type=text]:focus{border-color:#f97316;box-shadow:0 0 0 3px rgba(249,115,22,.1);}
.input-icon{position:absolute;left:11px;top:35px;color:#94a3b8;font-size:13px;}
.btn{width:100%;padding:13px;background:#f97316;color:#fff;border:none;border-radius:10px;font-size:15px;font-weight:600;cursor:pointer;margin-top:14px;transition:.2s;}
.btn:hover{background:#ea6c0a;}
.alert{padding:10px 14px;border-radius:8px;font-size:13px;margin-bottom:16px;display:flex;align-items:center;gap:8px;}
.alert-error{background:#fef2f2;border:1px solid #fecaca;color:#dc2626;}
.alert-info{background:#eff6ff;border:1px solid #bfdbfe;color:#1d4ed8;}
.section-lbl{font-size:13px;font-weight:700;color:#64748b;text-transform:uppercase;letter-spacing:.5px;margin:20px 0 12px;display:flex;align-items:center;gap:6px;}
.section-lbl i{color:#f97316;}
@media(max-width:500px){.doc-grid,.bank-row,.upload-grid{grid-template-columns:1fr;}}
</style>
</head>
<body>

<div class="topbar">
  <% if (db != null) { %>
  <a href="delivery-dashboard.jsp"><i class="fa fa-arrow-left"></i> Dashboard</a>
  <% } %>
  <span class="title"><i class="fa fa-file-alt"></i> My Documents</span>
</div>

<div class="content">

<% if (hasDocuments) { 
   // ── DOCUMENTS ALREADY SUBMITTED — show view ──────────────────────
%>

  <!-- Status Banner -->
  <% if ("APPROVED".equals(boyStatus)) { %>
  <div class="status-banner approved">
    <i class="fa fa-circle-check"></i>
    <div><h3>Documents Verified ✓</h3><p>Your account is fully approved. You can start delivering!</p></div>
  </div>
  <% } else if ("REJECTED".equals(boyStatus)) { %>
  <div class="status-banner rejected">
    <i class="fa fa-circle-xmark"></i>
    <div><h3>Documents Rejected</h3><p>Please contact support or re-submit your documents.</p></div>
  </div>
  <% } else { %>
  <div class="status-banner pending">
    <i class="fa fa-clock"></i>
    <div><h3>Under Review</h3><p>Your documents are submitted. Review takes 2–3 working days.</p></div>
  </div>
  <% } %>

  <!-- Identity Documents -->
  <div class="card">
    <div class="card-title"><i class="fa fa-id-card"></i> Identity Documents</div>
    <div class="doc-grid">
      <div class="doc-item">
        <i class="fa fa-address-card"></i>
        <div class="doc-info">
          <div class="lbl">Aadhaar Card</div>
          <% if (aadhaarPath != null) { %>
          <a href="<%=request.getContextPath()%>/<%=aadhaarPath%>" target="_blank"><i class="fa fa-eye"></i> View</a>
          <% } else { %><div class="val" style="color:#ef4444;">Not uploaded</div><% } %>
        </div>
        <% if (aadhaarPath != null) { %><div class="check"><i class="fa fa-check"></i></div><% } %>
      </div>
      <div class="doc-item">
        <i class="fa fa-credit-card"></i>
        <div class="doc-info">
          <div class="lbl">PAN Card</div>
          <% if (panPath != null) { %>
          <a href="<%=request.getContextPath()%>/<%=panPath%>" target="_blank"><i class="fa fa-eye"></i> View</a>
          <% } else { %><div class="val" style="color:#ef4444;">Not uploaded</div><% } %>
        </div>
        <% if (panPath != null) { %><div class="check"><i class="fa fa-check"></i></div><% } %>
      </div>
      <div class="doc-item">
        <i class="fa fa-id-badge"></i>
        <div class="doc-info">
          <div class="lbl">Driving Licence</div>
          <% if (licencePath != null) { %>
          <a href="<%=request.getContextPath()%>/<%=licencePath%>" target="_blank"><i class="fa fa-eye"></i> View</a>
          <% } else { %><div class="val" style="color:#ef4444;">Not uploaded</div><% } %>
        </div>
        <% if (licencePath != null) { %><div class="check"><i class="fa fa-check"></i></div><% } %>
      </div>
      <div class="doc-item">
        <i class="fa fa-car"></i>
        <div class="doc-info">
          <div class="lbl">Vehicle RC</div>
          <% if (rcPath != null) { %>
          <a href="<%=request.getContextPath()%>/<%=rcPath%>" target="_blank"><i class="fa fa-eye"></i> View</a>
          <% } else { %><div class="val" style="color:#ef4444;">Not uploaded</div><% } %>
        </div>
        <% if (rcPath != null) { %><div class="check"><i class="fa fa-check"></i></div><% } %>
      </div>
    </div>
  </div>

  <!-- Profile Photo -->
  <div class="card">
    <div class="card-title"><i class="fa fa-camera"></i> Profile Photo</div>
    <div class="doc-item" style="max-width:300px;">
      <i class="fa fa-user-circle"></i>
      <div class="doc-info">
        <div class="lbl">Passport-size Photo</div>
        <% if (photoPath != null) { %>
        <a href="<%=request.getContextPath()%>/<%=photoPath%>" target="_blank"><i class="fa fa-eye"></i> View Photo</a>
        <% } else { %><div class="val" style="color:#ef4444;">Not uploaded</div><% } %>
      </div>
      <% if (photoPath != null) { %><div class="check"><i class="fa fa-check"></i></div><% } %>
    </div>
  </div>

  <!-- Bank Details -->
  <div class="card">
    <div class="card-title"><i class="fa fa-building-columns"></i> Bank Account Details</div>
    <div class="bank-row">
      <div class="bank-item">
        <div class="lbl">Bank Name</div>
        <div class="val"><%=bankName != null ? bankName : "—"%></div>
      </div>
      <div class="bank-item">
        <div class="lbl">Account Holder</div>
        <div class="val"><%=accountHolder != null ? accountHolder : "—"%></div>
      </div>
      <div class="bank-item">
        <div class="lbl">Account Number</div>
        <div class="val"><%=accountNumber != null ? "XXXX" + accountNumber.substring(Math.max(0,accountNumber.length()-4)) : "—"%></div>
      </div>
      <div class="bank-item">
        <div class="lbl">IFSC Code</div>
        <div class="val"><%=ifscCode != null ? ifscCode : "—"%></div>
      </div>
    </div>
  </div>

<% } else {
   // ── NO DOCUMENTS YET — show upload form ─────────────────────────
%>

  <div class="card">
    <div style="text-align:center;margin-bottom:24px;">
      <i class="fa fa-motorcycle" style="font-size:38px;color:#f97316;"></i>
      <h2 style="font-size:20px;font-weight:700;color:#0f172a;margin-top:10px;">Upload Your Documents</h2>
      <p style="font-size:13px;color:#64748b;margin-top:4px;">Complete your profile to start delivering</p>
    </div>

    <div class="progress">
      <div class="progress-label"><span>Registration</span><span>Documents</span><span>Approval</span></div>
      <div class="progress-bar"><div class="progress-fill"></div></div>
    </div>

    <% if ("missing".equals(error)) { %>
    <div class="alert alert-error"><i class="fa fa-circle-exclamation"></i> Please upload all required documents.</div>
    <% } else if ("failed".equals(error)) { %>
    <div class="alert alert-error"><i class="fa fa-circle-exclamation"></i> Upload failed. Please try again.</div>
    <% } %>

    <div class="alert alert-info"><i class="fa fa-shield-halved"></i> Your documents are encrypted and stored securely.</div>

    <form action="deliveryDocUpload" method="post" enctype="multipart/form-data" onsubmit="return validateDocs()">

      <div class="section-lbl"><i class="fa fa-id-card"></i> Identity Documents</div>
      <div class="upload-grid">
        <div class="upload-box" id="box-aadhaar">
          <input type="file" name="aadhaar" id="f-aadhaar" accept="image/*,.pdf" onchange="fileChosen(this,'box-aadhaar')" required>
          <i class="fa fa-address-card"></i>
          <span>Aadhaar Card <span style="color:#ef4444">*</span></span>
          <div class="fname" id="fn-aadhaar"></div>
        </div>
        <div class="upload-box" id="box-pan">
          <input type="file" name="pan" id="f-pan" accept="image/*,.pdf" onchange="fileChosen(this,'box-pan')" required>
          <i class="fa fa-credit-card"></i>
          <span>PAN Card <span style="color:#ef4444">*</span></span>
          <div class="fname" id="fn-pan"></div>
        </div>
        <div class="upload-box" id="box-licence">
          <input type="file" name="licence" id="f-licence" accept="image/*,.pdf" onchange="fileChosen(this,'box-licence')" required>
          <i class="fa fa-id-badge"></i>
          <span>Driving Licence <span style="color:#ef4444">*</span></span>
          <div class="fname" id="fn-licence"></div>
        </div>
        <div class="upload-box" id="box-rc">
          <input type="file" name="rc" id="f-rc" accept="image/*,.pdf" onchange="fileChosen(this,'box-rc')" required>
          <i class="fa fa-car"></i>
          <span>Vehicle RC <span style="color:#ef4444">*</span></span>
          <div class="fname" id="fn-rc"></div>
        </div>
      </div>

      <div class="section-lbl"><i class="fa fa-camera"></i> Profile Photo</div>
      <div class="upload-grid" style="grid-template-columns:1fr;">
        <div class="upload-box" id="box-photo">
          <input type="file" name="photo" id="f-photo" accept="image/*" onchange="fileChosen(this,'box-photo')" required>
          <i class="fa fa-user-circle"></i>
          <span>Passport-size Photo <span style="color:#ef4444">*</span></span>
          <div class="fname" id="fn-photo"></div>
        </div>
      </div>

      <div class="section-lbl"><i class="fa fa-building-columns"></i> Bank Account Details</div>
      <div class="form-group">
        <label>Bank Name *</label>
        <i class="fa fa-landmark input-icon"></i>
        <input type="text" name="bankName" placeholder="e.g. State Bank of India" required maxlength="100">
      </div>
      <div class="form-group">
        <label>Account Holder Name *</label>
        <i class="fa fa-user input-icon"></i>
        <input type="text" name="accountHolder" placeholder="Name as on bank account" required maxlength="100">
      </div>
      <div class="form-group">
        <label>Account Number *</label>
        <i class="fa fa-hashtag input-icon"></i>
        <input type="text" name="accountNumber" placeholder="Enter account number" required maxlength="20" pattern="[0-9]{9,18}">
      </div>
      <div class="form-group">
        <label>IFSC Code *</label>
        <i class="fa fa-code input-icon"></i>
        <input type="text" name="ifscCode" placeholder="e.g. SBIN0001234" required maxlength="11" style="text-transform:uppercase">
      </div>

      <button class="btn" type="submit"><i class="fa fa-paper-plane"></i> Submit Documents</button>
      <p style="font-size:12px;color:#94a3b8;text-align:center;margin-top:10px;"><i class="fa fa-clock"></i> Review takes 2–3 working days.</p>
    </form>
  </div>

<% } %>
</div>

<script>
function fileChosen(input, boxId) {
  const box = document.getElementById(boxId);
  const fn  = document.getElementById('fn-' + boxId.replace('box-',''));
  if (input.files && input.files[0]) {
    box.classList.add('has-file');
    fn.textContent = '✓ ' + input.files[0].name;
  }
}
function validateDocs() {
  const required = ['f-aadhaar','f-pan','f-licence','f-rc','f-photo'];
  for (let id of required) {
    if (!document.getElementById(id).files.length) {
      alert('Please upload all required documents.'); return false;
    }
  }
  return true;
}
</script>
</body>
</html>
