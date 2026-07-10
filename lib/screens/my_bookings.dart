import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hobit_worker/screens/reschedule.dart';
import '../api_services/api_services.dart';
import '../api_services/urls.dart';
import '../l10n/app_localizations.dart';
import '../models/available_booking_model.dart';
import '../models/extend_service_model.dart';
import '../prefs/app_preference.dart';
import '../prefs/preference_key.dart';
import '../colors/appcolors.dart';
import '../utils/app_bar.dart';
import '../utils/extension_history.dart';
final bookingStatusProvider = StateProvider<String?>((ref) => null);
/// MODEL
class BookingModel {
  final int id;
  final String customerName;
  final String serviceName;
  final String bookingDate;
  final String timeSlot;
  final String subscriptionName;
  final String address;
  final String city;
  final String status;

  final String startDate;   // NEW
  final String endDate;     //
  final List<String> addonNames;
  final List<int> addonQty;
  final String acceptanceStatus; // pending | accepted | declined

  BookingModel({
    required this.id,
    required this.customerName,
    required this.serviceName,
    required this.bookingDate,
    required this.timeSlot,
    required this.subscriptionName,
    required this.address,
    required this.city,
    required this.status,

    required this.startDate,
    required this.endDate,

    required this.addonNames,
    required this.addonQty,
    required this.acceptanceStatus,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    List services = json['services'] ?? [];
    List<String> addonNames = [];
    List<int> addonQty = [];

    for (var s in services) {
      if (s['is_addon'] == true) {
        addonNames.add(s['addon_name'] ?? '');
        addonQty.add(s['addon_qty'] ?? 0);
      }
    }

    return BookingModel(
      id: json['id'],
      customerName: json['customer_name'] ?? '',
      serviceName: json['service']?['name'] ?? '',
      bookingDate: json['booking_date'] ?? '',
      timeSlot: json['time_slot'] ?? '',
      subscriptionName: json['service']?['subscription']?['name'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      status: json['status'] ?? '',

      startDate: json['start_date'] ?? '',   // NEW
      endDate: json['end_date'] ?? '', // NEW
      addonNames: addonNames,
      addonQty: addonQty,
      acceptanceStatus: json['acceptance_status']?.toString() ?? '',
    );
  }
}

class RescheduleHistoryModel {
  final int rescheduleCount;

  RescheduleHistoryModel({
    required this.rescheduleCount,
  });

  factory RescheduleHistoryModel.fromJson(Map<String, dynamic> json) {
    return RescheduleHistoryModel(
      rescheduleCount: json['reschedule_count'] ?? 0,
    );
  }
}

/// API
class BookingApi {
  static Future<List<BookingModel>> getBookings({String? status}) async {
    final token = AppPreference().getString(PreferencesKey.token);

    final res = await ApiService.getRequest(
      '/api/worker/bookings',
      queryParameters: status != null ? {'status': status} : null,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ),
    );

    final List list = res.data['data'];
    return list.map((e) => BookingModel.fromJson(e)).toList();
  }

  /// GET /api/worker/available-bookings — unclaimed bookings the worker can claim
  static Future<List<AvailableBookingModel>> getAvailableBookings() async {
    final token = AppPreference().getString(PreferencesKey.token);

    final res = await ApiService.getRequest(
      availableBookingsUrl,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ),
    );

    final List list = res.data['data'] ?? [];
    return list.map((e) => AvailableBookingModel.fromJson(e)).toList();
  }

