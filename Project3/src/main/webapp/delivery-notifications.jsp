/**
 * delivery-notifications.js
 * 
 * Include this script in your delivery boy JSP pages (delivery-dashboard.jsp, etc.)
 * It polls the server every 15 seconds and updates the notification bell dynamically.
 *
 * USAGE in JSP:
 *   <script src="${pageContext.request.contextPath}/js/delivery-notifications.js"></script>
 *
 * REQUIRED HTML in your navbar:
 *   <div id="notif-bell-container" style="position:relative; display:inline-block;">
 *     <button id="notif-bell-btn" onclick="toggleNotifDropdown()" style="background:none;border:none;cursor:pointer;position:relative;">
 *       🔔
 *       <span id="notif-badge" style="display:none; position:absolute; top:-6px; right:-6px;
 *             background:#e53e3e; color:#fff; border-radius:50%; font-size:11px;
 *             min-width:18px; height:18px; line-height:18px; text-align:center; padding:0 4px;">
 *         0
 *       </span>
 *     </button>
 *     <div id="notif-dropdown" style="display:none; position:absolute; right:0; top:110%;
 *          width:340px; background:#fff; border:1px solid #e2e8f0; border-radius:10px;
 *          box-shadow:0 8px 24px rgba(0,0,0,.12); z-index:9999; overflow:hidden;">
 *       <div style="display:flex;justify-content:space-between;align-items:center;
 *                   padding:12px 16px; border-bottom:1px solid #e2e8f0;">
 *         <strong>Notifications</strong>
 *         <a href="#" onclick="markAllRead(); return false;"
 *            style="font-size:12px;color:#4a90d9;">Mark all as read</a>
 *       </div>
 *       <div id="notif-list" style="max-height:360px;overflow-y:auto;"></div>
 *       <div style="padding:10px;text-align:center;border-top:1px solid #e2e8f0;">
 *         <a href="delivery-notifications.jsp" style="font-size:13px;color:#4a90d9;">
 *           View all notifications
 *         </a>
 *       </div>
 *     </div>
 *   </div>
 */

