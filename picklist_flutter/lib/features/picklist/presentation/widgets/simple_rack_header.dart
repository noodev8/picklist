import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';

/*
Simple rack header widget for grouping picks by rack location.
Shows a clean divider with rack name and item count for easy navigation.
*/

class SimpleRackHeader extends StatelessWidget {
  const SimpleRackHeader({
    super.key,
    required this.rackLocation,
    required this.itemCount,
    required this.pickedCount,
  });

  final String rackLocation;
  final int itemCount;
  final int pickedCount;

  @override
  Widget build(BuildContext context) {
    final isCompleted = pickedCount == itemCount;
    final remainingCount = itemCount - pickedCount;
    
    // Get display name for the rack (e.g., "Rack 01" from "C3-Front-Rack-01")
    final displayName = _getDisplayName(rackLocation);
    
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: isCompleted 
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCompleted 
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Rack Icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCompleted ? AppColors.success : AppColors.primary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getRackIcon(rackLocation),
              color: AppColors.textOnPrimary,
              size: 18,
            ),
          ),
          
          AppSpacing.horizontalSpaceMD,
          
          // Rack Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: AppTypography.titleMedium.copyWith(
                    color: isCompleted ? AppColors.success : AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  isCompleted 
                      ? 'All $itemCount items picked'
                      : '$remainingCount of $itemCount remaining',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          // Status Badge
          if (isCompleted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check,
                    color: AppColors.textOnPrimary,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Complete',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textOnPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _getDisplayName(String location) {
    final parts = location.split('-');
    if (parts.length >= 3) {
      final type = parts[parts.length - 2]; // "Rack", "Basket", etc.
      final number = parts[parts.length - 1]; // "01", "02", etc.
      return '$type $number';
    }
    return location;
  }

  IconData _getRackIcon(String location) {
    final locationLower = location.toLowerCase();
    if (locationLower.contains('rack')) return Icons.view_module;
    if (locationLower.contains('basket')) return Icons.shopping_basket;
    if (locationLower.contains('shelf')) return Icons.shelves;
    if (locationLower.contains('display')) return Icons.storefront;
    if (locationLower.contains('counter')) return Icons.countertops;
    return Icons.inventory_2;
  }
}
