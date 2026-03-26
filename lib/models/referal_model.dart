class ReferralEarningModel {
  final int referralPoints;
  final int referralsCount;
  final List<ReferralUserModel> referrals;

  ReferralEarningModel({
    required this.referralPoints,
    required this.referralsCount,
    required this.referrals,
  });

  factory ReferralEarningModel.fromJson(Map<String, dynamic> json) {

    final List list = json["referrals"] ?? [];

    return ReferralEarningModel(
      referralPoints: json["referral_points"] ?? 0,
      referralsCount: json["referrals_count"] ?? 0,
      referrals: list.map((e) => ReferralUserModel.fromJson(e)).toList(),
    );
  }
}

class ReferralUserModel {
  final String name;
  final String phone;
  final int points;
  final String createdAt;

  ReferralUserModel({
    required this.name,
    required this.phone,
    required this.points,
    required this.createdAt,
  });

  factory ReferralUserModel.fromJson(Map<String, dynamic> json) {
    return ReferralUserModel(
      name: json["name"] ?? "User",
      phone: json["phone"] ?? "",
      points: json["points"] ?? 0,
      createdAt: json["created_at"] ?? "",
    );
  }
}