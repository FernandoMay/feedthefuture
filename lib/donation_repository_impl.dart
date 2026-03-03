import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/errors/failures.dart';
import '../../../domain/entities/donation.dart';
import '../../../domain/repositories/donation_repository.dart';
import '../../models/donation_model.dart';

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
            NotFoundFailure(message: 'Donación no encontrada'));
      }
      return Right(DonationModel.fromFirestore(doc));
    } catch (e) {
      return Left(FirestoreFailure(message: 'Error al obtener donación: $e'));
    }
  }

  @override
  Future<Either<AppFailure, Donation>> createDonation(
      Donation donation) async {
    try {
      final model = DonationModel(
        id: '',
        donorId: donation.donorId,
        donorName: donation.donorName,
        donorPhotoUrl: donation.donorPhotoUrl,
        category: donation.category,
        name: donation.name,
        description: donation.description,
        quantity: donation.quantity,
        unit: donation.unit,
        expirationDate: donation.expirationDate,
        createdAt: DateTime.now(),
        status: AppConstants.statusPending,
        riskScore: AppConstants.riskSafe, // Will be updated by Cloud Function
        location: donation.location,
        photoUrls: donation.photoUrls,
        weightKg: donation.weightKg,
        nutritionInfo: donation.nutritionInfo,
      );

      final ref = await _col.add(model.toFirestore());
      final created = await ref.get();
      return Right(DonationModel.fromFirestore(created));
    } catch (e) {
      return Left(FirestoreFailure(message: 'Error al crear donación: $e'));
    }
  }

  @override
  Future<Either<AppFailure, Donation>> updateDonationStatus({
    required String id,
    required String status,
  }) async {
    try {
      await _col.doc(id).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final doc = await _col.doc(id).get();
      return Right(DonationModel.fromFirestore(doc));
    } catch (e) {
      return Left(FirestoreFailure(message: 'Error al actualizar: $e'));
    }
  }

  @override
  Future<Either<AppFailure, void>> assignDonation({
    required String donationId,
    required String ngoId,
    required String ngoName,
  }) async {
    try {
      await _col.doc(donationId).update({
        'assignedNgoId': ngoId,
        'assignedNgoName': ngoName,
        'status': AppConstants.statusMatched,
        'matchedAt': FieldValue.serverTimestamp(),
      });
      return const Right(null);
    } catch (e) {
      return Left(FirestoreFailure(message: 'Error al asignar: $e'));
    }
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
  Future<Either<AppFailure, List<Donation>>> getNearbyDonations({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    try {
      // Approximate bounding box
      final latDelta = radiusKm / 111.0;
      final lngDelta = radiusKm / (111.0 * (latitude * 3.14159 / 180).abs());

      final snap = await _col
          .where('status', isEqualTo: AppConstants.statusAvailable)
          .where('location.latitude',
              isGreaterThan: latitude - latDelta,
              isLessThan: latitude + latDelta)
          .get();

      final donations = snap.docs
          .map((d) => DonationModel.fromFirestore(d))
          .where((d) =>
              d.location.longitude > longitude - lngDelta &&
              d.location.longitude < longitude + lngDelta)
          .toList();

      return Right(donations);
    } catch (e) {
      return Left(FirestoreFailure(message: 'Error de búsqueda: $e'));
    }
  }
}
