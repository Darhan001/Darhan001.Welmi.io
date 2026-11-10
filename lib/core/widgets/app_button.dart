import 'package:flutter/material.dart';
import 'package:lumina/core/theme/app_palette.dart';
import 'package:lumina/core/theme/app_tokens.dart';

enum AppButtonVariant { primary, secondary, outline, text }

enum AppButtonSize { sm, md, lg }

/// Стандартная кнопка приложения.
///
/// Цвета берутся из [AppPalette], размеры и скругление — из [AppTokens],
/// поэтому изменение темы меняет все кнопки одного варианта сразу.
///
/// Варианты: [AppButtonVariant.primary] (сплошная), [AppButtonVariant.secondary]
/// (брендовая подложка), [AppButtonVariant.outline] (рамка), [AppButtonVariant.text].
class AppButton extends StatelessWidget {
  final String text;
  final IconData? icon;

  /// Иконка после текста (например, стрелка «Далее»).
  final IconData? trailingIcon;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool loading;
  final bool fullWidth;

  const AppButton({
    super.key,
    required this.text,
    this.icon,
    this.trailingIcon,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.loading = false,
    this.fullWidth = true,
  });

  /// Цвета варианта: фон, текст, рамка.
  static (Color, Color, Color?) colorsFor(
    AppButtonVariant variant,
    AppPalette p,
  ) {
    return switch (variant) {
      AppButtonVariant.primary => (p.primary, p.textOnPrimary, null),
      AppButtonVariant.secondary => (
        p.isDark ? p.primary.withValues(alpha: 0.15) : p.successBg,
        p.isDark ? p.success : p.greenDark,
        null,
      ),
      AppButtonVariant.outline => (Colors.transparent, p.text, p.border),
      AppButtonVariant.text => (Colors.transparent, p.text, null),
    };
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final tokens = AppTokens.of(context);
    final enabled = onPressed != null && !loading;
    final (bg, fg, borderColor) = colorsFor(variant, p);
    final spec = switch (size) {
      AppButtonSize.sm => tokens.buttonSmall,
      AppButtonSize.md => tokens.buttonMedium,
      AppButtonSize.lg => tokens.buttonLarge,
    };
    final fontSize = spec.fontSize;
    final labelColor = enabled
        ? fg
        : (variant == AppButtonVariant.primary
              ? fg.withValues(alpha: 0.6)
              : p.disabled);

    final content = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          SizedBox(
            width: fontSize + 2,
            height: fontSize + 2,
            child: CircularProgressIndicator(strokeWidth: 2.2, color: fg),
          )
        else if (icon != null)
          Icon(icon, size: fontSize + 4, color: fg),
        if ((loading || icon != null) && text.isNotEmpty)
          const SizedBox(width: 10),
        if (text.isNotEmpty)
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: tokens.buttonFontWeight,
                color: labelColor,
              ),
            ),
          ),
        if (trailingIcon != null && !loading) ...[
          const SizedBox(width: 8),
          Icon(trailingIcon, size: fontSize + 3, color: labelColor),
        ],
      ],
    );

    final style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(
        Size(fullWidth ? double.infinity : 0, 0),
      ),
      padding: WidgetStatePropertyAll(spec.padding),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.buttonRadius),
        ),
      ),
      side: WidgetStatePropertyAll(
        borderColor != null ? BorderSide(color: borderColor) : BorderSide.none,
      ),
      elevation: const WidgetStatePropertyAll(0),
      backgroundColor: WidgetStatePropertyAll(
        enabled
            ? bg
            : (variant == AppButtonVariant.outline ||
                      variant == AppButtonVariant.text
                  ? Colors.transparent
                  : p.disabled.withValues(alpha: 0.15)),
      ),
      foregroundColor: WidgetStatePropertyAll(enabled ? fg : p.disabled),
      overlayColor: WidgetStatePropertyAll(
        Colors.black.withValues(alpha: 0.06),
      ),
    );

    final onTap = enabled ? onPressed : null;
    return switch (variant) {
      AppButtonVariant.primary || AppButtonVariant.secondary => ElevatedButton(
        onPressed: onTap,
        style: style,
        child: content,
      ),
      AppButtonVariant.outline => OutlinedButton(
        onPressed: onTap,
        style: style,
        child: content,
      ),
      AppButtonVariant.text => TextButton(
        onPressed: onTap,
        style: style,
        child: content,
      ),
    };
  }
}

/// Круглая иконочная кнопка с зоной нажатия из [AppTokens.iconButtonSize].
///
/// [tooltip] обязателен: у кнопки без текста это единственная подпись для
/// экранного диктора.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.variant = AppButtonVariant.text,
    this.iconSize = 22,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final side = AppTokens.of(context).iconButtonSize;
    final (bg, fg, borderColor) = AppButton.colorsFor(variant, p);
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      iconSize: iconSize,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        minimumSize: Size.square(side),
        backgroundColor: bg,
        foregroundColor: fg,
        disabledForegroundColor: p.disabled,
        side: borderColor != null ? BorderSide(color: borderColor) : null,
      ),
    );
  }
}
