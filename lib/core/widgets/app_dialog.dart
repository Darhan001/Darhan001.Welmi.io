import 'package:flutter/material.dart';
import 'package:lumina/core/theme/theme_colors.dart';

/// Единые диалоги подтверждения и нижние листы.
class AppDialog {
  AppDialog._();

  /// Диалог подтверждения необратимого действия.
  /// Возвращает `true`, если пользователь подтвердил.
  static Future<bool?> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Удалить',
    String cancelLabel = 'Отмена',
    bool destructive = true,
    IconData? icon,
  }) {
    final tc = ThemeColors.of(context);
    final confirmColor = destructive ? tc.error : tc.success;

    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tc.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: icon != null
            ? CircleAvatar(
                radius: 28,
                backgroundColor: confirmColor.withValues(alpha: 0.12),
                child: Icon(icon, color: confirmColor, size: 26),
              )
            : null,
        title: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, height: 1.5, color: tc.textSecondary),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              cancelLabel,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: tc.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              confirmLabel,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: confirmColor),
            ),
          ),
        ],
      ),
    );
  }
}

/// Единый нижний лист (bottom sheet) в стиле приложения.
class AppBottomSheet {
  AppBottomSheet._();

  static Future<T?> show<T>(
    BuildContext context, {
    required Widget Function(BuildContext, ThemeColors) builder,
    double maxHeight = 0.75,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final tc = ThemeColors.of(ctx);
        return FractionallySizedBox(
          heightFactor: maxHeight,
          child: Container(
            decoration: BoxDecoration(
              color: tc.card,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: tc.border.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(child: builder(ctx, tc)),
              ],
            ),
          ),
        );
      },
    );
  }
}
