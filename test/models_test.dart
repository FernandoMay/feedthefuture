import 'package:feed_the_future/features/auth/data/models/app_user_model.dart';
import 'package:feed_the_future/features/auth/domain/entities/app_user.dart';
import 'package:feed_the_future/features/donations/data/models/donation_model.dart';
import 'package:feed_the_future/features/donations/domain/entities/donation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppUserModel', () {
    test('toFirestore and fromFirestore round trip', () {
      final now = DateTime.now();
      final model = AppUserModel(
        id: 'user123',
        email: 'test@example.com',
        displayName: 'Test User',
        role: 'DONOR',
        organizationName: 'Org',
        createdAt: now,
      );

      final data = model.toFirestore();
      expect(data['email'], 'test@example.com');
      expect(data['displayName'], 'Test User');
      expect(data['role'], 'DONOR');
    });

    test('AppUserModel extends AppUser', () {
      final model = AppUserModel(
        id: '1',
        email: 'a@b.com',
        displayName: 'Name',
        role: 'NGO',
        createdAt: DateTime.now(),
      );
      expect(model, isA<AppUser>());
    });

    test('AppUser copyWith preserves identity', () {
      final user = AppUser(
        id: '1',
        email: 'a@b.com',
        displayName: 'Original',
        role: 'DONOR',
        createdAt: DateTime.now(),
      );
      final updated = user.copyWith(displayName: 'Updated');
      expect(updated.displayName, 'Updated');
      expect(updated.id, '1');
    });
  });

  group('DonationModel', () {
    test('toFirestore contains required fields', () {
      final now = DateTime.now();
      final model = DonationModel(
        id: 'don123',
        donorId: 'user1',
        donorName: 'Donor',
        category: 'Frutas y Verduras',
        name: 'Manzanas',
        description: 'Frescas',
        quantity: 10,
        unit: 'kg',
        expirationDate: now.add(const Duration(days: 3)),
        createdAt: now,
        status: 'available',
        riskScore: 'SAFE',
        location: const DonationLocation(
          latitude: 19.43,
          longitude: -99.13,
          address: 'CDMX',
        ),
      );

      final data = model.toFirestore();
      expect(data['donorId'], 'user1');
      expect(data['category'], 'Frutas y Verduras');
      expect(data['status'], 'available');
    });

    test('isExpiringSoon returns true within 24h', () {
      final donation = DonationModel(
        id: '1',
        donorId: 'u1',
        donorName: 'D',
        category: 'C',
        name: 'N',
        description: 'D',
        quantity: 1,
        unit: 'kg',
        expirationDate: DateTime.now().add(const Duration(hours: 12)),
        createdAt: DateTime.now(),
        status: 'available',
        riskScore: 'SAFE',
        location: const DonationLocation(
          latitude: 0, longitude: 0, address: 'A',
        ),
      );
      expect(donation.isExpiringSoon, isTrue);
    });

    test('isExpiringSoon returns false after 24h', () {
      final donation = DonationModel(
        id: '2',
        donorId: 'u1',
        donorName: 'D',
        category: 'C',
        name: 'N',
        description: 'D',
        quantity: 1,
        unit: 'kg',
        expirationDate: DateTime.now().add(const Duration(days: 5)),
        createdAt: DateTime.now(),
        status: 'available',
        riskScore: 'SAFE',
        location: const DonationLocation(
          latitude: 0, longitude: 0, address: 'A',
        ),
      );
      expect(donation.isExpiringSoon, isFalse);
    });

    test('co2Saved computes correctly', () {
      final donation = DonationModel(
        id: '3',
        donorId: 'u1',
        donorName: 'D',
        category: 'C',
        name: 'N',
        description: 'D',
        quantity: 10,
        unit: 'kg',
        expirationDate: DateTime.now().add(const Duration(days: 1)),
        createdAt: DateTime.now(),
        status: 'available',
        riskScore: 'SAFE',
        location: const DonationLocation(
          latitude: 0, longitude: 0, address: 'A',
        ),
        weightKg: 8,
      );
      expect(donation.co2Saved, 20.0);
    });
  });
}
