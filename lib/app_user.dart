import 'package:equatable/equatable.dart';
import '../../../core/constants/app_constants.dart';

class AppUser extends Equatable {
  final String id;
  final String email;
  final String displayName;
  final String role;
  final String? photoUrl;
  final String? phone;
  final String? organizationName;
  final UserLocation? location;
  final DateTime createdAt;
  final bool isVerified;
  final double reputationScore;

  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    this.photoUrl,
    this.phone,
    this.organizationName,
    this.location,
    required this.createdAt,
    this.isVerified = false,
    this.reputationScore = 5.0,
  });

  bool get isDonor => role == AppConstants.roleDonor;
  bool get isNgo => role == AppConstants.roleNgo;
  bool get isVolunteer => role == AppConstants.roleVolunteer;
  bool get isCommunity => role == AppConstants.roleCommunity;
  bool get isAdmin => role == AppConstants.roleAdmin;

  String get roleLabel {
    switch (role) {
      case AppConstants.roleDonor:
        return 'Donante';
      case AppConstants.roleNgo:
        return 'ONG / Banco de Alimentos';
      case AppConstants.roleVolunteer:
        return 'Voluntario';
      case AppConstants.roleCommunity:
        return 'Comunidad';
      case AppConstants.roleAdmin:
        return 'Administrador';
      default:
        return 'Usuario';
    }
  }

  AppUser copyWith({
    String? displayName,
    String? photoUrl,
    String? phone,
    String? organizationName,
    UserLocation? location,
    bool? isVerified,
    double? reputationScore,
  }) {
    return AppUser(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      role: role,
      photoUrl: photoUrl ?? this.photoUrl,
      phone: phone ?? this.phone,
      organizationName: organizationName ?? this.organizationName,
      location: location ?? this.location,
      createdAt: createdAt,
      isVerified: isVerified ?? this.isVerified,
      reputationScore: reputationScore ?? this.reputationScore,
    );
  }

  @override
  List<Object?> get props => [id, email, role];
}

class UserLocation extends Equatable {
  final double latitude;
  final double longitude;
  final String? address;
  final String? city;
  final String? state;

  const UserLocation({
    required this.latitude,
    required this.longitude,
    this.address,
    this.city,
    this.state,
  });

  @override
  List<Object?> get props => [latitude, longitude];
}
