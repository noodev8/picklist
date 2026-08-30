import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/pick_mode.dart';

/// Switches to the job the picker is *not* doing.
///
/// Customer picks run every day and Amazon stock runs every week or two, so the
/// two jobs are not offered as an even choice. The app opens on customer picks
/// and this sits below the areas as a way out to the other job - out of the way
/// of the run somebody is almost always here to do.
class JobLink extends StatelessWidget {
  const JobLink({
    super.key,
    required this.current,
    required this.onSwitch,
    this.enabled = true,
  });

  final PickMode current;
  final ValueChanged<PickMode> onSwitch;
  final bool enabled;

  PickMode get _other =>
      current == PickMode.customer ? PickMode.amazon : PickMode.customer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('OTHER JOB', style: AppTypography.eyebrow),
        AppSpacing.h12,
        Material(
          color: Colors.transparent,
          borderRadius: AppRadius.md,
          child: InkWell(
            borderRadius: AppRadius.md,
            onTap: enabled
                ? () {
                    HapticFeedback.selectionClick();
                    onSwitch(_other);
                  }
                : null,
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: AppRadius.md,
                border: Border.all(color: AppColors.rule),
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    _other == PickMode.amazon
                        ? Icons.inventory_rounded
                        : Icons.receipt_long_rounded,
                    size: 18,
                    color: AppColors.chalkFaint,
                  ),
                  AppSpacing.w12,
                  Expanded(
                    child: Text(
                      'Switch to ${_other.jobName}',
                      style: AppTypography.label
                          .copyWith(color: AppColors.chalkDim),
                    ),
                  ),
                  const Icon(
                    Icons.swap_horiz_rounded,
                    size: 18,
                    color: AppColors.chalkFaint,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Marks the screen when the run is Amazon stock rather than the everyday
/// customer picks, so nobody works the wrong list by habit.
class JobTag extends StatelessWidget {
  const JobTag({super.key, required this.mode});

  final PickMode mode;

  @override
  Widget build(BuildContext context) {
    if (mode != PickMode.amazon) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(left: AppSpacing.md),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.signal.withValues(alpha: 0.16),
        borderRadius: AppRadius.sm,
        border: Border.all(color: AppColors.signal.withValues(alpha: 0.55)),
      ),
      child: Text(
        'AMAZON',
        style: AppTypography.labelSmall.copyWith(color: AppColors.signal),
      ),
    );
  }
}
