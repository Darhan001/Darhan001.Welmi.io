import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/features/food_database/domain/models/food_product.dart';

/// Карточка продукта в результатах поиска: название, бренд, БЖУ и ккал/100 г.
class ProductResultCard extends StatelessWidget {
  final FoodProduct product;
  final VoidCallback onTap;

  const ProductResultCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  String get _macrosLine {
    if (!product.hasNutrition) return 'Нет данных о пищевой ценности';
    final macros = <String>[
      if (product.proteinPer100g != null)
        'Б ${formatNutrient(product.proteinPer100g)}',
      if (product.fatPer100g != null) 'Ж ${formatNutrient(product.fatPer100g)}',
      if (product.carbsPer100g != null)
        'У ${formatNutrient(product.carbsPer100g)}',
    ];
    return macros.isEmpty ? 'Калорийность без БЖУ' : macros.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: tc.shadow(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: tc.card,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: tc.text,
                        ),
                      ),
                      if (product.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          product.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: tc.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        _macrosLine,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: product.hasNutrition ? tc.green : tc.error,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatNutrient(product.kcalPer100g),
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: tc.text,
                      ),
                    ),
                    Text(
                      'ккал / 100 г',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: tc.textHint,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, color: tc.inactive),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
