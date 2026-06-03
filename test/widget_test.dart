import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';

import 'package:feed_the_future/main.dart';
import 'package:feed_the_future/core/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();

  setUpAll(() async {
    try {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: '123',
          appId: '123',
          messagingSenderId: '123',
          projectId: '123',
        ),
      );
    } catch (_) {}
  });

  group('Feed the Future App Tests', () {
    testWidgets('App should build without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: FeedTheFutureApp(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    test('AppTheme should have light theme', () {
      final theme = AppTheme.light;
      expect(theme, isNotNull);
      expect(theme.colorScheme.primary, isNotNull);
    });

    test('AppTheme should have dark theme', () {
      final theme = AppTheme.dark;
      expect(theme, isNotNull);
      expect(theme.colorScheme.primary, isNotNull);
    });
  });
}
