import 'package:flutter/foundation.dart';
import 'api_service.dart';

class FieldService with ChangeNotifier {
  final ApiService _apiService = ApiService(baseUrl: 'http://localhost:5000/api');
  List<Map<String, dynamic>> _fields = [];
  Map<String, dynamic>? _selectedField;
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get fields => _fields;
  Map<String, dynamic>? get selectedField => _selectedField;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Clear error
  void _clearError() {
    _error = null;
  }

  // Set error
  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set fields
  void _setFields(List<Map<String, dynamic>> fields) {
    _fields = fields;
    notifyListeners();
  }

  // Set selected field
  void _setSelectedField(Map<String, dynamic>? field) {
    _selectedField = field;
    notifyListeners();
  }

  // Get all fields
  Future<bool> getFields() async {
    _clearError();
    _setLoading(true);
    
    try {
      final response = await _apiService.get('/fields');
      _setFields(List<Map<String, dynamic>>.from(response['fields']));
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Get field by ID
  Future<bool> getFieldById(String id) async {
    _clearError();
    _setLoading(true);
    
    try {
      final response = await _apiService.get('/fields/$id');
      _setSelectedField(response['field']);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Create new field (admin only)
  Future<bool> createField({
    required String name,
    required String description,
    required double price,
    required String imageUrl,
    required bool isAvailable,
  }) async {
    _clearError();
    _setLoading(true);
    
    try {
      final response = await _apiService.post('/fields', {
        'name': name,
        'description': description,
        'price': price,
        'imageUrl': imageUrl,
        'isAvailable': isAvailable,
      });
      
      // Add the new field to the list
      final newField = response['field'];
      _fields.add(newField);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Update field (admin only)
  Future<bool> updateField({
    required String id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    bool? isAvailable,
  }) async {
    _clearError();
    _setLoading(true);
    
    try {
      final Map<String, dynamic> data = {};
      if (name != null) data['name'] = name;
      if (description != null) data['description'] = description;
      if (price != null) data['price'] = price;
      if (imageUrl != null) data['imageUrl'] = imageUrl;
      if (isAvailable != null) data['isAvailable'] = isAvailable;
      
      final response = await _apiService.patch('/fields/$id', data);
      
      // Update the field in the list
      final updatedField = response['field'];
      final index = _fields.indexWhere((field) => field['_id'] == id);
      if (index != -1) {
        _fields[index] = updatedField;
      }
      
      // Update selected field if it's the one being updated
      if (_selectedField != null && _selectedField!['_id'] == id) {
        _setSelectedField(updatedField);
      }
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Delete field (admin only)
  Future<bool> deleteField(String id) async {
    _clearError();
    _setLoading(true);
    
    try {
      await _apiService.delete('/fields/$id');
      
      // Remove the field from the list
      _fields.removeWhere((field) => field['_id'] == id);
      
      // Clear selected field if it's the one being deleted
      if (_selectedField != null && _selectedField!['_id'] == id) {
        _setSelectedField(null);
      }
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Check field availability for a specific date and time
  Future<bool> checkAvailability(String id, DateTime date, String startTime, String endTime) async {
    _clearError();
    _setLoading(true);
    
    try {
      final queryParams = {
        'date': date.toIso8601String().split('T')[0],
        'startTime': startTime,
        'endTime': endTime,
      };
      
      final response = await _apiService.get('/fields/$id/availability?${Uri(queryParameters: queryParams).query}');
      
      _setLoading(false);
      return response['isAvailable'] ?? false;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }
} 