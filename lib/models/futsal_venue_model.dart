import 'field_model.dart';

class FutsalVenue {
  final String? id;
  final String name;
  final String description;
  final String address;
  final String phone;
  final String email;
  final String? imageUrl;
  final List<String> facilities;
  final List<Field> fields;
  final String ownerId;
  final DateTime createdAt;
  final DateTime updatedAt;

  FutsalVenue({
    this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.phone,
    required this.email,
    this.imageUrl,
    required this.facilities,
    required this.fields,
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FutsalVenue.fromJson(Map<String, dynamic> json) {
    return FutsalVenue(
      id: json['_id'],
      name: json['name'],
      description: json['description'],
      address: json['address'],
      phone: json['phone'],
      email: json['email'],
      imageUrl: json['imageUrl'],
      facilities: List<String>.from(json['facilities']),
      fields: (json['fields'] as List)
          .map((field) => Field.fromJson(field))
          .toList(),
      ownerId: json['ownerId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'address': address,
      'phone': phone,
      'email': email,
      'facilities': facilities,
      'fields': fields.map((field) => field.toJson()).toList(),
      'ownerId': ownerId,
    };
  }

  FutsalVenue copyWith({
    String? id,
    String? name,
    String? description,
    String? address,
    String? phone,
    String? email,
    String? imageUrl,
    List<String>? facilities,
    List<Field>? fields,
    String? ownerId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FutsalVenue(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      imageUrl: imageUrl ?? this.imageUrl,
      facilities: facilities ?? this.facilities,
      fields: fields ?? this.fields,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 