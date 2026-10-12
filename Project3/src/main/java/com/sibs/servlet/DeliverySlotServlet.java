package com.sibs.servlet;

import com.sibs.dao.DeliverySlotDAO;
import com.sibs.model.DeliveryBoy;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;

/**
 * Handles all delivery-slot actions:
 *   book       — delivery boy books a slot for today
 *   startShift — marks booking ACTIVE, records shift_start
 *   endShift   — marks booking COMPLETED, records shift_end + working_hours
 *   cancel     — cancels a BOOKED slot (cannot cancel an active shift)
 *
 * Registered via web.xml → /deliverySlot  (NO @WebServlet annotation)
 */
public class DeliverySlotServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        // ── Auth guard ───────────────────────────────────────────────────────
        if (session == null || session.getAttribute("deliveryBoy") == null) {
            response.sendRedirect("delivery-login.jsp");
            return;
        }

        DeliveryBoy db = (DeliveryBoy) session.getAttribute("deliveryBoy");
        int deliveryBoyId = db.getId();

        String action = request.getParameter("action");
        if (action == null) action = "";

        DeliverySlotDAO dao = new DeliverySlotDAO();
        String redirectUrl;

        switch (action) {

            // ── BOOK ─────────────────────────────────────────────────────────
            case "book": {
                String slotIdStr = request.getParameter("slotId");
                if (slotIdStr == null || slotIdStr.trim().isEmpty()) {
                    redirectUrl = "delivery-slot-booking.jsp?error=No+slot+selected.";
                    break;
                }
                int slotId;
                try {
                    slotId = Integer.parseInt(slotIdStr.trim());
                } catch (NumberFormatException e) {
                    redirectUrl = "delivery-slot-booking.jsp?error=Invalid+slot.";
                    break;
                }

                String result = dao.bookSlot(deliveryBoyId, slotId);
                switch (result) {
                    case "ok":
                        redirectUrl = "delivery-slot-booking.jsp?success=Slot+booked+successfully!+Get+ready+for+your+shift.";
                        break;
                    case "already_booked":
                        redirectUrl = "delivery-slot-booking.jsp?error=You+already+have+an+active+or+booked+slot.+Complete+your+current+shift+first.";
                        break;
                    case "slot_full":
                        redirectUrl = "delivery-slot-booking.jsp?error=Sorry,+this+slot+is+full.+Please+choose+another.";
                        break;
                    default:
                        redirectUrl = "delivery-slot-booking.jsp?error=Something+went+wrong.+Please+try+again.";
                        break;
                }
                break;
            }

            // ── START SHIFT ──────────────────────────────────────────────────
            case "startShift": {
                String bidStr = request.getParameter("bookingId");
                String shiftResult;
                try {
                    int bookingId = Integer.parseInt(bidStr);
                    shiftResult = dao.startShift(deliveryBoyId, bookingId);
                } catch (Exception ignored) {
                    shiftResult = dao.startShift(deliveryBoyId); // fallback
                }
                if ("ok".equals(shiftResult)) {
                    redirectUrl = "delivery-slot-booking.jsp?success=Shift+started!+You+are+now+on+duty.";
                } else if (shiftResult != null && shiftResult.startsWith("too_early:")) {
                    String slotTime = shiftResult.split(":", 2)[1];
                    redirectUrl = "delivery-slot-booking.jsp?error=Too+early!+Your+slot+starts+at+" + slotTime.replace(":", "%3A") + ".+Please+wait+until+then.";
                } else if ("not_found".equals(shiftResult)) {
                    redirectUrl = "delivery-slot-booking.jsp?error=No+booked+slot+found+for+today.";
                } else {
                    redirectUrl = "delivery-slot-booking.jsp?error=Could+not+start+shift.+Please+try+again.";
                }
                break;
            }

            // ── END SHIFT ────────────────────────────────────────────────────
            case "endShift": {
                boolean ok = dao.endShift(deliveryBoyId);
                redirectUrl = ok
                    ? "delivery-slot-booking.jsp?success=Shift+ended.+Great+work+today!"
                    : "delivery-slot-booking.jsp?error=Could+not+end+shift.+No+active+shift+found.";
                break;
            }

            // ── CANCEL BOOKING ───────────────────────────────────────────────
            case "cancel": {
                boolean ok = dao.cancelBooking(deliveryBoyId);
                redirectUrl = ok
                    ? "delivery-slot-booking.jsp?success=Booking+cancelled.+You+can+book+another+slot."
                    : "delivery-slot-booking.jsp?error=Cannot+cancel+-+your+shift+may+already+be+active.";
                break;
            }

            // ── UNKNOWN ACTION ───────────────────────────────────────────────
            default:
                redirectUrl = "delivery-slot-booking.jsp?error=Unknown+action.";
                break;
        }

        response.sendRedirect(redirectUrl);
    }

    // Redirect GET requests back to the slot page
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.sendRedirect("delivery-slot-booking.jsp");
    }
}