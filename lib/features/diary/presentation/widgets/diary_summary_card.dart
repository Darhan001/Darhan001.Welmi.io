import 'package:flutter/material.dart';
import 'package:lumina/core/services/daily_tracker.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/features/diary/presentation/widgets/calorie_arc_progress.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Карточка «Сегодня»: дуга калорий и прогресс БЖУ.
class DiarySummaryCard extends StatelessWidget {
  final DailyTracker tracker;

  /// Сумма калорий по записям дневника.
  final int totalCalories;

  const DiarySummaryCard({
    super.key,
    required this.tracker,
    required this.totalCalories,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final loc = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: tc.shadow(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.todayLabel,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: tc.text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      loc.remainingKcal(tracker.remainingCalories),
                      style: TextStyle(
                        fontSize: 13,
                        color: tc.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              CalorieArcProgress(
                current: totalCalories,
                goal: tracker.goalCalories,
              ),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              _MacroProgress(
                label: loc.protein,
                value: tracker.proteinProgress,
                current: tracker.totalProtein,
                goal: tracker.goalProtein,
                color: const Color(0xFF75A47F),
              ),
              const SizedBox(width: 12),
              _MacroProgress(
                label: loc.fat,
                value: tracker.fatProgress,
                current: tracker.totalFat,
                goal: tracker.goalFat,
                color: const Color(0xFFFFB347),
              ),
              const SizedBox(width: 12),
              _MacroProgress(
                label: loc.carbs,
                value: tracker.carbsProgress,
                current: tracker.totalCarbs,
                goal: tracker.goalCarbs,
                color: const Color(0xFF4A90E2),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroProgress extends StatelessWidget {
  final String label;
  final double value;
  final int current;
  final int goal;
  final Color color;

  const _MacroProgress({
    required this.label,
    required this.value,
    required this.current,
    required this.goal,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$currentг',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: tc.text,
                  ),
                ),
                Text(
                  ' / $goalг',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: tc.inactive,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              height: 6,
              width: double.infinity,
              decoration: BoxDecoration(
                color: tc.card,
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: value.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