  /// POST /api/worker/bookingrequest/{id}/claim
  static Future<Map<String, dynamic>> claimBooking(
      int bookingId, AppLocalizations loc) async {
    try {
      final token = AppPreference().getString(PreferencesKey.token);

      final res = await ApiService.postRequest(
        claimBookingUrl(bookingId),
        {},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      return {
        'success': res.data['success'] == true,
        'message': res.data['message']?.toString() ?? '',
        'booking_id': res.data['booking_id'],
        'status': res.data['status']?.toString() ?? '',
        'acceptance_status': res.data['acceptance_status']?.toString() ?? '',
      };
    } catch (e) {
      debugPrint("Claim booking error: $e");
      return {'success': false, 'message': loc.somethingWentWrong};
    }
  }

  /// POST /api/worker/bookingrequest/{id}/reject — reject an available booking.
  static Future<Map<String, dynamic>> rejectBooking(
      int bookingId, AppLocalizations loc) async {
    try {
      final token = AppPreference().getString(PreferencesKey.token);

      final res = await ApiService.postRequest(
        rejectBookingUrl(bookingId),
        {},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      return {
        'success': res.data['success'] == true,
        'message': res.data['message']?.toString() ?? '',
        'booking_id': res.data['booking_id'],
        'status': res.data['status']?.toString() ?? '',
        'acceptance_status': res.data['acceptance_status']?.toString() ?? '',
      };
    } catch (e) {
      debugPrint("Reject booking error: $e");
      return {'success': false, 'message': loc.somethingWentWrong};
    }
  }

  // NOTE: Old assigned-booking Accept / Decline API integration disabled as per
  // backend developer's request (accept/decline API not to be integrated).
  /*
  /// POST /api/worker/bookingrequest/{id}/accept
  static Future<Map<String, dynamic>> acceptBooking(int bookingId) async {
    try {
      final token = AppPreference().getString(PreferencesKey.token);

      final res = await ApiService.postRequest(
        '/api/worker/bookingrequest/$bookingId/accept',
        {},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      return {
        'success': res.data['success'] == true,
        'message': res.data['message']?.toString() ?? '',
        'acceptance_status': res.data['acceptance_status']?.toString() ?? '',
      };
    } catch (e) {
      debugPrint("Accept booking error: $e");
      return {'success': false, 'message': 'Something went wrong'};
    }
  }

  /// POST /api/worker/bookingrequest/{id}/decline   body(optional): { "reason": ".." }
  static Future<Map<String, dynamic>> declineBooking(
    int bookingId, {
    String? reason,
  }) async {
    try {
      final token = AppPreference().getString(PreferencesKey.token);

      final res = await ApiService.postRequest(
        '/api/worker/bookingrequest/$bookingId/decline',
        (reason != null && reason.trim().isNotEmpty)
            ? {'reason': reason.trim()}
            : {},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      return {
        'success': res.data['success'] == true,
        'message': res.data['message']?.toString() ?? '',
        'acceptance_status': res.data['acceptance_status']?.toString() ?? '',
      };
    } catch (e) {
      debugPrint("Decline booking error: $e");
      return {'success': false, 'message': 'Something went wrong'};
    }
  }
  */

  static Future<RescheduleHistoryModel?> getRescheduleHistory(int bookingId) async {
    try {
      final token = AppPreference().getString(PreferencesKey.token);

      final res = await ApiService.getRequest(
        '/api/customer/bookings/$bookingId/reschedule-history',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      return RescheduleHistoryModel.fromJson(res.data['data']);
    } catch (e) {
      debugPrint("Reschedule API error: $e");
      return null;
    }
  }
  static Future<BookingExtensionResponse?> getBookingExtensions(int bookingId) async {
    try {
      final token = AppPreference().getString(PreferencesKey.token);

      final res = await ApiService.getRequest(
        "/api/instant-bookings/$bookingId/extensions",
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Accept": "application/json",
          },
        ),
      );

      return BookingExtensionResponse.fromJson(res.data);

    } catch (e) {
      debugPrint("Extension API error: $e");
      return null;
    }
  }

  static Future<int?> getBookingRating(int bookingId) async {
    try {
      final token = AppPreference().getString(PreferencesKey.token);
      final workerId = AppPreference().getString(PreferencesKey.userId);

      final res = await ApiService.getRequest(
        "/api/workers/$workerId/ratings",
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Accept": "application/json",
          },
        ),
      );

      final List ratings = res.data['ratings']['data'];

      final rating = ratings.firstWhere(
            (e) => e['booking_id'] == bookingId,
        orElse: () => null,
      );

      if (rating == null) return null;

      return rating['rating'];
    } catch (e) {
      debugPrint("Rating API error: $e");
      return null;
    }
  }

}
/// STATUS ENUM
enum JobStatus { all, available, assigned, inProgress, completed,  subscription, rescheduled }
/// SCREEN
// class BookingsScreen extends StatefulWidget {
//   final String? initialStatus;
//   const BookingsScreen({Key? key, this.initialStatus}) : super(key: key);
//
//   @override
//   State<BookingsScreen> createState() => _BookingsScreenState();
// }

