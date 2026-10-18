/// ============================================================
/// Supabase Models — все данные приложения
/// ============================================================
/// Эти модели соответствуют таблицам в Supabase.
/// После подключения Supabase, данные будут сериализоваться
/// через .fromJson() / .toJson() для работы с Supabase API.
library;

import 'dart:convert';

// ─────────────────────────────────────────────────────────────
// ENUMS
// ─────────────────────────────────────────────────────────────

enum GoalType { loseWeight, gainWeight, maintainWeight }

enum Gender { male, female }

enum ActivityLevel { sedentary, light, moderate, high }

enum MealType { breakfast, lunch, dinner, snack }

// ─────────────────────────────────────────────────────────────
// USERS / PROFILES
// ─────────────────────────────────────────────────────────────

class UserProfile {
  final String id; // UUID from Supabase Auth
  String? displayName;
  String? email;
  String? photoUrl;
  GoalType? goal;
  Gender? gender;
  double heightCm; // cm
  double currentWeightKg; // kg
  double targetWeightKg; // kg
  DateTime birthDate;
  ActivityLevel? activityLevel;
  double goalSpeedKgPerWeek; // kg per week
  String? subscriptionTier; // 'free', 'pro'
  DateTime? subscriptionExpiresAt;
  String? unitsSystem; // 'metric', 'imperial'
  Map<String, bool> notificationPrefs;
  DateTime createdAt;
  DateTime updatedAt;

  UserProfile({
    required this.id,
    this.displayName,
    this.email,
    this.photoUrl,
    this.goal,
    this.gender,
    this.heightCm = 175,
    this.currentWeightKg = 72,
    this.targetWeightKg = 70,
    DateTime? birthDate,
    this.activityLevel,
    this.goalSpeedKgPerWeek = 0.5,
    this.subscriptionTier = 'free',
    this.subscriptionExpiresAt,
    this.unitsSystem = 'metric',
    Map<String, bool>? notificationPrefs,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : birthDate = birthDate ?? DateTime(1995, 1, 1),
        notificationPrefs = notificationPrefs ?? _defaultNotificationPrefs(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  static Map<String, bool> _defaultNotificationPrefs() => {
        'water_reminders': true,
        'meal_reminders': true,
        'motivational': false,
      };

  int get age {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  // BMR (Mifflin-St Jeor)
  int get bmr {
    if (gender == null) return 0;
    if (gender == Gender.male) {
      return (10 * currentWeightKg + 6.25 * heightCm - 5 * age + 5).round();
    } else {
      return (10 * currentWeightKg + 6.25 * heightCm - 5 * age - 161).round();
    }
  }

  // TDEE
  int get tdee {
    switch (activityLevel) {
      case ActivityLevel.sedentary:
        return (bmr * 1.2).round();
      case ActivityLevel.light:
        return (bmr * 1.375).round();
      case ActivityLevel.moderate:
        return (bmr * 1.55).round();
      case ActivityLevel.high:
        return (bmr * 1.725).round();
      case null:
        return bmr;
    }
  }

  // Daily calorie target
  int get dailyCalories {
    if (goal == null) return tdee;
    final deficit = (goalSpeedKgPerWeek * 1100).round();
    switch (goal!) {
      case GoalType.loseWeight:
        return (tdee - deficit).clamp(1200, tdee);
      case GoalType.gainWeight:
        return tdee + deficit;
      case GoalType.maintainWeight:
        return tdee;
    }
  }

  int get proteinGrams => (currentWeightKg * 1.6).round();
  int get fatGrams => (dailyCalories * 0.25 / 9).round();
  int get carbGrams =>
      ((dailyCalories - proteinGrams * 4 - fatGrams * 9) / 4).round();

  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) 'id': id,
        'display_name': displayName,
        'email': email,
        'photo_url': photoUrl,
        'goal': goal?.name,
        'gender': gender?.name,
        'height_cm': heightCm,
        'current_weight_kg': currentWeightKg,
        'target_weight_kg': targetWeightKg,
        'birth_date': birthDate.toIso8601String(),
        'activity_level': activityLevel?.name,
        'goal_speed_kg_per_week': goalSpeedKgPerWeek,
        'subscription_tier': subscriptionTier,
        'subscription_expires_at': subscriptionExpiresAt?.toIso8601String(),
        'units_system': unitsSystem,
        'notification_prefs': jsonEncode(notificationPrefs),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        displayName: json['display_name'] as String?,
        email: json['email'] as String?,
        photoUrl: json['photo_url'] as String?,
        goal: json['goal'] != null
            ? GoalType.values.firstWhere((e) => e.name == json['goal'])
            : null,
        gender: json['gender'] != null
            ? Gender.values.firstWhere((e) => e.name == json['gender'])
            : null,
        heightCm: (json['height_cm'] as num?)?.toDouble() ?? 175,
        currentWeightKg:
            (json['current_weight_kg'] as num?)?.toDouble() ?? 72,
        targetWeightKg:
            (json['target_weight_kg'] as num?)?.toDouble() ?? 70,
        birthDate: json['birth_date'] != null
            ? DateTime.parse(json['birth_date'] as String)
            : DateTime(1995, 1, 1),
        activityLevel: json['activity_level'] != null
            ? ActivityLevel.values
                .firstWhere((e) => e.name == json['activity_level'])
            : null,
        goalSpeedKgPerWeek:
            (json['goal_speed_kg_per_week'] as num?)?.toDouble() ?? 0.5,
        subscriptionTier: json['subscription_tier'] as String? ?? 'free',
        subscriptionExpiresAt: json['subscription_expires_at'] != null
            ? DateTime.parse(json['subscription_expires_at'] as String)
            : null,
        unitsSystem: json['units_system'] as String? ?? 'metric',
        notificationPrefs: json['notification_prefs'] != null
            // JSONB-колонка приходит из Supabase уже как объект (Map),
            // но может быть и строкой — поддерживаем оба варианта
            ? (json['notification_prefs'] is Map
                ? Map<String, bool>.from(json['notification_prefs'] as Map)
                : Map<String, bool>.from(
                    jsonDecode(json['notification_prefs'] as String)))
            : _defaultNotificationPrefs(),
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : DateTime.now(),
      );
}

// ─────────────────────────────────────────────────────────────
// WEIGHT ENTRIES
// ─────────────────────────────────────────────────────────────

class WeightEntry {
  final String id;
  final String userId;
  double weightKg;
  DateTime date;
  String? notes;
  DateTime createdAt;

  WeightEntry({
    String? id,
    required this.userId,
    required this.weightKg,
    DateTime? date,
    this.notes,
    DateTime? createdAt,
  })  : id = id ?? '',
        date = date ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) 'id': id,
        'user_id': userId,
        'weight_kg': weightKg,
        'date': date.toIso8601String(),
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
      };

