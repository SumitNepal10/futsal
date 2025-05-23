import 'package:flutter/foundation.dart';
import '../models/kit_rental.dart';
import 'api_service.dart';

class KitRentalService extends ChangeNotifier {
  final ApiService _apiService;
  List<KitRental> _rentals = [];
  bool _isLoading = false;
  String? _error;

  KitRentalService(this._apiService);

  List<KitRental> get rentals => _rentals;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchRentals() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getKitRentals();
      _rentals = response.map((json) => KitRental.fromJson(json)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<KitRental> createRental({
    required String kitId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.createKitRental(
        kitId: kitId,
        startDate: startDate,
        endDate: endDate,
      );
      final rental = KitRental.fromJson(response);
      _rentals.add(rental);
      return rental;
    } catch (e) {
      _error = e.toString();
      rethrow;
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