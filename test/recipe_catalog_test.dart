import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumina/features/meal_plan/data/recipes_seed_data.dart';
import 'package:lumina/features/meal_plan/domain/models/recipe_model.dart';

/// Каталог рецептов: каждая запись обязана хранить собственную фотографию.
/// Эти тесты фиксируют, что фото не вычисляется по индексу и не дублируется.
void main() {
  final recipes = buildSeedRecipes();

  group('Каталог рецептов', () {
    test('не пуст и содержит уникальные id и названия', () {
      expect(recipes.length, greaterThanOrEqualTo(20));
      expect(recipes.map((r) => r.id).toSet().length, recipes.length);
      expect(recipes.map((r) => r.title).toSet().length, recipes.length);
    });

    test('у каждого рецепта есть фото, и файлы не повторяются', () {
      for (final recipe in recipes) {
        expect(recipe.imagePath, isNotNull, reason: recipe.title);
        expect(recipe.imagePath!.isNotEmpty, isTrue, reason: recipe.title);
        expect(
          recipe.imagePath!.startsWith('assets/images/recipes/'),
          isTrue,
          reason: recipe.title,
        );
      }
      final paths = recipes.map((r) => r.imagePath!).toList();
      expect(paths.toSet().length, paths.length,
          reason: 'Два блюда не должны делить одну фотографию');
    });

    test('запись TheMealDB хранит свой idMeal и своё фото', () {
      final fromApi = recipes.where((r) => r.mealDbId != null).toList();
      expect(fromApi, isNotEmpty);

      for (final recipe in fromApi) {
        final id = recipe.mealDbId!;
        expect(recipe.id, 'mealdb-$id');
        expect(
          recipe.imagePath,
          'assets/images/recipes/${id}_${_slug(recipe.imagePath!)}',
          reason: '${recipe.title}: файл фото должен начинаться с idMeal',
        );
        expect(recipe.imageUrl, contains('themealdb.com'));
      }
    });

    test('файлы фотографий существуют и являются JPEG не меньше 480 px', () {
      for (final recipe in recipes) {
        final file = File(recipe.imagePath!);
        expect(file.existsSync(), isTrue,
            reason: 'Нет файла ${recipe.imagePath} для «${recipe.title}»');
        final bytes = file.readAsBytesSync();
        expect(bytes.length, greaterThan(1024), reason: recipe.imagePath);
        expect(bytes[0], 0xFF, reason: '${recipe.imagePath} не JPEG');
        expect(bytes[1], 0xD8, reason: '${recipe.imagePath} не JPEG');

        final size = _jpegSize(bytes);
        expect(size, isNotNull, reason: 'Не удалось прочитать ${recipe.imagePath}');
        expect(size!.width, greaterThanOrEqualTo(480));
        expect(size.height, greaterThanOrEqualTo(360));
      }
    });

    test('SOURCES.md связывает каждый idMeal с файлом и strMealThumb', () {
      final sources = File('assets/images/recipes/SOURCES.md').readAsStringSync();
      for (final recipe in recipes.where((r) => r.mealDbId != null)) {
        expect(sources, contains(recipe.mealDbId!));
        expect(sources, contains(recipe.imagePath!.split('/').last));
        expect(sources, contains(recipe.imageUrl));
      }
      expect(sources, contains('syrniki.jpg'));
    });

    test('ингредиенты и шаги заполнены, шаги идут по порядку', () {
      for (final recipe in recipes) {
        expect(recipe.ingredients, isNotEmpty, reason: recipe.title);
        expect(recipe.steps, isNotEmpty, reason: recipe.title);
        for (var i = 0; i < recipe.steps.length; i++) {
          expect(recipe.steps[i].stepNumber, i + 1);
          expect(recipe.steps[i].description.trim(), isNotEmpty);
        }
        expect(recipe.servingWeightGrams, greaterThan(0), reason: recipe.title);
        expect(recipe.cookingTimeMinutes, greaterThan(0));
        expect(recipe.imageCredit, isNotNull, reason: recipe.title);
      }
    });

    test('КБЖУ согласованы с калорийностью и помечены как оценка', () {
      for (final recipe in recipes) {
        final fromMacros =
            recipe.proteinGrams * 4 + recipe.fatGrams * 9 + recipe.carbsGrams * 4;
        expect(
          (fromMacros - recipe.calories).abs(),
          lessThan(recipe.calories * .12),
          reason:
              '${recipe.title}: КБЖУ ${fromMacros.round()} против ${recipe.calories} ккал',
        );
        expect(recipe.nutritionIsEstimate, isTrue);
      }
    });

    test('JSON сохраняет idMeal, фото и массу порции', () {
      final recipe = recipes.firstWhere((r) => r.mealDbId != null);
      final restored = Recipe.fromJson(
        Map<String, dynamic>.from(recipe.toJson()),
      );
      expect(restored.mealDbId, recipe.mealDbId);
      expect(restored.title, recipe.title);
      expect(restored.imageUrl, recipe.imageUrl);
      expect(restored.imagePath, recipe.imagePath);
      expect(restored.imageCredit, recipe.imageCredit);
      expect(restored.servingWeightGrams, recipe.servingWeightGrams);
      expect(restored.nutritionIsEstimate, recipe.nutritionIsEstimate);
      expect(restored.ingredients.length, recipe.ingredients.length);
      expect(restored.steps.length, recipe.steps.length);
      expect(restored.calories, recipe.calories);
    });

    test('сортировка и фильтрация не меняют фото записи', () {
      final shuffled = [...recipes]..shuffle();
      final sorted = [...shuffled]..sort((a, b) => a.title.compareTo(b.title));
      for (final recipe in sorted) {
        final original = recipes.firstWhere((r) => r.id == recipe.id);
        expect(recipe.imagePath, original.imagePath);
        expect(recipe.imageUrl, original.imageUrl);
        expect(recipe.title, original.title);
      }
      final vegetarian = recipes.where((r) => r.isVegetarian).toList();
      for (final recipe in vegetarian) {
        expect(
          recipes.firstWhere((r) => r.id == recipe.id).imagePath,
          recipe.imagePath,
        );
      }
    });

    test('категории ссылаются на фото существующих рецептов', () {
      final paths = recipes.map((r) => r.imagePath).toSet();
      for (final category in seedRecipeCategories) {
        expect(category.imagePath, isNotNull, reason: category.name);
        expect(paths, contains(category.imagePath),
            reason: 'Категория ${category.name} показывает не фото рецепта');
      }
    });
  });
}

String _slug(String path) => path.split('/').last.split('_').skip(1).join('_');

({int width, int height})? _jpegSize(List<int> bytes) {
  var i = 2;
  while (i + 9 < bytes.length) {
    if (bytes[i] != 0xFF) return null;
    final marker = bytes[i + 1];
    final length = (bytes[i + 2] << 8) | bytes[i + 3];
    if (marker >= 0xC0 &&
        marker <= 0xCF &&
        marker != 0xC4 &&
        marker != 0xC8 &&
        marker != 0xCC) {
      final height = (bytes[i + 5] << 8) | bytes[i + 6];
      final width = (bytes[i + 7] << 8) | bytes[i + 8];
      return (width: width, height: height);
    }
    i += 2 + length;
  }
  return null;
}
