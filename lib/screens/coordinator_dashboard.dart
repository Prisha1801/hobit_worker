import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:hobit_worker/colors/appcolors.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api_services/api_services.dart';
import '../api_services/location_service.dart';
import '../api_services/urls.dart';
import '../models/coordinator_booking_model.dart';
import '../models/available_worker_model.dart' as worker_model;
import '../models/subscription_type_model.dart';
import '../prefs/app_preference.dart';
import '../prefs/preference_key.dart';
import '../utils/appBar_for_home.dart';
import '../auth/fcm_service.dart';
import '../auth/logout.dart';
import '../widgets/booking_repo_home.dart';
import '../widgets/sos_widget.dart';

class CoordinatorDashboard extends ConsumerStatefulWidget {
  const CoordinatorDashboard({super.key});

  @override
  ConsumerState<CoordinatorDashboard> createState() =>
      _CoordinatorDashboardState();
}

class _CoordinatorDashboardState extends ConsumerState<CoordinatorDashboard>
    with SosMixin<CoordinatorDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String selectedFilter = "All";
  bool isLoading = false;
  CoordinatorBookingResponse? bookingResponse;
  int currentPage = 1;
  List<CoordinatorInfo> coordinators = [];

  List<SubscriptionType> subscriptionTypes = [];
  int? selectedSubscriptionId;
  DateTime? startDate;
  DateTime? endDate;

  // Search for main dashboard
  final TextEditingController _dashboardSearchController =
  TextEditingController();
  String _dashboardSearchQuery = "";

  @override
  void initState() {
    super.initState();
    fetchSubscriptionTypes();
    fetchBookings(currentPage);
    fetchCoordinators();
    // ✅ Listen for new bookings to show popup
    FCMService.newBookingNotifier.addListener(_onNewBookingArrived);
  }

  @override
  void dispose() {
    FCMService.newBookingNotifier.removeListener(_onNewBookingArrived);
    _dashboardSearchController.dispose();
    super.dispose();
  }

  void _onNewBookingArrived() {
    final data = FCMService.newBookingNotifier.value;
    if (data != null && mounted) {
      _showNewBookingPopup(data);
      FCMService.newBookingNotifier.value = null; // reset
    }
  }

  void _showNewBookingPopup(Map<String, dynamic> data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_active_outlined,
                  size: 40,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "New Booking #${data['booking_id'] ?? 'N/A'}",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                data['body'] ?? "A new booking request has arrived.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, fontSize: 14),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        fetchBookings(1); // Refresh list
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text("View Order"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                        foregroundColor: Colors.black54,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text("Dismiss"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  CoordinatorInfo? getCoordinatorById(int? id) {
    try {
      return coordinators.firstWhere(
            (e) => e.id == id,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> fetchCoordinators() async {
    try {
      final token = AppPreference().getString(PreferencesKey.token);

      final res = await ApiService.getRequest(
        coordinatorUrl,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (res.data != null) {
        final List list = res.data['coordinators'] ?? [];

        setState(() {
          coordinators = list
              .map((e) => CoordinatorInfo.fromJson(e))
              .toList();
        });
      }
    } catch (e) {
      debugPrint("Coordinator Error: $e");
    }
  }

  Future<void> fetchSubscriptionTypes() async {
    try {
      final token = AppPreference().getString(PreferencesKey.token);
      final res = await ApiService.getRequest(
        getSubscriptionTypesUrl,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (res.data != null) {
        setState(() {
          subscriptionTypes = SubscriptionTypeResponse.fromJson(res.data).data;
        });
      }
    } catch (e) {
      debugPrint("Error fetching subscription types: $e");
    }
  }

  Future<void> fetchBookings(int page) async {
    setState(() {
      isLoading = true;
      currentPage = page;
    });

    try {
      final token = AppPreference().getString(PreferencesKey.token);

      Map<String, dynamic> queryParams = {'page': page};

      // String url = getBookingsUrl;
      String url = selectedFilter == "My Bookings"
          ? getCoMyBookingUrl
          : getBookingsUrl;

      if (selectedSubscriptionId != null ||
          startDate != null ||
          endDate != null) {
        url = filterBookingsUrl;
        if (selectedSubscriptionId != null) {
          queryParams['subscription_id'] = selectedSubscriptionId;
        }
        if (startDate != null) {
          queryParams['start_date'] = DateFormat(
            'yyyy-MM-dd',
          ).format(startDate!);
        }
        if (endDate != null) {
          queryParams['end_date'] = DateFormat('yyyy-MM-dd').format(endDate!);
        }
      }
      else {
        if (selectedFilter == "Today") {
          queryParams['today'] = 'true';
        } else if (selectedFilter != "All" &&   selectedFilter != "My Bookings") {
          queryParams['status'] = selectedFilter.toLowerCase();
        }
      }

      final res = await ApiService.getRequest(
        url,
        queryParameters: queryParams,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (res.data != null) {
        setState(() {
          bookingResponse = CoordinatorBookingResponse.fromJson(res.data);
        });
      }
    } catch (e) {
      debugPrint("Error fetching bookings: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _resetFilters() {
    setState(() {
      selectedFilter = "All";
      selectedSubscriptionId = null;
      startDate = null;
      endDate = null;
      currentPage = 1;
      _dashboardSearchQuery = "";
      _dashboardSearchController.clear();
    });
    fetchBookings(1);
  }

  void _openAssignWorkerDialog(BookingData booking) {
    showDialog(
      context: context,
      builder: (context) => AssignWorkerDialog(
        booking: booking,
        onSuccess: () => fetchBookings(currentPage),
      ),
    );
  }

  void _openUpdateStatusDialog(BookingData booking) {
    showDialog(
      context: context,
      builder: (context) => UpdateStatusDialog(
        booking: booking,
        onSuccess: () => fetchBookings(currentPage),
      ),
    );
  }

  void _openEditBookingDialog(BookingData booking) {
    showDialog(
      context: context,
      builder: (context) => EditBookingDialog(
        booking: booking,
        onSuccess: () => fetchBookings(currentPage),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = bookingResponse?.stats;
    final allBookings = bookingResponse?.data ?? [];

    // Front-end search filtering for main dashboard
    final filteredBookings = allBookings.where((booking) {
      final query = _dashboardSearchQuery.toLowerCase();
      if (query.isEmpty) return true;

      return booking.id.toString().contains(query) ||
          booking.customerName.toLowerCase().contains(query) ||
          (booking.worker?.name ?? "").toLowerCase().contains(query) ||
          booking.address.toLowerCase().contains(query) ||
          booking.service.name.toLowerCase().contains(query);
    }).toList();

    final name = AppPreference().getString(PreferencesKey.name);
    final phone = AppPreference().getString(PreferencesKey.phone);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBarHome(
        onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
        onEmergencyPressed: () => showSosDialog(),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: kkblack),
              accountName: Text(
                name.isEmpty ? "Coordinator" : name,
                overflow: TextOverflow.ellipsis,
              ),
              accountEmail: Text(phone, overflow: TextOverflow.ellipsis),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Colors.black),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text("Dashboard"),
              onTap: () => Navigator.pop(context),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                "Logout",
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: () {
                Navigator.pop(context);
                showLogoutDialog(context, ref);
              },
            ),
          ],
        ),
      ),
      backgroundColor: const Color(0xFFF8F9FB),
      body: RefreshIndicator(
        onRefresh: () async {
          _resetFilters();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Service / Booking Module",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF101828),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Manage bookings, assignments & commissions",
                    style: TextStyle(fontSize: 14, color: Color(0xFF667085)),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _dashboardSearchController,
                onChanged: (value) {
                  setState(() {
                    _dashboardSearchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: "Search ID, customer, worker or location...",
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              if (isLoading && bookingResponse == null)
                const Center(child: CircularProgressIndicator())
              else ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatCard(
                        "Completed",
                        "${stats?.completedBookings ?? 0}",
                        Colors.green,
                      ),
                      _buildStatCard(
                        "Pending",
                        "${stats?.pendingBookings ?? 0}",
                        Colors.orange,
                      ),
                      _buildStatCard(
                        "In Progress",
                        "${stats?.inprogressBookings ?? 0}",
                        Colors.blue,
                      ),
                      _buildStatCard(
                        "Assigned",
                        "${stats?.assignedBookings ?? 0}",
                        Colors.indigo,
                      ),
                      _buildStatCard(
                        "Cancelled",
                        "${stats?.cancelledBookings ?? 0}",
                        Colors.red,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Total Commission",
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "₹ ${stats?.totalCommission.toStringAsFixed(2) ?? "0"}",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: isLoading ? null : () => fetchBookings(1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE0E7FF),
                    foregroundColor: Colors.blue.shade700,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text("Refresh Bookings"),
                ),
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _filterChip("Today"),
                          _filterChip("All"),
                          _filterChip("Pending"),
                          _filterChip("Inprogress"),
                          _filterChip("Completed"),
                          _filterChip("My Bookings"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              if (isLoading && filteredBookings.isEmpty)
                const Center(child: CircularProgressIndicator())
              else if (filteredBookings.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text("No bookings found"),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredBookings.length,
                  separatorBuilder: (context, index) =>
                  const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final booking = filteredBookings[index];
                    final coordinatorData =
                    booking.coordinatorIds.isNotEmpty
                        ? getCoordinatorById(
                      booking.coordinatorIds.first,
                    )
                        : null;
                    return _buildBookingCard(
                      booking: booking,
                      id: "BK-${booking.id}",
                      service: booking.service.name,
                      category: booking.service.category.name,
                      status: booking.status.isNotEmpty
                          ? booking.status[0].toUpperCase() +
                          booking.status.substring(1)
                          : "",
                      paymentStatus: booking.paymentStatus,
                      customer: booking.customerName,
                      customerLoc: booking.customer.publicId,
                      customerPhone: booking.customerPhone,
                      latitude: booking.latitude,
                      longitude: booking.longitude,
                      worker: booking.worker?.name ?? "Unassigned",
                      workerId: booking.worker?.publicId,
                      coordinator: coordinatorData?.name ?? "Not assigned",
                      hideCoordinator: selectedFilter == "My Bookings",
                      date: booking.bookingDate,
                      time: booking.timeSlot,
                      address: booking.address,
                      amount: "₹${booking.amount}",
                      showAssignWorker:
                      (booking.paymentStatus ?? "").toLowerCase() ==
                          "paid" &&
                          booking.status != "completed" &&
                          booking.status != "assigned",
                      onAssignTap: () => _openAssignWorkerDialog(booking),
                      onUpdateStatusTap: () => _openUpdateStatusDialog(booking),
                      onEditTap: () => _openEditBookingDialog(booking),
                    );
                  },
                ),

              const SizedBox(height: 24),

              if (bookingResponse != null &&
                  (bookingResponse?.lastPage ?? 1) > 1)
                _buildPaginationControls(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationControls() {
    final lastPage = bookingResponse!.lastPage;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: currentPage > 1
              ? () => fetchBookings(currentPage - 1)
              : null,
          icon: const Icon(Icons.arrow_back_ios, size: 18),
        ),
        Text(
          "Page $currentPage of $lastPage",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        IconButton(
          onPressed: currentPage < lastPage
              ? () => fetchBookings(currentPage + 1)
              : null,
          icon: const Icon(Icons.arrow_forward_ios, size: 18),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String count, Color color) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12, bottom: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label) {
    bool isSelected = selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = label;
          selectedSubscriptionId = null;
          startDate = null;
          endDate = null;
          _dashboardSearchQuery = "";
          _dashboardSearchController.clear();
        });
        fetchBookings(1);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1D2939) : const Color(0xFFF2F4F7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF344054),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard({
    required BookingData booking,
    required String id,
    required String service,
    required String category,
    required String status,
    String? paymentStatus,
    required String customer,
    required String customerLoc,
    String? customerPhone,
    String? latitude,
    String? longitude,
    required String worker,
    String? workerId,
    required String coordinator,
    String? coordinatorPhone,
    required String date,
    required String time,
    String? address,
    String? amount,
    bool showAssignWorker = false,
    bool hideCoordinator = false,
    VoidCallback? onAssignTap,
    VoidCallback? onUpdateStatusTap,
    VoidCallback? onEditTap,
  }) {
    Color statusColor = status == "Pending"
        ? Colors.orange
        : status == "Completed"
        ? Colors.green
        : Colors.blue;
    Color statusBg = statusColor.withOpacity(0.1);

    Color pStatusColor = (paymentStatus ?? "").toLowerCase() == "paid"
        ? Colors.green
        : Colors.red;
    Color pStatusBg = pStatusColor.withOpacity(0.1);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                id,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Row(
                children: [
                  if (paymentStatus != null && paymentStatus.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: pStatusBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        paymentStatus.toUpperCase(),
                        style: TextStyle(
                          color: pStatusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            service,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            category,
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const Text(
            "View Extensions",
            style: TextStyle(color: Colors.blue, fontSize: 13),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Customer",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.blue.shade50,
                          child: Text(
                            customer.isNotEmpty ? customer[0] : "C",
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customer,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                customerLoc,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (customerPhone != null &&
                                  customerPhone.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Row(
                                    children: [
                                      GestureDetector(
                                        // onTap: () async {
                                        //   final Uri launchUri = Uri(
                                        //     scheme: 'tel',
                                        //     path: customerPhone,
                                        //   );
                                        //   if (await canLaunchUrl(launchUri)) {
                                        //     await launchUrl(launchUri);
                                        //   }
                                        // },
                                        onTap: () async {
                                          final Uri uri = Uri.parse("tel:$customerPhone");

                                          await launchUrl(
                                            uri,
                                            mode: LaunchMode.externalApplication,
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(
                                              0.1,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.call,
                                            color: Colors.green,
                                            size: 14,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      GestureDetector(
                                        // onTap: () async {
                                        //   final Uri launchUri = Uri(
                                        //     scheme: 'tel',
                                        //     path: customerPhone,
                                        //   );
                                        //
                                        //   if (await canLaunchUrl(launchUri)) {
                                        //     await launchUrl(launchUri);
                                        //   }
                                        // },
                                        onTap: () async {
                                          final Uri uri = Uri.parse("tel:$customerPhone");

                                          await launchUrl(
                                            uri,
                                            mode: LaunchMode.externalApplication,
                                          );
                                        },
                                        child: Text(
                                          customerPhone,
                                          style: const TextStyle(
                                            color: Colors.blue,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Worker",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    if (worker == "Unassigned")
                      Text(
                        worker,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                          fontSize: 13,
                        ),
                      )
                    else
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.purple.shade50,
                            child: Text(
                              worker.isNotEmpty ? worker[0] : "W",
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.purple,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  worker,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (workerId != null)
                                  Text(
                                    workerId,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 11,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!hideCoordinator) ...[
            const SizedBox(height: 16),
            const Text(
              "Coordinator",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 4),
            if (coordinator == "Not assigned")
              Text(
                coordinator,
                style: const TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                  fontSize: 13,
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coordinator,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  if (coordinatorPhone != null)
                    Text(
                      coordinatorPhone,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
          ],
          // const Text(
          //   "Coordinator",
          //   style: TextStyle(color: Colors.grey, fontSize: 12),
          // ),
          // const SizedBox(height: 4),
          // if (coordinator == "Not assigned")
          //   Text(
          //     coordinator,
          //     style: const TextStyle(
          //       color: Colors.grey,
          //       fontStyle: FontStyle.italic,
          //       fontSize: 13,
          //     ),
          //   )
          // else
          //   Column(
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     children: [
          //       Text(
          //         coordinator,
          //         style: const TextStyle(
          //           fontWeight: FontWeight.bold,
          //           fontSize: 13,
          //         ),
          //       ),
          //       if (coordinatorPhone != null)
          //         Text(
          //           coordinatorPhone,
          //           style: const TextStyle(color: Colors.grey, fontSize: 11),
          //         ),
          //     ],
          //   ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                date,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.access_time, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                time,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          if (address != null) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      if (latitude != null &&
                          longitude != null &&
                          latitude!.isNotEmpty &&
                          longitude!.isNotEmpty) {
                        try {
                          final position =
                          await LocationService.getCurrentLocation();
                          final String url =
                              "https://www.google.com/maps/dir/?api=1&origin=${position.latitude},${position.longitude}&destination=$latitude,$longitude&travelmode=driving";
                          final uri = Uri.parse(url);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Could not launch Google Maps"),
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error: $e")),
                            );
                          }
                        }
                      }
                    },
                    child: Text(
                      address!,
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                const Text(
                  "Read More",
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
          if (amount != null) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            // Amount row
            Row(
              children: [
                const Text(
                  "Amount",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(width: 8),
                Text(
                  amount!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Action buttons
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (showAssignWorker) ...[
                    _actionButton(
                      label: "Assign Worker",
                      icon: Icons.person_add_outlined,
                      color: Colors.blue.shade700,
                      borderColor: const Color(0xFFBFDBFE),
                      onTap: onAssignTap,
                    ),
                    const SizedBox(width: 8),
                  ],
                  _actionButton(
                    label: "Update Status",
                    icon: Icons.sync_outlined,
                    color: Colors.orange.shade700,
                    borderColor: const Color(0xFFFFD580),
                    onTap: onUpdateStatusTap,
                  ),
                  // const SizedBox(width: 8),
                  // _actionButton(
                  //   label: "Edit",
                  //   icon: Icons.edit_outlined,
                  //   color: Colors.green.shade700,
                  //   borderColor: const Color(0xFFA7F3D0),
                  //   onTap: onEditTap,
                  // ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color borderColor,
    VoidCallback? onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14, color: color),
      label: Text(label, style: TextStyle(fontSize: 12, color: color)),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: borderColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class AssignWorkerDialog extends StatefulWidget {
  final BookingData booking;
  final VoidCallback onSuccess;

  const AssignWorkerDialog({
    Key? key,
    required this.booking,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<AssignWorkerDialog> createState() => _AssignWorkerDialogState();
}

class _AssignWorkerDialogState extends State<AssignWorkerDialog> {
  bool isLoading = true;
  worker_model.AvailableWorkerResponse? workerResponse;
  int? selectedWorkerId;
  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchAvailableWorkers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchAvailableWorkers() async {
    try {
      final token = AppPreference().getString(PreferencesKey.token);
      final res = await ApiService.getRequest(
        "$getAvailableWorkersUrl${widget.booking.id}",
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (res.data != null) {
        setState(() {
          workerResponse = worker_model.AvailableWorkerResponse.fromJson(
            res.data,
          );
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching workers: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> assignWorker() async {
    if (selectedWorkerId == null) return;

    setState(() => isLoading = true);

    try {
      final token = AppPreference().getString(PreferencesKey.token);
      final res = await ApiService.postRequest(
        assignWorkerUrl,
        {
          "booking_id": widget.booking.id,
          "worker_ids": [selectedWorkerId],
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (res.data != null && res.data['success'] == true) {
        Navigator.pop(context);
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Worker assigned successfully")),
        );
      }
    } catch (e) {
      debugPrint("Error assigning worker: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to assign worker")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    List<worker_model.WorkerInfo> filteredWorkers =
        workerResponse?.availableWorkers.where((worker) {
          return worker.name.toLowerCase().contains(searchQuery.toLowerCase());
        }).toList() ??
            [];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        width: MediaQuery.of(context).size.width * 0.9,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Assign Worker",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 🔍 Search Bar for Workers - MOVED HERE (Under "Assign Worker" Title)
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search workers by name...",
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.blue),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Booking Details",
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      if (widget.booking.paymentStatus.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                            widget.booking.paymentStatus.toLowerCase() ==
                                "paid"
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.booking.paymentStatus.toUpperCase(),
                            style: TextStyle(
                              color:
                              widget.booking.paymentStatus.toLowerCase() ==
                                  "paid"
                                  ? Colors.green
                                  : Colors.red,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Flexible(child: _detailChip(widget.booking.service.name)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: _iconDetail(
                          Icons.person_outline,
                          widget.booking.customerName,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Flexible(
                        child: _iconDetail(
                          Icons.calendar_today_outlined,
                          widget.booking.bookingDate,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: _iconDetail(
                          Icons.access_time,
                          widget.booking.timeSlot,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Available Workers",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Text(
              "Select workers to assign to this booking",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 12),

            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (workerResponse?.availableWorkers.isEmpty ?? true)
              const Center(child: Text("No available workers found"))
            else if (filteredWorkers.isEmpty)
                const Center(child: Text("No matching workers found"))
              else
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.3,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: filteredWorkers.length,
                    separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final worker = filteredWorkers[index];
                      return _buildWorkerItem(worker);
                    },
                  ),
                ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: selectedWorkerId != null ? assignWorker : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFF93C5FD,
                      ), // Light blue as in image
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text("Assign"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerItem(worker_model.WorkerInfo worker) {
    bool isSelected = selectedWorkerId == worker.id;
    return GestureDetector(
      onTap: () => setState(() => selectedWorkerId = worker.id),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade200,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF6EE7B7),
              child: Text(
                worker.name.isNotEmpty
                    ? worker.name.substring(0, 2).toUpperCase()
                    : "W",
                style: const TextStyle(fontSize: 12, color: Colors.black),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    worker.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.orange, size: 14),
                        const Text(
                          " New",
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "0 Jobs",
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const Text(
                          "N/A",
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Checkbox(
              value: isSelected,
              onChanged: (v) => setState(() => selectedWorkerId = worker.id),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFDBEAFE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.blue,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _iconDetail(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.blue),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.blue,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Update Status Dialog
// ─────────────────────────────────────────────────────────────────────────────

class UpdateStatusDialog extends StatefulWidget {
  final BookingData booking;
  final VoidCallback onSuccess;

  const UpdateStatusDialog({
    super.key,
    required this.booking,
    required this.onSuccess,
  });

  @override
  State<UpdateStatusDialog> createState() => _UpdateStatusDialogState();
}

class _UpdateStatusDialogState extends State<UpdateStatusDialog> {
  bool isLoading = false;
  late String selectedStatus;

  static const List<Map<String, dynamic>> _statusOptions = [
    {'value': 'pending',    'label': 'Pending',     'color': Colors.orange},
    {'value': 'assigned',   'label': 'Assigned',    'color': Colors.indigo},
    {'value': 'inprogress', 'label': 'In Progress', 'color': Colors.blue},
    {'value': 'completed',  'label': 'Completed',   'color': Colors.green},
    {'value': 'cancelled',  'label': 'Cancelled',   'color': Colors.red},
  ];

  @override
  void initState() {
    super.initState();
    selectedStatus = widget.booking.status;
  }

  Future<void> _submit() async {
    if (selectedStatus == widget.booking.status) {
      Navigator.pop(context);
      return;
    }

    setState(() => isLoading = true);

    final success = await BookingApi.updateBookingStatus(
      bookingId: widget.booking.id,
      status: selectedStatus,
    );

    if (!mounted) return;
    setState(() => isLoading = false);

    if (success) {
      Navigator.pop(context);
      widget.onSuccess();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Booking status updated successfully")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update status. Please try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Update Status",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              "BK-${widget.booking.id} · ${widget.booking.service.name}",
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),

            // Status options
            ..._statusOptions.map((opt) {
              final isSelected = selectedStatus == opt['value'];
              final color = opt['color'] as Color;
              return GestureDetector(
                onTap: () => setState(() => selectedStatus = opt['value'] as String),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withValues(alpha: 0.07) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? color : Colors.grey.shade200,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        opt['label'] as String,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? color : Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      if (isSelected) Icon(Icons.check_circle, color: color, size: 18),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: isLoading
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                        : const Text("Update"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Edit Booking Dialog
// ─────────────────────────────────────────────────────────────────────────────

class EditBookingDialog extends StatefulWidget {
  final BookingData booking;
  final VoidCallback onSuccess;

  const EditBookingDialog({
    super.key,
    required this.booking,
    required this.onSuccess,
  });

  @override
  State<EditBookingDialog> createState() => _EditBookingDialogState();
}

class _EditBookingDialogState extends State<EditBookingDialog> {
  bool isLoading = false;
  late TextEditingController _dateCtrl;
  late TextEditingController _timeCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _amountCtrl;

  @override
  void initState() {
    super.initState();
    _dateCtrl    = TextEditingController(text: widget.booking.bookingDate);
    _timeCtrl    = TextEditingController(text: widget.booking.timeSlot);
    _addressCtrl = TextEditingController(text: widget.booking.address);
    _amountCtrl  = TextEditingController(text: widget.booking.amount);
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _timeCtrl.dispose();
    _addressCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    DateTime initial;
    try {
      initial = DateFormat('yyyy-MM-dd').parse(_dateCtrl.text);
    } catch (_) {
      initial = DateTime.now();
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      _dateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Future<void> _submit() async {
    final date    = _dateCtrl.text.trim();
    final time    = _timeCtrl.text.trim();
    final address = _addressCtrl.text.trim();
    final amount  = _amountCtrl.text.trim();

    if (date.isEmpty || time.isEmpty || address.isEmpty || amount.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    setState(() => isLoading = true);

    final success = await BookingApi.editBooking(
      bookingId: widget.booking.id,
      bookingDate: date,
      timeSlot: time,
      address: address,
      amount: amount,
    );

    if (!mounted) return;
    setState(() => isLoading = false);

    if (success) {
      Navigator.pop(context);
      widget.onSuccess();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Booking updated successfully")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update booking. Please try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Edit Booking",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            Text(
              "BK-${widget.booking.id} · ${widget.booking.service.name}",
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 20),

            // Booking Date
            _fieldLabel("Booking Date"),
            TextFormField(
              controller: _dateCtrl,
              readOnly: true,
              onTap: _pickDate,
              decoration: _inputDecoration(
                hint: "yyyy-MM-dd",
                suffix: const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 14),

            // Time Slot
            _fieldLabel("Time Slot"),
            TextFormField(
              controller: _timeCtrl,
              decoration: _inputDecoration(
                hint: "e.g. 10:00 AM - 12:00 PM",
                suffix: const Icon(Icons.access_time, size: 18, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 14),

            // Address
            _fieldLabel("Address"),
            TextFormField(
              controller: _addressCtrl,
              maxLines: 2,
              decoration: _inputDecoration(hint: "Enter address"),
            ),
            const SizedBox(height: 14),

            // Amount
            _fieldLabel("Amount (₹)"),
            TextFormField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration(hint: "Enter amount", prefix: "₹ "),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: isLoading
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                        : const Text("Save Changes"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
  );

  InputDecoration _inputDecoration({
    required String hint,
    Widget? suffix,
    String? prefix,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixText: prefix,
      suffixIcon: suffix,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}
