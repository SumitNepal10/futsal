class Kit {
  final String id;
  final String name;
  final String? description;
  final String size;
  final int quantity;
  final double price;
  final String? imageUrl;
  final String type;
  final String futsalId;
  final bool isAvailable;
  final List<String>? images;

  Kit({
    required this.id,
    required this.name,
    this.description,
    required this.size,
    required this.quantity,
    required this.price,
    this.imageUrl,
    required this.type,
    required this.futsalId,
    this.isAvailable = true,
    this.images,
  });

  factory Kit.fromJson(Map<String, dynamic> json) {
    return Kit(
      id: json['_id'],
      name: json['name'],
      description: json['description'],
      size: json['size'],
      quantity: json['quantity'],
      price: json['price'].toDouble(),
      imageUrl: json['imageUrl'],
      type: json['type'],
      futsalId: json['futsal'],
      isAvailable: json['isAvailable'] ?? true,
      images: json['images'] != null ? List<String>.from(json['images']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'size': size,
      'quantity': quantity,
      'price': price,
      'imageUrl': imageUrl,
      'type': type,
      'futsal': futsalId,
      'isAvailable': isAvailable,
      'images': images,
    };
  }
} 