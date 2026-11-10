import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/features/meal_plan/domain/recipe_filters.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Показывает шторку фильтров.
///
/// Возвращает новые фильтры, `const RecipeFilters()` при сбросе или `null`,
/// если шторку закрыли без применения.
Future<RecipeFilters?> showRecipeFiltersSheet(
  BuildContext context, {
  required RecipeFilters current,
}) {
  final tc = ThemeColors.of(context);
  final loc = AppLocalizations.of(context)!;

  return showModalBottomSheet<RecipeFilters>(
    context: context,
    isScrollControlled: true,
    backgroundColor: tc.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) {
      var calories = current.maxCalories;
      var protein = current.minProtein;
      var minutes = current.maxMinutes;
      var diet = current.diet;

      return StatefulBuilder(
        builder: (context, setSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: tc.divider,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  loc.filtersTitle,
                  style: GoogleFonts.notoSerif(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: tc.text,
                  ),
                ),
                const SizedBox(height: 12),
                _FilterChoice<int>(
                  title: loc.nutrientCalories,
                  formatValue: loc.filterUpToKcal,
                  selected: calories,
                  values: const [300, 500, 700],
                  onSelect: (v) => setSheet(() => calories = v),
                ),
                _FilterChoice<int>(
                  title: loc.recipeFilterProteinFrom,
                  formatValue: loc.filterFromGrams,
                  selected: protein,
                  values: const [20, 30, 40],
                  onSelect: (v) => setSheet(() => protein = v),
                ),
                _FilterChoice<int>(
                  title: loc.recipeFilterTimeUpTo,
                  formatValue: loc.filterUpToMinutes,
                  selected: minutes,
                  values: const [20, 30, 45],
                  onSelect: (v) => setSheet(() => minutes = v),
                ),
                _FilterChoice<RecipeDiet>(
                  title: loc.recipeFilterDiet,
                  selected: diet,
                  values: RecipeDiet.values,
                  formatValue: (value) => switch (value) {
                    RecipeDiet.vegetarian => loc.recipeDietVegetarian,
                    RecipeDiet.sugarFree => loc.recipeDietSugarFree,
                  },
                  onSelect: (v) => setSheet(() => diet = v),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(sheetContext, const RecipeFilters()),
                      child: Text(loc.resetAction),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () => Navigator.pop(
                        sheetContext,
                        RecipeFilters(
                          maxCalories: calories,
                          minProtein: protein,
                          maxMinutes: minutes,
                          diet: diet,
                        ),
                      ),
                      child: Text(loc.showAction),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Группа вариантов одного фильтра: «Любое» и значения.
class _FilterChoice<T> extends StatelessWidget {
  const _FilterChoice({
    required this.title,
    required this.selected,
    required this.values,
    required this.onSelect,
    required this.formatValue,
  });

  final String title;
  final T? selected;
  final List<T> values;
  final ValueChanged<T?> onSelect;
  final String Function(T value) formatValue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: Text(AppLocalizations.of(context)!.anyOption),
                selected: selected == null,
                onSelected: (_) => onSelect(null),
              ),
              ...values.map(
                (value) => ChoiceChip(
                  label: Text(formatValue(value)),
                  selected: selected == value,
                  onSelected: (_) => onSelect(selected == value ? null : value),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
