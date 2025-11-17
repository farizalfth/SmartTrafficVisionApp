// lib/models/user.dart
enum UserRole { admin, operator, analyst, guest }

class User {
  final String id;
  final String username;
  final String email;
  final UserRole role;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      role: UserRole.values.firstWhere((e) => e.toString().split('.').last == json['role']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role': role.toString().split('.').last,
    };
  }
}