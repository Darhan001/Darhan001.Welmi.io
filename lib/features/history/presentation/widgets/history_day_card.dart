import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/features/history/presentation/widgets/history_design.dart';

/// Карточка дня: дата, метрики и добавленные упражнения.
class HistoryDayCard extends StatelessWidget {
  const HistoryDayCard({
    super.key,
    required this.dateLabel,
    required this.isToday,
    required this.exercises,
    this.stepsLabel,
    this.waterMl = 0,
    this.calories = 0,
    this.minutes = 0,
    this.distanceLabel,
    required this.distanceUnit,
  });

  final String dateLabel;
  final bool isToday;
  final List<Map<String, dynamic>> exercises;
  final String? stepsLabel;
  final int waterMl;
  final int calories;
  final int minutes;
  final String? distanceLabel;
  final String distanceUnit;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final tc = ThemeColors.of(context);
    final hasMetrics =
        stepsLabel != null ||
        waterMl > 0 ||
        calories > 0 ||
        minutes > 0 ||
        distanceLabel != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: tc.shadow(0.03),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                dateLabel,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: isToday ? HistoryDesign.greenDark : tc.text,
                ),
              ),
              const Spacer(),
              if (hasMetrics || exercises.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: HistoryDesign.greenSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    loc.active,
                    style: const TextStyle(
                      color: HistoryDesign.greenDark,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (stepsLabel != null)
                _MetricChip(
                  icon: Icons.directions_walk_rounded,
                  value: stepsLabel!,
                  label: loc.activityStepsUnit,
                  color: HistoryDesign.orange,
                  soft: HistoryDesign.orangeSoft,
                ),
              if (waterMl > 0)
                _MetricChip(
                  icon: Icons.water_drop_rounded,
                  value: '$waterMl',
                  label: loc.waterMlLabel,
                  color: HistoryDesign.blue,
                  soft: HistoryDesign.blueSoft,
                ),
              if (calories > 0)
                _MetricChip(
                  icon: Icons.local_fire_department_rounded,
                  value: '$calories',
                  label: loc.kcal,
                  color: HistoryDesign.pink,
                  soft: HistoryDesign.pinkSoft,
                ),
              if (minutes > 0)
                _MetricChip(
                  icon: Icons.timer_outlined,
                  value: '$minutes',
                  label: loc.minutesShort,
                  color: HistoryDesign.orange,
                  soft: HistoryDesign.orangeSoft,
                ),
              if (distanceLabel != null)
                _MetricChip(
                  icon: Icons.straighten,
                  value: distanceLabel!,
                  label: distanceUnit,
                  color: HistoryDesign.green,
                  soft: HistoryDesign.greenSoft,
                ),
            ],
          ),
          if (exercises.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            ...exercises.map(
              (ex) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(
                      Icons.fitness_center_rounded,
                      size: 16,
                      color: HistoryDesign.greenDark,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ex['name'] as String? ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: tc.text,
                        ),
                      ),
                    ),
                    Text(
                      '${ex['sets']}×${ex['reps']}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: HistoryDesign.greenDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.soft,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color soft;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

/// Сводка за период: шаги, вода и число активных дней.
class HistorySummaryCard extends StatelessWidget {
  const HistorySummaryCard({
    super.key,
    required this.steps,
    required this.waterLiters,
    required this.activeDays,
  });

  final String steps;
  final String waterLiters;
  final int activeDays;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final tc = ThemeColors.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: tc.shadow(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryItem(
              icon: Icons.directions_walk_rounded,
              value: steps,
              label: loc.historySteps30,
              color: HistoryDesign.orange,
              soft: HistoryDesign.orangeSoft,
            ),
          ),
          Container(
            width: 1,
            height: 44,
            color: tc.divider.withValues(alpha: 0.4),
          ),
          Expanded(
            child: _SummaryItem(
              icon: Icons.water_drop_rounded,
              value: loc.litersValue(waterLiters),
              label: loc.historyWater14,
              color: HistoryDesign.blue,
              soft: HistoryDesign.blueSoft,
            ),
          ),
          Container(
            width: 1,
            height: 44,
            color: tc.divider.withValues(alpha: 0.4),
          ),
          Expanded(
            child: _SummaryItem(
              icon: Icons.fitness_center_rounded,
              value: '$activeDays',
              label: loc.historyActiveDays,
              color: HistoryDesign.green,
              soft: HistoryDesign.greenSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.soft,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color soft;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: soft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: tc.text,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 9,
            color: tc.textHint,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
