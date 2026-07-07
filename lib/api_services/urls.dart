//const String baseUrl = "https://hobitadmin.anantkamalsoftwarelabs.com";
//const String baseUrl = "https://backendhobit.anantkamalsoftwarelabs.com";

// const String baseUrl = "https://hobitadmin.hobit.club";

//const String baseUrl = "https://uatadmin.hobit.club";
const String baseUrl = "https://testing.hobit.club";
//registrations apis
const String signUpUrl = "/api/worker/register_app";
const String  serviceCategoriesUrl = "/api/service-categories";
const String  serviceUrl = "/api/services";
const String  citiesUrl = "/api/cities";
const String  zonesUrl = "/api/zones";
const String  serviceAreaUrl = "/api/serviceable-areas";

/// login
const String  loginUrl = "/api/worker/login/send-otp";
const String  verifyOtpUrl = "/api/worker/login/verify-otp";
const String logoutUrl = "/api/logout";
const String getBankDetailsUrl = "/api/worker/bank-details";
const String putBankDetailsUrl = "/api/worker/update_bank_details";
const String getPersonalInfoUrl = "/api/worker/me";
const String fcmTokenUrl = "/api/user/fcm-token";
const String notificationUrl = "/api/worker/bookings";

// Available (unclaimed) bookings — worker can claim these
const String availableBookingsUrl = "/api/worker/available-bookings";
String claimBookingUrl(int bookingId) =>
    "/api/worker/bookingrequest/$bookingId/claim";

// Available bookings — "Accept" reuses the claim URL above; only "Reject" is new
String rejectBookingUrl(int bookingId) =>
    "/api/worker/bookingrequest/$bookingId/reject";

// Live tracking ("On My Way") — worker streams GPS to Firebase RTDB
const String trackingStartUrl = "/api/tracking/start";
const String trackingStopUrl = "/api/tracking/stop";

// Firebase Realtime Database URL for the "hobitpartner" project.
// (Not present in google-services.json, so it must be set explicitly.)
const String hobitRtdbUrl =
    "https://hobitpartner-default-rtdb.asia-southeast1.firebasedatabase.app";

// Attendance APIs worker
const String checkInUrl = "/api/checkin";
const String checkOutUrl = "/api/checkout";
const String myAttendanceUrl = "/api/attendance/my";

// Emergency / SOS Alerts (worker)
// POST — raise an SOS alert. body: booking_id (required), alert_type
// (safety|medical|accident|harassment|other), message, latitude, longitude.
const String emergencyAlertUrl = "/api/worker/emergency-alert";
// GET — the worker's own emergency alert history.
const String emergencyAlertsUrl = "/api/worker/emergency-alerts";

// Coordinator APIs
const String getBookingsUrl = "/api/getbookings";
const String getCoMyBookingUrl = "/api/coordinator/my-bookings";
const String getAvailableWorkersUrl = "/api/admin/unassigned_worker/";
const String assignWorkerUrl = "/api/admin/assign-booking";
const String getSubscriptionTypesUrl = "/api/subscription-types";
const String filterBookingsUrl = "/api/bookings/filter";
const String coordinatorUrl = "/api/coordinators";
