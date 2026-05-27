class AvailableWorkerResponse {
  final BookingInfo booking;
  final List<WorkerInfo> availableWorkers;

  AvailableWorkerResponse({required this.booking, required this.availableWorkers});

  factory AvailableWorkerResponse.fromJson(Map<String, dynamic> json) {
    return AvailableWorkerResponse(
      booking: BookingInfo.fromJson(json['booking'] ?? {}),
      availableWorkers: (json['available_workers'] as List?)
          ?.map((e) => WorkerInfo.fromJson(e))
          .toList() ?? [],
    );
  }
}

class BookingInfo {
  final int id;
  final int serviceId;
  final String date;
  final String timeSlot;

  BookingInfo({required this.id, required this.serviceId, required this.date, required this.timeSlot});

  factory BookingInfo.fromJson(Map<String, dynamic> json) {
    return BookingInfo(
      id: json['id'] ?? 0,
      serviceId: json['service_id'] ?? 0,
      date: json['date'] ?? '',
      timeSlot: json['time_slot'] ?? '',
    );
  }
}

class WorkerInfo {
  final int id;
  final String name;
  final String phone;

  WorkerInfo({required this.id, required this.name, required this.phone});

  factory WorkerInfo.fromJson(Map<String, dynamic> json) {
    return WorkerInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}
