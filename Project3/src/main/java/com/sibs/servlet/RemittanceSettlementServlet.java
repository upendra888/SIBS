package com.sibs.servlet;

import com.sibs.dao.DeliveryBoyEarningsDAO;
import com.sibs.dao.DeliveryBoyEarningsDAO.EarningsSummary;
import com.sibs.dao.NotificationDAO;
import com.sibs.model.User;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.List;

@WebServlet("/remittanceSettlement")
public class RemittanceSettlementServlet extends HttpServlet {

    private final DeliveryBoyEarningsDAO earningsDAO = new DeliveryBoyEarningsDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        User admin = session != null ? (User) session.getAttribute("user") : null;
        if (admin == null || !"ADMIN".equals(admin.getRole())) {
            res.sendRedirect("login.jsp");
            return;
        }

        List<EarningsSummary> summaries = earningsDAO.getAllSettlementPreview();
        req.setAttribute("remittanceSummaries", summaries);
        req.getRequestDispatcher("remittance-settlement.jsp").forward(req, res);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        User admin = session != null ? (User) session.getAttribute("user") : null;
        if (admin == null || !"ADMIN".equals(admin.getRole())) {
            res.sendRedirect("login.jsp");
            return;
        }

        String action = req.getParameter("action");

        // ── Preview (AJAX call) ───────────────────────────────────────────────
        if ("preview".equals(action)) {
            res.setContentType("application/json");
            res.setCharacterEncoding("UTF-8");
            PrintWriter out = res.getWriter();
            try {
                int    deliveryBoyId = Integer.parseInt(req.getParameter("deliveryBoyId"));
                double baseSalary    = Double.parseDouble(req.getParameter("baseSalary"));
                EarningsSummary es   = earningsDAO.calculateSettlement(deliveryBoyId, baseSalary);
                out.print("{" +
                    "\"baseSalary\":"           + es.baseSalary          + "," +
                    "\"totalCashCollected\":"   + es.totalCashCollected  + "," +
                    "\"totalDeliveryCharge\":"  + es.totalDeliveryCharge + "," +
                    "\"totalRemittance\":"      + es.totalRemittance     + "," +
                    "\"finalPayout\":"          + es.finalPayout         +
                "}");
            } catch (Exception e) {
                out.print("{\"error\":\"" + e.getMessage() + "\"}");
            }
            return;
        }

        // ── Process settlement ────────────────────────────────────────────────
        try {
            int    deliveryBoyId = Integer.parseInt(req.getParameter("deliveryBoyId"));
            double baseSalary    = Double.parseDouble(req.getParameter("baseSalary"));
            String note          = req.getParameter("note");
            if (note == null || note.isBlank()) note = "Monthly salary settlement";

            EarningsSummary es = earningsDAO.processSettlement(deliveryBoyId, baseSalary, note);
            req.getSession().setAttribute("settlementResult", es);

            // Notify delivery boy: earnings settled
            NotificationDAO.sendEarningsCredited(deliveryBoyId, es.finalPayout, "monthly settlement");

            res.sendRedirect("remittance-settlement.jsp?settled=1&boyId=" + deliveryBoyId);

        } catch (Exception e) {
            e.printStackTrace();
            res.sendRedirect("remittance-settlement.jsp?error=settlement_failed");
        }
    }
}