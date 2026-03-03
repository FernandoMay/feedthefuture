import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:feed_the_future/core/theme/app_theme.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;

    int selectedIndex = 0;
    if (location.startsWith('/impact')) {
      selectedIndex = 1;
    } else if (location.startsWith('/community')) {
      selectedIndex = 2;
    } else if (location.startsWith('/donations/new')) {
      selectedIndex = 0;
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: (i) {
              switch (i) {
                case 0:
                  context.go('/home');
                  break;
                case 1:
                  context.go('/impact');
                  break;
                case 2:
                  context.go('/community');
                  break;
              }
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.volunteer_activism_outlined),
                selectedIcon: Icon(Icons.volunteer_activism_rounded),
                label: 'Donaciones',
              ),
              NavigationDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart_rounded),
                label: 'Impacto',
              ),
              NavigationDestination(
                icon: Icon(Icons.people_outline_rounded),
                selectedIcon: Icon(Icons.people_rounded),
                label: 'Comunidad',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
