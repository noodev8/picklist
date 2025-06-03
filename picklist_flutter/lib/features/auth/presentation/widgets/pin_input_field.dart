import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';

/// Custom PIN input field with single text box
class PinInputField extends StatefulWidget {
  const PinInputField({
    super.key,
    required this.controller,
    this.onSubmitted,
    this.onChanged,
    this.errorText,
    this.enabled = true,
    this.pinLength = 4,
  });

  final TextEditingController controller;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final bool enabled;
  final int pinLength;

  @override
  State<PinInputField> createState() => _PinInputFieldState();
}

class _PinInputFieldState extends State<PinInputField> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    widget.onChanged?.call(value);

    // Auto-submit when PIN is complete
    if (value.length == widget.pinLength) {
      widget.onSubmitted?.call(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 200,
          height: 60,
          decoration: BoxDecoration(
            color: widget.enabled ? AppColors.surface : AppColors.surfaceVariant,
            borderRadius: AppRadius.radiusMD,
            border: Border.all(
              color: _getBorderColor(),
              width: _focusNode.hasFocus ? 2 : 1,
            ),
            boxShadow: _focusNode.hasFocus
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            enabled: widget.enabled,
            textAlign: TextAlign.center,
            style: AppTypography.headlineLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: widget.enabled ? AppColors.textPrimary : AppColors.textTertiary,
              letterSpacing: 8.0,
            ),
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: widget.pinLength,
            decoration: InputDecoration(
              border: InputBorder.none,
              counterText: '',
              contentPadding: EdgeInsets.zero,
              hintText: '••••',
              hintStyle: AppTypography.headlineLarge.copyWith(
                color: AppColors.textTertiary,
                letterSpacing: 8.0,
              ),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(widget.pinLength),
            ],
            onChanged: _onChanged,
            onSubmitted: widget.onSubmitted,
          ),
        ),
        if (widget.errorText != null) ...[
          AppSpacing.verticalSpaceSM,
          _buildErrorText(),
        ],
      ],
    );
  }

  Widget _buildErrorText() {
    return Container(
      padding: AppSpacing.paddingHorizontalMD,
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            size: 16,
            color: AppColors.error,
          ),
          AppSpacing.horizontalSpaceXS,
          Expanded(
            child: Text(
              widget.errorText!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getBorderColor() {
    if (!widget.enabled) return const Color.fromARGB(0, 255, 255, 255);
    if (widget.errorText != null) return AppColors.error;
    if (_focusNode.hasFocus) return AppColors.primary;
    if (widget.controller.text.isNotEmpty) return AppColors.success;
    return const Color.fromARGB(0, 255, 255, 255);
  }
}
