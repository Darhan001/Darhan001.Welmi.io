import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Единая типографика приложения.
///
/// Используйте `AppTypography.build(brightness)` в AppTheme, а в виджетах —
/// стили из `Theme.of(context).textTheme` (например `textTheme.headlineMedium`)
/// либо `AppTypography.body(context, weight: FontWeight.w700)`.
class AppTypography {
  AppTypography._();

  /// Полная TextTheme для светлой/тёмной темы.
  static TextTheme build(Brightness brightness) {
    final bool dark = brightness == Brightness.dark;
    final Color text = dark ? AppColors.darkText : AppColors.textPrimary;
    final Color secondary =
        dark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final Color hint = dark ? AppColors.darkTextHint : AppColors.textHint;

    return GoogleFonts.notoSerifTextTheme().copyWith(
      // ── Display (крупные заголовки) ──
      displayLarge: GoogleFonts.notoSerif(
        fontSize: 32,
        fontWeight: FontWeight.w900,
        height: 1.2,
        color: text,
      ),
      displayMedium: GoogleFonts.notoSerif(
        fontSize: 28,
        fontWeight: FontWeight.w900,
        height: 1.25,
        color: text,
      ),
      displaySmall: GoogleFonts.notoSerif(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        height: 1.3,
        color: text,
      ),

      // ── H1–H3 ──
      headlineLarge: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        height: 1.3,
        color: text,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: text,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        height: 1.35,
        color: text,
      ),

      // ── Titles ──
      titleLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        height: 1.4,
        color: text,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        height: 1.4,
        color: text,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        height: 1.4,
        color: secondary,
      ),

      // ── Body / Body Small ──
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        height: 1.5,
        color: text,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 15,
        height: 1.5,
        color: text,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 13,
        height: 1.45,
        color: secondary,
      ),

      // ── Button / Label ──
      labelLarge: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: text,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: text,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: hint,
      ),
    );
  }

  /// Основной текст с возможностью переопределить цвет/вес.
  static TextStyle body(
    BuildContext context, {
    Color? color,
    FontWeight? weight,
    double? size,
  }) {
    return Theme.of(context)
        .textTheme
        .bodyMedium!
        .copyWith(color: color, fontWeight: weight, fontSize: size);
  }

  /// Заголовок уровня H1.
  static TextStyle h1(
    BuildContext context, {
    Color? color,
  }) {
    return Theme.of(context)
        .textTheme
        .headlineLarge!
        .copyWith(color: color);
  }

  /// Заголовок уровня H2.
  static TextStyle h2(
    BuildContext context, {
    Color? color,
  }) {
    return Theme.of(context)
        .textTheme
        .headlineMedium!
        .copyWith(color: color);
  }

  /// Заголовок уровня H3.
  static TextStyle h3(
    BuildContext context, {
    Color? color,
  }) {
    return Theme.of(context)
        .textTheme
        .headlineSmall!
        .copyWith(color: color);
  }

  /// Крупный Display-заголовок.
  static TextStyle display(
    BuildContext context, {
    Color? color,
  }) {
    return Theme.of(context)
        .textTheme
        .displayMedium!
        .copyWith(color: color);
  }

  /// Подпись (caption).
  static TextStyle caption(
    BuildContext context, {
    Color? color,
  }) {
    return Theme.of(context)
        .textTheme
        .bodySmall!
        .copyWith(color: color);
  }
}
