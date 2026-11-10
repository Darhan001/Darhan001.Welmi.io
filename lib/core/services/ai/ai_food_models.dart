import 'package:lumina/core/services/ai/ai_json.dart';

/// Результат AI-анализа фото еды.
class FoodAnalysisResult {
  final String name;
  final int calories;
  final double proteinGrams;
  final double fatGrams;
  final double carbsGrams;
  final double? amountGrams;
  final String description;

  FoodAnalysisResult({
    required this.name,
    required this.calories,
    required this.proteinGrams,
    required this.fatGrams,
    required this.carbsGrams,
    this.amountGrams,
    this.description = '',
  });

  factory FoodAnalysisResult.fromJson(Map<String, dynamic> json) {
    return FoodAnalysisResult(
      name: json['name']?.toString() ?? json['название']?.toString() ?? 'Блюдо',
      calories: aiToDouble(
        json['calories'] ?? json['калории'] ?? json['kcal'],
      ).toInt(),
      proteinGrams: aiToDouble(
        json['protein_grams'] ?? json['protein'] ?? json['белки'],
      ),
      fatGrams: aiToDouble(json['fat_grams'] ?? json['fat'] ?? json['жиры']),
      carbsGrams: aiToDouble(
        json['carbs_grams'] ?? json['carbs'] ?? json['углеводы'],
      ),
      amountGrams: aiToDouble(
        json['amount_grams'] ?? json['weight'] ?? json['вес'],
      ),
      description:
          json['description']?.toString() ?? json['описание']?.toString() ?? '',
    );
  }
}

/// Отдельный продукт в распознанном голосовом сообщении
class VoiceFoodItem {
  final String name;
  final String portion; // например "2 шт.", "200 г", "1 тарелка"
  final int calories;
  final double proteinGrams;
  final double fatGrams;
  final double carbsGrams;

  VoiceFoodItem({
    required this.name,
    required this.portion,
    required this.calories,
    required this.proteinGrams,
    required this.fatGrams,
    required this.carbsGrams,
  });

  factory VoiceFoodItem.fromJson(Map<String, dynamic> json) {
    return VoiceFoodItem(
      name: json['name']?.toString() ?? 'Продукт',
      portion:
          json['portion']?.toString() ??
          json['amount']?.toString() ??
          '1 порция',
      calories: aiToDouble(json['calories'] ?? json['kcal']).toInt(),
      proteinGrams: aiToDouble(json['protein_grams'] ?? json['protein']),
      fatGrams: aiToDouble(json['fat_grams'] ?? json['fat']),
      carbsGrams: aiToDouble(json['carbs_grams'] ?? json['carbs']),
    );
  }
}

/// Результат AI-анализа голосового сообщения о съеденной пище
class VoiceFoodAnalysisResult {
  final List<VoiceFoodItem> items;
  final int totalCalories;
  final double totalProtein;
  final double totalFat;
  final double totalCarbs;
  final String? clarificationNeeded; // если AI не уверен в количестве

  VoiceFoodAnalysisResult({
    required this.items,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalFat,
    required this.totalCarbs,
    this.clarificationNeeded,
  });

  factory VoiceFoodAnalysisResult.fromJson(Map<String, dynamic> json) {
    // Битые элементы (не объекты) пропускаем, а не роняем весь разбор.
    final rawItems = json['items'];
    final items = [
      if (rawItems is List)
        for (final e in rawItems)
          if (e is Map) VoiceFoodItem.fromJson(Map<String, dynamic>.from(e)),
    ];

    int totalCalories = aiToDouble(
      json['total_calories'] ?? json['total_kcal'],
    ).toInt();
    double totalProtein = aiToDouble(json['total_protein']);
    double totalFat = aiToDouble(json['total_fat']);
    double totalCarbs = aiToDouble(json['total_carbs']);

    // Если AI вернул нули в сумме, считаем из отдельных продуктов
    if (totalCalories == 0 && items.isNotEmpty) {
      for (final item in items) {
        totalCalories += item.calories;
        totalProtein += item.proteinGrams;
        totalFat += item.fatGrams;
        totalCarbs += item.carbsGrams;
      }
    }

    // Модель иногда пишет строку "null" вместо null.
    final clarification = json['clarification_needed']?.toString().trim();
    return VoiceFoodAnalysisResult(
      items: items,
      totalCalories: totalCalories,
      totalProtein: totalProtein,
      totalFat: totalFat,
      totalCarbs: totalCarbs,
      clarificationNeeded:
          clarification == null ||
              clarification.isEmpty ||
              clarification == 'null'
          ? null
          : clarification,
    );
  }
}
