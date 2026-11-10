import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/models/supabase_models.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/app_button.dart';
import 'package:lumina/core/widgets/app_card.dart';
import 'package:lumina/features/progress/domain/progress_metrics.dart';
import 'package:lumina/features/progress/presentation/widgets/progress_body_fat_summary.dart';
import 'package:lumina/features/progress/presentation/widgets/progress_common.dart';
import 'package:lumina/features/progress/presentation/widgets/progress_line_chart.dart';
import 'package:lumina/l10n/app_localizations.dart';

String bodyFatMethodLabel(String method) => switch (method) {
  'caliper' => 'калипер',
  'scale' => 'весы',
  'estimated' => 'оценка',
  _ => 'вручную',
};

/// Вкладка «% жира»: текущее значение, график, история и кнопки записи.
class ProgressBodyFatTab extends StatelessWidget {
  const ProgressBodyFatTab({
    super.key,
    required this.entries,
    required this.rangeFrom,
    required this.rangeDays,
    required this.onRecord,
    required this.onEstimate,
  });

  /// Все записи, новые первыми.
  final List<BodyFatEntry> entries;
  final DateTime rangeFrom;
  final int rangeDays;
  final VoidCallback onRecord;
  final VoidCallback onEstimate;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Column(
      children: [
        if (entries.isNotEmpty) ...[
          BodyFatSummaryCard(percent: entries.first.bodyFatPercent),
          const SizedBox(height: 16),
          _BodyFatChartCard(
            points: seriesSince(
              entries,
              from: rangeFrom,
              dateOf: (e) => e.date,
              valueOf: (e) => e.bodyFatPercent,
            ),
            rangeDays: rangeDays,
            onEstimate: onEstimate,
          ),
          if (entries.length >= 2) ...[
            const SizedBox(height: 24),
            _BodyFatHistoryCard(entries: entries.take(5).toList()),
          ],
        ] else
          const ProgressEmptyCard(
            icon: Icons.monitor_heart_outlined,
            title: 'Пока нет данных о % жира',
            subtitle:
                'Запишите процент жира в теле, чтобы отслеживать изменения',
          ),
        const SizedBox(height: 24),
        AppButton(
          text: '+ ${loc.recordBodyFat}',
          size: AppButtonSize.lg,
          onPressed: onRecord,
        ),
      ],
    );
  }
}

class _BodyFatChartCard extends StatelessWidget {
  const _BodyFatChartCard({
    required this.points,
    required this.rangeDays,
    required this.onEstimate,
  });

  final List<ProgressPoint> points;
  final int rangeDays;
  final VoidCallback onEstimate;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return AppCard(
      radius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProgressCardHeader(
            title: 'Динамика % жира',
            trailing: Text(
              'за $rangeDays дн.',
              style: TextStyle(fontSize: 11, color: tc.textHint),
            ),
          ),
          const SizedBox(height: 14),
          if (points.isEmpty)
            const ProgressChartPlaceholder(
              text: 'За выбранный период нет записей % жира',
            )
          else
            ProgressLineChart(
              points: points,
              color: ProgressColors.bodyFat,
              unit: '%',
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                size: 13,
                color: ProgressColors.bodyFat,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Оценочный расчёт по замерам — не медицинское измерение.',
                  style: TextStyle(
                    fontSize: 10,
                    color: tc.textHint,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Material(
            color: ProgressColors.bodyFat.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: onEstimate,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 44),
                alignment: Alignment.center,
                child: const Text(
                  'Оценить по замерам',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: ProgressColors.bodyFat,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BodyFatHistoryCard extends StatelessWidget {
  const _BodyFatHistoryCard({required this.entries});

  final List<BodyFatEntry> entries;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return AppCard(
      radius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ProgressCardHeader(title: 'История'),
          const SizedBox(height: 16),
          for (final e in entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Text(
                    '${e.date.day}.${e.date.month}',
                    style: TextStyle(fontSize: 12, color: tc.textSecondary),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${e.bodyFatPercent.toStringAsFixed(1)}%',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: tc.text,
                    ),
                  ),
                  if (e.method != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '(${bodyFatMethodLabel(e.method!)})',
                      style: TextStyle(fontSize: 10, color: tc.textHint),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
