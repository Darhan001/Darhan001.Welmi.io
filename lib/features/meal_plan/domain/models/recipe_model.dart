/// Модель ингредиента рецепта
class RecipeIngredient {
  final String name;
  final String amount;
  final int calories;

  const RecipeIngredient({
    required this.name,
    required this.amount,
    required this.calories,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'amount': amount,
    'calories': calories,
  };

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) =>
      RecipeIngredient(
        name: json['name'] as String? ?? '',
        amount: json['amount'] as String? ?? '',
        calories: (json['calories'] as num?)?.toInt() ?? 0,
      );
}

/// Модель шага приготовления
class RecipeStep {
  final int stepNumber;
  final String description;
  final int? timerMinutes;

  const RecipeStep({
    required this.stepNumber,
    required this.description,
    this.timerMinutes,
  });

  Map<String, dynamic> toJson() => {
    'step_number': stepNumber,
    'description': description,
    if (timerMinutes != null) 'timer_minutes': timerMinutes,
  };

  factory RecipeStep.fromJson(Map<String, dynamic> json) => RecipeStep(
    stepNumber: (json['step_number'] as num?)?.toInt() ?? 1,
    description: json['description'] as String? ?? '',
    timerMinutes: (json['timer_minutes'] as num?)?.toInt(),
  );
}

/// Категория рецепта
class RecipeCategory {
  final String id;
  final String name;
  final String iconUrl;
  final String? imageUrl;
  final String? imagePath;

  const RecipeCategory({
    required this.id,
    required this.name,
    required this.iconUrl,
    this.imageUrl,
    this.imagePath,
  });
}

/// Основная модель рецепта
///
/// Фотография — часть записи: `imageUrl`/`imagePath` описывают именно это блюдо
/// (`title`), а `mealDbId` — idMeal из TheMealDB, к которому относится фото.
/// Ни один экран не должен вычислять картинку по индексу элемента в списке.
class Recipe {
  final String id;

  /// idMeal в TheMealDB. `null` — блюдо из собственного проверенного набора
  /// (например, сырники, которых в TheMealDB нет).
  final String? mealDbId;
  final String title;
  final String imageUrl;
  final String? imagePath;

  /// Атрибуция фотографии (лицензия требует указания автора).
  final String? imageCredit;
  final String category; // 'breakfast', 'lunch', 'dinner', 'snack', 'dessert'
  final String description;
  final int calories;
  final double proteinGrams;
  final double fatGrams;
  final double carbsGrams;
  final double fiberGrams;
  final double sugarGrams;
  final double sodiumMg;
  final int cookingTimeMinutes;
  final int servings;
  final int servingWeightGrams;

  /// КБЖУ на порцию — оценка по составу рецепта. TheMealDB не публикует
  /// пищевую ценность, поэтому значение нельзя выдавать за данные API.
  final bool nutritionIsEstimate;
  final List<String> tags;
  final List<RecipeIngredient> ingredients;
  final List<RecipeStep> steps;
  final bool isVegetarian;
  final bool isHighProtein;
  final bool isLowCalorie;
  final bool isQuick;

  const Recipe({
    required this.id,
    this.mealDbId,
    required this.title,
    required this.imageUrl,
    this.imagePath,
    this.imageCredit,
    required this.category,
    this.description = '',
    required this.calories,
    required this.proteinGrams,
    required this.fatGrams,
    required this.carbsGrams,
    this.fiberGrams = 2.0,
    this.sugarGrams = 2.0,
    this.sodiumMg = 200.0,
    required this.cookingTimeMinutes,
    this.servings = 1,
    this.servingWeightGrams = 0,
    this.nutritionIsEstimate = true,
    this.tags = const [],
    required this.ingredients,
    required this.steps,
    this.isVegetarian = false,
    this.isHighProtein = false,
    this.isLowCalorie = false,
    this.isQuick = false,
  });

