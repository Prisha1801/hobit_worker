import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import '../api_services/api_services.dart';
import '../api_services/urls.dart';
import '../l10n/app_localizations.dart';
import '../models/available_booking_model.dart';
import '../prefs/app_preference.dart';
import '../prefs/preference_key.dart';
import '../screens/my_bookings.dart';
import 'appBar_for_home.dart';
import 'app_bar.dart';
import 'bottom_nav_bar.dart';

/// ================= MODEL =================
class BookingNotificationModel {
  final int id;
  final String status;
  final String customerName;
  final String date;
  final String time;

  BookingNotificationModel({
    required this.id,
    required this.status,
    required this.customerName,
    required this.date,
    required this.time,
  });

  factory BookingNotificationModel.fromJson(Map<String, dynamic> json) {
    return BookingNotificationModel(
      id: json['id'] ?? 0,
      status: json['status'] ?? "",
      customerName: json['customer_name'] ?? "",
      date: json['booking_date'] ?? "",
      time: json['time_slot'] ?? "",
    );
  }
}

DateTime? _parseBookingDate(String dateStr) {
  if (dateStr.trim().isEmpty) return null;

  try {

    /// FORMAT => 19-05-2026
    if (dateStr.contains('-') &&
        dateStr.split('-').first.length == 2) {

      return DateFormat('dd-MM-yyyy').parseStrict(dateStr);
    }

    /// FORMAT => 2026-05-19
    return DateFormat('yyyy-MM-dd').parseStrict(dateStr);

  } catch (e) {
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      return null;
    }
  }
}
// /// Helper to parse booking date strings returned by API.
// DateTime? _parseBookingDate(String dateStr) {
//   if (dateStr.trim().isEmpty) return null;
//   try {
//     // API returns dd-MM-yyyy (e.g. 12-05-2026) — parse with that first
//     final formatter = DateFormat('dd-MM-yyyy');
//     return formatter.parseStrict(dateStr);
//   } catch (_) {
//     try {
//       // fallback to ISO parse
//       return DateTime.parse(dateStr);
//     } catch (e) {
//       return null;
//     }
//   }
// }

Future<List<BookingNotificationModel>> getBookings(String? status) async {
  try {
    final token = AppPreference().getString(PreferencesKey.token);
    final role = AppPreference().getString(PreferencesKey.role).toLowerCase();

    // Decide endpoint based on role
    final bool isCoordinator =
        role.contains('coordinator') ||
            role.contains('co-ordinator') ||
            role.contains('co-ordinators');

    final String url =
    isCoordinator
        ? getBookingsUrl
        : notificationUrl;

    final Map<String, dynamic>? queryParams = status != null ? {"status": status} : null;

    final res = await ApiService.getRequest(
      url,
      queryParameters: queryParams,
      options: Options(
        headers: {
          "Authorization": "Bearer $token",
        },
      ),
    );
    print("ROLE ======> $role");
    print("URL ======> $url");
    print("RESPONSE ======> ${res.data}");
    final data = res.data;
    final List list = data["data"] ?? [];

    return list.map((e) => BookingNotificationModel.fromJson(e)).toList();

  } catch (e) {
    throw "Something went wrong";
  }
}


Future<List<BookingNotificationModel>> getAllNotifications() async {

  final role =
  AppPreference()
      .getString(PreferencesKey.role)
      .toLowerCase();

  final bool isCoordinator =
      // role.contains('coordinator') ||
      //     role.contains('co-ordinator') ||
          role.contains('co-ordinators');

  if (isCoordinator) {

    /// Coordinator API
    return await getBookings(null);

  } else {

    /// Worker APIs
    final assigned = await getBookings("assigned");
    final inProgress = await getBookings("inprogress");
    final completed = await getBookings("completed");

    return [
      ...assigned,
      ...inProgress,
      ...completed,
    ];
  }
}
// Future<List<BookingNotificationModel>> getAllNotifications() async {
//   // For worker we fetch common statuses (keep existing behavior)
//   final role = AppPreference().getString(PreferencesKey.role).toLowerCase();
//
//   if (role.contains('coordinator')) {
//     // For coordinator, fetch without splitting by status (API returns paginated list)
//     return await getBookings(null);
//   } else {
//     final assigned = await getBookings("assigned");
//     final inProgress = await getBookings("inprogress");
//     final completed = await getBookings("completed");
//
//     return [
//       ...assigned,
//       ...inProgress,
//       ...completed,
//     ];
//   }
// }

