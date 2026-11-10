import 'package:flutter/material.dart';
import 'app_palette.dart';

/// Короткий доступ к цветам текущей темы.
///
/// Значения берутся из [AppPalette], подключённой к теме, поэтому правка
/// палитры в одном месте меняет все экраны.
///
/// Использование:
///   final tc = ThemeColors.of(context);
///   Container(color: tc.card, child: Text('...', style: TextStyle(color: tc.text)));
class ThemeColors {
  const ThemeColors._(this.palette);

  /// Цвета без контекста (тесты, код вне дерева виджетов).
  ThemeColors({required bool isDark})
    : palette = isDark ? AppPalette.dark : AppPalette.light;

  factory ThemeColors.of(BuildContext context) =>
      ThemeColors._(AppPalette.of(context));

  final AppPalette palette;

  bool get isDark => palette.isDark;

  // Backgrounds
  Color get background => palette.background;
  Color get card => palette.card;
  Color get surface => palette.surface;

  // Text
  Color get text => palette.text;
  Color get textSecondary => palette.textSecondary;
  Color get textHint => palette.textHint;
  Color get textOnPrimary => palette.textOnPrimary;

  // UI elements
  Color get primary => palette.primary;
  Color get divider => palette.divider;
  Color get border => palette.border;
  Color get inactive => palette.inactive;

  // Brand
  Color get green => palette.green;
  Color get greenDark => palette.greenDark;

  // Semantic (success / warning / error / disabled)
  Color get success => palette.success;
  Color get successBg => palette.successBg;
  Color get warning => palette.warning;
  Color get error => palette.error;
  Color get errorBg => palette.errorBg;
  Color get disabled => palette.disabled;

  // Shadows — lighter in dark mode for subtlety
  Color shadow(double opacity) => palette.shadow(opacity);
}
