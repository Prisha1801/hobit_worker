class BookingTimerModel {
  final int bookingId;
  final String status;
  final bool running;
  final String? serviceStartedAt;
  final String? serviceEndedAt;
  final int elapsedSeconds;
  final String elapsedFormatted;

  BookingTimerModel({
    required this.bookingId,
    required this.status,
    required this.running,
    this.serviceStartedAt,
    this.serviceEndedAt,
    required this.elapsedSeconds,
    required this.elapsedFormatted,
  });

  factory BookingTimerModel.fromJson(Map<String, dynamic> json) {
    return BookingTimerModel(
      bookingId:
          json['booking_id'] is num ? (json['booking_id'] as num).toInt() : 0,
      status: json['status']?.toString() ?? '',
      running: json['running'] == true,
      serviceStartedAt: json['service_started_at']?.toString(),
      serviceEndedAt: json['service_ended_at']?.toString(),
      elapsedSeconds: json['elapsed_seconds'] is num
          ? (json['elapsed_seconds'] as num).toInt()
          : 0,
      elapsedFormatted: json['elapsed_formatted']?.toString() ?? '00:00:00',
    );
  }
}
