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
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown User',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
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

class FutsalDetails {
  final String id;
  final String name;
  final String location;
  final double pricePerHour;

  FutsalDetails({
    required this.id,
    required this.name,
    required this.location,
    required this.pricePerHour,
  });

  factory FutsalDetails.fromJson(Map<String, dynamic> json) {
    return FutsalDetails(
      id: json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      location: json['location'] as String? ?? '',
      pricePerHour: json['pricePerHour']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'location': location,
      'pricePerHour': pricePerHour,
    };
  }
}

class KitItem {
  final String id;
  final String name;

  KitItem({
    required this.id,
    required this.name,
  });

  factory KitItem.fromJson(Map<String, dynamic> json) {
    return KitItem(
      id: json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
    };
  }
}

class KitRental {
  final KitItem? kitId;
  final int? quantity;
  final double? price;

  KitRental({
    this.kitId,
    this.quantity,
    this.price,
  });

  factory KitRental.fromJson(Map<String, dynamic> json) {
    print('KitRental.fromJson input: $json');
    final kitRental = KitRental(
      kitId: json['kitId'] != null ? KitItem.fromJson(json['kitId']) : null,
      quantity: json['quantity'] as int?,
      price: json['price']?.toDouble(),
    );
    print('Created KitRental: kitId=${kitRental.kitId?.name}, quantity=${kitRental.quantity}, price=${kitRental.price}');
    return kitRental;
  }

  Map<String, dynamic> toJson() {
    return {
      'kitId': kitId?.toJson(),
      'quantity': quantity,
      'price': price,
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
  final FutsalDetails? futsal;
  final List<KitRental>? kitRentals;
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
    this.futsal,
    this.kitRentals,
    required this.createdAt,
    required this.updatedAt,
  });

  String? get courtName => futsal?.name;

  factory Booking.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (e) {
        print('Error parsing date: $value');
        return null;
      }
    }

    return Booking(
      id: json['_id']?.toString() ?? '',
      date: parseDate(json['date']) ?? DateTime.now(),
      startTime: json['startTime']?.toString() ?? '',
      endTime: json['endTime']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      totalPrice: (json['totalPrice'] ?? 0.0).toDouble(),
      user: json['user'] is Map<String, dynamic>
          ? BookingUser.fromJson(json['user'] as Map<String, dynamic>)
          : BookingUser(
              id: '',
              name: 'Unknown User',
              phone: '',
              email: '',
            ),
      futsal: json['futsal'] != null ? FutsalDetails.fromJson(json['futsal'] as Map<String, dynamic>) : null,
      kitRentals: (json['kitRentals'] as List<dynamic>?)?.map((item) {
        print('Processing kit rental item: $item');
        return KitRental.fromJson(item as Map<String, dynamic>);
      }).toList(),
      createdAt: parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: parseDate(json['updatedAt']) ?? DateTime.now(),
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
      'futsal': futsal?.toJson(),
      'kitRentals': kitRentals?.map((item) => item.toJson()).toList(),
    };
  }
} 