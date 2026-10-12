
<%@ page import="com.sibs.model.User,com.sibs.dao.DashboardDAO,com.sibs.dao.StaffLeaveDAO,com.sibs.dao.SupportComplaintDAO,com.sibs.dao.ReturnDAO,com.sibs.dao.DeliveryBoyDAO,com.sibs.dao.NotificationDAO" %>
<%
User user = (User)session.getAttribute("user");
if(user == null || !"ADMIN".equals(user.getRole())){
    response.sendRedirect("login.jsp");
    return;
}
DashboardDAO dao       = new DashboardDAO();
StaffLeaveDAO leaveDao = new StaffLeaveDAO();
int pendingLeaves      = leaveDao.countAllPending();
int totalProducts      = dao.getTotalProducts();
int totalUsers         = dao.getTotalUsers();
int totalSales         = dao.getTotalSales();
int lowStock           = dao.getLowStockCount();
int openComplaints=0, pendingReturns=0, pendingApprovals=0;
try{ openComplaints   = new SupportComplaintDAO().countOpen();           }catch(Exception e){}
try{ pendingReturns   = new ReturnDAO().countPending();                   }catch(Exception e){}
try{ pendingApprovals = new DeliveryBoyDAO().countPendingApprovals();    }catch(Exception e){}
int pendingOrders=0, cancelledToday=0, onlineDeliveryBoys=0, activeDeliveries=0,
    todaySlots=0, pendingCod=0, unpaidBills=0, todaySales=0, absentStaff=0;
try{ pendingOrders      = dao.getPendingOrdersCount();      }catch(Exception e){}
try{ cancelledToday     = dao.getCancelledOrdersCount();    }catch(Exception e){}
try{ onlineDeliveryBoys = dao.getOnlineDeliveryBoysCount(); }catch(Exception e){}
try{ activeDeliveries   = dao.getActiveDeliveriesCount();   }catch(Exception e){}
try{ todaySlots         = dao.getTodaySlotsCount();         }catch(Exception e){}
try{ pendingCod         = dao.getPendingCodCount();         }catch(Exception e){}
try{ unpaidBills        = dao.getUnpaidBillsCount();        }catch(Exception e){}
try{ todaySales         = dao.getTodaySalesCount();         }catch(Exception e){}
try{ absentStaff        = dao.getAbsentStaffCount();        }catch(Exception e){}
String username = user.getUsername();
String initials = username.substring(0,1).toUpperCase();
java.util.Calendar cal = java.util.Calendar.getInstance();
int hour = cal.get(java.util.Calendar.HOUR_OF_DAY);
String greeting = hour<12?"Good morning":hour<17?"Good afternoon":"Good evening";
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>SIBS Admin</title>
<link href="https://fonts.googleapis.com/css2?family=DM+Sans:ital,opsz,wght@0,9..40,300;0,9..40,400;0,9..40,500;0,9..40,600;0,9..40,700;1,9..40,400&family=DM+Mono:wght@400;500&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">
<style>
*{margin:0;padding:0;box-sizing:border-box;}
:root{
  --font:'DM Sans',system-ui,sans-serif;
  --mono:'DM Mono',monospace;
  --bg:#f0f2f5;
  --surface:#ffffff;
  --surface2:#f7f8fa;
  --border:#e4e6ea;
  --border2:#cdd0d6;
  --text:#111318;
  --text2:#374151;
  --muted:#6b7280;
  --muted2:#9ca3af;

  /* Sidebar — dark navy */
  --sb:#0f1117;
  --sb2:#161b24;
  --sb3:#1e2432;
  --sb-border:#ffffff0c;
  --sb-text:#8892a4;
  --sb-hover:#e2e8f0;
  --sb-section:#3d4a5c;

  --accent:#2563eb;
  --accent-dim:#2563eb14;
  --accent-hover:#1d4ed8;

  --shadow-xs:0 1px 2px rgba(0,0,0,.05);
  --shadow-sm:0 1px 4px rgba(0,0,0,.07),0 1px 2px rgba(0,0,0,.04);
  --shadow:0 4px 16px rgba(0,0,0,.08),0 2px 4px rgba(0,0,0,.04);
  --shadow-lg:0 12px 36px rgba(0,0,0,.12),0 4px 10px rgba(0,0,0,.06);

  --radius:14px;
  --radius-sm:9px;
  --sb-w:248px;
  --sb-wc:58px;
  --tbh:56px;
  --ease:.22s cubic-bezier(.4,0,.2,1);
}
[data-theme="dark"]{
  --bg:#080a0f;
  --surface:#10131a;
  --surface2:#141820;
  --border:#1e2433;
  --border2:#2a3144;
  --text:#edf0f5;
  --text2:#c8cdd8;
  --muted:#5a6478;
  --muted2:#3d4860;
}
html,body{height:100%;overflow:hidden;font-family:var(--font);-webkit-font-smoothing:antialiased;}
body{background:var(--bg);color:var(--text);display:flex;}

/* ═══ SIDEBAR ═══ */
.sidebar{
  width:var(--sb-w);height:100vh;background:var(--sb);
  display:flex;flex-direction:column;flex-shrink:0;
  position:relative;z-index:200;
  transition:width var(--ease);overflow:hidden;
  border-right:1px solid var(--sb-border);
}
body.sc .sidebar{width:var(--sb-wc);}

