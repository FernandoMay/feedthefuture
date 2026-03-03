import 'package:feed_the_future/core/routes/app_router.dart';
import 'package:feed_the_future/core/theme/app_theme.dart';
import 'package:feed_the_future/features/donations/presentation/providers/donation_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CommunityHomePage extends ConsumerWidget {
  const CommunityHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final donationsAsync = ref.watch(availableDonationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Comunidad')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.greenDeep, AppTheme.greenMid],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🌿 Centro Comunitario',
                      style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 1.2,
                          color: AppTheme.greenGlow,
                          fontFamily: 'DMSans',
                          fontWeight: FontWeight.w700)),
                  SizedBox(height: 8),
                  Text(
                    'Alimentos disponibles\ncerca de ti',
                    style: TextStyle(
                        fontFamily: 'DMSerifDisplay',
                        fontSize: 26,
                        color: AppTheme.cream,
                        height: 1.2),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Explora donaciones disponibles, solicita apoyo o únete como voluntario.',
                    style: TextStyle(
                        fontSize: 13,
                        color: Color(0x80FAF6EE),
                        fontFamily: 'DMSans',
                        height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Quick actions
            const Text('Acciones rápidas', style: AppTextStyles.headingMedium),
            const SizedBox(height: 12),
            Row(children: [
              _QuickAction('📍', 'Donaciones cercanas', () {}),
              const SizedBox(width: 12),
              _QuickAction('🙋', 'Ser voluntario', () {}),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _QuickAction('📞', 'Contactar ONG', () {}),
              const SizedBox(width: 12),
              _QuickAction('📊', 'Ver impacto', () => context.go(AppRoutes.impact)),
            ]),
            const SizedBox(height: 24),
            // Available donations
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Alimentos disponibles',
                    style: AppTextStyles.headingMedium),
                TextButton(
                  onPressed: () => context.go(AppRoutes.home),
                  child: const Text('Ver todos'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            donationsAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppTheme.greenFresh)),
              error: (e, _) => Text('Error: $e'),
              data: (donations) {
                final nearby = donations.take(5).toList();
                if (nearby.isEmpty) {
                  return const Center(
                      child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Sin donaciones disponibles actualmente.',
                        style: AppTextStyles.bodyMedium),
                  ));
                }
                return Column(
                  children: nearby
                      .map((d) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: DonationCard(
                              donation: d,
                              onTap: () =>
                                  context.go(AppRoutes.donationDetail(d.id)),
                            ),
                          ))
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;

  const _QuickAction(this.emoji, this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: const Border.fromBorderSide(
                BorderSide(color: Color(0x1A2D8A55), width: 1.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 8),
              Text(label,
                  style: AppTextStyles.bodyMedium.copyWith(
                      color: AppTheme.charcoal, fontWeight: FontWeight.w500),
                  maxLines: 2),
            ],
          ),
        ),
      ),
    );
  }
}
