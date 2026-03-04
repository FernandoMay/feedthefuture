import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:feed_the_future/core/theme/app_theme.dart';

class ImpactDashboardPage extends ConsumerWidget {
  const ImpactDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Impacto')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.greenDeep, AppTheme.greenMid],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DASHBOARD ESG',
                      style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 1.2,
                          color: AppTheme.greenGlow,
                          fontFamily: 'DMSans',
                          fontWeight: FontWeight.w700)),
                  SizedBox(height: 8),
                  Text('Tu impacto\nacumulado',
                      style: TextStyle(
                          fontFamily: 'DMSerifDisplay',
                          fontSize: 28,
                          color: AppTheme.cream,
                          height: 1.1)),
                  SizedBox(height: 16),
                  Row(children: [
                    _HeroStat('4,823 kg', 'Rescatados'),
                    _HeroStat('2.1 t', 'CO₂ evitado'),
                    _HeroStat('1,240', 'Familias'),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Monthly chart
            const Text('Kg rescatados por mes',
                style: AppTextStyles.headingMedium),
            const SizedBox(height: 12),
            Container(
              height: 220,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: const Border.fromBorderSide(
                    BorderSide(color: Color(0x1A2D8A55), width: 1.5)),
              ),
              child: BarChart(
                BarChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => const FlLine(
                      color: Color(0x0D2D8A55),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          const months = [
                            'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
                            'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
                          ];
                          final i = v.toInt();
                          if (i < 0 || i >= months.length) {
                            return const SizedBox();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(months[i],
                                style: const TextStyle(
                                    fontSize: 10, color: AppTheme.textMuted,
                                    fontFamily: 'DMSans')),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (v, _) => Text(
                          '${v.toInt()}',
                          style: const TextStyle(
                              fontSize: 10, color: AppTheme.textMuted,
                              fontFamily: 'DMSans'),
                        ),
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    120, 180, 210, 250, 320, 380, 290, 410, 490, 520, 600, 640
                  ].asMap().entries.map((e) {
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                          toY: e.value.toDouble(),
                          color: AppTheme.greenFresh,
                          width: 14,
                          borderRadius: BorderRadius.circular(6),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: 700,
                            color: const Color(0x0A2D8A55),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Category breakdown
            const Text('Por categoría', style: AppTextStyles.headingMedium),
            const SizedBox(height: 12),
            ...[
              ('🥦', 'Frutas y Verduras', 0.38, AppTheme.greenFresh),
              ('🍞', 'Panadería', 0.24, AppTheme.earth),
              ('🥛', 'Lácteos', 0.18, Colors.blue),
              ('🥩', 'Proteínas', 0.12, AppTheme.accentOrange),
              ('📦', 'Otros', 0.08, AppTheme.textMuted),
            ].map((item) => _CategoryBar(
              emoji: item.$1,
              label: item.$2,
              percent: item.$3,
              color: item.$4,
            )),
            const SizedBox(height: 20),
            // ODS badges
            const Text('Objetivos ODS alcanzados',
                style: AppTextStyles.headingMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                '🎯 ODS 2 — Hambre Cero',
                '🤝 ODS 1 — Fin Pobreza',
                '🌿 ODS 12 — Producción',
                '🌍 ODS 13 — Clima',
              ].map((s) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0x0D2D8A55),
                      borderRadius: BorderRadius.circular(100),
                      border: const Border.fromBorderSide(
                          BorderSide(color: Color(0x1A2D8A55))),
                    ),
                    child: Text(s,
                        style: const TextStyle(
                            fontSize: 13,
                            fontFamily: 'DMSans',
                            color: AppTheme.greenMid,
                            fontWeight: FontWeight.w500)),
                  )).toList(),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String value;
  final String label;
  const _HeroStat(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(
              fontFamily: 'DMSerifDisplay', fontSize: 20,
              color: AppTheme.greenLime, height: 1)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(
              fontSize: 11, color: Color(0x80FAF6EE), fontFamily: 'DMSans')),
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final String emoji;
  final String label;
  final double percent;
  final Color color;

  const _CategoryBar({
    required this.emoji, required this.label,
    required this.percent, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
            Text('${(percent * 100).toInt()}%',
                style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600, color: AppTheme.charcoal)),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: const Color(0x0D2D8A55),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
