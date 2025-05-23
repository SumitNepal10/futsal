import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/kit_booking.dart';
import 'api_service.dart';
import 'auth_service.dart';

class KitBookingService extends ChangeNotifier {
  final ApiService _apiService;
  final AuthService _authService;
  String? _error;
  bool _isLoading = false;

  KitBookingService(this._apiService, this._authService);

  String? get error => _error;
  bool get isLoading => _isLoading;

  Future<KitBooking> createKitBooking({
    required String futsalId,
    required String bookingId,
    required List<Map<String, dynamic>> kitRentals,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('Creating kit booking with data:');
      print('futsalId: $futsalId');
      print('bookingId: $bookingId');
      print('kitRentals: $kitRentals');

      final dynamic responseData = await _apiService.post(
        '/api/kit-bookings',
        body: {
          'futsal': futsalId,
          'booking': bookingId,
          'kitRentals': kitRentals,
        },
      );

      print('Successfully created kit booking.');
      return KitBooking.fromJson(responseData as Map<String, dynamic>);

    } catch (e) {
      print('Error creating kit booking: $e');
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<KitBooking>> getUserKitBookings() async {
    try {
      print('KitBookingService: Starting getUserKitBookings');
      _isLoading = true;
      _error = null;
      notifyListeners();

      final userId = _authService.currentUser?.id;
      if (userId == null) {
        print('KitBookingService: No authenticated user found.');
        throw Exception('User not authenticated.');
      }

      print('KitBookingService: Current user ID: $userId');
      
      print('KitBookingService: Making API call to /api/kit-bookings/user/$userId');
      final responseData = await _apiService.get(
        '/api/kit-bookings/user/$userId',
        requireAuth: false
      );
      print('KitBookingService: API Response received: $responseData');

      final List<dynamic> data = responseData;
      final bookings = data.map((json) => KitBooking.fromJson(json as Map<String, dynamic>)).toList();
      print('KitBookingService: Successfully parsed ${bookings.length} bookings');
      return bookings;

    } catch (e) {
      print('KitBookingService: Error in getUserKitBookings: $e');
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<KitBooking>> getFutsalKitBookings(String futsalId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final responseData = await _apiService.get('/api/kit-bookings/futsal/$futsalId');

      final List<dynamic> data = responseData;
      return data.map((json) => KitBooking.fromJson(json as Map<String, dynamic>)).toList();

    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<KitBooking> updateKitBookingStatus(String bookingId, String status) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final responseData = await _apiService.put(
        '/api/kit-bookings/$bookingId/status',
        body: {'status': status},
      );

      return KitBooking.fromJson(responseData as Map<String, dynamic>);

    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 