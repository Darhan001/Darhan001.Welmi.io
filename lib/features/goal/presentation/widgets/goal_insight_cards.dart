import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/app_card.dart';
import 'package:lumina/core/widgets/units_format.dart';
import 'package:lumina/features/goal/domain/goal_progress.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Две карточки: средний темп и прогноз дней до цели.
class GoalDailyStats extends StatelessWidget {
  const GoalDailyStats({super.key, required this.progress});

  final GoalProgress progress;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final loc = AppLocalizations.of(context)!;
    final pace = progress.averagePace;
    // TODO(l10n): суффикс «/день» — нужен ключ локализации (см. отчёт).
    final paceText = pace == null
        ? '—'
        : '${pace.isPlanned ? '≈' : ''}${loc.formatWeight(pace.kgPerDay, decimals: 2)}/день';
    final days = progress.estimatedDaysToGoal;
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: loc.avgPerDay,
            value: paceText,
            icon: Icons.trending_down,
            color: tc.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: loc.daysRemaining,
            value: days > 0 ? '$days' : '—',
            icon: Icons.calendar_today,
            color: Colors.blueGrey,
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
    return AppCard(
      child: Column(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: tc.textHint,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Текст подсказки Welmi AI из локализации.
String goalInsightText(AppLocalizations loc, GoalProgress? progress) {
  if (progress == null) return loc.aiInsightFillProfile;
  return switch (progress.insight) {
    GoalInsight.startTracking => loc.aiInsightStartTracking,
    GoalInsight.greatPace => loc.aiInsightGreatPace(
      progress.estimatedDaysToGoal,
    ),
    GoalInsight.almostThere => loc.aiInsightAlmostThere,
    GoalInsight.steadyProgress => loc.aiInsightSteadyProgress,
    GoalInsight.slowProgress => loc.aiInsightSlowProgress,
    GoalInsight.onTrack => loc.aiInsightOnTrack,
  };
}

/// Карточка с подсказкой Welmi AI.
class GoalInsightCard extends StatelessWidget {
  const GoalInsightCard({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return AppCard(
      color: tc.isDark ? const Color(0xFF1E281E) : tc.successBg,
      shadow: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: tc.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.auto_awesome, color: tc.green, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welmi AI',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: tc.isDark ? tc.success : tc.greenDark,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 13,
                    color: tc.text,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
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

/// Мотивационная цитата дня.
class GoalMotivationCard extends StatelessWidget {
  const GoalMotivationCard({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final quotes = [
      loc.motivationQuote1,
      loc.motivationQuote2,
      loc.motivationQuote3,
      loc.motivationQuote4,
      loc.motivationQuote5,
    ];
    final quote = quotes[DateTime.now().day % quotes.length];
    final tc = ThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [tc.greenDark, tc.green],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: tc.green.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                loc.motivation,
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            quote,
            style: GoogleFonts.notoSerif(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Welmi',
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
