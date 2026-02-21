class WithdrawalHistoryModel {
  final int id;
  final String amount;
  final String? approvedAmount;
  final String status;
  final String requestNote;
  final DateTime createdAt;

  WithdrawalHistoryModel({
    required this.id,
    required this.amount,
    this.approvedAmount,
    required this.status,
    required this.requestNote,
    required this.createdAt,
  });

  factory WithdrawalHistoryModel.fromJson(Map<String, dynamic> json) {
    return WithdrawalHistoryModel(
      id: json['id'],
      amount: json['amount'],
      approvedAmount: json['approved_amount'],
      status: json['status'],
      requestNote: json['request_note'] ?? "",
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
