import 'package:flutter/material.dart';

/// Цвета экрана AI-чата.
///
/// Чат намеренно всегда тёмный (премиальный стиль с лаймовым акцентом) и не
/// зависит от темы приложения, поэтому цвета заданы здесь, а не берутся
/// из `AppPalette`.
abstract final class ChatDesign {
  static const Color bg = Color(0xFF0F0F0F);
  static const Color card = Color(0xFF1A1A1A);
  static const Color cardGradientEnd = Color(0xFF222222);
  static const Color cardBorder = Color(0xFF2A2A2A);
  static const Color lime = Color(0xFFD4FF44);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF8A8A8A);
  static const Color textMuted = Color(0xFF555555);
  static const Color recording = Color(0xFFFF5252);
  static const double radiusLg = 28;

  /// Фирменный зелёный градиент аватара Welmi AI.
  static const LinearGradient avatarGradient = LinearGradient(
    colors: [Color(0xFF75A47F), Color(0xFF5A8A64)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Маленький значок AI слева от ответа и индикатора набора.
class ChatAiBadge extends StatelessWidget {
  const ChatAiBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      margin: const EdgeInsets.only(right: 8, bottom: 4),
      decoration: BoxDecoration(
        gradient: ChatDesign.avatarGradient,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
    );
  }
}
