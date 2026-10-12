<%--
  staffNotificationBell.jsp — Drop-in bell for any staff/admin page topbar.
  Include this inside a topbar-right div. Font Awesome + getNotifications servlet required.
--%>
<style>
.snb-bell-wrap{position:relative;}
.snb-icon-btn{width:34px;height:34px;border-radius:9px;border:1px solid var(--border,#e2e8f0);
  background:var(--surface,#fff);display:flex;align-items:center;justify-content:center;
  cursor:pointer;color:var(--muted,#64748b);font-size:14px;transition:background .12s,color .12s;}
.snb-icon-btn:hover{background:#f1f5f9;color:#0f172a;}
.snb-bell-badge{position:absolute;top:-5px;right:-5px;min-width:17px;height:17px;padding:0 4px;
  background:#ef4444;color:#fff;font-size:9px;font-weight:700;border-radius:99px;
  display:none;align-items:center;justify-content:center;border:2px solid var(--surface,#fff);
  line-height:1;pointer-events:none;}
.snb-bell-badge.show{display:flex;}
@keyframes snb-ring{0%,100%{transform:rotate(0);}15%{transform:rotate(16deg);}
  30%{transform:rotate(-12deg);}45%{transform:rotate(8deg);}
  60%{transform:rotate(-5deg);}75%{transform:rotate(3deg);}}
.snb-bell-ico.ring{animation:snb-ring .65s ease-in-out;}

/* Dropdown */
.snb-dd{position:absolute;top:calc(100% + 10px);right:0;width:360px;
  background:var(--surface,#fff);border:1px solid var(--border,#e2e8f0);
  border-radius:16px;box-shadow:0 12px 40px rgba(0,0,0,.18);z-index:9999;
  overflow:hidden;opacity:0;pointer-events:none;
  transform:translateY(-8px) scale(.98);transform-origin:top right;
  transition:opacity .2s,transform .2s;}
.snb-dd.open{opacity:1;pointer-events:all;transform:translateY(0) scale(1);}
.snb-head{display:flex;align-items:center;justify-content:space-between;padding:14px 16px 10px;}
.snb-title{font-size:14px;font-weight:700;color:var(--text,#0f172a);}
.snb-actions{display:flex;gap:6px;}
.snb-btn{padding:4px 10px;border-radius:6px;border:none;font-size:12px;font-weight:600;cursor:pointer;}
.snb-btn.primary{background:#2563eb;color:#fff;}
.snb-btn.ghost{background:var(--border,#e2e8f0);color:var(--text,#0f172a);}
.snb-tabs{display:flex;border-bottom:1px solid var(--border,#e2e8f0);padding:0 8px;overflow-x:auto;scrollbar-width:none;}
.snb-tabs::-webkit-scrollbar{display:none;}
.snb-tab{padding:8px 10px;font-size:12px;font-weight:600;color:var(--muted,#64748b);
  cursor:pointer;white-space:nowrap;border-bottom:2px solid transparent;transition:.15s;}
.snb-tab.active{color:#2563eb;border-bottom-color:#2563eb;}
.snb-tab-ct{display:inline-flex;align-items:center;justify-content:center;
  background:#ef4444;color:#fff;font-size:9px;font-weight:700;min-width:15px;height:15px;
  border-radius:99px;padding:0 3px;margin-left:4px;display:none;}
.snb-tab-ct.show{display:inline-flex;}
.snb-list{max-height:360px;overflow-y:auto;}
.snb-item{display:flex;align-items:flex-start;gap:10px;padding:12px 16px;cursor:pointer;
  border-bottom:1px solid var(--border,#e2e8f0);transition:background .1s;}
.snb-item:hover{background:#f8fafc;}
.snb-item.unread{background:#eff6ff;}
.snb-ico{width:34px;height:34px;border-radius:50%;display:flex;align-items:center;
  justify-content:center;flex-shrink:0;font-size:13px;}
.snb-body{flex:1;min-width:0;}
.snb-ttl{font-size:13px;font-weight:600;color:var(--text,#0f172a);}
.snb-msg{font-size:12px;color:var(--muted,#64748b);margin-top:2px;
  overflow:hidden;display:-webkit-box;-webkit-line-clamp:2;-webkit-box-orient:vertical;}
.snb-time{font-size:11px;color:var(--muted,#64748b);margin-top:3px;}
.snb-dot{width:7px;height:7px;border-radius:50%;background:#2563eb;flex-shrink:0;margin-top:5px;}
.snb-empty{padding:32px;text-align:center;color:var(--muted,#64748b);font-size:13px;}
.snb-empty i{font-size:24px;display:block;margin-bottom:8px;opacity:.4;}
.snb-footer{padding:10px 16px;border-top:1px solid var(--border,#e2e8f0);text-align:center;}
.snb-footer-link{font-size:12px;color:#2563eb;cursor:pointer;font-weight:600;}
.snb-footer-link:hover{text-decoration:underline;}
</style>

<div class="snb-bell-wrap" id="snbWrap">
  <a href="<%=request.getContextPath()%>/staff-notifications.jsp" class="snb-icon-btn" title="Notifications" style="text-decoration:none;">
    <i class="fa fa-bell snb-bell-ico" id="snbIco"></i>
    <span class="snb-bell-badge" id="snbBadge"></span>
  </a>
</div>

<script>
(function(){
  var CTX='<%=request.getContextPath()%>';
  var _prevUnrd=-1;

  function snbFetch(){
    fetch(CTX+'/getNotifications').then(function(r){return r.json();}).then(function(data){
      var badge=document.getElementById('snbBadge');
      var bell=document.getElementById('snbIco');
      if(data.unread>0){
        badge.textContent=data.unread>99?'99+':data.unread;
        badge.classList.add('show');
      } else {
        badge.classList.remove('show');
      }
      if(_prevUnrd>=0&&data.unread>_prevUnrd){
        bell.classList.remove('ring'); void bell.offsetWidth; bell.classList.add('ring');
      }
      _prevUnrd=data.unread;
    }).catch(function(){});
  }

  snbFetch();
  setInterval(snbFetch, 60000);
})();
</script>
