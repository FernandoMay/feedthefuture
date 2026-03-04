import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:feed_the_future/core/theme/app_theme.dart';
import 'package:feed_the_future/core/routes/app_router.dart';
import 'package:feed_the_future/features/donations/domain/entities/donation.dart';

class DonationCard extends ConsumerWidget {
  final Donation donation;
  final VoidCallback? onTap;

  const DonationCard({
    super.key,
    required this.donation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with category and status
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(donation.category),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      donation.category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        donation.name,
                        style: AppTextStyles.headingMedium.copyWith(
                          color: AppTheme.charcoal,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_outlined,
                            size: 16,
                            color: AppTheme.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(donation.expirationDate),
                            style: AppTextStyles.caption.copyWith(
                              color: _getExpirationColor(donation),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Description
              Text(
                donation.description,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppTheme.charcoal,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              
              // Quantity and location
              Row(
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                    size: 20,
                    color: AppTheme.greenFresh,
                  ),
                  const SizedBox(width: 8),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${donation.quantity.toStringAsFixed(1)} ${donation.unit}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppTheme.greenFresh,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        donation.location.address,
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Frutas y Verduras':
        return Colors.green;
      case 'Lácteos':
        return Colors.blue;
      case 'Panadería':
        return Colors.orange;
      case 'Carnes':
        return Colors.red;
      default:
        return AppTheme.greenFresh;
    }
  }

  Color _getExpirationColor(Donation donation) {
    if (donation.isExpiringSoon) {
      return AppTheme.warningAmber;
    }
    if (donation.isUrgent) {
      return AppTheme.dangerRed;
    }
    return AppTheme.textMuted;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);
    
    if (difference.inDays == 0) {
      return 'Hoy';
    } else if (difference.inDays == 1) {
      return 'Mañana';
    } else if (difference.inDays < 7) {
      return 'En ${difference.inDays} días';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }
}
