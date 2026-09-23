import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.brand,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      textTheme: AppTypography.build(Brightness.light),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      primaryColor: AppColors.iconGreenDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.iconGreenDark,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkText,
        secondary: AppColors.darkSecondary,
        error: AppColors.darkError,
      ),
      textTheme: AppTypography.build(Brightness.dark),
    );
  }
}
