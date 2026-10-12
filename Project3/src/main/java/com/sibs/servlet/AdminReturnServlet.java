package com.sibs.servlet;

import com.sibs.dao.DeliveryBoyDAO;
import com.sibs.dao.NotificationDAO;
import com.sibs.dao.ReturnDAO;
import com.sibs.model.ReturnRequest;
import com.sibs.model.User;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.util.List;

@WebServlet("/AdminReturnServlet")
public class AdminReturnServlet extends HttpServlet {

    private final ReturnDAO returnDAO = new ReturnDAO();
    private final DeliveryBoyDAO deliveryBoyDAO = new DeliveryBoyDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        User user = getAuthorizedUser(req, resp);
        if (user == null) return;

        String status = req.getParameter("status");
        List<ReturnRequest> returns = (status != null && !status.isEmpty())
                ? returnDAO.getReturnsByStatus(status)
                : returnDAO.getAllReturns();

        req.setAttribute("returns", returns);
        req.setAttribute("filterStatus", status);
        req.setAttribute("currentUser", user);
        // Pass delivery boys for the Schedule Pickup modal
        req.setAttribute("deliveryBoys", deliveryBoyDAO.getAllDeliveryBoys());
        req.getRequestDispatcher("/managereturns.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        User user = getAuthorizedUser(req, resp);
        if (user == null) return;

        // Admin is monitoring only — all actions belong to staff
        if ("admin".equalsIgnoreCase(user.getRole())) {
            req.getSession().setAttribute("errorMsg", "Admins can only monitor returns. Actions are for staff.");
            resp.sendRedirect(req.getContextPath() + "/AdminReturnServlet");
            return;
        }

        String action   = req.getParameter("action");
        int    returnId = Integer.parseInt(req.getParameter("returnId"));
        boolean ok      = false;

        switch (action == null ? "" : action) {

            case "approve": {
                double refundAmount = Double.parseDouble(req.getParameter("refundAmount"));
                String refundMethod = req.getParameter("refundMethod");
                String adminNote    = req.getParameter("adminNote");
                ok = returnDAO.approveReturn(returnId, refundAmount, refundMethod, adminNote);
                if (ok) {
                    com.sibs.model.ReturnRequest rr = returnDAO.getReturnById(returnId);
                    if (rr != null) NotificationDAO.sendReturnStatusChanged(rr.getUserId(), returnId, rr.getProductName() != null ? rr.getProductName() : "your product", "Approved");
                }
                break;
            }
            case "reject": {
                String adminNote = req.getParameter("adminNote");
                ok = returnDAO.rejectReturn(returnId, adminNote);
                if (ok) {
                    com.sibs.model.ReturnRequest rr = returnDAO.getReturnById(returnId);
                    if (rr != null) NotificationDAO.sendReturnStatusChanged(rr.getUserId(), returnId, rr.getProductName() != null ? rr.getProductName() : "your product", "Rejected");
                }
                break;
            }
            case "schedulePickup": {
                String dbIdParam = req.getParameter("deliveryBoyId");
                if (dbIdParam == null || dbIdParam.isEmpty()) {
                    req.getSession().setAttribute("errorMsg", "Please select a delivery boy before scheduling pickup.");
                    resp.sendRedirect(req.getContextPath() + "/AdminReturnServlet?action=list");
                    return;
                }
                int deliveryBoyId = Integer.parseInt(dbIdParam);
                String otp = returnDAO.assignPickupDeliveryBoy(returnId, deliveryBoyId);
                ok = (otp != null);
                if (ok) {
                    com.sibs.model.ReturnRequest rr = returnDAO.getReturnById(returnId);
                    if (rr != null) {
                        NotificationDAO.sendReturnStatusChanged(rr.getUserId(), returnId,
                            rr.getProductName() != null ? rr.getProductName() : "your product",
                            "Pickup Scheduled – Delivery Boy Assigned");
                    }
                }
                break;
            }
            case "confirmPickup":
                ok = returnDAO.confirmPickup(returnId);
                break;
            case "refund":
                ok = returnDAO.processRefund(returnId);
                break;
            default:
                req.getSession().setAttribute("errorMsg", "Unknown action.");
        }

        req.getSession().setAttribute(ok ? "successMsg" : "errorMsg",
                ok ? "Return updated successfully." : "Action failed. Please try again.");

        resp.sendRedirect(req.getContextPath() + "/AdminReturnServlet?action=list");
    }

    // Admin (monitoring only) and staff (full actions) both access the view
    private User getAuthorizedUser(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        HttpSession session = req.getSession(false);
        User user = (session != null) ? (User) session.getAttribute("user") : null;
        if (user == null) { resp.sendRedirect(req.getContextPath() + "/login.jsp"); return null; }

        String role = user.getRole();
        if (!"admin".equalsIgnoreCase(role) && !"staff".equalsIgnoreCase(role)) {
            resp.sendRedirect(req.getContextPath() + "/login.jsp");
            return null;
        }
        return user;
    }
}