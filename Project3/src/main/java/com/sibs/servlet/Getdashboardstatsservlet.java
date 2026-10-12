package com.sibs.servlet;

import com.sibs.dao.DashboardDAO;
import com.sibs.dao.DeliveryBoyDAO;
import com.sibs.dao.ReturnDAO;
import com.sibs.dao.StaffLeaveDAO;
import com.sibs.dao.SupportComplaintDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import com.sibs.model.User;
import java.io.IOException;

/**
 * SIBS — Real-time dashboard stats endpoint
 * Returns JSON with all sidebar badge counts + KPI stats.
 * Called by dashboard.jsp every 30 seconds via fetch().
 */
@WebServlet("/getDashboardStats")
public class Getdashboardstatsservlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        User user = (User) req.getSession().getAttribute("user");
        if (user == null) {
            res.setStatus(401);
            res.getWriter().write("{\"error\":\"unauthorized\"}");
            return;
        }

        res.setContentType("application/json");
        res.setCharacterEncoding("UTF-8");

        try {
            DashboardDAO dao = new DashboardDAO();

            // KPI cards
            int totalProducts    = dao.getTotalProducts();
            int totalUsers       = dao.getTotalUsers();
            int totalSales       = dao.getTotalSales();
            int lowStock         = dao.getLowStockCount();

            // Sidebar badges
            int pendingOrders    = 0;
            int cancelledToday   = 0;
            int pendingReturns   = 0;
            int pendingApprovals = 0;
            int onlineDeliveries = 0;
            int activeDeliveries = 0;
            int todaySlots       = 0;
            int pendingCod       = 0;
            int todaySales       = 0;
            int absentStaff      = 0;
            int pendingLeaves    = 0;
            int openComplaints   = 0;
            int pendingWithdrawals = 0;

            try { pendingOrders    = dao.getPendingOrdersCount();          } catch (Exception e) {}
            try { cancelledToday   = dao.getCancelledOrdersCount();        } catch (Exception e) {}
            try { onlineDeliveries = dao.getOnlineDeliveryBoysCount();     } catch (Exception e) {}
            try { activeDeliveries = dao.getActiveDeliveriesCount();       } catch (Exception e) {}
            try { todaySlots       = dao.getTodaySlotsCount();             } catch (Exception e) {}
            try { pendingCod       = dao.getPendingCodCount();             } catch (Exception e) {}
            try { todaySales       = dao.getTodaySalesCount();             } catch (Exception e) {}
            try { absentStaff      = dao.getAbsentStaffCount();            } catch (Exception e) {}
            try { pendingReturns   = new ReturnDAO().countPending();        } catch (Exception e) {}
            try { pendingApprovals = new DeliveryBoyDAO().countPendingApprovals(); } catch (Exception e) {}
            try { pendingLeaves    = new StaffLeaveDAO().countAllPending(); } catch (Exception e) {}
            try { openComplaints   = new SupportComplaintDAO().countOpen(); } catch (Exception e) {}
            try { pendingWithdrawals = new DeliveryBoyDAO().countPendingWithdrawRequests(); } catch (Exception e) {}

            String json = String.format(
                "{\"totalProducts\":%d,\"totalUsers\":%d,\"totalSales\":%d,\"lowStock\":%d," +
                "\"pendingOrders\":%d,\"cancelledToday\":%d,\"pendingReturns\":%d," +
                "\"pendingApprovals\":%d,\"onlineDeliveries\":%d,\"activeDeliveries\":%d," +
                "\"todaySlots\":%d,\"pendingCod\":%d,\"todaySales\":%d," +
                "\"absentStaff\":%d,\"pendingLeaves\":%d,\"openComplaints\":%d," +
                "\"pendingWithdrawals\":%d}",
                totalProducts, totalUsers, totalSales, lowStock,
                pendingOrders, cancelledToday, pendingReturns,
                pendingApprovals, onlineDeliveries, activeDeliveries,
                todaySlots, pendingCod, todaySales,
                absentStaff, pendingLeaves, openComplaints,
                pendingWithdrawals
            );
            res.getWriter().write(json);
        } catch (Exception e) {
            res.setStatus(500);
            res.getWriter().write("{\"error\":\"server error\"}");
        }
    }
}