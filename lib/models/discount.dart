class DiscountCondition {
  final double minSpend;
  final List<String> excludePaymentIds;

  DiscountCondition({required this.minSpend, required this.excludePaymentIds});

  factory DiscountCondition.fromJson(Map<String, dynamic> json) {
    return DiscountCondition(
      minSpend: (json['min_spend'] ?? 0).toDouble(),
      excludePaymentIds: List<String>.from(json['exclude_payment_ids'] ?? []),
    );
  }
}

class DiscountSchedule {
  final DateTime? startDate;
  final DateTime? endDate;
  final List<int> applicableDaysOfMonth;
  final List<int> applicableDaysOfWeek;

  DiscountSchedule({
    this.startDate,
    this.endDate,
    required this.applicableDaysOfMonth,
    required this.applicableDaysOfWeek,
  });

  factory DiscountSchedule.fromJson(Map<String, dynamic> json) {
    return DiscountSchedule(
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'])
          : null,
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'])
          : null,
      applicableDaysOfMonth: List<int>.from(
        json['applicable_days_of_month'] ?? [],
      ),
      applicableDaysOfWeek: List<int>.from(
        json['applicable_days_of_week'] ?? [],
      ),
    );
  }
}

class DiscountReward {
  final double? rate;
  final double? amount;
  final int? pointsCost;

  DiscountReward({this.rate, this.amount, this.pointsCost});

  factory DiscountReward.fromJson(Map<String, dynamic> json) {
    return DiscountReward(
      rate: json['rate']?.toDouble(),
      amount: json['amount']?.toDouble(),
      pointsCost: json['points_cost']?.toInt(),
    );
  }
}

class Discount {
  final String id;
  final List<String> shopIds;
  final List<String> requiredPaymentIds;
  final String titleZh;
  final String titleEn;
  final String type;
  final DiscountCondition conditions;
  final DiscountSchedule schedule;
  final DiscountReward rewards;
  final bool isProduct;

  Discount({
    required this.id,
    required this.shopIds,
    required this.requiredPaymentIds,
    required this.titleZh,
    required this.titleEn,
    required this.type,
    required this.conditions,
    required this.schedule,
    required this.rewards,
    this.isProduct = false,
  });

  factory Discount.fromJson(Map<String, dynamic> json) {
    return Discount(
      id: json['id'],
      shopIds: List<String>.from(json['shop_ids'] ?? []),
      requiredPaymentIds: List<String>.from(json['required_payment_ids'] ?? []),
      titleZh: json['title_zh'],
      titleEn: json['title_en'] ?? "",
      type: json['type'],
      conditions: DiscountCondition.fromJson(json['conditions'] ?? {}),
      schedule: DiscountSchedule.fromJson(json['schedule'] ?? {}),
      rewards: DiscountReward.fromJson(json['rewards'] ?? {}),
      isProduct: json['is_product'] ?? false,
    );
  }
}
