import 'package:flutter/material.dart';
import 'package:lumina/core/theme/app_tokens.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/press_scale.dart';

/// Стандартная карточка приложения (тема-aware: светлая/тёмная).
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? radius;
  final VoidCallback? onTap;
  final Color? color;
  final bool bordered;
  final bool shadow;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.radius,
    this.onTap,
    this.color,
    this.bordered = false,
    this.shadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final tokens = AppTokens.of(context);
    final radius = this.radius ?? tokens.cardRadius;

    final decoration = BoxDecoration(
      color: color ?? tc.card,
      borderRadius: BorderRadius.circular(radius),
      // В тёмной теме тень почти не видна — карточку от фона отделяет
      // тонкая рамка.
      border: bordered
          ? Border.all(color: tc.border.withValues(alpha: 0.5))
          : (tc.isDark
                ? Border.all(color: tc.border.withValues(alpha: 0.35))
                : null),
      boxShadow: shadow
          ? [
              BoxShadow(
                color: tc.shadow(0.04),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ]
          : null,
    );

    final content = Padding(
      padding: padding ?? tokens.cardPadding,
      child: child,
    );

    if (onTap == null) {
      return Container(margin: margin, decoration: decoration, child: content);
    }

    return PressScale(
      scale: 0.98,
      child: Container(
        margin: margin,
        decoration: decoration,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(radius),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(radius),
            child: content,
          ),
        ),
      ),
    );
  }
}
