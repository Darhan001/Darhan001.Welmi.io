import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/models/supabase_models.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/app_card.dart';
import 'package:lumina/core/widgets/units_format.dart';
import 'package:lumina/features/goal/domain/goal_progress.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Карточка «Тип цели» с кратким статусом пути.
class GoalTypeCard extends StatelessWidget {
  const GoalTypeCard({super.key, required this.progress});

  final GoalProgress progress;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final loc = AppLocalizations.of(context)!;
    final goal = progress.goal;
    final goalLabel = switch (goal) {
      GoalType.loseWeight => loc.goalWeightLoss,
      GoalType.gainWeight => loc.goalGainWeight,
      GoalType.maintainWeight => loc.goalMaintain,
      null => loc.goalNotSelected,
    };
    final days = progress.estimatedDaysToGoal;
    final subtitle = goal == null
        ? loc.goalTapToSelect
        : goal == GoalType.maintainWeight
        ? loc.goalMaintainDesc
        : days > 0
        ? loc.goalDaysToGoal(days)
        : progress.daysIn > 0
        ? loc.goalDaysSinceStart(progress.daysIn)
        : loc.goalTargetWeight(loc.formatWeight(progress.goalKg));

    return AppCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: tc.successBg,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Icons.fitness_center, color: tc.green, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.goalTypeLabel,
                  style: TextStyle(
                    fontSize: 10,
                    color: tc.textHint,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  goalLabel,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: tc.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: tc.textHint),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
