package com.sibs.servlet;

import com.sibs.dao.DeliveryBoyDAO;
import com.sibs.dao.NotificationDAO;
import com.sibs.model.DeliveryBoy;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;

/**
 * WalletWithdrawServlet
 *
 * POST /walletWithdraw
 *   Params: amount (double)
 *
 * Instead of immediately debiting the wallet, creates a
 * wallet_withdraw_requests row (status=PENDING) and notifies staff.
 * The staff reviews it via StaffWithdrawServlet.
 */
@WebServlet("/walletWithdraw")
public class WalletWithdrawServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {

        // Auth check
        DeliveryBoy db = (DeliveryBoy) req.getSession().getAttribute("deliveryBoy");
        if (db == null) {
            resp.sendRedirect("delivery-login.jsp");
            return;
        }

        // Parse amount
        double amount;
        try {
            amount = Double.parseDouble(req.getParameter("amount"));
        } catch (Exception e) {
            resp.sendRedirect("delivery-wallet.jsp?flash=invalid_amount");
            return;
        }

        DeliveryBoyDAO dao = new DeliveryBoyDAO();
        String result = dao.requestWithdraw(db.getId(), amount);

        switch (result) {
            case "OK":
                // Notify all staff about the new request
                NotificationDAO.sendWithdrawRequestToStaff(
                    db.getId(), db.getName(), amount);
                resp.sendRedirect("delivery-wallet.jsp?flash=withdraw_requested");
                break;
            case "INSUFFICIENT":
                resp.sendRedirect("delivery-wallet.jsp?flash=insufficient");
                break;
            case "INVALID_AMOUNT":
                resp.sendRedirect("delivery-wallet.jsp?flash=invalid_amount");
                break;
            case "PENDING_EXISTS":
                resp.sendRedirect("delivery-wallet.jsp?flash=pending_exists");
                break;
            default:
                resp.sendRedirect("delivery-wallet.jsp?flash=error");
        }
    }
}