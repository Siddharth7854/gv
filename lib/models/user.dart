class User {
  final String userId;
  final String email;
  final String fullName;
  final String role;
  final bool isActive;
  final DateTime createdAt;
  final String? photoUrl;
  final String? block;
  final String? district;
  final String? ward;
  final String? address;
  final String? pincode;

  const User({
    required this.userId,
    required this.email,
    required this.fullName,
    required this.role,
    this.isActive = true,
    required this.createdAt,
    this.photoUrl,
    this.block,
    this.district,
    this.ward,
    this.address,
    this.pincode,
  });

  // Getter for backward compatibility
  String get name => fullName;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: (json['userId'] ?? json['citizen_id'] ?? json['id'] ?? '').toString(),
      email: json['email'] as String? ?? '',
      fullName: json['fullName'] as String? ?? json['full_name'] as String? ?? '',
      role: json['role'] as String? ?? 'citizen',
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      photoUrl: json['photoUrl'] as String? ?? json['photo_url'] as String?,
      block: json['block'] as String? ?? '',
      district: json['district'] as String? ?? '',
      ward: json['ward'] as String? ?? '',
      address: json['address'] as String? ?? '',
      pincode: json['pincode'] as String? ?? '',
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
      'block': block,
      'district': district,
      'ward': ward,
      'address': address,
      'pincode': pincode,
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
    String? block,
    String? district,
    String? ward,
    String? address,
    String? pincode,
  }) {
    return User(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      photoUrl: photoUrl ?? this.photoUrl,
      block: block ?? this.block,
      district: district ?? this.district,
      ward: ward ?? this.ward,
      address: address ?? this.address,
      pincode: pincode ?? this.pincode,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.userId == userId &&
        other.email == email &&
        other.fullName == fullName &&
        other.role == role &&
        other.isActive == isActive &&
        other.createdAt == createdAt &&
        other.photoUrl == photoUrl;
  }

  @override
  int get hashCode {
    return userId.hashCode ^
        email.hashCode ^
        fullName.hashCode ^
        role.hashCode ^
        isActive.hashCode ^
        createdAt.hashCode ^
        photoUrl.hashCode;
  }

  @override
  String toString() {
    return 'User(userId: $userId, fullName: $fullName, email: $email, role: $role)';
  }
}