.sb-logo{
  height:var(--tbh);padding:0 12px;
  display:flex;align-items:center;gap:10px;flex-shrink:0;
  border-bottom:1px solid var(--sb-border);white-space:nowrap;
}
.sb-logo-mark{
  width:30px;height:30px;border-radius:8px;flex-shrink:0;
  background:linear-gradient(135deg,#3b82f6,#1d4ed8);
  display:flex;align-items:center;justify-content:center;
  font-size:13px;color:#fff;box-shadow:0 4px 10px rgba(37,99,235,.35);
}
.sb-logo-text{
  font-size:13.5px;font-weight:700;color:#fff;letter-spacing:-.01em;
  transition:opacity var(--ease),max-width var(--ease);max-width:140px;overflow:hidden;
}
body.sc .sb-logo-text{opacity:0;max-width:0;}
.sb-tog{
  margin-left:auto;width:24px;height:24px;border-radius:6px;flex-shrink:0;
  display:flex;align-items:center;justify-content:center;cursor:pointer;
  color:var(--sb-text);font-size:10px;
  background:var(--sb3);border:1px solid var(--sb-border);
  transition:background .14s,color .14s,transform var(--ease);
}
.sb-tog:hover{background:#ffffff14;color:#fff;}
body.sc .sb-tog{transform:rotate(180deg);}

.sb-nav{flex:1;padding:8px 6px;overflow-y:auto;overflow-x:hidden;}
.sb-nav::-webkit-scrollbar{width:0;}

.sb-sect{
  font-size:9px;font-weight:700;letter-spacing:.8px;text-transform:uppercase;
  color:var(--sb-section);padding:13px 8px 4px;white-space:nowrap;
  transition:opacity var(--ease),max-height var(--ease),padding var(--ease);
  max-height:30px;overflow:hidden;
}
body.sc .sb-sect{opacity:0;max-height:0;padding:0;}

.ni{
  display:flex;align-items:center;gap:9px;
  padding:7px 9px;border-radius:8px;
  font-size:13px;font-weight:400;color:var(--sb-text);
  cursor:pointer;margin-bottom:1px;
  text-decoration:none;border:none;background:none;
  width:100%;text-align:left;white-space:nowrap;overflow:hidden;
  position:relative;
  transition:background .13s,color .13s,padding var(--ease);
}
.ni:hover{background:#ffffff0b;color:var(--sb-hover);}
.ni.active{background:#2563eb1a;color:#93c5fd;font-weight:500;border:1px solid #2563eb20;}
.ni.active .ni-ico{color:#60a5fa;}
.ni-ico{width:16px;text-align:center;font-size:13px;flex-shrink:0;color:var(--sb-section);transition:color .13s;}
.ni:hover .ni-ico{color:var(--sb-hover);}
body.sc .ni{padding:7px 20px;}
.ni-txt{transition:opacity .13s,max-width var(--ease);max-width:150px;overflow:hidden;}
body.sc .ni-txt{opacity:0;max-width:0;}
.ni-badge{
  margin-left:auto;padding:1px 6px;border-radius:99px;
  font-size:9.5px;font-weight:700;flex-shrink:0;
  background:#ef444420;color:#fca5a5;border:1px solid #ef444430;
  transition:opacity .13s,max-width var(--ease);max-width:40px;
}
.ni-badge.warn{background:#f59e0b1e;color:#fcd34d;border-color:#f59e0b28;}
body.sc .ni-badge{opacity:0;max-width:0;padding:0;border:none;overflow:hidden;}

/* collapsed tooltip */
body.sc .ni::after{
  content:attr(data-label);
  position:absolute;left:calc(var(--sb-wc) + 6px);top:50%;
  transform:translateY(-50%) translateX(-4px);
  background:#1a1f2e;color:#e2e8f0;font-size:12px;font-weight:500;
  padding:6px 12px;border-radius:8px;white-space:nowrap;
  pointer-events:none;z-index:9999;
  box-shadow:0 6px 20px rgba(0,0,0,.28),0 0 0 1px #ffffff0c;
  opacity:0;transition:opacity .13s,transform .13s;
}
body.sc .ni:hover::after{opacity:1;transform:translateY(-50%) translateX(0);}

.sb-foot{padding:6px 6px 10px;border-top:1px solid var(--sb-border);flex-shrink:0;}
.sb-user{
  display:flex;align-items:center;gap:8px;padding:7px 9px;border-radius:8px;
  cursor:pointer;transition:background .13s;white-space:nowrap;overflow:hidden;
  text-decoration:none;
}
.sb-user:hover{background:#ffffff0b;}
.sb-av{
  width:26px;height:26px;border-radius:7px;flex-shrink:0;
  background:linear-gradient(135deg,#2563eb,#1d4ed8);
  color:#fff;font-size:11px;font-weight:700;
  display:flex;align-items:center;justify-content:center;
}
.sb-uname{font-size:12px;font-weight:500;color:var(--sb-hover);}
.sb-urole{font-size:10px;color:var(--sb-section);}
.sb-uinfo{transition:opacity var(--ease),max-width var(--ease);max-width:130px;}
body.sc .sb-uinfo{opacity:0;max-width:0;}
.sb-logout{
  display:flex;align-items:center;gap:9px;padding:7px 9px;border-radius:8px;
  color:var(--sb-section);font-size:13px;text-decoration:none;
  transition:background .13s,color .13s;white-space:nowrap;overflow:hidden;margin-top:1px;
}
.sb-logout:hover{background:#ef444412;color:#fca5a5;}
.sb-logout i{width:16px;text-align:center;font-size:13px;flex-shrink:0;}
.sb-ltxt{transition:opacity var(--ease),max-width var(--ease);max-width:110px;}
body.sc .sb-ltxt{opacity:0;max-width:0;}

.sb-ov{
  display:none;position:fixed;inset:0;z-index:199;
  background:rgba(0,0,0,.5);backdrop-filter:blur(3px);
  opacity:0;pointer-events:none;transition:opacity .22s;
}
@media(max-width:780px){
  .sidebar{position:fixed;top:0;left:0;height:100vh;width:var(--sb-w)!important;
    transform:translateX(0);transition:transform .26s cubic-bezier(.4,0,.2,1);}
  body.sc .sidebar{transform:translateX(-100%);}
  .sb-ov{display:block;}
  body:not(.sc) .sb-ov{opacity:1;pointer-events:all;}
  .rp{width:100%;}
}

/* ═══ TOPBAR ═══ */
.rp{flex:1;display:flex;flex-direction:column;height:100vh;overflow:hidden;min-width:0;}
.topbar{
  height:var(--tbh);padding:0 20px;
  background:var(--surface);border-bottom:1px solid var(--border);
  display:flex;align-items:center;justify-content:space-between;
  flex-shrink:0;gap:14px;box-shadow:var(--shadow-xs);
}
.tb-l{display:flex;align-items:center;gap:9px;min-width:0;}
.tb-menu{
  width:32px;height:32px;border-radius:8px;border:1px solid var(--border);
  background:var(--surface2);display:flex;align-items:center;justify-content:center;
  cursor:pointer;color:var(--muted);font-size:12px;flex-shrink:0;
  transition:background .13s,color .13s;
}
.tb-menu:hover{background:var(--accent-dim);color:var(--accent);}
.bc{display:flex;align-items:center;gap:5px;font-size:12.5px;color:var(--muted);white-space:nowrap;}
.bc .sep{font-size:9px;color:var(--muted2);}
.bc .cur{color:var(--text);font-weight:600;}

.srch{
  display:flex;align-items:center;gap:8px;
  background:var(--surface2);border:1px solid var(--border);
  border-radius:9px;padding:7px 13px;width:260px;
  transition:border-color .13s,box-shadow .13s;
}
.srch:focus-within{border-color:#2563eb50;box-shadow:0 0 0 3px #2563eb0e;}
.srch i{color:var(--muted2);font-size:12px;flex-shrink:0;}
.srch input{border:none;background:transparent;font-size:12.5px;font-family:var(--font);color:var(--text);outline:none;flex:1;}
.srch input::placeholder{color:var(--muted2);}

.tb-r{display:flex;align-items:center;gap:7px;flex-shrink:0;}
.tb-ico{
  width:32px;height:32px;border-radius:8px;border:1px solid var(--border);
  background:var(--surface2);display:flex;align-items:center;justify-content:center;
  cursor:pointer;color:var(--muted);font-size:12.5px;position:relative;
  transition:background .13s,color .13s;
}
.tb-ico:hover{background:var(--accent-dim);color:var(--accent);}
.notif-wrap{position:relative;}
.notif-cnt{
  position:absolute;top:-4px;right:-4px;
  min-width:16px;height:16px;padding:0 3px;
  background:#ef4444;color:#fff;font-size:9px;font-weight:700;
  border-radius:99px;display:flex;align-items:center;justify-content:center;
  border:2px solid var(--surface);pointer-events:none;
}
.notif-dd{
  position:absolute;top:calc(100% + 8px);right:0;width:310px;
  background:var(--surface);border:1px solid var(--border);border-radius:var(--radius);
  box-shadow:var(--shadow-lg);z-index:9999;overflow:hidden;
  opacity:0;pointer-events:none;transform:translateY(-5px);
  transition:opacity .16s,transform .16s;
}
.notif-dd.open{opacity:1;pointer-events:all;transform:translateY(0);}
.nd-head{
  display:flex;align-items:center;justify-content:space-between;
  padding:12px 15px;border-bottom:1px solid var(--border);
}
.nd-title{font-size:12.5px;font-weight:700;color:var(--text);}
.nd-close{font-size:11px;color:var(--accent);cursor:pointer;font-weight:600;padding:2px 7px;border-radius:6px;transition:background .13s;}
.nd-close:hover{background:var(--accent-dim);}
.nd-list{max-height:320px;overflow-y:auto;scrollbar-width:thin;scrollbar-color:var(--border) transparent;}
.nd-item{
  display:flex;align-items:flex-start;gap:10px;
  padding:10px 15px;cursor:pointer;
  border-bottom:1px solid var(--border);transition:background .11s;
}
.nd-item:last-child{border-bottom:none;}
.nd-item:hover{background:var(--surface2);}
.nd-ico{width:30px;height:30px;border-radius:8px;flex-shrink:0;display:flex;align-items:center;justify-content:center;font-size:12px;}
.nd-body{flex:1;min-width:0;}
.nd-t{font-size:12px;font-weight:600;color:var(--text);margin-bottom:2px;}
.nd-s{font-size:11.5px;color:var(--muted);line-height:1.4;}
.nd-dot{width:6px;height:6px;border-radius:50%;background:#ef4444;flex-shrink:0;margin-top:4px;}
.nd-empty{padding:28px 16px;text-align:center;color:var(--muted);}
.nd-empty i{font-size:24px;color:var(--muted2);margin-bottom:6px;display:block;}
.nd-empty p{font-size:12.5px;}
.nd-foot{padding:9px 15px;border-top:1px solid var(--border);text-align:center;}
.nd-foot a{font-size:12px;font-weight:600;color:var(--accent);cursor:pointer;text-decoration:none;}
.tb-av{
  width:32px;height:32px;border-radius:9px;flex-shrink:0;
  background:linear-gradient(135deg,#2563eb,#1d4ed8);
  color:#fff;font-size:11.5px;font-weight:700;
  display:flex;align-items:center;justify-content:center;cursor:pointer;
  box-shadow:0 2px 7px rgba(37,99,235,.28);
  transition:box-shadow .13s,transform .13s;
}
.tb-av:hover{transform:scale(1.05);box-shadow:0 4px 12px rgba(37,99,235,.4);}

/* ═══ CONTENT ═══ */
.cw{flex:1;overflow:hidden;position:relative;display:flex;flex-direction:column;min-height:0;}
#cf{width:100%;height:100%;border:none;background:var(--bg);flex:1;display:block;}
.loader{
  position:absolute;inset:0;background:var(--bg);z-index:20;
  display:flex;flex-direction:column;align-items:center;justify-content:center;
  opacity:0;pointer-events:none;transition:opacity .18s;
}
.loader.on{opacity:1;pointer-events:all;}
.spin{width:34px;height:34px;border-radius:50%;border:3px solid var(--border2);border-top-color:var(--accent);animation:spin .6s linear infinite;}
@keyframes spin{to{transform:rotate(360deg);}}
.load-lbl{margin-top:12px;font-size:12.5px;color:var(--muted);}

/* ═══ DASHBOARD HOME ═══ */
.dh{
  width:100%;height:100%;overflow-y:auto;padding:22px 24px;
  background:var(--bg);scrollbar-width:thin;scrollbar-color:var(--border2) transparent;
}
.dh::-webkit-scrollbar{width:4px;}
.dh::-webkit-scrollbar-thumb{background:var(--border2);border-radius:99px;}

.dh-hdr{margin-bottom:20px;}
.dh-greet{font-size:21px;font-weight:700;color:var(--text);letter-spacing:-.025em;}
.dh-greet .wave{display:inline-block;animation:wave 2.4s ease-in-out infinite;}
@keyframes wave{0%,100%{transform:rotate(0);}25%{transform:rotate(18deg);}50%{transform:rotate(-6deg);}75%{transform:rotate(14deg);}}
.dh-date{font-size:12.5px;color:var(--muted);margin-top:3px;display:flex;align-items:center;gap:8px;}
.live-dot{display:inline-flex;align-items:center;gap:4px;font-size:11.5px;color:#22c55e;font-weight:500;}
.live-dot span{width:6px;height:6px;border-radius:50%;background:#22c55e;animation:pulse 2s infinite;}
@keyframes pulse{0%,100%{opacity:1;}50%{opacity:.3;}}

/* alerts */
.al{
  display:flex;align-items:center;gap:10px;
  padding:10px 14px;border-radius:9px;margin-bottom:8px;
  font-size:12.5px;border:1px solid;
}
.al.warn{background:#fefce8;border-color:#fde68a;color:#92400e;}
.al.info{background:#eff6ff;border-color:#bfdbfe;color:#1e40af;}
.al.danger{background:#fef2f2;border-color:#fecaca;color:#991b1b;}
[data-theme="dark"] .al.warn{background:#1a1400;border-color:#854d0e40;color:#fcd34d;}
[data-theme="dark"] .al.info{background:#001233;border-color:#1e40af40;color:#93c5fd;}
[data-theme="dark"] .al.danger{background:#1f0000;border-color:#991b1b40;color:#fca5a5;}
.al-ico{width:28px;height:28px;border-radius:7px;display:flex;align-items:center;justify-content:center;font-size:12.5px;flex-shrink:0;}
.al.warn .al-ico{background:#fde68a;color:#92400e;}
.al.info .al-ico{background:#bfdbfe;color:#1e40af;}
.al.danger .al-ico{background:#fecaca;color:#991b1b;}
[data-theme="dark"] .al.warn .al-ico{background:#854d0e30;color:#fcd34d;}
[data-theme="dark"] .al.info .al-ico{background:#1e40af30;color:#93c5fd;}
[data-theme="dark"] .al.danger .al-ico{background:#991b1b30;color:#fca5a5;}
.al b{font-weight:600;}
.al-link{margin-left:auto;font-size:11.5px;font-weight:600;cursor:pointer;padding:4px 9px;border-radius:6px;background:rgba(0,0,0,.06);transition:background .13s;white-space:nowrap;text-decoration:none;color:inherit;flex-shrink:0;}
.al-link:hover{background:rgba(0,0,0,.12);}

/* KPI grid — 5 cols on large, 3 on medium, 2 on small */
.kpi-grid{
  display:grid;
  grid-template-columns:repeat(5,1fr);
  gap:12px;margin-bottom:18px;
}
@media(max-width:1280px){.kpi-grid{grid-template-columns:repeat(3,1fr);}}
@media(max-width:860px){.kpi-grid{grid-template-columns:repeat(2,1fr);}}
@media(max-width:520px){.kpi-grid{grid-template-columns:1fr;}}

.kc{
  background:var(--surface);border:1px solid var(--border);
  border-radius:var(--radius);padding:16px 18px;
  cursor:pointer;position:relative;overflow:hidden;
  transition:transform .16s,box-shadow .16s,border-color .16s;
}
.kc::before{
  content:'';position:absolute;top:0;left:0;right:0;height:3px;
  background:var(--kc-accent);border-radius:var(--radius) var(--radius) 0 0;
}
.kc:hover{transform:translateY(-2px);box-shadow:var(--shadow-lg);border-color:var(--border2);}
.kc-ico{
  width:38px;height:38px;border-radius:10px;margin-bottom:12px;
  display:flex;align-items:center;justify-content:center;font-size:15px;
  background:var(--kc-bg);color:var(--kc-clr);
}
.kc-num{font-size:27px;font-weight:700;line-height:1;letter-spacing:-.04em;color:var(--kc-clr);margin-bottom:4px;}
.kc-lbl{font-size:11.5px;color:var(--muted);font-weight:400;margin-bottom:3px;}
.kc-sub{font-size:11px;font-weight:500;color:var(--kc-clr);opacity:.7;display:flex;align-items:center;gap:3px;}

/* KPI colour tokens */
.k-blue{--kc-accent:linear-gradient(90deg,#2563eb,#60a5fa);--kc-bg:#dbeafe;--kc-clr:#1d4ed8;}
.k-green{--kc-accent:linear-gradient(90deg,#16a34a,#4ade80);--kc-bg:#d1fae5;--kc-clr:#15803d;}
.k-amber{--kc-accent:linear-gradient(90deg,#d97706,#fbbf24);--kc-bg:#fef3c7;--kc-clr:#b45309;}
.k-red{--kc-accent:linear-gradient(90deg,#dc2626,#f87171);--kc-bg:#fee2e2;--kc-clr:#b91c1c;}
.k-orange{--kc-accent:linear-gradient(90deg,#ea580c,#fb923c);--kc-bg:#ffedd5;--kc-clr:#c2410c;}
[data-theme="dark"] .k-blue{--kc-bg:#1e3a5f;--kc-clr:#60a5fa;}
[data-theme="dark"] .k-green{--kc-bg:#064e3b;--kc-clr:#4ade80;}
[data-theme="dark"] .k-amber{--kc-bg:#78350f;--kc-clr:#fbbf24;}
[data-theme="dark"] .k-red{--kc-bg:#7f1d1d;--kc-clr:#f87171;}
[data-theme="dark"] .k-orange{--kc-bg:#431407;--kc-clr:#fb923c;}

/* Stat row — second row of wide tiles */
.stat-row{
  display:grid;
  grid-template-columns:repeat(4,1fr);
  gap:12px;margin-bottom:18px;
}
@media(max-width:1100px){.stat-row{grid-template-columns:repeat(2,1fr);}}
@media(max-width:520px){.stat-row{grid-template-columns:1fr;}}

.st{
  background:var(--surface);border:1px solid var(--border);
  border-radius:var(--radius-sm);padding:13px 16px;
  display:flex;align-items:center;gap:12px;cursor:pointer;
  transition:background .13s,box-shadow .13s;
}
.st:hover{background:var(--surface2);box-shadow:var(--shadow-sm);}
.st-ico{
  width:34px;height:34px;border-radius:9px;flex-shrink:0;
  display:flex;align-items:center;justify-content:center;font-size:13px;
}
.st-body{flex:1;min-width:0;}
.st-num{font-size:17px;font-weight:700;color:var(--text);line-height:1;}
.st-lbl{font-size:11px;color:var(--muted);margin-top:1px;}
.st-pill{
  font-size:10.5px;font-weight:600;padding:3px 8px;border-radius:99px;
  white-space:nowrap;
}
.st-pill.ok{background:#d1fae5;color:#065f46;border:1px solid #a7f3d0;}
.st-pill.warn{background:#fef3c7;color:#92400e;border:1px solid #fde68a;}
.st-pill.bad{background:#fee2e2;color:#991b1b;border:1px solid #fecaca;}
[data-theme="dark"] .st-pill.ok{background:#064e3b;color:#4ade80;border-color:#065f46;}
[data-theme="dark"] .st-pill.warn{background:#78350f;color:#fbbf24;border-color:#92400e;}
[data-theme="dark"] .st-pill.bad{background:#7f1d1d;color:#f87171;border-color:#991b1b;}

/* Bottom grid */
.bg{display:grid;grid-template-columns:1fr 1fr;gap:14px;}
@media(max-width:860px){.bg{grid-template-columns:1fr;}}

.card{background:var(--surface);border:1px solid var(--border);border-radius:var(--radius);overflow:hidden;}
.card-hd{padding:14px 18px;border-bottom:1px solid var(--border);display:flex;align-items:center;justify-content:space-between;}
.card-title{font-size:13px;font-weight:700;color:var(--text);}
.card-bd{padding:14px 18px;}
.card-lnk{font-size:11.5px;font-weight:600;color:var(--accent);cursor:pointer;padding:4px 9px;border-radius:6px;transition:background .13s;text-decoration:none;display:flex;align-items:center;gap:4px;}
.card-lnk:hover{background:var(--accent-dim);}

/* Quick actions */
.qa-list{display:flex;flex-direction:column;gap:5px;}
.qa{
  display:flex;align-items:center;gap:10px;padding:10px 12px;
  border-radius:9px;cursor:pointer;background:var(--surface2);border:1px solid var(--border);
  transition:background .13s,border-color .13s,transform .13s;
  text-decoration:none;
}
.qa:hover{background:var(--accent-dim);border-color:#2563eb28;transform:translateX(2px);}
.qa-ico{width:30px;height:30px;border-radius:8px;flex-shrink:0;display:flex;align-items:center;justify-content:center;font-size:12.5px;}
.qa-lbl{font-size:12.5px;font-weight:500;color:var(--text2);flex:1;}
.qa-bdg{padding:1px 7px;border-radius:99px;font-size:9.5px;font-weight:700;background:#ef444418;color:#ef4444;border:1px solid #ef444428;flex-shrink:0;}
.qa-bdg.warn{background:#f59e0b16;color:#d97706;border-color:#f59e0b26;}
.qa-arr{font-size:9px;color:var(--muted2);transition:transform .13s,color .13s;}
.qa:hover .qa-arr{transform:translateX(2px);color:var(--accent);}

/* Animations */
@keyframes fadeUp{from{opacity:0;transform:translateY(8px);}to{opacity:1;transform:translateY(0);}}
.dh-hdr{animation:fadeUp .28s ease .03s both;}
.kpi-grid{animation:fadeUp .28s ease .07s both;}
.stat-row{animation:fadeUp .28s ease .1s both;}
.bg{animation:fadeUp .28s ease .13s both;}
</style>
</head>
<body>

<div class="sb-ov" id="sbOv" onclick="toggleSB()"></div>

<!-- ═══ SIDEBAR ═══ -->
<div class="sidebar">
  <div class="sb-logo">
    <div class="sb-logo-mark"><i class="fa fa-shield-halved"></i></div>
    <span class="sb-logo-text">SIBS Admin</span>
    <div class="sb-tog" onclick="toggleSB()"><i class="fa fa-chevron-left"></i></div>
  </div>

  <div class="sb-nav">
    <div class="sb-sect">Overview</div>
    <div class="ni active" onclick="nav('home','Dashboard')" data-page="home" data-label="Dashboard">
      <i class="ni-ico fa fa-gauge-high"></i><span class="ni-txt">Dashboard</span>
    </div>
    <div class="ni" onclick="nav('users.jsp','Manage Users')" data-page="users.jsp" data-label="Users">
      <i class="ni-ico fa fa-users"></i><span class="ni-txt">Manage Users</span>
    </div>
    <div class="ni" onclick="nav('add-staff.jsp','Add Staff')" data-page="add-staff.jsp" data-label="Add Staff">
      <i class="ni-ico fa fa-user-plus"></i><span class="ni-txt">Add Staff</span>
    </div>

    <div class="sb-sect">Catalogue</div>
    <div class="ni" onclick="nav('products.jsp','Products')" data-page="products.jsp" data-label="Products">
      <i class="ni-ico fa fa-box"></i><span class="ni-txt">Products</span>
    </div>
    <div class="ni" onclick="nav('add-product.jsp','Add Product')" data-page="add-product.jsp" data-label="Add Product">
      <i class="ni-ico fa fa-plus-circle"></i><span class="ni-txt">Add Product</span>
    </div>

    <div class="sb-sect">Orders</div>
    <div class="ni" onclick="nav('admin-orders.jsp','Orders')" data-page="admin-orders.jsp" data-label="Orders">
      <i class="ni-ico fa fa-shopping-bag"></i><span class="ni-txt">Orders</span>
    </div>
    <div class="ni" onclick="nav('AdminReturnServlet?action=list','Returns')" data-page="AdminReturnServlet" data-label="Returns">
      <i class="ni-ico fa fa-rotate-left"></i><span class="ni-txt">Manage Returns</span>
      <span class="ni-badge" id="badge-returns" style="<%=pendingReturns>0?"":"display:none"%>"><%=pendingReturns%></span>
    </div>
    <div class="ni" onclick="nav('staff-cancelled-orders.jsp','Cancelled Orders')" data-page="staff-cancelled-orders.jsp" data-label="Cancelled">
      <i class="ni-ico fa fa-ban"></i><span class="ni-txt">Cancelled</span>
    </div>

    <div class="sb-sect">Delivery</div>
    <div class="ni" onclick="nav('manage-delivery-boys.jsp','Delivery Boys')" data-page="manage-delivery-boys.jsp" data-label="Delivery Boys">
      <i class="ni-ico fa fa-motorcycle"></i><span class="ni-txt">Delivery Boys</span>
    </div>
    <div class="ni" onclick="nav('admin-delivery-approvals.jsp','Approvals')" data-page="admin-delivery-approvals.jsp" data-label="Approvals">
      <i class="ni-ico fa fa-user-check"></i><span class="ni-txt">Approvals</span>
      <span class="ni-badge warn" id="badge-approvals" style="<%=pendingApprovals>0?"":"display:none"%>"><%=pendingApprovals%></span>
    </div>
    <div class="ni" onclick="nav('delivery-monitor.jsp','Live Monitor')" data-page="delivery-monitor.jsp" data-label="Monitor">
      <i class="ni-ico fa fa-satellite-dish"></i><span class="ni-txt">Live Monitor</span>
    </div>
    <div class="ni" onclick="nav('admin-delivery-slots.jsp','Delivery Slots')" data-page="admin-delivery-slots.jsp" data-label="Slots">
      <i class="ni-ico fa fa-calendar-check"></i><span class="ni-txt">Delivery Slots</span>
      <span class="ni-badge warn" id="badge-slots" style="<%=todaySlots>0?"":"display:none"%>"><%=todaySlots%></span>
    </div>

    <div class="sb-sect">Finance</div>
    <div class="ni" onclick="nav('admin-cod-ledger.jsp','COD Remittance')" data-page="admin-cod-ledger.jsp" data-label="COD">
      <i class="ni-ico fa fa-money-bill-wave"></i><span class="ni-txt">COD Remittance</span>
      <span class="ni-badge" id="badge-cod" style="<%=pendingCod>0?"":"display:none"%>"><%=pendingCod%></span>
    </div>
    <div class="ni" onclick="nav('billing.jsp','Billing')" data-page="billing.jsp" data-label="Billing">
      <i class="ni-ico fa fa-file-invoice"></i><span class="ni-txt">Billing</span>
    </div>
    <div class="ni" onclick="nav('sales.jsp','Sales')" data-page="sales.jsp" data-label="Sales">
      <i class="ni-ico fa fa-chart-line"></i><span class="ni-txt">Sales</span>
    </div>

    <div class="sb-sect">Staff</div>
    <div class="ni" onclick="nav('admin-attendance.jsp','Attendance')" data-page="admin-attendance.jsp" data-label="Attendance">
      <i class="ni-ico fa fa-user-clock"></i><span class="ni-txt">Attendance</span>
    </div>
    <div class="ni" onclick="nav('admin-leave.jsp','Leave Requests')" data-page="admin-leave.jsp" data-label="Leave">
      <i class="ni-ico fa fa-calendar-xmark"></i><span class="ni-txt">Leave Requests</span>
      <span class="ni-badge warn" id="badge-leaves" style="<%=pendingLeaves>0?"":"display:none"%>"><%=pendingLeaves%></span>
    </div>
    <div class="ni" onclick="nav('admin-notifications.jsp','Broadcast')" data-page="admin-notifications.jsp" data-label="Broadcast">
      <i class="ni-ico fa fa-bullhorn"></i><span class="ni-txt">Broadcast</span>
    </div>
    <div class="ni" onclick="nav('support','Support')" data-page="support" data-label="Support">
      <i class="ni-ico fa fa-headset"></i><span class="ni-txt">Support</span>
      <span class="ni-badge" id="badge-support" style="<%=openComplaints>0?"":"display:none"%>"><%=openComplaints%></span>
    </div>
    <div class="ni" onclick="nav('admin-settings.jsp','Settings')" data-page="admin-settings.jsp" data-label="Settings">
      <i class="ni-ico fa fa-gear"></i><span class="ni-txt">Settings</span>
    </div>
  </div>

  <div class="sb-foot">
    <a class="sb-user" href="admin-profile.jsp" style="text-decoration:none;">
      <div class="sb-av"><%=initials%></div>
      <div class="sb-uinfo">
        <div class="sb-uname"><%=username%></div>
        <div class="sb-urole">Administrator</div>
      </div>
    </a>
    <a class="sb-logout" href="logout">
      <i class="fa fa-sign-out-alt"></i>
      <span class="sb-ltxt">Logout</span>
    </a>
  </div>
</div>

<!-- ═══ RIGHT PANEL ═══ -->
<div class="rp">
  <div class="topbar">
    <div class="tb-l">
      <div class="tb-menu" onclick="toggleSB()"><i class="fa fa-bars"></i></div>
      <div class="bc">
        <span>SIBS</span>
        <i class="fa fa-chevron-right sep"></i>
        <span class="cur" id="pg-label">Dashboard</span>
      </div>
    </div>
    <div class="srch">
      <i class="fa fa-magnifying-glass"></i>
      <input type="text" placeholder="Search…">
    </div>
    <div class="tb-r">
      <div class="tb-ico" onclick="toggleTheme()" title="Toggle theme"><i class="fa fa-moon" id="themeIco"></i></div>

      <!-- Notification bell -->
      <div class="notif-wrap" id="notifWrap">
        <div class="tb-ico" onclick="toggleNotif(event)">
          <i class="fa fa-bell"></i>
          <span class="notif-cnt" id="notifBadge" style="display:none"></span>
        </div>
        <div class="notif-dd" id="notifDd">
          <div class="nd-head">
            <span class="nd-title" id="ndTitle">Notifications</span>
            <span class="nd-close" onclick="closeNotif()">Close ✕</span>
          </div>
          <div class="nd-list" id="ndList">
            <div class="nd-empty"><i class="fa fa-spinner fa-spin"></i><p>Loading…</p></div>
          </div>
          <div class="nd-foot" id="ndFoot" style="display:none">
            <a onclick="markAllRead()">Mark all as read</a>
          </div>
        </div>
      </div>

      <a href="admin-profile.jsp" style="text-decoration:none;">
        <div class="tb-av" title="<%=username%>"><%=initials%></div>
      </a>
    </div>
  </div>

  <div class="cw">
    <div class="loader" id="loader">
      <div class="spin"></div>
      <div class="load-lbl" id="load-txt">Loading…</div>
    </div>

    <!-- Dashboard home -->
    <div class="dh" id="dash-home">

      <div class="dh-hdr">
        <div class="dh-greet"><%=greeting%>, <%=username%> <span class="wave">👋</span></div>
        <div class="dh-date">
          <%
            java.text.SimpleDateFormat sdf = new java.text.SimpleDateFormat("EEEE, d MMMM yyyy");
            out.print(sdf.format(new java.util.Date()));
          %>
          <span class="live-dot"><span></span>Live</span>
        </div>
      </div>

      <!-- Alert banners -->
      <% if(lowStock>0){ %>
      <div class="al warn">
        <div class="al-ico"><i class="fa fa-triangle-exclamation"></i></div>
        <div><b>Low stock alert</b> — <%=lowStock%> product(s) need restocking.</div>
        <a class="al-link" onclick="nav('products.jsp','Products')">View →</a>
      </div>
      <% } %>
      <% if(pendingLeaves>0){ %>
      <div class="al info">
        <div class="al-ico"><i class="fa fa-calendar-xmark"></i></div>
        <div><b><%=pendingLeaves%> leave request<%=pendingLeaves>1?"s":""%></b> pending approval.</div>
        <a class="al-link" onclick="nav('admin-leave.jsp','Leave Requests')">Review →</a>
      </div>
      <% } %>
      <% if(pendingApprovals>0){ %>
      <div class="al danger">
        <div class="al-ico"><i class="fa fa-user-check"></i></div>
        <div><b><%=pendingApprovals%> delivery approval<%=pendingApprovals>1?"s":""%></b> waiting for review.</div>
        <a class="al-link" onclick="nav('admin-delivery-approvals.jsp','Approvals')">Review →</a>
      </div>
      <% } %>

      <!-- KPI row 1 — key business metrics -->
      <div class="kpi-grid">
        <div class="kc k-blue" onclick="nav('products.jsp','Products')">
          <div class="kc-ico"><i class="fa fa-box"></i></div>
          <div class="kc-num" id="kpi-products"><%=totalProducts%></div>
          <div class="kc-lbl">Total Products</div>
          <div class="kc-sub"><i class="fa fa-arrow-right" style="font-size:9px;"></i> Manage</div>
        </div>
        <div class="kc k-green" onclick="nav('users.jsp','Manage Users')">
          <div class="kc-ico"><i class="fa fa-users"></i></div>
          <div class="kc-num" id="kpi-users"><%=totalUsers%></div>
          <div class="kc-lbl">Registered Users</div>
          <div class="kc-sub"><i class="fa fa-arrow-right" style="font-size:9px;"></i> View all</div>
        </div>
        <div class="kc k-amber" onclick="nav('admin-orders.jsp','Orders')">
          <div class="kc-ico"><i class="fa fa-chart-line"></i></div>
          <div class="kc-num" id="kpi-sales"><%=totalSales%></div>
          <div class="kc-lbl">Total Sales</div>
          <div class="kc-sub"><i class="fa fa-arrow-up" style="font-size:9px;"></i> Orders</div>
        </div>
        <div class="kc k-red" onclick="nav('products.jsp','Products')">
          <div class="kc-ico"><i class="fa fa-triangle-exclamation"></i></div>
          <div class="kc-num" id="kpi-lowstock"><%=lowStock%></div>
          <div class="kc-lbl">Low Stock Items</div>
          <div class="kc-sub"><%=lowStock>0?"Needs attention":"All stocked ✓"%></div>
        </div>
        <div class="kc k-orange" onclick="nav('admin-leave.jsp','Leave Requests')">
          <div class="kc-ico"><i class="fa fa-calendar-xmark"></i></div>
          <div class="kc-num"><%=pendingLeaves%></div>
          <div class="kc-lbl">Pending Leaves</div>
          <div class="kc-sub"><%=pendingLeaves>0?"Needs review":"All clear ✓"%></div>
        </div>
      </div>

      <!-- Stat row 2 — operational metrics -->
      <div class="stat-row">
        <div class="st" onclick="nav('admin-orders.jsp','Orders')">
          <div class="st-ico" style="background:#ede9fe;color:#6366f1;"><i class="fa fa-clock"></i></div>
          <div class="st-body">
            <div class="st-num"><%=pendingOrders%></div>
            <div class="st-lbl">Pending Orders</div>
          </div>
          <span class="st-pill <%=pendingOrders>0?"warn":"ok"%>"><%=pendingOrders>0?"Pending":"Clear"%></span>
        </div>
        <div class="st" onclick="nav('delivery-monitor.jsp','Live Monitor')">
          <div class="st-ico" style="background:#dcfce7;color:#16a34a;"><i class="fa fa-truck-fast"></i></div>
          <div class="st-body">
            <div class="st-num"><%=activeDeliveries%></div>
            <div class="st-lbl">Active Deliveries</div>
          </div>
          <span class="st-pill <%=activeDeliveries>0?"ok":""%>" style="<%=activeDeliveries==0?"background:var(--surface2);color:var(--muted);border-color:var(--border);":""%>"><%=activeDeliveries>0?"Live":"Idle"%></span>
        </div>
        <div class="st" onclick="nav('admin-cod-ledger.jsp','COD Remittance')">
          <div class="st-ico" style="background:#fef3c7;color:#d97706;"><i class="fa fa-money-bill-wave"></i></div>
          <div class="st-body">
            <div class="st-num"><%=pendingCod%></div>
            <div class="st-lbl">Pending COD</div>
          </div>
          <span class="st-pill <%=pendingCod>0?"warn":"ok"%>"><%=pendingCod>0?"Pending":"Clear"%></span>
        </div>
        <div class="st" onclick="nav('support','Support')">
          <div class="st-ico" style="background:#fee2e2;color:#dc2626;"><i class="fa fa-headset"></i></div>
          <div class="st-body">
            <div class="st-num"><%=openComplaints%></div>
            <div class="st-lbl">Open Complaints</div>
          </div>
          <span class="st-pill <%=openComplaints>0?"bad":"ok"%>"><%=openComplaints>0?"Open":"Clear"%></span>
        </div>
      </div>

      <!-- Bottom cards -->
      <div class="bg">
        <!-- Quick Actions -->
        <div class="card">
          <div class="card-hd">
            <div class="card-title">Quick Actions</div>
          </div>
          <div class="card-bd">
            <div class="qa-list">
              <div class="qa" onclick="nav('add-product.jsp','Add Product')">
                <div class="qa-ico" style="background:#dbeafe;color:#2563eb;"><i class="fa fa-plus-circle"></i></div>
                <span class="qa-lbl">Add New Product</span>
                <i class="fa fa-chevron-right qa-arr"></i>
              </div>
              <div class="qa" onclick="nav('add-staff.jsp','Add Staff')">
                <div class="qa-ico" style="background:#d1fae5;color:#059669;"><i class="fa fa-user-plus"></i></div>
                <span class="qa-lbl">Add Staff Member</span>
                <i class="fa fa-chevron-right qa-arr"></i>
              </div>
              <div class="qa" onclick="nav('admin-orders.jsp','Orders')">
                <div class="qa-ico" style="background:#ede9fe;color:#7c3aed;"><i class="fa fa-shopping-bag"></i></div>
                <span class="qa-lbl">Manage Orders</span>
                <i class="fa fa-chevron-right qa-arr"></i>
              </div>
              <div class="qa" onclick="nav('admin-delivery-approvals.jsp','Approvals')">
                <div class="qa-ico" style="background:#ffedd5;color:#ea580c;"><i class="fa fa-user-check"></i></div>
                <span class="qa-lbl">Delivery Approvals</span>
                <% if(pendingApprovals>0){ %><span class="qa-bdg"><%=pendingApprovals%></span><% } %>
                <i class="fa fa-chevron-right qa-arr"></i>
              </div>
              <div class="qa" onclick="nav('admin-leave.jsp','Leave Requests')">
                <div class="qa-ico" style="background:#fef3c7;color:#d97706;"><i class="fa fa-calendar-xmark"></i></div>
                <span class="qa-lbl">Leave Requests</span>
                <% if(pendingLeaves>0){ %><span class="qa-bdg warn"><%=pendingLeaves%></span><% } %>
                <i class="fa fa-chevron-right qa-arr"></i>
              </div>
              <div class="qa" onclick="nav('AdminReturnServlet?action=list','Returns')">
                <div class="qa-ico" style="background:#e0f2fe;color:#0284c7;"><i class="fa fa-rotate-left"></i></div>
                <span class="qa-lbl">Manage Returns</span>
                <% if(pendingReturns>0){ %><span class="qa-bdg"><%=pendingReturns%></span><% } %>
                <i class="fa fa-chevron-right qa-arr"></i>
              </div>
              <div class="qa" onclick="nav('billing.jsp','Billing')">
                <div class="qa-ico" style="background:#fce7f3;color:#db2777;"><i class="fa fa-file-invoice-dollar"></i></div>
                <span class="qa-lbl">Billing &amp; Invoices</span>
                <i class="fa fa-chevron-right qa-arr"></i>
              </div>
              <div class="qa" onclick="nav('support','Support')">
                <div class="qa-ico" style="background:#d1fae5;color:#059669;"><i class="fa fa-headset"></i></div>
                <span class="qa-lbl">Support Complaints</span>
                <% if(openComplaints>0){ %><span class="qa-bdg"><%=openComplaints%></span><% } %>
                <i class="fa fa-chevron-right qa-arr"></i>
              </div>
            </div>
          </div>
        </div>

        <!-- System Status -->
        <div class="card">
          <div class="card-hd">
            <div class="card-title">System Status</div>
            <a class="card-lnk" onclick="nav('delivery-monitor.jsp','Live Monitor')">Live map <i class="fa fa-arrow-right"></i></a>
          </div>
          <div class="card-bd">
            <div style="display:flex;flex-direction:column;gap:8px;">
              <div class="st" onclick="nav('products.jsp','Products')" style="margin:0;">
                <div class="st-ico" style="background:#dbeafe;color:#2563eb;"><i class="fa fa-box"></i></div>
                <div class="st-body">
                  <div class="st-num"><%=totalProducts%></div>
                  <div class="st-lbl">Products in catalogue</div>
                </div>
                <span class="st-pill ok">Active</span>
              </div>
              <div class="st" style="margin:0;">
                <div class="st-ico" style="background:#d1fae5;color:#059669;"><i class="fa fa-users"></i></div>
                <div class="st-body">
                  <div class="st-num"><%=totalUsers%></div>
                  <div class="st-lbl">Registered users</div>
                </div>
                <span class="st-pill ok">Active</span>
              </div>
              <div class="st" onclick="nav('AdminReturnServlet?action=list','Returns')" style="margin:0;">
                <div class="st-ico" style="background:#e0f2fe;color:#0284c7;"><i class="fa fa-rotate-left"></i></div>
                <div class="st-body">
                  <div class="st-num"><%=pendingReturns%></div>
                  <div class="st-lbl">Pending returns</div>
                </div>
                <span class="st-pill <%=pendingReturns>0?"warn":"ok"%>"><%=pendingReturns>0?"Review":"Clear"%></span>
              </div>
              <div class="st" onclick="nav('support','Support')" style="margin:0;">
                <div class="st-ico" style="background:#d1fae5;color:#059669;"><i class="fa fa-headset"></i></div>
                <div class="st-body">
                  <div class="st-num"><%=openComplaints%></div>
                  <div class="st-lbl">Open complaint<%=openComplaints!=1?"s":""%></div>
                </div>
                <span class="st-pill <%=openComplaints>0?"bad":"ok"%>"><%=openComplaints>0?"Open":"Clear"%></span>
              </div>
              <div class="st" onclick="nav('products.jsp','Products')" style="margin:0;">
                <div class="st-ico" style="background:<%=lowStock>0?"#fee2e2;color:#dc2626":"#d1fae5;color:#059669"%>;"><i class="fa fa-triangle-exclamation"></i></div>
                <div class="st-body">
                  <div class="st-num"><%=lowStock%></div>
                  <div class="st-lbl">Low stock item<%=lowStock!=1?"s":""%></div>
                </div>
                <span class="st-pill <%=lowStock>0?"warn":"ok"%>"><%=lowStock>0?"Restock":"Healthy"%></span>
              </div>
            </div>
          </div>
        </div>
      </div>

    </div><!-- /dash-home -->

    <iframe id="cf" src="about:blank" style="display:none;height:100%;"></iframe>
  </div>
</div>

<script>
(function(){
  var t=localStorage.getItem('sibs-admin-theme')||'light';
  document.documentElement.setAttribute('data-theme',t);
  document.getElementById('themeIco').className=t==='dark'?'fa fa-sun':'fa fa-moon';
  if(localStorage.getItem('sibs-admin-sb')==='1') document.body.classList.add('sc');
})();

function toggleTheme(){
  var d=document.documentElement.getAttribute('data-theme')==='dark';
  var n=d?'light':'dark';
  document.documentElement.setAttribute('data-theme',n);
  localStorage.setItem('sibs-admin-theme',n);
  document.getElementById('themeIco').className=n==='dark'?'fa fa-sun':'fa fa-moon';
}
function toggleSB(){
  var c=document.body.classList.toggle('sc');
  localStorage.setItem('sibs-admin-sb',c?'1':'0');
}

/* ── Notification bell ── */
function toggleNotif(e){
  e.stopPropagation();
  var dd=document.getElementById('notifDd');
  if(dd.classList.contains('open')){dd.classList.remove('open');}
  else{dd.classList.add('open');loadNotifications();}
}
function closeNotif(){
  var dd=document.getElementById('notifDd');
  if(dd)dd.classList.remove('open');
}
document.addEventListener('click',function(e){
  var w=document.getElementById('notifWrap');
  if(w&&!w.contains(e.target))closeNotif();
});

/* ── SPA nav ── */
var frame=document.getElementById('cf');
var home=document.getElementById('dash-home');
var loader=document.getElementById('loader');
var lTxt=document.getElementById('load-txt');
var pgLbl=document.getElementById('pg-label');
var cur='home';

function setActive(p){
  document.querySelectorAll('.ni[data-page]').forEach(function(el){
    el.classList.toggle('active',el.dataset.page===p||el.dataset.page===p.split('?')[0]);
  });
}
function nav(url,label){
  if(cur===url)return;
  cur=url;pgLbl.textContent=label;setActive(url);
  if(url==='home'){frame.style.display='none';home.style.display='block';return;}
  lTxt.textContent='Loading '+label+'…';
  loader.classList.add('on');
  home.style.display='none';frame.style.display='none';
  frame.src=url;
  frame.onload=function(){
    refreshStats();loadNotifications();
    loader.classList.remove('on');
    try{
      var u=frame.contentWindow.location.href;
      if(u.indexOf('login')!==-1){window.top.location.href='login.jsp';return;}
    }catch(e){}
    frame.style.display='block';
    try{
      var doc=frame.contentDocument||frame.contentWindow.document;
      var old=doc.getElementById('__emb');if(old)old.remove();
      var s=doc.createElement('style');s.id='__emb';
      s.textContent='.sidebar,#sidebar{display:none!important}.topbar{display:none!important}.content,.content-area,.main-content,main{margin-left:0!important;padding-left:24px!important}html,body{height:auto!important;overflow:auto!important}';
      doc.head.appendChild(s);
    }catch(e){}
  };
  frame.onerror=function(){loader.classList.remove('on');frame.style.display='block';};
}

/* ── Stats refresh ── */
function refreshStats(){
  fetch('getDashboardStats').then(function(r){return r.json();}).then(function(d){
    function ui(id,v){var el=document.getElementById(id);if(el&&v!==undefined)el.textContent=v;}
    ui('kpi-sales',d.totalSales);ui('kpi-lowstock',d.lowStock);
    ui('kpi-products',d.totalProducts);ui('kpi-users',d.totalUsers);
    function badge(id,v){
      var el=document.getElementById(id);if(!el)return;
      if(v>0){el.textContent=v;el.style.display='';}else{el.style.display='none';}
    }
    badge('badge-returns',d.pendingReturns);badge('badge-approvals',d.pendingApprovals);
    badge('badge-leaves',d.pendingLeaves);badge('badge-support',d.openComplaints);
    badge('badge-slots',d.todaySlots);badge('badge-cod',d.pendingCod);
  }).catch(function(){});
}
refreshStats();setInterval(refreshStats,30000);

/* ── Notifications ── */
function loadNotifications(){
  fetch('getNotifications').then(function(r){return r.json();}).then(function(data){
    var badge=document.getElementById('notifBadge');
    if(badge){
      if(data.unread>0){badge.textContent=data.unread;badge.style.display='';}
      else{badge.style.display='none';}
    }
    var title=document.getElementById('ndTitle');
    if(title)title.textContent=data.unread>0?'Notifications ('+data.unread+')':'Notifications';
    var list=document.getElementById('ndList');
    var foot=document.getElementById('ndFoot');
    if(!list)return;
    if(!data.items||data.items.length===0){
      list.innerHTML='<div class="nd-empty"><i class="fa fa-bell-slash"></i><p>No new notifications</p></div>';
      if(foot)foot.style.display='none';return;
    }
    var icoMap={
      ORDER:{icon:'fa-shopping-bag',bg:'#fef3c7',cl:'#d97706'},
      RETURN:{icon:'fa-rotate-left',bg:'#e0f2fe',cl:'#0284c7'},
      COMPLAINT:{icon:'fa-headset',bg:'#fee2e2',cl:'#dc2626'},
      LEAVE:{icon:'fa-calendar-xmark',bg:'#fce7f3',cl:'#db2777'},
      DELIVERY:{icon:'fa-truck',bg:'#fef3c7',cl:'#d97706'},
      SYSTEM:{icon:'fa-bell',bg:'#ede9fe',cl:'#7c3aed'}
    };
    list.innerHTML=data.items.map(function(n){
      var ic=icoMap[n.category]||icoMap['SYSTEM'];
      return '<div class="nd-item" onclick="markOneRead('+n.id+',' + JSON.stringify(n.linkUrl||'') + ')" style="'+(n.isRead?'opacity:.7;':'font-weight:600;')+'">'
        +'<div class="nd-ico" style="background:'+ic.bg+';color:'+ic.cl+';"><i class="fa '+ic.icon+'"></i></div>'
        +'<div class="nd-body"><div class="nd-t">'+n.title+'</div><div class="nd-s">'+n.message+'</div>'
        +'<div style="font-size:10px;color:var(--muted2);margin-top:2px;">'+n.relativeTime+'</div></div>'
        +(!n.isRead?'<div class="nd-dot"></div>':'')+'</div>';
    }).join('');
    if(foot)foot.style.display='';
  }).catch(function(){});
}
function markOneRead(id,url){
  fetch('getNotifications?action=markRead&id='+id,{method:'POST'}).then(function(){loadNotifications();});
  closeNotif();
  if(url)setTimeout(function(){nav(url,'');},150);
}
function markAllRead(){
  fetch('getNotifications?action=markAllRead',{method:'POST'}).then(function(){loadNotifications();});
  closeNotif();
}
loadNotifications();
setInterval(function(){if(!document.hidden)loadNotifications();},30000);
</script>
</body>
</html>
