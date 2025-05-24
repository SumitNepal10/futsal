import 'package:flutter/foundation.dart';
import '../models/time_slot.dart';
import 'api_service.dart';

class TimeSlotService extends ChangeNotifier {
  final ApiService _apiService;
  List<TimeSlot> _timeSlots = [];
  bool _isLoading = false;
  String? _error;

  TimeSlotService(this._apiService);

  List<TimeSlot> get timeSlots => _timeSlots;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchTimeSlots(String fieldId, DateTime date) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.get(
        '/api/bookings/available-slots/${fieldId}',
        queryParams: {
          'date': date.toIso8601String(),
        },
      );

      // The response format is {slots: [...]} for the available-slots endpoint
      if (response['slots'] != null) {
        _timeSlots = (response['slots'] as List)
            .map((json) => TimeSlot.fromJson(json))
            .toList();
      } else {
        _timeSlots = [];
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<TimeSlot?> createTimeSlot({
    required String fieldId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.post(
        '/api/time-slots',
        body: {
          'field': fieldId,
          'startTime': startTime.toIso8601String(),
          'endTime': endTime.toIso8601String(),
        },
      );

      final newTimeSlot = TimeSlot.fromJson(response['data']);
      _timeSlots.add(newTimeSlot);
      return newTimeSlot;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateTimeSlotAvailability(String timeSlotId, bool isAvailable) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _apiService.put(
        '/api/time-slots/$timeSlotId',
        body: {
          'isAvailable': isAvailable,
        },
      );

      final index = _timeSlots.indexWhere((slot) => slot.id == timeSlotId);
      if (index != -1) {
        final timeSlot = _timeSlots[index];
        _timeSlots[index] = TimeSlot(
          id: timeSlot.id,
          startTime: timeSlot.startTime,
          endTime: timeSlot.endTime,
          isAvailable: isAvailable,
          price: timeSlot.price,
        );
      }

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
} 