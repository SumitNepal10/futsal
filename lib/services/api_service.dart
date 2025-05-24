import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import '../models/user.dart';
import '../models/booking_model.dart' as booking_model;
import '../models/time_slot_model.dart';
import 'package:intl/intl.dart';


class ApiService extends ChangeNotifier {
  final String baseUrl = 'http://localhost:5000';
  String? _authToken;
  bool _isLoading = false;
  String? _error;
  final http.Client _client = http.Client();

  ApiService() {
    loadToken();
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _authToken != null;

  String? get authToken => _authToken;

  void _setLoading(bool value) {
    _isLoading = value;
    Future.microtask(() => notifyListeners());
  }

  void _setError(String? value) {
    _error = value;
    Future.microtask(() => notifyListeners());
  }

  Future<String?> setAuthToken(String token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    notifyListeners();
    return token;
  }

  Future<void> clearAuthToken() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    notifyListeners();
  }

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('token');
    notifyListeners();
  }

  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  Future<dynamic> get(String endpoint, {Map<String, dynamic>? queryParams, bool requireAuth = true}) async {
    try {
      _setLoading(true);
      _setError(null);

      final uri = Uri.parse('$baseUrl$endpoint').replace(
        queryParameters: queryParams?.map((key, value) => MapEntry(key, value.toString())),
      );

      final headers = requireAuth ? _headers : {'Content-Type': 'application/json'};

      final response = await http.get(
        uri,
        headers: headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get data: ${response.body}');
      }
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to post data: ${response.body}');
      }
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<dynamic> put(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to put data: ${response.body}');
      }
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<dynamic> patch(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await http.patch(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to patch data: ${response.body}');
      }
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<dynamic> delete(String endpoint) async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to delete data: ${response.body}');
      }
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Login and store token
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await post(
        '/api/auth/login',
        body: {
          'email': email,
          'password': password,
        },
      );
      
      if (response['status'] == 'success' && response['token'] != null) {
        await setAuthToken(response['token']);
        return response;
      } else {
        final errorMessage = response['message'] ?? 'Login failed: Invalid credentials';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        throw Exception('Cannot connect to server. Please check your internet connection.');
      }
      throw Exception('Login failed: ${e.toString()}');
    }
  }
  
  // Register and store token
  Future<Map<String, dynamic>> register(String name, String email, String password, String phone, String role) async {
    try {
      final response = await post(
        '/api/auth/register',
        body: {
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
          'role': role,
        },
      );
      
      if (response['status'] == 'success' && response['token'] != null) {
        await setAuthToken(response['token']);
      }
      
      return response;
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }
  
  // Logout and remove token
  Future<void> logout() async {
    await clearAuthToken();
  }

  // Get current user data
  Future<User> getCurrentUser() async {
    try {
      final response = await get('/api/auth/me');
      return User.fromJson(response['user']);
    } catch (e) {
      throw Exception('Failed to fetch user data: $e');
    }
  }

  // Get user's booking history
  Future<List<booking_model.Booking>> getUserBookings() async {
    try {
      final response = await get('/api/bookings/my-bookings');
      final List<dynamic> bookingsData = List<dynamic>.from(response);
      return bookingsData.map((json) => booking_model.Booking.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch booking history: $e');
    }
  }

  Future<Map<String, dynamic>> uploadFile(String endpoint, File file) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final request = http.MultipartRequest('POST', uri);
      
      // Add headers
      request.headers.addAll(_headers);
      
      // Add file
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          file.path,
        ),
      );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final decodedResponse = jsonDecode(responseData);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decodedResponse;
      } else {
        throw decodedResponse['message'] ?? 'Failed to upload file';
      }
    } catch (e) {
      throw 'Failed to upload file: $e';
    }
  }

  // Get futsal venues for owner
  Future<List<Map<String, dynamic>>> getOwnerVenues() async {
    try {
      final response = await get('/api/futsals/owner/me');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch owner venues: $e');
    }
  }

  // Get kit inventory for owner
  Future<List<Map<String, dynamic>>> getKitInventory() async {
    try {
      final response = await get('/api/kits/owner');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch kit inventory: $e');
    }
  }

  // Get kit rentals for owner
  Future<List<Map<String, dynamic>>> getKitRentals() async {
    try {
      final response = await get('/api/kits/rentals');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch kit rentals: $e');
    }
  }

  // Get bookings for owner
  Future<List<Map<String, dynamic>>> getOwnerBookings(String filter) async {
    try {
      print('Fetching owner bookings with filter: $filter');
      final response = await get('/api/bookings/owner?filter=$filter&include_kit_rentals=true');
      
      print('API Response type: ${response.runtimeType}');
      print('Full API Response: $response');
      
      List<Map<String, dynamic>> bookings;
      
      if (response is List) {
        print('Response is a List');
        bookings = List<Map<String, dynamic>>.from(response);
      } else if (response is Map && response['bookings'] != null) {
        print('Response is a Map with bookings key');
        bookings = List<Map<String, dynamic>>.from(response['bookings']);
      } else {
        print('Response is in unexpected format');
        return [];
      }
      
      print('Number of bookings: ${bookings.length}');
      for (var booking in bookings) {
        print('Booking ID: ${booking['_id']}');
        print('Booking User: ${booking['user']}');
        print('Booking Futsal: ${booking['futsal']}');
        print('Booking Kit Rentals: ${booking['kitRentals']}');
        if (booking['kitRentals'] != null) {
          print('Kit Rentals Type: ${booking['kitRentals'].runtimeType}');
          if (booking['kitRentals'] is List) {
            print('Number of Kit Rentals: ${booking['kitRentals'].length}');
            for (var rental in booking['kitRentals']) {
              print('Kit Rental Details: $rental');
            }
          }
        }
      }
      
      return bookings;
      
      return [];
    } catch (e) {
      print('Error in getOwnerBookings: $e'); // Debug log
      throw HttpException('Error fetching owner bookings: $e');
    }
  }

  // Get owner statistics
  Future<Map<String, dynamic>> getOwnerStats() async {
    try {
      final response = await get('/api/owner/stats');
      return response['data'];
    } catch (e) {
      throw Exception('Failed to fetch owner statistics: $e');
    }
  }

  // Get time slots for owner
  Future<List<Map<String, dynamic>>> getOwnerTimeSlots() async {
    try {
      final response = await get('/api/time-slots/owner');
      return List<Map<String, dynamic>>.from(response['data']);
    } catch (e) {
      throw Exception('Failed to fetch owner time slots: $e');
    }
  }

  // Create time slot
  Future<Map<String, dynamic>> createTimeSlot(String courtId, DateTime date) async {
    try {
      final response = await post(
        '/api/time-slots',
        body: {
          'courtId': courtId,
          'date': DateFormat('yyyy-MM-dd').format(date),
        },
      );
      return response;
    } catch (e) {
      throw Exception('Failed to create time slot: $e');
    }
  }

  // Update time slot availability
  Future<Map<String, dynamic>> updateTimeSlotAvailability(String slotId, bool isAvailable) async {
    try {
      final response = await patch(
        '/api/time-slots/$slotId/availability',
        body: {'isAvailable': isAvailable},
      );
      return response;
    } catch (e) {
      throw Exception('Failed to update time slot availability: $e');
    }
  }

  Future<List<dynamic>> getOwnerFutsals() async {
    try {
      final response = await get('/api/futsals/owner/me');
      if (response is List) {
        return response;
      } else if (response is Map && response.containsKey('data')) {
        return response['data'] as List;
      } else {
        throw 'Invalid response format from server';
      }
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }

  Future<http.MultipartRequest> createMultipartRequest(
    String endpoint,
    Map<String, dynamic> fields,
    dynamic file,
    String fileField,
  ) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final request = http.MultipartRequest('POST', uri);

    // Add headers
    request.headers.addAll({
      if (_authToken != null) 'Authorization': 'Bearer $_authToken',
    });

    // Add fields
    fields.forEach((key, value) {
      request.fields[key] = value.toString();
    });

    // Add file
    if (file is XFile) {
      final bytes = await file.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        fileField,
        bytes,
        filename: file.name,
        contentType: MediaType.parse('image/${file.name.split('.').last}'),
      );
      request.files.add(multipartFile);
    } else if (file is File) {
      final fileStream = http.ByteStream(file.openRead());
      final fileLength = await file.length();
      final multipartFile = http.MultipartFile(
        fileField,
        fileStream,
        fileLength,
        filename: file.path.split('/').last,
        contentType: MediaType.parse('image/${file.path.split('.').last}'),
      );
      request.files.add(multipartFile);
    } else {
      throw Exception('Invalid file type. Must be either File or XFile');
    }

    return request;
  }

  Future<Map<String, dynamic>> addFutsal({
    required String name,
    required String location,
    required double pricePerHour,
    required String description,
    required List<XFile> images,
    required String openingTime,
    required String closingTime,
    required List<String> facilities,
  }) async {
    try {
      if (pricePerHour <= 0) {
        throw Exception('Price must be greater than 0');
      }

      // Convert images to base64
      List<String> base64Images = [];
      for (var image in images) {
        final bytes = await image.readAsBytes();
        final base64Image = base64Encode(bytes);
        base64Images.add(base64Image);
      }

      final requestBody = {
        'name': name,
        'location': location,
        'pricePerHour': pricePerHour,
        'description': description,
        'images': base64Images,
        'openingTime': openingTime,
        'closingTime': closingTime,
        'facilities': facilities,
        'isAvailable': true,
        'rating': 0,
        'totalRatings': 0,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/futsals'),
        headers: {
          'Content-Type': 'application/json',
          if (_authToken != null) 'Authorization': 'Bearer $_authToken',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode >= 400) {
        throw response.body;
      }

      return json.decode(response.body);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }

  Future<void> addKit(Map<String, dynamic> kitData) async {
    final response = await post(
      '/api/kits',
      body: kitData,
    );
    if (response == null || (response is Map && response['error'] != null)) {
      throw Exception(response?['error'] ?? 'Failed to add kit');
    }
  }

  Future<List<TimeSlot>> getTimeSlots(String courtId, DateTime date) async {
    try {
      final response = await post(
        '/api/time-slots',
        body: {
          'courtId': courtId,
          'date': DateFormat('yyyy-MM-dd').format(date),
        },
      );
      return (response as List).map((json) => TimeSlot.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get time slots: $e');
    }
  }

  Future<void> uploadImage(String endpoint, XFile image) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$endpoint'));
      request.headers.addAll(_headers);
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          image.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to upload image: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<String> getCurrentUserId() async {
    try {
      final response = await get('/api/auth/me');
      return response['_id'];
    } catch (e) {
      throw Exception('Failed to get current user ID: $e');
    }
  }

}

class HttpException implements Exception {
  final String message;

  HttpException(this.message);

  @override
  String toString() {
    return message;
  }
}