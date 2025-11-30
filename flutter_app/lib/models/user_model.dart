// User model for the Flutter app
class User {
  final int id;
  final String email;
  final String username;
  final String? profilePhoto;

  User({
    required this.id,
    required this.email,
    required this.username,
    this.profilePhoto,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      profilePhoto: json['profilePhoto'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'profilePhoto': profilePhoto,
    };
  }
}
