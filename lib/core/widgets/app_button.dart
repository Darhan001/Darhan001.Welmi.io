import 'package:flutter/material.dart';
import 'package:lumina/core/theme/theme_colors.dart';

enum AppButtonVariant { primary, secondary, outline, text }

enum AppButtonSize { sm, md, lg }

/// Стандартная кнопка приложения.
///
/// Варианты: [AppButtonVariant.primary] (сплошная), [AppButtonVariant.secondary]
/// (брендовая подложка), [AppButtonVariant.outline] (рамка), [AppButtonVariant.text].
class AppButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool loading;
  final bool fullWidth;

  const AppButton({
    super.key,
    required this.text,
    this.icon,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.loading = false,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final enabled = onPressed != null && !loading;

    final (bg, fg, borderColor) = switch (variant) {
      AppButtonVariant.primary => (tc.primary, tc.textOnPrimary, null),
      AppButtonVariant.secondary =>
        (tc.isDark ? tc.primary.withValues(alpha: 0.15) : tc.successBg,
            tc.isDark ? tc.success : tc.greenDark, null),
      AppButtonVariant.outline => (Colors.transparent, tc.text, tc.border),
      AppButtonVariant.text => (Colors.transparent, tc.text, null),
    };

    final (hPadding, vPadding, fontSize) = switch (size) {
      AppButtonSize.sm => (16.0, 8.0, 13.0),
      AppButtonSize.md => (24.0, 14.0, 15.0),
      AppButtonSize.lg => (28.0, 18.0, 17.0),
    };

    final content = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading) ...[
          SizedBox(
            width: fontSize + 2,
            height: fontSize + 2,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: fg,
            ),
          ),
        ] else if (icon != null) ...[
          Icon(icon, size: fontSize + 4, color: fg),
        ],
        if ((loading || icon != null) && text.isNotEmpty) const SizedBox(width: 10),
        if (text.isNotEmpty)
          Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: enabled ? fg : (variant == AppButtonVariant.primary
                  ? fg.withValues(alpha: 0.6)
                  : tc.disabled),
            ),
          ),
      ],
    );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(30),
      side: variant == AppButtonVariant.outline
          ? BorderSide(color: borderColor!)
          : BorderSide.none,
    );

    final baseStyle = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(
        Size(fullWidth ? double.infinity : 0, 0),
      ),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding),
      ),
      shape: WidgetStatePropertyAll(shape),
      elevation: const WidgetStatePropertyAll(0),
      backgroundColor: WidgetStatePropertyAll(
        enabled ? bg : (variant == AppButtonVariant.outline
            ? Colors.transparent
            : tc.disabled.withValues(alpha: 0.15)),
      ),
      overlayColor: WidgetStatePropertyAll(
        Colors.black.withValues(alpha: 0.06),
      ),
    );

    final textButton = TextButton(
      onPressed: enabled ? onPressed : null,
      style: baseStyle.copyWith(
        foregroundColor: WidgetStatePropertyAll(enabled ? fg : tc.disabled),
      ),
      child: content,
    );

    return switch (variant) {
      AppButtonVariant.primary || AppButtonVariant.secondary => ElevatedButton(
          onPressed: enabled ? onPressed : null,
          style: baseStyle.copyWith(
            foregroundColor: WidgetStatePropertyAll(enabled ? fg : tc.disabled),
          ),
          child: content,
        ),
      AppButtonVariant.outline => OutlinedButton(
          onPressed: enabled ? onPressed : null,
          style: baseStyle.copyWith(
            foregroundColor: WidgetStatePropertyAll(enabled ? fg : tc.disabled),
          ),
          child: content,
        ),
      AppButtonVariant.text => textButton,
    };
  }
}
