import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Для HapticFeedback
import 'package:lumina/core/widgets/app_snackbar.dart';

// ═══════════════════════════════════════════════════════════════
// 📳 ТАКТИЛЬНАЯ ОТДАЧА (HAPTIC FEEDBACK)
// ═══════════════════════════════════════════════════════════════

/// Лёгкая отдача — для обычных нажатий и переключений.
void hapticTap() => HapticFeedback.selectionClick();

/// Заметная отдача — для успешных действий (сохранение, сканирование).
void hapticSuccess() => HapticFeedback.mediumImpact();

/// Сильная отдача — для важных событий.
void hapticHeavy() => HapticFeedback.heavyImpact();

// ═══════════════════════════════════════════════════════════════
// 🎬 ПЛАВНЫЙ ПЕРЕХОД МЕЖДУ СТРАНИЦАМИ
// ═══════════════════════════════════════════════════════════════

/// Переход на экран раздела.
///
/// Обычный [MaterialPageRoute]: анимацию задаёт тема (`AppTheme`), поэтому
/// она одна на всё приложение. Прежний самодельный переход отключал
/// системные жесты — на iOS экран нельзя было закрыть свайпом от края.
Route<T> smoothPageRoute<T>(Widget page) {
  return MaterialPageRoute<T>(builder: (context) => page);
}

/// ScaleTransition — для модальных карточек (Hero-like)
Route<T> scalePageRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.disableAnimationsOf(context)) return child;
      return ScaleTransition(
        scale: Tween<double>(begin: 0.92, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: FadeTransition(
          opacity: Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 350),
  );
}

/// Мягкое появление содержимого: прозрачность + небольшой сдвиг снизу.
///
/// [index] задаёт короткую задержку для элементов списка (каскад), но
/// не больше ~240 мс, чтобы длинные списки не «ползли». При системной
/// настройке «уменьшить движение» виджет показывается сразу.
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({super.key, required this.child, this.index = 0});

  final Widget child;
  final int index;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final delay = (index.clamp(0, 6)) * 40;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 260 + delay),
      curve: Interval(delay / (260 + delay), 1, curve: Curves.easeOutCubic),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - t)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 🔔 СТАНДАРТНЫЙ SNACKBAR
// ═══════════════════════════════════════════════════════════════

void showWelmiSnackbar(
  BuildContext context,
  String message, {
  IconData? icon,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  // Единая реализация — см. AppSnackbar
  AppSnackbar.show(
    context,
    message,
    icon: icon,
    actionLabel: actionLabel,
    onAction: onAction,
  );
}
