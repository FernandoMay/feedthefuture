import 'package:feed_the_future/features/donations/domain/entities/donation.dart';
import 'package:feed_the_future/features/donations/presentation/providers/donation_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:feed_the_future/core/theme/app_theme.dart';

class DonationDetailPage extends ConsumerWidget {
  final String donationId;
  const DonationDetailPage({super.key, required this.donationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // In production, watch a single donation stream by ID
    final donationsAsync = ref.watch(availableDonationsProvider);

    return donationsAsync.when(
      loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (list) {
        final donation = list.where((d) => d.id == donationId).firstOrNull;
        if (donation == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Donación')),
            body: const Center(child: Text('Donación no encontrada')),
          );
        }
        return _DonationDetailView(donation: donation);
      },
    );
  }
}

class _DonationDetailView extends ConsumerWidget {
  final Donation donation;
  const _DonationDetailView({required this.donation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppTheme.greenDeep,
            foregroundColor: AppTheme.greenLime,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppTheme.greenDeep,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60),
                      Text(
                        _categoryEmoji(donation.category),
                        style: const TextStyle(fontSize: 64),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  children: [
                    Expanded(
                      child: Text(donation.name,
                          style: AppTextStyles.headingLarge),
                    ),
                    _RiskLabel(riskScore: donation.riskScore),
                  ],
                ),
                const SizedBox(height: 8),
                Text(donation.description, style: AppTextStyles.bodyMedium),
                const SizedBox(height: 20),
                _InfoGrid(donation: donation),
                const SizedBox(height: 20),
                _DonorCard(donation: donation),
                const SizedBox(height: 20),
                _LocationCard(donation: donation),
                const SizedBox(height: 20),
                _ImpactCard(donation: donation),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomActions(donation: donation),
    );
  }

  String _categoryEmoji(String cat) {
    switch (cat) {
      case 'Frutas y Verduras': return '🥦';
      case 'Lácteos': return '🥛';
      case 'Panadería': return '🍞';
      default: return '📦';
    }
  }
}

class _RiskLabel extends StatelessWidget {
  final String riskScore;
  const _RiskLabel({required this.riskScore});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    switch (riskScore) {
      case 'SAFE':
        bg = AppTheme.greenFresh.withOpacity(0.12);
        fg = AppTheme.greenMid;
        label = '✓ Seguro';
        break;
      case 'CONDITIONAL':
        bg = AppTheme.warningAmber.withOpacity(0.12);
        fg = AppTheme.warningAmber;
        label = '⚠ Condicional';
        break;
      default:
        bg = AppTheme.dangerRed.withOpacity(0.12);
        fg = AppTheme.dangerRed;
        label = '✗ Rechazado';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(100),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final Donation donation;
  const _InfoGrid({required this.donation});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: [
        _InfoTile(icon: '⚖️', label: 'Cantidad',
            value: '${donation.quantity} ${donation.unit}'),
        _InfoTile(icon: '📁', label: 'Categoría', value: donation.category),
        _InfoTile(icon: '📅', label: 'Vence',
            value: DateFormat('d MMM HH:mm', 'es').format(donation.expirationDate)),
        _InfoTile(icon: '📊', label: 'Estado',
            value: _statusLabel(donation.status)),
      ],
    );
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'available': return 'Disponible';
      case 'matched': return 'Asignado';
      case 'in_transit': return 'En camino';
      case 'delivered': return 'Entregado';
      default: return s;
    }
  }
}

class _InfoTile extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: const Border.fromBorderSide(
          BorderSide(color: Color(0x1A2D8A55), width: 1.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$icon $label', style: AppTextStyles.caption),
          const SizedBox(height: 2),
          Text(value, style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600, fontSize: 14),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _DonorCard extends StatelessWidget {
  final Donation donation;
  const _DonorCard({required this.donation});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: const Border.fromBorderSide(
          BorderSide(color: Color(0x1A2D8A55), width: 1.5),
        ),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: const Color(0x0D2D8A55),
          backgroundImage: donation.donorPhotoUrl != null
              ? NetworkImage(donation.donorPhotoUrl!)
              : null,
          child: donation.donorPhotoUrl == null
              ? const Icon(Icons.store_outlined, color: AppTheme.greenMid)
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Donante', style: AppTextStyles.caption),
            Text(donation.donorName,
                style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600)),
          ]),
        ),
        const Icon(Icons.verified_rounded, color: AppTheme.greenFresh, size: 20),
      ]),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final Donation donation;
  const _LocationCard({required this.donation});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: const Border.fromBorderSide(
          BorderSide(color: Color(0x1A2D8A55), width: 1.5),
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.location_on_outlined, color: AppTheme.greenFresh, size: 18),
          SizedBox(width: 6),
          Text('Ubicación de recolección', style: AppTextStyles.caption),
        ]),
        const SizedBox(height: 8),
        Text(donation.location.address,
            style: AppTextStyles.bodyMedium),
        const SizedBox(height: 12),
        Container(
          height: 100,
          decoration: BoxDecoration(
            color: const Color(0x0D2D8A55),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Icon(Icons.map_outlined, color: AppTheme.greenFresh, size: 32),
          ),
        ),
      ]),
    );
  }
}

class _ImpactCard extends StatelessWidget {
  final Donation donation;
  const _ImpactCard({required this.donation});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.greenDeep, AppTheme.greenMid],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Impacto estimado', style: TextStyle(
            fontSize: 11, color: AppTheme.greenGlow,
            fontFamily: 'DMSans', fontWeight: FontWeight.w700,
            letterSpacing: 0.8)),
        const SizedBox(height: 12),
        Row(children: [
          _ImpactItem('🌱',
              '${donation.co2Saved.toStringAsFixed(1)} kg',
              'CO₂ evitado'),
          _ImpactItem('👨‍👩‍👧',
              '~${(donation.quantity / 2).round()}',
              'Personas alimentadas'),
        ]),
      ]),
    );
  }
}

class _ImpactItem extends StatelessWidget {
  final String icon;
  final String value;
  final String label;
  const _ImpactItem(this.icon, this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        Text(icon, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(
            fontFamily: 'DMSerifDisplay', fontSize: 22,
            color: AppTheme.greenLime, height: 1)),
        Text(label, style: const TextStyle(
            fontSize: 11, color: Color(0x80FAF6EE), fontFamily: 'DMSans')),
      ]),
    );
  }
}

class _BottomActions extends ConsumerWidget {
  final Donation donation;
  const _BottomActions({required this.donation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(
            color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, -4))],
      ),
      child: Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.share_outlined),
            label: const Text('Compartir'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: donation.status == 'available' ? () {} : null,
            icon: const Icon(Icons.handshake_outlined),
            label: Text(
              donation.status == 'available' ? 'Reclamar donación' : 'Ya asignada',
            ),
          ),
        ),
      ]),
    );
  }
}
