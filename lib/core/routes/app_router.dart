import 'package:feed_the_future/features/auth/presentation/providers/auth_provider.dart';
import 'package:feed_the_future/features/auth/presentation/pages/login_page.dart';
import 'package:feed_the_future/features/auth/presentation/pages/register_page.dart';
import 'package:feed_the_future/features/auth/presentation/pages/splash_page.dart';
import 'package:feed_the_future/features/community/presentation/pages/community_home_page.dart';
import 'package:feed_the_future/features/donations/presentation/pages/donation_detail_page.dart';
import 'package:feed_the_future/features/donations/presentation/pages/donation_form_page.dart';
import 'package:feed_the_future/features/donations/presentation/pages/donations_list_page.dart';
import 'package:feed_the_future/features/impact/presentation/pages/impact_dashboard_page.dart';
import 'package:feed_the_future/features/profile/presentation/pages/profile_page.dart';
import 'package:feed_the_future/features/notifications/presentation/pages/notifications_page.dart';
import 'package:feed_the_future/features/settings/presentation/pages/settings_page.dart';
import 'package:feed_the_future/core/widgets/main_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isSplash = state.matchedLocation == '/splash';
      final isAuth = state.matchedLocation.startsWith('/auth');

      if (isSplash) return null;
      if (!isLoggedIn && !isAuth) return '/auth/login';
      if (isLoggedIn && isAuth) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashPage(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (_, __) => const RegisterPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, __) => const DonationsListPage(),
          ),
          GoRoute(
            path: '/donations/new',
            builder: (_, __) => const DonationFormPage(),
          ),
          GoRoute(
            path: '/donations/:id',
            builder: (context, state) => DonationDetailPage(
              donationId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/impact',
            builder: (_, __) => const ImpactDashboardPage(),
          ),
          GoRoute(
            path: '/community',
            builder: (_, __) => const CommunityHomePage(),
          ),
          GoRoute(
            path: '/profile',
            builder: (_, __) => const ProfilePage(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (_, __) => const NotificationsPage(),
          ),
          GoRoute(
            path: '/settings',
            builder: (_, __) => const SettingsPage(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Página no encontrada: ${state.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Ir al inicio'),
            ),
          ],
        ),
      ),
    ),
  );
});

// Route names for convenience
class AppRoutes {
  static const splash = '/splash';
  static const login = '/auth/login';
  static const register = '/auth/register';
  static const home = '/home';
  static const donationNew = '/donations/new';
  static String donationDetail(String id) => '/donations/$id';
  static const impact = '/impact';
  static const community = '/community';
  static const profile = '/profile';
  static const notifications = '/notifications';
  static const settings = '/settings';
}
