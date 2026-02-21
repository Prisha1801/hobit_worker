
class IdNameModel {
  final int id;
  final String name;
  final int? categoryId;
  final int? cityId; // for Zones
  final int? zoneId; // for Areas

  IdNameModel({
    required this.id,
    required this.name,
    this.categoryId,
    this.cityId,
    this.zoneId,
  });

  factory IdNameModel.fromJson(Map<String, dynamic> json) {
    return IdNameModel(
      id: json['id'],
      name: json['name'],
      categoryId: json['category_id'],
      cityId: json['city_id'],   // zones API
      zoneId: json['zone_id'],   // areas API
    );
  }
}
