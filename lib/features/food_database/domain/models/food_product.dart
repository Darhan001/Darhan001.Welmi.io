/// Модели базы продуктов Open Food Facts.
///
/// Пищевая ценность хранится в пересчёте на 100 г — именно в таком виде
/// значения приходят из API. Значения необязательные: у части продуктов
/// в открытой базе заполнены не все нутриенты, поэтому `null` означает
/// «данных нет», а не ноль.
library;

/// Форматирует число для интерфейса: целые — без дробной части,
/// дробные — с одним знаком. `null` отображается как «—».
String formatNutrient(double? value) {
  if (value == null) return '—';
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(1);
}

/// Граммы без лишней дробной части: 150, 150.5.
String formatGrams(double grams) {
  if (grams == grams.roundToDouble()) return grams.toStringAsFixed(0);
  return grams.toStringAsFixed(1);
}

/// Продукт из Open Food Facts с пищевой ценностью на 100 г.
class FoodProduct {
  final String barcode;
  final String name;
  final String? brand;
  final double? kcalPer100g;
  final double? proteinPer100g;
  final double? fatPer100g;
  final double? carbsPer100g;
  final String? quantity;
  final String? servingSize;
  final String? nutriscoreGrade;

  const FoodProduct({
    required this.barcode,
    required this.name,
    this.brand,
    this.kcalPer100g,
    this.proteinPer100g,
    this.fatPer100g,
    this.carbsPer100g,
    this.quantity,
    this.servingSize,
    this.nutriscoreGrade,
  });

  /// Есть хотя бы одно значение пищевой ценности.
  bool get hasNutrition =>
      kcalPer100g != null ||
      proteinPer100g != null ||
      fatPer100g != null ||
      carbsPer100g != null;

  /// Все макросы известны — можно оценить калорийность, если её нет в базе.
  bool get hasCompleteMacros =>
      proteinPer100g != null && fatPer100g != null && carbsPer100g != null;

  /// Вторая строка для списка: бренд, фасовка и Serving size.
  String get subtitle {
    final parts = <String>[
      if (brand != null && brand!.trim().isNotEmpty) brand!.trim(),
      if (quantity != null && quantity!.trim().isNotEmpty) quantity!.trim(),
      if (servingSize != null && servingSize!.trim().isNotEmpty)
        'порция ${servingSize!.trim()}',
    ];
    return parts.join(' · ');
  }

  /// Пересчёт пищевой ценности на указанную массу.
  ///
  /// Если калорийность не указана, но известны все три макроса, она
  /// оценивается по формуле Атуотера: 4×белки + 9×жиры + 4×углеводы.
  FoodPortion portionOf(double grams) {
    double? scale(double? per100) {
      if (per100 == null || grams <= 0) return null;
      return per100 * grams / 100;
    }

    final protein = scale(proteinPer100g);
    final fat = scale(fatPer100g);
    final carbs = scale(carbsPer100g);

    int? calories;
    var estimated = false;
    final kcal = scale(kcalPer100g);
    if (kcal != null) {
      calories = kcal.round();
    } else if (protein != null && fat != null && carbs != null) {
      calories = (protein * 4 + fat * 9 + carbs * 4).round();
      estimated = true;
    }

    return FoodPortion(
      grams: grams,
      calories: calories,
      proteinGrams: protein,
      fatGrams: fat,
      carbsGrams: carbs,
      isCaloriesEstimated: estimated,
    );
  }
}

/// Пищевая ценность конкретной порции.
class FoodPortion {
  final double grams;
  final int? calories;
  final double? proteinGrams;
  final double? fatGrams;
  final double? carbsGrams;

  /// Калорийность посчитана из БЖУ, а не взята из базы.
  final bool isCaloriesEstimated;

  const FoodPortion({
    required this.grams,
    this.calories,
    this.proteinGrams,
    this.fatGrams,
    this.carbsGrams,
    this.isCaloriesEstimated = false,
  });
}

/// Готовая запись для дневника: то, что возвращают поиск/сканирование
/// и что затем сохраняется в `food_entries` + `meal_items`.
class FoodDraft {
  final String name;
  final int calories;
  final double? proteinGrams;
  final double? fatGrams;
  final double? carbsGrams;

  /// Масса порции в граммах (null — масса не указана).
  final double? grams;

  /// Дополнительное описание (например, бренд).
  final String description;

  const FoodDraft({
    required this.name,
    required this.calories,
    this.proteinGrams,
    this.fatGrams,
    this.carbsGrams,
    this.grams,
    this.description = '',
  });

  /// Собирает запись из продукта и рассчитанной порции.
  factory FoodDraft.fromPortion(FoodProduct product, FoodPortion portion) {
    return FoodDraft(
      name: product.name,
      calories: portion.calories ?? 0,
      proteinGrams: portion.proteinGrams,
      fatGrams: portion.fatGrams,
      carbsGrams: portion.carbsGrams,
      grams: portion.grams,
      description: product.brand?.trim() ?? '',
    );
  }

  /// Что показываем второй строкой в дневнике: «150 г · Бренд».
  String get info {
    final parts = <String>[
      if (grams != null && grams! > 0) '${formatGrams(grams!)} г',
      if (description.trim().isNotEmpty) description.trim(),
    ];
    return parts.join(' · ');
  }
}
