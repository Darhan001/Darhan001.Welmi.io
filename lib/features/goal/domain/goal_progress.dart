import 'package:lumina/core/models/supabase_models.dart';
import 'package:lumina/core/services/user_data_service.dart';

/// Подсказка Welmi AI на экране цели. Текст строится в UI из локализации.
enum GoalInsight {
  startTracking,
  greatPace,
  almostThere,
  steadyProgress,
  slowProgress,
  onTrack,
}

/// Расчёт прогресса к цели по весу.
///
/// Только реальные данные: старт — первая запись веса (или вес из профиля),
/// текущий — последняя запись, цель — из профиля. Раньше без данных
/// подставлялись выдуманные 72 → 65 кг.
class GoalProgress {
  const GoalProgress({
    required this.startKg,
    required this.currentKg,
    required this.goalKg,
    required this.goal,
    required this.goalSpeedKgPerWeek,
    required this.firstEntryDate,
    this.now,
  });

  final double startKg;
  final double currentKg;
  final double goalKg;
  final GoalType? goal;
  final double goalSpeedKgPerWeek;

  /// Дата первой записи веса; null, если записей нет.
  final DateTime? firstEntryDate;

  /// «Сейчас» для расчёта дней (в тестах); по умолчанию — текущее время.
  final DateTime? now;

  /// Прогресс из данных пользователя или null, если профиля нет.
  static GoalProgress? fromUserData(UserDataService data, {DateTime? now}) {
    final profile = data.profile;
    if (profile == null) return null;
    final entries = data.weightEntries;
    return GoalProgress(
      startKg: data.startWeight ?? profile.currentWeightKg,
      currentKg: data.latestWeight ?? profile.currentWeightKg,
      goalKg: profile.targetWeightKg,
      goal: profile.goal,
      goalSpeedKgPerWeek: profile.goalSpeedKgPerWeek,
      firstEntryDate: entries.isEmpty ? null : entries.last.date,
      now: now,
    );
  }

  bool get hasWeightGoal =>
      goal == GoalType.loseWeight || goal == GoalType.gainWeight;

  /// Доля пути к цели 0…1 (и для похудения, и для набора массы).
  double get progress {
    if (goalKg > startKg) {
      return ((currentKg - startKg) / (goalKg - startKg)).clamp(0.0, 1.0);
    }
    if (goalKg < startKg) {
      return ((startKg - currentKg) / (startKg - goalKg)).clamp(0.0, 1.0);
    }
    return 0.0;
  }

  /// Изменение веса от старта (положительное — потеря).
  double get totalLoss => startKg - currentKg;

  /// Сколько осталось до цели в кг, без учёта направления.
  double get remainingKg => (currentKg - goalKg).abs().clamp(0.0, 999.0);

  /// Дней с первой записи веса (минимум 1, если запись есть).
  int get daysIn {
    final first = firstEntryDate;
    if (first == null) return 0;
    final days = (now ?? DateTime.now()).difference(first).inDays;
    return days < 1 ? 1 : days;
  }

  /// Фактическое среднее изменение веса в день (может быть отрицательным).
  double get avgLossPerDay => daysIn > 0 ? totalLoss / daysIn : 0;

  /// Запланированный темп из профиля, кг/день.
  double get plannedPacePerDay => goalSpeedKgPerWeek / 7;

  /// Темп в направлении цели: при наборе массы знак меняется.
  double get _paceTowardsGoal =>
      goal == GoalType.gainWeight ? -avgLossPerDay : avgLossPerDay;

  /// Прогноз дней до цели: по фактическому темпу, иначе по плану.
  int get estimatedDaysToGoal {
    if (!hasWeightGoal || remainingKg <= 0) return 0;
    final actual = _paceTowardsGoal;
    final pace = actual > 0.001 ? actual : plannedPacePerDay;
    if (pace <= 0) return 0;
    return (remainingKg / pace).round();
  }

  /// Темп для карточки «В среднем»: факт, план (`isPlanned`) или null.
  ({double kgPerDay, bool isPlanned})? get averagePace {
    if (daysIn > 0 && avgLossPerDay.abs() >= 0.005) {
      return (kgPerDay: _paceTowardsGoal, isPlanned: false);
    }
    if (hasWeightGoal) return (kgPerDay: plannedPacePerDay, isPlanned: true);
    return null;
  }

  GoalInsight get insight {
    if (totalLoss <= 0 && remainingKg <= 0) return GoalInsight.startTracking;
    if (avgLossPerDay > 0.1) {
      return estimatedDaysToGoal > 0
          ? GoalInsight.greatPace
          : GoalInsight.almostThere;
    }
    if (avgLossPerDay > 0.03) return GoalInsight.steadyProgress;
    if (remainingKg > 5) return GoalInsight.slowProgress;
    return GoalInsight.onTrack;
  }
}
