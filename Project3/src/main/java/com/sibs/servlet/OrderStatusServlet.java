package com.sibs.servlet;

import com.sibs.util.DBConnection;
import jakarta.servlet.AsyncContext;
import jakarta.servlet.AsyncEvent;
import jakarta.servlet.AsyncListener;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.*;
import java.util.concurrent.atomic.AtomicBoolean;

@WebServlet(urlPatterns = "/orderStatus", asyncSupported = true)
public class OrderStatusServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res) throws IOException {

        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("customer") == null) {
            res.sendError(HttpServletResponse.SC_UNAUTHORIZED);
            return;
        }

        com.sibs.model.User user = (com.sibs.model.User) session.getAttribute("customer");
        int userId = user.getId();

        res.setContentType("text/event-stream");
        res.setCharacterEncoding("UTF-8");
        res.setHeader("Cache-Control", "no-cache");
        res.setHeader("Connection", "keep-alive");
        res.setHeader("X-Accel-Buffering", "no");

        AsyncContext async = req.startAsync();
        async.setTimeout(5 * 60 * 1000); // 5 minutes

        // FIX: track whether async is already completed (by timeout or client disconnect)
        AtomicBoolean completed = new AtomicBoolean(false);

        async.addListener(new AsyncListener() {
            public void onComplete(AsyncEvent e) { completed.set(true); }
            public void onTimeout(AsyncEvent e)  {
                completed.set(true);
                try { async.complete(); } catch (Exception ignored) {}
            }
            public void onError(AsyncEvent e)    {
                completed.set(true);
                try { async.complete(); } catch (Exception ignored) {}
            }
            public void onStartAsync(AsyncEvent e) {}
        });

        PrintWriter writer = res.getWriter();

        new Thread(() -> {
            String lastSnapshot = "";
            int retries = 0;

            while (retries < 100 && !completed.get()) {
                try {
                    String snapshot = fetchStatusSnapshot(userId);
                    if (!snapshot.equals(lastSnapshot)) {
                        lastSnapshot = snapshot;
                        writer.write("data: " + snapshot + "\n\n");
                        writer.flush();
                    }
                    if (retries % 5 == 0) {
                        writer.write(": heartbeat\n\n");
                        writer.flush();
                    }
                    if (writer.checkError()) break; // client disconnected
                    Thread.sleep(3000);
                    retries++;
                } catch (Exception e) {
                    break;
                }
            }

            // FIX: only call complete() if not already done
            if (completed.compareAndSet(false, true)) {
                try { async.complete(); } catch (Exception ignored) {}
            }
        }).start();
    }

    private String fetchStatusSnapshot(int userId) {
        StringBuilder sb = new StringBuilder("[");
        String sql =
            "SELECT o.group_id, o.id AS order_id, o.status, " +
            "       da.otp, da.id AS assign_id, da.status AS da_status " +
            "FROM orders o " +
            "LEFT JOIN delivery_assignments da ON da.order_id = o.id " +
            "WHERE o.user_id = ? " +
            "ORDER BY o.group_id DESC, o.id ASC";

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, userId);
            ResultSet rs = ps.executeQuery();
            boolean first = true;
            int lastGroup = -1;
            while (rs.next()) {
                int groupId = rs.getInt("group_id");
                if (groupId == lastGroup) continue;
                lastGroup = groupId;

                int    orderId  = rs.getInt("order_id");
                String status   = rs.getString("status");
                String otp      = rs.getString("otp");
                int    assignId = rs.getInt("assign_id");
                String daStatus = rs.getString("da_status");

                if (!first) sb.append(",");
                first = false;
                sb.append("{")
                  .append("\"groupId\":").append(groupId).append(",")
                  .append("\"orderId\":").append(orderId).append(",")
                  .append("\"status\":\"").append(status != null ? status : "PENDING").append("\",")
                  .append("\"daStatus\":\"").append(daStatus != null ? daStatus.toUpperCase() : "").append("\",")
                  .append("\"assignId\":").append(assignId).append(",")
                  .append("\"otp\":\"").append(otp != null ? otp : "").append("\"")
                  .append("}");
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        sb.append("]");
        return sb.toString();
    }
}