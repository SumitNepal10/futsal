import 'package:flutter/foundation.dart';
import 'kit.dart';

class KitRental {
  final Kit kit;
  final int quantity;
  final double price;

  KitRental({
    required this.kit,
    required this.quantity,
    required this.price,
  });

  factory KitRental.fromJson(Map<String, dynamic> json) {
    return KitRental(
      kit: json['kit'] is Map<String, dynamic>
          ? Kit.fromJson(json['kit'])
          : Kit(id: json['kit'].toString(), name: 'Unknown Kit', description: null, price: 0.0, size: 'N/A', quantity: 0, type: 'Unknown', futsalId: '', isAvailable: false, images: []),
      quantity: json['quantity'],
      price: (json['price'] is int) ? json['price'].toDouble() : (json['price'] is double ? json['price'] : 0.0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'kit': kit,
      'quantity': quantity,
      'price': price,
    };
  }
}

class KitBooking {
  final String id;
  final String user;
  final String futsal;
  final Map<String, dynamic>? futsalDetails;
  final String booking;
  final Map<String, dynamic>? bookingDetails;
  final List<KitRental> kitRentals;
  final double totalAmount;
  final String status;
  final DateTime createdAt;

  KitBooking({
    required this.id,
    required this.user,
    required this.futsal,
    this.futsalDetails,
    required this.booking,
    this.bookingDetails,
    required this.kitRentals,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
  });

  factory KitBooking.fromJson(Map<String, dynamic> json) {
    return KitBooking(
      id: json['_id'],
      user: json['user'] == null ? '' : (json['user'] is String ? json['user'] : json['user']['_id']),
      futsal: json['futsal'] == null ? '' : (json['futsal'] is String ? json['futsal'] : json['futsal']['_id']),
      futsalDetails: json['futsal'] is Map<String, dynamic> ? json['futsal'] : null,
      booking: json['booking'] == null ? '' : (json['booking'] is String ? json['booking'] : json['booking']['_id']),
      bookingDetails: json['booking'] is Map<String, dynamic> ? json['booking'] : null,
      kitRentals: (json['kitRentals'] as List? ?? [])
          .map((rental) => KitRental.fromJson(rental))
          .toList(),
      totalAmount: (json['totalAmount'] is num)
          ? json['totalAmount'].toDouble()
          : 0.0,
      status: json['status'] ?? 'Unknown',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user': user,
      'futsal': futsal,
      'booking': booking,
      'kitRentals': kitRentals.map((rental) => rental.toJson()).toList(),
      'totalAmount': totalAmount,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
} 