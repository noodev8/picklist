import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';

/// Custom PIN input field with individual digit boxes
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
  late List<FocusNode> _focusNodes;
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _setupControllers();
    _setupListeners();
  }

  void _setupControllers() {
    _focusNodes = List.generate(
      widget.pinLength,
      (index) => FocusNode(),
    );
    _controllers = List.generate(
      widget.pinLength,
      (index) => TextEditingController(),
    );
  }

  void _setupListeners() {
    widget.controller.addListener(_onMainControllerChanged);
    
    for (int i = 0; i < widget.pinLength; i++) {
      _controllers[i].addListener(() => _onDigitChanged(i));
    }
  }

  void _onMainControllerChanged() {
    final text = widget.controller.text;
    for (int i = 0; i < widget.pinLength; i++) {
      _controllers[i].text = i < text.length ? text[i] : '';
    }
  }

  void _onDigitChanged(int index) {
    final digit = _controllers[index].text;
    
    // Update main controller
    final currentPin = _controllers.map((c) => c.text).join();
    widget.controller.text = currentPin;
    widget.onChanged?.call(currentPin);
    
    // Handle navigation between fields
    if (digit.isNotEmpty && index < widget.pinLength - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (digit.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    
    // Submit when complete
    if (currentPin.length == widget.pinLength) {
      widget.onSubmitted?.call(currentPin);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onMainControllerChanged);
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            widget.pinLength,
            (index) => _buildDigitField(index),
          ),
        ),
        if (widget.errorText != null) ...[
          AppSpacing.verticalSpaceSM,
          _buildErrorText(),
        ],
      ],
    );
  }

  Widget _buildDigitField(int index) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: widget.enabled ? AppColors.surface : AppColors.surfaceVariant,
        borderRadius: AppRadius.radiusMD,
        border: Border.all(
          color: _getFieldBorderColor(index),
          width: _focusNodes[index].hasFocus ? 2 : 1,
        ),
        boxShadow: _focusNodes[index].hasFocus
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
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        enabled: widget.enabled,
        textAlign: TextAlign.center,
        style: AppTypography.headlineLarge.copyWith(
          fontWeight: FontWeight.bold,
          color: widget.enabled ? AppColors.textPrimary : AppColors.textTertiary,
        ),
        keyboardType: TextInputType.number,
        obscureText: true,
        maxLength: 1,
        decoration: const InputDecoration(
          border: InputBorder.none,
          counterText: '',
          contentPadding: EdgeInsets.zero,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        onChanged: (value) {
          if (value.length > 1) {
            _controllers[index].text = value.substring(value.length - 1);
          }
        },
      ),
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

  Color _getFieldBorderColor(int index) {
    if (!widget.enabled) return AppColors.border;
    if (widget.errorText != null) return AppColors.error;
    if (_focusNodes[index].hasFocus) return AppColors.primary;
    if (_controllers[index].text.isNotEmpty) return AppColors.success;
    return AppColors.border;
  }
}
