import 'package:flutter/foundation.dart';
import '../models/booking.dart';
import 'api_service.dart';
import 'package:intl/intl.dart';

import '../models/time_slot.dart';

class BookingService extends ChangeNotifier {
  final ApiService _apiService;
  List<Booking> _bookings = [];
  bool _isLoading = false;
  String? _error;

  BookingService({required ApiService apiService}) : _apiService = apiService;

  List<Booking> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _setLoading(bool value) {
    _isLoading = value;
    Future.microtask(() => notifyListeners());
  }

  void _setError(String? value) {
    _error = value;
    Future.microtask(() => notifyListeners());
  }

  Future<void> fetchBookings() async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await _apiService.get('/api/bookings');
      _bookings = (response as List).map((json) => Booking.fromJson(json)).toList();

      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> fetchCourtBookings(String courtId, DateTime date) async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await _apiService.get(
        '/api/bookings/court/$courtId',
        queryParams: {'date': DateFormat('yyyy-MM-dd').format(date)},
      );
      _bookings = (response as List).map((json) => Booking.fromJson(json)).toList();

      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      rethrow;
    }
  }

  Future<Booking> createBooking(Map<String, dynamic> data) async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await _apiService.post(
        '/api/bookings',
        body: data,
      );

      if (response is Map<String, dynamic>) {
        final newBooking = Booking.fromJson(response);
        _bookings.add(newBooking);
        notifyListeners();
        _setLoading(false);
        return newBooking;
      } else {
        throw Exception('Unexpected response format from API. Expected Map, received ${response.runtimeType}');
      }
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> updateBookingStatus(String bookingId, String status) async {
    try {
      _setLoading(true);
      _setError(null);

      await _apiService.patch(
        '/api/bookings/$bookingId/status',
        body: {'status': status},
      );

      final index = _bookings.indexWhere((booking) => booking.id == bookingId);
      if (index != -1) {
        _bookings[index] = _bookings[index].copyWith(status: status);
        notifyListeners();
      }

      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> fetchOwnerBookings({String? filter}) async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await _apiService.get(
        '/api/bookings/owner',
        queryParams: {'status': filter},
      );
      _bookings = (response as List).map((json) => Booking.fromJson(json)).toList();

      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> updateBooking(String bookingId, Map<String, dynamic> data) async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await _apiService.patch(
        '/api/bookings/$bookingId',
        body: data,
      );

      final updatedBooking = Booking.fromJson(response);
      final index = _bookings.indexWhere((booking) => booking.id == bookingId);
      if (index != -1) {
        _bookings[index] = updatedBooking;
        notifyListeners();
      }

      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> deleteBooking(String bookingId) async {
    try {
      _setLoading(true);
      _setError(null);

      await _apiService.delete('/api/bookings/$bookingId');
      _bookings.removeWhere((booking) => booking.id == bookingId);
      notifyListeners();

      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      rethrow;
    }
  }

  Future<List<TimeSlot>> getAvailableSlots(String courtId, DateTime date) async {
    try {
      _setLoading(true);
      _setError(null);
      
      // Create a new date at midnight to avoid timezone issues
      final dateAtMidnight = DateTime(date.year, date.month, date.day);
      print('Original input date: ${date.toString()}');
      print('Date at midnight: ${dateAtMidnight.toString()}');
      
      final formattedDate = DateFormat('yyyy-MM-dd').format(dateAtMidnight);
      print('Formatted date for API: $formattedDate');
      print('Date components - Year: ${dateAtMidnight.year}, Month: ${dateAtMidnight.month}, Day: ${dateAtMidnight.day}');

      final response = await _apiService.get(
        '/api/bookings/available-slots/$courtId',
        queryParams: {
          'date': formattedDate,
        },
      );

      print('Available slots response type: ${response.runtimeType}');
      print('Available slots response: $response');
      
      List<TimeSlot> slots = [];
      if (response is List) {
        print('Response is a List');
        slots = response.map((json) => TimeSlot.fromJson(json)).toList();
      } else if (response is Map && response['slots'] != null) {
        print('Response is a Map with slots key');
        slots = (response['slots'] as List).map((json) => TimeSlot.fromJson(json)).toList();
      } else {
        print('Unexpected response format');
      }
      
      print('Parsed ${slots.length} time slots');

      _setLoading(false);
      return slots;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      rethrow;
    }
  }
} 