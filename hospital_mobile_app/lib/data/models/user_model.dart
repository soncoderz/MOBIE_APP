import '../../domain/entities/user.dart';

/// User model - data layer with JSON serialization
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    required super.fullName,
    super.phone,
    super.phoneNumber,
    super.avatar,
    super.avatarUrl,
    super.address,
    super.gender,
    super.dateOfBirth,
    required super.role,
    required super.createdAt,
  });

  /// Create UserModel from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Handle avatar field - can be String, Map, or null
    String? avatarValue;
    final avatarData = json['avatar'];
    if (avatarData is String) {
      avatarValue = avatarData;
    } else if (avatarData is Map<String, dynamic>) {
      // Server returns avatar as an object with url/secureUrl
      avatarValue = avatarData['secureUrl'] ?? avatarData['url'];
    }
    
    // Handle dateOfBirth field - can be String, DateTime ISO string, or null
    String? dateOfBirthValue;
    final dobData = json['dateOfBirth'];
    if (dobData is String) {
      // If it's a full ISO string with time, extract just the date part
      if (dobData.contains('T')) {
        dateOfBirthValue = dobData.split('T').first;
      } else {
        dateOfBirthValue = dobData;
      }
    }
    
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      phone: json['phone'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      avatar: avatarValue,
      avatarUrl: json['avatarUrl'] as String?,
      address: json['address'] as String?,
      gender: json['gender'] as String?,
      dateOfBirth: dateOfBirthValue,
      role: json['role'] ?? json['roleType'] ?? 'patient',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  /// Convert UserModel to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'phoneNumber': phoneNumber,
      'avatar': avatar,
      'avatarUrl': avatarUrl,
      'address': address,
      'gender': gender,
      'dateOfBirth': dateOfBirth,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create User entity from UserModel
  User toEntity() {
    return User(
      id: id,
      email: email,
      fullName: fullName,
      phone: phone,
      phoneNumber: phoneNumber,
      avatar: avatar,
      avatarUrl: avatarUrl,
      address: address,
      gender: gender,
      dateOfBirth: dateOfBirth,
      role: role,
      createdAt: createdAt,
    );
  }

  /// Create UserModel from User entity
  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      email: user.email,
      fullName: user.fullName,
      phone: user.phone,
      phoneNumber: user.phoneNumber,
      avatar: user.avatar,
      avatarUrl: user.avatarUrl,
      address: user.address,
      gender: user.gender,
      dateOfBirth: user.dateOfBirth,
      role: user.role,
      createdAt: user.createdAt,
    );
  }
}
