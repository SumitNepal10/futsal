import 'user.dart';

class AuthResponse {
  final String? token;
  final User user;
  final String? redirectPath;

  AuthResponse({
    required this.token,
    required this.user,
    required this.redirectPath,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String?,
      user: User.fromJson(json['user']),
      redirectPath: json['redirectPath'] as String?,
    );
  }
} 