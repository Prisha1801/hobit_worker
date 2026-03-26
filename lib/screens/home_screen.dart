import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hobit_worker/colors/appcolors.dart';
import '../api_services/api_services.dart';
import '../api_services/location_service.dart';
import '../api_services/urls.dart';
import '../l10n/app_localizations.dart';
import '../maps/customer_route_map.dart';
import '../models/booking_model.dart';
import '../models/extend_service_model.dart';
import '../models/get_profile_model.dart';
import '../prefs/app_preference.dart';
import '../prefs/preference_key.dart';
import '../utils/appBar_for_home.dart';
import '../utils/extension_history.dart';
import '../widgets/booking_repo_home.dart';
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
      // for (var b in assigned) {
      //   print("API booking dateeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee: ${b.bookingDate}");
      // }
      //
      // print("Device today dateeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee: ${DateTime.now()}");
      final todayAssigned = assigned
          .where((b) => isToday(b.bookingDate))
          .toList();

      final todayInProgress = inProgress
          .where((b) => isToday(b.bookingDate))
          .toList();

      todayBookings = [
        ...todayInProgress,
        ...todayAssigned,
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

          /// ===== BUTTONS =====
          Row(
            children: [

              /// VIEW DIRECTION
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: OutlinedButton(
                    onPressed: () async {
                      final position =
                      await LocationService.getCurrentLocation();

                      final success =
                      await BookingApi.sendWorkerLiveLocation(
                        bookingId: booking.id,
                        latitude: position.latitude,
                        longitude: position.longitude,
                      );

                      if (success) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CustomerRouteMap(
                              customerLat: booking.latitude,
                              customerLng: booking.longitude,
                              address: booking.address,
                            ),
                          ),
                        );
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: kkblack),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: FittedBox(
                      child: Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 16, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            loc.viewDirection,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              /// VERIFY OTP
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed:
                    isInProgress(booking) ? null : () {
                      _openOtpDialog(booking.id);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kkblack,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: Text(
                      loc.verifyOtp,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBarHome(),
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
                height: isKycApproved ? 160 : 210, // 🔥 dynamic height
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6FF), // ✅ background
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.white, // ✅ #FFFFFF
                      offset: Offset(0, 1), // y = 1
                      blurRadius: 4, // blur = 4
                      spreadRadius: 0,
                    ),
                  ],
                  borderRadius: BorderRadius.circular(0),
                ),
                child: Column(
                  children: [
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
                else
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.45, // card height
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: todayBookings.length,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        return SizedBox(
                          width: MediaQuery.of(context).size.width * 0.85,
                          child: buildAssignedJobCard(todayBookings[index]),
                        );
                      },
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

  int secondsRemaining = 60;
  Timer? timer;
  bool canResend = false;

  @override
  void initState() {
    super.initState();
    startTimer();
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              loc.otpVerification,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              loc.enterOtpMsg,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                6,
                    (index) => SizedBox(
                  width: 36,
                  height: 42,
                  child:
                  TextField(
                    maxLength: 1,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    textAlignVertical: TextAlignVertical.center,

                    // ✅ MAKE DIGITS BIG
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),

                    onChanged: (val) {
                      if (val.isNotEmpty) {
                        otp += val;
                        FocusScope.of(context).nextFocus();
                      }
                    },

                    decoration: InputDecoration(
                      counterText: '',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 26),


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

                        final success = await BookingApi.sendStartOtp(
                          widget.bookingId,
                        );

                        setState(() => resendLoading = false);

                        if (success) {
                          otp = ""; // 🔥 reset otp

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("OTP resent successfully"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Failed to resend OTP"),
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

            // canResend
            //     ? RichText(
            //   text: TextSpan(
            //     text: loc.dontReceiveCode,
            //     style: const TextStyle(color: Colors.black54, fontSize: 13),
            //     children: [
            //       WidgetSpan(
            //         child: GestureDetector(
            //           onTap: resendLoading
            //               ? null
            //               : () async {
            //
            //             setState(() => resendLoading = true);
            //
            //             final success = await BookingApi.sendStartOtp(
            //               widget.bookingId,
            //             );
            //
            //             setState(() => resendLoading = false);
            //
            //             if (success) {
            //               otp = "";
            //
            //               startTimer(); // 🔥 restart timer
            //
            //               ScaffoldMessenger.of(context).showSnackBar(
            //                 const SnackBar(
            //                   content: Text("OTP resent successfully"),
            //                   backgroundColor: Colors.green,
            //                 ),
            //               );
            //             }
            //           },
            //           child: Padding(
            //             padding: const EdgeInsets.only(left: 4),
            //             child: resendLoading
            //                 ? const SizedBox(
            //               width: 14,
            //               height: 14,
            //               child: CircularProgressIndicator(strokeWidth: 2),
            //             )
            //                 : Text(
            //               loc.resend,
            //               style: const TextStyle(
            //                 color: Colors.green,
            //                 fontSize: 13,
            //                 fontWeight: FontWeight.w600,
            //               ),
            //             ),
            //           ),
            //         ),
            //       ),
            //     ],
            //   ),
            // )
            //     : Text(
            //   "Resend OTP in 00:${secondsRemaining.toString().padLeft(2, '0')}",
            //   style: const TextStyle(
            //     fontSize: 13,
            //     color: Colors.grey,
            //   ),
            // ),
            SizedBox(height: 26),
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
                  if (otp.length != 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(loc.enterValidOtp)),
                    );
                    return;
                  }

                  setState(() => loading = true);

                  final success = await BookingApi.verifyStartOtp(
                    bookingId: widget.bookingId,
                    otp: otp,
                  );

                  setState(() => loading = false);

                  if (success) {
                    Navigator.pop(context);
                    widget.onSuccess();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(loc.invalidOtp),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  "Verify OTP",
                  style: TextStyle(
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