class BookingsScreen extends ConsumerStatefulWidget {
  final String? initialStatus;

  const BookingsScreen({Key? key, this.initialStatus}) : super(key: key);

  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

// class _BookingsScreenState extends State<BookingsScreen>
class _BookingsScreenState extends ConsumerState<BookingsScreen>
    with WidgetsBindingObserver {
  JobStatus selectedTab = JobStatus.all;
  List<BookingModel> bookings = [];

  /// Unclaimed bookings shown under the "Available" tab.
  List<AvailableBookingModel> availableBookings = [];

  bool loading = true;
  bool isFirstLoad = true;

  /// Booking ids currently being accepted/declined/claimed (for per-card spinner).
  final Set<int> _processingIds = {};


  // @override
  // void initState() {
  //   super.initState();
  //   WidgetsBinding.instance.addObserver(this);
  //
  //   final status = ref.read(bookingStatusProvider);
  //
  //   if (status != null) {
  //     switch (status) {
  //       case "assigned":
  //         selectedTab = JobStatus.assigned;
  //         break;
  //       case "inprogress":
  //         selectedTab = JobStatus.inProgress;
  //         break;
  //       case "completed":
  //         selectedTab = JobStatus.completed;
  //         break;
  //       default:
  //         selectedTab = JobStatus.all;
  //     }
  //   }
  //
  //   loadBookings();
  // }
  // void initState() {
  //   super.initState();
  //   WidgetsBinding.instance.addObserver(this);
  //
  //   if (widget.initialStatus != null) {
  //     switch (widget.initialStatus) {
  //       case "assigned":
  //         selectedTab = JobStatus.assigned;
  //         break;
  //       case "inprogress":
  //         selectedTab = JobStatus.inProgress;
  //         break;
  //       case "completed":
  //         selectedTab = JobStatus.completed;
  //         break;
  //       default:
  //         selectedTab = JobStatus.all;
  //     }
  //   }
  //   loadBookings();
  // }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      loadBookings(isRefresh: true);
    }
  }

  /// =======================
  /// LOAD BOOKINGS
  /// =======================
  Future<void> loadBookings({bool isRefresh = false}) async {
    if (!isRefresh) {
      setState(() => loading = true);
    }

    try {
      /// Available (unclaimed) bookings use a separate endpoint.
      if (selectedTab == JobStatus.available) {
        availableBookings = await BookingApi.getAvailableBookings();
        setState(() => loading = false);
        return;
      }

      String? status;

      switch (selectedTab) {
        case JobStatus.assigned:
          status = 'assigned';
          break;

        case JobStatus.inProgress:
          status = 'inprogress';
          break;

        case JobStatus.completed:
          status = 'completed';
          break;

        case JobStatus.subscription:
          status = null;
          break;

        case JobStatus.rescheduled:
          status = 'rescheduled';
          break;

        case JobStatus.available:
        case JobStatus.all:
          status = null;
          break;
      }

      final data = await BookingApi.getBookings(status: status);

      /// 👇 subscription filter
      if (selectedTab == JobStatus.subscription) {
        bookings = data.where((b) =>
        b.subscriptionName.toLowerCase() == "monthly subscription"
        ).toList();
      } else {
        bookings = data;
      }

    } catch (e) {
      debugPrint("Booking API error: $e");
    }

    setState(() => loading = false);
  }

  /// =======================
  /// ACCEPT / DECLINE
  /// =======================
  // NOTE: Accept / Decline flow disabled as per backend developer's request
  // (accept/decline API not to be integrated).
  /*
  Future<void> _acceptBooking(BookingModel booking) async {
    setState(() => _processingIds.add(booking.id));

    final result = await BookingApi.acceptBooking(booking.id);

    if (!mounted) return;
    setState(() => _processingIds.remove(booking.id));

    _showActionSnack(
      result,
      successFallback: 'Booking accepted.',
      failFallback: 'Failed to accept booking.',
    );

    if (result['success'] == true) {
      loadBookings(isRefresh: true);
    }
  }

  Future<void> _declineBooking(BookingModel booking) async {
    final reason = await _askDeclineReason();
    if (reason == null) return; // user cancelled the dialog

    setState(() => _processingIds.add(booking.id));

    final result = await BookingApi.declineBooking(booking.id, reason: reason);

    if (!mounted) return;
    setState(() => _processingIds.remove(booking.id));

    _showActionSnack(
      result,
      successFallback: 'Booking declined.',
      failFallback: 'Failed to decline booking.',
    );

    if (result['success'] == true) {
      loadBookings(isRefresh: true);
    }
  }
  */

  /// =======================
  /// ACCEPT / REJECT (available bookings — replaces the old Claim flow)
  /// =======================
  Future<void> _acceptAvailableBooking(AvailableBookingModel booking) async {
    final loc = AppLocalizations.of(context)!;
    setState(() => _processingIds.add(booking.id));

    // Accept uses the existing claim API — only the button text differs.
    final result = await BookingApi.claimBooking(booking.id, loc);

    if (!mounted) return;
    setState(() => _processingIds.remove(booking.id));

    _showActionSnack(
      result,
      successFallback: loc.mbBookingAccepted,
      failFallback: loc.mbFailedAccept,
    );

    if (result['success'] == true) {
      /// Accepted bookings move to "Assigned" — jump there and reload.
      setState(() => selectedTab = JobStatus.assigned);
      loadBookings(isRefresh: true);
    }
  }

  Future<void> _rejectAvailableBooking(AvailableBookingModel booking) async {
    final loc = AppLocalizations.of(context)!;
    setState(() => _processingIds.add(booking.id));

    final result = await BookingApi.rejectBooking(booking.id, loc);

    if (!mounted) return;
    setState(() => _processingIds.remove(booking.id));

    _showActionSnack(
      result,
      successFallback: loc.mbBookingRejected,
      failFallback: loc.mbFailedReject,
    );

    if (result['success'] == true) {
      /// Rejected bookings drop out of the available list — just reload.
      loadBookings(isRefresh: true);
    }
  }

  /// =======================
  /// CLAIM (disabled — replaced by Accept / Reject on available bookings)
  /// =======================
  /*
  Future<void> _claimBooking(AvailableBookingModel booking) async {
    setState(() => _processingIds.add(booking.id));

    final result = await BookingApi.claimBooking(booking.id);

    if (!mounted) return;
    setState(() => _processingIds.remove(booking.id));

    _showActionSnack(
      result,
      successFallback: 'Booking claimed.',
      failFallback: 'Failed to claim booking.',
    );

    if (result['success'] == true) {
      /// Claimed bookings move to "Assigned" — jump there and reload.
      setState(() => selectedTab = JobStatus.assigned);
      loadBookings(isRefresh: true);
    }
  }
  */

  void _showActionSnack(
    Map<String, dynamic> result, {
    required String successFallback,
    required String failFallback,
  }) {
    final success = result['success'] == true;
    final msg = (result['message']?.toString().isNotEmpty == true)
        ? result['message'].toString()
        : (success ? successFallback : failFallback);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? kGreen : Colors.red,
      ),
    );
  }

  /// Optional reason dialog before declining. Returns the reason (may be empty)
  /// or null if the worker cancelled.
  // NOTE: Accept / Decline flow disabled as per backend developer's request
  // (accept/decline API not to be integrated).
  /*
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
            onPressed: () => Navigator.pop(ctx), // null = cancel
            child: const Text('Cancel',
                style: TextStyle(color: Colors.black54)),
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

  // Future<void> loadBookings({bool isRefresh = false}) async {
  //   if (!isRefresh) {
  //     setState(() => loading = true);
  //   }
  //
  //   try {
  //     String? status;
  //
  //     switch (selectedTab) {
  //       case JobStatus.assigned:
  //         status = 'assigned';
  //       case JobStatus.inProgress:
  //         status = 'inprogress';
  //         break;
  //       case JobStatus.completed:
  //         status = 'completed';
  //         break;
  //
  //         break;
  //       case JobStatus.all:
  //         status = null;
  //         break;
  //     }
  //
  //     bookings = await BookingApi.getBookings(status: status);
  //
  //
  //     if (selectedTab == JobStatus.subscription) {
  //       bookings = data.where((b) =>
  //       b.subscriptionName.toLowerCase() == "monthly subscription"
  //       ).toList();
  //     } else {
  //       bookings = data;
  //     }
  //
  //
  //   } catch (e) {
  //     debugPrint("Booking API error: $e");
  //   }
  //
  //   setState(() => loading = false);
  // }


  /// UI
  @override
  Widget build(BuildContext context) {

    if (isFirstLoad) {
      isFirstLoad = false;
      Future.microtask(() => loadBookings());
    }
    ref.listen<String?>(bookingStatusProvider, (previous, next) {
      if (next != null) {
        setState(() {
          switch (next) {
            case "assigned":
              selectedTab = JobStatus.assigned;
              break;
            case "inprogress":
              selectedTab = JobStatus.inProgress;
              break;
            case "completed":
              selectedTab = JobStatus.completed;
              break;
            default:
              selectedTab = JobStatus.all;
          }
        });

        /// 🔥 reload bookings
        loadBookings();

        /// 🔥 reset
        ref.read(bookingStatusProvider.notifier).state = null;
      }
    });
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: kWhite,
      appBar: CommonAppBar(
        title: loc.bookings,
        showBackButton: false,
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),

          /// ===== TABS =====
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildTab(loc.allRequests, JobStatus.all),
                _buildTab(loc.available, JobStatus.available),
                _buildTab(loc.assigned, JobStatus.assigned),
                _buildTab(loc.inProgress, JobStatus.inProgress),
                _buildTab(loc.completed, JobStatus.completed),
                _buildTab(loc.subscription, JobStatus.subscription),
                _buildTab(loc.rescheduled, JobStatus.rescheduled),
               // _buildTab(loc.cancelled, JobStatus.cancelled),
              ],
            ),
          ),

          const SizedBox(height: 20),

          /// ===== LIST =====
          Expanded(
            child: RefreshIndicator(
              color: kkblack,
              onRefresh: () => loadBookings(isRefresh: true),
              child: loading
                  ? ListView(
                children: const [
                  SizedBox(height: 200),
                  Center(child: CircularProgressIndicator()),
                ],
              )
                  : selectedTab == JobStatus.available
                  ? (availableBookings.isEmpty
                  ? ListView(
                children: [
                  const SizedBox(height: 200),
                  Center(child: Text(loc.noBookingsFound)),
                ],
              )
                  : ListView.builder(
                padding:
                const EdgeInsets.symmetric(horizontal: 16),
                itemCount: availableBookings.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding:
                    const EdgeInsets.only(bottom: 12),
                    child: _availableCard(availableBookings[index]),
                  );
                },
              ))
                  : bookings.isEmpty
                  ? ListView(
                children: [
                  const SizedBox(height: 200),
                  Center(child: Text(loc.noBookingsFound)),
                ],
              )
                  : ListView.builder(
                padding:
                const EdgeInsets.symmetric(horizontal: 16),
                itemCount: bookings.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding:
                    const EdgeInsets.only(bottom: 12),
                    child: _jobCard(bookings[index]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// =======================
  /// TAB WIDGET
  /// =======================
  Widget _buildTab(String title, JobStatus status) {
    final isSelected = selectedTab == status;

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () {
          setState(() => selectedTab = status);
          loadBookings();
        },
        child: Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? kkblack : kWhite,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? kkblack : Colors.grey.shade300,
            ),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }

  /// =======================
  /// BOOKING CARD
  /// =======================
  Widget _jobCard(BookingModel booking) {
    final loc = AppLocalizations.of(context)!;
    Color chipBg;
    Color chipTextColor;
    String chipText;

    switch (booking.status) {
      case 'assigned':
        chipBg = const Color(0xFFFFF6E5);
        chipText = loc.assigned;
        chipTextColor = Colors.orange;
        break;
      case 'inprogress':
        chipBg = const Color(0xFFFFF2FD);
        chipText = loc.inProgress;
        chipTextColor = Colors.blue;
        break;
      case 'completed':
        chipBg = const Color(0xFFE9F8EE);
        chipText = loc.completed;
        chipTextColor = Colors.green;
        break;
      // case 'cancelled':
      //   chipBg = const Color(0xFFFFEDED);
      //   chipText = 'Cancelled';
      //   chipTextColor = Colors.red;
      //   break;
      default:
        chipBg = const Color(0xFFF3F3F3);
        chipText = booking.status;
        chipTextColor = Colors.black;
    }


    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
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
          /// TOP ROW
          Row(
            children: [
              const CircleAvatar(radius: 20, child: Icon(Icons.person)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  booking.customerName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: chipBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  chipText,
                  style: TextStyle(
                    fontSize: 12,
                    color: chipTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          /// SERVICE + DATE/TIME
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// LEFT SIDE
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.serviceRequested,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.serviceName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (booking.addonNames.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          /// ADDON TITLE WITH ICON
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              children: [
                                // Icon(
                                //   Icons.add_box,
                                //   size: 16,
                                //   color: Colors.black87,
                                // ),
                                // SizedBox(width: 4),
                                Text(
                                  loc.mbAddon,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 4),

                          /// ADDON LIST
                          ...List.generate(
                            booking.addonNames.length,
                                (index) => Text(
                              "${booking.addonNames[index]} (${loc.mbQty}: ${booking.addonQty[index]})",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),

                    // if (booking.subscriptionName.isNotEmpty)
                    //   Container(
                    //     margin: const EdgeInsets.only(top: 4),
                    //     padding: const EdgeInsets.symmetric(
                    //       horizontal: 8,
                    //       vertical: 3,
                    //     ),
                    //     decoration: BoxDecoration(
                    //       color: Colors.blue.withOpacity(0.1),
                    //       borderRadius: BorderRadius.circular(12),
                    //     ),
                    //     child: Text(
                    //       booking.subscriptionName,
                    //       style: const TextStyle(
                    //         fontSize: 11,
                    //         fontWeight: FontWeight.w600,
                    //         color: Colors.blue,
                    //       ),
                    //     ),
                    //   ),

                    if (booking.subscriptionName.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              booking.subscriptionName,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue,
                              ),
                            ),
                          ),

                          const SizedBox(height: 4),

                          /// EXTENSION BUTTON
                          FutureBuilder<BookingExtensionResponse?>(
                            future: BookingApi.getBookingExtensions(booking.id),
                            builder: (context, snapshot) {

                              if (!snapshot.hasData) {
                                return const SizedBox();
                              }

                              final data = snapshot.data!;

                              if (data.extensionCount == 0) {
                                return const SizedBox();
                              }

                              return GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => ExtensionHistoryDialog(
                                      bookingId: booking.id,
                                    ),
                                  );
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    "${loc.mbExtendedService} (${data.extensionCount})",
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              /// RIGHT SIDE
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      loc.dateTime,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Text(
                    //   booking.bookingDate,
                    //   style: const TextStyle(
                    //     fontSize: 13,
                    //     fontWeight: FontWeight.w500,
                    //   ),
                    // ),
                    if (booking.startDate.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          "${loc.mbStart}: ${booking.startDate}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ),

                    if (booking.endDate.isNotEmpty)
                      Text(
                        "${loc.mbEnd}: ${booking.endDate}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      booking.timeSlot,
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

          const SizedBox(height: 10),
          const Divider(),
          /// LOCATION
          Row(
            children: [
              const Icon(Icons.location_on,
                  size: 16, color: Colors.green),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                    "${booking.address}, ${booking.city}"),
              ),
              //const Text('Booking ID - '),
              // Text(
              //   "BK-${booking.id}",
              //   style:
              //   const TextStyle(fontWeight: FontWeight.w600),
              // ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "BK-${booking.id}",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 4),

                  /// ⭐ RATING STARS
                  FutureBuilder<int?>(
                    future: BookingApi.getBookingRating(booking.id),
                    builder: (context, snapshot) {

                      if (!snapshot.hasData) {
                        return const SizedBox();
                      }

                      final rating = snapshot.data!;

                      if (rating == null || rating == 0) {
                        return const SizedBox();
                      }

                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          5,
                              (index) => Icon(
                            index < rating ? Icons.star : Icons.star_border,
                            size: 16,
                            color: Colors.orange,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              )
            ],
          ),
          FutureBuilder<RescheduleHistoryModel?>(
            future: BookingApi.getRescheduleHistory(booking.id),
            builder: (context, snapshot) {

              if (!snapshot.hasData) {
                return const SizedBox();
              }

              final data = snapshot.data as RescheduleHistoryModel;

              if (data.rescheduleCount == 0) {
                return const SizedBox();
              }

              return Align(
                alignment: Alignment.center,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:kkblack,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => RescheduleHistoryDialog(
                        bookingId: booking.id,
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.history,
                    size: 16,
                  ),
                  label: Text(
                    loc.mbRescheduleHistory,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white
                    ),
                  ),
                ),
              );
            },
          ),

          /// ===== ACCEPT / DECLINE (only for assigned bookings) =====
          // NOTE: Accept / Decline flow disabled as per backend developer's
          // request (accept/decline API not to be integrated). This also
          // removes the "You accepted/declined this booking" status label.
          // if (booking.status == 'assigned') _buildAcceptDecline(booking),
        ],
      ),
    );
  }

  /// =======================
  /// AVAILABLE (CLAIMABLE) CARD
  /// =======================
  Widget _availableCard(AvailableBookingModel booking) {
    final loc = AppLocalizations.of(context)!;
    final processing = _processingIds.contains(booking.id);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
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
          /// TOP ROW
          Row(
            children: [
              const CircleAvatar(radius: 20, child: Icon(Icons.person)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  booking.customerName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F8EE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  loc.available,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          /// SERVICE + DATE/TIME
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.serviceRequested,
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.serviceName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    // NOTE: Price is intentionally hidden from the worker in
                    // the available bookings card (as per requirement).
                    // if (booking.amount.isNotEmpty)
                    //   Padding(
                    //     padding: const EdgeInsets.only(top: 4),
                    //     child: Text(
                    //       "₹${booking.amount}",
                    //       style: const TextStyle(
                    //         fontSize: 13,
                    //         fontWeight: FontWeight.w600,
                    //         color: Colors.black87,
                    //       ),
                    //     ),
                    //   ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      loc.dateTime,
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.bookingDate,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      booking.timeSlot,
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

          const SizedBox(height: 10),
          const Divider(),

          /// LOCATION + ID
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.green),
              const SizedBox(width: 6),
              Expanded(child: Text(booking.address)),
              Text(
                "BK-${booking.id}",
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),

          /// ===== ACCEPT / REJECT BUTTONS =====
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Row(
              children: [
                /// REJECT
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: processing
                          ? null
                          : () => _rejectAvailableBooking(booking),
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
                    height: 44,
                    child: ElevatedButton(
                      onPressed: processing
                          ? null
                          : () => _acceptAvailableBooking(booking),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kGreen,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade400,
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
                          : Text(
                              loc.mbAccept,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// =======================
  /// ACCEPT / DECLINE WIDGET
  /// =======================
  // NOTE: Accept / Decline flow disabled as per backend developer's request
  // (accept/decline API not to be integrated).
  /*
  Widget _buildAcceptDecline(BookingModel booking) {
    final processing = _processingIds.contains(booking.id);
    final st = booking.acceptanceStatus.toLowerCase();

    /// Already accepted → status label
    if (st == 'accepted') {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: kGreen, size: 18),
            const SizedBox(width: 6),
            Text(
              'You accepted this booking',
              style: TextStyle(
                color: kGreen,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    /// Already declined → status label
    if (st == 'declined') {
      return const Padding(
        padding: EdgeInsets.only(top: 12),
        child: Row(
          children: [
            Icon(Icons.cancel, color: Colors.red, size: 18),
            SizedBox(width: 6),
            Text(
              'You declined this booking',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    /// Pending → Accept + Decline buttons
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        children: [
          /// DECLINE
          Expanded(
            child: SizedBox(
              height: 42,
              child: OutlinedButton(
                onPressed: processing ? null : () => _declineBooking(booking),
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
                onPressed: processing ? null : () => _acceptBooking(booking),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kGreen,
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
      ),
    );
  }
  */
}
