import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lumina/features/chat/presentation/widgets/chat_design.dart';

/// «AI печатает…» — пузырь с прыгающими точками.
class ChatTypingIndicator extends StatelessWidget {
  const ChatTypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 48, top: 6, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const ChatAiBadge(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: ChatDesign.card,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: ChatDesign.cardBorder),
            ),
            child: const _TypingDots(dotColor: ChatDesign.lime),
          ),
        ],
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots({required this.dotColor});
  final Color dotColor;

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // При отключённых анимациях точки стоят на месте.
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
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
        return SizedBox(
          width: 50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [_dot(0.0), _dot(0.2), _dot(0.4)],
          ),
        );
      },
    );
  }

  Widget _dot(double delay) {
    final phase = (_controller.value - delay) * pi;
    final offset = -8 * sin(phase).clamp(-1.0, 1.0);
    return Transform.translate(
      offset: Offset(0, offset > 0 ? 0 : offset),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: widget.dotColor.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
