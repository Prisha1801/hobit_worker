/// Emergency / SOS alert raised by a worker.
///
/// Shape is parsed defensively because the raise + history endpoints may wrap
/// the alert under `data` / `alert` and return numbers as strings.
class EmergencyAlertModel {
  final int? id;
  final int? bookingId;
  final String alertType;
  final String? message;
  final String status;
  final double? latitude;
  final double? longitude;
  final String? createdAt;

  EmergencyAlertModel({
    this.id,
    this.bookingId,
    required this.alertType,
    this.message,
    required this.status,
    this.latitude,
    this.longitude,
    this.createdAt,
  });

  factory EmergencyAlertModel.fromJson(Map<String, dynamic> json) {
    return EmergencyAlertModel(
      id: _toInt(json['id']),
      bookingId: _toInt(json['booking_id']),
      alertType: (json['alert_type'] ?? 'safety').toString(),
      message: json['message']?.toString(),
      status: (json['status'] ?? 'pending').toString(),
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      createdAt: json['created_at']?.toString(),
    );
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}
