class CategoryModel {
  final String id;
  final String name;
  final bool isActive;

  CategoryModel({required this.id, required this.name, required this.isActive});

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'],
      isActive: json['is_active'] ?? true, // 🔥 INI PENTING
    );
  }
}
