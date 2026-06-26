/// Model for the `/api/checkin` response `data` object.
class CheckInModel {
  final int id;
  final int workerId;
  final int? zoneId;
  final String date;
  final String latitude;
  final String longitude;
  final num distanceM;
  final String loggedAt;
  final String photoUrl;
  final String createdAt;
  final String updatedAt;

  CheckInModel({
    required this.id,
    required this.workerId,
    required this.zoneId,
    required this.date,
    required this.latitude,
    required this.longitude,
    required this.distanceM,
    required this.loggedAt,
    required this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CheckInModel.fromJson(Map<String, dynamic> json) {
    return CheckInModel(
      id: json['id'] ?? 0,
      workerId: json['worker_id'] ?? 0,
      zoneId: json['zone_id'],
      date: json['date'] ?? '',
      latitude: json['check_in_lat']?.toString() ?? '',
      longitude: json['check_in_lon']?.toString() ?? '',
      distanceM: json['check_in_distance_m'] ?? 0,
      loggedAt: json['check_in_at'] ?? '',
      photoUrl: json['check_in_photo']?.toString() ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}
