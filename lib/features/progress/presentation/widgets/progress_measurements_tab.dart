import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/models/supabase_models.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/app_button.dart';
import 'package:lumina/core/widgets/app_card.dart';
import 'package:lumina/features/progress/domain/progress_metrics.dart';
import 'package:lumina/features/progress/presentation/widgets/progress_common.dart';
import 'package:lumina/features/progress/presentation/widgets/progress_measurement_chart_card.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Вкладка «Замеры»: последние значения, график выбранного замера и кнопка
/// записи.
class ProgressMeasurementsTab extends StatelessWidget {
  const ProgressMeasurementsTab({
    super.key,
    required this.measurements,
    required this.rangeFrom,
    required this.metric,
    required this.onMetricChanged,
    required this.onRecord,
  });

  /// Все замеры, новые первыми (как отдаёт UserDataService).
  final List<BodyMeasurement> measurements;
  final DateTime rangeFrom;
  final MeasureMetric metric;
  final ValueChanged<MeasureMetric> onMetricChanged;
  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Column(
      children: [
        if (measurements.isNotEmpty) ...[
          _LatestMeasurementsCard(
            latest: measurements.first,
            previous: measurements.length > 1 ? measurements[1] : null,
          ),
          const SizedBox(height: 16),
          MeasurementChartCard(
            points: seriesSince(
              measurements,
              from: rangeFrom,
              dateOf: (m) => m.date,
              valueOf: metric.valueOf,
            ),
            metric: metric,
            onMetricChanged: onMetricChanged,
          ),
        ] else
          ProgressEmptyCard(
            icon: Icons.straighten,
            title: AppLocalizations.of(context)!.measEmptyTitle,
            subtitle: AppLocalizations.of(context)!.measEmptySubtitle,
          ),
        const SizedBox(height: 24),
        AppButton(
          text: '+ ${loc.recordMeasurements}',
          size: AppButtonSize.lg,
          onPressed: onRecord,
        ),
      ],
    );
  }
}

class _LatestMeasurementsCard extends StatelessWidget {
  const _LatestMeasurementsCard({required this.latest, this.previous});

  final BodyMeasurement latest;
  final BodyMeasurement? previous;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final loc = AppLocalizations.of(context)!;
    return AppCard(
      radius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProgressCardHeader(
            title: AppLocalizations.of(context)!.measLatest,
            trailing: Text(
              '${latest.date.day}.${latest.date.month}',
              style: TextStyle(fontSize: 12, color: tc.textSecondary),
            ),
          ),
          const SizedBox(height: 20),
          for (final m in MeasureMetric.values)
            if (m.valueOf(latest) case final value?)
              _MeasureRow(
                label: measureMetricLabel(loc, m),
                current: value,
                previous: previous == null ? null : m.valueOf(previous!),
                unit: loc.unitCm,
              ),
        ],
      ),
    );
  }
}

class _MeasureRow extends StatelessWidget {
  const _MeasureRow({
    required this.label,
    required this.current,
    required this.previous,
    required this.unit,
  });

  final String label;
  final double current;
  final double? previous;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final diff = previous != null ? current - previous! : 0.0;
    final down = diff < 0;
    final diffColor = down ? ProgressColors.weight : Colors.orange;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: tc.text,
              ),
            ),
          ),
          Text(
            '${current.toStringAsFixed(0)} $unit',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: tc.text,
            ),
          ),
          const Spacer(),
          if (diff.abs() >= 0.5)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: diffColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    down ? Icons.arrow_downward : Icons.arrow_upward,
                    size: 10,
                    color: diffColor,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${diff.abs().toStringAsFixed(0)} $unit',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: diffColor,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
