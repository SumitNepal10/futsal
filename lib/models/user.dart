class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? profilePicture;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.profilePicture,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? '',
      phone: json['phone'] as String?,
      profilePicture: json['profilePicture'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
    };
    if (phone != null) {
      data['phone'] = phone;
    }
    if (profilePicture != null) {
      data['profilePicture'] = profilePicture;
    }
    return data;
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? phone,
    String? profilePicture,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      profilePicture: profilePicture ?? this.profilePicture,
    );
  }
} 