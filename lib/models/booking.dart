import 'package:intl/intl.dart';

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
      id: json['id'] as String? ?? '', // Handle potential null or missing id
      name: json['name'] as String? ?? '', // Handle potential null or missing name
      phone: json['phone'] as String? ?? '', // Handle potential null or missing phone
      email: json['email'] as String? ?? '', // Handle potential null or missing email
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

class Booking {
  final String id;
  final String futsal;
  final String futsalName;
  final DateTime date;
  final String startTime;
  final String endTime;
  final double totalPrice;
  final String status;
  final List<Map<String, dynamic>> kitRentals;
  final BookingUser user;

  Booking({
    required this.id,
    required this.futsal,
    required this.futsalName,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.totalPrice,
    required this.status,
    this.kitRentals = const [],
    required this.user,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['_id'] ?? json['id'],
      futsal: json['futsal'] is Map<String, dynamic> ? json['futsal']['_id'] : json['futsal'],
      futsalName: json['futsal'] is Map<String, dynamic> ? json['futsal']['name'] : (json['futsalName'] ?? ''),
      date: DateTime.parse(json['date']),
      startTime: json['startTime'],
      endTime: json['endTime'],
      totalPrice: (json['totalPrice'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'pending',
      kitRentals: json['kitRentals'] is List ? List<Map<String, dynamic>>.from(json['kitRentals']) : [],
      user: json['user'] is Map<String, dynamic> ? BookingUser.fromJson(json['user']) : BookingUser(id: json['user'].toString(), name: 'Unknown User', phone: '', email: ''), // Handle case where user might be a String ID
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'futsal': futsal,
      'futsalName': futsalName,
      'date': date.toIso8601String(),
      'startTime': startTime,
      'endTime': endTime,
      'totalPrice': totalPrice,
      'status': status,
      'kitRentals': kitRentals,
      'user': user.toJson(),
    };
  }

  Booking copyWith({
    String? id,
    String? futsal,
    String? futsalName,
    DateTime? date,
    String? startTime,
    String? endTime,
    double? totalPrice,
    String? status,
    List<Map<String, dynamic>>? kitRentals,
    BookingUser? user,
  }) {
    return Booking(
      id: id ?? this.id,
      futsal: futsal ?? this.futsal,
      futsalName: futsalName ?? this.futsalName,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      kitRentals: kitRentals ?? this.kitRentals,
      user: user ?? this.user,
    );
  }
} 