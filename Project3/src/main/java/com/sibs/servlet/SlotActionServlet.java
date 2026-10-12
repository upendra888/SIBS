package com.sibs.servlet;

import com.sibs.dao.DeliverySlotDAO;
import com.sibs.dao.NotificationDAO;
import com.sibs.model.DeliveryBoy;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;

@WebServlet("/slotAction")
public class SlotActionServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
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

            case "book": {
                String slotIdStr = request.getParameter("slotId");
                int slotId = 0;
                try { slotId = Integer.parseInt(slotIdStr); } catch (Exception ignored) {}
                if (slotId == 0) {
                    redirectUrl = "delivery-slot-booking.jsp?error=No+slot+selected.";
                    break;
                }
                String result = dao.bookSlot(deliveryBoyId, slotId);
                switch (result) {
                    case "ok":
                        redirectUrl = "delivery-slot-booking.jsp?success=Slot+booked+successfully!";
                        NotificationDAO.sendSlotBooked(deliveryBoyId, db.getName(), slotId);
                        break;
                    case "already_booked":
                        redirectUrl = "delivery-slot-booking.jsp?error=You+already+have+an+active+booking+for+this+slot.";
                        break;
                    case "slot_full":
                        redirectUrl = "delivery-slot-booking.jsp?error=This+slot+is+full.+Please+choose+another.";
                        break;
                    default:
                        redirectUrl = "delivery-slot-booking.jsp?error=Booking+failed.+Please+try+again.";
                        break;
                }
                break;
            }

            case "startShift": {
                // Parse bookingId — if missing/invalid, fall back to earliest BOOKED slot
                String bidStr = request.getParameter("bookingId");
                String shiftResult;
                try {
                    int bookingId = Integer.parseInt(bidStr);
                    shiftResult = dao.startShift(deliveryBoyId, bookingId);
                } catch (Exception ignored) {
                    shiftResult = dao.startShift(deliveryBoyId);
                }

                if ("ok".equals(shiftResult)) {
                    redirectUrl = "delivery-slot-booking.jsp?success=Shift+started!+You+are+now+on+duty.";
                    NotificationDAO.sendShiftStarted(deliveryBoyId, db.getName());
                } else if (shiftResult != null && shiftResult.startsWith("too_early:")) {
                    String slotTime = shiftResult.split(":", 2)[1];
                    redirectUrl = "delivery-slot-booking.jsp?error=Too+early!+Your+slot+starts+at+"
                                  + slotTime.replace(":", "%3A") + ".+Please+wait+until+then.";
                } else if ("not_found".equals(shiftResult)) {
                    redirectUrl = "delivery-slot-booking.jsp?error=No+booked+slot+found+for+today.";
                } else {
                    redirectUrl = "delivery-slot-booking.jsp?error=Could+not+start+shift.+Please+try+again.";
                }
                break;
            }

            case "endShift": {
                boolean ok = dao.endShift(deliveryBoyId);
                if (ok) NotificationDAO.sendShiftEnded(deliveryBoyId, db.getName());
                redirectUrl = ok
                    ? "delivery-slot-booking.jsp?success=Shift+ended.+Great+work+today!"
                    : "delivery-slot-booking.jsp?error=Could+not+end+shift.+No+active+shift+found.";
                break;
            }

            case "cancel": {
                String bidStr = request.getParameter("bookingId");
                boolean ok = false;
                try {
                    int bookingId = Integer.parseInt(bidStr);
                    ok = dao.cancelBookingById(bookingId, deliveryBoyId);
                } catch (Exception ignored) {
                    ok = dao.cancelBooking(deliveryBoyId);
                }
                if (ok) NotificationDAO.sendSlotCancelled(deliveryBoyId, db.getName());
                redirectUrl = ok
                    ? "delivery-slot-booking.jsp?success=Booking+cancelled.+You+can+book+another+slot."
                    : "delivery-slot-booking.jsp?error=Cannot+cancel+-+your+shift+may+already+be+active.";
                break;
            }

            default:
                redirectUrl = "delivery-slot-booking.jsp?error=Unknown+action.";
                break;
        }

        response.sendRedirect(redirectUrl);
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.sendRedirect("delivery-slot-booking.jsp");
    }
}