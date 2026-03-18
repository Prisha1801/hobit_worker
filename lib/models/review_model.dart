// class RatingSummary {
//   final double averageRating;
//   final int totalRatings;
//
//   RatingSummary({
//     required this.averageRating,
//     required this.totalRatings,
//   });
//
//   factory RatingSummary.fromJson(Map<String, dynamic> json) {
//     return RatingSummary(
//       averageRating: (json['average_rating'] ?? 0).toDouble(),
//       totalRatings: json['total_ratings'] ?? 0,
//     );
//   }
// }
//
// class RatingModel {
//   final int rating;
//   final String description;
//   final String customerName;
//   final String createdAt;
//
//   RatingModel({
//     required this.rating,
//     required this.description,
//     required this.customerName,
//     required this.createdAt,
//   });
//
//   factory RatingModel.fromJson(Map<String, dynamic> json) {
//     return RatingModel(
//       rating: json['rating'] ?? 0,
//       description: json['description'] ?? '',
//       customerName: json['customer']['name'] ?? '',
//       createdAt: json['created_at'] ?? '',
//     );
//   }
// }

class RatingSummary {
  final double averageRating;
  final int totalRatings;

  RatingSummary({
    required this.averageRating,
    required this.totalRatings,
  });

  factory RatingSummary.fromJson(Map<String, dynamic> json) {
    return RatingSummary(
      averageRating: (json["average_rating"] ?? 0).toDouble(),
      totalRatings: json["total_ratings"] ?? 0,
    );
  }
}

class RatingModel {
  final int id;
  final int rating;
  final String description;
  final String createdAt;
  final String customerName;

  RatingModel({
    required this.id,
    required this.rating,
    required this.description,
    required this.createdAt,
    required this.customerName,
  });

  factory RatingModel.fromJson(Map<String, dynamic> json) {
    return RatingModel(
      id: json["id"] ?? 0,
      rating: json["rating"] ?? 0,
      description: json["description"] ?? "",
      createdAt: json["created_at"] ?? "",
      customerName: json["customer"]?["name"] ?? "Customer",
    );
  }
}