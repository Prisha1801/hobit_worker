class SubscriptionTypeResponse {
  final List<SubscriptionType> data;

  SubscriptionTypeResponse({required this.data});

  factory SubscriptionTypeResponse.fromJson(dynamic json) {
    List<SubscriptionType> types = [];
    if (json is List) {
      types = json.map((e) => SubscriptionType.fromJson(e as Map<String, dynamic>)).toList();
    } else if (json is Map && json['data'] is List) {
      types = (json['data'] as List)
          .map((e) => SubscriptionType.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return SubscriptionTypeResponse(data: types);
  }
}

class SubscriptionType {
  final int id;
  final String name;

  SubscriptionType({required this.id, required this.name});

  factory SubscriptionType.fromJson(Map<String, dynamic> json) {
    return SubscriptionType(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
    );
  }
}
