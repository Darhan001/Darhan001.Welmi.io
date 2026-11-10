import 'package:supabase_flutter/supabase_flutter.dart';

/// Общие помощники для запросов к таблицам Supabase.
///
/// RLS-политики на сервере гарантируют, что пользователь видит и меняет
/// только свои строки; фильтр `user_id` в запросах — для индексов и ясности.
mixin SupabaseQueryBase {
  SupabaseClient get client;

  /// Дата в формате колонки `date` (YYYY-MM-DD).
  static String day(DateTime date) => date.toIso8601String().substring(0, 10);

  /// Одна запись на пользователя в день: обновляет существующую или создаёт.
  Future<Map<String, dynamic>> upsertForDay(
    String table, {
    required String userId,
    required DateTime date,
    required Map<String, dynamic> json,
  }) async {
    final existing = await client
        .from(table)
        .select('id')
        .eq('user_id', userId)
        .eq('date', day(date))
        .maybeSingle();

    if (existing != null) {
      return client
          .from(table)
          .update(Map.of(json)..remove('id'))
          .eq('id', existing['id'])
          .select()
          .single();
    }
    return client.from(table).insert(json).select().single();
  }

  /// Записи пользователя за период, новые первыми. Фильтр по дате — в
  /// запросе, а не в Dart: иначе с сервера тянулась вся история.
  Future<List<Map<String, dynamic>>> rowsInRange(
    String table,
    String userId, {
    DateTime? from,
    DateTime? to,
  }) async {
    var query = client.from(table).select().eq('user_id', userId);
    if (from != null) query = query.gte('date', day(from));
    if (to != null) query = query.lte('date', day(to));
    return query.order('date', ascending: false);
  }
}
