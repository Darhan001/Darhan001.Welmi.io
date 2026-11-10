import 'package:flutter/material.dart';
import 'app_palette.dart';
import 'app_tokens.dart';
import 'app_typography.dart';

/// Сборка [ThemeData] из палитры и токенов.
///
/// Цвета — в [AppPalette], формы и размеры — в [AppTokens]. Здесь они
/// превращаются в [ColorScheme] и стили стандартных кнопок, диалогов и
/// листов, поэтому экраны не должны дублировать эти стили у себя.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => build(AppPalette.light);

  static ThemeData get darkTheme => build(AppPalette.dark);

  static ThemeData build(
    AppPalette p, {
    AppTokens tokens = AppTokens.standard,
    TextTheme? textTheme,
  }) {
    final brightness = p.isDark ? Brightness.dark : Brightness.light;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: p.green,
          brightness: brightness,
        ).copyWith(
          primary: p.primary,
          onPrimary: p.textOnPrimary,
          secondary: p.isDark ? p.textSecondary : p.green,
          surface: p.surface,
          onSurface: p.text,
          onSurfaceVariant: p.textSecondary,
          error: p.error,
          outline: p.border,
          outlineVariant: p.divider,
        );
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(tokens.buttonRadius),
    );
    final buttonText = TextStyle(
      fontSize: tokens.buttonMedium.fontSize,
      fontWeight: tokens.buttonFontWeight,
    );

    return ThemeData(
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
      primaryColor: p.primary,
      dividerColor: p.divider,
      textTheme: textTheme ?? AppTypography.build(brightness),
      extensions: [p, tokens],
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.textOnPrimary,
          disabledBackgroundColor: p.disabled.withValues(alpha: 0.15),
          disabledForegroundColor: p.disabled,
          elevation: 0,
          shape: buttonShape,
          padding: tokens.buttonMedium.padding,
          textStyle: buttonText,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.textOnPrimary,
          shape: buttonShape,
          padding: tokens.buttonMedium.padding,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.text,
          side: BorderSide(color: p.border),
          shape: buttonShape,
          padding: tokens.buttonMedium.padding,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.primary,
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      dialogTheme: DialogThemeData(
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.dialogRadius),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(tokens.sheetRadius),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(color: p.divider),
    );
  }
}
