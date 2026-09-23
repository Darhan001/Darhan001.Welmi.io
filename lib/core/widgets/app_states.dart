import 'package:flutter/material.dart';
import 'package:lumina/core/theme/theme_colors.dart';

/// Единый индикатор загрузки.
class AppLoading extends StatelessWidget {
  final String? message;
  final bool fullScreen;

  const AppLoading({super.key, this.message, this.fullScreen = true});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final spinner = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: tc.green,
            backgroundColor: tc.border.withValues(alpha: 0.4),
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: TextStyle(fontSize: 13, color: tc.textSecondary),
          ),
        ],
      ],
    );

    if (fullScreen) {
      return Center(child: spinner);
    }
    return spinner;
  }
}

/// Единое пустое состояние.
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: tc.successBg.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44, color: tc.green.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: tc.text),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, height: 1.5, color: tc.textSecondary),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: tc.primary,
                  foregroundColor: tc.textOnPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Единое состояние ошибки с кнопкой «Повторить».
class AppErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const AppErrorState({super.key, this.message = 'Что-то пошло не так', this.onRetry});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: tc.errorBg,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline_rounded, size: 36, color: tc.error),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: tc.textSecondary),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Попробовать снова'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: tc.text,
                  side: BorderSide(color: tc.border.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
