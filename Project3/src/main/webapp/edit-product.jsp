<%@ page import="com.sibs.dao.ProductDAO, com.sibs.model.Product, com.sibs.model.User" %>
<%
User user = (User)session.getAttribute("user");
if(user == null || !"ADMIN".equals(user.getRole())){
    response.sendRedirect("login.jsp");
    return;
}
int id = Integer.parseInt(request.getParameter("id"));
ProductDAO dao = new ProductDAO();
Product p = dao.getProductById(id);
String unit = (p.getUnit()!=null && !p.getUnit().trim().isEmpty()) ? p.getUnit().toLowerCase().trim() : "kg";
String cat  = (p.getCategory()!=null) ? p.getCategory().toLowerCase().trim() : "";
String imgSrc = (p.getImagePath()!=null&&!p.getImagePath().isEmpty())
    ? request.getContextPath()+"/"+p.getImagePath() : "";
%>
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Edit Product — SIBS</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<style>
:root{--bg:#f8fafc;--surface:#fff;--border:#e2e8f0;--text:#0f172a;--muted:#64748b;--primary:#2563eb;--warn:#f59e0b;}
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
.img-panel{background:var(--surface);border:1px solid var(--border);border-radius:12px;padding:20px;text-align:center;height:fit-content;}
.img-preview-box{width:140px;height:140px;border-radius:10px;border:2px dashed var(--border);display:flex;align-items:center;justify-content:center;margin:0 auto 12px;background:var(--bg);overflow:hidden;cursor:pointer;transition:.15s;}
.img-preview-box:hover{border-color:var(--primary);}
.img-preview-box img{width:100%;height:100%;object-fit:contain;}
.file-input{display:none;}
.upload-label{font-size:12px;color:var(--primary);cursor:pointer;font-weight:500;}
.form-card{background:var(--surface);border:1px solid var(--border);border-radius:12px;padding:24px;}
.form-card h3{font-size:15px;font-weight:700;margin-bottom:20px;padding-bottom:12px;border-bottom:1px solid var(--border);}
.form-row{display:grid;grid-template-columns:1fr 1fr;gap:14px;margin-bottom:14px;}
@media(max-width:480px){.form-row{grid-template-columns:1fr;}}
.field{margin-bottom:14px;}
.field label{display:block;font-size:12px;font-weight:600;color:var(--muted);margin-bottom:6px;text-transform:uppercase;letter-spacing:.4px;}
.field input,.field select{width:100%;padding:9px 12px;border:1px solid var(--border);border-radius:7px;background:var(--bg);color:var(--text);font-size:13px;outline:none;transition:.15s;}
.field input:focus,.field select:focus{border-color:var(--primary);background:var(--surface);}
.submit-btn{width:100%;padding:11px;background:var(--warn);color:#fff;border:none;border-radius:8px;cursor:pointer;font-weight:600;font-size:14px;margin-top:6px;transition:.15s;display:flex;align-items:center;justify-content:center;gap:8px;}
.submit-btn:hover{background:#d97706;}
</style>
</head>
<body>

<div class="topbar">
  <a href="products.jsp"><i class="fa fa-arrow-left"></i> Products</a>
  <span style="color:var(--border);">|</span>
  <span class="page-title">Edit Product #<%=p.getId()%></span>
  <button class="dark-btn" onclick="toggleDark()"><i class="fa fa-moon"></i></button>
</div>

<div class="layout">
  <div class="img-panel">
    <div class="img-preview-box" onclick="document.getElementById('imgInput').click()">
      <img id="imgPreview" src="<%=imgSrc%>" onerror="this.style.display='none'">
    </div>
    <input type="file" id="imgInput" class="file-input" accept="image/*" onchange="previewImage(event)">
    <label for="imgInput" class="upload-label"><i class="fa fa-upload"></i> Change image</label>
    <p style="font-size:11px;color:var(--muted);margin-top:6px;">Leave blank to keep current</p>
  </div>

  <div class="form-card">
    <h3><i class="fa fa-pen" style="color:var(--warn);"></i> Edit Product</h3>
    <form action="<%=request.getContextPath()%>/updateProduct" method="post" enctype="multipart/form-data">
      <input type="hidden" name="id"       value="<%=p.getId()%>">
      <input type="hidden" name="oldImage" value="<%=p.getImagePath()%>">
      <input type="file"   name="image" id="hiddenImgInput" style="display:none;" accept="image/*">

      <div class="field">
        <label>Product Name *</label>
        <input type="text" name="name" value="<%=p.getName()%>" required>
      </div>
      <div class="form-row">
        <div class="field" style="margin:0;">
          <label>Price (₹) *</label>
          <input type="number" step="0.01" min="0" name="price" value="<%=p.getPrice()%>" required>
        </div>
        <div class="field" style="margin:0;">
          <label>Stock Quantity *</label>
          <input type="number" min="0" name="quantity" value="<%=p.getQuantity()%>" required>
        </div>
      </div>
      <div class="form-row">
        <div class="field" style="margin:0;">
          <label>Category *</label>
          <select name="category" required>
            <option value="" disabled>Select category</option>
            <option value="vegetables" <%="vegetables".equalsIgnoreCase(cat)?"selected":""%>>Vegetables</option>
            <option value="fruits"     <%="fruits".equalsIgnoreCase(cat)?"selected":""%>>Fruits</option>
            <option value="non-veg"    <%="non-veg".equalsIgnoreCase(cat)||"nonveg".equalsIgnoreCase(cat)?"selected":""%>>Non-Veg</option>
            <option value="dairy"      <%="dairy".equalsIgnoreCase(cat)?"selected":""%>>Dairy</option>
            <option value="beverages"  <%="beverages".equalsIgnoreCase(cat)?"selected":""%>>Beverages</option>
            <option value="electronics"<%="electronics".equalsIgnoreCase(cat)?"selected":""%>>Electronics</option>
            <option value="clothing"   <%="clothing".equalsIgnoreCase(cat)?"selected":""%>>Clothing</option>
            <option value="snacks"     <%="snacks".equalsIgnoreCase(cat)?"selected":""%>>Snacks</option>
          </select>
        </div>
        <div class="field" style="margin:0;">
          <label>Unit *</label>
          <select name="unit" required>
            <option value="" disabled>Select unit</option>
            <option value="kg"  <%="kg".equals(unit) ?"selected":""%>>kg</option>
            <option value="g"   <%="g".equals(unit)  ?"selected":""%>>g</option>
            <option value="l"   <%="l".equals(unit)  ?"selected":""%>>L</option>
            <option value="ml"  <%="ml".equals(unit) ?"selected":""%>>ml</option>
            <option value="pcs" <%="pcs".equals(unit)?"selected":""%>>pcs</option>
          </select>
        </div>
      </div>
      <div class="field">
        <label>Weight / Volume *</label>
        <input type="number" step="0.01" min="0" name="weight" value="<%=p.getWeight()%>" required>
      </div>
      <button type="submit" class="submit-btn"><i class="fa fa-floppy-disk"></i> Save Changes</button>
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

document.getElementById('imgInput').addEventListener('change',function(){
  const dt=new DataTransfer();
  if(this.files[0]) dt.items.add(this.files[0]);
  document.getElementById('hiddenImgInput').files=dt.files;
  previewImage({target:this});
});
function previewImage(event){
  const file=event.target.files[0];
  if(!file) return;
  const reader=new FileReader();
  reader.onload=function(){
    document.getElementById('imgPreview').src=reader.result;
    document.getElementById('imgPreview').style.display='block';
  };
  reader.readAsDataURL(file);
}
</script>
</body>
</html>
