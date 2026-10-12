<%@ page import="com.sibs.model.User" %>
<%
User user = (User)session.getAttribute("user");
if(user == null || !"ADMIN".equals(user.getRole())){
    response.sendRedirect("login.jsp");
    return;
}
%>
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Add Product — SIBS</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<style>
:root{--bg:#f8fafc;--surface:#fff;--border:#e2e8f0;--text:#0f172a;--muted:#64748b;--primary:#2563eb;--success:#16a34a;}
[data-theme="dark"]{--bg:#0f172a;--surface:#1e293b;--border:#334155;--text:#f1f5f9;--muted:#94a3b8;}
*{margin:0;padding:0;box-sizing:border-box;font-family:'Inter',sans-serif;}
body{background:var(--bg);color:var(--text);min-height:100vh;}
.topbar{background:var(--surface);border-bottom:1px solid var(--border);padding:0 24px;height:60px;display:flex;align-items:center;gap:10px;position:sticky;top:0;z-index:50;}
.topbar a{color:var(--muted);text-decoration:none;font-size:13px;display:flex;align-items:center;gap:5px;}
.topbar a:hover{color:var(--primary);}
.page-title{font-weight:700;font-size:16px;}
.dark-btn{background:none;border:1px solid var(--border);width:34px;height:34px;border-radius:8px;cursor:pointer;color:var(--muted);margin-left:auto;}
.layout{max-width:820px;margin:28px auto;padding:0 16px;display:grid;grid-template-columns:200px 1fr;gap:24px;}
@media(max-width:640px){.layout{grid-template-columns:1fr;}}
/* IMAGE UPLOAD */
.img-panel{background:var(--surface);border:1px solid var(--border);border-radius:12px;padding:20px;text-align:center;height:fit-content;}
.img-preview-box{width:140px;height:140px;border-radius:10px;border:2px dashed var(--border);display:flex;align-items:center;justify-content:center;margin:0 auto 12px;background:var(--bg);overflow:hidden;cursor:pointer;transition:.15s;}
.img-preview-box:hover{border-color:var(--primary);}
.img-preview-box img{width:100%;height:100%;object-fit:contain;display:none;}
.img-preview-box .placeholder{color:var(--muted);font-size:12px;text-align:center;padding:10px;}
.img-preview-box i{font-size:28px;color:var(--muted);margin-bottom:6px;display:block;}
.file-input{display:none;}
.upload-label{font-size:12px;color:var(--primary);cursor:pointer;font-weight:500;}
/* FORM */
.form-card{background:var(--surface);border:1px solid var(--border);border-radius:12px;padding:24px;}
.form-card h3{font-size:15px;font-weight:700;margin-bottom:20px;padding-bottom:12px;border-bottom:1px solid var(--border);}
.form-row{display:grid;grid-template-columns:1fr 1fr;gap:14px;margin-bottom:14px;}
@media(max-width:480px){.form-row{grid-template-columns:1fr;}}
.field{margin-bottom:14px;}
.field label{display:block;font-size:12px;font-weight:600;color:var(--muted);margin-bottom:6px;text-transform:uppercase;letter-spacing:.4px;}
.field input,.field select{width:100%;padding:9px 12px;border:1px solid var(--border);border-radius:7px;background:var(--bg);color:var(--text);font-size:13px;outline:none;transition:.15s;}
.field input:focus,.field select:focus{border-color:var(--primary);background:var(--surface);}
.field input.error,.field select.error{border-color:var(--danger);}
.submit-btn{width:100%;padding:11px;background:var(--success);color:#fff;border:none;border-radius:8px;cursor:pointer;font-weight:600;font-size:14px;margin-top:6px;transition:.15s;display:flex;align-items:center;justify-content:center;gap:8px;}
.submit-btn:hover{background:#15803d;}
</style>
</head>
<body>

<div class="topbar">
  <a href="products.jsp"><i class="fa fa-arrow-left"></i> Products</a>
  <span style="color:var(--border);">|</span>
  <span class="page-title">Add Product</span>
  <button class="dark-btn" onclick="toggleDark()"><i class="fa fa-moon"></i></button>
</div>

<div class="layout">
  <!-- IMAGE PANEL -->
  <div class="img-panel">
    <div class="img-preview-box" onclick="document.getElementById('imgInput').click()">
      <div class="placeholder" id="imgPlaceholder"><i class="fa fa-image"></i>Click to upload</div>
      <img id="imgPreview">
    </div>
    <input type="file" id="imgInput" class="file-input" accept="image/*" onchange="previewImage(event)">
    <label for="imgInput" class="upload-label"><i class="fa fa-upload"></i> Choose image</label>
    <p style="font-size:11px;color:var(--muted);margin-top:6px;">JPG, PNG, WEBP<br>Max 5MB</p>
  </div>

  <!-- FORM CARD -->
  <div class="form-card">
    <h3><i class="fa fa-plus-circle" style="color:var(--success);"></i> New Product</h3>
    <form action="<%=request.getContextPath()%>/addProduct" method="post" enctype="multipart/form-data" id="productForm" onsubmit="return validateForm()">
      <!-- hidden image field wired to the shared input -->
      <input type="file" name="image" id="hiddenImgInput" style="display:none;" accept="image/*" required>

      <div class="field">
        <label>Product Name *</label>
        <input type="text" name="name" id="fname" placeholder="e.g. Fresh Tomatoes" required>
      </div>

      <div class="form-row">
        <div class="field" style="margin:0;">
          <label>Price (₹) *</label>
          <input type="number" step="0.01" min="0" name="price" id="fprice" placeholder="0.00" required>
        </div>
        <div class="field" style="margin:0;">
          <label>Stock Quantity *</label>
          <input type="number" min="0" name="quantity" id="fqty" placeholder="0" required>
        </div>
      </div>

      <div class="form-row">
        <div class="field" style="margin:0;">
          <label>Category *</label>
          <select name="category" id="fcat" required>
            <option value="" disabled selected>Select category</option>
            <option value="vegetables">Vegetables</option>
            <option value="fruits">Fruits</option>
            <option value="non-veg">Non-Veg</option>
            <option value="dairy">Dairy</option>
            <option value="beverages">Beverages</option>
            <option value="electronics">Electronics</option>
            <option value="clothing">Clothing</option>
            <option value="snacks">Snacks</option>
          </select>
        </div>
        <div class="field" style="margin:0;">
          <label>Unit *</label>
          <select name="unit" id="funit" required>
            <option value="" disabled selected>Select unit</option>
            <option value="kg">kg</option>
            <option value="g">g</option>
            <option value="l">L</option>
            <option value="ml">ml</option>
            <option value="pcs">pcs</option>
          </select>
        </div>
      </div>

      <div class="field">
        <label>Weight / Volume *</label>
        <input type="number" step="0.01" min="0" name="weight" id="fweight" placeholder="e.g. 1.5" required>
      </div>

      <div class="field">
        <label>Description</label>
        <input type="text" name="description" id="fdesc" placeholder="e.g. Fresh farm tomatoes, 1kg pack" maxlength="255">
      </div>

      <div class="field">
        <label>Stock Status *</label>
        <select name="stockStatus" id="fstock" required>
          <option value="1" selected>In Stock</option>
          <option value="0">Out of Stock</option>
        </select>
      </div>

      <button type="submit" class="submit-btn"><i class="fa fa-plus"></i> Add Product</button>
    </form>
  </div>
</div>

<script>
function toggleDark(){
  const h=document.documentElement,d=h.getAttribute('data-theme')==='dark';
  h.setAttribute('data-theme',d?'light':'dark');
  localStorage.setItem('sibs-theme',d?'light':'dark');
}
(function(){const t=localStorage.getItem('sibs-theme');if(t)document.documentElement.setAttribute('data-theme',t);})();

// Mirror the visible file input into the form's named input
document.getElementById('imgInput').addEventListener('change', function(){
  const dt = new DataTransfer();
  if(this.files[0]) dt.items.add(this.files[0]);
  document.getElementById('hiddenImgInput').files = dt.files;
  previewImage({target: this});
});

function previewImage(event){
  const file = event.target.files[0];
  if(!file) return;
  const reader = new FileReader();
  reader.onload = function(){
    const img = document.getElementById('imgPreview');
    img.src = reader.result;
    img.style.display = 'block';
    document.getElementById('imgPlaceholder').style.display = 'none';
  };
  reader.readAsDataURL(file);
}

function validateForm(){
  let valid = true;
  ['fname','fprice','fqty','fcat','funit','fweight'].forEach(id=>{
    const el = document.getElementById(id);
    if(!el.value.trim()){el.classList.add('error');valid=false;}
    else el.classList.remove('error');
  });
  return valid;
}
</script>
</body>
</html>
