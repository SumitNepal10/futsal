import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/auth_response.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  final ApiService _apiService;
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  AuthService({required ApiService apiService}) : _apiService = apiService {
    _loadUser();
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  User? get currentUser => _currentUser;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson != null) {
      _currentUser = User.fromJson(jsonDecode(userJson));
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await _apiService.post(
        '/api/auth/login',
        body: {
          'email': email,
          'password': password,
        },
      );

      final authResponse = AuthResponse.fromJson(response);
      if (authResponse.token != null) {
        await _apiService.setAuthToken(authResponse.token!);
      } else {
        await _apiService.clearAuthToken();
      }

      _currentUser = authResponse.user;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(_currentUser!.toJson()));

      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> register(String name, String email, String password, String role) async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await _apiService.post(
        '/api/auth/register',
        body: {
          'name': name,
          'email': email,
          'password': password,
          'role': role,
        },
      );

      final authResponse = AuthResponse.fromJson(response);
      if (authResponse.token != null) {
        await _apiService.setAuthToken(authResponse.token!);
      } else {
        await _apiService.clearAuthToken();
      }

      _currentUser = authResponse.user;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(_currentUser!.toJson()));

      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.clearAuthToken();
      _currentUser = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user');
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }

  // Get user profile
  Future<bool> getUserProfile() async {
    _setLoading(true);
    _setError(null);
    
    try {
      final response = await _apiService.get('/users/profile');
      _currentUser = User.fromJson(response);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Update user profile
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final response = await _apiService.patch(
        '/api/auth/profile',
        body: data,
      );
      _currentUser = User.fromJson(response);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(_currentUser!.toJson()));

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Change password
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _setLoading(true);
    _setError(null);
    
    try {
      await _apiService.patch(
        '/api/auth/change-password',
        body: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _setError(null);
    
    try {
      await _apiService.post(
        '/api/auth/reset-password',
        body: {
          'email': email,
        },
      );
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<User> getCurrentUser() async {
    try {
      final response = await _apiService.get('/api/auth/me');
      return User.fromJson(response['user']);
    } catch (e) {
      throw Exception('Get current user error: $e');
    }
  }
} 