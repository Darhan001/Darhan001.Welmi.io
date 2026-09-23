import 'package:flutter/material.dart';

/// Единый snackbar для фидбека об успехе/ошибке/информации.
class AppSnackbar {
  AppSnackbar._();

  static void show(
    BuildContext context,
    String message, {
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFF2B2B2B),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        duration: Duration(seconds: actionLabel != null ? 6 : 2),
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: const Color(0xFF75A47F),
                onPressed: onAction,
              )
            : null,
      ),
    );
  }

  /// Успех — зелёная галочка.
  static void success(BuildContext context, String message) {
    show(context, message, icon: Icons.check_circle_rounded);
  }

  /// Ошибка — красный крестик.
  static void error(BuildContext context, String message) {
    show(context, message, icon: Icons.error_rounded);
  }

  /// Информация — обычный snackbar.
  static void info(BuildContext context, String message) {
    show(context, message);
  }
}
