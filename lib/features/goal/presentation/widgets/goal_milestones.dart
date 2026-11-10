import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lumina/core/models/supabase_models.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/app_card.dart';
import 'package:lumina/core/widgets/units_format.dart';
import 'package:lumina/features/goal/domain/goal_progress.dart';
import 'package:lumina/l10n/app_localizations.dart';

class _Milestone {
  const _Milestone(
    this.label,
    this.date, {
    this.done = true,
    this.isStart = false,
  });

  final String label;
  final String date;
  final bool done;
  final bool isStart;
}

/// Вехи прогресса: последние записи веса по порядку и цель.
class GoalMilestones extends StatelessWidget {
  const GoalMilestones({
    super.key,
    required this.entries,
    required this.progress,
  });

  /// Записи веса от новых к старым (как в [UserDataService]).
  final List<WeightEntry> entries;
  final GoalProgress progress;

  List<_Milestone> _build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final df = DateFormat.MMMd(Localizations.localeOf(context).toString());
    // Последние 5 записей в хронологическом порядке. Раньше список шёл от
    // новых к старым, а отметку «Старт» получала самая свежая запись.
    final recent = entries.take(5).toList().reversed;
    final list = [
      for (final e in recent)
        _Milestone(
          loc.formatWeight(e.weightKg),
          df.format(e.date),
          isStart: identical(e, entries.last),
        ),
    ];
    // Цель показываем и для набора массы, а не только для похудения.
    if (progress.hasWeightGoal && progress.remainingKg > 0) {
      final days = progress.estimatedDaysToGoal;
      list.add(
        _Milestone(
          '${loc.formatWeight(progress.goalKg)} 🎯',
          days > 0 ? loc.goalDaysToGoal(days) : loc.goalWeight,
          done: false,
        ),
      );
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final milestones = _build(context);
    if (milestones.isEmpty) return const SizedBox.shrink();
    final tc = ThemeColors.of(context);
    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.milestones,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: tc.text,
            ),
          ),
          const SizedBox(height: 20),
          for (var i = 0; i < milestones.length; i++)
            _MilestoneRow(
              milestone: milestones[i],
              isFirst: i == 0,
              isLast: i == milestones.length - 1,
            ),
        ],
      ),
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  const _MilestoneRow({
    required this.milestone,
    required this.isFirst,
    required this.isLast,
  });

  final _Milestone milestone;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final done = milestone.done;
    final lineColor = done ? tc.green : tc.text.withValues(alpha: 0.08);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(width: isFirst ? 0 : 2, height: 8, color: lineColor),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? tc.green : tc.card,
                    border: Border.all(
                      color: done ? tc.green : tc.text.withValues(alpha: 0.15),
                      width: 2,
                    ),
                  ),
                  child: done
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : null,
                ),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: lineColor)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    milestone.label,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: done ? FontWeight.w800 : FontWeight.w600,
                      color: done ? tc.text : tc.textHint,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    milestone.date,
                    style: TextStyle(
                      fontSize: 11,
                      color: tc.textHint,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (milestone.isStart)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: tc.successBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                AppLocalizations.of(context)!.start,
                style: TextStyle(
                  color: tc.green,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
