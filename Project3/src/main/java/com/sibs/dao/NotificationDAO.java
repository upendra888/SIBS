package com.sibs.dao;

import com.sibs.model.Notification;
import com.sibs.util.DBConnection;
import com.sibs.util.EmailService;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * NotificationDAO
 *
 * All public "send*" helpers are the preferred way to insert notifications.
 * Each helper corresponds to a real business event and sets the correct
 * recipient, category, title, message, and deep-link automatically.
 *
 * Low-level access (countUnread, getFor*, markRead) are called from
 * servlets and JSPs to drive bell badges and notification panels.
 *
 * Recipient columns are mutually exclusive:
 *   customer    → user_id
 *   staff/admin → staff_id
 *   delivery    → delivery_boy_id
 */
public class NotificationDAO {

    // ─────────────────────────────────────────────────────────────────
    // 1.  Factory / "send" helpers
    //     Call these from the relevant servlet after a state change.
    // ─────────────────────────────────────────────────────────────────

    /** Customer: order placed */
    public static void sendOrderPlaced(int customerId, int orderId, String productSummary) {
        Notification n = forCustomer(customerId);
        n.setCategory("ORDER");
        n.setPriority("MEDIUM");
        n.setTitle("Order Confirmed");
        n.setMessage("Your order for " + productSummary + " has been placed! We'll start packing it soon.");
        n.setLinkUrl("/my-orders.jsp");
        n.setOrderId(orderId);
        insert(n);
    }

    /** Customer: order status changed (Packed, Dispatched, Delivered, Cancelled …) */
    public static void sendOrderStatusChanged(int customerId, int orderId,
                                              String productName, String newStatus) {
        Notification n = forCustomer(customerId);
        n.setCategory("ORDER");
        n.setPriority("Cancelled".equalsIgnoreCase(newStatus) ? "HIGH" : "MEDIUM");
        n.setTitle("Order " + newStatus);
        n.setMessage("Your order for \"" + productName + "\" is now " + newStatus + ".");
        n.setLinkUrl("/my-orders.jsp");
        n.setOrderId(orderId);
        insert(n);
    }

    /** Customer: support complaint resolved by staff */
    public static void sendComplaintResolved(int customerId, int complaintId, String verdict) {
        Notification n = forCustomer(customerId);
        n.setCategory("COMPLAINT");
        n.setPriority("HIGH");
        n.setTitle("Support Ticket " + ("GENUINE".equalsIgnoreCase(verdict) ? "Resolved" : "Closed"));
        n.setMessage("GENUINE".equalsIgnoreCase(verdict)
            ? "Good news! Your complaint has been reviewed and a remedy is being arranged."
            : "Your complaint has been reviewed and marked as closed. Contact support if you need help.");
        n.setLinkUrl("/customer-support.jsp");
        n.setComplaintId(complaintId);
        insert(n);
    }

    /** Customer: return request status updated (Approved, Rejected, Refunded …) */
    public static void sendReturnStatusChanged(int customerId, int returnId,
                                               String productName, String status) {
        sendReturnStatusChanged(customerId, returnId, productName, status, null, null);
    }

    public static void sendReturnStatusChanged(int customerId, int returnId,
                                               String productName, String status,
                                               String email, String customerName) {
        Notification n = forCustomer(customerId);
        n.setCategory("RETURN");
        n.setPriority("Rejected".equalsIgnoreCase(status) ? "HIGH" : "MEDIUM");
        n.setTitle("Return " + status);
        n.setMessage("Your return for \"" + productName + "\" has been " + status.toLowerCase() + ".");
        n.setLinkUrl("/myreturns.jsp");
        n.setReturnId(returnId);
        insert(n);

        if (email != null && !email.isEmpty()) {
            new Thread(() -> EmailService.sendReturnStatusEmail(email, customerName != null ? customerName : "Customer", productName, status)).start();
        }
    }

    /** Staff/admin: new support complaint raised by customer */
    public static void sendNewComplaintToStaff(int complaintId, String customerName) {
        Notification n = forAllStaff();
        n.setCategory("COMPLAINT");
        n.setPriority("HIGH");
        n.setTitle("New Support Ticket");
        n.setMessage(customerName + " raised a new support complaint. Assign it for review.");
        n.setLinkUrl("/support");
        n.setComplaintId(complaintId);
        insert(n);
    }

    /** Staff/admin: new return request submitted */
    public static void sendNewReturnToStaff(int returnId, String customerName, String productName) {
        Notification n = forAllStaff();
        n.setCategory("RETURN");
        n.setPriority("MEDIUM");
        n.setTitle("New Return Request");
        n.setMessage(customerName + " submitted a return for \"" + productName + "\". Review and approve.");
        n.setLinkUrl("/AdminReturnServlet?action=list");
        n.setReturnId(returnId);
        insert(n);
    }

    /** Staff/admin: leave application submitted */
    public static void sendLeaveApplicationToAdmin(int leaveId, String staffName) {
        Notification n = forAllStaff();
        n.setCategory("LEAVE");
        n.setPriority("MEDIUM");
        n.setTitle("Leave Request");
        n.setMessage(staffName + " submitted a leave application awaiting your approval.");
        n.setLinkUrl("/admin-leave.jsp");
        insert(n);
    }

