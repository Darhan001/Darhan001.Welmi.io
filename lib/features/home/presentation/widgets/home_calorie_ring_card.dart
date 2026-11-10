import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/theme/theme_colors.dart';
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

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final loc = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(24),
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
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 210,
                  height: 210,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return CircularProgressIndicator(
                        value: value,
                        strokeWidth: 14,
                        backgroundColor: tc.text.withValues(alpha: 0.05),
                        color: progress > 0.8
                            ? tc.green
                            : progress > 0.5
                            ? Colors.orange
                            : tc.primary,
                        strokeCap: StrokeCap.round,
                      );
                    },
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
                    Text(
                      '$remaining',
                      style: GoogleFonts.inter(
                        fontSize: 52,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -2,
                        color: tc.text,
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
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final macro in macros)
                _MacroPill(
                  label: macro.label,
                  value: '${macro.total} / ${macro.goal}г',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroPill extends StatelessWidget {
  const _MacroPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: tc.textHint,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: tc.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: tc.divider.withValues(alpha: 0.4)),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: tc.text,
            ),
          ),
        ),
      ],
    );
  }
}
