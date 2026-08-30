import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/pick_area.dart';

/// One area of the unit, set like the signage hanging over an aisle: a coloured
/// spine, the area name in condensed caps, and the number still to pick.
///
/// Two or three people pick at once and each takes an area, so the count on the
/// right is the number that decides who goes where - it gets the largest type on
/// the screen. The spine turns green when an area is clear, which is readable
/// from across the room without reading anything.
class AreaPlate extends StatelessWidget {
  const AreaPlate({
    super.key,
    required this.area,
    required this.onTap,
  });

  final PickArea area;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color accent = area.isClear ? AppColors.done : AppColors.signal;

    return Semantics(
      button: true,
      label: area.isClear
          ? '${area.name}, all ${area.total} picked'
          : '${area.name}, ${area.remaining} of ${area.total} left',
      child: Material(
        color: AppColors.deck,
        borderRadius: AppRadius.md,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Container(width: 4, color: accent),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                area.name.toUpperCase(),
                                style: AppTypography.bayCode.copyWith(
                                  color: area.isClear
                                      ? AppColors.chalkDim
                                      : AppColors.chalk,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            AppSpacing.w12,
                            if (area.isClear)
                              const _ClearBadge()
                            else
                              Text(
                                '${area.remaining}',
                                style: AppTypography.counter.copyWith(
                                  color: AppColors.signal,
                                ),
                              ),
                          ],
                        ),
                        AppSpacing.h8,
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: _ProgressRule(
                                progress: area.progress,
                                accent: accent,
                              ),
                            ),
                            AppSpacing.w12,
                            Text(
                              area.isClear
                                  ? '${area.total} lines'
                                  : '${area.picked} of ${area.total} picked',
                              style: AppTypography.detail,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ClearBadge extends StatelessWidget {
  const _ClearBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.done.withValues(alpha: 0.14),
        borderRadius: AppRadius.pill,
        border: Border.all(color: AppColors.done.withValues(alpha: 0.5)),
      ),
      child: Text(
        'CLEAR',
        style: AppTypography.labelSmall.copyWith(color: AppColors.done),
      ),
    );
  }
}

/// A hairline that fills as the area is worked through. Deliberately thin - it
/// is a glanceable shape, not a number to read.
class _ProgressRule extends StatelessWidget {
  const _ProgressRule({required this.progress, required this.accent});

  final double progress;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.pill,
      child: SizedBox(
        height: 3,
        child: LinearProgressIndicator(
          value: progress,
          backgroundColor: AppColors.rule,
          valueColor: AlwaysStoppedAnimation<Color>(accent),
        ),
      ),
    );
  }
}