    /** Staff: leave approved or rejected — notify the applicant */
    public static void sendLeaveDecisionToStaff(int staffId, String decision, String remarks) {
        sendLeaveDecisionToStaff(staffId, decision, remarks, null, null);
    }

    public static void sendLeaveDecisionToStaff(int staffId, String decision, String remarks,
                                                 String email, String name) {
        Notification n = forStaff(staffId);
        n.setCategory("LEAVE");
        n.setPriority("Rejected".equalsIgnoreCase(decision) ? "HIGH" : "MEDIUM");
        n.setTitle("Leave " + decision);
        n.setMessage("Your leave request has been " + decision.toLowerCase()
            + (remarks != null && !remarks.isEmpty() ? ". Note: " + remarks : "."));
        n.setLinkUrl("/staff-leave.jsp");
        insert(n);

        if (email != null && !email.isEmpty()) {
            new Thread(() -> EmailService.sendLeaveDecisionEmail(email, name != null ? name : "Staff", decision, remarks)).start();
        }
    }

    /** Delivery boy: new assignment */
    public static void sendDeliveryAssigned(int deliveryBoyId, int orderId, String customerName) {
        Notification n = forDeliveryBoy(deliveryBoyId);
        n.setCategory("DELIVERY");
        n.setPriority("HIGH");
        n.setTitle("New Delivery Assigned");
        n.setMessage("Order #" + orderId + " for " + customerName + " has been assigned to you.");
        n.setLinkUrl("/delivery-dashboard.jsp");
        n.setOrderId(orderId);
        insert(n);
    }

    /** Delivery boy: delivery approval status changed */
    public static void sendApprovalDecision(int deliveryBoyId, String decision) {
        Notification n = forDeliveryBoy(deliveryBoyId);
        n.setCategory("DELIVERY");
        n.setPriority("HIGH");
        n.setTitle("Account " + decision);
        n.setMessage("Your delivery partner account has been " + decision.toLowerCase()
            + ". " + ("APPROVED".equalsIgnoreCase(decision)
                ? "You can now log in and accept deliveries."
                : "Contact support if you think this is an error."));
        n.setLinkUrl("/delivery-login.jsp");
        insert(n);
    }

    /** Admin: delivery boy successfully remitted COD cash */
    public static void sendCodRemitted(int deliveryBoyId, String name, double amount) {
        Notification n = forAllStaff();
        n.setCategory("COD");
        n.setPriority("MEDIUM");
        n.setTitle("COD Remittance Received");
        n.setMessage(name + " remitted ₹" + (int) amount + " COD cash. Check the ledger.");
        n.setLinkUrl("/admin-cod-ledger.jsp");
        insert(n);
        new Thread(() -> EmailService.sendCodAlertEmail(name, amount, false)).start();
    }

    /** Admin: delivery boy forced offline — cannot cover COD remittance */
    public static void sendCodForceOffline(int deliveryBoyId, String name, double amount) {
        Notification n = forAllStaff();
        n.setCategory("COD");
        n.setPriority("HIGH");
        n.setTitle("COD Alert: Delivery Boy Offline");
        n.setMessage(name + " was forced offline — insufficient balance to cover ₹" + (int) amount + " pending COD.");
        n.setLinkUrl("/admin-cod-ledger.jsp");
        insert(n);
        new Thread(() -> EmailService.sendCodAlertEmail(name, amount, true)).start();
    }

    /** Admin: delivery boy booked a slot */
    public static void sendSlotBooked(int deliveryBoyId, String name, int slotId) {
        Notification n = forAllStaff();
        n.setCategory("DELIVERY");
        n.setPriority("LOW");
        n.setTitle("Slot Booked");
        n.setMessage(name + " booked a delivery slot and is ready for shift.");
        n.setLinkUrl("/admin-delivery-slots.jsp");
        insert(n);
    }

    /** Admin: delivery boy started their shift */
    public static void sendShiftStarted(int deliveryBoyId, String name) {
        Notification n = forAllStaff();
        n.setCategory("DELIVERY");
        n.setPriority("LOW");
        n.setTitle("Shift Started");
        n.setMessage(name + " has started their delivery shift and is now on duty.");
        n.setLinkUrl("/admin-delivery-slots.jsp");
        insert(n);
    }

    /** Admin: delivery boy ended their shift */
    public static void sendShiftEnded(int deliveryBoyId, String name) {
        Notification n = forAllStaff();
        n.setCategory("DELIVERY");
        n.setPriority("LOW");
        n.setTitle("Shift Ended");
        n.setMessage(name + " has completed their delivery shift.");
        n.setLinkUrl("/admin-delivery-slots.jsp");
        insert(n);
    }

    /** Admin: delivery boy cancelled their slot booking */
    public static void sendSlotCancelled(int deliveryBoyId, String name) {
        Notification n = forAllStaff();
        n.setCategory("DELIVERY");
        n.setPriority("LOW");
        n.setTitle("Slot Cancelled");
        n.setMessage(name + " cancelled their slot booking.");
        n.setLinkUrl("/admin-delivery-slots.jsp");
        insert(n);
    }

