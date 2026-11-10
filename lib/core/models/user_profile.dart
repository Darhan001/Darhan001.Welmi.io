import 'dart:convert';

import 'json_read.dart';

enum GoalType { loseWeight, gainWeight, maintainWeight }

enum Gender { male, female }

enum ActivityLevel { sedentary, light, moderate, high }

/// Профиль пользователя (таблица `profiles`).
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

  /// Устаревшие поля подписки: доступ к Premium определяется только
  /// серверным `subscription_entitlements`, клиент их не записывает.
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
  }) : birthDate = birthDate ?? DateTime(1995, 1, 1),
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
    final base = 10 * currentWeightKg + 6.25 * heightCm - 5 * age;
    return (gender == Gender.male ? base + 5 : base - 161).round();
  }

  // TDEE
  int get tdee => switch (activityLevel) {
    ActivityLevel.sedentary => (bmr * 1.2).round(),
    ActivityLevel.light => (bmr * 1.375).round(),
    ActivityLevel.moderate => (bmr * 1.55).round(),
    ActivityLevel.high => (bmr * 1.725).round(),
    null => bmr,
  };

  // Daily calorie target
  int get dailyCalories {
    final deficit = (goalSpeedKgPerWeek * 1100).round();
    return switch (goal) {
      null => tdee,
      // clamp(1200, tdee) бросал ArgumentError при tdee < 1200
      // (например, пол не указан → bmr = 0).
      GoalType.loseWeight =>
        tdee <= 1200 ? tdee : (tdee - deficit).clamp(1200, tdee),
      GoalType.gainWeight => tdee + deficit,
      GoalType.maintainWeight => tdee,
    };
  }

  int get proteinGrams => (currentWeightKg * 1.6).round();
  int get fatGrams => (dailyCalories * 0.25 / 9).round();
  int get carbGrams =>
      ((dailyCalories - proteinGrams * 4 - fatGrams * 9) / 4).round();

  /// Поля для записи в `profiles` и для локального кэша.
  ///
  /// `subscription_tier`/`subscription_expires_at` намеренно не пишутся:
  /// раньше каждое сохранение профиля перезаписывало их значением с клиента.
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
    'units_system': unitsSystem,
    'notification_prefs': jsonEncode(notificationPrefs),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: readString(json['id']),
    displayName: readStringOrNull(json['display_name']),
    email: readStringOrNull(json['email']),
    photoUrl: readStringOrNull(json['photo_url']),
    goal: enumByName(GoalType.values, json['goal']),
    gender: enumByName(Gender.values, json['gender']),
    heightCm: readDouble(json['height_cm'], 175),
    currentWeightKg: readDouble(json['current_weight_kg'], 72),
    targetWeightKg: readDouble(json['target_weight_kg'], 70),
    birthDate: readDateOrNull(json['birth_date']) ?? DateTime(1995, 1, 1),
    activityLevel: enumByName(ActivityLevel.values, json['activity_level']),
    goalSpeedKgPerWeek: readDouble(json['goal_speed_kg_per_week'], 0.5),
    subscriptionTier: readStringOrNull(json['subscription_tier']) ?? 'free',
    subscriptionExpiresAt: readDateOrNull(json['subscription_expires_at']),
    unitsSystem: readStringOrNull(json['units_system']) ?? 'metric',
    notificationPrefs:
        _parsePrefs(json['notification_prefs']) ?? _defaultNotificationPrefs(),
    createdAt: readDateOrNow(json['created_at']),
    updatedAt: readDateOrNow(json['updated_at']),
  );

  /// JSONB-колонка приходит из Supabase объектом (Map), но может быть и
  /// строкой. Небулевы значения пропускаются, а не роняют разбор профиля.
  static Map<String, bool>? _parsePrefs(Object? raw) {
    Object? decoded = raw;
    if (raw is String) {
      try {
        decoded = jsonDecode(raw);
      } on FormatException {
        return null;
      }
    }
    if (decoded is! Map) return null;
    return {
      for (final e in decoded.entries)
        if (e.value is bool) e.key.toString(): e.value as bool,
    };
  }
}
