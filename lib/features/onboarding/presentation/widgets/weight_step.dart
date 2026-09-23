import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/theme/theme_colors.dart';

class WeightStep extends StatefulWidget {
  final double weight;
  final ValueChanged<double> onWeightChanged;

  const WeightStep({
    super.key,
    required this.weight,
    required this.onWeightChanged,
  });

  @override
  State<WeightStep> createState() => _WeightStepState();
}

class _WeightStepState extends State<WeightStep> {
  late double _weight;
  late int _displayWeight;

  @override
  void initState() {
    super.initState();
    _weight = widget.weight;
    _displayWeight = widget.weight.round();
  }

  @override
  void didUpdateWidget(WeightStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weight != widget.weight) {
      _weight = widget.weight;
      _displayWeight = widget.weight.round();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Column(
      children: [
        const SizedBox(height: 40),
        Text(
          'Сколько ты весишь\nсейчас?',
          textAlign: TextAlign.center,
          style: GoogleFonts.notoSerif(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: tc.text,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Это поможет нам рассчитать твою норму калорий',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(color: tc.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 32),
        _buildUnitToggle('кг', 'фунты', tc),
        const SizedBox(height: 60),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('$_displayWeight',
                style: GoogleFonts.inter(
                    fontSize: 80, fontWeight: FontWeight.w900, color: tc.text)),
            const SizedBox(width: 4),
            Text('кг',
                style: GoogleFonts.inter(
                    fontSize: 24,
                    color: tc.textSecondary,
                    fontWeight: FontWeight.w500)),
          ],
        ),
        const Spacer(),
        // Горизонтальная линейка снизу
        SizedBox(
          height: 120,
          child: GestureDetector(
            onHorizontalDragUpdate: (details) {
              setState(() {
                _weight += details.delta.dx * 0.15;
                _weight = _weight.clamp(30.0, 250.0);
                _displayWeight = _weight.round();
                widget.onWeightChanged(_weight);
              });
            },
            child: Container(
              width: double.infinity,
              color: Colors.transparent,
              child: CustomPaint(
                size: const Size(double.infinity, 100),
                painter: WeightRulerPainter(
                  currentWeight: _weight,
                  isDark: tc.isDark,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
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

class WeightRulerPainter extends CustomPainter {
  final double currentWeight;
  final bool isDark;
  WeightRulerPainter({required this.currentWeight, this.isDark = false});

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

    double centerX = size.width / 2;
    
    // Рисуем указатель (центральную линию) сверху
    canvas.drawLine(
      Offset(centerX, 0),
      Offset(centerX, 30),
      centerLinePaint,
    );

    // Масштаб: 1 кг = 10 пикселей
    const double pixelsPerUnit = 10;

    int minWeight = (currentWeight - (size.width / 2 / pixelsPerUnit)).floor() - 1;
    int maxWeight = (currentWeight + (size.width / 2 / pixelsPerUnit)).ceil() + 1;

    for (int w = minWeight; w <= maxWeight; w++) {
      if (w < 30 || w > 250) continue;

      double x = centerX + (w - currentWeight) * pixelsPerUnit;
      
      if (x < 0 || x > size.width) continue;

      bool isMajor = w % 10 == 0;
      bool isMedium = w % 5 == 0;
      
      double tickHeight = isMajor ? 45 : (isMedium ? 30 : 20);
      if (isDark) {
        paint.color = isMajor ? Colors.white54 : (isMedium ? Colors.white38 : Colors.white24);
      } else {
        paint.color = isMajor ? Colors.black38 : (isMedium ? Colors.black26 : Colors.black12);
      }
      paint.strokeWidth = isMajor ? 2 : 1.5;

      canvas.drawLine(
        Offset(x, 0),
        Offset(x, tickHeight),
        paint,
      );

      if (isMajor) {
        final textPainter = TextPainter(
          text: TextSpan(text: '$w', style: textStyle),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, tickHeight + 8),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant WeightRulerPainter oldDelegate) =>
      oldDelegate.currentWeight != currentWeight;
}
