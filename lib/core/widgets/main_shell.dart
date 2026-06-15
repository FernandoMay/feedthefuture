import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
      // appBar: AppBar(
      //   title: _buildAppTitle(selectedIndex),
      //   actions: [
      //     // Notificaciones
      //     IconButton(
      //       icon: const Icon(Icons.notifications_outlined),
      //       onPressed: () => context.go('/notifications'),
      //     ),
      //     // Configuración
      //     IconButton(
      //       icon: const Icon(Icons.settings_outlined),
      //       onPressed: () => context.go('/settings'),
      //     ),
      //     // Perfil de usuario
      //     PopupMenuButton<String>(
      //       icon: CircleAvatar(
      //         radius: 16,
      //         backgroundColor: Colors.grey[300],
      //         backgroundImage: user?.photoUrl != null 
      //             ? NetworkImage(user!.photoUrl!) 
      //             : null,
      //         child: user?.photoUrl == null 
      //             ? const Icon(Icons.person, size: 20, color: Colors.grey)
      //             : null,
      //       ),
      //       onSelected: (value) {
      //         switch (value) {
      //           case 'profile':
      //             context.go('/profile');
      //             break;
      //           case 'settings':
      //             context.go('/settings');
      //             break;
      //           case 'logout':
      //             _showLogoutConfirmation(context, ref);
      //             break;
      //         }
      //       },
      //       itemBuilder: (context) => [
      //         PopupMenuItem(
      //           value: 'profile',
      //           child: Row(
      //             children: [
      //               const Icon(Icons.person),
      //               const SizedBox(width: 8),
      //               Text(user?.displayName ?? 'Mi Perfil'),
      //             ],
      //           ),
      //         ),
      //         PopupMenuItem(
      //           value: 'settings',
      //           child: Row(
      //             children: const [
      //               Icon(Icons.settings),
      //               SizedBox(width: 8),
      //               Text('Configuración'),
      //             ],
      //           ),
      //         ),
      //         const PopupMenuDivider(),
      //         PopupMenuItem(
      //           value: 'logout',
      //           child: Row(
      //             children: const [
      //               Icon(Icons.logout, color: Colors.red),
      //               SizedBox(width: 8),
      //               Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
      //             ],
      //           ),
      //         ),
      //       ],
      //     ),
      //   ],
      // ),
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
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