    /** Staff: late check-in alert to the staff member themselves */
    public static void sendLateAttendance(int staffId, String name, String time) {
        sendLateAttendance(staffId, name, time, null);
    }

    public static void sendLateAttendance(int staffId, String name, String time, String email) {
        Notification n = forStaff(staffId);
        n.setCategory("ATTENDANCE");
        n.setPriority("HIGH");
        n.setTitle("Late Attendance Marked");
        n.setMessage("You checked in late at " + time + ". Please ensure punctuality. Your status has been marked as LATE.");
        n.setLinkUrl("/staff-attendance.jsp");
        insert(n);

        Notification admin = forAllStaff();
        admin.setCategory("ATTENDANCE");
        admin.setPriority("HIGH");
        admin.setTitle("Late Arrival: " + name);
        admin.setMessage(name + " checked in late at " + time + ". Status marked as LATE.");
        admin.setLinkUrl("/admin-attendance.jsp");
        insert(admin);

        if (email != null && !email.isEmpty()) {
            new Thread(() -> EmailService.sendLateAttendanceEmail(email, name, time)).start();
        }
    }

    /** Staff: check-in successful */
    public static void sendCheckIn(int staffId, String name, String time) {
        Notification n = forStaff(staffId);
        n.setCategory("ATTENDANCE");
        n.setPriority("LOW");
        n.setTitle("Check-In Successful");
        n.setMessage("Hi " + name + "! Your attendance has been marked. Check-In Time: " + time + ".");
        n.setLinkUrl("/staff-attendance.jsp");
        insert(n);
    }

    /** Staff: check-out successful */
    public static void sendCheckOut(int staffId, String name, String time) {
        Notification n = forStaff(staffId);
        n.setCategory("ATTENDANCE");
        n.setPriority("LOW");
        n.setTitle("Check-Out Successful");
        n.setMessage("Goodbye " + name + "! Check-Out Time: " + time + ". Have a great day!");
        n.setLinkUrl("/staff-attendance.jsp");
        insert(n);
    }

    /** Staff: break started */
    public static void sendBreakIn(int staffId, String name, String time) {
        Notification n = forStaff(staffId);
        n.setCategory("ATTENDANCE");
        n.setPriority("LOW");
        n.setTitle("Break Started");
        n.setMessage("Enjoy your break, " + name + "! Break started at " + time + ".");
        n.setLinkUrl("/staff-attendance.jsp");
        insert(n);
    }

    /** Staff: break ended */
    public static void sendBreakOut(int staffId, String name, String time) {
        Notification n = forStaff(staffId);
        n.setCategory("ATTENDANCE");
        n.setPriority("LOW");
        n.setTitle("Break Ended");
        n.setMessage("Welcome back, " + name + "! Break ended at " + time + ".");
        n.setLinkUrl("/staff-attendance.jsp");
        insert(n);
    }
    /** Admin: delivery boy submitted KYC documents — needs approval review */
    public static void sendKycSubmittedToAdmin(int deliveryBoyId, String deliveryBoyName) {
        Notification n = forAllStaff();
        n.setCategory("DELIVERY");
        n.setPriority("HIGH");
        n.setTitle("KYC Documents Submitted");
        n.setMessage(deliveryBoyName + " submitted KYC documents and is awaiting account approval.");
        n.setLinkUrl("/admin-delivery-approvals.jsp");
        insert(n);
    }

    /** Customer: UPI/Card payment successful */
    public static void sendPaymentSuccess(int customerId, int orderId, String txnId, String method) {
        Notification n = forCustomer(customerId);
        n.setCategory("PAYMENT");
        n.setPriority("HIGH");
        n.setTitle("Payment Successful");
        n.setMessage(method + " payment confirmed for Order #" + orderId
            + (txnId != null ? ". Transaction ID: " + txnId : "") + ".");
        n.setLinkUrl("/my-orders.jsp");
        n.setOrderId(orderId);
        insert(n);
    }

    /** Customer: payment failed */
    public static void sendPaymentFailed(int customerId, int orderId, String reason) {
        Notification n = forCustomer(customerId);
        n.setCategory("PAYMENT");
        n.setPriority("HIGH");
        n.setTitle("Payment Failed");
        n.setMessage("Your payment for Order #" + orderId + " could not be processed"
            + (reason != null ? ": " + reason : ".") + " Please try again.");
        n.setLinkUrl("/my-orders.jsp");
        n.setOrderId(orderId);
        insert(n);
    }

    /** Delivery boy: KYC approved — account now active */
    public static void sendKycApproved(int deliveryBoyId) {
        Notification n = forDeliveryBoy(deliveryBoyId);
        n.setCategory("DELIVERY");
        n.setPriority("HIGH");
        n.setTitle("KYC Approved");
        n.setMessage("Congratulations! Your KYC verification has been approved. Your delivery account is now active.");
        n.setLinkUrl("/delivery-dashboard.jsp");
        insert(n);
    }

    /** Delivery boy: KYC rejected — re-upload required */
    public static void sendKycRejected(int deliveryBoyId, String reason) {
        Notification n = forDeliveryBoy(deliveryBoyId);
        n.setCategory("DELIVERY");
        n.setPriority("HIGH");
        n.setTitle("KYC Rejected — Re-upload Required");
        n.setMessage("Your KYC documents were rejected"
            + (reason != null && !reason.isEmpty() ? ": " + reason : ".")
            + " Please re-upload valid documents.");
        n.setLinkUrl("/delivery-kyc.jsp");
        insert(n);
    }

