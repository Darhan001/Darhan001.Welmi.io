import 'package:flutter/material.dart';
import 'package:lumina/core/theme/theme_colors.dart';

/// Выбираемый чип (тема-aware). Используется для вкладок-фильтров, методов и т.п.
class AppChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;

  const AppChip({
    super.key,
    required this.label,
    this.icon,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? tc.isDark
                  ? tc.primary
                  : tc.successBg
              : tc.card,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected
                ? tc.isDark
                    ? tc.success
                    : tc.green
                : tc.border.withValues(alpha: 0.5),
          ),
          boxShadow: selected
              ? [BoxShadow(color: tc.shadow(0.05), blurRadius: 8, offset: const Offset(0, 3))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 15,
                color: selected ? (tc.isDark ? tc.success : tc.greenDark) : tc.textSecondary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? (tc.isDark ? tc.success : tc.greenDark) : tc.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Маленький бейдж-счётчик (например, «3 л за неделю»).
class AppBadge extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color? color;
  final Color? backgroundColor;

  const AppBadge({
    super.key,
    required this.text,
    this.icon,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final fg = color ?? tc.greenDark;
    final bg = backgroundColor ?? tc.successBg;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
