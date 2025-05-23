import 'package:intl/intl.dart';
import 'field_model.dart';

class RentalUser {
  final String id;
  final String name;
  final String phone;
  final String email;

  RentalUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
  });

  factory RentalUser.fromJson(Map<String, dynamic> json) {
    return RentalUser(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
    };
  }
}

class Kit {
  final String id;
  final String name;
  final String description;
  final double price;
  final bool isAvailable;

  Kit({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.isAvailable,
  });

  factory Kit.fromJson(Map<String, dynamic> json) {
    return Kit(
      id: json['_id'] ?? json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      price: (json['price'] as num).toDouble(),
      isAvailable: json['isAvailable'] ?? true,
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

class KitRental {
  final String id;
  final Kit kit;
  final RentalUser user;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final double totalPrice;

  KitRental({
    required this.id,
    required this.kit,
    required this.user,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.totalPrice,
  });

  factory KitRental.fromJson(Map<String, dynamic> json) {
    return KitRental(
      id: json['_id'] ?? json['id'],
      kit: Kit.fromJson(json['kit']),
      user: RentalUser.fromJson(json['user']),
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      status: json['status'],
      totalPrice: (json['totalPrice'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kit': kit.toJson(),
      'user': user.toJson(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status,
      'totalPrice': totalPrice,
    };
  }
} 