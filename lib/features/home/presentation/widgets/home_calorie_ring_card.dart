import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/theme/app_tokens.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/animated_count.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Сколько макроса съедено из нормы.
class HomeMacroValue {
  const HomeMacroValue({
    required this.label,
    required this.total,
    required this.goal,
  });

  final String label;
  final int total;
  final int goal;

  /// Доля нормы (0…1); без нормы — 0, чтобы не делить на ноль.
  double get progress => goal > 0 ? (total / goal).clamp(0.0, 1.0) : 0.0;
}

/// Кольцо калорий и макросы за день.
class HomeCalorieRingCard extends StatelessWidget {
  const HomeCalorieRingCard({
    super.key,
    required this.remaining,
    required this.goal,
    required this.progress,
    required this.macros,
  });

  final int remaining;
  final int goal;

  /// Доля съеденного от нормы (0…1 и выше).
  final double progress;
  final List<HomeMacroValue> macros;

  static const _ringDuration = Duration(milliseconds: 900);

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final loc = AppLocalizations.of(context)!;
    final tokens = AppTokens.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final ringColor = progress > 0.8
        ? tc.green
        : progress > 0.5
        ? tc.warning
        : tc.primary;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        boxShadow: [
          BoxShadow(
            color: tc.shadow(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Semantics(
            container: true,
            label: '${loc.remaining}: $remaining. ${loc.ofKcal(goal)}',
            child: ExcludeSemantics(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 210,
                    height: 210,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
                      duration: reduceMotion ? Duration.zero : _ringDuration,
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) => CircularProgressIndicator(
                        value: value,
                        strokeWidth: 14,
                        backgroundColor: tc.text.withValues(alpha: 0.05),
                        color: ringColor,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        loc.remaining,
                        style: TextStyle(
                          fontSize: 14,
                          color: tc.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      AnimatedCount(
                        value: remaining,
                        duration: _ringDuration,
                        style: GoogleFonts.inter(
                          fontSize: 52,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -2,
                          color: tc.text,
                          // Цифры одной ширины: число не «дрожит» при счёте.
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        loc.ofKcal(goal),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: tc.textHint,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < macros.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(
                  child: _MacroBar(
                    macro: macros[i],
                    value: loc.macroOfGoalGrams(
                      macros[i].total,
                      macros[i].goal,
                    ),
                    reduceMotion: reduceMotion,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Макрос: подпись, «съедено / норма» и полоса прогресса.
class _MacroBar extends StatelessWidget {
  const _MacroBar({
    required this.macro,
    required this.value,
    required this.reduceMotion,
  });

  final HomeMacroValue macro;
  final String value;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    return Semantics(
      container: true,
      label: '${macro.label}: $value',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              macro.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: tc.textHint,
              ),
            ),
            const SizedBox(height: 6),
            // Подпись не переносится и не вылезает за колонку на узких
            // экранах и при увеличенном шрифте — уменьшается целиком.
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: tc.text,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: macro.progress),
                duration: reduceMotion
                    ? Duration.zero
                    : HomeCalorieRingCard._ringDuration,
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => LinearProgressIndicator(
                  value: v,
                  minHeight: 6,
                  backgroundColor: tc.text.withValues(alpha: 0.06),
                  color: tc.green,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
