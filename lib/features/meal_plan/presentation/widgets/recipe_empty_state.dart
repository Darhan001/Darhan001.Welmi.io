import 'package:flutter/material.dart';
import 'package:lumina/core/theme/theme_colors.dart';

/// Ничего не нашлось (или рецептов ещё нет).
class RecipeEmptyState extends StatelessWidget {
  const RecipeEmptyState({
    super.key,
    required this.hasFilters,
    required this.onReset,
  });

  final bool hasFilters;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 44, color: tc.textSecondary),
            const SizedBox(height: 12),
            Text(
              hasFilters
                  ? 'Ничего не найдено.\nПопробуйте изменить запрос или фильтры.'
                  : 'Рецепты скоро появятся.',
              textAlign: TextAlign.center,
              style: TextStyle(color: tc.textSecondary, height: 1.4),
            ),
            if (hasFilters) ...[
              const SizedBox(height: 8),
              TextButton(onPressed: onReset, child: const Text('Сбросить')),
            ],
          ],
        ),
      ),
    );
  }
}
