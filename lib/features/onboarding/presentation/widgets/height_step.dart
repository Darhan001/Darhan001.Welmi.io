import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/theme/theme_colors.dart';

class HeightStep extends StatefulWidget {
  final double height;
  final ValueChanged<double> onHeightChanged;

  const HeightStep({
    super.key,
    required this.height,
    required this.onHeightChanged,
  });

  @override
  State<HeightStep> createState() => _HeightStepState();
}

class _HeightStepState extends State<HeightStep> {
  late double _height;
  late int _displayHeight;

  @override
  void initState() {
    super.initState();
    _height = widget.height;
    _displayHeight = widget.height.round();
  }

  @override
  void didUpdateWidget(HeightStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.height != widget.height) {
      _height = widget.height;
      _displayHeight = widget.height.round();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Column(
      children: [
        const SizedBox(height: 40),
        Text(
          'Какой у тебя рост?',
          textAlign: TextAlign.center,
          style: GoogleFonts.notoSerif(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: tc.text,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Это поможет нам точнее рассчитать твою дневную норму',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(color: tc.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 32),
        _buildUnitToggle('см', 'футы', tc),
        const SizedBox(height: 20),
        Expanded(
          child: Row(
            children: [
              // Линейка слева
              GestureDetector(
                onVerticalDragUpdate: (details) {
                  setState(() {
                    _height -= details.delta.dy * 0.15;
                    _height = _height.clamp(100.0, 250.0);
                    _displayHeight = _height.round();
                    widget.onHeightChanged(_height);
                  });
                },
                child: Container(
                  width: 100,
                  color: Colors.transparent,
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: HeightRulerPainter(
                      currentHeight: _height,
                      isDark: tc.isDark,
                    ),
                  ),
                ),
              ),
              // Большое число по центру
              Expanded(
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('$_displayHeight',
                          style: GoogleFonts.inter(
                              fontSize: 80, fontWeight: FontWeight.w900, color: tc.text)),
                      const SizedBox(width: 4),
                      Text('см',
                          style: GoogleFonts.inter(
                              fontSize: 24,
                              color: tc.textSecondary,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 80), // Для баланса визуального центра
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUnitToggle(String u1, String u2, ThemeColors tc) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: tc.isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(
              color: tc.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(u1,
                style:
                    TextStyle(color: tc.textOnPrimary, fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(u2,
                style: TextStyle(
                    color: tc.textSecondary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class HeightRulerPainter extends CustomPainter {
  final double currentHeight;
  final bool isDark;
  HeightRulerPainter({required this.currentHeight, this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? Colors.white24 : Colors.black12
      ..strokeWidth = 1.5;

    final textStyle = GoogleFonts.inter(
      color: isDark ? Colors.white38 : Colors.black26,
      fontSize: 13,
      fontWeight: FontWeight.w600,
    );

    final centerLinePaint = Paint()
      ..color = isDark ? Colors.white70 : Colors.black
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    double centerY = size.height / 2;
    
    // Рисуем указатель (центральную линию)
    canvas.drawLine(
      Offset(size.width - 30, centerY),
      Offset(size.width, centerY),
      centerLinePaint,
    );

    // Масштаб: 1 см = 8 пикселей
    const double pixelsPerCm = 8;

    int minCm = (currentHeight - (size.height / 2 / pixelsPerCm)).floor() - 1;
    int maxCm = (currentHeight + (size.height / 2 / pixelsPerCm)).ceil() + 1;

    for (int cm = minCm; cm <= maxCm; cm++) {
      if (cm < 100 || cm > 250) continue;

      double y = centerY - (cm - currentHeight) * pixelsPerCm;
      
      if (y < 0 || y > size.height) continue;

      bool isMajor = cm % 10 == 0;
      bool isMedium = cm % 5 == 0;
      
      double tickWidth = isMajor ? 45 : (isMedium ? 30 : 20);
      if (isDark) {
        paint.color = isMajor ? Colors.white54 : (isMedium ? Colors.white38 : Colors.white24);
      } else {
        paint.color = isMajor ? Colors.black38 : (isMedium ? Colors.black26 : Colors.black12);
      }
      paint.strokeWidth = isMajor ? 2 : 1.5;

      canvas.drawLine(
        Offset(size.width - tickWidth, y),
        Offset(size.width, y),
        paint,
      );

      if (isMajor) {
        final textPainter = TextPainter(
          text: TextSpan(text: '$cm', style: textStyle),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(size.width - tickWidth - textPainter.width - 12, y - textPainter.height / 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant HeightRulerPainter oldDelegate) =>
      oldDelegate.currentHeight != currentHeight;
}

// Старый RulerPainter временно оставлен для совместимости с WeightStep
class RulerPainter extends CustomPainter {
  final bool vertical;
  RulerPainter({required this.vertical});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black12
      ..strokeWidth = 1.5;

    if (vertical) {
      for (double i = 0; i <= size.height; i += 15) {
        double width = (i % 75 == 0) ? 40 : 20;
        canvas.drawLine(Offset(size.width / 2 - width / 2, i),
            Offset(size.width / 2 + width / 2, i), paint);
      }
    } else {
      for (double i = 0; i <= size.width; i += 15) {
        double height = (i % 75 == 0) ? 40 : 20;
        canvas.drawLine(Offset(i, 0), Offset(i, height), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
