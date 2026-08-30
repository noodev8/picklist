import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/pick_mode.dart';

/// Segmented control for choosing which picking job the picker is doing.
///
/// Customer and Amazon picks are separate lists with different mechanics, so this is
/// a once-at-the-start decision rather than something toggled mid-list. It sits at the
/// top of the dashboard for that reason, and the pick list screen shows a badge so the
/// choice stays visible after navigating away from here.
class PickModeSelector extends StatelessWidget {
  const PickModeSelector({
    super.key,
    required this.selectedMode,
    required this.onModeSelected,
    this.enabled = true,
  });

  final PickMode selectedMode;
  final ValueChanged<PickMode> onModeSelected;

  /// Disabled while picks are loading, so a picker cannot queue up mode switches
  /// faster than the lists can be fetched.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.radiusMD,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          for (final PickMode mode in PickMode.values)
            Expanded(
              child: _ModeButton(
                mode: mode,
                isSelected: mode == selectedMode,
                enabled: enabled,
                onTap: () => onModeSelected(mode),
              ),
            ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.mode,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
  });

  final PickMode mode;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Amazon uses the secondary colour so the two jobs are told apart at a glance,
    // not just by reading the label
    final Color activeColor =
        mode == PickMode.amazon ? AppColors.secondary : AppColors.primary;

    return Material(
      color: isSelected ? activeColor : Colors.transparent,
      borderRadius: AppRadius.radiusSM,
      child: InkWell(
        onTap: enabled && !isSelected ? onTap : null,
        borderRadius: AppRadius.radiusSM,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                mode == PickMode.amazon
                    ? Icons.inventory_2_outlined
                    : Icons.shopping_bag_outlined,
                size: 18,
                color: isSelected
                    ? AppColors.textOnPrimary
                    : AppColors.textSecondary,
              ),
              AppSpacing.horizontalSpaceSM,
              Text(
                mode.displayName,
                style: AppTypography.titleSmall.copyWith(
                  color: isSelected
                      ? AppColors.textOnPrimary
                      : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
