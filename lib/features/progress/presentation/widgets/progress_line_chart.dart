import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/features/progress/domain/progress_metrics.dart';

/// Серая подложка вместо графика: «нет данных», «нужно больше записей».
class ProgressChartPlaceholder extends StatelessWidget {
  const ProgressChartPlaceholder({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Container(
      height: 110,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: tc.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: tc.textSecondary),
      ),
    );
  }
}

/// Линейный график по настоящим записям пользователя.
///
/// [points] уже отфильтрованы по интервалу и отсортированы по дате;
/// значения — в единицах показа ([unit]).
class ProgressLineChart extends StatelessWidget {
  const ProgressLineChart({
    super.key,
    required this.points,
    required this.color,
    required this.unit,
  });

  final List<ProgressPoint> points;
  final Color color;
  final String unit;

  static String _shortDate(DateTime d) =>
      '${d.day}.${d.month.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    if (points.length < 2) {
      return ProgressChartPlaceholder(
        text:
            'Нужно минимум 2 записи за выбранный период\n'
            '(${points.length} из 2)',
      );
    }

    var minV = points.first.value;
    var maxV = minV;
    for (final p in points) {
      minV = math.min(minV, p.value);
      maxV = math.max(maxV, p.value);
    }
    final spread = maxV - minV;
    final pad = spread > 0 ? spread * 0.25 : 1.0;
    final step = spread > 0 ? spread / 3 : 1.0;
    final labelStep = math.max(1, (points.length / 4).ceil());
    final hintStyle = TextStyle(fontSize: 9, color: tc.textHint);

    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (points.length - 1).toDouble(),
          minY: minV - pad,
          maxY: maxV + pad,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: step,
            getDrawingHorizontalLine: (_) => FlLine(
              color: tc.divider.withValues(alpha: 0.7),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 38,
                interval: step,
                getTitlesWidget: (value, meta) =>
                    Text(value.toStringAsFixed(0), style: hintStyle),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final i = value.round();
                  final isLast = i == points.length - 1;
                  if (i < 0 || i >= points.length) {
                    return const SizedBox.shrink();
                  }
                  if (i % labelStep != 0 && !isLast) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(_shortDate(points[i].date), style: hintStyle),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touched) => touched.map((spot) {
                final i = spot.x.round().clamp(0, points.length - 1);
                final d = points[i].date;
                return LineTooltipItem(
                  '${d.day}.${d.month}: ${spot.y.toStringAsFixed(1)} $unit',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < points.length; i++)
                  FlSpot(i.toDouble(), points[i].value),
              ],
              isCurved: true,
              curveSmoothness: 0.25,
              color: color,
              barWidth: 3,
              dotData: FlDotData(
                show: points.length <= 20,
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(
                      radius: 3,
                      color: color,
                      strokeWidth: 1.5,
                      strokeColor: Colors.white,
                    ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
