class User {
  final String id;
  final String displayName;
  final String name;
  final String username;
  final String email;
  final String role;
  final String? company;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const User({
    required this.id,
    required this.displayName,
    required this.name,
    required this.username,
    required this.email,
    required this.role,
    this.company,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final dName = json['displayName'] as String? ?? json['name'] as String? ?? '';
    final uName = json['username'] as String? ?? '';
    return User(
      id: json['id'] as String? ?? '',
      displayName: dName.isNotEmpty ? dName : uName,
      name: (json['name'] as String? ?? dName).isNotEmpty ? (json['name'] as String? ?? dName) : uName,
      username: uName,
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
      company: json['company'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'name': name,
      'username': username,
      'email': email,
      'role': role,
      'company': company,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class AuthResponse {
  final String token;
  final User user;

  const AuthResponse({required this.token, required this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String? ?? '',
      user: User.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class LoginCredentials {
  final String identifier; // email or username
  final String password;

  const LoginCredentials({required this.identifier, required this.password});

  Map<String, dynamic> toJson() {
    return {
      'identifier': identifier,
      'password': password,
    };
  }
}

class RegisterPayload {
  final String username;
  final String email;
  final String password;
  final String? name;
  final String? displayName;

  const RegisterPayload({
    required this.username,
    required this.email,
    required this.password,
    this.name,
    this.displayName,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'password': password,
      if (name != null) 'name': name,
      if (displayName != null) 'displayName': displayName,
    };
  }
}
