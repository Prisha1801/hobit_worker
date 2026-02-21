// import 'package:dio/dio.dart';
// import '../api_services/api_services.dart';
// import '../prefs/app_preference.dart';
// import '../prefs/preference_key.dart';
// import 'package:flutter/material.dart';
// import '../colors/appcolors.dart';
// import '../utils/app_bar.dart';
//
// class BookingModel {
//   final int id;
//   final String customerName;
//   final String serviceName;
//   final String bookingDate;
//   final String timeSlot;
//   final String address;
//   final String city;
//   final String status;
//
//   BookingModel({
//     required this.id,
//     required this.customerName,
//     required this.serviceName,
//     required this.bookingDate,
//     required this.timeSlot,
//     required this.address,
//     required this.city,
//     required this.status,
//   });
//
//   factory BookingModel.fromJson(Map<String, dynamic> json) {
//     return BookingModel(
//       id: json['id'],
//       customerName: json['customer_name'] ?? '',
//       serviceName: json['service']?['name'] ?? '',
//       bookingDate: json['booking_date'] ?? '',
//       timeSlot: json['time_slot'] ?? '',
//       address: json['address'] ?? '',
//       city: json['city'] ?? '',
//       status: json['status'] ?? '',
//     );
//   }
// }
//
//
// class BookingApi {
//   static Future<List<BookingModel>> getBookings() async {
//     final token = AppPreference().getString(PreferencesKey.token);
//
//     final res = await ApiService.getRequest(
//       '/api/worker/bookings',
//       options: Options(
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Accept': 'application/json',
//         },
//       ),
//     );
//
//     final List list = res.data['data'];
//     return list.map((e) => BookingModel.fromJson(e)).toList();
//   }
// }
//
//
// enum JobStatus { all, inProgress, completed, cancelled }
//
// class BookingsScreen extends StatefulWidget {
//   const BookingsScreen({Key? key}) : super(key: key);
//
//   @override
//   State<BookingsScreen> createState() => _BookingsScreenState();
// }
//
// class _BookingsScreenState extends State<BookingsScreen> {
//   JobStatus selectedTab = JobStatus.all;
//   List<BookingModel> bookings = [];
//   bool loading = true;
//
//
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.resumed) {
//       loadBookings(isRefresh: true);
//     }
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     loadBookings();
//   }
//
//   // Future<void> loadBookings() async {
//   //   try {
//   //     bookings = await BookingApi.getBookings();
//   //   } catch (e) {
//   //     debugPrint("Booking API error: $e");
//   //   }
//   //   setState(() => loading = false);
//   // }
//
//   Future<void> loadBookings({bool isRefresh = false}) async {
//     if (!isRefresh) {
//       setState(() => loading = true);
//     }
//
//     try {
//       bookings = await BookingApi.getBookings();
//     } catch (e) {
//       debugPrint("Booking API error: $e");
//     }
//
//     setState(() => loading = false);
//   }
//
//
//   List<BookingModel> get filteredBookings {
//     if (selectedTab == JobStatus.all) return bookings;
//
//     return bookings.where((b) {
//       switch (selectedTab) {
//         case JobStatus.inProgress:
//           return b.status == 'inprogress';
//         case JobStatus.completed:
//           return b.status == 'completed';
//         case JobStatus.cancelled:
//           return b.status == 'cancelled';
//         default:
//           return true;
//       }
//     }).toList();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: kWhite,
//       appBar: const CommonAppBar(
//         title: 'Bookings',
//         showBackButton: false,
//       ),
//       body: Column(
//         children: [
//           const SizedBox(height: 12),
//
//           /// ===== TABS =====
//           SizedBox(
//             height: 42,
//             child: ListView(
//               scrollDirection: Axis.horizontal,
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               children: [
//                 _buildTab('All Requests', JobStatus.all),
//                 _buildTab('In progress', JobStatus.inProgress),
//                 _buildTab('Completed', JobStatus.completed),
//                 _buildTab('Cancelled', JobStatus.cancelled),
//               ],
//             ),
//           ),
//
//           const SizedBox(height: 20),
//
//           /// ===== LIST =====
//           // Expanded(
//           //   child: loading
//           //       ? const Center(child: CircularProgressIndicator())
//           //       : filteredBookings.isEmpty
//           //       ? const Center(child: Text("No bookings found"))
//           //       : ListView.builder(
//           //     padding: const EdgeInsets.symmetric(horizontal: 16),
//           //     itemCount: filteredBookings.length,
//           //     itemBuilder: (context, index) {
//           //       return Padding(
//           //         padding: const EdgeInsets.only(bottom: 12),
//           //         child: _jobCard(filteredBookings[index]),
//           //       );
//           //     },
//           //   ),
//           // ),
//           Expanded(
//             child: RefreshIndicator(
//               color: kkblack,
//               onRefresh: () => loadBookings(isRefresh: true),
//               child: loading
//                   ? ListView(
//                 children: const [
//                   SizedBox(height: 200),
//                   Center(child: CircularProgressIndicator()),
//                 ],
//               )
//                   : filteredBookings.isEmpty
//                   ? ListView(
//                 children: const [
//                   SizedBox(height: 200),
//                   Center(child: Text("No bookings found")),
//                 ],
//               )
//                   : ListView.builder(
//                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                 itemCount: filteredBookings.length,
//                 itemBuilder: (context, index) {
//                   return Padding(
//                     padding: const EdgeInsets.only(bottom: 12),
//                     child: _jobCard(filteredBookings[index]),
//                   );
//                 },
//               ),
//             ),
//           ),
//
//         ],
//       ),
//     );
//   }
//
//   Widget _buildTab(String title, JobStatus status) {
//     final isSelected = selectedTab == status;
//
//     return Padding(
//       padding: const EdgeInsets.only(right: 12),
//       child: GestureDetector(
//         onTap: () => setState(() => selectedTab = status),
//         child: Container(
//           padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
//           decoration: BoxDecoration(
//             color: isSelected ? kkblack : kWhite,
//             borderRadius: BorderRadius.circular(24),
//             border: Border.all(
//               color: isSelected ? kkblack : Colors.grey.shade300,
//             ),
//           ),
//           child: Text(
//             title,
//             style: TextStyle(
//               fontSize: 13,
//               fontWeight: FontWeight.w600,
//               color: isSelected ? Colors.white : Colors.black54,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _jobCard(BookingModel booking) {
//     Color chipBg;
//     Color chipTextColor;
//     String chipText;
//
//     switch (booking.status) {
//       case 'inprogress':
//         chipBg = const Color(0xFFFFF2FD);
//         chipText = 'In progress';
//         chipTextColor = Colors.blue;
//         break;
//       case 'completed':
//         chipBg = const Color(0xFFE9F8EE);
//         chipText = 'Completed';
//         chipTextColor = Colors.green;
//         break;
//       case 'cancelled':
//         chipBg = const Color(0xFFFFEDED);
//         chipText = 'Cancelled';
//         chipTextColor = Colors.red;
//         break;
//       default:
//         chipBg = const Color(0xFFF3F3F3);
//         chipText = 'Assigned';
//         chipTextColor = Colors.orange;
//     }
//
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: kWhite,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: const [
//           BoxShadow(
//             color: Color(0x0D000000),
//             offset: Offset(0, 4),
//             blurRadius: 4,
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           /// TOP ROW
//           Row(
//             children: [
//               const CircleAvatar(radius: 20, child: Icon(Icons.person)),
//               const SizedBox(width: 10),
//               Expanded(
//                 child: Text(
//                   booking.customerName,
//                   style: const TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ),
//               Container(
//                 padding:
//                 const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: chipBg,
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Text(
//                   chipText,
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: chipTextColor,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//
//           const SizedBox(height: 12),
//
//           /// SERVICE + DATE/TIME
//           Row(
//             children: [
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Service Requested',
//                       style:
//                       TextStyle(fontSize: 12, color: Colors.black54),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       booking.serviceName,
//                       style: const TextStyle(
//                           fontSize: 14, fontWeight: FontWeight.w600),
//                     ),
//                   ],
//                 ),
//               ),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.end,
//                   children: [
//                     Text(
//                       booking.bookingDate,
//                       style: const TextStyle(fontSize: 13),
//                     ),
//                     Text(
//                       booking.timeSlot,
//                       style: const TextStyle(
//                           fontSize: 12, color: Colors.black54),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//
//           const SizedBox(height: 10),
//           const Divider(),
//
//           /// LOCATION
//           Row(
//             children: [
//               const Icon(Icons.location_on,
//                   size: 16, color: Colors.green),
//               const SizedBox(width: 6),
//               Expanded(
//                 child: Text("${booking.address}, ${booking.city}"),
//               ),
//               const Text('Booking ID - '),
//               Text(
//                 "BK-${booking.id}",
//                 style: const TextStyle(fontWeight: FontWeight.w600),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
//

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../api_services/api_services.dart';
import '../l10n/app_localizations.dart';
import '../prefs/app_preference.dart';
import '../prefs/preference_key.dart';
import '../colors/appcolors.dart';
import '../utils/app_bar.dart';

/// MODEL
class BookingModel {
  final int id;
  final String customerName;
  final String serviceName;
  final String bookingDate;
  final String timeSlot;
  final String address;
  final String city;
  final String status;

  BookingModel({
    required this.id,
    required this.customerName,
    required this.serviceName,
    required this.bookingDate,
    required this.timeSlot,
    required this.address,
    required this.city,
    required this.status,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'],
      customerName: json['customer_name'] ?? '',
      serviceName: json['service']?['name'] ?? '',
      bookingDate: json['booking_date'] ?? '',
      timeSlot: json['time_slot'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      status: json['status'] ?? '',
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
}
/// STATUS ENUM
enum JobStatus { all,assigned, inProgress, completed, cancelled }
/// SCREEN
class BookingsScreen extends StatefulWidget {
  const BookingsScreen({Key? key}) : super(key: key);

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen>
    with WidgetsBindingObserver {
  JobStatus selectedTab = JobStatus.all;
  List<BookingModel> bookings = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    loadBookings();
  }

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
        case JobStatus.inProgress:
          status = 'inprogress';
          break;
        case JobStatus.completed:
          status = 'completed';
          break;
        case JobStatus.cancelled:
          status = 'cancelled';
          break;
        case JobStatus.all:
          status = null;
          break;
      }

      bookings = await BookingApi.getBookings(status: status);
    } catch (e) {
      debugPrint("Booking API error: $e");
    }

    setState(() => loading = false);
  }

  /// =======================
  /// UI
  /// =======================
  @override
  Widget build(BuildContext context) {
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
                _buildTab(loc.cancelled, JobStatus.cancelled),
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

    // switch (booking.status) {
    //   case 'inprogress':
    //     chipBg = const Color(0xFFFFF2FD);
    //     chipText = 'In progress';
    //     chipTextColor = Colors.blue;
    //     break;
    //   case 'completed':
    //     chipBg = const Color(0xFFE9F8EE);
    //     chipText = 'Completed';
    //     chipTextColor = Colors.green;
    //     break;
    //   case 'cancelled':
    //     chipBg = const Color(0xFFFFEDED);
    //     chipText = 'Cancelled';
    //     chipTextColor = Colors.red;
    //     break;
    //   default:
    //     chipBg = const Color(0xFFF3F3F3);
    //     chipText = 'Assigned';
    //     chipTextColor = Colors.orange;
    // }
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
      case 'cancelled':
        chipBg = const Color(0xFFFFEDED);
        chipText = 'Cancelled';
        chipTextColor = Colors.red;
        break;
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
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Service Requested',
                      style: TextStyle(
                          fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.serviceName,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      booking.bookingDate,
                      style: const TextStyle(fontSize: 13),
                    ),
                    Text(
                      booking.timeSlot,
                      style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54),
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
              const Text('Booking ID - '),
              Text(
                "BK-${booking.id}",
                style:
                const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
