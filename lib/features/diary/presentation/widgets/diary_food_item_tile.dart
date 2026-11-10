import 'package:flutter/material.dart';
import 'package:lumina/core/models/supabase_models.dart';
import 'package:lumina/core/theme/theme_colors.dart';

/// Строка продукта в приёме пищи. Нажатие открывает действия с записью.
class DiaryFoodItemTile extends StatelessWidget {
  final MealItem item;
  final VoidCallback onTap;

  const DiaryFoodItemTile({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final info = item.info ?? '';

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: tc.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.restaurant_rounded,
                size: 20,
                color: tc.inactive,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: tc.text,
                    ),
                  ),
                  if (info.isNotEmpty)
                    Text(
                      info,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: tc.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              '${item.calories}',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: tc.text,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.more_horiz_rounded, size: 16, color: tc.inactive),
          ],
        ),
      ),
    );
  }
}
