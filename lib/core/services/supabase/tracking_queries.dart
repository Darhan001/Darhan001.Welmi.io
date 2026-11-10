import 'package:lumina/core/models/supabase_models.dart';
import 'package:lumina/core/services/supabase/supabase_base.dart';

/// Вес, вода, активность, замеры и процент жира.
mixin TrackingQueries on SupabaseQueryBase {
  // ── Вес ──

  Future<WeightEntry> addWeightEntry(WeightEntry entry) async {
    final response = await client
        .from('weight_entries')
        .insert(entry.toJson())
        .select()
        .single();
    return WeightEntry.fromJson(response);
  }

  Future<void> updateWeightEntry(WeightEntry entry) async {
    final data = entry.toJson()..remove('id');
    await client.from('weight_entries').update(data).eq('id', entry.id);
  }

  Future<List<WeightEntry>> getWeightEntries(
    String userId, {
    DateTime? from,
    DateTime? to,
  }) async {
    // Колонка date здесь — метка времени, поэтому сравнение по полной дате.
    var filterBuilder = client
        .from('weight_entries')
        .select()
        .eq('user_id', userId);
    if (from != null) {
      filterBuilder = filterBuilder.gte('date', from.toIso8601String());
    }
    if (to != null) {
      filterBuilder = filterBuilder.lte('date', to.toIso8601String());
    }
    final response = await filterBuilder.order('date', ascending: false);
    return response.map(WeightEntry.fromJson).toList();
  }

  // ── Вода ──

  Future<WaterEntry> addWaterEntry(WaterEntry entry) async {
    final response = await client
        .from('water_entries')
        .insert(entry.toJson())
        .select()
        .single();
    return WaterEntry.fromJson(response);
  }

  Future<List<WaterEntry>> getWaterEntries(String userId, DateTime date) async {
    final response = await client
        .from('water_entries')
        .select()
        .eq('user_id', userId)
        .eq('date', SupabaseQueryBase.day(date))
        .order('created_at');
    return response.map(WaterEntry.fromJson).toList();
  }

  Future<int> getDailyWaterTotal(String userId, DateTime date) async {
    final response = await client
        .from('water_entries')
        .select('amount_ml')
        .eq('user_id', userId)
        .eq('date', SupabaseQueryBase.day(date));
    return response.fold<int>(
      0,
      (sum, e) => sum + ((e['amount_ml'] as num?)?.toInt() ?? 0),
    );
  }

  /// Выпито воды по дням периода одним запросом: ключ — дата YYYY-MM-DD.
  /// Заменяет цикл getDailyWaterTotal по дням (N запросов подряд).
  Future<Map<String, int>> getWaterTotalsByDay(
    String userId, {
    required DateTime from,
    required DateTime to,
  }) async {
    final response = await client
        .from('water_entries')
        .select('date, amount_ml')
        .eq('user_id', userId)
        .gte('date', SupabaseQueryBase.day(from))
        .lte('date', SupabaseQueryBase.day(to));
    final totals = <String, int>{};
    for (final row in response) {
      final date = row['date'];
      if (date is! String || date.length < 10) continue;
      final key = date.substring(0, 10);
      totals[key] =
          (totals[key] ?? 0) + ((row['amount_ml'] as num?)?.toInt() ?? 0);
    }
    return totals;
  }

  // ── Замеры тела, % жира, активность: одна запись на день ──

  Future<BodyMeasurement> saveBodyMeasurement(
    BodyMeasurement measurement,
  ) async {
    final row = await upsertForDay(
      'body_measurements',
      userId: measurement.userId,
      date: measurement.date,
      json: measurement.toJson(),
    );
    return BodyMeasurement.fromJson(row);
  }

  Future<List<BodyMeasurement>> getBodyMeasurements(
    String userId, {
    DateTime? from,
    DateTime? to,
  }) async {
    final rows = await rowsInRange(
      'body_measurements',
      userId,
      from: from,
      to: to,
    );
    return rows.map(BodyMeasurement.fromJson).toList();
  }

  Future<BodyFatEntry> saveBodyFatEntry(BodyFatEntry entry) async {
    final row = await upsertForDay(
      'body_fat_entries',
      userId: entry.userId,
      date: entry.date,
      json: entry.toJson(),
    );
    return BodyFatEntry.fromJson(row);
  }

  Future<List<BodyFatEntry>> getBodyFatEntries(
    String userId, {
    DateTime? from,
    DateTime? to,
  }) async {
    final rows = await rowsInRange(
      'body_fat_entries',
      userId,
      from: from,
      to: to,
    );
    return rows.map(BodyFatEntry.fromJson).toList();
  }

  Future<ActivityLog> saveActivityLog(ActivityLog log) async {
    final row = await upsertForDay(
      'activity_logs',
      userId: log.userId,
      date: log.date,
      json: log.toJson(),
    );
    return ActivityLog.fromJson(row);
  }

  Future<List<ActivityLog>> getActivityLogs(
    String userId, {
    DateTime? from,
    DateTime? to,
  }) async {
    final rows = await rowsInRange('activity_logs', userId, from: from, to: to);
    return rows.map(ActivityLog.fromJson).toList();
  }
}
