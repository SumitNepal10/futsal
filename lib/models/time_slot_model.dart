import 'package:intl/intl.dart';
import 'field_model.dart';

class TimeSlot {
  final String id;
  final Field field;
  final String startTime;
  final String endTime;
  final double price;
  final bool isAvailable;
  final DateTime date;

  TimeSlot({
    required this.id,
    required this.field,
    required this.startTime,
    required this.endTime,
    required this.price,
    required this.isAvailable,
    required this.date,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      id: json['_id'] ?? json['id'],
      field: Field.fromJson(json['field']),
      startTime: json['startTime'],
      endTime: json['endTime'],
      price: (json['price'] as num).toDouble(),
      isAvailable: json['isAvailable'] ?? true,
      date: DateTime.parse(json['date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'field': field.toJson(),
      'startTime': startTime,
      'endTime': endTime,
      'price': price,
      'isAvailable': isAvailable,
      'date': date.toIso8601String(),
    };
  }

  String get formattedTime {
    final format = DateFormat('h:mm a');
    return '${format.format(DateTime.parse(startTime))} - ${format.format(DateTime.parse(endTime))}';
  }
} 