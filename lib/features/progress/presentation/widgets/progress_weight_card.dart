import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/services/units_service.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/app_card.dart';
import 'package:lumina/core/widgets/units_format.dart';
import 'package:lumina/features/progress/domain/progress_metrics.dart';
import 'package:lumina/features/progress/presentation/widgets/progress_common.dart';
import 'package:lumina/features/progress/presentation/widgets/progress_line_chart.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Карточка текущего веса с графиком за выбранный интервал.
class ProgressWeightCard extends StatelessWidget {
  const ProgressWeightCard({
    super.key,
    required this.currentKg,
    required this.lossKg,
    required this.pointsKg,
    required this.rangeDays,
  });

  final double currentKg;

  /// Снижение веса от первой записи (кг), null — не с чем сравнить.
  final double? lossKg;

  /// Записи веса за интервал, значения в кг.
  final List<ProgressPoint> pointsKg;
  final int rangeDays;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final loc = AppLocalizations.of(context)!;
    final loss = lossKg ?? 0;
    // График подписывает значения, поэтому переводим их в выбранные единицы.
    final units = UnitsService.instance;
    final points = [
      for (final p in pointsKg)
        (date: p.date, value: units.weightToDisplay(p.value)),
    ];

    return AppCard(
      radius: 24,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.currentWeightCaps,
                    style: TextStyle(
                      fontSize: 10,
                      color: tc.textHint,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        loc.weightValue(currentKg),
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: tc.text,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        loc.weightUnitLabel,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: tc.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (loss > 0) _LossBadge(text: loc.formatWeight(loss)),
            ],
          ),
          const SizedBox(height: 24),
          ProgressCardHeader(
            title: loc.weightDynamics,
            fontSize: 13,
            trailing: Text(
              AppLocalizations.of(context)!.rangeLastDaysShort(rangeDays),
              style: TextStyle(fontSize: 11, color: tc.textHint),
            ),
          ),
          const SizedBox(height: 12),
          ProgressLineChart(
            points: points,
            color: ProgressColors.weight,
            unit: loc.weightUnitLabel,
          ),
        ],
      ),
    );
  }
}

class _LossBadge extends StatelessWidget {
  const _LossBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ProgressColors.weight.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.arrow_downward,
            size: 12,
            color: ProgressColors.weight,
          ),
          Text(
            ' $text',
            style: const TextStyle(
              color: ProgressColors.weight,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
