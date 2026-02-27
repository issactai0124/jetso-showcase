class Shop {
  final String id;
  final String nameZh;
  final String nameEn;
  final String? descriptionZh;
  final String? descriptionEn;
  final String category;

  Shop({
    required this.id,
    required this.nameZh,
    required this.nameEn,
    this.descriptionZh,
    this.descriptionEn,
    required this.category,
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id'],
      nameZh: json['name_zh'],
      nameEn: json['name_en'],
      descriptionZh: json['description_zh'],
      descriptionEn: json['description_en'],
      category: json['category'] ?? '其他',
    );
  }
}
