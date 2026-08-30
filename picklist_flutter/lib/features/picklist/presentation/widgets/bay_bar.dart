import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Marks the point in the list where a picker walks to the next bay.
///
/// It carries the bay number and nothing else that competes with it, because the
/// bar's whole job is to be the thing you look up and match against the rack.
class BayBar extends StatelessWidget {
  const BayBar({
    super.key,
    required this.bay,
    required this.area,
    required this.remaining,
    required this.total,
    this.showArea = false,
  });

  /// Bay number within its area, e.g. `02`.
  final String bay;

  /// Area the bay sits in, e.g. `C3-Front`.
  final String area;

  final int remaining;
  final int total;

  /// Shown when the list spans the whole unit and the bay number alone would be
  /// ambiguous.
  final bool showArea;

  @override
  Widget build(BuildContext context) {
    final bool clear = remaining == 0;
    final Color accent = clear ? AppColors.done : AppColors.signal;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
      child: Row(
        children: <Widget>[
          Container(width: 3, height: 22, color: accent),
          AppSpacing.w8,
          Text(
            showArea ? '${area.toUpperCase()}  $bay' : 'BAY $bay',
            style: AppTypography.bayCode.copyWith(
              color: clear ? AppColors.chalkDim : AppColors.chalk,
              fontSize: 22,
            ),
          ),
          AppSpacing.w12,
          const Expanded(child: Divider(color: AppColors.rule)),
          // A single untouched line needs no tally - the row below already
          // says everything the tally would.
          if (clear || total > 1) ...<Widget>[
            AppSpacing.w12,
            Text(
              clear ? 'done' : '$remaining of $total',
              style: AppTypography.detail.copyWith(
                color: clear ? AppColors.done : AppColors.chalkDim,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
