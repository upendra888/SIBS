package com.sibs.servlet;

import com.sibs.dao.NotificationDAO;
import com.sibs.util.DBConnection;
import com.sibs.util.EmailService;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.File;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;

@WebServlet("/deliveryDocUpload")
@MultipartConfig(
    fileSizeThreshold = 1024 * 1024,      // 1 MB
    maxFileSize       = 10 * 1024 * 1024, // 10 MB per file
    maxRequestSize    = 60 * 1024 * 1024  // 60 MB total
)
public class DeliveryDocumentUploadServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);

        // Guard: must have a pending delivery boy ID in session
        Integer deliveryBoyId = (session != null)
                ? (Integer) session.getAttribute("pending_delivery_boy_id")
                : null;

        if (deliveryBoyId == null) {
            res.sendRedirect("delivery-register.jsp");
            return;
        }

        // ── Create upload directory ──────────────────────────────────────────
        String uploadDir = getServletContext().getRealPath("/uploads/delivery-docs/");
        File dir = new File(uploadDir);
        if (!dir.exists()) dir.mkdirs();

        // ── Save each document file ──────────────────────────────────────────
        String aadhaarPath = saveFile(req, "aadhaar",  uploadDir, deliveryBoyId);
        String panPath     = saveFile(req, "pan",      uploadDir, deliveryBoyId);
        String licencePath = saveFile(req, "licence",  uploadDir, deliveryBoyId);
        String rcPath      = saveFile(req, "rc",       uploadDir, deliveryBoyId);
        String photoPath   = saveFile(req, "photo",    uploadDir, deliveryBoyId);

        // Validate all required files were uploaded
        if (aadhaarPath == null || panPath == null || licencePath == null
                || rcPath == null || photoPath == null) {
            res.sendRedirect("delivery-documents.jsp?error=missing");
            return;
        }

        // ── Bank details ─────────────────────────────────────────────────────
        String bankName      = req.getParameter("bankName");
        String accountHolder = req.getParameter("accountHolder");
        String accountNumber = req.getParameter("accountNumber");
        String ifscCode      = req.getParameter("ifscCode");

        if (bankName == null || accountHolder == null
                || accountNumber == null || ifscCode == null
                || bankName.isBlank() || accountNumber.isBlank() || ifscCode.isBlank()) {
            res.sendRedirect("delivery-documents.jsp?error=missing");
            return;
        }

        // ── Insert into delivery_documents table ─────────────────────────────
        String insertDoc = "INSERT INTO delivery_documents "
            + "(delivery_boy_id, aadhaar_path, pan_path, licence_path, rc_path, photo_path, "
            + " bank_name, account_holder_name, account_number, ifsc_code) "
            + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

        // ── Update delivery boy status to PENDING ────────────────────────────
        String updateStatus = "UPDATE delivery_boys SET status='PENDING' WHERE id=?";

        try (Connection con = DBConnection.getConnection()) {
            try (PreparedStatement ps = con.prepareStatement(insertDoc)) {
                ps.setInt   (1, deliveryBoyId);
                ps.setString(2, aadhaarPath);
                ps.setString(3, panPath);
                ps.setString(4, licencePath);
                ps.setString(5, rcPath);
                ps.setString(6, photoPath);
                ps.setString(7, bankName);
                ps.setString(8, accountHolder);
                ps.setString(9, accountNumber);
                ps.setString(10, ifscCode);
                ps.executeUpdate();
            }
            try (PreparedStatement ps = con.prepareStatement(updateStatus)) {
                ps.setInt(1, deliveryBoyId);
                ps.executeUpdate();
            }
        } catch (Exception e) {
            e.printStackTrace();
            res.sendRedirect("delivery-documents.jsp?error=failed");
            return;
        }

        // ── Notify admin by email ────────────────────────────────────────────
        EmailService.sendDeliveryBoyApplicationEmail(deliveryBoyId);
        // Notify admin/staff about new KYC submission
        try {
            com.sibs.model.DeliveryBoy _db = new com.sibs.dao.DeliveryBoyDAO().getById(deliveryBoyId);
            String dbName = (_db != null && _db.getName() != null) ? _db.getName() : "A delivery partner";
            NotificationDAO.sendKycSubmittedToAdmin(deliveryBoyId, dbName);
        } catch (Exception _ignored) {}

        // ── Clear session ────────────────────────────────────────────────────
        session.removeAttribute("pending_delivery_boy_id");

        res.sendRedirect("delivery-login.jsp?msg=submitted");
    }

    /** Saves a part to disk, returns the relative path or null if no file. */
    private String saveFile(HttpServletRequest req, String partName,
                             String uploadDir, int dbId) throws IOException, ServletException {
        Part part = req.getPart(partName);
        if (part == null || part.getSize() == 0) return null;

        String original  = getFileName(part);
        String ext       = original.contains(".") ? original.substring(original.lastIndexOf('.')) : "";
        String filename  = "db" + dbId + "_" + partName + "_" + System.currentTimeMillis() + ext;
        part.write(uploadDir + File.separator + filename);
        return "uploads/delivery-docs/" + filename;
    }

    private String getFileName(Part part) {
        String cd = part.getHeader("content-disposition");
        for (String s : cd.split(";")) {
            if (s.trim().startsWith("filename")) {
                return s.substring(s.indexOf('=') + 1).trim().replace("\"", "");
            }
        }
        return "file";
    }
}