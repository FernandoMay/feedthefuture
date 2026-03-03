import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feed_the_future/features/auth/domain/entities/app_user.dart';

class AppUserModel extends AppUser {
  const AppUserModel({
    required super.id,
    required super.email,
    required super.displayName,
    required super.role,
    super.organizationName,
    super.photoUrl,
    super.phone,
    super.location,
    required super.createdAt,
    super.isVerified = false,
    super.reputationScore = 0,
  });

  factory AppUserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    UserLocation? location;
    if (data['location'] != null) {
      final locationData = data['location'] as Map<String, dynamic>;
      location = UserLocation(
        latitude: (locationData['latitude'] as num).toDouble(),
        longitude: (locationData['longitude'] as num).toDouble(),
        address: locationData['address'] as String?,
        city: locationData['city'] as String?,
      );
    }

    return AppUserModel(
      id: doc.id,
      email: data['email'] as String,
      displayName: data['displayName'] as String,
      role: data['role'] as String,
      organizationName: data['organizationName'] as String?,
      photoUrl: data['photoUrl'] as String?,
      phone: data['phone'] as String?,
      location: location,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isVerified: data['isVerified'] as bool? ?? false,
      reputationScore: data['reputationScore'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role,
      if (organizationName != null) 'organizationName': organizationName,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (phone != null) 'phone': phone,
      if (location != null)
        'location': {
          'latitude': location!.latitude,
          'longitude': location!.longitude,
          if (location!.address != null) 'address': location!.address,
          if (location!.city != null) 'city': location!.city,
        },
      'createdAt': Timestamp.fromDate(createdAt),
      'isVerified': isVerified,
      'reputationScore': reputationScore,
    };
  }
}
