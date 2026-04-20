class StockModel {
  final String id;
  final String name;
  final int quantity;
  final int minStock;
  final String unit;

  StockModel({
    required this.id,
    required this.name,
    required this.quantity,
    required this.minStock,
    required this.unit,
  });

  factory StockModel.fromJson(Map<String, dynamic> json) {
    return StockModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      quantity: int.tryParse(json['quantity']?.toString() ?? '') ?? 0,
      minStock: int.tryParse(json['min_stock']?.toString() ?? '') ?? 0,
      unit: json['unit']?.toString() ?? 'pcs',
    );
  }

  StockModel copyWith({
    int? quantity,
    int? minStock,
    String? name,
    String? unit,
  }) {
    return StockModel(
      id: id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      minStock: minStock ?? this.minStock,
      unit: unit ?? this.unit,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'min_stock': minStock,
      'unit': unit,
    };
  }
}
