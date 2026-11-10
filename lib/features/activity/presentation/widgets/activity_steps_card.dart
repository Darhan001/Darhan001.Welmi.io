import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/theme/app_colors.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/units_format.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Главная карточка шагов: кольцо прогресса и мини-статистика дня.
class ActivityStepsCard extends StatelessWidget {
  const ActivityStepsCard({
    super.key,
    required this.steps,
    required this.goal,
    required this.distanceKm,
    required this.calories,
    required this.minutes,
  });

  final int steps;
  final int goal;
  final double distanceKm;
  final double calories;
  final double minutes;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final loc = AppLocalizations.of(context)!;
    final progress = goal > 0 ? (steps / goal).clamp(0.0, 1.0) : 0.0;
    final remaining = (goal - steps).clamp(0, goal);
    final reached = remaining == 0;
    final ringColor = reached ? AppColors.brand : Colors.orange;
    final animate = !MediaQuery.disableAnimationsOf(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: tc.shadow(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            reached
                ? loc.activityGoalReached
                : loc.activityStepsToGoal(remaining),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: ringColor,
            ),
          ),
          const SizedBox(height: 24),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 200,
                height: 200,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: animate ? 0 : progress, end: progress),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => CircularProgressIndicator(
                    value: value,
                    strokeWidth: 12,
                    backgroundColor: tc.text.withValues(alpha: 0.05),
                    color: ringColor,
                    strokeCap: StrokeCap.round,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$steps',
                    style: GoogleFonts.inter(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: tc.text,
                    ),
                  ),
                  Text(
                    loc.activityStepsUnit,
                    style: TextStyle(
                      fontSize: 14,
                      color: tc.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _MiniStat(
                distanceKm > 0 ? loc.formatDistance(distanceKm) : '—',
                loc.activityDistance,
              ),
              _MiniStat(
                calories > 0 ? '${calories.toInt()} ${loc.kcal}' : '—',
                loc.activityEnergy,
              ),
              _MiniStat(
                minutes > 0 ? '${minutes.toInt()} ${loc.minutesShort}' : '—',
                loc.activityLog,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.value, this.label);

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
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
