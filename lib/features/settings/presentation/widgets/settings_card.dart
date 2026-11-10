import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Цвета экрана настроек: настроение темы задаётся флагом [isDark].
abstract final class SettingsDesign {
  static const Color green = Color(0xFF75A47F);
  static const Color softGreen = Color(0xFFE8F3E5);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color backgroundLight = Color(0xFFF9F7F2);

  static Color background(bool isDark) =>
      isDark ? backgroundDark : backgroundLight;

  /// Фон карточки настроек.
  static Color card(bool isDark) =>
      isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white;

  /// Основной цвет текста.
  static Color text(bool isDark) => isDark ? Colors.white : Colors.black;

  /// Второстепенный текст и подписи.
  static Color textMuted(bool isDark) =>
      isDark ? Colors.white38 : Colors.black38;

  /// Стрелки и разделители.
  static Color hairline(bool isDark) =>
      isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black12;
}

/// Белая (в тёмной теме — полупрозрачная) карточка настроек с тенью.
class SettingsCard extends StatelessWidget {
  const SettingsCard({
    super.key,
    required this.isDark,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final bool isDark;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: SettingsDesign.card(isDark),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Подпись раздела: «БЕЗОПАСНОСТЬ», «ВНЕШНИЙ ВИД» и т. п.
class SettingsSectionTitle extends StatelessWidget {
  const SettingsSectionTitle({
    super.key,
    required this.title,
    required this.isDark,
  });

  final String title;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.inter(
        fontWeight: FontWeight.w900,
        fontSize: 12,
        color: isDark ? Colors.white38 : Colors.black.withValues(alpha: 0.35),
        letterSpacing: 1.0,
      ),
    );
  }
}

/// Иконка в зелёном квадрате слева от заголовка карточки.
class SettingsTileIcon extends StatelessWidget {
  const SettingsTileIcon({super.key, required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: SettingsDesign.softGreen,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, size: 22, color: SettingsDesign.green),
    );
  }
}
