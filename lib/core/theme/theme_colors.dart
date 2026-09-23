import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'theme_provider.dart';

/// Helper для получения цветов, адаптированных под текущую тему (светлая/тёмная)
///
/// Использование:
///   final tc = ThemeColors.of(context);
///   Container(color: tc.card, child: Text('...', style: TextStyle(color: tc.text)));
class ThemeColors {
  final bool isDark;

  const ThemeColors({required this.isDark});

  // Backgrounds
  Color get background => isDark ? AppColors.darkBackground : const Color(0xFFF9F7F2);
  Color get card => isDark ? AppColors.darkCard : Colors.white;
  Color get surface => isDark ? AppColors.darkSurface : const Color(0xFFF0F0F0);

  // Text
  Color get text => isDark ? AppColors.darkText : Colors.black87;
  Color get textSecondary => isDark ? AppColors.darkTextSecondary : Colors.black38;
  Color get textHint => isDark ? AppColors.darkTextHint : Colors.black26;
  Color get textOnPrimary => Colors.white;

  // UI elements
  Color get primary => isDark ? AppColors.iconGreenDark : Colors.black;
  Color get divider => isDark ? AppColors.darkDivider : Colors.black12;
  Color get border => isDark ? AppColors.darkBorder : Colors.black;
  Color get inactive => isDark ? AppColors.darkTextHint : Colors.black26;

  // Brand
  Color get green => AppColors.iconGreen;
  Color get greenDark => AppColors.iconGreenDark;

  // Semantic (success / warning / error / disabled)
  Color get success => isDark ? AppColors.darkSuccess : AppColors.success;
  Color get successBg =>
      isDark ? AppColors.darkSurface : AppColors.brandLight;
  Color get warning => isDark ? AppColors.darkWarning : AppColors.warning;
  Color get error => isDark ? AppColors.darkError : AppColors.error;
  Color get errorBg => isDark ? const Color(0xFF3A2A2A) : const Color(0xFFFDECEA);
  Color get disabled => isDark ? AppColors.darkDisabled : AppColors.disabled;

  // Shadows — lighter in dark mode for subtlety
  Color shadow(double opacity) =>
      Colors.black.withValues(alpha: isDark ? opacity * 0.5 : opacity);

  /// Получить ThemeColors из BuildContext
  factory ThemeColors.of(BuildContext context) {
    final isDark = ThemeProvider.isDark(context);
    return ThemeColors(isDark: isDark);
  }
}