  /// Прозрачная формула оценки питательности от 0 до 100
  /// Базируется на плотности белка, клетчатке, балансе калорийности и умеренном количестве сахара/натрия
  int get nutritionScore {
    double score = 50.0;

    // Бонус за белок (до +25)
    final proteinRatio = calories > 0 ? (proteinGrams * 4.0) / calories : 0.0;
    if (proteinRatio >= 0.3) {
      score += 25;
    } else if (proteinRatio >= 0.2) {
      score += 18;
    } else if (proteinRatio >= 0.12) {
      score += 10;
    }

    // Бонус за клетчатку (до +15)
    if (fiberGrams >= 6.0) {
      score += 15;
    } else if (fiberGrams >= 3.0) {
      score += 10;
    } else if (fiberGrams >= 1.5) {
      score += 5;
    }

    // Штраф за добавленный сахар
    if (sugarGrams > 20.0) {
      score -= 15;
    } else if (sugarGrams > 10.0) {
      score -= 8;
    } else {
      score += 5; // мало сахара
    }

    // Штраф за избыток натрия
    if (sodiumMg > 900.0) {
      score -= 12;
    } else if (sodiumMg > 500.0) {
      score -= 5;
    } else {
      score += 5;
    }

    return score.round().clamp(25, 98);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'mealdb_id': mealDbId,
    'title': title,
    'image_url': imageUrl,
    'image_path': imagePath,
    'image_credit': imageCredit,
    'category': category,
    'description': description,
    'calories': calories,
    'protein_grams': proteinGrams,
    'fat_grams': fatGrams,
    'carbs_grams': carbsGrams,
    'fiber_grams': fiberGrams,
    'sugar_grams': sugarGrams,
    'sodium_mg': sodiumMg,
    'cooking_time_minutes': cookingTimeMinutes,
    'servings': servings,
    'serving_weight_grams': servingWeightGrams,
    'nutrition_is_estimate': nutritionIsEstimate,
    'tags': tags,
    'ingredients': ingredients.map((e) => e.toJson()).toList(),
    'steps': steps.map((e) => e.toJson()).toList(),
    'is_vegetarian': isVegetarian,
    'is_high_protein': isHighProtein,
    'is_low_calorie': isLowCalorie,
    'is_quick': isQuick,
  };

  factory Recipe.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    final rawIng = json['ingredients'] as List? ?? [];
    final rawSteps = json['steps'] as List? ?? [];

    return Recipe(
      id: json['id']?.toString() ?? '',
      mealDbId: json['mealdb_id']?.toString(),
      title: json['title'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      imagePath: json['image_path'] as String?,
      imageCredit: json['image_credit'] as String?,
      category: json['category'] as String? ?? 'breakfast',
      description: json['description'] as String? ?? '',
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      proteinGrams: toDouble(json['protein_grams']),
      fatGrams: toDouble(json['fat_grams']),
      carbsGrams: toDouble(json['carbs_grams']),
      fiberGrams: toDouble(json['fiber_grams'] ?? 2.0),
      sugarGrams: toDouble(json['sugar_grams'] ?? 2.0),
      sodiumMg: toDouble(json['sodium_mg'] ?? 200.0),
      cookingTimeMinutes: (json['cooking_time_minutes'] as num?)?.toInt() ?? 20,
      servings: (json['servings'] as num?)?.toInt() ?? 1,
      servingWeightGrams:
          (json['serving_weight_grams'] as num?)?.toInt() ?? 0,
      nutritionIsEstimate: json['nutrition_is_estimate'] != false,
      tags:
          (json['tags'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      ingredients: rawIng
          .map(
            (e) =>
                RecipeIngredient.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      steps: rawSteps
          .map((e) => RecipeStep.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      isVegetarian: json['is_vegetarian'] == true,
      isHighProtein: json['is_high_protein'] == true,
      isLowCalorie: json['is_low_calorie'] == true,
      isQuick: json['is_quick'] == true,
    );
  }
}
