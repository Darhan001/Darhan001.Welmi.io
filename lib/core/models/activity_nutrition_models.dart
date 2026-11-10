import 'json_read.dart';

/// Дневной лог активности (таблица `activity_logs`), одна запись на дату.
class ActivityLog {
  final String id;
  final String userId;
  DateTime date;
  int steps;
  double? caloriesBurned;
  double? activeMinutes;
  double? distanceKm;
  DateTime createdAt;

  ActivityLog({
    String? id,
    required this.userId,
    DateTime? date,
    this.steps = 0,
    this.caloriesBurned,
    this.activeMinutes,
    this.distanceKm,
    DateTime? createdAt,
  }) : id = id ?? '',
       date = date ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    if (id.isNotEmpty) 'id': id,
    'user_id': userId,
    'date': date.toIso8601String(),
    'steps': steps,
    'calories_burned': caloriesBurned,
    'active_minutes': activeMinutes,
    'distance_km': distanceKm,
    'created_at': createdAt.toIso8601String(),
  };

  factory ActivityLog.fromJson(Map<String, dynamic> json) => ActivityLog(
    id: readString(json['id']),
    userId: readString(json['user_id']),
    date: readDateOrNow(json['date']),
    steps: readInt(json['steps']),
    caloriesBurned: readDoubleOrNull(json['calories_burned']),
    activeMinutes: readDoubleOrNull(json['active_minutes']),
    distanceKm: readDoubleOrNull(json['distance_km']),
    createdAt: readDateOrNow(json['created_at']),
  );
}

/// Дневная сводка питания (таблица `daily_nutrition`).
class DailyNutrition {
  final String id;
  final String userId;
  DateTime date;
  int totalCalories;
  int proteinGrams;
  int fatGrams;
  int carbGrams;
  int waterMl;
  DateTime createdAt;

  DailyNutrition({
    String? id,
    required this.userId,
    DateTime? date,
    this.totalCalories = 0,
    this.proteinGrams = 0,
    this.fatGrams = 0,
    this.carbGrams = 0,
    this.waterMl = 0,
    DateTime? createdAt,
  }) : id = id ?? '',
       date = date ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    if (id.isNotEmpty) 'id': id,
    'user_id': userId,
    'date': date.toIso8601String(),
    'total_calories': totalCalories,
    'protein_grams': proteinGrams,
    'fat_grams': fatGrams,
    'carb_grams': carbGrams,
    'water_ml': waterMl,
    'created_at': createdAt.toIso8601String(),
  };

  factory DailyNutrition.fromJson(Map<String, dynamic> json) => DailyNutrition(
    id: readString(json['id']),
    userId: readString(json['user_id']),
    date: readDateOrNow(json['date']),
    totalCalories: readInt(json['total_calories']),
    proteinGrams: readInt(json['protein_grams']),
    fatGrams: readInt(json['fat_grams']),
    carbGrams: readInt(json['carb_grams']),
    waterMl: readInt(json['water_ml']),
    createdAt: readDateOrNow(json['created_at']),
  );
}
