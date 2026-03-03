class CategoryConfig {
  final List<CategoryGroup> categories;

  CategoryConfig({required this.categories});

  factory CategoryConfig.fromJson(Map<String, dynamic> json) {
    return CategoryConfig(
      categories: (json['categories'] as List)
          .map((c) => CategoryGroup.fromJson(c))
          .toList(),
    );
  }
}

class CategoryGroup {
  final String id;
  final String nameZh;
  final String nameEn;
  final String color;
  final List<SubCategoryInfo> subcategories;

  CategoryGroup({
    required this.id,
    required this.nameZh,
    required this.nameEn,
    required this.color,
    required this.subcategories,
  });

  factory CategoryGroup.fromJson(Map<String, dynamic> json) {
    return CategoryGroup(
      id: json['id'],
      nameZh: json['name_zh'],
      nameEn: json['name_en'],
      color: json['color'],
      subcategories: (json['subcategories'] as List)
          .map((s) => SubCategoryInfo.fromJson(s))
          .toList(),
    );
  }
}

class SubCategoryInfo {
  final String id;
  final String nameZh;
  final String nameEn;

  SubCategoryInfo({
    required this.id,
    required this.nameZh,
    required this.nameEn,
  });

  factory SubCategoryInfo.fromJson(Map<String, dynamic> json) {
    return SubCategoryInfo(
      id: json['id'],
      nameZh: json['name_zh'],
      nameEn: json['name_en'],
    );
  }
}
