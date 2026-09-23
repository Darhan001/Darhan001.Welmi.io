import 'package:flutter/material.dart';

/// Полные дизайн-токены цветов (light + dark).
///
/// Старые имена сохранены для обратной совместимости,
/// новые экраны используют общие токены: [textPrimary], [border],
/// [success], [warning], [error], [disabled] и их dark-версии.
class AppColors {
  // ─────────────────────────────────────────────
  // 🎨 BRAND
  // ─────────────────────────────────────────────
  static const Color brand = Color(0xFF75A47F);
  static const Color brandDark = Color(0xFF4A8C5C);
  static const Color brandLight = Color(0xFFE8F3E5);

  // ─────────────────────────────────────────────
  // ☀️ LIGHT THEME
  // ─────────────────────────────────────────────
  static const Color background = Color(0xFFF9F7F2);
  static const Color surface = Color(0xFFF0F0F0);
  static const Color card = Colors.white;

  static const Color primary = Colors.black;
  static const Color secondary = Color(0xFF9E9E9E);

  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Colors.black54;
  static const Color textHint = Colors.black26;

  static const Color border = Colors.black12;
  static const Color divider = Colors.black12;

  static const Color success = Color(0xFF4A8C5C);
  static const Color warning = Color(0xFFE6A23C);
  static const Color error = Color(0xFFD9534F);
  static const Color disabled = Color(0xFFBDBDBD);

  // ─────────────────────────────────────────────
  // 🌙 DARK THEME
  // ─────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF2C2C2C);

  static const Color darkPrimary = Color(0xFF8BC98E);
  static const Color darkSecondary = Color(0xFF9E9E9E);

  static const Color darkText = Color(0xFFE8E8E8);
  static const Color darkTextSecondary = Color(0xFF9E9E9E);
  static const Color darkTextHint = Color(0xFF6E6E6E);

  static const Color darkBorder = Color(0xFF3A3A3A);
  static const Color darkDivider = Color(0xFF3A3A3A);

  static const Color darkSuccess = Color(0xFF8BC98E);
  static const Color darkWarning = Color(0xFFE6A23C);
  static const Color darkError = Color(0xFFEF6B6B);
  static const Color darkDisabled = Color(0xFF5A5A5A);

  // ─────────────────────────────────────────────
  // 🔁 Обратная совместимость (старые имена)
  // ─────────────────────────────────────────────
  static const Color accentGreen = brandLight;
  static const Color iconGreen = brand;
  static const Color iconGreenDark = brandDark;
  static const Color cardBg = card;
  static const Color progressActive = primary;
  static const Color progressInactive = border;
}
