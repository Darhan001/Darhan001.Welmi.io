import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lumina/core/theme/app_colors.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/units_format.dart';
import 'package:lumina/features/weight/presentation/widgets/weight_chart_painter.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Зелёный для снижения веса, оранжевый — для набора.
Color weightTrendColor(bool down) => down ? AppColors.brand : Colors.orange;

BoxDecoration weightCardDecoration(
  ThemeColors tc,
  double radius,
  double opacity,
) => BoxDecoration(
  color: tc.card,
  borderRadius: BorderRadius.circular(radius),
  boxShadow: [
    BoxShadow(
      color: tc.shadow(opacity),
      blurRadius: radius - 8,
      offset: const Offset(0, 6),
    ),
  ],
);

/// График динамики веса (точки — от старых к новым).
class WeightChartCard extends StatelessWidget {
  const WeightChartCard({
    super.key,
    required this.weights,
    required this.firstDate,
    required this.lastDate,
    required this.animation,
  });

  final List<double> weights;
  final DateTime firstDate;
  final DateTime lastDate;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final loc = AppLocalizations.of(context)!;
    final format = DateFormat('d MMM', loc.localeName);
    final dateStyle = TextStyle(fontSize: 10, color: tc.textHint);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: weightCardDecoration(tc, 32, 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc.weightDynamics,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: tc.text,
                ),
              ),
              Text(
                loc.weightEntries(weights.length),
                style: TextStyle(
                  fontSize: 11,
                  color: tc.textHint,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            width: double.infinity,
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, _) => CustomPaint(
                painter: WeightChartPainter(
                  weightHistory: weights,
                  color: tc.primary,
                  animationValue: animation.value,
                ),
                size: const Size(double.infinity, 200),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(format.format(firstDate), style: dateStyle),
              Text(format.format(lastDate), style: dateStyle),
            ],
          ),
        ],
      ),
    );
  }
}

/// «Сброшено» и «осталось до цели».
class WeightStatsRow extends StatelessWidget {
  const WeightStatsRow({super.key, required this.loss, required this.toGoal});

  final double loss;
  final double toGoal;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: _MiniStat(
            loc.weightLost,
            loc.formatWeight(loss),
            Icons.trending_down,
            AppColors.brand,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MiniStat(
            loc.weightToGoal,
            loc.formatWeight(toGoal),
            Icons.flag_rounded,
            Colors.orange,
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.label, this.value, this.icon, this.color);

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: weightCardDecoration(tc, 20, 0.03),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: tc.text,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: tc.textHint,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Изменение веса по последним (до 7) записям.
class WeightRecentChangeCard extends StatelessWidget {
  const WeightRecentChangeCard({super.key, required this.weights});

  /// Веса от старых к новым, минимум две записи.
  final List<double> weights;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final loc = AppLocalizations.of(context)!;
    final recent = weights.length >= 7
        ? weights.sublist(weights.length - 7)
        : weights;
    final change = recent.last - recent.first;
    final down = change <= 0;
    final color = weightTrendColor(down);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: weightCardDecoration(tc, 24, 0.03),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              down ? Icons.trending_down : Icons.trending_up,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.weekChange(recent.length),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: tc.text,
                  ),
                ),
                Text(
                  down
                      ? loc.weekLostValue(loc.formatWeight(change.abs()))
                      : loc.weekGainedValue(loc.formatWeight(change)),
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            loc.formatWeight(change, signed: true),
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
