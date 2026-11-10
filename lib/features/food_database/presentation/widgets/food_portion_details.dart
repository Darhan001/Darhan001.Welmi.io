import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/features/food_database/domain/models/food_product.dart';

/// «На 100 г: 250 ккал · Б 10 г · Ж 5 г · У 30 г».
String per100Label(FoodProduct product) {
  if (!product.hasNutrition) return 'Пищевая ценность: нет данных';
  final parts = <String>[
    if (product.kcalPer100g != null)
      '${formatNutrient(product.kcalPer100g)} ккал',
    if (product.proteinPer100g != null)
      'Б ${formatNutrient(product.proteinPer100g)} г',
    if (product.fatPer100g != null) 'Ж ${formatNutrient(product.fatPer100g)} г',
    if (product.carbsPer100g != null)
      'У ${formatNutrient(product.carbsPer100g)} г',
  ];
  return 'На 100 г: ${parts.join(' · ')}';
}

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
    final note = portion.isCaloriesEstimated
        ? 'Калорийность рассчитана из БЖУ: в базе её нет.'
        : !hasCompleteMacros
        ? 'В базе заполнены не все нутриенты — «—» означает «нет данных».'
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
                'ккал',
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
              _MacroTile(label: 'Белки', value: portion.proteinGrams),
              const SizedBox(width: 8),
              _MacroTile(label: 'Жиры', value: portion.fatGrams),
              const SizedBox(width: 8),
              _MacroTile(label: 'Углеводы', value: portion.carbsGrams),
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
              value == null ? '—' : '${formatNutrient(value)} г',
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
              'В Open Food Facts у этого продукта нет пищевой ценности. '
              'Добавь запись вручную из дневника.',
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
