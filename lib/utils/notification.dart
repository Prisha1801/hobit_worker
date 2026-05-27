import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import '../api_services/api_services.dart';
import '../api_services/urls.dart';
import '../l10n/app_localizations.dart';
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

  // Coordinator-specific view: either 'today' or 'upcoming'
  String coordinatorView = 'today'; // 'today' or 'upcoming'

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
              Text(
                loc.today_notifications,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],

            const SizedBox(height: 12),

            /// BOOKINGS
            if (bookings.isEmpty)
              _emptyState()
            else
              ...bookings.map(
                    (item) => _notificationCard(item),
              ),
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
                  "Booking #${item.id} with ${item.customerName}",
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