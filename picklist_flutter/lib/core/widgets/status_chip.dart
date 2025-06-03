import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';

/// Status chip widget for displaying pick status with consistent styling
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.status,
    this.size = ChipSize.medium,
  });

  final PickStatus status;
  final ChipSize size;

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(status);
    
    return Container(
      padding: _getPadding(),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: AppRadius.radiusSM,
        border: Border.all(
          color: config.borderColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config.icon,
            size: _getIconSize(),
            color: config.iconColor,
          ),
          AppSpacing.horizontalSpaceXS,
          Text(
            config.label,
            style: _getTextStyle().copyWith(
              color: config.textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case ChipSize.small:
        return const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        );
      case ChipSize.medium:
        return const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        );
    }
  }

  double _getIconSize() {
    switch (size) {
      case ChipSize.small:
        return 12;
      case ChipSize.medium:
        return 14;
    }
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case ChipSize.small:
        return AppTypography.labelSmall;
      case ChipSize.medium:
        return AppTypography.labelMedium;
    }
  }

  _StatusConfig _getStatusConfig(PickStatus status) {
    switch (status) {
      case PickStatus.pending:
        return _StatusConfig(
          label: 'Pending',
          icon: Icons.schedule,
          backgroundColor: AppColors.warning.withValues(alpha: 0.1),
          borderColor: AppColors.warning.withValues(alpha: 0.3),
          iconColor: AppColors.warning,
          textColor: AppColors.warning,
        );
      case PickStatus.picked:
        return _StatusConfig(
          label: 'Picked',
          icon: Icons.check_circle,
          backgroundColor: AppColors.success.withValues(alpha: 0.1),
          borderColor: AppColors.success.withValues(alpha: 0.3),
          iconColor: AppColors.success,
          textColor: AppColors.success,
        );
      case PickStatus.priority:
        return _StatusConfig(
          label: 'Priority',
          icon: Icons.priority_high,
          backgroundColor: AppColors.error.withValues(alpha: 0.1),
          borderColor: AppColors.error.withValues(alpha: 0.3),
          iconColor: AppColors.error,
          textColor: AppColors.error,
        );
    }
  }
}

class _StatusConfig {
  const _StatusConfig({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    required this.textColor,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final Color textColor;
}

enum PickStatus {
  pending,
  picked,
  priority,
}

enum ChipSize {
  small,
  medium,
}
