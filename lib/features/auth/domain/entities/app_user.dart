import 'package:equatable/equatable.dart';

class UserLocation extends Equatable {
  final double latitude;
  final double longitude;
  final String? address;
  final String? city;

  const UserLocation({
    required this.latitude,
    required this.longitude,
    this.address,
    this.city,
  });

  @override
  List<Object?> get props => [latitude, longitude, address, city];
}

class AppUser extends Equatable {
  final String id;
  final String email;
  final String displayName;
  final String role;
  final String? organizationName;
  final String? photoUrl;
  final String? phone;
  final UserLocation? location;
  final DateTime createdAt;
  final bool isVerified;
  final int reputationScore;
  final List<String>? fcmTokens;

  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    this.organizationName,
    this.photoUrl,
    this.phone,
    this.location,
    required this.createdAt,
    this.isVerified = false,
    this.reputationScore = 0,
    this.fcmTokens,
  });

  @override
  List<Object?> get props => [
        id,
        email,
        displayName,
        role,
        organizationName,
        photoUrl,
        phone,
        location,
        createdAt,
        isVerified,
        reputationScore,
        fcmTokens,
      ];

  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? role,
    String? organizationName,
    String? photoUrl,
    String? phone,
    UserLocation? location,
    DateTime? createdAt,
    bool? isVerified,
    int? reputationScore,
    List<String>? fcmTokens,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      organizationName: organizationName ?? this.organizationName,
      photoUrl: photoUrl ?? this.photoUrl,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      isVerified: isVerified ?? this.isVerified,
      reputationScore: reputationScore ?? this.reputationScore,
      fcmTokens: fcmTokens ?? this.fcmTokens,
    );
  }
}
