import 'package:flutter/material.dart';

/// Лёгкое «проседание» содержимого под пальцем.
///
/// Слушает касания, не участвуя в распознавании жестов, поэтому ничего не
/// отнимает у кнопки или `InkWell` внутри. Не анимируется, если элемент
/// неактивен или в системе включено «уменьшить движение».
class PressScale extends StatefulWidget {
  const PressScale({
    super.key,
    required this.child,
    this.enabled = true,
    this.scale = 0.97,
  });

  final Widget child;
  final bool enabled;

  /// Масштаб в нажатом состоянии.
  final double scale;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool value) {
    if (_down != value && mounted) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    final active =
        widget.enabled && !MediaQuery.disableAnimationsOf(context) && _down;
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: active ? widget.scale : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
