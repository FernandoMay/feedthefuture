import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feed_the_future/features/donations/domain/entities/donation.dart';

class DonationModel extends Donation {
  const DonationModel({
    required super.id,
    required super.donorId,
    required super.donorName,
    super.donorPhotoUrl,
    required super.category,
    required super.name,
    required super.description,
    required super.quantity,
    required super.unit,
    required super.expirationDate,
    required super.createdAt,
    required super.status,
    required super.riskScore,
    required super.location,
    super.assignedNgoId,
    super.assignedNgoName,
    super.assignedVolunteerId,
    super.photoUrls = const [],
    super.weightKg,
    super.nutritionInfo,
  });

  factory DonationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    final locationData = data['location'] as Map<String, dynamic>;
    final location = DonationLocation(
      latitude: (locationData['latitude'] as num).toDouble(),
      longitude: (locationData['longitude'] as num).toDouble(),
      address: locationData['address'] as String,
      city: locationData['city'] as String?,
    );

    return DonationModel(
      id: doc.id,
      donorId: data['donorId'] as String,
      donorName: data['donorName'] as String,
      donorPhotoUrl: data['donorPhotoUrl'] as String?,
      category: data['category'] as String,
      name: data['name'] as String,
      description: data['description'] as String,
      quantity: (data['quantity'] as num).toDouble(),
      unit: data['unit'] as String,
      expirationDate: (data['expirationDate'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      status: data['status'] as String,
      riskScore: data['riskScore'] as String,
      location: location,
      assignedNgoId: data['assignedNgoId'] as String?,
      assignedNgoName: data['assignedNgoName'] as String?,
      assignedVolunteerId: data['assignedVolunteerId'] as String?,
      photoUrls: List<String>.from(data['photoUrls'] as List? ?? []),
      weightKg: data['weightKg'] != null ? (data['weightKg'] as num).toDouble() : null,
      nutritionInfo: data['nutritionInfo'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'donorId': donorId,
      'donorName': donorName,
      if (donorPhotoUrl != null) 'donorPhotoUrl': donorPhotoUrl,
      'category': category,
      'name': name,
      'description': description,
      'quantity': quantity,
      'unit': unit,
      'expirationDate': Timestamp.fromDate(expirationDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'riskScore': riskScore,
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
        'address': location.address,
        if (location.city != null) 'city': location.city,
      },
      if (assignedNgoId != null) 'assignedNgoId': assignedNgoId,
      if (assignedNgoName != null) 'assignedNgoName': assignedNgoName,
      if (assignedVolunteerId != null) 'assignedVolunteerId': assignedVolunteerId,
      'photoUrls': photoUrls,
      if (weightKg != null) 'weightKg': weightKg,
      if (nutritionInfo != null) 'nutritionInfo': nutritionInfo,
    };
  }

  DonationModel copyWith({
    String? id,
    String? donorId,
    String? donorName,
    String? donorPhotoUrl,
    String? category,
    String? name,
    String? description,
    double? quantity,
    String? unit,
    DateTime? expirationDate,
    DateTime? createdAt,
    String? status,
    String? riskScore,
    DonationLocation? location,
    String? assignedNgoId,
    String? assignedNgoName,
    String? assignedVolunteerId,
    List<String>? photoUrls,
    double? weightKg,
    Map<String, dynamic>? nutritionInfo,
  }) {
    return DonationModel(
      id: id ?? this.id,
      donorId: donorId ?? this.donorId,
      donorName: donorName ?? this.donorName,
      donorPhotoUrl: donorPhotoUrl ?? this.donorPhotoUrl,
      category: category ?? this.category,
      name: name ?? this.name,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      expirationDate: expirationDate ?? this.expirationDate,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      riskScore: riskScore ?? this.riskScore,
      location: location ?? this.location,
      assignedNgoId: assignedNgoId ?? this.assignedNgoId,
      assignedNgoName: assignedNgoName ?? this.assignedNgoName,
      assignedVolunteerId: assignedVolunteerId ?? this.assignedVolunteerId,
      photoUrls: photoUrls ?? this.photoUrls,
      weightKg: weightKg ?? this.weightKg,
      nutritionInfo: nutritionInfo ?? this.nutritionInfo,
    );
  }
}
