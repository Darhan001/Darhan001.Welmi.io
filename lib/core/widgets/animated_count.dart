import 'package:flutter/material.dart';

/// Число, которое плавно «досчитывает» до нового значения.
///
/// Используется для крупных показателей (калории, вода): изменение видно,
/// а не подменяется мгновенно. При системной настройке «уменьшить движение»
/// значение показывается сразу. Для экранных дикторов всегда объявляется
/// итоговое число, а не промежуточные кадры.
class AnimatedCount extends StatelessWidget {
  const AnimatedCount({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 700),
    this.format,
  });

  final int value;
  final TextStyle? style;
  final Duration duration;

  /// Как показать число; по умолчанию — без разделителей.
  final String Function(int value)? format;

  String _text(int v) => format?.call(v) ?? '$v';

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return Text(_text(value), style: style);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) =>
          Text(_text(v.round()), style: style, semanticsLabel: _text(value)),
    );
  }
}