  factory WeightEntry.fromJson(Map<String, dynamic> json) => WeightEntry(
        id: json['id'] as String? ?? '',
        userId: json['user_id'] as String,
        weightKg: (json['weight_kg'] as num).toDouble(),
        date: json['date'] != null
            ? DateTime.parse(json['date'] as String)
            : DateTime.now(),
        notes: json['notes'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
      );
}

// ─────────────────────────────────────────────────────────────
// WATER ENTRIES
// ─────────────────────────────────────────────────────────────

class WaterEntry {
  final String id;
  final String userId;
  int amountMl;
  DateTime date;
  DateTime createdAt;

  WaterEntry({
    String? id,
    required this.userId,
    required this.amountMl,
    DateTime? date,
    DateTime? createdAt,
  })  : id = id ?? '',
        date = date ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) 'id': id,
        'user_id': userId,
        'amount_ml': amountMl,
        'date': date.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  factory WaterEntry.fromJson(Map<String, dynamic> json) => WaterEntry(
        id: json['id'] as String? ?? '',
        userId: json['user_id'] as String,
        amountMl: json['amount_ml'] as int,
        date: json['date'] != null
            ? DateTime.parse(json['date'] as String)
            : DateTime.now(),
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
      );
}

// ─────────────────────────────────────────────────────────────
// FOOD DIARY ENTRIES
// ─────────────────────────────────────────────────────────────

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
  })  : id = id ?? '',
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
        id: json['id'] as String? ?? '',
        userId: json['user_id'] as String,
        date: json['date'] != null
            ? DateTime.parse(json['date'] as String)
            : DateTime.now(),
        mealType: MealType.values.firstWhere((e) => e.name == json['meal_type']),
        totalCalories: json['total_calories'] as int? ?? 0,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
      );
}

// ─────────────────────────────────────────────────────────────
// MEAL ITEMS
// ─────────────────────────────────────────────────────────────

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
  })  : id = id ?? '',
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
        id: json['id'] as String? ?? '',
        foodEntryId: json['food_entry_id'] as String,
        name: json['name'] as String,
        calories: json['calories'] as int,
        proteinGrams: (json['protein_grams'] as num?)?.toDouble(),
        fatGrams: (json['fat_grams'] as num?)?.toDouble(),
        carbsGrams: (json['carbs_grams'] as num?)?.toDouble(),
        amountGrams: (json['amount_grams'] as num?)?.toDouble(),
        info: json['info'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
      );
}

