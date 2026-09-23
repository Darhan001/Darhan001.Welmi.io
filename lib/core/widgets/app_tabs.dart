import 'package:flutter/material.dart';
import 'package:lumina/core/theme/theme_colors.dart';

/// Сегментированный переключатель (горизонтальная лента вкладок).
class AppTabs<T> extends StatelessWidget {
  final List<(T value, String label)> items;
  final T selected;
  final ValueChanged<T> onChanged;
  final bool scrollable;

  const AppTabs({
    super.key,
    required this.items,
    required this.selected,
    required this.onChanged,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    final tabs = items
        .map((item) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onChanged(item.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: item.$1 == selected
                        ? tc.primary
                        : tc.card,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: item.$1 == selected
                          ? Colors.transparent
                          : tc.border.withValues(alpha: 0.5),
                    ),
                    boxShadow: item.$1 == selected
                        ? [BoxShadow(color: tc.shadow(0.08), blurRadius: 8, offset: const Offset(0, 3))]
                        : null,
                  ),
                  child: Text(
                    item.$2,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: item.$1 == selected ? tc.textOnPrimary : tc.textSecondary,
                    ),
                  ),
                ),
              ),
            ))
        .toList();

    if (scrollable) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(children: tabs),
      );
    }

    return Row(children: tabs);
  }
}
