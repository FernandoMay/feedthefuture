import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:feed_the_future/main.dart';
import 'package:feed_the_future/features/auth/presentation/pages/splash_page.dart';
import 'package:feed_the_future/core/theme/app_theme.dart';

void main() {
  group('Feed the Future App Tests', () {
    testWidgets('App should build without errors', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(
        const ProviderScope(
          child: FeedTheFutureApp(),
        ),
      );

      // Verify that the app builds successfully
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('SplashPage should build without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SplashPage(),
          ),
        ),
      );

      // Verify that the splash page builds
      expect(find.byType(SplashPage), findsOneWidget);
    });

    test('AppTheme should have light theme', () {
      final theme = AppTheme.light;
      
      // Verify that the theme is not null
      expect(theme, isNotNull);
      expect(theme.colorScheme.primary, isNotNull);
    });

    test('AppTheme should have dark theme', () {
      final theme = AppTheme.dark;
      
      // Verify that the theme is not null
      expect(theme, isNotNull);
      expect(theme.colorScheme.primary, isNotNull);
    });
  });
}
