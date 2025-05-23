import 'time_slot.dart';
import 'kit.dart';

class FutsalCourt {
  final String id;
  final String name;
  final String location;
  final String description;
  final String owner;
  final double pricePerHour;
  final List<String?>? images; // Made images nullable list of nullable strings
  final List<TimeSlot>? timeSlots; // Made timeSlots nullable list
  final List<Kit>? availableKits; // Made availableKits nullable list
  final String openingTime;
  final String closingTime;
  final bool isAvailable; // Added isAvailable
  final double rating; // Added rating
  final int totalRatings; // Added totalRatings
  final List<String> facilities; // Added facilities
  final DateTime createdAt;
  final DateTime updatedAt;

  FutsalCourt({
    required this.id,
    required this.name,
    required this.location,
    required this.description,
    required this.owner,
    required this.pricePerHour,
    this.images, // Made images optional
    this.timeSlots, // Made timeSlots optional
    this.availableKits, // Made availableKits optional
    required this.openingTime,
    required this.closingTime,
    required this.isAvailable, // Made isAvailable required in constructor
    required this.rating, // Made rating required in constructor
    required this.totalRatings, // Added to constructor
    required this.facilities, // Added to constructor
    required this.createdAt,
    required this.updatedAt,
  });

  factory FutsalCourt.fromJson(Map<String, dynamic> json) {
    try {
      // Handle owner field which could be an object or string
      String ownerId = '';
      if (json['owner'] is Map) {
        ownerId = json['owner']['_id']?.toString() ?? '';
      } else {
        ownerId = json['owner']?.toString() ?? '';
      }

      return FutsalCourt(
        id: json['_id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        location: json['location']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        owner: ownerId,
        pricePerHour: (json['pricePerHour'] is num) ? (json['pricePerHour'] as num).toDouble() : 0.0,
        images: (json['images'] as List?)?.map((img) => img?.toString()).toList(),
        timeSlots: (json['timeSlots'] as List?)
            ?.map((slot) => TimeSlot.fromJson(slot as Map<String, dynamic>))
            .toList(),
        availableKits: (json['availableKits'] as List?)
            ?.map((kit) => Kit.fromJson(kit as Map<String, dynamic>))
            .toList(),
        openingTime: json['openingTime']?.toString() ?? '08:00',
        closingTime: json['closingTime']?.toString() ?? '22:00',
        isAvailable: json['isAvailable'] as bool? ?? true,
        rating: (json['rating'] is num) ? (json['rating'] as num).toDouble() : 0.0,
        totalRatings: (json['totalRatings'] is num) ? (json['totalRatings'] as num).toInt() : 0,
        facilities: (json['facilities'] as List?)?.map((f) => f.toString()).toList() ?? [],
        createdAt: json['createdAt'] != null 
            ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null 
            ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );
    } catch (e) {
      // Added print for debugging if fromJson fails
      print('Error parsing FutsalCourt from JSON: $e\nJSON: $json');
      rethrow; // Rethrow the exception after printing
    }
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id, // Include id in toJson
      'name': name,
      'location': location,
      'description': description,
      'owner': owner,
      'pricePerHour': pricePerHour,
      'images': images, // Should handle nullable list and items automatically
      'timeSlots': timeSlots?.map((slot) => slot.toJson()).toList(), // Handle nullable list
      'availableKits': availableKits?.map((kit) => kit.toJson()).toList(), // Handle nullable list
      'openingTime': openingTime,
      'closingTime': closingTime,
      'isAvailable': isAvailable, // Include isAvailable in toJson
      'rating': rating, // Include rating in toJson
      'totalRatings': totalRatings, // Added to JSON
      'facilities': facilities, // Added to JSON
      'createdAt': createdAt.toIso8601String(), // Convert DateTime to String
      'updatedAt': updatedAt.toIso8601String(), // Convert DateTime to String
    };
  }
} 