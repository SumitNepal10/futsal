class KitRental {
  final String id;
  final String kit;
  final String user;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final double totalPrice;
  final DateTime createdAt;

  KitRental({
    required this.id,
    required this.kit,
    required this.user,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.totalPrice,
    required this.createdAt,
  });

  factory KitRental.fromJson(Map<String, dynamic> json) {
    return KitRental(
      id: json['_id'],
      kit: json['kit'],
      user: json['user'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      status: json['status'],
      totalPrice: json['totalPrice'].toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'kit': kit,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
  }
} 