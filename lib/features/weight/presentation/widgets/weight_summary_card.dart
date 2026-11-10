import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/theme/app_colors.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/units_format.dart';
import 'package:lumina/features/weight/presentation/widgets/weight_cards.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Текущий вес, старт, цель и прогресс к цели.
class WeightSummaryCard extends StatelessWidget {
  const WeightSummaryCard({
    super.key,
    required this.current,
    required this.start,
    required this.goal,
  });

  final double current;
  final double start;
  final double goal;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final loc = AppLocalizations.of(context)!;
    final loss = start - current;
    final hasGoal = goal > 0 && start > goal;
    final progress = hasGoal
        ? ((start - current) / (start - goal)).clamp(0.0, 1.0)
        : 0.0;
    final trend = weightTrendColor(loss > 0);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: weightCardDecoration(tc, 32, 0.04),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Info(loc.startWeight, loc.formatWeight(start)),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: trend.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      loss > 0 ? Icons.arrow_downward : Icons.arrow_upward,
                      size: 14,
                      color: trend,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      // Направление показывает стрелка рядом, поэтому выводим модуль:
                      // раньше при наборе веса получалось «+-1.2 кг».
                      loc.formatWeight(loss.abs()),
                      style: TextStyle(
                        color: trend,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              _Info(loc.goalWeight, loc.formatWeight(goal)),
            ],
          ),
          const SizedBox(height: 24),
          // Число — в единицах пользователя (раньше всегда в кг).
          Text(
            loc.weightValue(current),
            style: GoogleFonts.inter(
              fontSize: 56,
              fontWeight: FontWeight.w900,
              color: tc.text,
            ),
          ),
          Text(
            loc.currentWeightUnit(loc.weightUnitLabel),
            style: TextStyle(
              fontSize: 12,
              color: tc.textHint,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (hasGoal) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: tc.text.withValues(alpha: 0.05),
                color: AppColors.brand,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              loc.percentToGoal((progress * 100).toStringAsFixed(0)),
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.brand,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
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
