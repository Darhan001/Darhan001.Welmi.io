import 'package:flutter/material.dart';
import 'package:lumina/core/theme/app_tokens.dart';
import 'package:lumina/core/theme/theme_colors.dart';

/// Заглушка на месте содержимого, пока оно загружается.
///
/// Повторяет форму будущего блока, поэтому экран не «прыгает», когда
/// данные приходят. Мягко пульсирует; при настройке «уменьшить движение»
/// остаётся неподвижной.
class AppSkeleton extends StatefulWidget {
  const AppSkeleton({super.key, this.width, required this.height, this.radius});

  final double? width;
  final double height;

  /// По умолчанию — скругление карточки из [AppTokens].
  final double? radius;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final radius = widget.radius ?? AppTokens.of(context).cardRadius;
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) => Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: tc.text.withValues(alpha: 0.05 + 0.05 * _pulse.value),
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),
    );
  }
}
