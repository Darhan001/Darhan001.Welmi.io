import 'dart:convert';

import 'package:lumina/core/models/workout_plan.dart';

// Разбор ответов моделей: они часто оборачивают JSON в markdown или текст,
// поэтому берём фрагмент между первой и последней скобкой.

/// Число из JSON-значения (число или строка); всё остальное — 0.
double aiToDouble(Object? val) {
  if (val == null) return 0.0;
  if (val is num) return val.toDouble();
  return double.tryParse(val.toString()) ?? 0.0;
}

/// Первый JSON-объект в тексте ответа или null.
Map<String, dynamic>? extractJsonObject(String text) {
  final start = text.indexOf('{');
  final end = text.lastIndexOf('}');
  if (start == -1 || end <= start) return null;
  try {
    final decoded = jsonDecode(text.substring(start, end + 1));
    return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
  } catch (_) {
    return null;
  }
}

/// Первый JSON-массив в тексте ответа или null.
List<Object?>? _extractJsonList(String text) {
  final start = text.indexOf('[');
  final end = text.lastIndexOf(']');
  if (start == -1 || end <= start) return null;
  try {
    final decoded = jsonDecode(text.substring(start, end + 1));
    return decoded is List ? decoded : null;
  } catch (_) {
    return null;
  }
}

List<Map<String, dynamic>> _mapsOf(List<Object?> list) => [
  for (final e in list)
    if (e is Map) Map<String, dynamic>.from(e),
];

/// Недельный план питания: массив дней или объект `{"days": [...]}`.
List<Map<String, dynamic>>? parseWeekPlan(String text) {
  final list = _extractJsonList(text);
  if (list != null) return _mapsOf(list);
  final days = extractJsonObject(text)?['days'];
  return days is List ? _mapsOf(days) : null;
}

/// План тренировок: объект `{"days": [...]}` или сразу массив дней.
WorkoutPlan? parseWorkoutPlan(String text) {
  try {
    final json = extractJsonObject(text);
    if (json != null) {
      final plan = WorkoutPlan.fromJson(json);
      if (plan.days.isNotEmpty) return plan;
    }
  } catch (_) {}
  try {
    final list = _extractJsonList(text);
    if (list != null) {
      final plan = WorkoutPlan.fromJson({'days': list});
      if (plan.days.isNotEmpty) return plan;
    }
  } catch (_) {}
  return null;
}
