import 'package:flutter/material.dart';
import 'package:lumina/core/theme/theme_colors.dart';

/// Кастомная шапка экрана в стиле приложения: круглая кнопка «назад»,
/// заголовок по центру и действия справа.
class AppAppBar extends StatelessWidget {
  final String title;
  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final Widget? leading;

  const AppAppBar({
    super.key,
    required this.title,
    this.showBack = true,
    this.onBack,
    this.actions = const [],
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    Widget backButton = Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: tc.shadow(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Icon(Icons.arrow_back, size: 22, color: tc.text),
    );

    if (onBack != null || showBack) {
      backButton = GestureDetector(
        onTap: onBack ?? () => Navigator.maybePop(context),
        child: backButton,
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        leading ?? (showBack ? backButton : const SizedBox(width: 38)),
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: tc.text),
        ),
        actions.isNotEmpty
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < actions.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    actions[i],
                  ],
                ],
              )
            : const SizedBox(width: 38),
      ],
    );
  }
}

/// Круглая кнопка-действие для шапки (обновление, настройки и т.п.).
class AppBarActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;

  const AppBarActionButton({
    super.key,
    required this.icon,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: tc.card,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: tc.shadow(0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Icon(icon, size: 20, color: color ?? tc.textHint),
      ),
    );
  }
}
