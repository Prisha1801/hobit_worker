/// Model for the `/api/checkout` response `data` object.
class CheckOutModel {
  final int id;
  final int workerId;
  final int? zoneId;
  final String date;
  final String checkInAt;
  final String checkInLat;
  final String checkInLon;
  final num checkInDistanceM;
  final String checkOutAt;
  final String checkOutLat;
  final String checkOutLon;
  final num checkOutDistanceM;
  final String createdAt;
  final String updatedAt;

  CheckOutModel({
    required this.id,
    required this.workerId,
    required this.zoneId,
    required this.date,
    required this.checkInAt,
    required this.checkInLat,
    required this.checkInLon,
    required this.checkInDistanceM,
    required this.checkOutAt,
    required this.checkOutLat,
    required this.checkOutLon,
    required this.checkOutDistanceM,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CheckOutModel.fromJson(Map<String, dynamic> json) {
    return CheckOutModel(
      id: json['id'] ?? 0,
      workerId: json['worker_id'] ?? 0,
      zoneId: json['zone_id'],
      date: json['date'] ?? '',
      checkInAt: json['check_in_at'] ?? '',
      checkInLat: json['check_in_lat']?.toString() ?? '',
      checkInLon: json['check_in_lon']?.toString() ?? '',
      checkInDistanceM: json['check_in_distance_m'] ?? 0,
      checkOutAt: json['check_out_at'] ?? '',
      checkOutLat: json['check_out_lat']?.toString() ?? '',
      checkOutLon: json['check_out_lon']?.toString() ?? '',
      checkOutDistanceM: json['check_out_distance_m'] ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}
