class WorkerProfileModel {
  final int id;
  final int workerId;
  final String name;
  final String email;
  final String phone;
  final int isActive;
  final bool? isAssigned;
  final List<Category> categories;
  final List<Service> services;
  final City city;
  final City zone;
  final City? area;
  final String walletBalance;
  final String kycStatus;
  final List<Document> documents;
  final List<WorkerAvailability> workerAvailability;
  final double averageRatings;
  final int ratingCount;
  final int jobsCompleted;


  WorkerProfileModel({
    required this.id,
    required this.workerId,
    required this.name,
    required this.email,
    required this.phone,
    required this.isActive,
    this.isAssigned,
    required this.categories,
    required this.services,
    required this.city,
    required this.zone,
    this.area,
    required this.walletBalance,
    required this.kycStatus,
    required this.documents,
    required this.workerAvailability,
    required this.averageRatings,
    required this.ratingCount,
    required this.jobsCompleted,

  });

  factory WorkerProfileModel.fromJson(Map<String, dynamic> json) {
    final availabilityJson =
        json['worker_availability'] ??
            json['worker_availablillity'] ??
            [];

    return WorkerProfileModel(
      id: json['id'],
      workerId: json['worker_id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      isActive: json['is_active'] ?? 0,
      isAssigned: json['is_assigned'],
      categories: (json['categories'] as List? ?? [])
          .map((e) => Category.fromJson(e))
          .toList(),
      services: (json['services'] as List? ?? [])
          .map((e) => Service.fromJson(e))
          .toList(),
      city: City.fromJson(json['city']),
      zone: City.fromJson(json['zone']),
      area: json['area'] != null
          ? City.fromJson(json['area'])
          : null,
      walletBalance: json['wallet_balance']?.toString() ?? '0.00',
      kycStatus: json['kyc_status'] ?? '',
      documents: (json['documents'] as List? ?? [])
          .map((e) => Document.fromJson(e))
          .toList(),
      workerAvailability: (availabilityJson as List)
          .map((e) => WorkerAvailability.fromJson(e))
          .toList(),
      averageRatings:
      (json['average_ratings'] as num?)?.toDouble() ?? 0.0,
      ratingCount: json['rating_count'] ?? 0,
      jobsCompleted: json['jobs_completed'] ?? 0,

    );
  }
}

class Category {
  final int id;
  final String name;

  Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'] ?? '',
    );
  }
}
class Service {
  final int id;
  final String name;

  Service({required this.id, required this.name});

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'],
      name: json['name'] ?? '',
    );
  }
}
class City {
  final int id;
  final String name;

  City({required this.id, required this.name});

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id'],
      name: json['name'] ?? '',
    );
  }
}
class Document {
  final String type;
  final String number;
  final String frontUrl;
  final String backUrl;

  Document({
    required this.type,
    required this.number,
    required this.frontUrl,
    required this.backUrl,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      type: json['type'] ?? '',
      number: json['number'] ?? '',
      frontUrl: json['front_url'] ?? '',
      backUrl: json['back_url'] ?? '',
    );
  }
}
class WorkerAvailability {
  final int id;
  final int workerId;
  final List<String> availableDates;
  final List<AvailableTime> availableTimes;
  final bool status;
  final String createdAt;
  final String updatedAt;

  WorkerAvailability({
    required this.id,
    required this.workerId,
    required this.availableDates,
    required this.availableTimes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WorkerAvailability.fromJson(Map<String, dynamic> json) {
    return WorkerAvailability(
      id: json['id'],
      workerId: json['worker_id'],
      availableDates:
      (json['available_dates'] as List? ?? []).cast<String>(),
      availableTimes:
      (json['available_times'] as List? ?? [])
          .map((e) => AvailableTime.fromJson(e))
          .toList(),
      status: json['status'] ?? false,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}
class AvailableTime {
  final String start;
  final String end;

  AvailableTime({required this.start, required this.end});

  factory AvailableTime.fromJson(Map<String, dynamic> json) {
    return AvailableTime(
      start: json['start'] ?? '',
      end: json['end'] ?? '',
    );
  }
}