// ─────────────────────────────────────────────────────────────
// ACTIVITY LOGS
// ─────────────────────────────────────────────────────────────

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
  })  : id = id ?? '',
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
        id: json['id'] as String? ?? '',
        userId: json['user_id'] as String,
        date: json['date'] != null
            ? DateTime.parse(json['date'] as String)
            : DateTime.now(),
        steps: json['steps'] as int? ?? 0,
        caloriesBurned: (json['calories_burned'] as num?)?.toDouble(),
        activeMinutes: (json['active_minutes'] as num?)?.toDouble(),
        distanceKm: (json['distance_km'] as num?)?.toDouble(),
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
      );
}

// ─────────────────────────────────────────────────────────────
// BODY MEASUREMENTS (замеры тела)
// ─────────────────────────────────────────────────────────────

class BodyMeasurement {
  final String id;
  final String userId;
  DateTime date;
  double? chestCm;
  double? waistCm;
  double? hipsCm;
  double? leftArmCm;
  double? rightArmCm;
  double? leftThighCm;
  double? rightThighCm;
  double? neckCm;
  String? notes;
  DateTime createdAt;

  BodyMeasurement({
    String? id,
    required this.userId,
    DateTime? date,
    this.chestCm,
    this.waistCm,
    this.hipsCm,
    this.leftArmCm,
    this.rightArmCm,
    this.leftThighCm,
    this.rightThighCm,
    this.neckCm,
    this.notes,
    DateTime? createdAt,
  })  : id = id ?? '',
        date = date ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) 'id': id,
        'user_id': userId,
        'date': date.toIso8601String(),
        'chest_cm': chestCm,
        'waist_cm': waistCm,
        'hips_cm': hipsCm,
        'left_arm_cm': leftArmCm,
        'right_arm_cm': rightArmCm,
        'left_thigh_cm': leftThighCm,
        'right_thigh_cm': rightThighCm,
        'neck_cm': neckCm,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
      };

  factory BodyMeasurement.fromJson(Map<String, dynamic> json) => BodyMeasurement(
        id: json['id'] as String? ?? '',
        userId: json['user_id'] as String,
        date: json['date'] != null
            ? DateTime.parse(json['date'] as String)
            : DateTime.now(),
        chestCm: (json['chest_cm'] as num?)?.toDouble(),
        waistCm: (json['waist_cm'] as num?)?.toDouble(),
        hipsCm: (json['hips_cm'] as num?)?.toDouble(),
        leftArmCm: (json['left_arm_cm'] as num?)?.toDouble(),
        rightArmCm: (json['right_arm_cm'] as num?)?.toDouble(),
        leftThighCm: (json['left_thigh_cm'] as num?)?.toDouble(),
        rightThighCm: (json['right_thigh_cm'] as num?)?.toDouble(),
        neckCm: (json['neck_cm'] as num?)?.toDouble(),
        notes: json['notes'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
      );
}

// ─────────────────────────────────────────────────────────────
// BODY FAT ENTRIES (% жира)
// ─────────────────────────────────────────────────────────────

class BodyFatEntry {
  final String id;
  final String userId;
  DateTime date;
  double bodyFatPercent;
  String? method; // 'caliper', 'scale', 'manual', 'estimated'
  String? notes;
  DateTime createdAt;

  BodyFatEntry({
    String? id,
    required this.userId,
    DateTime? date,
    required this.bodyFatPercent,
    this.method,
    this.notes,
    DateTime? createdAt,
  })  : id = id ?? '',
        date = date ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) 'id': id,
        'user_id': userId,
        'date': date.toIso8601String(),
        'body_fat_percent': bodyFatPercent,
        'method': method,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
      };

  factory BodyFatEntry.fromJson(Map<String, dynamic> json) => BodyFatEntry(
        id: json['id'] as String? ?? '',
        userId: json['user_id'] as String,
        date: json['date'] != null
            ? DateTime.parse(json['date'] as String)
            : DateTime.now(),
        bodyFatPercent: (json['body_fat_percent'] as num).toDouble(),
        method: json['method'] as String?,
        notes: json['notes'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
      );
}

// ─────────────────────────────────────────────────────────────
// DAILY NUTRITION SUMMARY
// ─────────────────────────────────────────────────────────────

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
  })  : id = id ?? '',
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
        id: json['id'] as String? ?? '',
        userId: json['user_id'] as String,
        date: json['date'] != null
            ? DateTime.parse(json['date'] as String)
            : DateTime.now(),
        totalCalories: json['total_calories'] as int? ?? 0,
        proteinGrams: json['protein_grams'] as int? ?? 0,
        fatGrams: json['fat_grams'] as int? ?? 0,
        carbGrams: json['carb_grams'] as int? ?? 0,
        waterMl: json['water_ml'] as int? ?? 0,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
      );
}