    // ── Delivery Boy: Order lifecycle ─────────────────────────────────

    /** Delivery boy: pickup confirmed — item collected from warehouse */
    public static void sendPickupConfirmed(int deliveryBoyId, int orderId, String productName) {
        Notification n = forDeliveryBoy(deliveryBoyId);
        n.setCategory("DELIVERY");
        n.setPriority("MEDIUM");
        n.setTitle("Pickup Confirmed");
        n.setMessage("You have picked up Order #" + orderId + " (\"" + productName + "\"). Head to the delivery address.");
        n.setLinkUrl("/delivery-dashboard.jsp");
        n.setOrderId(orderId);
        insert(n);
    }

    /** Delivery boy: delivery marked as successful */
    public static void sendDeliverySuccessful(int deliveryBoyId, int orderId, String productName) {
        Notification n = forDeliveryBoy(deliveryBoyId);
        n.setCategory("DELIVERY");
        n.setPriority("MEDIUM");
        n.setTitle("Delivery Successful");
        n.setMessage("Great job! Order #" + orderId + " (\"" + productName + "\") has been delivered successfully.");
        n.setLinkUrl("/delivery-dashboard.jsp");
        n.setOrderId(orderId);
        insert(n);
    }

    /** Delivery boy: their delivery attempt failed (notifies the delivery boy) */
    public static void sendDeliveryFailedToDeliveryBoy(int deliveryBoyId, int orderId, String productName, String reason) {
        Notification n = forDeliveryBoy(deliveryBoyId);
        n.setCategory("DELIVERY");
        n.setPriority("HIGH");
        n.setTitle("Delivery Failed — Action Required");
        n.setMessage("Delivery for Order #" + orderId + " (\"" + productName + "\") was marked as failed"
            + (reason != null && !reason.isEmpty() ? ": " + reason : ".")
            + " Please contact admin or retry.");
        n.setLinkUrl("/delivery-dashboard.jsp");
        n.setOrderId(orderId);
        insert(n);
    }

    /** Delivery boy: assigned order was cancelled by customer or admin */
    public static void sendAssignedOrderCancelled(int deliveryBoyId, int orderId, String productName) {
        Notification n = forDeliveryBoy(deliveryBoyId);
        n.setCategory("DELIVERY");
        n.setPriority("HIGH");
        n.setTitle("Assigned Order Cancelled");
        n.setMessage("Order #" + orderId + " (\"" + productName + "\") assigned to you has been cancelled. No further action needed.");
        n.setLinkUrl("/delivery-dashboard.jsp");
        n.setOrderId(orderId);
        insert(n);
    }

    /** Staff (broadcast): delivery boy cancelled ride — order needs reassignment */
    public static void sendRideCancelledByDeliveryBoy(int groupId, int orderId) {
        Notification n = forAllStaff();
        n.setCategory("DELIVERY");
        n.setPriority("HIGH");
        n.setTitle("Ride Cancelled — Reassign Needed");
        n.setMessage("Delivery boy cancelled Order #" + groupId + " before pickup. Please reassign a delivery boy.");
        n.setLinkUrl("/staff-orders.jsp");
        n.setOrderId(orderId);
        insert(n);
    }

    /** Delivery boy: re-delivery scheduled for a previously failed/returned order */
    public static void sendRedeliveryScheduled(int deliveryBoyId, int orderId, String customerName) {
        Notification n = forDeliveryBoy(deliveryBoyId);
        n.setCategory("DELIVERY");
        n.setPriority("HIGH");
        n.setTitle("Re-delivery Scheduled");
        n.setMessage("Order #" + orderId + " for " + customerName + " has been scheduled for re-delivery. Please check your dashboard.");
        n.setLinkUrl("/delivery-dashboard.jsp");
        n.setOrderId(orderId);
        insert(n);
    }

    // ── Delivery Boy: COD & Earnings ──────────────────────────────────

    /** Delivery boy: COD amount collected reminder after delivering a COD order */
    public static void sendCodCollected(int deliveryBoyId, int orderId, double amount) {
        Notification n = forDeliveryBoy(deliveryBoyId);
        n.setCategory("COD");
        n.setPriority("HIGH");
        n.setTitle("COD Amount Collected");
        n.setMessage("You collected ₹" + (int) amount + " COD cash for Order #" + orderId + ". Remember to remit it to admin.");
        n.setLinkUrl("/delivery-cash-ledger.jsp");
        n.setOrderId(orderId);
        insert(n);
    }

    /** Delivery boy: COD remittance deadline approaching */
    public static void sendCodRemittanceDue(int deliveryBoyId, double pendingAmount) {
        Notification n = forDeliveryBoy(deliveryBoyId);
        n.setCategory("COD");
        n.setPriority("HIGH");
        n.setTitle("COD Remittance Due");
        n.setMessage("You have ₹" + (int) pendingAmount + " pending COD cash to remit. Please submit it to admin before your shift ends.");
        n.setLinkUrl("/delivery-cash-ledger.jsp");
        insert(n);
    }

