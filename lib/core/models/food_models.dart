import 'json_read.dart';

enum MealType { breakfast, lunch, dinner, snack }

/// Приём пищи в дневнике (таблица `food_entries`).
class FoodEntry {
  final String id;
  final String userId;
  DateTime date;
  MealType mealType;
  List<MealItem> items;
  int totalCalories;
  DateTime createdAt;

  FoodEntry({
    String? id,
    required this.userId,
    DateTime? date,
    this.mealType = MealType.breakfast,
    List<MealItem>? items,
    this.totalCalories = 0,
    DateTime? createdAt,
  }) : id = id ?? '',
       date = date ?? DateTime.now(),
       items = items ?? [],
       createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    if (id.isNotEmpty) 'id': id,
    'user_id': userId,
    'date': date.toIso8601String(),
    'meal_type': mealType.name,
    'total_calories': totalCalories,
    'created_at': createdAt.toIso8601String(),
  };

  factory FoodEntry.fromJson(Map<String, dynamic> json) => FoodEntry(
    id: readString(json['id']),
    userId: readString(json['user_id']),
    date: readDateOrNow(json['date']),
    // Неизвестный тип раньше бросал StateError и ронял загрузку всего дня.
    mealType:
        enumByName(MealType.values, json['meal_type']) ?? MealType.breakfast,
    totalCalories: readInt(json['total_calories']),
    createdAt: readDateOrNow(json['created_at']),
  );
}

/// Позиция внутри приёма пищи (таблица `meal_items`).
class MealItem {
  final String id;
  final String foodEntryId;
  String name;
  int calories;
  double? proteinGrams;
  double? fatGrams;
  double? carbsGrams;
  double? amountGrams;
  String? info; // e.g. "250г"
  DateTime createdAt;

  MealItem({
    String? id,
    required this.foodEntryId,
    required this.name,
    required this.calories,
    this.proteinGrams,
    this.fatGrams,
    this.carbsGrams,
    this.amountGrams,
    this.info,
    DateTime? createdAt,
  }) : id = id ?? '',
       createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    if (id.isNotEmpty) 'id': id,
    'food_entry_id': foodEntryId,
    'name': name,
    'calories': calories,
    'protein_grams': proteinGrams,
    'fat_grams': fatGrams,
    'carbs_grams': carbsGrams,
    'amount_grams': amountGrams,
    'info': info,
    'created_at': createdAt.toIso8601String(),
  };

  factory MealItem.fromJson(Map<String, dynamic> json) => MealItem(
    id: readString(json['id']),
    foodEntryId: readString(json['food_entry_id']),
    name: readString(json['name']),
    calories: readInt(json['calories']),
    proteinGrams: readDoubleOrNull(json['protein_grams']),
    fatGrams: readDoubleOrNull(json['fat_grams']),
    carbsGrams: readDoubleOrNull(json['carbs_grams']),
    amountGrams: readDoubleOrNull(json['amount_grams']),
    info: readStringOrNull(json['info']),
    createdAt: readDateOrNow(json['created_at']),
  );
}
