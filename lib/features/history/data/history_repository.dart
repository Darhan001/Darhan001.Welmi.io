import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumina/core/models/supabase_models.dart';
import 'package:lumina/core/services/supabase/supabase_base.dart';
import 'package:lumina/core/services/supabase_service.dart';
import 'package:lumina/features/history/domain/day_activity.dart';

/// Данные истории активности: шаги и вода с сервера, упражнения — локально.
class HistoryRepository {
  HistoryRepository({SupabaseService? supabase})
    : _supabase = supabase ?? SupabaseService();

  final SupabaseService _supabase;

  static String _key(DateTime d) => SupabaseQueryBase.day(d);

  /// Последние [days] дней (сегодня первым) и логи активности за 30 дней.
  Future<({List<DayActivity> days, List<ActivityLog> logs30})> load(
    String userId, {
    int days = 14,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstDay = today.subtract(Duration(days: days - 1));

    // Три независимых источника — параллельно; вода одним запросом за период
    // (раньше — отдельный запрос на каждый из 14 дней, по очереди).
    final (logs30, waters, exercises) = await (
      _supabase.getActivityLogs(
        userId,
        from: now.subtract(const Duration(days: 30)),
      ),
      _supabase.getWaterTotalsByDay(userId, from: firstDay, to: today),
      loadExercises(userId),
    ).wait;

    final byDate = {for (final log in logs30) _key(log.date): log};
    final result = List.generate(days, (i) {
      final day = today.subtract(Duration(days: i));
      final key = _key(day);
      final log = byDate[key];
      return DayActivity(
        date: day,
        steps: log?.steps ?? 0,
        calories: (log?.caloriesBurned ?? 0).toInt(),
        minutes: (log?.activeMinutes ?? 0).toInt(),
        distanceKm: log?.distanceKm ?? 0,
        waterMl: waters[key] ?? 0,
        exercises: exercises[key] ?? [],
      );
    });
    return (days: result, logs30: logs30);
  }

  // ─── Упражнения (локальное хранилище) ───

  static String _exerciseKey(String userId) => 'exercise_log_$userId';

  Future<Map<String, List<Map<String, dynamic>>>> loadExercises(
    String userId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_exerciseKey(userId));
      if (raw == null) return {};
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return data.map(
        (k, v) => MapEntry(
          k,
          (v as List).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
        ),
      );
    } catch (e) {
      debugPrint('⚠️ Exercise log read error: $e');
      return {};
    }
  }

  Future<void> addExercise(
    String userId, {
    required String name,
    required int sets,
    required int reps,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final data = await loadExercises(userId);
    final key = _key(DateTime.now());
    (data[key] ??= []).add({'name': name, 'sets': sets, 'reps': reps});
    await prefs.setString(_exerciseKey(userId), jsonEncode(data));
  }
}
