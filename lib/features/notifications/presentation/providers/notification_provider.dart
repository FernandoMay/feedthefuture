import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:feed_the_future/features/auth/presentation/providers/auth_provider.dart';
import 'package:feed_the_future/features/notifications/data/models/notification_model.dart';

class NotificationNotifier extends StateNotifier<AsyncValue<List<AppNotification>>> {
  final FirebaseFirestore _firestore;
  final String _userId;

  NotificationNotifier(this._firestore, this._userId) : super(const AsyncValue.loading()) {
    _loadNotifications();
  }

  void _loadNotifications() {
    state = const AsyncValue.loading();
    
    _firestore
        .collection('notifications')
        .where('userId', isEqualTo: _userId)
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            final notifications = snapshot.docs
                .map((doc) => AppNotification.fromFirestore(doc))
                .toList();
            state = AsyncValue.data(notifications);
          },
          onError: (error, stackTrace) {
            state = AsyncValue.error(error, stackTrace);
          },
        );
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (error) {
      state = AsyncValue.error(error, StackTrace.current);
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final unreadNotifications = state.whenData(
        (notifications) => notifications.where((n) => !n.isRead).toList(),
      ).value ?? [];

      final batch = _firestore.batch();
      for (final notification in unreadNotifications) {
        batch.update(
          _firestore.collection('notifications').doc(notification.id),
          {'isRead': true},
        );
      }
      await batch.commit();
    } catch (error) {
      state = AsyncValue.error(error, StackTrace.current);
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (error) {
      state = AsyncValue.error(error, StackTrace.current);
    }
  }

  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
    DateTime? expiresAt,
  }) async {
    try {
      final notification = AppNotification(
        id: '',
        userId: userId,
        title: title,
        body: body,
        type: type,
        data: data,
        isRead: false,
        createdAt: DateTime.now(),
        expiresAt: expiresAt ?? DateTime.now().add(const Duration(days: 30)),
      );

      await _firestore
          .collection('notifications')
          .add(notification.toMap());
    } catch (error) {
      state = AsyncValue.error(error, StackTrace.current);
    }
  }
}

// Provider for notifications
final notificationsProvider = StateNotifierProvider<NotificationNotifier, AsyncValue<List<AppNotification>>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) throw Exception('User not authenticated');
  
  return NotificationNotifier(FirebaseFirestore.instance, user.id);
});

// Provider for notification service
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(FirebaseFirestore.instance);
});

class NotificationService {
  final FirebaseFirestore _firestore;

  NotificationService(this._firestore);

  Future<void> sendDonationAssignedNotification({
    required String userId,
    required String donationId,
    required String donationName,
  }) async {
    await _firestore.collection('notifications').add({
      'userId': userId,
      'title': '¡Donación Asignada!',
      'body': 'Tu donación "$donationName" ha sido asignada para recolección.',
      'type': 'donation_assigned',
      'data': {'donationId': donationId},
      'isRead': false,
      'createdAt': Timestamp.now(),
      'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
    });
  }

  Future<void> sendDonationCompletedNotification({
    required String userId,
    required String donationId,
    required String donationName,
  }) async {
    await _firestore.collection('notifications').add({
      'userId': userId,
      'title': '¡Donación Completada!',
      'body': 'Tu donación "$donationName" ha sido recolectada exitosamente.',
      'type': 'donation_completed',
      'data': {'donationId': donationId},
      'isRead': false,
      'createdAt': Timestamp.now(),
      'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
    });
  }

  Future<void> sendNewNearbyDonationNotification({
    required String userId,
    required String donationId,
    required String donationName,
    required String location,
  }) async {
    await _firestore.collection('notifications').add({
      'userId': userId,
      'title': 'Nueva Donación Cerca',
      'body': '"$donationName" disponible cerca de $location',
      'type': 'new_nearby_donation',
      'data': {'donationId': donationId},
      'isRead': false,
      'createdAt': Timestamp.now(),
      'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
    });
  }
}
