import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/pick_item.dart';

/// One line of the run, laid out in the order a picker's eye moves: size, then
/// code, then move on.
///
/// The size sits in a box shaped like the label on the end of a shoebox, and the
/// style reference follows it at nearly the same weight - between them they
/// identify the box on the shelf. The shoe name and colour are demoted to a
/// single quiet line: useful when something does not look right, never the thing
/// being scanned for. The whole row is the target, and tapping a picked row puts
/// the pick back.
class PickRow extends StatelessWidget {
  const PickRow({
    super.key,
    required this.item,
    required this.onToggle,
    this.isBusy = false,
  });

  final PickItem item;
  final VoidCallback onToggle;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final bool picked = item.isPicked;

    return Semantics(
      button: true,
      label: 'Size ${item.size}, code ${item.styleRef}, '
          '${item.displayName}, bay ${item.location}',
      hint: picked ? 'Picked. Tap to put back' : 'Tap to pick',
      child: Material(
        color: picked ? AppColors.ground : AppColors.deck,
        borderRadius: AppRadius.md,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isBusy ? null : onToggle,
          child: AnimatedOpacity(
            opacity: isBusy ? 0.45 : 1,
            duration: const Duration(milliseconds: 120),
            child: Container(
              constraints: const BoxConstraints(minHeight: 72),
              padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
              decoration: BoxDecoration(
                borderRadius: AppRadius.md,
                border: Border.all(
                  color: picked
                      ? AppColors.done.withValues(alpha: 0.28)
                      : AppColors.rule,
                ),
              ),
              child: Row(
                children: <Widget>[
                  _SizeChip(size: item.size, picked: picked),
                  AppSpacing.w12,
                  Expanded(child: _details(picked)),
                  // Nothing sits here while a line is outstanding: a chevron
                  // would promise a screen that tapping does not open.
                  if (picked) ...<Widget>[
                    AppSpacing.w8,
                    const Icon(
                      Icons.undo_rounded,
                      size: 16,
                      color: AppColors.chalkFaint,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _details(bool picked) {
    final List<String> facts = <String>[
      item.displayName,
      if (item.showsColourSeparately) item.colour,
      if (item.orderNum.isNotEmpty && item.orderNum != '#FREE') item.orderNum,
    ].where((String fact) => fact.isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          item.styleRef.isEmpty ? item.productCode : item.styleRef,
          style: AppTypography.itemCode.copyWith(
            color: picked ? AppColors.chalkFaint : AppColors.chalk,
            decoration: picked ? TextDecoration.lineThrough : null,
            decorationColor: AppColors.chalkFaint,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (facts.isNotEmpty) ...<Widget>[
          AppSpacing.h4,
          Text(
            facts.join('  ·  '),
            style: AppTypography.detail.copyWith(
              color: picked ? AppColors.chalkFaint : AppColors.chalkDim,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

/// The shoebox end-label: the size, boxed, at the size it can be read at arm's
/// length. Amber outline while it is still to pick, solid green once it is done.
class _SizeChip extends StatelessWidget {
  const _SizeChip({required this.size, required this.picked});

  final String size;
  final bool picked;

  @override
  Widget build(BuildContext context) {
    final bool short = size.length <= 3;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: 54,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: picked ? AppColors.done : Colors.transparent,
        borderRadius: AppRadius.sm,
        border: Border.all(
          color: picked ? AppColors.done : AppColors.signal,
          width: 2,
        ),
      ),
      // The size stays readable once picked. It is what someone checks against
      // the box in their hand before deciding to put a pick back.
      child: Text(
        size.isEmpty ? '—' : size,
        maxLines: 1,
        style: AppTypography.sizeNumeral.copyWith(
          color: picked ? AppColors.ground : AppColors.signal,
          fontSize: short ? 30 : 20,
        ),
      ),
    );
  }
}
