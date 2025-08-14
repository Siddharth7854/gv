class User {
  final String userId;
  final String email;
  final String fullName;
  final String role;
  final bool isActive;
  final DateTime createdAt;
  final String? photoUrl;

  const User({
    required this.userId,
    required this.email,
    required this.fullName,
    required this.role,
    this.isActive = true,
    required this.createdAt,
    this.photoUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      role: json['role'] as String,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      photoUrl: json['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'fullName': fullName,
      'role': role,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'photoUrl': photoUrl,
    };
  }

  User copyWith({
    String? userId,
    String? email,
    String? fullName,
    String? role,
    bool? isActive,
    DateTime? createdAt,
    String? photoUrl,
  }) {
    return User(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
