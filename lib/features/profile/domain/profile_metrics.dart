import 'package:lumina/core/models/supabase_models.dart';

/// Полных лет на дату [now] (по умолчанию — сегодня).
int ageOn(DateTime birthDate, {DateTime? now}) {
  final today = now ?? DateTime.now();
  var age = today.year - birthDate.year;
  if (today.month < birthDate.month ||
      (today.month == birthDate.month && today.day < birthDate.day)) {
    age--;
  }
  return age;
}

/// Базовый обмен (Mifflin-St Jeor). 0 — если данных недостаточно:
/// без введённых значений не считаем по выдуманным 72 кг и 175 см.
int calculateBmr({
  required double? weightKg,
  required double? heightCm,
  required DateTime? birthDate,
  required Gender? gender,
  DateTime? now,
}) {
  if (weightKg == null || heightCm == null || birthDate == null) return 0;
  final age = ageOn(birthDate, now: now);
  final base = 10 * weightKg + 6.25 * heightCm - 5 * age;
  return switch (gender) {
    Gender.male => (base + 5).round(),
    Gender.female => (base - 161).round(),
    null => 0,
  };
}

/// Суточный расход энергии с учётом активности.
int calculateTdee(int bmr, ActivityLevel? activity) {
  if (bmr == 0) return 0;
  final factor = switch (activity) {
    ActivityLevel.sedentary => 1.2,
    ActivityLevel.light => 1.375,
    ActivityLevel.moderate => 1.55,
    ActivityLevel.high => 1.725,
    null => 1.0,
  };
  return (bmr * factor).round();
}
