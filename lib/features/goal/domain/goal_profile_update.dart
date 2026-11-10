import 'package:lumina/core/models/supabase_models.dart';

/// Копия профиля с новой целью.
///
/// Все остальные поля, включая `createdAt`, берутся из существующего
/// профиля. Раньше профиль собирался заново: без профиля в БД уходили
/// выдуманные рост 175 см, вес 72 кг и дата рождения 1995 года, а
/// `created_at` каждый раз перезаписывался текущим временем.
UserProfile profileWithGoal(
  UserProfile existing, {
  required GoalType goal,
  required double targetWeightKg,
  required double goalSpeedKgPerWeek,
}) {
  return UserProfile(
    id: existing.id,
    displayName: existing.displayName,
    email: existing.email,
    photoUrl: existing.photoUrl,
    heightCm: existing.heightCm,
    currentWeightKg: existing.currentWeightKg,
    targetWeightKg: targetWeightKg,
    gender: existing.gender,
    goal: goal,
    activityLevel: existing.activityLevel,
    goalSpeedKgPerWeek: goalSpeedKgPerWeek,
    birthDate: existing.birthDate,
    subscriptionTier: existing.subscriptionTier,
    subscriptionExpiresAt: existing.subscriptionExpiresAt,
    unitsSystem: existing.unitsSystem,
    notificationPrefs: Map.of(existing.notificationPrefs),
    createdAt: existing.createdAt,
  );
}
