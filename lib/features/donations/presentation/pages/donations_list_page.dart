import 'package:feed_the_future/core/routes/app_router.dart';
import 'package:feed_the_future/core/theme/app_theme.dart';
import 'package:feed_the_future/features/donations/presentation/providers/donation_provider.dart';
import 'package:feed_the_future/features/donations/presentation/widgets/donation_card.dart';
import 'package:feed_the_future/features/donations/presentation/widgets/donation_filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DonationsListPage extends ConsumerWidget {
  const DonationsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final donationsAsync = ref.watch(filteredDonationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.greenDeep,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.eco_rounded,
                  color: AppTheme.greenLime, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('Feed the Future'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0x1A2D8A55),
            child: Icon(Icons.person_outline, size: 18, color: AppTheme.greenMid),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Summary bar
          _SummaryBanner(),
          // Filter bar
          const DonationFilterBar(),
          // List
          Expanded(
            child: donationsAsync.when(
              loading: () => const _DonationsSkeleton(),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: AppTheme.dangerRed),
                    const SizedBox(height: 12),
                    Text('Error: $e', style: AppTextStyles.bodyMedium),
                  ],
                ),
              ),
              data: (donations) {
                if (donations.isEmpty) {
                  return const _EmptyState();
                }
                return RefreshIndicator(
                  color: AppTheme.greenFresh,
                  onRefresh: () async {
                    ref.invalidate(availableDonationsProvider);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: donations.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => DonationCard(
                      donation: donations[i],
                      onTap: () =>
                          context.go(AppRoutes.donationDetail(donations[i].id)),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(AppRoutes.donationNew),
        backgroundColor: AppTheme.greenDeep,
        foregroundColor: AppTheme.greenLime,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva donación',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _SummaryBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final donations = ref.watch(availableDonationsProvider).value ?? [];
    final totalKg = donations.fold<double>(
        0, (sum, d) => sum + (d.weightKg ?? d.quantity));
    final urgent = donations.where((d) => d.isUrgent).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.greenDeep, AppTheme.greenMid],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _SummaryItem(
            value: donations.length.toString(),
            label: 'Disponibles',
            icon: '📦',
          ),
          const _Divider(),
          _SummaryItem(
            value: '${totalKg.toStringAsFixed(0)} kg',
            label: 'Total',
            icon: '⚖️',
          ),
          const _Divider(),
          _SummaryItem(
            value: urgent.toString(),
            label: 'Urgentes',
            icon: '⚡',
            urgent: urgent > 0,
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String value;
  final String label;
  final String icon;
  final bool urgent;

  const _SummaryItem({
    required this.value,
    required this.label,
    required this.icon,
    this.urgent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'DMSerifDisplay',
              fontSize: 20,
              color: urgent ? AppTheme.warningAmber : AppTheme.greenLime,
              height: 1,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0x80FAF6EE),
              fontFamily: 'DMSans',
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 1,
      color: Colors.white.withOpacity(0.15),
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0x0D2D8A55),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.inbox_outlined,
                size: 40, color: AppTheme.greenFresh),
          ),
          const SizedBox(height: 16),
          const Text('Sin donaciones disponibles',
              style: AppTextStyles.headingMedium),
          const SizedBox(height: 8),
          const Text('Sé el primero en registrar\nun alimento rescatado.',
              textAlign: TextAlign.center, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}

class _DonationsSkeleton extends StatelessWidget {
  const _DonationsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
