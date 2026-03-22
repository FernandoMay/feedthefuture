import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService(FirebaseMessaging.instance);
});

class PushNotificationService {
  final FirebaseMessaging _messaging;

  PushNotificationService(this._messaging);

  Future<void> initialize() async {
    // 1. Request permissions for iOS and Android
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');

    // 2. Get the FCM token for this device
    try {
      String? token = await _messaging.getToken();
      debugPrint("FCM Token: $token");
      if (token != null) {
        _saveTokenToFirestore(token);
      }
      
      // Listen for token refreshes
      _messaging.onTokenRefresh.listen((newToken) {
        debugPrint("FCM Token Refreshed: $newToken");
        _saveTokenToFirestore(newToken);
      });
    } catch (e) {
      debugPrint("Error getting FCM token: $e");
    }

    // 3. Handle messages while app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
      }
    });
  }

  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        await userRef.update({
          'fcmTokens': FieldValue.arrayUnion([token])
        });
        debugPrint('FCM Token saved to Firestore');
      }
    } catch (e) {
      debugPrint('Error saving FCM token to Firestore: $e');
    }
  }
}

// Background handler (must be a top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
}
