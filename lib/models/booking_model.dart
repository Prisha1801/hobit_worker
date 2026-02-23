class AssignedBookingModel {
  final int id;
  final String customerName;
  final String customerPhone;
  final String bookingDate;
  final String timeSlot;
  final String address;
  final String city;
  final String status;
  final double latitude;
  final double longitude;
  final ServiceModel service;

  AssignedBookingModel({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.bookingDate,
    required this.timeSlot,
    required this.address,
    required this.city,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.service,
  });

  factory AssignedBookingModel.fromJson(Map<String, dynamic> json) {
    return AssignedBookingModel(
      id: json['id'],
      customerName: json['customer_name'] ?? '',
      customerPhone: json['customer_phone'] ?? '',
      bookingDate: json['booking_date'] ?? '',
      timeSlot: json['time_slot'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      latitude: double.parse(json['latitude']),
      longitude: double.parse(json['longitude']),
      status: json['status'] ?? '',
      service: ServiceModel.fromJson(json['service']),
    );
  }
}
class ServiceModel {
  final int id;
  final String name;
  final String description;
  final String price;
  final SubscriptionModel? subscription;

  ServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.subscription,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: json['price'] ?? '0',
      subscription: json['subscription'] != null
          ? SubscriptionModel.fromJson(json['subscription'])
          : null,
    );
  }
}

class SubscriptionModel {
  final int id;
  final String name;

  SubscriptionModel({
    required this.id,
    required this.name,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}

// class ServiceModel {
//   final int id;
//   final String name;
//   final String description;
//   final String price;
//   final SubscriptionModel? subscription; // ✅ NEW
//
//   ServiceModel({
//     required this.id,
//     required this.name,
//     required this.description,
//     required this.price,
//     required this.subscription
//   });
//
//   factory ServiceModel.fromJson(Map<String, dynamic> json) {
//     return ServiceModel(
//       id: json['id'],
//       name: json['name'] ?? '',
//       description: json['description'] ?? '',
//       price: json['price'] ?? '0',
//     );
//   }
// }
