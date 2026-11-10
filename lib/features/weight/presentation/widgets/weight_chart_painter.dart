import 'package:flutter/material.dart';

/// Плавная линия веса с заливкой; [animationValue] раскрывает её слева направо.
class WeightChartPainter extends CustomPainter {
  final List<double> weightHistory;
  final Color color;
  final double animationValue;

  WeightChartPainter({
    required this.weightHistory,
    required this.color,
    this.animationValue = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (weightHistory.length < 2) return;

    final chartHeight = size.height * 0.85;
    final topMargin = size.height * 0.15;

    final minWeight = weightHistory.reduce((a, b) => a < b ? a : b);
    final maxWeight = weightHistory.reduce((a, b) => a > b ? a : b);
    final range = (maxWeight - minWeight).clamp(0.5, double.infinity);

    // Padding
    const leftPad = 0.0;
    const rightPad = 0.0;
    final chartWidth = size.width - leftPad - rightPad;

    // Grid lines
    final gridPaint = Paint()
      ..color = color.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = topMargin + (chartHeight / 4) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Gradient fill
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final fillPath = Path();

    // Line
    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final itemsToShow = (weightHistory.length * animationValue).ceil().clamp(
      2,
      weightHistory.length,
    );
    final visibleWeights = weightHistory.sublist(0, itemsToShow);
    if (visibleWeights.length < 2) return;

    final vStepX = chartWidth / (visibleWeights.length - 1);
    final path = Path();

    for (int i = 0; i < visibleWeights.length; i++) {
      final x = leftPad + i * vStepX;
      final y =
          topMargin +
          chartHeight -
          ((visibleWeights[i] - minWeight) / range) * chartHeight;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else if (i < visibleWeights.length - 1) {
        // Smooth curve using quadratic bezier
        final prevX = leftPad + (i - 1) * vStepX;
        final midX = (prevX + x) / 2;
        final prevY =
            topMargin +
            chartHeight -
            ((visibleWeights[i - 1] - minWeight) / range) * chartHeight;
        path.quadraticBezierTo(prevX, prevY, midX, (prevY + y) / 2);
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
        fillPath.lineTo(x, size.height);
        fillPath.close();
      }
    }

    canvas.drawPath(fillPath, fillPaint);

    // Draw the line
    if (animationValue >= 0.05) {
      canvas.drawPath(path, linePaint);
    }

    // Draw dots for each point
    for (int i = 0; i < visibleWeights.length; i++) {
      final x = leftPad + i * vStepX;
      final y =
          topMargin +
          chartHeight -
          ((visibleWeights[i] - minWeight) / range) * chartHeight;

      final isLast = i == visibleWeights.length - 1;
      canvas.drawCircle(
        Offset(x, y),
        isLast ? 6 : 3,
        Paint()
          ..color = isLast ? Colors.white : color.withValues(alpha: 0.5)
          ..style = PaintingStyle.fill,
      );
      if (isLast) {
        canvas.drawCircle(Offset(x, y), 4, Paint()..color = color);
      }
    }
  }

  @override
  bool shouldRepaint(covariant WeightChartPainter oldDelegate) =>
      oldDelegate.weightHistory != weightHistory ||
      oldDelegate.animationValue != animationValue;
}
