class PaymentMethod {
  final String id;
  final String nameZh;
  final String nameEn;
  final String type;
  final String? descriptionZh;
  final String? descriptionEn;

  PaymentMethod({
    required this.id,
    required this.nameZh,
    required this.nameEn,
    required this.type,
    this.descriptionZh,
    this.descriptionEn,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'],
      nameZh: json['name_zh'],
      nameEn: json['name_en'],
      type: json['type'],
      descriptionZh: json['description_zh'],
      descriptionEn: json['description_en'],
    );
  }
}
