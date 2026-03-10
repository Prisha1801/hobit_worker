// class BookingExtensionModel {
//   final int id;
//   final int durationMinutes;
//   final String amount;
//   final String paymentStatus;
//   final String paymentLink;
//
//   BookingExtensionModel({
//     required this.id,
//     required this.durationMinutes,
//     required this.amount,
//     required this.paymentStatus,
//     required this.paymentLink,
//   });
//
//   factory BookingExtensionModel.fromJson(Map<String, dynamic> json) {
//     return BookingExtensionModel(
//       id: json['id'] ?? 0,
//       durationMinutes: json['duration_minutes'] ?? 0,
//       amount: json['amount'] ?? '0',
//       paymentStatus: json['payment_status'] ?? '',
//       paymentLink: json['payment_link'] ?? '',
//     );
//   }
// }


class BookingExtensionModel {
  final int id;
  final int durationMinutes;
  final String amount;
  final String paymentStatus;
  final String paymentLink;
  final String createdAt;

  BookingExtensionModel({
    required this.id,
    required this.durationMinutes,
    required this.amount,
    required this.paymentStatus,
    required this.paymentLink,
    required this.createdAt,
  });

  factory BookingExtensionModel.fromJson(Map<String, dynamic> json) {
    return BookingExtensionModel(
      id: json['id'] ?? 0,
      durationMinutes: json['duration_minutes'] ?? 0,
      amount: json['amount'] ?? '',
      paymentStatus: json['payment_status'] ?? '',
      paymentLink: json['payment_link'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class BookingExtensionResponse {
  final int extensionCount;
  final List<BookingExtensionModel> extensions;

  BookingExtensionResponse({
    required this.extensionCount,
    required this.extensions,
  });

  factory BookingExtensionResponse.fromJson(Map<String, dynamic> json) {
    final booking = json['booking'];

    return BookingExtensionResponse(
      extensionCount: booking['extension_count'] ?? 0,
      extensions: (booking['extensions'] as List)
          .map((e) => BookingExtensionModel.fromJson(e))
          .toList(),
    );
  }
}