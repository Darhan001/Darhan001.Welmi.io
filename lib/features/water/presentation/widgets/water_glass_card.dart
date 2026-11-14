import 'package:flutter/material.dart';
import 'package:lumina/core/theme/app_colors.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/animated_count.dart';
import 'package:lumina/core/widgets/app_card.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// «Стакан» с уровнем воды за сегодня.
class WaterGlassCard extends StatelessWidget {
  const WaterGlassCard({
    super.key,
    required this.currentMl,
    required this.goalMl,
    required this.progress,
  });

  final int currentMl;
  final int goalMl;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final loc = AppLocalizations.of(context)!;
    final remaining = (goalMl - currentMl).clamp(0, goalMl);
    final reached = progress >= 1.0;

    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            // Раньше здесь выводилось «Осталось N ккал» — единица от калорий.
            reached ? loc.activityGoalReached : loc.waterRemainingMl(remaining),
            style: TextStyle(
              fontSize: 13,
              color: reached ? tc.success : tc.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          Semantics(
            label: '$currentMl / ${loc.waterOfGoal(goalMl)}',
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 180,
                  height: 220,
                  decoration: BoxDecoration(
                    color: tc.isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFFF0F7FF),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: tc.isDark
                          ? Colors.white10
                          : Colors.black.withValues(alpha: 0.06),
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(38),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: AnimatedContainer(
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 500),
                        curve: Curves.easeOutCubic,
                        height: 220 * progress.clamp(0.0, 1.0),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [AppColors.brand, AppColors.brandDark],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Текст по центру стакана: белый, когда вода дошла до середины,
                // иначе цвет темы (раньше белый терялся на пустом светлом стакане).
                DefaultTextStyle(
                  style: TextStyle(
                    color: progress >= 0.5 ? Colors.white : tc.text,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Число растёт вместе с уровнем воды в стакане.
                      AnimatedCount(
                        value: currentMl,
                        duration: const Duration(milliseconds: 500),
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        loc.waterOfGoal(goalMl),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