    /** Delivery boy: earnings credited for the day/week */
    public static void sendEarningsCredited(int deliveryBoyId, double amount, String period) {
        Notification n = forDeliveryBoy(deliveryBoyId);
        n.setCategory("EARNING");
        n.setPriority("MEDIUM");
        n.setTitle("Earnings Credited");
        n.setMessage("Your " + period + " earnings of ₹" + (int) amount + " have been credited to your wallet.");
        n.setLinkUrl("/delivery-earnings.jsp");
        insert(n);
    }

    /** Delivery boy: wallet balance is below minimum threshold */
    public static void sendWalletBalanceLow(int deliveryBoyId, double balance, double minRequired) {
        Notification n = forDeliveryBoy(deliveryBoyId);
        n.setCategory("EARNING");
        n.setPriority("HIGH");
        n.setTitle("Wallet Balance Low");
        n.setMessage("Your wallet balance (₹" + (int) balance + ") is below the required minimum of ₹" + (int) minRequired + ". Please recharge to continue accepting COD orders.");
        n.setLinkUrl("/delivery-wallet.jsp");
        insert(n);
    }

    // ── Delivery Boy: Shift Reminders ─────────────────────────────────

    /** Delivery boy: shift starting soon reminder */
    public static void sendShiftReminder(int deliveryBoyId, String slotTime) {
        Notification n = forDeliveryBoy(deliveryBoyId);
        n.setCategory("SHIFT");
        n.setPriority("MEDIUM");
        n.setTitle("Shift Starting Soon");
        n.setMessage("Your delivery shift starts at " + slotTime + ". Please be ready and go online before the slot begins.");
        n.setLinkUrl("/delivery-slot-booking.jsp");
        insert(n);
    }

    /** Delivery boy: no orders assigned in their booked slot */
    public static void sendNoOrdersInSlot(int deliveryBoyId, String slotTime) {
        Notification n = forDeliveryBoy(deliveryBoyId);
        n.setCategory("SHIFT");
        n.setPriority("LOW");
        n.setTitle("No Orders in Your Slot");
        n.setMessage("No orders have been assigned for your slot at " + slotTime + ". Stay online — orders may be assigned shortly.");
        n.setLinkUrl("/delivery-dashboard.jsp");
        insert(n);
    }

    // ── Delivery Boy: Ratings ─────────────────────────────────────────

    /** Delivery boy: received a new rating from a customer */
    public static void sendNewRatingReceived(int deliveryBoyId, int orderId, int stars, String customerName) {
        Notification n = forDeliveryBoy(deliveryBoyId);
        n.setCategory("RATING");
        n.setPriority("LOW");
        n.setTitle("New Rating Received");
        n.setMessage(customerName + " rated your delivery for Order #" + orderId + " — " + stars + " star" + (stars != 1 ? "s" : "") + ". Keep it up!");
        n.setLinkUrl("/delivery-ratings.jsp");
        n.setOrderId(orderId);
        insert(n);
    }

    /** Delivery boy: average rating dropped below acceptable threshold */
    /** Customer: thank-you notification after they submit a delivery rating */
    public static void sendRatingThankYou(int customerId, int orderId, int stars) {
        Notification n = forCustomer(customerId);
        n.setCategory("RATING");
        n.setPriority("LOW");
        n.setTitle("Thanks for Your Rating!");
        n.setMessage("You gave " + stars + " star" + (stars != 1 ? "s" : "") +
                " for Order #" + orderId + ". Your feedback helps us improve our service!");
        n.setLinkUrl("/my-orders.jsp");
        n.setOrderId(orderId);
        insert(n);
    }

    public static void sendRatingDropAlert(int deliveryBoyId, double avgRating) {
        Notification n = forDeliveryBoy(deliveryBoyId);
        n.setCategory("RATING");
        n.setPriority("HIGH");
        n.setTitle("Rating Dropped — Attention Needed");
        n.setMessage("Your average rating has dropped to " + String.format("%.1f", avgRating) + " ★. Please ensure timely and polite deliveries to improve your score.");
        n.setLinkUrl("/delivery-ratings.jsp");
        insert(n);
    }

    /** Customer + admin: delivery started (out for delivery) */
    public static void sendDeliveryStarted(int customerId, int orderId, String productName) {
        Notification n = forCustomer(customerId);
        n.setCategory("DELIVERY");
        n.setPriority("MEDIUM");
        n.setTitle("Out for Delivery");
        n.setMessage("Your order for \"" + productName + "\" is out for delivery. Expect it soon!");
        n.setLinkUrl("/my-orders.jsp");
        n.setOrderId(orderId);
        insert(n);
    }

    /** Customer: delivery failed */
    public static void sendDeliveryFailed(int customerId, int orderId, String productName, String reason) {
        Notification n = forCustomer(customerId);
        n.setCategory("DELIVERY");
        n.setPriority("HIGH");
        n.setTitle("Delivery Failed");
        n.setMessage("Delivery attempt for \"" + productName + "\" was unsuccessful"
            + (reason != null && !reason.isEmpty() ? ": " + reason : ".")
            + " Our team will retry shortly.");
        n.setLinkUrl("/my-orders.jsp");
        n.setOrderId(orderId);
        insert(n);
    }

