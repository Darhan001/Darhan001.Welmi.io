/// Результат расчёта AI — персональный план питания
class AiNutritionPlan {
  final int dailyCalories;
  final int proteinGrams;
  final int fatGrams;
  final int carbGrams;
  final int waterMlGoal;
  final int tdee;
  final int bmr;
  final String mealSuggestion;

  AiNutritionPlan({
    required this.dailyCalories,
    required this.proteinGrams,
    required this.fatGrams,
    required this.carbGrams,
    this.waterMlGoal = 2000,
    this.tdee = 0,
    this.bmr = 0,
    this.mealSuggestion = '',
  });

  factory AiNutritionPlan.fromJson(Map<String, dynamic> json) {
    int getInt(List<String> keys, [int fallback = 0]) {
      for (final k in keys) {
        if (json.containsKey(k) && json[k] != null) {
          final v = json[k];
          if (v is num) return v.toInt();
          return int.tryParse(v.toString()) ?? fallback;
        }
      }
      return fallback;
    }

    return AiNutritionPlan(
      dailyCalories: getInt(['daily_calories', 'calories', 'калории'], 2000),
      proteinGrams: getInt(['protein_grams', 'protein', 'белки'], 120),
      fatGrams: getInt(['fat_grams', 'fat', 'жиры'], 60),
      carbGrams: getInt(['carb_grams', 'carbs', 'углеводы'], 200),
      waterMlGoal: getInt(['water_ml_goal', 'water', 'вода'], 2000),
      tdee: getInt(['tdee'], 0),
      bmr: getInt(['bmr'], 0),
      mealSuggestion: json['meal_suggestion']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'daily_calories': dailyCalories,
    'protein_grams': proteinGrams,
    'fat_grams': fatGrams,
    'carb_grams': carbGrams,
    'water_ml_goal': waterMlGoal,
    'tdee': tdee,
    'bmr': bmr,
    'meal_suggestion': mealSuggestion,
  };

  /// План по формуле Mifflin-St Jeor — когда AI недоступен.
  factory AiNutritionPlan.mifflinStJeor({
    required double heightCm,
    required double currentWeightKg,
    required int age,
    required String gender,
    required String goal,
    required String activityLevel,
    required double goalSpeedKgPerWeek,
  }) {
    final isMale = gender == 'male';
    final bmr = isMale
        ? (10 * currentWeightKg + 6.25 * heightCm - 5 * age + 5).round()
        : (10 * currentWeightKg + 6.25 * heightCm - 5 * age - 161).round();
    final activity = switch (activityLevel) {
      'sedentary' => 1.2,
      'light' => 1.375,
      'moderate' => 1.55,
      'high' => 1.725,
      _ => 1.2,
    };
    final tdee = (bmr * activity).round();
    final deficit = (goalSpeedKgPerWeek * 1100).round();
    final dailyCalories = switch (goal) {
      // При TDEE < 1200 clamp(1200, tdee) бросал ArgumentError — тогда
      // дефицит не закладываем: ниже 1200 ккал без врача не опускаемся.
      'loseWeight' when tdee <= 1200 => tdee,
      'loseWeight' => (tdee - deficit).clamp(1200, tdee),
      'gainWeight' => tdee + deficit,
      _ => tdee,
    };
    final proteinGrams = (currentWeightKg * 1.6).round();
    final fatGrams = (dailyCalories * 0.25 / 9).round();
    final carbGrams = ((dailyCalories - proteinGrams * 4 - fatGrams * 9) / 4)
        .round();
    final waterMlGoal = (currentWeightKg * 35).round();

    return AiNutritionPlan(
      dailyCalories: dailyCalories,
      proteinGrams: proteinGrams,
      fatGrams: fatGrams,
      carbGrams: carbGrams,
      waterMlGoal: waterMlGoal,
      tdee: tdee,
      bmr: bmr,
      mealSuggestion: switch (goal) {
        'loseWeight' => 'Сбалансированный рацион с дефицитом калорий',
        'gainWeight' => 'Рацион с профицитом калорий для набора массы',
        _ => 'Рацион для поддержания текущего веса',
      },
    );
  }
}
