import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:feed_the_future/core/constants/app_constants.dart';
import 'package:feed_the_future/core/theme/app_theme.dart';

class DonationFilterBar extends ConsumerWidget {
  const DonationFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.greenFresh.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          // Category filter
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: ref.watch(categoryFilterProvider) ?? 'Todas',
              decoration: const InputDecoration(
                labelText: 'Categoría',
                labelStyle: TextStyle(color: AppTheme.textMuted),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              icon: const Icon(Icons.category_outlined),
              items: ['Todas', ...AppConstants.foodCategories]
                  .map((category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ))
                  .toList(),
              onChanged: (value) {
                ref.read(categoryFilterProvider.notifier).state = value;
              },
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Status filter
          Expanded(
            child: DropdownButtonFormField<String>(
              value: ref.watch(statusFilterProvider) ?? 'Todas',
              decoration: const InputDecoration(
                labelText: 'Estado',
                labelStyle: TextStyle(color: AppTheme.textMuted),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              icon: const Icon(Icons.filter_list_outlined),
              items: [
                'Todas',
                AppConstants.statusAvailable,
                AppConstants.statusPending,
                AppConstants.statusMatched,
                AppConstants.statusInTransit,
              ]
                  .map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(_getStatusDisplayName(status)),
                      ))
                  .toList(),
              onChanged: (value) {
                ref.read(statusFilterProvider.notifier).state = value;
              },
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Sort button
          IconButton(
            onPressed: () {
              // Toggle sort order
              ref.read(sortOrderProvider.notifier).state = 
                  !(ref.read(sortOrderProvider) ?? false);
            },
            icon: Icon(
              ref.watch(sortOrderProvider) ?? false
                  ? Icons.arrow_upward
                  : Icons.arrow_downward,
            ),
            tooltip: 'Ordenar por fecha',
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.greenFresh.withOpacity(0.1),
              foregroundColor: AppTheme.greenFresh,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusDisplayName(String status) {
    switch (status) {
      case AppConstants.statusAvailable:
        return 'Disponible';
      case AppConstants.statusPending:
        return 'Pendiente';
      case AppConstants.statusMatched:
        return 'Asignada';
      case AppConstants.statusInTransit:
        return 'En tránsito';
      default:
        return status;
    }
  }
}

// Providers for filter state
final categoryFilterProvider = StateProvider<String?>((ref) => null);
final statusFilterProvider = StateProvider<String?>((ref) => null);
final sortOrderProvider = StateProvider<bool>((ref) => false);
