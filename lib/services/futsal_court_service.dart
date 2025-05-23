import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/futsal_court.dart';
import '../models/time_slot.dart';
import '../models/kit.dart';
import 'api_service.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:provider/provider.dart';
import 'auth_service.dart';
import 'package:collection/collection.dart'; // Import for listEquals

class FutsalCourtService extends ChangeNotifier {
  final ApiService _apiService;
  List<FutsalCourt> _courts = [];
  bool _isLoading = false;
  String? _error;
  bool _isDisposed = false;
  bool _isOwnerView = false;

  FutsalCourtService({required ApiService apiService}) : _apiService = apiService;

  List<FutsalCourt> get courts => List.unmodifiable(_courts);
  List<FutsalCourt> get ownerCourts => _isOwnerView ? List.unmodifiable(_courts) : [];
  bool get isLoading => _isLoading;
  String? get error => _error;

  @override
  void addListener(VoidCallback listener) {
    if (!_isDisposed) {
      super.addListener(listener);
    }
  }

  @override
  void removeListener(VoidCallback listener) {
    if (!_isDisposed) {
      super.removeListener(listener);
    }
  }

  void _setLoading(bool value) {
    if (!_isDisposed && _isLoading != value) {
      _isLoading = value;
      notifyListeners();
    }
  }

  void _setError(String? value) {
    if (!_isDisposed && _error != value) {
      _error = value;
      notifyListeners();
    }
  }

  void _setCourts(List<FutsalCourt> newCourts, {bool isOwnerView = false}) {
    if (!_isDisposed && (!listEquals(_courts, newCourts) || _isOwnerView != isOwnerView)) {
      _courts = newCourts;
      _isOwnerView = isOwnerView;
      notifyListeners();
    }
  }

  Future<List<FutsalCourt>> fetchOwnerCourts() async {
    if (_isDisposed) {
      throw Exception('FutsalCourtService has been disposed');
    }

    final completer = Completer<List<FutsalCourt>>();
    _setLoading(true);
    _setError(null);

    try {
      final dynamic response = await _apiService.get('/api/futsals/owner/me');

      if (response is List) {
        final newCourts = response.map((json) {
          try {
            return FutsalCourt.fromJson(json);
          } catch (e) {
            return null;
          }
        }).whereType<FutsalCourt>().toList();
        
        _setCourts(newCourts, isOwnerView: true);
        completer.complete(_courts);
      } else {
        const error = 'Invalid response format';
        _setError(error);
        completer.completeError(Exception(error));
      }
    } catch (e) {
      _setError(e.toString());
      completer.completeError(e);
    } finally {
      _setLoading(false);
    }

    return completer.future;
  }

  Future<void> fetchCourts() async {
    if (_isDisposed) {
      throw Exception('FutsalCourtService has been disposed');
    }

    final completer = Completer<void>();
    _setLoading(true);
    _setError(null);

    try {
      final response = await _apiService.get('/api/futsals', requireAuth: false);

      if (response is List) {
        final newCourts = response.map((json) => FutsalCourt.fromJson(json)).toList();
        _setCourts(newCourts, isOwnerView: false);
        completer.complete();
      } else {
        _setCourts([], isOwnerView: false);
        completer.complete();
      }
    } catch (e) {
      _setError(e.toString());
      completer.completeError(e);
    } finally {
      _setLoading(false);
    }

    return completer.future;
  }

  Future<FutsalCourt> createCourt(Map<String, dynamic> data) async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await _apiService.post(
        '/api/futsals',
        body: data,
      );

      final newCourt = FutsalCourt.fromJson(response);
      final updatedCourts = List<FutsalCourt>.from(_courts)..add(newCourt);
      _setCourts(updatedCourts, isOwnerView: _isOwnerView);

      _setLoading(false);
      return newCourt;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      rethrow;
    }
  }

  Future<FutsalCourt> updateCourt(String courtId, Map<String, dynamic> data) async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await _apiService.put(
        '/api/futsals/$courtId',
        body: data,
      );

      final updatedCourt = FutsalCourt.fromJson(response);
      final updatedCourts = List<FutsalCourt>.from(_courts);
      final index = updatedCourts.indexWhere((court) => court.id == courtId);
      if (index != -1) {
        updatedCourts[index] = updatedCourt;
        _setCourts(updatedCourts, isOwnerView: _isOwnerView);
      }

      _setLoading(false);
      return updatedCourt;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> deleteCourt(String courtId) async {
    try {
      _setLoading(true);
      _setError(null);

      await _apiService.delete('/api/futsals/$courtId');
      final updatedCourts = List<FutsalCourt>.from(_courts)
        ..removeWhere((court) => court.id == courtId);
      _setCourts(updatedCourts, isOwnerView: _isOwnerView);

      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      rethrow;
    }
  }

  Future<String> convertImageToBase64(List<int> imageBytes) async {
    return base64Encode(imageBytes);
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
} 