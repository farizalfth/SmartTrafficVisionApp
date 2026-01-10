enum UserRole { admin, operator, analyst, guest, user }

class User {
  final String id;
  final String username;
  final String email;
  final UserRole role;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.role, required String profilePictureUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      role: UserRole.values.firstWhere((e) => e.toString().split('.').last == json['role']), profilePictureUrl: '',
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