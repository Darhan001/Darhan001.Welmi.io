import 'package:flutter/material.dart';
import 'package:lumina/core/theme/theme_colors.dart';

/// Выбираемая плашка в шторке цели (тип цели, скорость).
class GoalChoiceChip extends StatelessWidget {
  const GoalChoiceChip({
    super.key,
    required this.selected,
    required this.onTap,
    required this.child,
    this.padding = const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
    this.radius = 16,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// Цвет текста выбранной плашки.
  static Color accent(ThemeColors tc) => tc.isDark ? tc.success : tc.greenDark;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 200),
          padding: padding,
          decoration: BoxDecoration(
            color: selected ? tc.successBg : tc.text.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: selected ? tc.greenDark : tc.text.withValues(alpha: 0.06),
              width: selected ? 2 : 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
