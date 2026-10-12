package com.sibs.servlet;

import com.sibs.dao.NotificationDAO;
import com.sibs.dao.SupportComplaintDAO;
import com.sibs.model.SupportComplaint;
import com.sibs.model.User;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.*;
import java.nio.file.*;

/**
 * RaiseComplaintServlet
 *
 * URL : POST /raiseComplaint
 * Who : Customer (session="customer")
 *
 * On success:
 *   1. Inserts a new support complaint (status OPEN, ticket ID SUP-XXXX).
 *   2. Sends an in-app notification to ALL staff (broadcast, staff_id = 0).
 *   3. Redirects customer back to customer-support.jsp with a success message.
 */
@WebServlet("/raiseComplaint")
@MultipartConfig(maxFileSize = 5 * 1024 * 1024) // 5 MB photo limit
public class RaiseComplaintServlet extends HttpServlet {

    private static final String UPLOAD_DIR = "complaint-photos";

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        User customer = (session != null) ? (User) session.getAttribute("customer") : null;

        if (customer == null) {
            res.sendRedirect(req.getContextPath() + "/customer-login.jsp");
            return;
        }

        // ── Read form fields ───────────────────────────────────────────────────
        String issueType   = req.getParameter("issueType");
        String description = req.getParameter("description");
        String orderIdStr  = req.getParameter("orderId");

        if (issueType == null || issueType.isBlank()) {
            redirect(req, res, "error", "Please select an issue type.");
            return;
        }

        // ── Optional photo upload ──────────────────────────────────────────────
        String photoPath = null;
        Part photoPart = req.getPart("photo");
        if (photoPart != null && photoPart.getSize() > 0) {
            String uploadDir = getServletContext().getRealPath("") + File.separator + UPLOAD_DIR;
            Files.createDirectories(Paths.get(uploadDir));

            String originalName = Paths.get(photoPart.getSubmittedFileName()).getFileName().toString();
            String ext          = originalName.contains(".")
                                  ? originalName.substring(originalName.lastIndexOf('.'))
                                  : ".jpg";
            String fileName     = "cp_" + System.currentTimeMillis() + "_" + customer.getId() + ext;
            photoPart.write(uploadDir + File.separator + fileName);
            photoPath = UPLOAD_DIR + "/" + fileName;
        }

        // ── Build model & persist ──────────────────────────────────────────────
        SupportComplaint c = new SupportComplaint();
        c.setUserId(customer.getId());
        c.setIssueType(issueType);
        c.setDescription(description == null ? "" : description.trim());
        c.setPhotoPath(photoPath);

        if (orderIdStr != null && !orderIdStr.isBlank()) {
            try { c.setOrderId(Integer.parseInt(orderIdStr)); }
            catch (NumberFormatException ignored) { }
        }

        try {
            int newId = new SupportComplaintDAO().insert(c);
            String ticketId = String.format("SUP-%04d", newId);

            // ── NOTIFICATION: alert all staff of the new complaint ─────────────
            try {
                String customerName = (customer.getName() != null && !customer.getName().isBlank())
                    ? customer.getName()
                    : customer.getUsername();
                NotificationDAO.sendNewComplaintToStaff(newId, customerName);
            } catch (Exception ex) {
                ex.printStackTrace(); // non-fatal — complaint is already saved
            }
            // ──────────────────────────────────────────────────────────────────

            session.setAttribute("supportMsg",
                "✅ Complaint submitted! Your ticket ID is <strong>" + ticketId + "</strong>. "
              + "We will review it shortly.");
            res.sendRedirect(req.getContextPath() + "/customer-support.jsp");

        } catch (Exception e) {
            getServletContext().log("RaiseComplaintServlet error", e);
            redirect(req, res, "error", "Something went wrong. Please try again.");
        }
    }

    private void redirect(HttpServletRequest req, HttpServletResponse res,
                          String key, String msg) throws IOException {
        req.getSession().setAttribute(key.equals("error") ? "supportError" : "supportMsg", msg);
        res.sendRedirect(req.getContextPath() + "/customer-support.jsp");
    }
}