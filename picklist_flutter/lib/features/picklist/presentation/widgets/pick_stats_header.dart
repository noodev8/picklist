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
    final totalPicks = provider.getTotalPicksForLocation(locationId);
    final remainingPicks = provider.getRemainingPicksForLocation(locationId);
    final completedPicks = totalPicks - remainingPicks;
    final progress = totalPicks > 0 ? completedPicks / totalPicks : 0.0;

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
      child: Column(
        children: [
          _buildProgressCircle(progress, completedPicks, totalPicks),
          AppSpacing.verticalSpaceLG,
          _buildStatsRow(completedPicks, remainingPicks, totalPicks),
        ],
      ),
    );
  }

  Widget _buildProgressCircle(double progress, int completed, int total) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            children: [
              // Background circle
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 8,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.border,
                  ),
                ),
              ),
              // Progress circle
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress == 1.0 ? AppColors.success : AppColors.primary,
                  ),
                ),
              ),
              // Center content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: AppTypography.headlineLarge.copyWith(
                        color: progress == 1.0 ? AppColors.success : AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Complete',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(int completed, int remaining, int total) {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            'Completed',
            completed.toString(),
            Icons.check_circle,
            AppColors.success,
          ),
        ),
        Container(
          width: 1,
          height: 40,
          color: AppColors.border,
        ),
        Expanded(
          child: _buildStatItem(
            'Remaining',
            remaining.toString(),
            Icons.schedule,
            AppColors.warning,
          ),
        ),
        Container(
          width: 1,
          height: 40,
          color: AppColors.border,
        ),
        Expanded(
          child: _buildStatItem(
            'Total',
            total.toString(),
            Icons.inventory_2,
            AppColors.primary,
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
