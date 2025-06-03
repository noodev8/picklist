import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';

/// Custom button widget with consistent styling and behavior
class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.fullWidth = false,
  });

  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool isLoading;
  final bool isDisabled;
  final IconData? icon;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final isEnabled = !isDisabled && !isLoading && onPressed != null;
    
    Widget button;
    
    switch (variant) {
      case ButtonVariant.primary:
        button = _buildElevatedButton(context, isEnabled);
        break;
      case ButtonVariant.secondary:
        button = _buildOutlinedButton(context, isEnabled);
        break;
      case ButtonVariant.text:
        button = _buildTextButton(context, isEnabled);
        break;
    }

    if (fullWidth) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }

  Widget _buildElevatedButton(BuildContext context, bool isEnabled) {
    return ElevatedButton(
      onPressed: isEnabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: isEnabled ? AppColors.primary : AppColors.textTertiary,
        foregroundColor: AppColors.textOnPrimary,
        padding: _getPadding(),
        minimumSize: _getMinimumSize(),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.radiusMD,
        ),
        elevation: isEnabled ? AppElevation.sm : 0,
      ),
      child: _buildButtonContent(),
    );
  }

  Widget _buildOutlinedButton(BuildContext context, bool isEnabled) {
    return OutlinedButton(
      onPressed: isEnabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: isEnabled ? AppColors.primary : AppColors.textTertiary,
        padding: _getPadding(),
        minimumSize: _getMinimumSize(),
        side: BorderSide(
          color: isEnabled ? AppColors.primary : AppColors.textTertiary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.radiusMD,
        ),
      ),
      child: _buildButtonContent(),
    );
  }

  Widget _buildTextButton(BuildContext context, bool isEnabled) {
    return TextButton(
      onPressed: isEnabled ? onPressed : null,
      style: TextButton.styleFrom(
        foregroundColor: isEnabled ? AppColors.primary : AppColors.textTertiary,
        padding: _getPadding(),
        minimumSize: _getMinimumSize(),
      ),
      child: _buildButtonContent(),
    );
  }

  Widget _buildButtonContent() {
    if (isLoading) {
      return SizedBox(
        height: _getTextStyle().fontSize,
        width: _getTextStyle().fontSize,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            variant == ButtonVariant.primary 
                ? AppColors.textOnPrimary 
                : AppColors.primary,
          ),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: _getIconSize()),
          AppSpacing.horizontalSpaceSM,
          Text(text, style: _getTextStyle()),
        ],
      );
    }

    return Text(text, style: _getTextStyle());
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm);
      case ButtonSize.medium:
        return AppSpacing.buttonPadding;
      case ButtonSize.large:
        return AppSpacing.buttonPaddingLarge;
    }
  }

  Size _getMinimumSize() {
    switch (size) {
      case ButtonSize.small:
        return const Size(0, 36);
      case ButtonSize.medium:
        return const Size(0, 44);
      case ButtonSize.large:
        return const Size(0, 52);
    }
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case ButtonSize.small:
        return AppTypography.labelMedium;
      case ButtonSize.medium:
        return AppTypography.buttonText;
      case ButtonSize.large:
        return AppTypography.labelLarge;
    }
  }

  double _getIconSize() {
    switch (size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.medium:
        return 18;
      case ButtonSize.large:
        return 20;
    }
  }
}

enum ButtonVariant {
  primary,
  secondary,
  text,
}

enum ButtonSize {
  small,
  medium,
  large,
}
