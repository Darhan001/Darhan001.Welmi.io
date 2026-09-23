import 'package:flutter/material.dart';
import 'package:lumina/core/theme/theme_colors.dart';

/// Пункт нижней навигации.
class AppNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const AppNavItem({
    required this.icon,
    required this.label,
    IconData? activeIcon,
  }) : activeIcon = activeIcon ?? icon;
}

/// Нижняя навигация в стиле приложения (тема-aware).
class AppBottomNav extends StatelessWidget {
  final List<AppNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    return Container(
      decoration: BoxDecoration(
        color: tc.card,
        boxShadow: [
          BoxShadow(
            color: tc.shadow(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final selected = i == currentIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: selected
                                ? (tc.isDark
                                    ? tc.primary.withValues(alpha: 0.18)
                                    : tc.successBg)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            selected ? item.activeIcon : item.icon,
                            size: 22,
                            color: selected
                                ? (tc.isDark ? tc.success : tc.greenDark)
                                : tc.textHint,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight:
                                selected ? FontWeight.w800 : FontWeight.w600,
                            color: selected
                                ? (tc.isDark ? tc.success : tc.greenDark)
                                : tc.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
