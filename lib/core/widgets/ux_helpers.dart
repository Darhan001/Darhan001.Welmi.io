import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Для HapticFeedback
import 'package:google_fonts/google_fonts.dart';
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

/// SlideTransition + FadeTransition для красивого перехода
Route<T> smoothPageRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.15, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeInOutCubic;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      var fadeTween = Tween<double>(begin: 0.0, end: 1.0);

      return SlideTransition(
        position: animation.drive(tween),
        child: FadeTransition(
          opacity: animation.drive(fadeTween),
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 350),
  );
}

/// ScaleTransition — для модальных карточек (Hero-like)
Route<T> scalePageRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return ScaleTransition(
        scale: Tween<double>(begin: 0.92, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOut),
          ),
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 350),
  );
}

// ═══════════════════════════════════════════════════════════════
// 📭 ПУСТОЕ СОСТОЯНИЕ
// ═══════════════════════════════════════════════════════════════

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle = '',
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
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
                color: Colors.black.withValues(alpha:0.03),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44, color: Colors.black.withValues(alpha:0.15)),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black38,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  actionLabel!,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ⏳ ЭКРАН ЗАГРУЗКИ (SHIMMER)
// ═══════════════════════════════════════════════════════════════

class ShimmerLoading extends StatefulWidget {
  final int itemCount;
  final double itemHeight;
  final double borderRadius;

  const ShimmerLoading({
    super.key,
    this.itemCount = 3,
    this.itemHeight = 100,
    this.borderRadius = 20,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Column(
          children: List.generate(widget.itemCount, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ShimmerTile(
                animation: _animation.value,
                height: widget.itemHeight,
                borderRadius: widget.borderRadius,
              ),
            );
          }),
        );
      },
    );
  }
}

class ShimmerTile extends StatelessWidget {
  final double animation;
  final double height;
  final double borderRadius;

  const ShimmerTile({
    super.key,
    required this.animation,
    this.height = 100,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment(animation, 0),
          end: Alignment(animation + 1, 0),
          colors: const [
            Color(0xFFF0F0F0),
            Color(0xFFE8E8E8),
            Color(0xFFF0F0F0),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ❌ ЭКРАН ОШИБКИ
// ═══════════════════════════════════════════════════════════════

class ErrorStateWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorStateWidget({
    super.key,
    this.message = 'Что-то пошло не так',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
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
                color: Colors.red.withValues(alpha:0.06),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  size: 36, color: Colors.redAccent),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Попробовать снова'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black,
                  side: BorderSide(color: Colors.black.withValues(alpha:0.15)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
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
  AppSnackbar.show(context, message,
      icon: icon, actionLabel: actionLabel, onAction: onAction);
}

// ═══════════════════════════════════════════════════════════════
// 📊 СТАНДАРТНАЯ КАРТОЧКА-СТАТИСТИКА
// ═══════════════════════════════════════════════════════════════

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.03),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 20, color: iconColor ?? Colors.black26),
                if (onTap != null)
                  const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.black12),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(value,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.black38,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 🔄 PULL-TO-REFRESH ОБЁРТКА
// ═══════════════════════════════════════════════════════════════

class RefreshablePage extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;
  final String? loadingMessage;

  const RefreshablePage({
    super.key,
    required this.onRefresh,
    required this.child,
    this.loadingMessage,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: Colors.black,
      backgroundColor: Colors.white,
      strokeWidth: 3,
      displacement: 80,
      child: child,
    );
  }
}
