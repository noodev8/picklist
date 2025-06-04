import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../models/pick_location.dart';

/// Enhanced location card with progress indicator and status
class LocationCard extends StatelessWidget {
  const LocationCard({
    super.key,
    required this.location,
    required this.remainingPicks,
    required this.totalPicks,
    required this.onTap,
  });

  final PickLocation location;
  final int remainingPicks;
  final int totalPicks;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final completedPicks = totalPicks - remainingPicks;
    final progress = totalPicks > 0 ? completedPicks / totalPicks : 0.0;
    final isCompleted = remainingPicks == 0;
    final hasPicks = totalPicks > 0;

    return Card(
      elevation: AppElevation.sm,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.radiusMD,
        child: Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            borderRadius: AppRadius.radiusMD,
            // Make the entire card background fully green when completed
            color: isCompleted
                ? AppColors.success.withValues(alpha: 0.2)
                : null,
            border: Border.all(
              color: isCompleted
                  ? AppColors.success.withValues(alpha: 0.3)
                  : AppColors.border,
              width: isCompleted ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              AppSpacing.verticalSpaceMD,
              _buildProgressSection(progress, hasPicks),
              AppSpacing.verticalSpaceMD,
              _buildFooter(isCompleted, hasPicks),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: AppRadius.radiusSM,
          ),
          child: Icon(
            _getLocationIcon(),
            color: AppColors.primary,
            size: 20,
          ),
        ),
        AppSpacing.horizontalSpaceMD,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                location.name,
                style: AppTypography.titleLarge,
              ),
              AppSpacing.verticalSpaceXS,
              Text(
                _getLocationDescription(),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.chevron_right,
          color: AppColors.textSecondary,
        ),
      ],
    );
  }

  Widget _buildProgressSection(double progress, bool hasPicks) {
    if (!hasPicks) {
      return Container(
        padding: AppSpacing.paddingMD,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: AppRadius.radiusSM,
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 16,
              color: AppColors.textSecondary,
            ),
            AppSpacing.horizontalSpaceXS,
            Text(
              'No picks available',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        AppSpacing.verticalSpaceXS,
        LinearProgressIndicator(
          value: progress,
          backgroundColor: AppColors.border,
          valueColor: AlwaysStoppedAnimation<Color>(
            progress == 1.0 ? AppColors.success : AppColors.primary,
          ),
          borderRadius: AppRadius.radiusXS,
        ),
      ],
    );
  }

  Widget _buildFooter(bool isCompleted, bool hasPicks) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (hasPicks) ...[
          Row(
            children: [
              _buildPickCount(
                'Completed',
                totalPicks - remainingPicks,
                AppColors.success,
              ),
              AppSpacing.horizontalSpaceLG,
              _buildPickCount(
                'Remaining',
                remainingPicks,
                AppColors.warning,
              ),
            ],
          ),
        ],
        // StatusChip removed as requested - no pending/complete chip display
      ],
    );
  }

  Widget _buildPickCount(String label, int count, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          count.toString(),
          style: AppTypography.titleMedium.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  IconData _getLocationIcon() {
    final name = location.name.toLowerCase();
    if (name.contains('front')) return Icons.storefront;
    if (name.contains('back')) return Icons.warehouse;
    if (name.contains('crocs')) return Icons.category;
    if (name.contains('shop')) return Icons.shopping_bag;
    return Icons.location_on;
  }

  String _getLocationDescription() {
    final name = location.name.toLowerCase();
    if (name.contains('front')) return 'Front warehouse section';
    if (name.contains('back')) return 'Back warehouse section';
    if (name.contains('crocs')) return 'Crocs product area';
    if (name.contains('shop')) return 'Shop floor items';
    if (name.contains('c1')) return 'C1 storage area';
    return 'Warehouse location';
  }
}