    // ── Staff: new COD order placed ───────────────────────────────────

    /** Staff/admin: new COD order placed — needs confirmation & assignment */
    public static void sendNewCODOrderToStaff(int orderId, String customerName) {
        Notification n = forAllStaff();
        n.setCategory("ORDER");
        n.setPriority("HIGH");
        n.setTitle("New COD Order #" + orderId);
        n.setMessage(customerName + " placed a COD order. Confirm and assign a delivery boy.");
        n.setLinkUrl("/staff-orders.jsp");
        n.setOrderId(orderId);
        insert(n);
    }

    /** Staff/admin: customer cancelled an order */
    public static void sendOrderCancelledToStaff(int orderId, int groupId, String customerName) {
        Notification n = forAllStaff();
        n.setCategory("ORDER");
        n.setPriority("HIGH");
        n.setTitle("Order Cancelled by Customer");
        n.setMessage(customerName + " cancelled Order #" + groupId + ". Review and update inventory if needed.");
        n.setLinkUrl("/staff-orders.jsp");
        n.setOrderId(orderId);
        insert(n);
    }

    /** Staff/admin: product stock dropped below threshold */
    public static void sendLowStockAlert(String productName, int remaining) {
        Notification n = forAllStaff();
        n.setCategory("SYSTEM");
        n.setPriority("HIGH");
        n.setTitle("Low Stock: " + productName);
        n.setMessage("\"" + productName + "\" has only " + remaining + " unit" + (remaining == 1 ? "" : "s") + " remaining. Restock soon.");
        n.setLinkUrl("/products.jsp");
        insert(n);
    }

    // ── Products ──────────────────────────────────────────────────────

    /** Staff/admin: product added to catalog */
    public static void sendProductAdded(String productName) {
        Notification n = forAllStaff();
        n.setCategory("SYSTEM");
        n.setPriority("LOW");
        n.setTitle("New Product Added");
        n.setMessage("\"" + productName + "\" has been added to the product catalog.");
        n.setLinkUrl("/products.jsp");
        insert(n);
    }

    /** Staff/admin: product updated */
    public static void sendProductUpdated(String productName) {
        Notification n = forAllStaff();
        n.setCategory("SYSTEM");
        n.setPriority("LOW");
        n.setTitle("Product Updated");
        n.setMessage("\"" + productName + "\" details have been updated in the catalog.");
        n.setLinkUrl("/products.jsp");
        insert(n);
    }

    /** Staff/admin: product deleted */
    public static void sendProductDeleted(String productName) {
        Notification n = forAllStaff();
        n.setCategory("SYSTEM");
        n.setPriority("MEDIUM");
        n.setTitle("Product Removed");
        n.setMessage("\"" + productName + "\" has been removed from the catalog.");
        n.setLinkUrl("/products.jsp");
        insert(n);
    }

    // ── Staff account ─────────────────────────────────────────────────

    /** New staff member: welcome notification on their own bell */
    public static void sendStaffWelcome(int staffId, String name) {
        Notification n = forStaff(staffId);
        n.setCategory("SYSTEM");
        n.setPriority("HIGH");
        n.setTitle("Welcome to SIBS, " + name + "!");
        n.setMessage("Your staff account has been created. Complete your profile and start your first shift.");
        n.setLinkUrl("/staff-dashboard.jsp");
        insert(n);
    }

    /** Admin broadcast: new staff member joined */
    public static void sendNewStaffToAdmin(String staffName, String role) {
        Notification n = forAllStaff();
        n.setCategory("SYSTEM");
        n.setPriority("LOW");
        n.setTitle("New Staff Member Added");
        n.setMessage(staffName + " (" + role + ") has joined the team.");
        n.setLinkUrl("/add-staff.jsp");
        insert(n);
    }

    /** Staff: leave request cancelled by themselves */
    public static void sendLeaveCancelledBySelf(int staffId, String name) {
        Notification n = forStaff(staffId);
        n.setCategory("LEAVE");
        n.setPriority("LOW");
        n.setTitle("Leave Request Cancelled");
        n.setMessage("Your leave request has been cancelled successfully.");
        n.setLinkUrl("/staff-leave.jsp");
        insert(n);
    }

    // ── Delivery boy registration ─────────────────────────────────────

    /** Delivery boy: registration received, KYC pending */
    public static void sendRegistrationReceived(int deliveryBoyId, String name) {
        Notification n = forDeliveryBoy(deliveryBoyId);
        n.setCategory("DELIVERY");
        n.setPriority("HIGH");
        n.setTitle("Registration Received");
        n.setMessage("Hi " + name + "! Your registration is received. Please upload your KYC documents to complete account setup.");
        n.setLinkUrl("/delivery-documents.jsp");
        insert(n);
    }

    // ─────────────────────────────────────────────────────────────────
    //  Wallet Withdraw Notifications
    // ─────────────────────────────────────────────────────────────────

