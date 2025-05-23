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
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['_id'] ?? json['id'],
      futsal: json['futsal'],
      futsalName: json['futsalName'] ?? '',
      date: DateTime.parse(json['date']),
      startTime: json['startTime'],
      endTime: json['endTime'],
      totalPrice: (json['totalPrice'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'pending',
      kitRentals: List<Map<String, dynamic>>.from(json['kitRentals'] ?? []),
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
    );
  }
} 