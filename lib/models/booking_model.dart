import 'package:intl/intl.dart';
import 'field_model.dart';

class BookingUser {
  final String id;
  final String name;
  final String phone;
  final String email;

  BookingUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
  });

  factory BookingUser.fromJson(Map<String, dynamic> json) {
    return BookingUser(
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

class KitRental {
  final int jerseys;
  final int shoes;
  final int balls;

  KitRental({
    required this.jerseys,
    required this.shoes,
    required this.balls,
  });

  factory KitRental.fromJson(Map<String, dynamic> json) {
    return KitRental(
      jerseys: json['jerseys'] as int,
      shoes: json['shoes'] as int,
      balls: json['balls'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'jerseys': jerseys,
      'shoes': shoes,
      'balls': balls,
    };
  }
}

class Booking {
  final String id;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String status;
  final double totalPrice;
  final BookingUser user;
  final Field field;
  final KitRental? kitRental;
  final DateTime createdAt;
  final DateTime updatedAt;

  Booking({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.totalPrice,
    required this.user,
    required this.field,
    this.kitRental,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['_id'] as String? ?? '',
      date: DateTime.parse(json['date']),
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      status: json['status'] as String? ?? '',
      totalPrice: json['totalPrice'].toDouble(),
      user: json['user'] is Map<String, dynamic> ? BookingUser.fromJson(json['user']) : BookingUser(id: json['user'].toString(), name: 'Unknown User', phone: '', email: ''),
      field: json['field'] is Map<String, dynamic> ? Field.fromJson(json['field']) : Field(id: json['field'].toString(), name: 'Unknown Futsal', description: '', price: 0.0, isAvailable: true, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      kitRental: json['kitRental'] != null ? KitRental.fromJson(json['kitRental']) : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': DateFormat('yyyy-MM-dd').format(date),
      'startTime': startTime,
      'endTime': endTime,
      'status': status,
      'totalPrice': totalPrice,
      'user': user.toJson(),
      'field': field.toJson(),
      'kitRental': kitRental?.toJson(),
    };
  }
} 