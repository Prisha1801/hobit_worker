class CoordinatorBookingResponse {
  final bool success;
  final Stats stats;
  final List<BookingData> data;
  final int lastPage;
  final int total;

  CoordinatorBookingResponse({
    required this.success,
    required this.stats,
    required this.data,
    required this.lastPage,
    required this.total,
  });

  factory CoordinatorBookingResponse.fromJson(Map<String, dynamic> json) {
    return CoordinatorBookingResponse(
      success: json['success'] ?? false,
      stats: Stats.fromJson(json['stats'] ?? {}),
      data: (json['data'] as List?)
          ?.map((e) => BookingData.fromJson(e))
          .toList() ?? [],
      lastPage: json['last_page'] ?? 1,
      total: json['total'] ?? 0,
    );
  }
}

class Stats {
  final int totalBookings;
  final int completedBookings;
  final int pendingBookings;
  final int assignedBookings;
  final int inprogressBookings;
  final int cancelledBookings;
  final double totalCommission;

  Stats({
    required this.totalBookings,
    required this.completedBookings,
    required this.pendingBookings,
    required this.assignedBookings,
    required this.inprogressBookings,
    required this.cancelledBookings,
    required this.totalCommission,
  });

  factory Stats.fromJson(Map<String, dynamic> json) {
    return Stats(
      totalBookings: json['total_bookings'] ?? 0,
      completedBookings: json['completed_bookings'] ?? 0,
      pendingBookings: json['pending_bookings'] ?? 0,
      assignedBookings: json['assigned_bookings'] ?? 0,
      inprogressBookings: json['inprogress_bookings'] ?? 0,
      cancelledBookings: json['cancelled_bookings'] ?? 0,
      totalCommission: (json['total_commission'] ?? 0).toDouble(),
    );
  }
}

class BookingData {
  final int id;
  final String bookingDate;
  final List<int> coordinatorIds;
  final String timeSlot;
  final String status;
  final String paymentStatus;
  final String amount;
  final String address;
  final String? latitude; // ✅ Added latitude
  final String? longitude; // ✅ Added longitude
  final String customerName;
  final String customerPhone; 
  final ServiceInfo service;
  final CustomerInfo customer;
  final WorkerInfo? worker;

  BookingData({
    required this.id,
    required this.bookingDate,
    required this.coordinatorIds,
    required this.timeSlot,
    required this.status,
    required this.paymentStatus,
    required this.amount,
    required this.address,
    this.latitude,
    this.longitude,
    required this.customerName,
    required this.customerPhone,
    required this.service,
    required this.customer,
    this.worker,
  });

  factory BookingData.fromJson(Map<String, dynamic> json) {
    final customerJson = json['customer'] ?? {};
    final serviceJson = json['service'] ?? {};

    return BookingData(
      id: json['id'] ?? 0,
      bookingDate: json['booking_date'] ?? '',
      coordinatorIds:
      (json['coordinator_ids'] as List?)
          ?.map((e) => int.tryParse(e.toString()) ?? 0)
          .toList() ??
          [],
      timeSlot: json['time_slot'] ?? '',
      status: json['status'] ?? '',
      paymentStatus: json['payment_status'] ?? '',
      amount: json['amount'] ?? '0',
      address: json['address'] ?? '',
      latitude: json['latitude']?.toString(), // ✅ Map from JSON
      longitude: json['longitude']?.toString(), // ✅ Map from JSON
      // customerName: json['customer_name'] ?? '',
      // customerPhone: json['customer_phone'] ?? '',
      customerName:
      json['customer_name'] ??
          customerJson['name'] ??
          '',

      // ✅ FIXED
      customerPhone:
      json['customer_phone'] ??
          customerJson['phone'] ??
          '',
      service: ServiceInfo.fromJson(json['service'] ?? {}),
      customer: CustomerInfo.fromJson(json['customer'] ?? {}),
      worker: json['worker'] != null ? WorkerInfo.fromJson(json['worker']) : null,
    );
  }
}

class ServiceInfo {
  final String name;
  final CategoryInfo category;

  ServiceInfo({required this.name, required this.category});

  factory ServiceInfo.fromJson(Map<String, dynamic> json) {
    return ServiceInfo(
      name: json['name'] ?? '',
      category: CategoryInfo.fromJson(json['category'] ?? {}),
    );
  }
}

class CategoryInfo {
  final String name;
  CategoryInfo({required this.name});
  factory CategoryInfo.fromJson(Map<String, dynamic> json) {
    return CategoryInfo(name: json['name'] ?? '');
  }
}

class CustomerInfo {
  final String name;
  final String publicId;
  final String phone;

  CustomerInfo({
    required this.name,
    required this.publicId,
    required this.phone,
  });

  factory CustomerInfo.fromJson(Map<String, dynamic> json) {
    return CustomerInfo(
      name: json['name'] ?? '',
      publicId: json['public_id'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}

class WorkerInfo {
  final String name;
  final String publicId;
  WorkerInfo({required this.name, required this.publicId});
  factory WorkerInfo.fromJson(Map<String, dynamic> json) {
    return WorkerInfo(
      name: json['name'] ?? '',
      publicId: json['public_id'] ?? '',
    );
  }
}



//// get coordinators lists model

class CoordinatorInfo {
  final int id;
  final String name;
  final String phone;

  CoordinatorInfo({
    required this.id,
    required this.name,
    required this.phone,
  });

  factory CoordinatorInfo.fromJson(Map<String, dynamic> json) {
    return CoordinatorInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}