import 'package:lumina/core/models/workout_plan.dart';
import 'package:lumina/core/services/ai/fallback_bodyweight_plan.dart';
import 'package:lumina/core/services/ai/fallback_calisthenics_plan.dart';
import 'package:lumina/core/services/ai/fallback_dumbbell_plan.dart';
import 'package:lumina/core/services/ai/fallback_gym_plan.dart';

/// Выбрать запасной план по инвентарю пользователя.
WorkoutPlan fallbackWorkoutPlan(String equipment) {
  final eq = equipment.toLowerCase();
  if (eq.contains('без инвентаря') ||
      eq.contains('собственный вес') ||
      eq.contains('вес тела')) {
    return fallbackBodyweightPlan();
  }
  if (eq.contains('зал') || eq.contains('тренажёр') || eq.contains('штанга')) {
    return fallbackGymPlan();
  }
  if (eq.contains('турник') || eq.contains('резин')) {
    return fallbackHomeCalisthenicsPlan();
  }
  return fallbackDumbbellPlan();
}
