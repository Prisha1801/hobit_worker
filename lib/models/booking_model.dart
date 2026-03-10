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
      id: json['id'] ?? 0,
      customerName: json['customer_name'] ?? '',
      customerPhone: json['customer_phone'] ?? '',
      bookingDate: json['booking_date'] ?? '',
      timeSlot: json['time_slot'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      status: json['status'] ?? '',

      latitude: double.tryParse(json['latitude']?.toString() ?? '') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '') ?? 0.0,

      service: json['service'] != null
          ? ServiceModel.fromJson(json['service'])
          : ServiceModel(
        id: 0,
        name: '',
        description: '',
        price: '0',
      ),
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