    /** Notify staff that a delivery boy requested a withdrawal */
    public static void sendWithdrawRequestToStaff(int deliveryBoyId, String deliveryBoyName, double amount) {
        Notification n = forAllStaff(); // broadcast to all staff
        n.setCategory("WALLET");
        n.setPriority("HIGH");
        n.setTitle("Withdraw Request – ₹" + String.format("%.0f", amount));
        n.setMessage(deliveryBoyName + " requested a wallet withdrawal of ₹" + String.format("%.2f", amount) + ". Please review and approve/reject.");
        n.setLinkUrl("/staff-withdrawals.jsp");
        n.setDeliveryBoyId(deliveryBoyId);
        insert(n);
    }

    /** Notify delivery boy that staff approved the withdrawal */
    public static void sendWithdrawApproved(int deliveryBoyId, double amount, String staffNote) {
        Notification n = forDeliveryBoy(deliveryBoyId);
        n.setCategory("WALLET");
        n.setPriority("HIGH");
        n.setTitle("Withdrawal Approved ✅");
        n.setMessage("Your withdrawal request of ₹" + String.format("%.2f", amount) + " has been approved and debited from your wallet."
            + (staffNote != null && !staffNote.isBlank() ? " Note: " + staffNote : ""));
        n.setLinkUrl("/delivery-wallet.jsp");
        insert(n);
    }

    /** Notify delivery boy that staff rejected the withdrawal */
    public static void sendWithdrawRejected(int deliveryBoyId, double amount, String staffNote) {
        Notification n = forDeliveryBoy(deliveryBoyId);
        n.setCategory("WALLET");
        n.setPriority("NORMAL");
        n.setTitle("Withdrawal Rejected ❌");
        n.setMessage("Your withdrawal request of ₹" + String.format("%.2f", amount) + " has been rejected."
            + (staffNote != null && !staffNote.isBlank() ? " Reason: " + staffNote : ""));
        n.setLinkUrl("/delivery-wallet.jsp");
        insert(n);
    }

    // ─────────────────────────────────────────────────────────────────
    // 2.  Read — for bell badge counts
    // ─────────────────────────────────────────────────────────────────

    public int countUnreadForCustomer(int userId) {
        return countUnread("user_id", userId);
    }

    public int countUnreadForStaff(int staffId) {
        // staff_id = 0 means "broadcast" — a staff member sees their own + broadcasts
        return countUnreadBroadcast("staff_id", staffId);
    }

    public int countUnreadForDeliveryBoy(int deliveryBoyId) {
        return countUnread("delivery_boy_id", deliveryBoyId);
    }

    // ─────────────────────────────────────────────────────────────────
    // 3.  Read — for notification panels
    // ─────────────────────────────────────────────────────────────────

    /** Latest N unread (or all) notifications for a customer. */
    public List<Notification> getForCustomer(int userId, int limit) {
        return fetch("WHERE user_id = ?", userId, limit);
    }

    /** Latest N notifications for a staff member (own + broadcasts). */
    public List<Notification> getForStaff(int staffId, int limit) {
        return fetchBroadcast("staff_id", staffId, limit);
    }

    /** Latest N notifications for a delivery boy. */
    public List<Notification> getForDeliveryBoy(int deliveryBoyId, int limit) {
        return fetch("WHERE delivery_boy_id = ?", deliveryBoyId, limit);
    }

    // ─────────────────────────────────────────────────────────────────
    // 4.  Mark as read
    // ─────────────────────────────────────────────────────────────────

