class MenuModel {
  final String id;
  final String name;
  final int price;
  final int stock;
  final String? categoryId;
  final String? categoryName;
  final bool status;
  final String? imageUrl;
  final bool hasRecipe;

  MenuModel({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.categoryId,
    required this.categoryName,
    required this.status,
    required this.imageUrl,
    required this.hasRecipe,
  });

  factory MenuModel.fromJson(Map<String, dynamic> json) {
    return MenuModel(
      id: json['id'],
      name: json['name'],
      price: json['price'] as int,
      stock: json['stock'] as int,
      categoryId: json['category_id']?.toString(),
      categoryName: json['categories'] != null
          ? json['categories']['name']
          : null,
      status: json['status'] ?? false,
      imageUrl: json['image_url'],
      hasRecipe: json['has_recipe'] ?? false,
    );
  }
}
