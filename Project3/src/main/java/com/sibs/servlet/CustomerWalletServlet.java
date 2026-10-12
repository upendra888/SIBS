package com.sibs.servlet;

import com.sibs.dao.CustomerWalletDAO;
import com.sibs.model.User;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;

/**
 * CustomerWalletServlet
 *
 * GET /customerWallet?action=balance
 *     → JSON { "balance": 120.50 }
 *
 * GET /customerWallet?action=transactions
 *     → JSON array of transactions
 *
 * (For the full wallet page, use customer-wallet.jsp which calls DAO directly.)
 */
@WebServlet("/customerWallet")
public class CustomerWalletServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res) throws IOException {
        res.setContentType("application/json");
        res.setCharacterEncoding("UTF-8");

        HttpSession session = req.getSession(false);
        User user = session != null ? (User) session.getAttribute("customer") : null;
        if (user == null) {
            res.setStatus(401);
            res.getWriter().write("{\"error\":\"Not logged in\"}");
            return;
        }

        String action = req.getParameter("action");
        CustomerWalletDAO dao = new CustomerWalletDAO();

        if ("balance".equals(action) || action == null) {
            double bal = dao.getBalance(user.getId());
            res.getWriter().write("{\"balance\":" + String.format("%.2f", bal) + "}");

        } else if ("transactions".equals(action)) {
            var txns = dao.getTransactions(user.getId());
            StringBuilder sb = new StringBuilder("[");
            for (int i = 0; i < txns.size(); i++) {
                String[] t = txns.get(i);
                if (i > 0) sb.append(",");
                sb.append("{");
                sb.append("\"amount\":").append(t[0]).append(",");
                sb.append("\"type\":\"").append(escape(t[1])).append("\",");
                sb.append("\"reason\":\"").append(escape(t[2])).append("\",");
                sb.append("\"orderId\":").append(t[3] != null ? t[3] : "null").append(",");
                sb.append("\"date\":\"").append(escape(t[4])).append("\"");
                sb.append("}");
            }
            sb.append("]");
            res.getWriter().write(sb.toString());

        } else {
            res.setStatus(400);
            res.getWriter().write("{\"error\":\"Unknown action\"}");
        }
    }

    private String escape(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"");
    }
}