import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/kit.dart';
import 'api_service.dart';

class KitService extends ChangeNotifier {
  final ApiService _apiService;
  List<Kit> _kits = [];
  bool _isLoading = false;
  String? _error;

  KitService(this._apiService);

  List<Kit> get kits => List.unmodifiable(_kits);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchKits({String? type}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final Map<String, dynamic>? queryParams = type != null ? {'type': type} : null;
      final dynamic data = await _apiService.get('/api/kits/owner', queryParams: queryParams);
      
      if (data is List) {
        _kits = data.map((json) => Kit.fromJson(json)).toList();
        _error = null;
      } else {
        _kits = [];
        _error = 'Failed to load kits: Invalid response format';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Kit?> createKit({
    required String name,
    String? description,
    required String size,
    required int quantity,
    required double price,
    required String courtId,
    required String type,
    required List<String> images,
  }) async {
    try {
      final response = await _apiService.post(
        '/api/kits',
        body: {
          'name': name,
          if (description != null) 'description': description,
          'size': size,
          'quantity': quantity,
          'price': price,
          'futsal': courtId,
          'type': type,
          'images': images,
          'isAvailable': true,
        },
      );

      if (response.statusCode == 201) {
        final kit = Kit.fromJson(json.decode(response.body));
        _kits.add(kit);
        notifyListeners();
        return kit;
      }
      return null;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<Kit?> updateKit(String id, {
    String? name,
    String? description,
    String? size,
    int? quantity,
    double? price,
    String? type,
    bool? isAvailable,
  }) async {
    try {
      final response = await _apiService.put(
        '/kits/$id',
        body: {
          if (name != null) 'name': name,
          if (description != null) 'description': description,
          if (size != null) 'size': size,
          if (quantity != null) 'quantity': quantity,
          if (price != null) 'price': price,
          if (type != null) 'type': type,
          if (isAvailable != null) 'isAvailable': isAvailable,
        },
      );

      if (response.statusCode == 200) {
        final updatedKit = Kit.fromJson(json.decode(response.body));
        final index = _kits.indexWhere((kit) => kit.id == id);
        if (index != -1) {
          _kits[index] = updatedKit;
          notifyListeners();
        }
        return updatedKit;
      }
      return null;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> deleteKit(String id) async {
    try {
      final response = await _apiService.delete('/kits/$id');
      
      if (response.statusCode == 200) {
        _kits.removeWhere((kit) => kit.id == id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<List<Kit>> getKitsByCourt(String courtId) async {
    try {
      final data = await _apiService.get('/api/kits/futsal/$courtId');
      
      if (data is List) {
        print('Received ${data.length} kits from server');
        final kits = data.map((json) => Kit.fromJson(json)).toList();
        print('Successfully parsed ${kits.length} kits');
        return kits;
      }
      print('Invalid response format: $data');
      return [];
    } catch (e) {
      print('Error fetching kits: $e');
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getUserRentals(String userId) async {
    try {
      final response = await _apiService.get('/api/kit-bookings/user/$userId');
      
      if (response is List) {
        return List<Map<String, dynamic>>.from(response);
      }
      print('KitService: Invalid response format: $response');
      return [];
    } catch (e) {
      print('KitService: Error fetching user rentals: $e');
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }
} 