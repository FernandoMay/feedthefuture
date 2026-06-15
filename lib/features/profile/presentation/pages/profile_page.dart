import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:feed_the_future/core/theme/app_theme.dart';
import 'package:feed_the_future/features/auth/presentation/providers/auth_provider.dart';
import 'package:feed_the_future/features/donations/presentation/providers/donation_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final myDonationsAsync = ref.watch(myDonationsProvider(user.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettings(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            _buildProfileHeader(user),
            const SizedBox(height: 24),

            // Stats Cards
            myDonationsAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text('Error: $error'),
              data: (donations) => _buildStatsCards(donations),
            ),
            const SizedBox(height: 24),

            // Recent Activity
            _buildRecentActivity(ref),
            const SizedBox(height: 24),

            // Actions
            _buildActionButtons(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.greenDeep, AppTheme.greenMid],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            backgroundImage: user?.photoUrl != null 
                ? NetworkImage(user!.photoUrl!) 
                : null,
            child: user?.photoUrl == null 
                ? const Icon(Icons.person, size: 40, color: AppTheme.greenDeep)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.displayName ?? 'Usuario',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                if (user?.organizationName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    user!.organizationName!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(donations) {
    final totalDonations = donations.length;
    final activeDonations = donations.where((d) => d.status == 'available').length;
    final completedDonations = donations.where((d) => d.status == 'completed').length;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Total',
            value: totalDonations.toString(),
            icon: Icons.volunteer_activism,
            color: AppTheme.greenDeep,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Activas',
            value: activeDonations.toString(),
            icon: Icons.pending,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Completadas',
            value: completedDonations.toString(),
            icon: Icons.check_circle,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    
    if (user == null) {
      return const CircularProgressIndicator();
    }
    
    final myDonationsAsync = ref.watch(myDonationsProvider(user.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actividad Reciente',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        myDonationsAsync.when(
          loading: () => const CircularProgressIndicator(),
          error: (error, stack) => Text('Error: $error'),
          data: (donations) {
            if (donations.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'No tienes donaciones registradas',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              );
            }

            final recentDonations = donations.take(3).toList();
            return Column(
              children: recentDonations.map((donation) {
                return ListTile(
                  leading: const Icon(Icons.volunteer_activism, color: AppTheme.greenDeep),
                  title: Text(donation.name),
                  subtitle: Text('${donation.quantity} ${donation.unit}'),
                  trailing: _buildStatusChip(donation.status),
                  onTap: () {
                    // Navigate to donation detail
                  },
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => context.go('/donations/new'),
            icon: const Icon(Icons.add),
            label: const Text('Nueva Donación'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.greenDeep,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showEditProfile(context),
            icon: const Icon(Icons.edit),
            label: const Text('Editar Perfil'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showLogoutConfirmation(context, ref),
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;
    
    switch (status) {
      case 'available':
        color = Colors.green;
        text = 'Disponible';
        break;
      case 'assigned':
        color = Colors.orange;
        text = 'Asignada';
        break;
      case 'completed':
        color = Colors.blue;
        text = 'Completada';
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showSettings(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Configuración',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notificaciones'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to notifications settings
              },
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('Privacidad'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to privacy settings
              },
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Ayuda'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to help
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfile(BuildContext context) {
    // TODO: Implement edit profile
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Próximamente')),
    );
  }

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authNotifierProvider.notifier).signOut();
            },
            child: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
