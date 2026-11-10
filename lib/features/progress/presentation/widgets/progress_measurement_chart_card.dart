import 'package:flutter/material.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/app_card.dart';
import 'package:lumina/features/progress/domain/progress_metrics.dart';
import 'package:lumina/features/progress/presentation/widgets/progress_common.dart';
import 'package:lumina/features/progress/presentation/widgets/progress_line_chart.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Подпись замера в выбранном языке.
String measureMetricLabel(AppLocalizations loc, MeasureMetric m) => switch (m) {
  MeasureMetric.waist => loc.progress_meas_waist,
  MeasureMetric.chest => loc.progress_meas_chest,
  MeasureMetric.hips => loc.progress_meas_hips,
  MeasureMetric.arm => loc.progress_meas_arm,
  MeasureMetric.thigh => loc.progress_meas_thigh,
  MeasureMetric.neck => loc.progress_meas_neck,
};

/// Карточка с графиком выбранного замера (только реальные записи).
class MeasurementChartCard extends StatelessWidget {
  const MeasurementChartCard({
    super.key,
    required this.points,
    required this.metric,
    required this.onMetricChanged,
  });

  final List<ProgressPoint> points;
  final MeasureMetric metric;
  final ValueChanged<MeasureMetric> onMetricChanged;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final loc = AppLocalizations.of(context)!;
    final diff = points.length >= 2
        ? points.last.value - points.first.value
        : null;

    return AppCard(
      radius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProgressCardHeader(
            title: 'Динамика замеров',
            trailing: diff == null
                ? null
                : Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: ProgressColors.measurements.withValues(
                        alpha: 0.12,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${diff > 0 ? '+' : ''}${diff.toStringAsFixed(1)} '
                      '${loc.unitCm}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: ProgressColors.measurements,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final m in MeasureMetric.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ProgressPill(
                      label: measureMetricLabel(loc, m),
                      selected: metric == m,
                      selectedColor: ProgressColors.measurements,
                      background: tc.surface,
                      outlined: false,
                      radius: 12,
                      fontSize: 11,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      onTap: () => onMetricChanged(m),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (points.isEmpty)
            ProgressChartPlaceholder(
              text:
                  'За выбранный период нет замеров '
                  '«${measureMetricLabel(loc, metric)}»',
            )
          else
            ProgressLineChart(
              points: points,
              color: ProgressColors.measurements,
              unit: loc.unitCm,
            ),
        ],
      ),
    );
  }
}
