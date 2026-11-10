import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/app_card.dart';
import 'package:lumina/core/widgets/units_format.dart';
import 'package:lumina/features/goal/domain/goal_progress.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Кольцо прогресса к цели со стартом, изменением и целью.
class GoalProgressRing extends StatelessWidget {
  const GoalProgressRing({
    super.key,
    required this.progress,
    required this.animation,
  });

  final GoalProgress progress;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final loc = AppLocalizations.of(context)!;
    final value = progress.progress;
    return AppCard(
      radius: 32,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: animation,
            builder: (context, _) => SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 12,
                    backgroundColor: tc.text.withValues(alpha: 0.05),
                    color: Colors.transparent,
                  ),
                  CircularProgressIndicator(
                    value: value * animation.value,
                    strokeWidth: 12,
                    backgroundColor: Colors.transparent,
                    color: tc.green,
                    strokeCap: StrokeCap.round,
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(value * 100).toStringAsFixed(0)}%',
                        style: GoogleFonts.inter(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: tc.greenDark,
                        ),
                      ),
                      Text(
                        loc.completed,
                        style: TextStyle(
                          fontSize: 12,
                          color: tc.textHint,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _RingStat(loc.formatWeight(progress.startKg), loc.start),
              _RingStat(
                loc.formatWeight(progress.totalLoss),
                loc.weightLost,
                highlight: true,
              ),
              _RingStat(loc.formatWeight(progress.goalKg), loc.goalWeight),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingStat extends StatelessWidget {
  const _RingStat(this.value, this.label, {this.highlight = false});

  final String value;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: highlight ? 20 : 16,
            fontWeight: FontWeight.w900,
            color: highlight ? tc.greenDark : tc.text,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: tc.textHint,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// Столбики «Было / Сейчас / Цель».
class GoalWeightComparison extends StatelessWidget {
  const GoalWeightComparison({
    super.key,
    required this.progress,
    required this.animation,
  });

  final GoalProgress progress;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final loc = AppLocalizations.of(context)!;
    final maxWeight = (progress.startKg + 2).clamp(
      progress.currentKg + 2,
      200.0,
    );
    Widget bar(String label, double kg, Color color, {bool isGoal = false}) =>
        Expanded(
          child: _WeightBar(
            label: label,
            weightKg: kg,
            maxWeight: maxWeight,
            color: color,
            isGoal: isGoal,
            animation: animation,
          ),
        );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.comparison,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: tc.text,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              bar(loc.was, progress.startKg, tc.text.withValues(alpha: 0.26)),
              const SizedBox(width: 12),
              bar(loc.now, progress.currentKg, tc.green),
              const SizedBox(width: 12),
              bar(loc.goalWeight, progress.goalKg, tc.greenDark, isGoal: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeightBar extends StatelessWidget {
  const _WeightBar({
    required this.label,
    required this.weightKg,
    required this.maxWeight,
    required this.color,
    required this.isGoal,
    required this.animation,
  });

  final String label;
  final double weightKg;
  final double maxWeight;
  final Color color;
  final bool isGoal;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final height = (weightKg / maxWeight * 140).clamp(40.0, 140.0);
    return Column(
      children: [
        AnimatedBuilder(
          animation: animation,
          builder: (context, _) => Container(
            height: isGoal ? 140 - (140 - height) * animation.value : height,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [color, color.withValues(alpha: 0.6)],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)!.weightValue(weightKg),
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: tc.text,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: tc.textHint,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
