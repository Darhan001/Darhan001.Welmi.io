import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lumina/core/models/supabase_models.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/units_format.dart';
import 'package:lumina/features/progress/presentation/widgets/progress_common.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Показывает фактические записи выбранного дня календаря.
/// Если записей нет — так и показывает, без выдуманных данных.
Future<void> showProgressDayDetails(
  BuildContext context, {
  required DateTime day,
  required List<WeightEntry> weights,
  required List<BodyMeasurement> measurements,
  required List<BodyFatEntry> bodyFat,
}) {
  bool sameDay(DateTime d) =>
      d.year == day.year && d.month == day.month && d.day == day.day;

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => ProgressDayDetailsSheet(
      day: day,
      weights: weights.where((e) => sameDay(e.date)).toList(),
      measurements: measurements.where((m) => sameDay(m.date)).toList(),
      bodyFat: bodyFat.where((b) => sameDay(b.date)).toList(),
    ),
  );
}

/// Содержимое шторки с записями одного дня (уже отфильтрованными).
class ProgressDayDetailsSheet extends StatelessWidget {
  const ProgressDayDetailsSheet({
    super.key,
    required this.day,
    required this.weights,
    required this.measurements,
    required this.bodyFat,
  });

  final DateTime day;
  final List<WeightEntry> weights;
  final List<BodyMeasurement> measurements;
  final List<BodyFatEntry> bodyFat;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final loc = AppLocalizations.of(context)!;
    final hasAny =
        weights.isNotEmpty || measurements.isNotEmpty || bodyFat.isNotEmpty;
    String cm(double v) => '${v.toStringAsFixed(1)} ${loc.unitCm}';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat.yMMMMd(loc.localeName).format(day),
              style: GoogleFonts.notoSerif(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: tc.text,
              ),
            ),
            const SizedBox(height: 16),
            if (!hasAny)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: tc.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'За этот день записей нет.',
                  style: TextStyle(fontSize: 13, color: tc.textSecondary),
                ),
              ),
            for (final w in weights)
              _DayRow(
                label: loc.weightTitle,
                value: loc.formatWeight(w.weightKg),
                icon: Icons.monitor_weight_outlined,
                color: ProgressColors.weight,
              ),
            for (final m in measurements)
              for (final (label, value) in [
                (loc.progress_meas_chest, m.chestCm),
                (loc.progress_meas_waist, m.waistCm),
                (loc.progress_meas_hips, m.hipsCm),
                (loc.progress_meas_arm, m.leftArmCm),
                (loc.progress_meas_thigh, m.leftThighCm),
                (loc.progress_meas_neck, m.neckCm),
              ])
                if (value != null)
                  _DayRow(
                    label: label,
                    value: cm(value),
                    icon: Icons.straighten,
                    color: ProgressColors.measurements,
                  ),
            for (final f in bodyFat)
              _DayRow(
                label: f.method == 'estimated'
                    ? '${loc.progressFilterBodyFat} (оценка)'
                    : loc.progressFilterBodyFat,
                value: '${f.bodyFatPercent.toStringAsFixed(1)} %',
                icon: Icons.monitor_heart_outlined,
                color: ProgressColors.bodyFat,
              ),
          ],
        ),
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: tc.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: tc.text,
            ),
          ),
        ],
      ),
    );
  }
}
