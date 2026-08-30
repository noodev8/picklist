import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// An on-screen keypad rather than the phone keyboard.
///
/// A picker signs in holding the phone in one hand, often with gloves on. Keys
/// the width of a thumb beat a numeric keyboard that takes half the screen and
/// puts the digits somewhere different on every handset.
class PinPad extends StatelessWidget {
  const PinPad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    this.enabled = true,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final List<String> row in const <List<String>>[
          <String>['1', '2', '3'],
          <String>['4', '5', '6'],
          <String>['7', '8', '9'],
          <String>['', '0', 'back'],
        ])
          Row(
            children: row
                .map((String key) => Expanded(child: _key(key)))
                .toList(),
          ),
      ],
    );
  }

  Widget _key(String key) {
    if (key.isEmpty) return const SizedBox(height: 68);

    final bool isBackspace = key == 'back';

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.md,
        child: InkWell(
          borderRadius: AppRadius.md,
          onTap: enabled
              ? () {
                  HapticFeedback.selectionClick();
                  if (isBackspace) {
                    onBackspace();
                  } else {
                    onDigit(key);
                  }
                }
              : null,
          child: Container(
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: AppRadius.md,
              border: Border.all(
                color: isBackspace ? Colors.transparent : AppColors.rule,
              ),
            ),
            child: isBackspace
                ? const Icon(
                    Icons.backspace_outlined,
                    color: AppColors.chalkDim,
                    size: 22,
                  )
                : Text(
                    key,
                    style: AppTypography.sizeNumeral.copyWith(
                      color: enabled ? AppColors.chalk : AppColors.chalkFaint,
                      fontSize: 28,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Four slots that fill as the PIN is typed. Shows how far along you are without
/// showing the PIN itself.
class PinDots extends StatelessWidget {
  const PinDots({
    super.key,
    required this.filled,
    required this.length,
    this.hasError = false,
  });

  final int filled;
  final int length;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(length, (int index) {
        final bool isFilled = index < filled;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          margin: const EdgeInsets.symmetric(horizontal: 7),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: hasError
                ? AppColors.alert
                : (isFilled ? AppColors.signal : Colors.transparent),
            border: Border.all(
              color: hasError
                  ? AppColors.alert
                  : (isFilled ? AppColors.signal : AppColors.rule),
              width: 2,
            ),
          ),
        );
      }),
    );
  }
}
