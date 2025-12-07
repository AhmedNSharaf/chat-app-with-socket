// User model for the Flutter app
class User {
  final int id;
  final String email;
  final String username;
  final String? profilePhoto;
  final bool isOnline;
  final String? lastSeen;
  final String status; // online, offline, away, busy
  final String? customStatus;

  User({
    required this.id,
    required this.email,
    required this.username,
    this.profilePhoto,
    this.isOnline = false,
    this.lastSeen,
    this.status = 'offline',
    this.customStatus,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      profilePhoto: json['profilePhoto'],
      isOnline: json['isOnline'] ?? false,
      lastSeen: json['lastSeen'],
      status: json['status'] ?? 'offline',
      customStatus: json['customStatus'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'profilePhoto': profilePhoto,
      'isOnline': isOnline,
      'lastSeen': lastSeen,
      'status': status,
      'customStatus': customStatus,
    };
  }

  User copyWith({
    int? id,
    String? email,
    String? username,
    String? profilePhoto,
    bool? isOnline,
    String? lastSeen,
    String? status,
    String? customStatus,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      status: status ?? this.status,
      customStatus: customStatus ?? this.customStatus,
    );
  }
}
