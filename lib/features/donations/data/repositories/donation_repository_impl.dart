import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:feed_the_future/core/constants/app_constants.dart';
import 'package:feed_the_future/core/errors/failures.dart';
import 'package:feed_the_future/features/donations/data/models/donation_model.dart';
import 'package:feed_the_future/features/donations/domain/entities/donation.dart';
import 'package:feed_the_future/features/donations/domain/repositories/donation_repository.dart';

class DonationRepositoryImpl implements DonationRepository {
  final FirebaseFirestore _firestore;

  const DonationRepositoryImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  CollectionReference get _col =>
      _firestore.collection(AppConstants.donationsCollection);

  @override
  Stream<List<Donation>> watchAvailableDonations() {
    return _col
        .where('status', isEqualTo: AppConstants.statusAvailable)
        .orderBy('expirationDate')
        .limit(AppConstants.defaultPageSize)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => DonationModel.fromFirestore(d)).toList());
  }

  @override
  Stream<List<Donation>> watchDonationsByDonor(String donorId) {
    return _col
        .where('donorId', isEqualTo: donorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => DonationModel.fromFirestore(d)).toList());
  }

  @override
  Stream<List<Donation>> watchDonationsByNgo(String ngoId) {
    return _col
        .where('assignedNgoId', isEqualTo: ngoId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => DonationModel.fromFirestore(d)).toList());
  }

  @override
  Future<Either<AppFailure, Donation>> getDonationById(String id) async {
    try {
      final doc = await _col.doc(id).get();
      if (!doc.exists) {
        return const Left(
            FirestoreFailure(message: 'Donación no encontrada'));
      }
      return Right(DonationModel.fromFirestore(doc));
    } catch (e) {
      return Left(FirestoreFailure(message: 'Error al obtener donación: $e'));
    }
  }

  @override
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
  }) async {
    try {
      final model = DonationModel(
        id: '',
        donorId: donorId,
        donorName: donorName,
        category: category,
        name: name,
        description: description,
        quantity: quantity,
        unit: unit,
        expirationDate: expirationDate,
        createdAt: DateTime.now(),
        status: AppConstants.statusPending,
        riskScore: AppConstants.riskSafe,
        location: location,
        photoUrls: photoUrls ?? [],
        weightKg: weightKg,
        nutritionInfo: nutritionInfo,
      );

      final ref = await _col.add(model.toFirestore());
      return Right(ref.id);
    } catch (e) {
      return Left(FirestoreFailure(message: 'Error al crear donación: $e'));
    }
  }

  @override
  Future<Either<AppFailure, Donation>> updateDonation({
    required String donationId,
    String? status,
    String? assignedNgoId,
    String? assignedNgoName,
    String? assignedVolunteerId,
    String? riskScore,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (status != null) updates['status'] = status;
      if (assignedNgoId != null) updates['assignedNgoId'] = assignedNgoId;
      if (assignedNgoName != null) updates['assignedNgoName'] = assignedNgoName;
      if (assignedVolunteerId != null) updates['assignedVolunteerId'] = assignedVolunteerId;
      if (riskScore != null) updates['riskScore'] = riskScore;
      
      updates['updatedAt'] = FieldValue.serverTimestamp();

      await _col.doc(donationId).update(updates);
      final doc = await _col.doc(donationId).get();
      return Right(DonationModel.fromFirestore(doc));
    } catch (e) {
      return Left(FirestoreFailure(message: 'Error al actualizar donación: $e'));
    }
  }

  @override
  Stream<List<Donation>> watchDonationsByVolunteer(String volunteerId) {
    return _col
        .where('assignedVolunteerId', isEqualTo: volunteerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => DonationModel.fromFirestore(d)).toList());
  }

  @override
  Future<Either<AppFailure, void>> deleteDonation(String id) async {
    try {
      await _col.doc(id).delete();
      return const Right(null);
    } catch (e) {
      return Left(FirestoreFailure(message: 'Error al eliminar: $e'));
    }
  }

  @override
  Future<Either<AppFailure, List<Donation>>> searchDonations({
    String? category,
    String? status,
    DonationLocation? location,
    double? radiusKm,
    DateTime? beforeDate,
    DateTime? afterDate,
    int? limit,
  }) async {
    try {
      Query query = _col;
      
      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }
      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }
      if (afterDate != null) {
        query = query.where('expirationDate', isGreaterThanOrEqualTo: afterDate);
      }
      if (beforeDate != null) {
        query = query.where('expirationDate', isLessThanOrEqualTo: beforeDate);
      }
      
      query = query.orderBy('createdAt', descending: true);
      if (limit != null) {
        query = query.limit(limit);
      }

      final snap = await query.get();
      final donations = snap.docs
          .map((d) => DonationModel.fromFirestore(d))
          .toList();

      // Filter by location if provided
      if (location != null && radiusKm != null) {
        final latDelta = radiusKm / 111.0;
        final lngDelta = radiusKm / (111.0 * (location.latitude * 3.14159 / 180).abs());

        return Right(donations.where((d) {
          final latDiff = (d.location.latitude - location.latitude).abs();
          final lngDiff = (d.location.longitude - location.longitude).abs();
          return latDiff <= latDelta && lngDiff <= lngDelta;
        }).toList());
      }

      return Right(donations);
    } catch (e) {
      return Left(FirestoreFailure(message: 'Error de búsqueda: $e'));
    }
  }
}
