import 'package:dartz/dartz.dart';
import 'package:feed_the_future/core/errors/failures.dart';
import 'package:feed_the_future/features/donations/domain/entities/donation.dart';

abstract class DonationRepository {
  Stream<List<Donation>> watchAvailableDonations();
  Stream<List<Donation>> watchDonationsByDonor(String donorId);
  Stream<List<Donation>> watchDonationsByNgo(String ngoId);
  Stream<List<Donation>> watchDonationsByVolunteer(String volunteerId);

  Future<Either<AppFailure, Donation>> getDonationById(String donationId);
  
  Future<Either<AppFailure, String>> createDonation({
    required String donorId,
    required String donorName,
    required String category,
    required String name,
    required String description,
    required double quantity,
    required String unit,
    required DateTime expirationDate,
    required DonationLocation location,
    List<String>? photoUrls,
    double? weightKg,
    Map<String, dynamic>? nutritionInfo,
  });

  Future<Either<AppFailure, Donation>> updateDonation({
    required String donationId,
    String? status,
    String? assignedNgoId,
    String? assignedNgoName,
    String? assignedVolunteerId,
    String? riskScore,
  });

  Future<Either<AppFailure, void>> deleteDonation(String donationId);

  Future<Either<AppFailure, List<Donation>>> searchDonations({
    String? category,
    String? status,
    DonationLocation? location,
    double? radiusKm,
    DateTime? beforeDate,
    DateTime? afterDate,
    int? limit,
  });
}
