import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// The app ships one theme. A picker's phone is used in a stockroom under mixed
/// light for a whole shift, so the dark ground is a deliberate choice rather than
/// a preference to toggle - and it keeps the amber "still to pick" accent the
/// brightest thing on the screen.
class AppTheme {
  AppTheme._();

  static const SystemUiOverlayStyle overlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: AppColors.ground,
    systemNavigationBarIconBrightness: Brightness.light,
  );

  static ThemeData get theme {
    final ColorScheme scheme = const ColorScheme.dark().copyWith(
      primary: AppColors.signal,
      onPrimary: AppColors.onSignal,
      secondary: AppColors.done,
      surface: AppColors.deck,
      onSurface: AppColors.chalk,
      error: AppColors.alert,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.ground,
      canvasColor: AppColors.ground,
      splashColor: AppColors.signal.withValues(alpha: 0.08),
      highlightColor: AppColors.signal.withValues(alpha: 0.05),
      dividerTheme: const DividerThemeData(
        color: AppColors.rule,
        thickness: 1,
        space: 1,
      ),
      textTheme: TextTheme(
        titleLarge: AppTypography.title,
        bodyLarge: AppTypography.body,
        bodyMedium: AppTypography.body,
        labelLarge: AppTypography.label,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.ground,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.chalk,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.title,
        systemOverlayStyle: overlayStyle,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.deckHigh,
        contentTextStyle: AppTypography.body,
        actionTextColor: AppColors.signal,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.signal,
        linearTrackColor: AppColors.rule,
        circularTrackColor: Colors.transparent,
      ),
    );
  }
}
