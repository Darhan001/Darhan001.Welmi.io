import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/app_card.dart';
import 'package:lumina/features/progress/domain/progress_metrics.dart';
import 'package:lumina/features/progress/presentation/widgets/progress_common.dart';
import 'package:lumina/l10n/app_localizations.dart';

String bodyFatCategoryLabel(AppLocalizations loc, BodyFatCategory c) =>
    switch (c) {
      BodyFatCategory.extremelyLow => loc.bfCatExtremelyLow,
      BodyFatCategory.athletic => loc.bfCatAthletic,
      BodyFatCategory.normal => loc.bfCatNormal,
      BodyFatCategory.aboveNormal => loc.bfCatAboveNormal,
      BodyFatCategory.high => loc.bfCatHigh,
    };

/// Текущий % жира: значение, категория и шкала 5–40 %.
class BodyFatSummaryCard extends StatelessWidget {
  const BodyFatSummaryCard({super.key, required this.percent});

  final double percent;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final fraction = (percent.clamp(5, 40) - 5) / 35;
    final scaleStyle = TextStyle(fontSize: 9, color: tc.textHint);
    return AppCard(
      radius: 24,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            AppLocalizations.of(context)!.bfHeaderCaps,
            style: TextStyle(
              fontSize: 10,
              color: tc.textHint,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                percent.toStringAsFixed(1),
                style: GoogleFonts.inter(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: tc.text,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '%',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: tc.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: ProgressColors.weight.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              bodyFatCategoryLabel(
                AppLocalizations.of(context)!,
                bodyFatCategory(percent),
              ),
              style: const TextStyle(
                color: ProgressColors.weight,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                Container(height: 12, color: tc.text.withValues(alpha: 0.08)),
                FractionallySizedBox(
                  widthFactor: fraction,
                  child: Container(
                    height: 12,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF75A47F),
                          Color(0xFFFF9800),
                          Color(0xFFE53935),
                        ],
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(6)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final mark in const ['5%', '15%', '25%', '40%+'])
                Text(mark, style: scaleStyle),
            ],
          ),
        ],
      ),
    );
  }
}
