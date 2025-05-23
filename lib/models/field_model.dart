class Field {
  final String id;
  final String name;
  final String description;
  final double price;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;

  Field({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.isAvailable,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Field.fromJson(Map<String, dynamic> json) {
    return Field(
      id: json['_id'] ?? json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      price: (json['price'] as num).toDouble(),
      isAvailable: json['isAvailable'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'isAvailable': isAvailable,
    };
  }
} 