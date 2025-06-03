import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';

/// Quick actions widget for common tasks
class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.radiusMD,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.refresh,
                  label: 'Refresh',
                  color: AppColors.primary,
                  onTap: () {
                    // TODO: Implement refresh functionality
                  },
                ),
              ),
              AppSpacing.horizontalSpaceMD,
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.filter_list,
                  label: 'Filter',
                  color: AppColors.secondary,
                  onTap: () {
                    // TODO: Implement filter functionality
                  },
                ),
              ),
            ],
          ),
          AppSpacing.verticalSpaceMD,
          Row(
            children: [
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.search,
                  label: 'Search',
                  color: AppColors.info,
                  onTap: () {
                    // TODO: Implement search functionality
                  },
                ),
              ),
              AppSpacing.horizontalSpaceMD,
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.analytics,
                  label: 'Reports',
                  color: AppColors.warning,
                  onTap: () {
                    // TODO: Implement reports functionality
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.radiusSM,
        child: Container(
          padding: AppSpacing.paddingMD,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: AppRadius.radiusSM,
            border: Border.all(
              color: color.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: AppRadius.radiusSM,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              AppSpacing.verticalSpaceSM,
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
