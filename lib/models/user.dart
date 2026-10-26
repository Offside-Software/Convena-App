class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.company,
    required this.organizationId,
    required this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final String company;
  final String organizationId;
  final String avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class AuthResponse {
  const AuthResponse({required this.token, required this.user});

  final String token;
  final User user;
}

class LoginCredentials {
  const LoginCredentials({required this.identifier, required this.password});

  final String identifier; // email or username
  final String password;
}

class RegisterPayload {
  const RegisterPayload({
    required this.name,
    required this.username,
    required this.email,
    required this.password,
  });

  final String name;
  final String username;
  final String email;
  final String password;
}
