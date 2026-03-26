import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hobit_worker/screens/reschedule.dart';
import '../api_services/api_services.dart';
import '../l10n/app_localizations.dart';
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
enum JobStatus { all,assigned, inProgress, completed,  subscription }
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
  bool loading = true;


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

  /// =======================
  /// UI
  /// =======================
  @override
  Widget build(BuildContext context) {
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
                _buildTab(loc.assigned, JobStatus.assigned),
                _buildTab(loc.inProgress, JobStatus.inProgress),
                _buildTab(loc.completed, JobStatus.completed),
                _buildTab(loc.subscription, JobStatus.subscription),
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
    Color chipBg;
    Color chipTextColor;
    String chipText;

    switch (booking.status) {
      case 'assigned':
        chipBg = const Color(0xFFFFF6E5);
        chipText = 'Assigned';
        chipTextColor = Colors.orange;
        break;
      case 'inprogress':
        chipBg = const Color(0xFFFFF2FD);
        chipText = 'In progress';
        chipTextColor = Colors.blue;
        break;
      case 'completed':
        chipBg = const Color(0xFFE9F8EE);
        chipText = 'Completed';
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
                    const Text(
                      'Service Requested',
                      style: TextStyle(
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
                          const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Row(
                              children: [
                                // Icon(
                                //   Icons.add_box,
                                //   size: 16,
                                //   color: Colors.black87,
                                // ),
                                // SizedBox(width: 4),
                                Text(
                                  "Addon:",
                                  style: TextStyle(
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
                              "${booking.addonNames[index]} (Qty: ${booking.addonQty[index]})",
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
                                    "Extended service (${data.extensionCount})",
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
                    const Text(
                      'Date & Time',
                      style: TextStyle(
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
                          "Start: ${booking.startDate}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ),

                    if (booking.endDate.isNotEmpty)
                      Text(
                        "End: ${booking.endDate}",
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
                  label: const Text(
                    "Reschedule History",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
