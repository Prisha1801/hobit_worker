/// Model for an unclaimed booking returned by
/// GET /api/worker/available-bookings
class AvailableBookingModel {
  final int id;
  final String status;
  final String paymentStatus;
  final int? workerId;
  final String bookingDate;
  final String timeSlot;
  final String address;
  final String amount;
  final String customerName;
  final String customerPhone;
  final String startDate;
  final String endDate;
  final bool claimable;
  final String serviceName;

  AvailableBookingModel({
    required this.id,
    required this.status,
    required this.paymentStatus,
    required this.workerId,
    required this.bookingDate,
    required this.timeSlot,
    required this.address,
    required this.amount,
    required this.customerName,
    required this.customerPhone,
    required this.startDate,
    required this.endDate,
    required this.claimable,
    required this.serviceName,
  });

  factory AvailableBookingModel.fromJson(Map<String, dynamic> json) {
    return AvailableBookingModel(
      id: json['id'] ?? 0,
      status: json['status']?.toString() ?? '',
      paymentStatus: json['payment_status']?.toString() ?? '',
      workerId: json['worker_id'] is num
          ? (json['worker_id'] as num).toInt()
          : null,
      bookingDate: json['booking_date']?.toString() ?? '',
      timeSlot: json['time_slot']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      amount: json['amount']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? '',
      customerPhone: json['customer_phone']?.toString() ?? '',
      startDate: json['start_date']?.toString() ?? '',
      endDate: json['end_date']?.toString() ?? '',
      claimable: json['claimable'] == true,
      serviceName: json['service']?['name']?.toString() ?? '',
    );
  }
}