(function () {
    'use strict';

    var POLL_INTERVAL_MS = 15000;   // 15 seconds — adjust as needed
    var LIMIT            = 10;       // how many notifications to fetch
    var _pollTimer       = null;
    var _dropdownOpen    = false;

    /* ── Category icons ──────────────────────────────────────────────────── */
    var ICONS = {
        DELIVERY : '🛵',
        ORDER    : '📦',
        PAYMENT  : '💰',
        COMPLAINT: '📣',
        ACCOUNT  : '👤',
        LEAVE    : '🏖️',
        DEFAULT  : '🔔'
    };

    function icon(category) {
        return ICONS[category] || ICONS.DEFAULT;
    }

    /* ── Fetch notifications from server ─────────────────────────────────── */
    function fetchNotifications() {
        fetch('delivery-notifications?action=poll&limit=' + LIMIT, {
            method      : 'GET',
            credentials : 'same-origin'
        })
        .then(function (r) {
            if (r.status === 401) {
                // Session expired — stop polling
                clearInterval(_pollTimer);
                return null;
            }
            return r.json();
        })
        .then(function (data) {
            if (!data) return;
            updateBadge(data.unreadCount);
            renderList(data.notifications);
        })
        .catch(function (err) {
            console.warn('[Notifications] Poll failed:', err);
        });
    }

    /* ── Update the red badge count ──────────────────────────────────────── */
    function updateBadge(count) {
        var badge = document.getElementById('notif-badge');
        if (!badge) return;
        if (count > 0) {
            badge.style.display = 'inline-block';
            badge.textContent   = count > 99 ? '99+' : count;
        } else {
            badge.style.display = 'none';
        }
    }

    /* ── Render notification list inside dropdown ─────────────────────────── */
    function renderList(notifications) {
        var list = document.getElementById('notif-list');
        if (!list) return;

        if (!notifications || notifications.length === 0) {
            list.innerHTML =
                '<p style="text-align:center;padding:24px;color:#a0aec0;font-size:13px;">' +
                'No notifications yet</p>';
            return;
        }

        var html = '';
        notifications.forEach(function (n) {
            var bg      = n.isRead ? '#fff' : '#ebf4ff';
            var border  = n.isRead ? '' : 'border-left:3px solid #4a90d9;';
            var link    = n.linkUrl || '#';
            var onClick = n.isRead ? '' :
                'onclick="markOneRead(' + n.id + ', this)"';

            html += '<a href="' + link + '" ' + onClick +
                    ' style="display:block;padding:12px 16px;text-decoration:none;' +
                    'color:#2d3748;background:' + bg + ';' + border +
                    'border-bottom:1px solid #f0f4f8;transition:background .15s;"' +
                    ' onmouseover="this.style.background=\'#f7fafc\'"' +
                    ' onmouseout="this.style.background=\'' + bg + '\'">' +

                    '<div style="display:flex;gap:10px;align-items:flex-start;">' +
                    '<span style="font-size:20px;flex-shrink:0;">' + icon(n.category) + '</span>' +
                    '<div style="flex:1;min-width:0;">' +
                    '<div style="font-weight:' + (n.isRead ? '400' : '600') +
                    ';font-size:13px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">' +
                    escHtml(n.title) + '</div>' +
                    '<div style="font-size:12px;color:#718096;margin-top:2px;' +
                    'white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">' +
                    escHtml(n.message) + '</div>' +
                    '<div style="font-size:11px;color:#a0aec0;margin-top:4px;">' +
                    escHtml(n.timeAgo) + '</div>' +
                    '</div></div></a>';
        });

        list.innerHTML = html;
    }

    /* ── Mark single notification read (optimistic UI) ───────────────────── */
    window.markOneRead = function (id, linkEl) {
        fetch('delivery-notifications?action=markRead', {
            method      : 'POST',
            credentials : 'same-origin',
            headers     : { 'Content-Type': 'application/x-www-form-urlencoded' },
            body        : 'id=' + id
        });
        // Optimistically update styling
        if (linkEl) {
            linkEl.style.background  = '#fff';
            linkEl.style.borderLeft  = '';
            linkEl.style.fontWeight  = '400';
        }
        // Decrement badge
        var badge = document.getElementById('notif-badge');
        if (badge) {
            var cur = parseInt(badge.textContent) || 0;
            updateBadge(Math.max(0, cur - 1));
        }
    };

    /* ── Mark all as read ────────────────────────────────────────────────── */
    window.markAllRead = function () {
        fetch('delivery-notifications?action=markAll', {
            method      : 'POST',
            credentials : 'same-origin'
        }).then(function () {
            updateBadge(0);
            // Re-render list with all items as read
            var items = document.querySelectorAll('#notif-list a');
            items.forEach(function (el) {
                el.style.background = '#fff';
                el.style.borderLeft = '';
            });
            fetchNotifications(); // refresh from server
        });
    };

    /* ── Toggle dropdown open/close ──────────────────────────────────────── */
    window.toggleNotifDropdown = function () {
        var dd = document.getElementById('notif-dropdown');
        if (!dd) return;
        _dropdownOpen = !_dropdownOpen;
        dd.style.display = _dropdownOpen ? 'block' : 'none';
    };

    /* ── Close dropdown when clicking outside ────────────────────────────── */
    document.addEventListener('click', function (e) {
        var container = document.getElementById('notif-bell-container');
        if (container && !container.contains(e.target)) {
            var dd = document.getElementById('notif-dropdown');
            if (dd) dd.style.display = 'none';
            _dropdownOpen = false;
        }
    });

    /* ── HTML escape helper ──────────────────────────────────────────────── */
    function escHtml(str) {
        if (!str) return '';
        return str.replace(/&/g, '&amp;')
                  .replace(/</g, '&lt;')
                  .replace(/>/g, '&gt;')
                  .replace(/"/g, '&quot;');
    }

    /* ── Boot ────────────────────────────────────────────────────────────── */
    document.addEventListener('DOMContentLoaded', function () {
        fetchNotifications();                          // immediate first load
        _pollTimer = setInterval(fetchNotifications, POLL_INTERVAL_MS);
    });

})();