import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/theme/app_colors.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Две карточки: цель по шагам и процент выполнения.
class ActivityStatsRow extends StatelessWidget {
  const ActivityStatsRow({super.key, required this.steps, required this.goal});

  final int steps;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final percent = goal > 0 ? (steps / goal * 100).toStringAsFixed(0) : '0';
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: loc.activityGoal,
            value: loc.activityGoalSteps(goal),
            icon: Icons.flag_rounded,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: loc.progressTitle,
            value: '$percent%',
            icon: Icons.trending_up,
            color: AppColors.brand,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(tc),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: tc.text,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: tc.textHint,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _cardDecoration(ThemeColors tc) => BoxDecoration(
  color: tc.card,
  borderRadius: BorderRadius.circular(20),
  boxShadow: [
    BoxShadow(
      color: tc.shadow(0.03),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ],
);

/// Карточка синхронизации с Google Fit / Apple Health.
class HealthSyncCard extends StatelessWidget {
  const HealthSyncCard({
    super.key,
    required this.syncing,
    required this.onSync,
  });

  final bool syncing;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final loc = AppLocalizations.of(context)!;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: syncing ? null : onSync,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(tc),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: tc.isDark ? tc.surface : AppColors.brandLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.monitor_heart_outlined,
                  size: 22,
                  color: AppColors.brand,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Google Fit / Apple Health',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: tc.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      loc.activityHealthSubtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: tc.textHint,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (syncing)
                const Padding(
                  padding: EdgeInsets.all(6),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: tc.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.sync_rounded,
                        size: 15,
                        color: tc.textOnPrimary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        loc.activitySyncShort,
                        style: TextStyle(
                          color: tc.textOnPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
