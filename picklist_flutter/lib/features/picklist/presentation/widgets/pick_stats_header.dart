import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../providers/picklist_provider.dart';

/// Header widget showing pick statistics for a location
class PickStatsHeader extends StatelessWidget {
  const PickStatsHeader({
    super.key,
    required this.locationId,
    required this.provider,
  });

  final String locationId;
  final PicklistProvider provider;

  @override
  Widget build(BuildContext context) {
    // Get pick counts for the location
    final totalPicks = provider.getTotalPicksForLocation(locationId);
    final remainingPicks = provider.getRemainingPicksForLocation(locationId);
    final completedPicks = totalPicks - remainingPicks;

    return Container(
      margin: AppSpacing.screenPadding,
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.05),
            AppColors.primary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: AppRadius.radiusMD,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: _buildStatsRow(completedPicks, remainingPicks),
    );
  }



  Widget _buildStatsRow(int completed, int remaining) {
    return Row(
      children: [
        // Completed picks section
        Expanded(
          child: _buildStatItem(
            'Completed',
            completed.toString(),
            Icons.check_circle,
            AppColors.success,
          ),
        ),
        // Divider between stats
        Container(
          width: 1,
          height: 40,
          color: AppColors.border,
        ),
        // Pending (remaining) picks section
        Expanded(
          child: _buildStatItem(
            'Pending',
            remaining.toString(),
            Icons.schedule,
            AppColors.warning,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        AppSpacing.verticalSpaceXS,
        Text(
          value,
          style: AppTypography.headlineMedium.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
