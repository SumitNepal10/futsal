class TimeSlot {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final bool isAvailable;
  final double price;

  TimeSlot({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
    required this.price,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    // Parse the time strings (HH:mm)
    final timeFormat = RegExp(r'^([0-9]{1,2}):([0-9]{2})(?::([0-9]{2}))?$');
    final startMatch = timeFormat.firstMatch(json['startTime']);
    final endMatch = timeFormat.firstMatch(json['endTime']);
    
    if (startMatch == null || endMatch == null) {
      throw FormatException('Invalid time format in JSON: ${json['startTime']} - ${json['endTime']}');
    }
    
    final now = DateTime.now();
    DateTime date;
    
    // If it's past 9 PM, use tomorrow's date for the slots
    if (now.hour >= 21) {
      date = DateTime(now.year, now.month, now.day + 1);
    } else {
      date = DateTime(now.year, now.month, now.day);
    }
    
    return TimeSlot(
      id: json['_id'] ?? json['id'] ?? '',
      startTime: date.add(Duration(
        hours: int.parse(startMatch.group(1)!),
        minutes: int.parse(startMatch.group(2)!),
      )),
      endTime: date.add(Duration(
        hours: int.parse(endMatch.group(1)!),
        minutes: int.parse(endMatch.group(2)!),
      )),
      isAvailable: json['isAvailable'] ?? true,
      price: (json['price'] ?? 0.0).toDouble(),
    );
  }

  // Format the time as HH:MM
  String get formattedStartTime => '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
  String get formattedEndTime => '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
  
  // Get a nicely formatted time range string
  String get formattedTimeRange => '$formattedStartTime - $formattedEndTime';
  
  // Get a formatted date string (May 24, 2025)
  String get formattedDate => '${_getMonthName(startTime.month)} ${startTime.day}, ${startTime.year}';
  
  // Get a short formatted date string (May 24)
  String get formattedShortDate => '${_getMonthName(startTime.month)} ${startTime.day}';
  
  // Get the month name from the month number
  String _getMonthName(int month) {
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return monthNames[month - 1];
  }
  
  // Get a formatted time with date
  String get formattedTimeWithDate => '$formattedTimeRange ($formattedShortDate)';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': formattedStartTime,
      'endTime': formattedEndTime,
      'price': price,
      'isAvailable': isAvailable,
    };
  }
  
  @override
  String toString() {
    return formattedTimeRange;
  }
} 