import 'package:flutter/material.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/app_card.dart';

/// Акцентные цвета разделов «Прогресса» (вес, замеры, % жира).
/// Это цвета графиков, а не темы, поэтому одинаковы в светлой и тёмной.
abstract final class ProgressColors {
  static const weight = Color(0xFF75A47F);
  static const measurements = Color(0xFF4A90E2);
  static const bodyFat = Color(0xFFAB47BC);
}

/// Таблетка-переключатель (вкладка, интервал, замер).
class ProgressPill extends StatelessWidget {
  const ProgressPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.selectedColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
    this.fontSize = 12,
    this.radius = 14,
    this.outlined = true,
    this.background,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? selectedColor;
  final EdgeInsets padding;
  final double fontSize;
  final double radius;

  /// Рамка у невыбранной таблетки.
  final bool outlined;

  /// Фон невыбранной таблетки (по умолчанию — цвет карточки).
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
        padding: padding,
        decoration: BoxDecoration(
          color: selected
              ? (selectedColor ?? tc.primary)
              : (background ?? tc.card),
          borderRadius: BorderRadius.circular(radius),
          border: selected || !outlined ? null : Border.all(color: tc.divider),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: selected ? tc.textOnPrimary : tc.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Пустое состояние раздела: иконка, заголовок, пояснение.
class ProgressEmptyCard extends StatelessWidget {
  const ProgressEmptyCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return AppCard(
      radius: 24,
      shadow: false,
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(icon, size: 48, color: tc.textHint),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: tc.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: tc.textSecondary),
          ),
          if (action != null) ...[const SizedBox(height: 24), action!],
        ],
      ),
    );
  }
}

/// Заголовок карточки с подписью справа.
class ProgressCardHeader extends StatelessWidget {
  const ProgressCardHeader({
    super.key,
    required this.title,
    this.trailing,
    this.fontSize = 15,
  });

  final String title;
  final Widget? trailing;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: fontSize,
              color: tc.text,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}
