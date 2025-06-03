import 'package:flutter/material.dart';

/// App color palette optimized for warehouse/industrial environments
/// with good contrast and accessibility
class AppColors {
  AppColors._();

  // Primary Colors - Professional blue palette
  static const Color primary = Color(0xFF1565C0); // Deep blue
  static const Color primaryLight = Color(0xFF5E92F3);
  static const Color primaryDark = Color(0xFF003C8F);
  
  // Secondary Colors - Complementary orange for actions
  static const Color secondary = Color(0xFFFF8F00); // Amber orange
  static const Color secondaryLight = Color(0xFFFFBF47);
  static const Color secondaryDark = Color(0xFFC56000);
  
  // Status Colors
  static const Color success = Color(0xFF2E7D32); // Green for completed picks
  static const Color successLight = Color(0xFF60AD5E);
  static const Color warning = Color(0xFFED6C02); // Orange for pending
  static const Color error = Color(0xFFD32F2F); // Red for errors
  static const Color info = Color(0xFF0288D1); // Light blue for info
  
  // Neutral Colors
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F3F4);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF5F6368);
  static const Color textTertiary = Color(0xFF9AA0A6);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSecondary = Color(0xFF000000);
  
  // Border Colors
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderLight = Color(0xFFF0F0F0);
  static const Color borderDark = Color(0xFFBDBDBD);
  
  // Shadow Colors
  static const Color shadow = Color(0x1A000000);
  static const Color shadowLight = Color(0x0D000000);
  
  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurfaceVariant = Color(0xFF2C2C2C);
  static const Color darkTextPrimary = Color(0xFFE0E0E0);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);
  static const Color darkBorder = Color(0xFF404040);
}
