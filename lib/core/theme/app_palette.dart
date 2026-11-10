import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Семантическая палитра приложения — единый источник цветов экранов.
///
/// Подключается к [ThemeData.extensions] в `AppTheme`, поэтому смена значений
/// здесь (или переключение светлой/тёмной темы) меняет все экраны, которые
/// берут цвета через `ThemeColors.of(context)` или `AppPalette.of(context)`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.isDark,
    required this.background,
    required this.card,
    required this.surface,
    required this.text,
    required this.textSecondary,
    required this.textHint,
    required this.textOnPrimary,
    required this.primary,
    required this.divider,
    required this.border,
    required this.inactive,
    required this.green,
    required this.greenDark,
    required this.success,
    required this.successBg,
    required this.warning,
    required this.error,
    required this.errorBg,
    required this.disabled,
    required this.shadowStrength,
  });

  final bool isDark;

  final Color background;
  final Color card;
  final Color surface;

  final Color text;
  final Color textSecondary;
  final Color textHint;
  final Color textOnPrimary;

  /// Основной цвет действий: заливка primary-кнопок, активные элементы.
  final Color primary;
  final Color divider;
  final Color border;
  final Color inactive;

  final Color green;
  final Color greenDark;

  final Color success;
  final Color successBg;
  final Color warning;
  final Color error;
  final Color errorBg;
  final Color disabled;

  /// Множитель прозрачности теней (в тёмной теме тени мягче).
  final double shadowStrength;

  static const light = AppPalette(
    isDark: false,
    background: AppColors.background,
    card: AppColors.card,
    surface: AppColors.surface,
    text: AppColors.textPrimary,
    textSecondary: Colors.black38,
    textHint: AppColors.textHint,
    textOnPrimary: Colors.white,
    primary: AppColors.primary,
    divider: AppColors.divider,
    border: Colors.black,
    inactive: AppColors.textHint,
    green: AppColors.brand,
    greenDark: AppColors.brandDark,
    success: AppColors.success,
    successBg: AppColors.brandLight,
    warning: AppColors.warning,
    error: AppColors.error,
    errorBg: Color(0xFFFDECEA),
    disabled: AppColors.disabled,
    shadowStrength: 1,
  );

  static const dark = AppPalette(
    isDark: true,
    background: AppColors.darkBackground,
    card: AppColors.darkCard,
    surface: AppColors.darkSurface,
    text: AppColors.darkText,
    textSecondary: AppColors.darkTextSecondary,
    textHint: AppColors.darkTextHint,
    textOnPrimary: Colors.white,
    primary: AppColors.brandDark,
    divider: AppColors.darkDivider,
    border: AppColors.darkBorder,
    inactive: AppColors.darkTextHint,
    green: AppColors.brand,
    greenDark: AppColors.brandDark,
    success: AppColors.darkSuccess,
    successBg: AppColors.darkSurface,
    warning: AppColors.darkWarning,
    error: AppColors.darkError,
    errorBg: Color(0xFF3A2A2A),
    disabled: AppColors.darkDisabled,
    shadowStrength: 0.5,
  );

  /// Палитра текущей темы. Без расширения в теме (например, в тестах с
  /// голым `MaterialApp`) выбирается по яркости темы.
  static AppPalette of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<AppPalette>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  Color shadow(double opacity) =>
      Colors.black.withValues(alpha: opacity * shadowStrength);

  @override
  AppPalette copyWith({
    Color? background,
    Color? card,
    Color? surface,
    Color? text,
    Color? textSecondary,
    Color? textHint,
    Color? textOnPrimary,
    Color? primary,
    Color? divider,
    Color? border,
    Color? inactive,
    Color? green,
    Color? greenDark,
    Color? success,
    Color? successBg,
    Color? warning,
    Color? error,
    Color? errorBg,
    Color? disabled,
    double? shadowStrength,
  }) {
    return AppPalette(
      isDark: isDark,
      background: background ?? this.background,
      card: card ?? this.card,
      surface: surface ?? this.surface,
      text: text ?? this.text,
      textSecondary: textSecondary ?? this.textSecondary,
      textHint: textHint ?? this.textHint,
      textOnPrimary: textOnPrimary ?? this.textOnPrimary,
      primary: primary ?? this.primary,
      divider: divider ?? this.divider,
      border: border ?? this.border,
      inactive: inactive ?? this.inactive,
      green: green ?? this.green,
      greenDark: greenDark ?? this.greenDark,
      success: success ?? this.success,
      successBg: successBg ?? this.successBg,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      errorBg: errorBg ?? this.errorBg,
      disabled: disabled ?? this.disabled,
      shadowStrength: shadowStrength ?? this.shadowStrength,
    );
  }

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      isDark: t < 0.5 ? isDark : other.isDark,
      background: c(background, other.background),
      card: c(card, other.card),
      surface: c(surface, other.surface),
      text: c(text, other.text),
      textSecondary: c(textSecondary, other.textSecondary),
      textHint: c(textHint, other.textHint),
      textOnPrimary: c(textOnPrimary, other.textOnPrimary),
      primary: c(primary, other.primary),
      divider: c(divider, other.divider),
      border: c(border, other.border),
      inactive: c(inactive, other.inactive),
      green: c(green, other.green),
      greenDark: c(greenDark, other.greenDark),
      success: c(success, other.success),
      successBg: c(successBg, other.successBg),
      warning: c(warning, other.warning),
      error: c(error, other.error),
      errorBg: c(errorBg, other.errorBg),
      disabled: c(disabled, other.disabled),
      shadowStrength:
          shadowStrength + (other.shadowStrength - shadowStrength) * t,
    );
  }
}
