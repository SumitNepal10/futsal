import 'package:flutter/foundation.dart';
import 'api_service.dart';

class PaymentService extends ChangeNotifier {
  final ApiService _apiService = ApiService(baseUrl: 'http://localhost:5000/api');
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  // Process payment
  Future<Map<String, dynamic>?> processPayment({
    required String bookingId,
    required double amount,
    required String paymentMethod,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.post('/payments/process', {
        'bookingId': bookingId,
        'amount': amount,
        'paymentMethod': paymentMethod,
      });

      if (response['status'] == 'success') {
        return response['data'];
      }
      return null;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Get payment methods
  Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.get('/payments/methods');
      if (response['status'] == 'success') {
        return List<Map<String, dynamic>>.from(response['data']);
      }
      return [];
    } catch (e) {
      _setError(e.toString());
      return [];
    } finally {
      _setLoading(false);
    }
  }

  // Get payment history
  Future<List<Map<String, dynamic>>> getPaymentHistory() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.get('/payments/history');
      if (response['status'] == 'success') {
        return List<Map<String, dynamic>>.from(response['data']);
      }
      return [];
    } catch (e) {
      _setError(e.toString());
      return [];
    } finally {
      _setLoading(false);
    }
  }

  // Refund payment
  Future<bool> refundPayment(String paymentId) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.post('/payments/$paymentId/refund', {});
      return response['status'] == 'success';
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
} 