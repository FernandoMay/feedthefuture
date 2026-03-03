import 'package:equatable/equatable.dart';

class Donation extends Equatable {
  final String id;
  final String donorId;
  final String donorName;
  final String? donorPhotoUrl;
  final String category;
  final String name;
  final String description;
  final double quantity;
  final String unit;
  final DateTime expirationDate;
  final DateTime createdAt;
  final String status;
  final String riskScore;
  final DonationLocation location;
  final String? assignedNgoId;
  final String? assignedNgoName;
  final String? assignedVolunteerId;
  final List<String> photoUrls;
  final double? weightKg;
  final Map<String, dynamic>? nutritionInfo;

  const Donation({
    required this.id,
    required this.donorId,
    required this.donorName,
    this.donorPhotoUrl,
    required this.category,
    required this.name,
    required this.description,
    required this.quantity,
    required this.unit,
    required this.expirationDate,
    required this.createdAt,
    required this.status,
    required this.riskScore,
    required this.location,
    this.assignedNgoId,
    this.assignedNgoName,
    this.assignedVolunteerId,
    this.photoUrls = const [],
    this.weightKg,
    this.nutritionInfo,
  });

  bool get isExpiringSoon =>
      expirationDate.difference(DateTime.now()).inHours < 24;

  bool get isUrgent =>
      status == 'available' && expirationDate.isBefore(
        DateTime.now().add(const Duration(hours: 12)),
      );

  double get co2Saved => (weightKg ?? quantity) * 2.5;

  @override
  List<Object?> get props => [id];
}

class DonationLocation extends Equatable {
  final double latitude;
  final double longitude;
  final String address;
  final String? city;

  const DonationLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.city,
  });

  @override
  List<Object?> get props => [latitude, longitude];
}
