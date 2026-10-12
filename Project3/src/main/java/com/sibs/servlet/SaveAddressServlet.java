package com.sibs.servlet;

import com.sibs.dao.AddressDAO;
import com.sibs.model.Address;
import com.sibs.model.User;
import jakarta.servlet.*;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.*;

@MultipartConfig
@WebServlet("/saveAddress")
public class SaveAddressServlet extends HttpServlet {

    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        res.setContentType("application/json");
        res.setCharacterEncoding("UTF-8");
        PrintWriter out = res.getWriter();

        HttpSession session = req.getSession(false);
        if (session == null) {
            out.print("{\"error\":\"Session expired. Please login again.\"}");
            return;
        }

        User user = (User) session.getAttribute("customer");
        if (user == null) {
            out.print("{\"error\":\"Session expired. Please login again.\"}");
            return;
        }

        String name    = req.getParameter("name");
        String phone   = req.getParameter("phone");
        String addrTxt = req.getParameter("address");

        if (name == null || name.trim().isEmpty() ||
            phone == null || phone.trim().isEmpty() ||
            addrTxt == null || addrTxt.trim().isEmpty()) {
            out.print("{\"error\":\"Name, phone and address are required.\"}");
            return;
        }

        Address a = new Address();
        a.setName(name.trim());
        a.setPhone(phone.trim());
        a.setAddress(addrTxt.trim());
        a.setLandmark(safe(req.getParameter("landmark")));
        a.setPincode(safe(req.getParameter("pincode")));
        a.setCity(safe(req.getParameter("city")));
        a.setState(safe(req.getParameter("state")));
        a.setDefault(false);

        try {
            String lat = req.getParameter("latitude");
            String lng = req.getParameter("longitude");
            if (lat != null && !lat.equals("0")) a.setLatitude(Double.parseDouble(lat));
            if (lng != null && !lng.equals("0")) a.setLongitude(Double.parseDouble(lng));
        } catch (NumberFormatException ignored) {}

        AddressDAO dao = new AddressDAO();
        int newId = dao.saveAndGetId(a, user.getId());

        if (newId > 0) {
            out.print("{\"addressId\":" + newId + "}");
        } else {
            out.print("{\"error\":\"Failed to save address. Please try again.\"}");
        }
    }

    private String safe(String s) {
        return (s != null) ? s.trim() : "";
    }
}