    /** Mark a single notification as read. */
    public boolean markRead(int notificationId) {
        String sql = "UPDATE notifications SET is_read=1, read_at=NOW() WHERE id=? AND is_read=0";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, notificationId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    /** Mark ALL unread notifications for a customer as read. */
    public void markAllReadForCustomer(int userId) {
        markAllRead("user_id", userId);
    }

    /** Mark ALL unread notifications for a staff member (own + broadcasts) as read. */
    public void markAllReadForStaff(int staffId) {
        String sql = "UPDATE notifications SET is_read=1, read_at=NOW() " +
                     "WHERE is_read=0 AND (staff_id=? OR staff_id=0)";
        runUpdate(sql, staffId);
    }

    /** Mark ALL unread notifications for a delivery boy as read. */
    public void markAllReadForDeliveryBoy(int deliveryBoyId) {
        markAllRead("delivery_boy_id", deliveryBoyId);
    }

    // ─────────────────────────────────────────────────────────────────
    // 5.  Delete
    // ─────────────────────────────────────────────────────────────────

    /** Delete a single notification by id. */
    public boolean deleteOne(int notificationId) {
        String sql = "DELETE FROM notifications WHERE id=?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, notificationId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    /** Delete all notifications for a customer. */
    public void deleteAllForCustomer(int userId) {
        deleteAll("user_id", userId);
    }

    /** Delete all notifications for a staff member (own + broadcasts). */
    public void deleteAllForStaff(int staffId) {
        String sql = "DELETE FROM notifications WHERE staff_id=? OR staff_id=0";
        runUpdate(sql, staffId);
    }

    /** Delete all notifications for a delivery boy. */
    public void deleteAllForDeliveryBoy(int deliveryBoyId) {
        deleteAll("delivery_boy_id", deliveryBoyId);
    }

    private void deleteAll(String col, int id) {
        String sql = "DELETE FROM notifications WHERE " + col + "=?";
        runUpdate(sql, id);
    }

    // ─────────────────────────────────────────────────────────────────
    // Private helpers
    // ─────────────────────────────────────────────────────────────────

    private static Notification forCustomer(int userId) {
        Notification n = new Notification();
        n.setUserId(userId);
        return n;
    }

    /** staff_id = 0 = "broadcast to ALL staff" — every staff member sees it. */
    private static Notification forAllStaff() {
        Notification n = new Notification();
        n.setStaffId(0);
        return n;
    }

    private static Notification forStaff(int staffId) {
        Notification n = new Notification();
        n.setStaffId(staffId);
        return n;
    }

    private static Notification forDeliveryBoy(int deliveryBoyId) {
        Notification n = new Notification();
        n.setDeliveryBoyId(deliveryBoyId);
        return n;
    }

    private static void insert(Notification n) {
        String sql = "INSERT INTO notifications " +
                     "(user_id, staff_id, delivery_boy_id, title, message, link_url, " +
                     " category, order_id, complaint_id, return_id, priority) " +
                     "VALUES (?,?,?,?,?,?,?,?,?,?,?)";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            setNullableInt(ps, 1, n.getUserId());
            setNullableInt(ps, 2, n.getStaffId());
            setNullableInt(ps, 3, n.getDeliveryBoyId());
            ps.setString(4, n.getTitle());
            ps.setString(5, n.getMessage());
            ps.setString(6, n.getLinkUrl());
            ps.setString(7, n.getCategory() != null ? n.getCategory() : "SYSTEM");
            setNullableInt(ps, 8,  n.getOrderId());
            setNullableInt(ps, 9,  n.getComplaintId());
            setNullableInt(ps, 10, n.getReturnId());
            ps.setString(11, n.getPriority() != null ? n.getPriority() : "LOW");
            ps.executeUpdate();
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    private int countUnread(String col, int id) {
        String sql = "SELECT COUNT(*) FROM notifications WHERE " + col + "=? AND is_read=0";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, id);
            ResultSet rs = ps.executeQuery();
            return rs.next() ? rs.getInt(1) : 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return 0;
        }
    }

    /** Staff: own rows OR broadcast rows (staff_id=0). */
    private int countUnreadBroadcast(String col, int id) {
        String sql = "SELECT COUNT(*) FROM notifications WHERE is_read=0 AND (" + col + "=? OR " + col + "=0)";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, id);
            ResultSet rs = ps.executeQuery();
            return rs.next() ? rs.getInt(1) : 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return 0;
        }
    }

    private List<Notification> fetch(String whereClause, int paramValue, int limit) {
        String sql = "SELECT * FROM notifications " + whereClause +
                     " ORDER BY created_at DESC LIMIT " + limit;
        List<Notification> list = new ArrayList<>();
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, paramValue);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) list.add(map(rs));
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    private List<Notification> fetchBroadcast(String col, int id, int limit) {
        String sql = "SELECT * FROM notifications WHERE (" + col + "=? OR " + col + "=0) " +
                     "ORDER BY created_at DESC LIMIT " + limit;
        List<Notification> list = new ArrayList<>();
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, id);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) list.add(map(rs));
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    private void markAllRead(String col, int id) {
        String sql = "UPDATE notifications SET is_read=1, read_at=NOW() WHERE " + col + "=? AND is_read=0";
        runUpdate(sql, id);
    }

    private void runUpdate(String sql, int id) {
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, id);
            ps.executeUpdate();
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    private Notification map(ResultSet rs) throws SQLException {
        Notification n = new Notification();
        n.setId(rs.getInt("id"));
        n.setUserId((Integer) rs.getObject("user_id"));
        n.setStaffId((Integer) rs.getObject("staff_id"));
        n.setDeliveryBoyId((Integer) rs.getObject("delivery_boy_id"));
        n.setTitle(rs.getString("title"));
        n.setMessage(rs.getString("message"));
        n.setLinkUrl(rs.getString("link_url"));
        n.setCategory(rs.getString("category"));
        n.setOrderId((Integer) rs.getObject("order_id"));
        n.setComplaintId((Integer) rs.getObject("complaint_id"));
        n.setReturnId((Integer) rs.getObject("return_id"));
        n.setPriority(rs.getString("priority"));
        n.setRead(rs.getInt("is_read") == 1);
        n.setCreatedAt(rs.getTimestamp("created_at"));
        n.setReadAt(rs.getTimestamp("read_at"));
        return n;
    }

    private static void setNullableInt(PreparedStatement ps, int idx, Integer val) throws SQLException {
        if (val == null) ps.setNull(idx, Types.INTEGER);
        else             ps.setInt(idx, val);
    }

    /** Customer: product review submitted or updated */
    public static void sendReviewSubmitted(int customerId, String productName, int rating, boolean isUpdate) {
        Notification n = forCustomer(customerId);
        n.setCategory("ORDER");
        n.setPriority("LOW");
        n.setTitle(isUpdate ? "Review Updated" : "Review Submitted");
        n.setMessage("Your " + rating + "-star review for \"" + productName + "\" has been " +
                     (isUpdate ? "updated" : "submitted") + ". Thank you for your feedback!");
        n.setLinkUrl("/my-orders.jsp");
        insert(n);
    }
}