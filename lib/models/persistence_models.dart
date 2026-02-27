class PresetSearch {
  final String id;
  final String shopId;
  final double amount;
  final DateTime createdAt;

  PresetSearch({
    required this.id,
    required this.shopId,
    required this.amount,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'shopId': shopId,
    'amount': amount,
    'createdAt': createdAt.toIso8601String(),
  };

  factory PresetSearch.fromJson(Map<String, dynamic> json) => PresetSearch(
    id: json['id'],
    shopId: json['shopId'],
    amount: json['amount'].toDouble(),
    createdAt: DateTime.parse(json['createdAt']),
  );
}

class AlarmReminder {
  final String id;
  final String discountId;
  final String shopId;
  final DateTime triggerTime;

  AlarmReminder({
    required this.id,
    required this.discountId,
    required this.shopId,
    required this.triggerTime,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'discountId': discountId,
    'shopId': shopId,
    'triggerTime': triggerTime.toIso8601String(),
  };

  factory AlarmReminder.fromJson(Map<String, dynamic> json) => AlarmReminder(
    id: json['id'],
    discountId: json['discountId'],
    shopId: json['shopId'],
    triggerTime: DateTime.parse(json['triggerTime']),
  );
}