/// ================= UI =================

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}
class _NotificationScreenState extends ConsumerState<NotificationScreen> {

  bool isLoading = true;
  List<BookingNotificationModel> bookings = [];

  /// Unclaimed bookings (workers only) shown at the top with a Claim action.
  List<AvailableBookingModel> availableBookings = [];

  /// Booking ids currently being claimed (per-card spinner).
  final Set<int> _claimingIds = {};

  // Coordinator-specific view: either 'today' or 'upcoming'
  String coordinatorView = 'today'; // 'today' or 'upcoming'

  // Worker-specific view: either 'today' or 'claim'
  String workerView = 'today'; // 'today' or 'claim'

  /// Auto-open the Claim tab once on first load if claim bookings exist.
  bool _didAutoSelectWorkerView = false;

  late final bool isCoordinator;

  @override
  void initState() {
    super.initState();
    notificationCount.value = 0;
    final role = AppPreference().getString(PreferencesKey.role).toLowerCase();
    isCoordinator =
        // role.contains('coordinator') ||
        //     role.contains('co-ordinator') ||
            role.contains('co-ordinators');
    fetchBookings();
  }

  /// ================= FETCH + TODAY/UPCOMING FILTER =================
  Future<void> fetchBookings() async {
    setState(() => isLoading = true);

    try {
      /// Workers also see unclaimed (available) bookings they can claim.
      if (!isCoordinator) {
        try {
          availableBookings = await BookingApi.getAvailableBookings();
        } catch (e) {
          debugPrint("Available bookings error: $e");
          availableBookings = [];
        }

        /// First load only: open the Claim tab if there are claim bookings,
        /// else stay on Today. Manual toggles afterwards are respected.
        if (!_didAutoSelectWorkerView) {
          workerView = availableBookings.isNotEmpty ? 'claim' : 'today';
          _didAutoSelectWorkerView = true;
        }
      }

      final data = await getAllNotifications();
      print("TOTAL BOOKINGS ======> ${data.length}");

      for (var item in data) {
        print("BOOKING DATE ======> ${item.date}");
      }
      final today = DateTime.now();

      final filtered = data.where((item) {
        try {
          final todayString = DateFormat('dd-MM-yyyy').format(today);

          if (isCoordinator) {

            /// TODAY BOOKINGS
            // if (coordinatorView == 'today') {
            //
            //   return item.date.trim() == todayString;
            //
            // }
            if (coordinatorView == 'today') {

              final bookingDate = _parseBookingDate(item.date);

              if (bookingDate == null) return false;

              final normalizedBookingDate = DateTime(
                bookingDate.year,
                bookingDate.month,
                bookingDate.day,
              );

              final normalizedToday = DateTime(
                today.year,
                today.month,
                today.day,
              );

              return normalizedBookingDate == normalizedToday;
            }
            else {

              /// UPCOMING BOOKINGS
              final bookingDate = _parseBookingDate(item.date);

              if (bookingDate == null) return false;

              return bookingDate.isAfter(
                DateTime(today.year, today.month, today.day),
              );
            }

          } else {

            /// WORKER TODAY BOOKINGS
            // return item.date.trim() == todayString;

            final bookingDate = _parseBookingDate(item.date);

            if (bookingDate == null) return false;

            final normalizedBookingDate = DateTime(
              bookingDate.year,
              bookingDate.month,
              bookingDate.day,
            );

            final normalizedToday = DateTime(
              today.year,
              today.month,
              today.day,
            );

            return normalizedBookingDate == normalizedToday;
          }
        } catch (e) {
          return false;
        }
      }).toList();

      setState(() {
        bookings = filtered;
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// ================= ACCEPT / REJECT =================
  /// Accept reuses the existing claim API — only the button text differs.
  Future<void> _acceptBooking(AvailableBookingModel booking) async {
    final loc = AppLocalizations.of(context)!;
    setState(() => _claimingIds.add(booking.id));

    final result = await BookingApi.claimBooking(booking.id, loc);

    if (!mounted) return;
    setState(() => _claimingIds.remove(booking.id));

    final success = result['success'] == true;
    final msg = (result['message']?.toString().isNotEmpty == true)
        ? result['message'].toString()
        : (success ? loc.mbBookingAccepted : loc.mbFailedAccept);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );

    if (success) {
      /// Remove the accepted booking and refresh the lists.
      setState(() {
        availableBookings.removeWhere((b) => b.id == booking.id);
      });
      fetchBookings();
    }
  }

  Future<void> _rejectBooking(AvailableBookingModel booking) async {
    final loc = AppLocalizations.of(context)!;
    setState(() => _claimingIds.add(booking.id));

    final result = await BookingApi.rejectBooking(booking.id, loc);

    if (!mounted) return;
    setState(() => _claimingIds.remove(booking.id));

    final success = result['success'] == true;
    final msg = (result['message']?.toString().isNotEmpty == true)
        ? result['message'].toString()
        : (success ? loc.mbBookingRejected : loc.mbFailedReject);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );

    if (success) {
      /// Remove the rejected booking and refresh the lists.
      setState(() {
        availableBookings.removeWhere((b) => b.id == booking.id);
      });
      fetchBookings();
    }
  }

  /// ================= STATUS COLOR =================
  Color getStatusColor(String status) {
    switch (status) {
      case "assigned":
        return Colors.orange;
      case "inprogress":
        return Colors.blue;
      case "completed":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  /// ================= TITLE =================
  String getTitle(String status) {
    final loc = AppLocalizations.of(context)!;
    switch (status) {
      case "assigned":
        return loc.assigned_title;
      case "inprogress":
        return loc.inprogress_title;
      case "completed":
        return loc.completed_title;
      default:
        return loc.default_title;
    }
  }

  /// ================= ICON =================
  IconData getStatusIcon(String status) {
    switch (status) {
      case "assigned":
        return Icons.assignment;
      case "inprogress":
        return Icons.build;
      case "completed":
        return Icons.check_circle;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.white,
        appBar: CommonAppBar(
          title: loc.notifications,
        ),
      body: isLoading
          ? const NotificationShimmer()
          : RefreshIndicator(
        onRefresh: fetchBookings,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            /// TITLE
            if (isCoordinator) ...[

              /// TITLE
              Text(
                coordinatorView == 'today'
                    ? 'Today Notifications'
                    : 'Upcoming Notifications',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 14),

              /// TOGGLE BUTTONS
              Row(
                children: [

                  /// TODAY BUTTON
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          coordinatorView = 'today';
                        });

                        fetchBookings();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: coordinatorView == 'today'
                              ? Colors.black
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: coordinatorView == 'today'
                                ? Colors.black
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Today',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: coordinatorView == 'today'
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  /// UPCOMING BUTTON
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          coordinatorView = 'upcoming';
                        });

                        fetchBookings();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: coordinatorView == 'upcoming'
                              ? Colors.black
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: coordinatorView == 'upcoming'
                                ? Colors.black
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Upcoming',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: coordinatorView == 'upcoming'
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ]else ...[
              /// TITLE
              Text(
                workerView == 'today'
                    ? loc.today_notifications
                    : loc.notifAvailableBookings,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 14),

              /// TOGGLE BUTTONS (Today / Available)
              Row(
                children: [
                  Expanded(child: _workerToggle('today', loc.notifToday)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _workerToggle(
                      'claim',
                      loc.available,
                      count: availableBookings.length,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),

            /// ===== CONTENT =====
            if (isCoordinator || workerView == 'today') ...[
              /// TODAY / COORDINATOR NOTIFICATIONS
              if (bookings.isEmpty)
                _emptyState()
              else
                ...bookings.map((item) => _notificationCard(item)),
            ] else ...[
              /// CLAIM (AVAILABLE) BOOKINGS
              if (availableBookings.isEmpty)
                _claimEmptyState()
              else
                ...availableBookings.map(_availableCard),
            ],
          ],
        ),
      ),
    );
  }

  /// ================= CARD =================
  Widget _notificationCard(BookingNotificationModel item) {
    final color = getStatusColor(item.status);
    final loc = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// ICON
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              getStatusIcon(item.status),
              color: color,
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          /// CONTENT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// TITLE + STATUS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        getTitle(item.status),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        item.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    )
                  ],
                ),

                const SizedBox(height: 6),

                /// DETAILS
                Text(
                  "${loc.notifBookingNo}${item.id} ${loc.notifWith} ${item.customerName}",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),

                const SizedBox(height: 4),

                /// DATE TIME
                Text(
                  "${item.date} • ${item.time}",
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black45,
                  ),
                ),

                const SizedBox(height: 10),

                /// ACTION
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    // onTap: () {
                    //   print("Open Booking 👉 ${item.id}");
                    //   Navigator.push(
                    //     context,
                    //     MaterialPageRoute(
                    //       builder: (_) => BookingsScreen(
                    //         initialStatus: item.status,
                    //       ),
                    //     ),
                    //   );
                    //
                    // },
                    onTap: () {
                      /// Bottom nav -> Bookings tab open
                      ref.read(bottomNavIndexProvider.notifier).state = 1;

                      /// Booking tab -> correct status open
                      ref.read(bookingStatusProvider.notifier).state = item.status;

                      /// Back to MainScreen
                      Navigator.pop(context);
                    },

                    child: Text(
                      loc.view_details,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  /// ================= WORKER TOGGLE (Today / Claim) =================
  Widget _workerToggle(String value, String label, {int count = 0}) {
    final selected = workerView == value;

    return GestureDetector(
      onTap: () {
        if (workerView != value) {
          setState(() => workerView = value);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? Colors.black : Colors.grey.shade300,
          ),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : Colors.black87,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: selected ? Colors.white : Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// ================= CLAIM EMPTY STATE =================
  Widget _claimEmptyState() {
    final loc = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assignment_turned_in_outlined,
                size: 60, color: Colors.grey),
            const SizedBox(height: 10),
            Text(loc.notifNoAvailableBookings),
          ],
        ),
      ),
    );
  }

  /// ================= AVAILABLE (CLAIMABLE) CARD =================
  Widget _availableCard(AvailableBookingModel item) {
    final loc = AppLocalizations.of(context)!;
    final claiming = _claimingIds.contains(item.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// TITLE + BADGE
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.serviceName.isNotEmpty
                      ? item.serviceName
                      : loc.notifNewBooking,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  loc.notifAvailableBadge,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          /// CUSTOMER + ID
          Text(
            "${loc.notifBookingNo}${item.id} • ${item.customerName}",
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),

          const SizedBox(height: 4),

          /// DATE TIME
          Text(
            "${item.bookingDate} • ${item.timeSlot}",
            style: const TextStyle(fontSize: 11, color: Colors.black45),
          ),

          const SizedBox(height: 4),

          /// ADDRESS
          /// NOTE: Price/amount is intentionally hidden from the worker in the
          /// notification claim card (as per requirement).
          Row(
            children: [
              const Icon(Icons.location_on, size: 14, color: Colors.green),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  item.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Colors.black45),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          /// ===== ACCEPT / REJECT BUTTONS =====
          Row(
            children: [
              /// REJECT
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: OutlinedButton(
                    onPressed:
                        claiming ? null : () => _rejectBooking(item),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      loc.mbReject,
                      style: const TextStyle(
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
                    onPressed:
                        claiming ? null : () => _acceptBooking(item),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade400,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: claiming
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            loc.mbAccept,
                            style: const TextStyle(fontWeight: FontWeight.w600),
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

  /// ================= EMPTY =================
  Widget _emptyState() {
    final loc = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notifications_off, size: 60, color: Colors.grey),
          const SizedBox(height: 10),
          Text(loc.no_notifications),
        ],
      ),
    );
  }
}




class NotificationShimmer extends StatelessWidget {
  const NotificationShimmer({Key? key}) : super(key: key);

  Widget _shimmerBox({double height = 10, double width = double.infinity}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  Widget _cardShimmer() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// ICON
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),

          const SizedBox(width: 12),

          /// CONTENT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _shimmerBox(height: 12)),
                    const SizedBox(width: 10),
                    _shimmerBox(height: 10, width: 50),
                  ],
                ),
                const SizedBox(height: 8),
                _shimmerBox(height: 10, width: 180),
                const SizedBox(height: 6),
                _shimmerBox(height: 10, width: 120),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: _shimmerBox(height: 10, width: 80),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (_, __) => _cardShimmer(),
      ),
    );
  }
}