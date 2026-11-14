import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/features/food_database/domain/models/food_product.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Карточка рассчитанной порции: калории крупно и три макроса.
class FoodPortionCard extends StatelessWidget {
  final FoodPortion portion;
  final bool hasCompleteMacros;

  const FoodPortionCard({
    super.key,
    required this.portion,
    required this.hasCompleteMacros,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final loc = AppLocalizations.of(context)!;
    final note = portion.isCaloriesEstimated
        ? loc.foodKcalEstimatedNote
        : !hasCompleteMacros
        ? loc.foodMacrosIncompleteNote
        : null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${portion.isCaloriesEstimated ? '≈' : ''}${portion.calories ?? '—'}',
                style: GoogleFonts.inter(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: tc.text,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                loc.kcal,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: tc.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _MacroTile(
                label: loc.nutrientProtein,
                value: portion.proteinGrams,
              ),
              const SizedBox(width: 8),
              _MacroTile(label: loc.nutrientFat, value: portion.fatGrams),
              const SizedBox(width: 8),
              _MacroTile(label: loc.nutrientCarbs, value: portion.carbsGrams),
            ],
          ),
          if (note != null) ...[
            const SizedBox(height: 10),
            Text(
              note,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: tc.textHint,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MacroTile extends StatelessWidget {
  final String label;
  final double? value;

  const _MacroTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: tc.background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
                color: tc.inactive,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value == null
                  ? '—'
                  : AppLocalizations.of(
                      context,
                    )!.gramsValue(formatNutrient(value)),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: tc.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Предупреждение: у продукта в базе нет пищевой ценности.
class FoodNoNutritionCard extends StatelessWidget {
  const FoodNoNutritionCard({super.key});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tc.errorBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: tc.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.foodNoNutritionCard,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: tc.text,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
