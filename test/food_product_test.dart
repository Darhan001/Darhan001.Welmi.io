import 'package:flutter_test/flutter_test.dart';
import 'package:lumina/features/food_database/data/open_food_facts_service.dart';
import 'package:lumina/features/food_database/domain/models/food_product.dart';

void main() {
  group('Open Food Facts: парсинг', () {
    test('результат поиска: бренд-массив и все нутриенты', () {
      final product = OpenFoodFactsService.parseSearchHit({
        'code': '4630250260075',
        'product_name': 'Молоко 1,5',
        'brands': ['Правильное молоко'],
        'nutriments': {
          'energy-kcal_100g': 44,
          'proteins_100g': 3,
          'fat_100g': 1.5,
          'carbohydrates_100g': 4.7,
        },
      });

      expect(product, isNotNull);
      expect(product!.barcode, '4630250260075');
      expect(product.name, 'Молоко 1,5');
      expect(product.brand, 'Правильное молоко');
      expect(product.kcalPer100g, 44);
      expect(product.proteinPer100g, 3);
      expect(product.fatPer100g, 1.5);
      expect(product.carbsPer100g, 4.7);
      expect(product.hasCompleteMacros, isTrue);
    });

    test('результат без названия отбрасывается', () {
      final product = OpenFoodFactsService.parseSearchHit({
        'code': '12345678',
        'nutriments': {'energy-kcal_100g': 100},
      });
      expect(product, isNull);
    });

    test('продукт по штрихкоду: килоджоули переводятся в ккал', () {
      final product = OpenFoodFactsService.parseProduct({
        'code': '3017620422003',
        'product_name': 'Nutella',
        'brands': 'Nutella, Ferrero',
        'nutriments': {
          'energy-kj_100g': 2252,
          'proteins_100g': 6.3,
          'fat_100g': 30.9,
          'carbohydrates_100g': 57.5,
        },
      });

      expect(product, isNotNull);
      expect(product!.brand, 'Nutella');
      expect(product.kcalPer100g, closeTo(2252 / 4.184, 0.001));
      expect(product.hasNutrition, isTrue);
    });

    test('продукт без названия получает запасное имя со штрихкодом', () {
      final product = OpenFoodFactsService.parseProduct(
        {'code': '4000000000000'},
        fallbackBarcode: '4000000000000',
      );

      expect(product, isNotNull);
      expect(product!.name, contains('4000000000000'));
      expect(product.hasNutrition, isFalse);
    });

    test('неполные данные: отсутствующие нутриенты остаются null', () {
      final product = OpenFoodFactsService.parseProduct({
        'code': '111',
        'product_name': 'Вода',
        'nutriments': {'proteins_100g': 0},
      });

      expect(product!.kcalPer100g, isNull);
      expect(product.fatPer100g, isNull);
      expect(product.carbsPer100g, isNull);
      expect(product.proteinPer100g, 0);
      expect(product.portionOf(100).calories, isNull);
    });
  });

  group('Пересчёт порции', () {
    const product = FoodProduct(
      barcode: '1',
      name: 'Тест',
      kcalPer100g: 250,
      proteinPer100g: 10,
      fatPer100g: 5,
      carbsPer100g: 30,
    );

    test('150 г масштабируются от значений на 100 г', () {
      final portion = product.portionOf(150);

      expect(portion.calories, 375);
      expect(portion.proteinGrams, closeTo(15, 0.0001));
      expect(portion.fatGrams, closeTo(7.5, 0.0001));
      expect(portion.carbsGrams, closeTo(45, 0.0001));
      expect(portion.isCaloriesEstimated, isFalse);
    });

    test('калорийность оценивается из БЖУ, если её нет в базе', () {
      const withoutKcal = FoodProduct(
        barcode: '2',
        name: 'Без калорий',
        proteinPer100g: 10,
        fatPer100g: 5,
        carbsPer100g: 20,
      );
      final portion = withoutKcal.portionOf(100);

      // 4×10 + 9×5 + 4×20 = 165
      expect(portion.calories, 165);
      expect(portion.isCaloriesEstimated, isTrue);
    });

    test('нулевая масса не даёт отрицательных значений', () {
      final portion = product.portionOf(0);

      expect(portion.calories, isNull);
      expect(portion.proteinGrams, isNull);
      expect(portion.fatGrams, isNull);
      expect(portion.carbsGrams, isNull);
    });
  });

  group('Форматирование', () {
    test('целые и дробные значения', () {
      expect(formatNutrient(44), '44');
      expect(formatNutrient(1.5), '1.5');
      expect(formatNutrient(null), '—');
      expect(formatGrams(150), '150');
      expect(formatGrams(150.5), '150.5');
    });

    test('FoodDraft.info содержит граммы и бренд', () {
      const draft = FoodDraft(
        name: 'Молоко',
        calories: 100,
        grams: 150,
        description: 'Бренд',
      );
      expect(draft.info, '150 г · Бренд');
    });
  });
}
