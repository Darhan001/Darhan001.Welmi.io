import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumina/core/services/tracker/daily_snapshot.dart';

/// Локальное хранилище дневного трекера: оффлайн-кэш дня, очередь
/// неотправленных операций и стрик. Ключи привязаны к пользователю.
class TrackerStorage {
  const TrackerStorage();

  static String _day(DateTime d) => d.toIso8601String().substring(0, 10);

  // ─── Очередь отложенной синхронизации (offline-first) ───

  Future<List<Map<String, dynamic>>> loadPending(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('pending_ops_$uid');
      if (raw == null) return [];
      return (jsonDecode(raw) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (e) {
      debugPrint('⚠️ Pending ops load error: $e');
      return [];
    }
  }

  Future<void> savePending(String uid, List<Map<String, dynamic>> ops) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_ops_$uid', jsonEncode(ops));
    } catch (e) {
      debugPrint('⚠️ Pending ops save error: $e');
    }
  }

  // ─── Оффлайн-кэш дня ───

  Future<void> saveSnapshot(String uid, DailySnapshot snapshot) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'daily_tracker_$uid',
        jsonEncode(snapshot.toJson()),
      );
    } catch (e) {
      debugPrint('⚠️ Tracker cache save error: $e');
    }
  }

  /// Снимок за [today] или `null`, если кэша нет или он за другой день.
  Future<DailySnapshot?> loadSnapshot(String uid, DateTime today) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('daily_tracker_$uid');
      if (raw == null) return null;
      final snapshot = DailySnapshot.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      return snapshot.isFor(today) ? snapshot : null;
    } catch (e) {
      debugPrint('⚠️ Tracker cache load error: $e');
      return null;
    }
  }

  // ─── Стрик «дней в цели подряд» ───

  /// Обновляет и возвращает стрик; при ошибке хранилища — `null`.
  Future<int?> updateStreak(
    String uid, {
    required DateTime today,
    required bool metGoal,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getInt('streak_count_$uid') ?? 0;
      final todayStr = _day(today);
      final next = nextStreak(
        lastDate: prefs.getString('streak_last_date_$uid'),
        stored: stored,
        today: todayStr,
        yesterday: _day(today.subtract(const Duration(days: 1))),
        metGoal: metGoal,
      );
      if (next == null) return stored;
      if (metGoal) {
        await prefs.setInt('streak_count_$uid', next.streak);
        await prefs.setString('streak_last_date_$uid', todayStr);
      } else if (next.reset) {
        await prefs.setInt('streak_count_$uid', 0);
      }
      return next.streak;
    } catch (e) {
      debugPrint('⚠️ Streak error: $e');
      return null;
    }
  }
}
