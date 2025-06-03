import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/app_spacing.dart';

/// Main theme configuration for the picklist app
/// Provides both light and dark themes with consistent styling
class AppTheme {
  AppTheme._();

  /// Light theme configuration
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: _lightColorScheme,
        textTheme: _textTheme,
        appBarTheme: _lightAppBarTheme,
        elevatedButtonTheme: _elevatedButtonTheme,
        outlinedButtonTheme: _outlinedButtonTheme,
        textButtonTheme: _textButtonTheme,
        cardTheme: _cardTheme,
        inputDecorationTheme: _inputDecorationTheme,
        chipTheme: _chipTheme,
        bottomNavigationBarTheme: _bottomNavigationBarTheme,
        floatingActionButtonTheme: _floatingActionButtonTheme,
        dividerTheme: _dividerTheme,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: AppTypography.fontFamily,
      );

  /// Dark theme configuration
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: _darkColorScheme,
        textTheme: _darkTextTheme,
        appBarTheme: _darkAppBarTheme,
        elevatedButtonTheme: _elevatedButtonTheme,
        outlinedButtonTheme: _outlinedButtonTheme,
        textButtonTheme: _textButtonTheme,
        cardTheme: _darkCardTheme,
        inputDecorationTheme: _darkInputDecorationTheme,
        chipTheme: _darkChipTheme,
        bottomNavigationBarTheme: _darkBottomNavigationBarTheme,
        floatingActionButtonTheme: _floatingActionButtonTheme,
        dividerTheme: _darkDividerTheme,
        scaffoldBackgroundColor: AppColors.darkBackground,
        fontFamily: AppTypography.fontFamily,
      );

  // Color Schemes
  static const ColorScheme _lightColorScheme = ColorScheme.light(
    primary: AppColors.primary,
    onPrimary: AppColors.textOnPrimary,
    secondary: AppColors.secondary,
    onSecondary: AppColors.textOnSecondary,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    error: AppColors.error,
    onError: AppColors.textOnPrimary,
    outline: AppColors.border,
    surfaceContainerHighest: AppColors.surfaceVariant,
  );

  static const ColorScheme _darkColorScheme = ColorScheme.dark(
    primary: AppColors.primaryLight,
    onPrimary: AppColors.textPrimary,
    secondary: AppColors.secondaryLight,
    onSecondary: AppColors.textPrimary,
    surface: AppColors.darkSurface,
    onSurface: AppColors.darkTextPrimary,
    error: AppColors.error,
    onError: AppColors.textOnPrimary,
    outline: AppColors.darkBorder,
    surfaceContainerHighest: AppColors.darkSurfaceVariant,
  );

  // Text Themes
  static TextTheme get _textTheme => TextTheme(
        displayLarge: AppTypography.displayLarge,
        displayMedium: AppTypography.displayMedium,
        displaySmall: AppTypography.displaySmall,
        headlineLarge: AppTypography.headlineLarge,
        headlineMedium: AppTypography.headlineMedium,
        headlineSmall: AppTypography.headlineSmall,
        titleLarge: AppTypography.titleLarge,
        titleMedium: AppTypography.titleMedium,
        titleSmall: AppTypography.titleSmall,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        bodySmall: AppTypography.bodySmall,
        labelLarge: AppTypography.labelLarge,
        labelMedium: AppTypography.labelMedium,
        labelSmall: AppTypography.labelSmall,
      );

  static TextTheme get _darkTextTheme => _textTheme.apply(
        bodyColor: AppColors.darkTextPrimary,
        displayColor: AppColors.darkTextPrimary,
      );

  // App Bar Themes
  static AppBarTheme get _lightAppBarTheme => AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: AppElevation.none,
        centerTitle: true,
        titleTextStyle: AppTypography.headlineMedium,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actionsIconTheme: const IconThemeData(color: AppColors.textPrimary),
      );

  static AppBarTheme get _darkAppBarTheme => AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: AppElevation.none,
        centerTitle: true,
        titleTextStyle: AppTypography.headlineMedium.copyWith(
          color: AppColors.darkTextPrimary,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: const IconThemeData(color: AppColors.darkTextPrimary),
        actionsIconTheme: const IconThemeData(color: AppColors.darkTextPrimary),
      );

  // Button Themes
  static ElevatedButtonThemeData get _elevatedButtonTheme =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: AppElevation.sm,
          padding: AppSpacing.buttonPadding,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.radiusMD,
          ),
          textStyle: AppTypography.buttonText,
        ),
      );

  static OutlinedButtonThemeData get _outlinedButtonTheme =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: AppSpacing.buttonPadding,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.radiusMD,
          ),
          textStyle: AppTypography.buttonText,
        ),
      );

  static TextButtonThemeData get _textButtonTheme => TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: AppSpacing.buttonPadding,
          textStyle: AppTypography.buttonText,
        ),
      );

  // Card Themes
  static CardTheme get _cardTheme => CardTheme(
        color: AppColors.surface,
        elevation: AppElevation.sm,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.radiusMD,
        ),
        margin: AppSpacing.paddingVerticalSM,
      );

  static CardTheme get _darkCardTheme => CardTheme(
        color: AppColors.darkSurface,
        elevation: AppElevation.sm,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.radiusMD,
        ),
        margin: AppSpacing.paddingVerticalSM,
      );

  // Input Decoration Themes
  static InputDecorationTheme get _inputDecorationTheme => InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: AppRadius.radiusMD,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.radiusMD,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.radiusMD,
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.radiusMD,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: AppSpacing.paddingMD,
        labelStyle: AppTypography.bodyMedium,
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textTertiary,
        ),
      );

  static InputDecorationTheme get _darkInputDecorationTheme =>
      InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        border: OutlineInputBorder(
          borderRadius: AppRadius.radiusMD,
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.radiusMD,
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.radiusMD,
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.radiusMD,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: AppSpacing.paddingMD,
        labelStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.darkTextSecondary,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.darkTextSecondary,
        ),
      );

  // Chip Themes
  static ChipThemeData get _chipTheme => ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        selectedColor: AppColors.primary,
        labelStyle: AppTypography.labelMedium,
        padding: AppSpacing.paddingHorizontalSM,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.radiusSM,
        ),
      );

  static ChipThemeData get _darkChipTheme => ChipThemeData(
        backgroundColor: AppColors.darkSurfaceVariant,
        selectedColor: AppColors.primaryLight,
        labelStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.darkTextPrimary,
        ),
        padding: AppSpacing.paddingHorizontalSM,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.radiusSM,
        ),
      );

  // Bottom Navigation Bar Themes
  static BottomNavigationBarThemeData get _bottomNavigationBarTheme =>
      BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: AppElevation.md,
      );

  static BottomNavigationBarThemeData get _darkBottomNavigationBarTheme =>
      BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.primaryLight,
        unselectedItemColor: AppColors.darkTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: AppElevation.md,
      );

  // Floating Action Button Theme
  static FloatingActionButtonThemeData get _floatingActionButtonTheme =>
      FloatingActionButtonThemeData(
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.textOnSecondary,
        elevation: AppElevation.md,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.radiusLG,
        ),
      );

  // Divider Themes
  static DividerThemeData get _dividerTheme => const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      );

  static DividerThemeData get _darkDividerTheme => const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
        space: 1,
      );

  // Convenience getters for backward compatibility and easy access
  static Color get primaryColor => AppColors.primary;
  static Color get successColor => AppColors.success;
  static Color get textSecondary => AppColors.textSecondary;
  static TextStyle get headlineLarge => AppTypography.headlineLarge;
  static TextStyle get headlineMedium => AppTypography.headlineMedium;
  static TextStyle get bodyLarge => AppTypography.bodyLarge;
  static TextStyle get bodyMedium => AppTypography.bodyMedium;
}
