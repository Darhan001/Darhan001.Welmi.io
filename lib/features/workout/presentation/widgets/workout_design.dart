import 'package:flutter/material.dart';

/// Тёмное оформление экранов тренировок: лаймовый акцент на почти чёрном.
abstract final class WorkoutDesign {
  static const Color bg = Color(0xFF0F0F0F);
  static const Color card = Color(0xFF1A1A1A);
  static const Color cardBorder = Color(0xFF2A2A2A);
  static const Color lime = Color(0xFFD4FF44);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF8A8A8A);
  static const Color textMuted = Color(0xFF555555);
  static const double radiusLg = 28;
  static const double radiusMd = 20;
  static const double radiusSm = 14;

  // Экран выполнения упражнения: чёрный фон и более кислотный акцент.
  static const Color exerciseBg = Color(0xFF000000);
  static const Color accent = Color(0xFFC6FF00);
  static const Color sheet = Color(0xFF121212);
  static const Color dialog = Color(0xFF1C1C1C);
}

/// Иконка и цвет, которыми обозначена мышечная группа.
({IconData icon, Color color}) muscleVisuals(String muscle) {
  final m = muscle.toLowerCase();
  if (m.contains('груд')) {
    return (
      icon: Icons.accessibility_new_rounded,
      color: const Color(0xFFEF5350),
    );
  }
  if (m.contains('спин')) {
    return (
      icon: Icons.airline_seat_recline_normal_rounded,
      color: const Color(0xFF42A5F5),
    );
  }
  if (m.contains('ног') || m.contains('ягод')) {
    return (icon: Icons.directions_run_rounded, color: const Color(0xFFAB47BC));
  }
  return (icon: Icons.fitness_center_rounded, color: WorkoutDesign.lime);
}
