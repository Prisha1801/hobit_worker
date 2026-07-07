import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hobit_worker/colors/appcolors.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api_services/api_services.dart';
import '../api_services/emergency_service.dart';
import '../api_services/live_tracking_service.dart';
import '../api_services/location_service.dart';
import '../api_services/urls.dart';
import '../l10n/app_localizations.dart';
import '../models/booking_model.dart';
import '../models/emergency_alert_model.dart';
import '../models/extend_service_model.dart';
import '../models/get_profile_model.dart';
import '../prefs/app_preference.dart';
import '../prefs/preference_key.dart';
import '../attendance/screens/attendance_screen.dart';
import '../utils/appBar_for_home.dart';
import '../utils/extension_history.dart';
import '../widgets/booking_repo_home.dart';
import '../widgets/service_timer_widget.dart';
import 'dart:async';

enum JobStatus { assigned, inprogress, completed }

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  JobStatus jobStatus = JobStatus.assigned;
  bool loadingAvailability = true;
  List<AssignedBookingModel> todayBookings = [];
  Map<int, List<BookingExtensionModel>> bookingExtensions = {};
  // String kycStatus = 'pending';
  String? kycStatus;
  bool get isKycApproved => kycStatus == 'approved';
  bool isInProgress(AssignedBookingModel booking) {
    return booking.status == "inprogress";
  }

  // AssignedBookingModel? assignedBooking;
  bool loadingBooking = true;
  bool resendLoading = false;

  /// Booking ids whose "On My Way" / stop action is in flight (per-card spinner).
  final Set<int> _trackingBusy = {};

  /// The currently active (uncancelled) SOS session, if any. While this is
  /// non-null, tapping the emergency button re-opens the active SOS screen
  /// instead of showing the alert dialog again. Cleared only when the worker
  /// cancels the alert.
  _SosSession? _activeSosSession;

  // NOTE: Accept / Decline flow disabled as per backend developer's request
  // (accept/decline API not to be integrated).
  // /// Booking ids currently being accepted/declined (per-card spinner).
  // final Set<int> _processingIds = {};


  Future<void> loadExtensions(int bookingId) async {
    try {
      final data = await BookingApi.getBookingExtensions(bookingId);

      setState(() {
        bookingExtensions[bookingId] = data;
      });

    } catch (e) {
      debugPrint("Extension error: $e");
    }
  }


  Future<void> _refreshHome() async {
    setState(() {
      loadingBooking = true;
    });

    // await loadAssignedBooking();
    await loadAvailabilityFromApi();
    await loadTodayJobs();
  }

  /// 🗺️ Open the customer location directly in the external Google Maps app
  /// (turn-by-turn navigation). No in-app map, no worker-location send here —
  /// the worker location is now shared only at the Confirm Location step.
  Future<void> _openInGoogleMaps(AssignedBookingModel booking) async {
    final lat = booking.latitude;
    final lng = booking.longitude;

    print("🗺️ [ViewMap] Clicked for BK-${booking.id} → customer: $lat,$lng");

    // Native Google Maps navigation intent (Android/iOS Google Maps app).
    final navUri = Uri.parse("google.navigation:q=$lat,$lng&mode=d");

    // Universal fallback (opens Google Maps in browser / app chooser).
    final webUri = Uri.parse(
      "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving",
    );

    try {
      if (await canLaunchUrl(navUri)) {
        print("🗺️ [ViewMap] Launching Google Maps app: $navUri");
        await launchUrl(navUri, mode: LaunchMode.externalApplication);
      } else {
        print("🗺️ [ViewMap] Google Maps app not available, opening web: $webUri");
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print("🗺️ [ViewMap] Failed to open Google Maps: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open Google Maps")),
        );
      }
    }
  }

  void _openOtpDialog(int bookingId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => OtpDialog(
        bookingId: bookingId,
        onSuccess: () async {
          //  Navigator.pop(context);

          setState(() => loadingBooking = true);

          // 🔥 MOST IMPORTANT
          await loadTodayJobs();
        },
      ),
    );
  }

  /// 🔥 NEW FLOW — end an in-progress service.
  /// POST /api/booking/end-service   body: { "booking_id": id }
  Future<void> _endService(int bookingId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'End Service',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to mark this service as completed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Yes, End'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await BookingApi.endService(bookingId);
    if (!mounted) return;

    final success = result['success'] == true;
    final msg = (result['message']?.toString().isNotEmpty == true)
        ? result['message'].toString()
        : (success ? 'Service completed' : 'Failed to end service');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );

    if (success) {
      // end-service auto-stops tracking server-side; just clear it locally.
      await LiveTrackingService.instance
          .stop(bookingId: bookingId, notifyBackend: false);
      setState(() => loadingBooking = true);
      await loadTodayJobs();
    }
  }

  /// 🔥 LIVE TRACKING — worker taps "On My Way".
  Future<void> _onMyWay(int bookingId) async {
    setState(() => _trackingBusy.add(bookingId));

    final result = await LiveTrackingService.instance.start(bookingId);

    if (!mounted) return;
    setState(() => _trackingBusy.remove(bookingId));

    final success = result['success'] == true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message']?.toString() ??
            (success ? 'Sharing your location.' : 'Failed to start tracking.')),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  /// 🔥 LIVE TRACKING — worker stops sharing before ending the service.
  Future<void> _stopSharing(int bookingId) async {
    setState(() => _trackingBusy.add(bookingId));

    await LiveTrackingService.instance.stop(bookingId: bookingId);

    if (!mounted) return;
    setState(() => _trackingBusy.remove(bookingId));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Stopped sharing location.')),
    );
  }

  // NOTE: Accept / Decline flow disabled as per backend developer's request
  // (accept/decline API not to be integrated).
  /*
  /// ===== ACCEPT / DECLINE (pending assigned bookings) =====
  Future<void> _acceptBooking(int bookingId) async {
    setState(() => _processingIds.add(bookingId));

    final result = await BookingApi.acceptBooking(bookingId);

    if (!mounted) return;
    setState(() => _processingIds.remove(bookingId));

    _showActionSnack(result, 'Booking accepted.', 'Failed to accept booking.');

    if (result['success'] == true) {
      await loadTodayJobs();
    }
  }

  Future<void> _declineBooking(int bookingId) async {
    final reason = await _askDeclineReason();
    if (reason == null) return; // cancelled

    setState(() => _processingIds.add(bookingId));

    final result = await BookingApi.declineBooking(bookingId, reason: reason);

    if (!mounted) return;
    setState(() => _processingIds.remove(bookingId));

    _showActionSnack(result, 'Booking declined.', 'Failed to decline booking.');

    if (result['success'] == true) {
      await loadTodayJobs();
    }
  }

  void _showActionSnack(
    Map<String, dynamic> result,
    String successFallback,
    String failFallback,
  ) {
    final success = result['success'] == true;
    final msg = (result['message']?.toString().isNotEmpty == true)
        ? result['message'].toString()
        : (success ? successFallback : failFallback);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Future<String?> _askDeclineReason() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'Decline Booking',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add a reason (optional):',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. I am not available at that time',
                hintStyle: const TextStyle(fontSize: 13),
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Decline'),
          ),
        ],
      ),
    );
  }
  */

  String getStatusText() {
    switch (jobStatus) {
      case JobStatus.assigned:
        return 'Assigned';
      case JobStatus.inprogress:
        return 'In Progress';
      case JobStatus.completed:
        return 'Completed';
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'assigned':
        return Colors.orange;
      case 'inprogress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String getButtonText() {
    final loc = AppLocalizations.of(context)!;
    if (jobStatus == JobStatus.assigned) return loc.startService;
    if (jobStatus == JobStatus.inprogress) return 'Complete Service';
    return 'Service Completed';
  }

  bool isAvailable = true;
  double dragPosition = 0;
  final double sliderWidth = 260;
  final double thumbSize = 42;

  // ✅ 1. Check booking is today
  bool isToday(String bookingDate) {
    final booking = DateTime.parse(bookingDate);
    final now = DateTime.now();

    return booking.year == now.year &&
        booking.month == now.month &&
        booking.day == now.day;
  }

  @override
  void initState() {
    super.initState();
    loadAvailabilityFromApi();
    //loadAssignedBooking();
    loadTodayJobs();
  }

  Future<void> loadTodayJobs() async {
    try {
      final assigned = await BookingApi.getAssignedBookings();
      final inProgress = await BookingApi.getInProgressBookings();

      // Show ALL assigned + in-progress jobs (no today-date / subscription
      // filtering). Pending ones get Accept/Decline; accepted ones get the
      // On My Way / Verify OTP flow. Declined ones are dropped from the list.
      final assignedJobs = assigned
          .where((b) => b.acceptanceStatus.toLowerCase() != 'declined')
          .toList();

      todayBookings = [
        ...inProgress,
        ...assignedJobs,
      ];

      for (var booking in todayBookings) {
        loadExtensions(booking.id);
      }
    } catch (e) {
      debugPrint("Booking error: $e");
      todayBookings = [];
    }

    setState(() => loadingBooking = false);
  }


  Future<void> loadAssignedBooking() async {
    try {
      final bookings = await BookingApi.getAssignedBookings();

      todayBookings = bookings.where((b) => isToday(b.bookingDate)).toList();
    } catch (e) {
      debugPrint("Booking error: $e");
      todayBookings = [];
    }

    setState(() => loadingBooking = false);
  }

  Future<void> loadAvailabilityFromApi() async {
    try {
      final token = AppPreference().getString(PreferencesKey.token);

      final res = await ApiService.getRequest(
        getPersonalInfoUrl,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final profile = WorkerProfileModel.fromJson(res.data);

      //  workerId = profile.id;


      setState(() {
        isAvailable = profile.isActive == 1;
        dragPosition = isAvailable ? 0 : sliderWidth - thumbSize - 8;
        kycStatus = profile.kycStatus; // 🔥 ADD THIS
        loadingAvailability = false;
      });
    } catch (e) {
      loadingAvailability = false;
    }
  }

  Future<void> updateAvailabilityToApi(bool newStatus) async {
    final token = AppPreference().getString(PreferencesKey.token);
    final workerId = AppPreference().getString(PreferencesKey.userId);

    await ApiService.putRequest(
      '/api/admin/worker/$workerId/update',
      {"is_active": newStatus ? 1 : 0},
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );
  }

  Widget statusChip(String status) {
    Color color = Colors.orange;
    if (status == "completed") color = Colors.green;
    if (status == "inprogress") color = Colors.blue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget buildAssignedJobCard(AssignedBookingModel booking) {
    final loc = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFC8CBD0), width: 0.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            offset: Offset(0, 4),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// ===== TOP ROW =====
          // Row(
          //   children: [
          //     const CircleAvatar(radius: 22, child: Icon(Icons.person)),
          //     const SizedBox(width: 12),
          //
          //     Expanded(
          //       child: Text(
          //         booking.customerName,
          //         maxLines: 1,
          //         overflow: TextOverflow.ellipsis,
          //         style: const TextStyle(
          //           fontSize: 15,
          //           fontWeight: FontWeight.w600,
          //         ),
          //       ),
          //     ),
          //
          //     const SizedBox(width: 6),
          //
          //     Container(
          //       padding: const EdgeInsets.symmetric(
          //         horizontal: 12,
          //         vertical: 5,
          //       ),
          //       decoration: BoxDecoration(
          //         color: getStatusColor(booking.status).withOpacity(0.15),
          //         borderRadius: BorderRadius.circular(20),
          //       ),
          //       child: Text(
          //         booking.status.toUpperCase(),
          //         style: TextStyle(
          //           fontSize: 11,
          //           color: getStatusColor(booking.status),
          //           fontWeight: FontWeight.w600,
          //         ),
          //       ),
          //     ),
          //   ],
          // ),
          Row(
            children: [
              const CircleAvatar(radius: 22, child: Icon(Icons.person)),
              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  booking.customerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              /// 🔥 STATUS CHIP
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: getStatusColor(booking.status).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  booking.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    color: getStatusColor(booking.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // const SizedBox(width: 2),

              /// 🔥 3 DOT MENU (RIGHT SIDE)
              PopupMenuButton<String>(
                color: Colors.white,
                icon: const Icon(Icons.more_vert, size: 20),
                onSelected: (value) async {

                  bool success = await BookingApi.updateBookingStatus(
                    bookingId: booking.id,
                    status: value,
                  );

                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Status updated to $value")),
                    );

                    loadTodayJobs(); // 🔥 refresh
                  }
                },
                itemBuilder: (context) {

                  final current = booking.status;

                  return [
                    if (current != "assigned")
                      const PopupMenuItem(
                        value: "assigned",
                        child: Text("Assigned"),
                      ),
                    if (current != "inprogress")
                      const PopupMenuItem(
                        value: "inprogress",
                        child: Text("In Progress"),
                      ),
                    if (current != "completed")
                      const PopupMenuItem(
                        value: "completed",
                        child: Text("Completed"),
                      ),
                  ];
                },
              ),
            ],
          ),

          const SizedBox(height: 14),

          /// ===== SERVICE + DATE/TIME =====
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// LEFT SIDE
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Text(
                      'Service Requested',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),

                    const SizedBox(height: 2),

                    // Text(
                    //   booking.service.name,
                    //   maxLines: 2,
                    //   overflow: TextOverflow.ellipsis,
                    //   style: const TextStyle(
                    //     fontSize: 14,
                    //     fontWeight: FontWeight.w600,
                    //   ),
                    // ),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        /// SERVICE NAME
                        Text(
                          booking.service.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        /// ADDON
                        if (booking.addonNames.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              "Addon: ${List.generate(
                                booking.addonNames.length,
                                    (i) => "${booking.addonNames[i]} (Qty: ${booking.addonQty[i]})",
                              ).join(", ")}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    if (booking.service.subscription?.name != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          /// SUBSCRIPTION
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              booking.service.subscription!.name,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue,
                              ),
                            ),
                          ),

                          /// EXTENSION BUTTON
                          if (bookingExtensions[booking.id] != null &&
                              bookingExtensions[booking.id]!.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => ExtensionHistoryDialog(
                                    bookingId: booking.id,
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(top: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "Extended Service (${bookingExtensions[booking.id]!.length})",
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              /// RIGHT SIDE
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [

                    const Text(
                      'Date & Time',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      booking.bookingDate,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      booking.timeSlot,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(thickness: 0.6),
          const SizedBox(height: 10),

          /// ===== LOCATION =====
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.green),
              const SizedBox(width: 6),

              Expanded(
                child: Text(
                  "${booking.address}, ${booking.city}",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ),

              const SizedBox(width: 6),

              Text(
                "BK-${booking.id}",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          /// ===== SERVICE TIMER (only while in progress) =====
          if (isInProgress(booking)) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timelapse, size: 18, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text(
                    'Service running',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  ServiceTimerWidget(bookingId: booking.id),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          /// ===== ACTIONS =====
          // NOTE: Accept / Decline flow disabled as per backend developer's
          // request (accept/decline API not to be integrated). Always show the
          // tracking / OTP flow below.
          // if (booking.status == 'assigned' &&
          //     booking.acceptanceStatus.toLowerCase() == 'pending') ...[
          //   /// PENDING → ACCEPT / DECLINE
          //   _buildAcceptDecline(booking),
          // ] else ...[

          /// ===== ON MY WAY / LIVE LOCATION SHARING =====
          _buildTrackingButton(booking),

          /// ===== BUTTONS =====
          Row(
            children: [

              /// VIEW DIRECTION
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: OutlinedButton(
                    onPressed: () => _openInGoogleMaps(booking),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: kkblack),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 16, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          loc.viewDirection,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            // color: Colors.black,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              /// VERIFY OTP (assigned) / END SERVICE (inprogress)
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: isInProgress(booking)
                        ? () => _endService(booking.id)
                        : () => _openOtpDialog(booking.id),
                    style: ElevatedButton.styleFrom(
                      //backgroundColor: kkblack,
                      backgroundColor: isInProgress(booking)
                          ? Colors.green.shade400
                          : Colors.yellow.shade400,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: Text(
                      isInProgress(booking) ? 'End Service' : loc.verifyOtp,
                      style: TextStyle(
                        fontSize: 13,
                        color: isInProgress(booking)
                            ? Colors.white
                            : Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // ], // end of disabled accept/decline else-branch
        ],
      ),
    );
  }


  /// "On My Way" button (starts live location sharing) / active-sharing pill.
  Widget _buildTrackingButton(AssignedBookingModel booking) {
    final busy = _trackingBusy.contains(booking.id);
    final isTracking =
        LiveTrackingService.instance.isTrackingBooking(booking.id);

    // Currently sharing → show status + stop control.
    if (isTracking) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.my_location, size: 18, color: Colors.green),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Sharing your live location',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ),
              busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : TextButton(
                      onPressed: () => _stopSharing(booking.id),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Stop',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      );
    }

    // Not sharing yet → "On My Way" button.
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        height: 40,
        child: ElevatedButton.icon(
          onPressed: busy ? null : () => _onMyWay(booking.id),
          style: ElevatedButton.styleFrom(
            backgroundColor: kkblack,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          icon: busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.navigation, size: 18),
          label: const Text(
            'On My Way',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  // NOTE: Accept / Decline flow disabled as per backend developer's request
  // (accept/decline API not to be integrated).
  /*
  /// Accept / Decline buttons for a pending assigned booking.
  Widget _buildAcceptDecline(AssignedBookingModel booking) {
    final processing = _processingIds.contains(booking.id);

    return Row(
      children: [
        /// DECLINE
        Expanded(
          child: SizedBox(
            height: 42,
            child: OutlinedButton(
              onPressed: processing ? null : () => _declineBooking(booking.id),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Decline',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        /// ACCEPT
        Expanded(
          child: SizedBox(
            height: 42,
            child: ElevatedButton(
              onPressed: processing ? null : () => _acceptBooking(booking.id),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: processing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Accept',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ),
      ],
    );
  }
  */

  /// Selectable emergency alert types accepted by the backend
  /// (safety|medical|accident|harassment|other).
  static const List<Map<String, dynamic>> _alertTypes = [
    {'value': 'safety', 'label': 'Safety', 'icon': Icons.shield_outlined},
    {'value': 'medical', 'label': 'Medical', 'icon': Icons.medical_services_outlined},
    {'value': 'accident', 'label': 'Accident', 'icon': Icons.car_crash_outlined},
    {'value': 'harassment', 'label': 'Harassment', 'icon': Icons.report_gmailerrorred_outlined},
    {'value': 'other', 'label': 'Other', 'icon': Icons.more_horiz},
  ];

  /// Pushes the active SOS screen for [session]. When the worker cancels the
  /// alert (the screen pops with `true`), the stored session is cleared so the
  /// next emergency tap starts a fresh alert dialog.
  Future<void> _openSosScreen(_SosSession session) async {
    final cancelled = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SosActiveScreen(
          workerName: session.workerName,
          sentAt: session.sentAt,
          location: session.location,
          bookingId: session.bookingId,
          alert: session.alert,
          alertType: session.alertType,
          serverMessage: session.serverMessage,
        ),
      ),
    );
    if (cancelled == true && mounted) {
      setState(() => _activeSosSession = null);
    }
  }

  void _showSosDialog() {
    final loc = AppLocalizations.of(context)!;

    // An alert is already active and not yet cancelled — re-open it instead of
    // raising a new one.
    if (_activeSosSession != null) {
      _openSosScreen(_activeSosSession!);
      return;
    }

    // SOS is only allowed against a service that is actually running.
    final inProgressJobs = todayBookings.where(isInProgress).toList();

    if (inProgressJobs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.sosOnlyInProgress),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final AssignedBookingModel activeBooking = inProgressJobs.first;

    final messageController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool sending = false;
        String alertType = 'safety';
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                const SizedBox(width: 8),
                Text(
                  loc.sosAlert,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.sosDescription,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    loc.sosBooking(activeBooking.id),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    loc.sosTypeOfEmergency,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _alertTypes.map((t) {
                      final selected = alertType == t['value'];
                      return ChoiceChip(
                        selected: selected,
                        onSelected: sending
                            ? null
                            : (_) => setDialogState(
                                () => alertType = t['value'] as String),
                        backgroundColor: Colors.grey.shade100,
                        selectedColor: Colors.red.withOpacity(0.12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: selected ? Colors.red : Colors.grey.shade300,
                          ),
                        ),
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              t['icon'] as IconData,
                              size: 15,
                              color: selected ? Colors.red : Colors.black54,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _emergencyTypeLabel(loc, t['value'] as String),
                              style: TextStyle(
                                fontSize: 12,
                                color: selected ? Colors.red : Colors.black87,
                                fontWeight:
                                    selected ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: messageController,
                    enabled: !sending,
                    maxLines: 3,
                    maxLength: 1000,
                    decoration: InputDecoration(
                      hintText: loc.sosAddMessage,
                      hintStyle: const TextStyle(fontSize: 13),
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: sending ? null : () => Navigator.pop(ctx),
                child: Text(loc.no,
                    style: const TextStyle(fontSize: 15, color: Colors.black54, fontWeight: FontWeight.w600)),
              ),
              ElevatedButton(
                onPressed: sending
                    ? null
                    : () async {
                        setDialogState(() => sending = true);

                        final dialogNav = Navigator.of(ctx);
                        final messenger = ScaffoldMessenger.of(context);
                        final workerName =
                            AppPreference().getString(PreferencesKey.name);
                        final sentAt = DateTime.now();

                        // Best-effort live location (fields are optional on the API).
                        double? lat;
                        double? lng;
                        try {
                          final pos = await LocationService.getCurrentLocation();
                          lat = pos.latitude;
                          lng = pos.longitude;
                          LocationStore.lat = lat;
                          LocationStore.lng = lng;
                        } catch (e) {
                          debugPrint('SOS location fetch failed: $e');
                          if (LocationStore.lat != 0.0 ||
                              LocationStore.lng != 0.0) {
                            lat = LocationStore.lat;
                            lng = LocationStore.lng;
                          }
                        }

                        final result = await EmergencyService.raiseAlert(
                          bookingId: activeBooking.id,
                          alertType: alertType,
                          message: messageController.text,
                          latitude: lat,
                          longitude: lng,
                        );

                        if (!mounted) return;

                        final success = result['success'] == true;
                        final msg = result['message']?.toString() ?? '';

                        if (!success) {
                          setDialogState(() => sending = false);
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(msg.isEmpty
                                  ? loc.sosFailed
                                  : msg),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        dialogNav.pop();

                        // Remember this alert so re-tapping emergency re-opens
                        // the active screen until the worker cancels it.
                        final session = _SosSession(
                          workerName: workerName,
                          sentAt: sentAt,
                          location: LocationStore.address,
                          bookingId: activeBooking.id,
                          alert: result['alert'] as EmergencyAlertModel?,
                          alertType: alertType,
                          serverMessage: msg,
                        );
                        setState(() => _activeSosSession = session);
                        _openSosScreen(session);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: sending
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(loc.sosYesSend,
                        style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBarHome(onEmergencyPressed: _showSosDialog),
      backgroundColor: kWhite,
      body: RefreshIndicator(
        color: kkblack,
        onRefresh: _refreshHome,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          //  padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= ATTENDANCE =================
              Container(
                width: double.infinity,
                // height: 160,
                height: isKycApproved ? 210 : 260, // 🔥 dynamic height (extra headroom to avoid bottom overflow)
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  // color: const Color(0xFFF5F6FF), // ✅ background
                  color: Colors.white,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.white, // ✅ #FFFFFF
                      offset: Offset(0, 1), // y = 1
                      blurRadius: 4, // blur = 4
                      spreadRadius: 0,
                    ),
                  ],
                  border: Border.all(
                    color: const Color(0xFFC8CBD0),
                    width: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(0),
                ),
                child: Column(
                  children: [
                    /// Attendance chip — top right
                    Align(
                      alignment: Alignment.centerRight,
                      child: AttendanceChip(
                        label: loc.attendance,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AttendanceScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      loc.attendance,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 11),
                    Text(
                      loc.workShift,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 20),

                    /// Swipe for availability (UI only)
                    Container(
                      width: sliderWidth,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isAvailable ? Colors.white : kkblack,
                        borderRadius: BorderRadius.circular(
                          28,
                        ), // Fully rounded like the image
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          /// CENTER TEXT
                          Text(
                            isAvailable ? loc.available : loc.unavailable,
                            style: TextStyle(
                              color: isAvailable ? Colors.black : Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          /// ARROWS ON THE RIGHT (like in the image)
                          Positioned(
                            right: 16,
                            child: Row(
                              children: List.generate(
                                2,
                                    (index) => Padding(
                                  padding: EdgeInsets.only(
                                    left: index > 0 ? 2 : 0,
                                  ),
                                  child: Icon(
                                    Icons.arrow_forward_ios,
                                    size: 12,
                                    color: isAvailable
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          /// SLIDE THUMB (FULLY ROUNDED CIRCLE)
                          Positioned(
                            left: dragPosition + 4, // Added padding from edge
                            top: 4, // Added padding from top
                            bottom: 4, // Added padding from bottom
                            child: GestureDetector(
                              onHorizontalDragUpdate: !isKycApproved ? null : (details) {
                                setState(() {
                                  dragPosition += details.delta.dx;
                                  if (dragPosition < 0) dragPosition = 0;
                                  if (dragPosition > sliderWidth - thumbSize - 8) {
                                    dragPosition = sliderWidth - thumbSize - 8;
                                  }
                                });
                              },
                              onHorizontalDragEnd: !isKycApproved ? null : (_) async {
                                bool newStatus;
                                if (dragPosition >= sliderWidth - thumbSize - 20) {
                                  newStatus = false;
                                  dragPosition = sliderWidth - thumbSize - 8;
                                } else {
                                  newStatus = true;
                                  dragPosition = 0;
                                }
                                setState(() => isAvailable = newStatus);
                                await updateAvailabilityToApi(newStatus);
                              },
                              // onHorizontalDragUpdate: (details) {
                              //   setState(() {
                              //     dragPosition += details.delta.dx;
                              //     if (dragPosition < 0) dragPosition = 0;
                              //     if (dragPosition >
                              //         sliderWidth - thumbSize - 8) {
                              //       dragPosition = sliderWidth - thumbSize - 8;
                              //     }
                              //   });
                              // },
                              // onHorizontalDragEnd: (_) {
                              //   setState(() {
                              //     // 👉 FULL SWIPE RIGHT = OFFLINE
                              //     if (dragPosition >= sliderWidth - thumbSize - 20) {
                              //       isAvailable = false;
                              //       dragPosition = sliderWidth - thumbSize - 8;
                              //     } else {
                              //       // 👉 revert back to ONLINE
                              //       isAvailable = true;
                              //       isAvailable = true;
                              //       dragPosition = 0;
                              //     }
                              //   });
                              // },
                              // onHorizontalDragEnd: (_) async {
                              //   bool newStatus;
                              //
                              //   if (dragPosition >=
                              //       sliderWidth - thumbSize - 20) {
                              //     newStatus = false;
                              //     dragPosition = sliderWidth - thumbSize - 8;
                              //   } else {
                              //     newStatus = true;
                              //     dragPosition = 0;
                              //   }
                              //
                              //   setState(() {
                              //     isAvailable = newStatus;
                              //   });
                              //
                              //   // 🔥 API CALL
                              //   await updateAvailabilityToApi(newStatus);
                              // },

                              child: Container(
                                width: thumbSize,
                                height: thumbSize, // ✅ same as width
                                decoration: BoxDecoration(
                                  color: isAvailable
                                      ? kkblack
                                      : Colors.white,
                                  shape: BoxShape.circle, // ✅ PERFECT CIRCLE
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: isAvailable
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // After the slider Container, inside the Column children:
                    //!isKycApproved
                    if (kycStatus != null && !isKycApproved) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
                        decoration: BoxDecoration(
                          color: kycStatus == 'rejected'
                              ? Colors.red.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              kycStatus == 'rejected' ? Icons.cancel : Icons.info_outline,
                              size: 14,
                              color: kycStatus == 'rejected' ? Colors.red : Colors.orange,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              kycStatus == 'rejected'
                                  ? 'KYC Rejected. Please re-upload documents.'
                                  : 'KYC approval pending. Attendance locked.',
                              style: TextStyle(
                                fontSize: 12,
                                color: kycStatus == 'rejected' ? Colors.red : Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Text(
                loc.currentAssignJob,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              if (loadingBooking)
                const Center(child: CircularProgressIndicator())

              else if (todayBookings.isEmpty)
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.35,
                  child: Center(
                    child: Text(
                      loc.noAssignedJobToday,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ),
                )
              // else
              // buildAssignedJobCard(assignedBooking!),
              else if (todayBookings.isEmpty)
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.35,
                    child: Center(
                      child: Text(
                        loc.noAssignedJobToday,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ),
                  )
                else if (todayBookings.length == 1)
                  /// 🔹 Single job → full-width card that wraps its content
                  /// (no fixed height, so no blank space below)
                  SizedBox(
                    width: double.infinity,
                    child: buildAssignedJobCard(todayBookings.first),
                  )
                else
                  /// 🔹 Multiple jobs → horizontal carousel. IntrinsicHeight makes
                  /// every card match the tallest one; height wraps content.
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (int i = 0; i < todayBookings.length; i++) ...[
                            if (i > 0) const SizedBox(width: 12),
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.85,
                              child: buildAssignedJobCard(todayBookings[i]),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}


class OtpDialog extends StatefulWidget {
  final int bookingId;
  final VoidCallback onSuccess;

  const OtpDialog({Key? key, required this.bookingId, required this.onSuccess})
      : super(key: key);

  @override
  State<OtpDialog> createState() => _OtpDialogState();
}

class _OtpDialogState extends State<OtpDialog> {
  String otp = "";
  bool loading = false;
  bool resendLoading = false;
  // ❌ OLD SMS / WhatsApp flow (kept for reference)
  // String selectedType = "sms"; // Default is SMS

  int secondsRemaining = 60;
  Timer? timer;
  bool canResend = false;
  final List<TextEditingController> controllers =
  List.generate(4, (_) => TextEditingController());

  final List<FocusNode> focusNodes =
  List.generate(4, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    startTimer();
    // 🔥 NEW FLOW: generate the customer start code as soon as the dialog opens
    _generateCode();
  }

  /// 🔥 NEW FLOW — calls /api/booking/generate-codes so the customer receives
  /// a start code, which the worker then enters below to verify.
  Future<void> _generateCode() async {
    final result = await BookingApi.generateStartCode(widget.bookingId);
    if (!mounted) return;

    final success = result["success"] == true;
    final msg = (result["message"]?.toString().isNotEmpty == true)
        ? result["message"].toString()
        : (success ? "Start code sent to customer" : "Failed to generate code");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  void startTimer() {
    secondsRemaining = 60;
    canResend = false;

    timer?.cancel();

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (secondsRemaining == 0) {
        setState(() {
          canResend = true;
        });
        t.cancel();
      } else {
        setState(() {
          secondsRemaining--;
        });
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Text(
            //   loc.otpVerification,
            //   style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            // ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [

                /// Empty for spacing
                const SizedBox(width: 24),

                /// Title (same as before)
                Text(
                  loc.otpVerification,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                /// 🔥 CLOSE BUTTON
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context); // 👉 popup close
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              loc.enterOtpMsg,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 16),

            Row(
              children: List.generate(4, (index) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: AspectRatio(
                      aspectRatio: 1, // perfect square, scales to width
                      child: TextField(
                        controller: controllers[index],
                        focusNode: focusNodes[index],
                        maxLength: 1,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        textAlignVertical: TextAlignVertical.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),

                        onChanged: (val) {
                          // Rebuild OTP straight from the boxes so edits /
                          // backspace anywhere stay correct.
                          otp = controllers.map((c) => c.text).join();

                          if (val.isNotEmpty && index < 3) {
                            FocusScope.of(context).nextFocus();
                          } else if (val.isEmpty && index > 0) {
                            FocusScope.of(context).previousFocus();
                          }
                        },

                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: kkblack, width: 2),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 16),

            // ❌ OLD SMS / WhatsApp OTP type selection (kept for reference, do not remove)
            /*
            /// 🔥 OTP TYPE SELECTION (Inside Resend Logic area)
            const Text(
              "Resend via:",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 100,
                  child: RadioListTile<String>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text("SMS", style: TextStyle(fontSize: 12)),
                    value: "sms",
                    groupValue: selectedType,
                    activeColor: Colors.black,
                    onChanged: (val) {
                      setState(() => selectedType = val!);
                    },
                  ),
                ),
                SizedBox(
                  width: 130,
                  child: RadioListTile<String>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text("WhatsApp", style: TextStyle(fontSize: 12)),
                    value: "whatsapp",
                    groupValue: selectedType,
                    activeColor: Colors.black,
                    onChanged: (val) {
                      setState(() => selectedType = val!);
                    },
                  ),
                ),
              ],
            ),
            */


            const SizedBox(height: 10),


            RichText(
              text: TextSpan(
                text: loc.dontReceiveCode,
                style: const TextStyle(color: Colors.black54, fontSize: 13),
                children: [
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: resendLoading
                          ? null
                          : () async {
                        setState(() => resendLoading = true);

                        // 🔥 NEW FLOW: regenerate the customer start code
                        final result =
                            await BookingApi.generateStartCode(widget.bookingId);

                        // ❌ OLD SMS / WhatsApp resend (kept for reference)
                        // final success = await BookingApi.sendStartOtp(
                        //   widget.bookingId,
                        //   type: selectedType, // Pass selected type
                        // );

                        setState(() => resendLoading = false);

                        if (result["success"] == true) {
                          otp = ""; // 🔥 reset otp
                          for (var c in controllers) {
                            c.clear();
                          }
                          FocusScope.of(context).requestFocus(focusNodes[0]);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("New code sent to customer"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Failed to send code"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: resendLoading
                            ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : Text(
                          loc.resend,
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              child:
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kkblack,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                onPressed: loading
                    ? null
                    : () async {
                  if (otp.length != 4) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(loc.enterValidOtp)),
                    );
                    return;
                  }

                  setState(() => loading = true);

                  // 🔥 NEW FLOW: verify via /api/booking/verifycode/{id}/start
                  final result = await BookingApi.verifyStartCode(
                    bookingId: widget.bookingId,
                    otp: otp,
                  );

                  // ❌ OLD verify flow (kept for reference)
                  // final result = await BookingApi.verifyStartOtp(
                  //   bookingId: widget.bookingId,
                  //   otp: otp,
                  // );

                  setState(() => loading = false);

                  if (result["success"]) {
                    Navigator.pop(context);
                    widget.onSuccess();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result["message"]),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                  loc.verifyOtp,
                  // "Verify OTP",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SOS Active Screen
// ─────────────────────────────────────────────

/// Maps a backend emergency-type value (safety|medical|accident|harassment|other)
/// to its localized label.
String _emergencyTypeLabel(AppLocalizations loc, String value) {
  switch (value) {
    case 'medical':
      return loc.sosTypeMedical;
    case 'accident':
      return loc.sosTypeAccident;
    case 'harassment':
      return loc.sosTypeHarassment;
    case 'other':
      return loc.sosTypeOther;
    case 'safety':
      return loc.sosTypeSafety;
    default:
      return loc.sosTypeOther;
  }
}

/// Snapshot of an active SOS alert, kept in the home screen state so the
/// active screen can be re-opened until the worker cancels the alert.
class _SosSession {
  final String workerName;
  final DateTime sentAt;
  final String location;
  final int? bookingId;
  final EmergencyAlertModel? alert;
  final String? alertType;
  final String? serverMessage;

  _SosSession({
    required this.workerName,
    required this.sentAt,
    required this.location,
    this.bookingId,
    this.alert,
    this.alertType,
    this.serverMessage,
  });
}

class SosActiveScreen extends StatefulWidget {
  final String workerName;
  final DateTime sentAt;
  final String location;
  final int? bookingId;

  /// The alert returned by the backend (null if the response carried no body).
  final EmergencyAlertModel? alert;

  /// The alert type the worker selected (fallback when [alert] is null).
  final String? alertType;

  /// Confirmation message returned by the server.
  final String? serverMessage;

  const SosActiveScreen({
    super.key,
    required this.workerName,
    required this.sentAt,
    required this.location,
    this.bookingId,
    this.alert,
    this.alertType,
    this.serverMessage,
  });

  @override
  State<SosActiveScreen> createState() => _SosActiveScreenState();
}

class _SosActiveScreenState extends State<SosActiveScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<_SosUpdate> _updates = [];
  Timer? _updateTimer;
  int _updateIndex = 0;

  late final List<String> _staticUpdates;

  /// alert type shown in the header / info tile.
  String get _alertType =>
      widget.alert?.alertType ?? widget.alertType ?? 'safety';

  /// current status reported by the backend.
  String get _status => widget.alert?.status ?? 'pending';

  /// Guards one-time, localization-dependent setup in [didChangeDependencies].
  bool _didInitLocalized = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Localizations are only available once dependencies are ready, so this
    // one-time setup lives here rather than in initState().
    if (_didInitLocalized) return;
    _didInitLocalized = true;

    final loc = AppLocalizations.of(context)!;
    _staticUpdates = [
      loc.sosLocatingResponder,
      loc.sosResponderAssigned,
    ];

    // Seed the timeline with the real server confirmation.
    final confirm = (widget.serverMessage?.trim().isNotEmpty == true)
        ? widget.serverMessage!.trim()
        : loc.sosAlertReceived;
    _updates.add(_SosUpdate(message: confirm, time: widget.sentAt));

    _updateTimer = Timer.periodic(const Duration(seconds: 3), (t) {
      if (_updateIndex < _staticUpdates.length) {
        setState(() {
          _updates.add(_SosUpdate(
            message: _staticUpdates[_updateIndex],
            time: DateTime.now(),
          ));
          _updateIndex++;
        });
      } else {
        t.cancel();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _updateTimer?.cancel();
    super.dispose();
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _prettyStatus(AppLocalizations loc, String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return loc.pending;
      case 'assigned':
        return loc.assigned;
      case 'completed':
        return loc.completed;
      case '':
        return loc.pending;
      default:
        return '${status[0].toUpperCase()}${status.substring(1)}';
    }
  }

  void _cancelSos() {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(loc.sosCancelTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(loc.sosCancelConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.no, style: const TextStyle(color: Colors.black54, fontSize: 14)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Signal the home screen that the alert was cancelled so it
              // clears the active session (a plain back gesture returns null
              // and keeps the session alive).
              Navigator.pop(context, true);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(loc.sosCancelled),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(loc.sosYesCancel, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              decoration: const BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Icon(Icons.sos, color: Colors.white, size: 48),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    loc.sosAlertSent,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    loc.sosSentAt(_formatTime(widget.sentAt)),
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Details
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _InfoTile(
                    icon: Icons.person,
                    label: loc.sosWorker,
                    value: widget.workerName.isEmpty ? loc.sosUnknown : widget.workerName,
                  ),
                  const SizedBox(height: 10),
                  _InfoTile(
                    icon: Icons.crisis_alert,
                    label: loc.sosEmergencyType,
                    value: '${_emergencyTypeLabel(loc, _alertType)}  •  ${_prettyStatus(loc, _status)}'
                        '${widget.alert?.id != null ? '  (#${widget.alert!.id})' : ''}',
                  ),
                  const SizedBox(height: 10),
                  _InfoTile(
                    icon: Icons.location_on,
                    label: loc.sosLastKnownLocation,
                    value: widget.location.isEmpty ? loc.sosLocationUnavailable : widget.location,
                  ),
                  if (widget.bookingId != null) ...[
                    const SizedBox(height: 10),
                    _InfoTile(
                      icon: Icons.work_outline,
                      label: loc.sosActiveBooking,
                      value: 'BK-${widget.bookingId}',
                    ),
                  ],
                  const SizedBox(height: 10),
                  _InfoTile(
                    icon: Icons.support_agent,
                    label: loc.sosSupportContact,
                    value: '+91 98765 43210',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Live status updates
            if (_updates.isNotEmpty)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.sosStatusUpdates,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.separated(
                          itemCount: _updates.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final u = _updates[i];
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.circle, size: 8, color: Colors.red),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(u.message,
                                      style: const TextStyle(fontSize: 13)),
                                ),
                                const SizedBox(width: 8),
                                Text(_formatTime(u.time),
                                    style: const TextStyle(fontSize: 11, color: Colors.black45)),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              const Spacer(),

            // Cancel button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _cancelSos,
                  icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                  label: Text(
                    loc.sosCancel,
                    style: const TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SosUpdate {
  final String message;
  final DateTime time;
  _SosUpdate({required this.message, required this.time});
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC8CBD0), width: 0.6),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: Colors.red),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.black45)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Animated Attendance Chip
// ─────────────────────────────────────────────

class AttendanceChip extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;

  const AttendanceChip({super.key, required this.label, this.onTap});

  @override
  State<AttendanceChip> createState() => _AttendanceChipState();
}

class _AttendanceChipState extends State<AttendanceChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    // Gentle continuous pulse to draw attention
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _pulseAnimation,
        // Press feedback: shrink slightly while held
        child: AnimatedScale(
          scale: _pressed ? 0.92 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _pressed ? Colors.blue.shade50 : Colors.white,
              border: Border.all(
                color: Colors.blue,
                width: 1.2,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.access_time, size: 14, color: Colors.blue),
                const SizedBox(width: 4),
                Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
