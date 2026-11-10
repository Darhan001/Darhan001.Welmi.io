import 'package:lumina/features/meal_plan/domain/models/recipe_model.dart';

/// Тип питания в фильтре каталога.
enum RecipeDiet { vegetarian, sugarFree }

/// Ограничения каталога рецептов, выбранные в шторке фильтров.
class RecipeFilters {
  const RecipeFilters({
    this.maxCalories,
    this.minProtein,
    this.maxMinutes,
    this.diet,
  });

  final int? maxCalories;
  final int? minProtein;
  final int? maxMinutes;

  final RecipeDiet? diet;

  bool get isEmpty =>
      maxCalories == null &&
      minProtein == null &&
      maxMinutes == null &&
      diet == null;

  bool get isNotEmpty => !isEmpty;

  /// Подходит ли рецепт под выбранные ограничения.
  bool matches(Recipe recipe) {
    final calories = maxCalories;
    if (calories != null && recipe.calories > calories) return false;
    final protein = minProtein;
    if (protein != null && recipe.proteinGrams < protein) return false;
    final minutes = maxMinutes;
    if (minutes != null && recipe.cookingTimeMinutes > minutes) return false;
    if (diet == RecipeDiet.vegetarian && !recipe.isVegetarian) return false;
    if (diet == RecipeDiet.sugarFree && recipe.sugarGrams > 2) return false;
    return true;
  }
}
