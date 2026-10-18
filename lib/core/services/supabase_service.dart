/// ============================================================
/// Supabase Service — работа с базой данных
/// ============================================================
/// Все методы теперь делают реальные запросы к Supabase.
/// RLS политики защищают данные — каждый видит только своё.
library;

import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lumina/core/services/auth_service.dart';
import 'package:lumina/core/models/supabase_models.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  bool _isInitialized = false;

  SupabaseClient get client => Supabase.instance.client;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // При запуске проверяем, есть ли активная сессия
    final session = client.auth.currentSession;
    if (session != null) {
      AuthService().syncFromSession(session.user);
    }

    // Слушаем изменения статуса входа
    client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        AuthService().syncFromSession(session.user);
      } else {
        AuthService().reset();
      }
    });

    _isInitialized = true;
  }

  // ────────────────────────────────────────────────────────────
  // PROFILES
  // ────────────────────────────────────────────────────────────

  Future<UserProfile> createProfile(UserProfile profile) async {
    final response = await client
        .from('profiles')
        .insert(profile.toJson())
        .select()
        .single();
    return UserProfile.fromJson(response);
  }

  Future<UserProfile?> getProfile(String userId) async {
    final response = await client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return response != null ? UserProfile.fromJson(response) : null;
  }

  Future<UserProfile> updateProfile(UserProfile profile) async {
    final response = await client
        .from('profiles')
        .update(profile.toJson())
        .eq('id', profile.id)
        .select()
        .single();
    return UserProfile.fromJson(response);
  }

  /// Создать профиль если нет, обновить если есть
  Future<UserProfile> upsertProfile(UserProfile profile) async {
    final existing = await getProfile(profile.id);
    if (existing != null) {
      return updateProfile(profile);
    } else {
      return createProfile(profile);
    }
  }

  /// Загрузить фото профиля в Supabase Storage (bucket 'avatars')
  /// и вернуть публичный URL. Требует создания bucket'а (см. supabase_schema.sql).
  Future<String> uploadProfilePhoto(String userId, XFile file) async {
    final Uint8List bytes = await file.readAsBytes();
    final name = file.name;
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : 'jpg';
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';
    await client.storage
        .from('avatars')
        .uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true));
    return client.storage.from('avatars').getPublicUrl(path);
  }

  // ────────────────────────────────────────────────────────────
  // WEIGHT ENTRIES
  // ────────────────────────────────────────────────────────────

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
    // Фильтруем по дате прямо в запросе (было: тянули всю историю пользователя
    // и фильтровали в Dart — лишний трафик и память при долгой истории).
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
    return (response as List).map((e) => WeightEntry.fromJson(e)).toList();
  }

  // ────────────────────────────────────────────────────────────
  // WATER ENTRIES
  // ────────────────────────────────────────────────────────────

  Future<WaterEntry> addWaterEntry(WaterEntry entry) async {
    final response = await client
        .from('water_entries')
        .insert(entry.toJson())
        .select()
        .single();
    return WaterEntry.fromJson(response);
  }

  Future<List<WaterEntry>> getWaterEntries(String userId, DateTime date) async {
    final dateStr = date.toIso8601String().substring(0, 10);
    final response = await client
        .from('water_entries')
        .select()
        .eq('user_id', userId)
        .eq('date', dateStr)
        .order('created_at');
    return (response as List).map((e) => WaterEntry.fromJson(e)).toList();
  }

  Future<int> getDailyWaterTotal(String userId, DateTime date) async {
    final dateStr = date.toIso8601String().substring(0, 10);
    final response = await client
        .from('water_entries')
        .select('amount_ml')
        .eq('user_id', userId)
        .eq('date', dateStr);
    final entries = response as List;
    if (entries.isEmpty) return 0;
    return entries.fold<int>(0, (sum, e) => sum + (e['amount_ml'] as int));
  }

  // ────────────────────────────────────────────────────────────
  // FOOD DIARY
  // ────────────────────────────────────────────────────────────

  Future<FoodEntry> addFoodEntry(FoodEntry entry) async {
    final response = await client
        .from('food_entries')
        .insert(entry.toJson())
        .select()
        .single();
    return FoodEntry.fromJson(response);
  }

  Future<List<FoodEntry>> getFoodEntries(String userId, DateTime date) async {
    final dateStr = date.toIso8601String().substring(0, 10);
    final response = await client
        .from('food_entries')
        .select()
        .eq('user_id', userId)
        .eq('date', dateStr)
        .order('created_at');
    return (response as List).map((e) => FoodEntry.fromJson(e)).toList();
  }

  Future<int> getDailyCalories(String userId, DateTime date) async {
    final dateStr = date.toIso8601String().substring(0, 10);
    final response = await client
        .from('daily_nutrition')
        .select('total_calories')
        .eq('user_id', userId)
        .eq('date', dateStr)
        .maybeSingle();
    return response?['total_calories'] as int? ?? 0;
  }

  // ────────────────────────────────────────────────────────────
  // MEAL ITEMS
  // ────────────────────────────────────────────────────────────

  Future<MealItem> addMealItem(MealItem item) async {
    final response = await client
        .from('meal_items')
        .insert(item.toJson())
        .select()
        .single();
    return MealItem.fromJson(response);
  }

  Future<MealItem> updateMealItem({
    required String id,
    required String name,
    required int calories,
    double? proteinGrams,
    double? fatGrams,
    double? carbsGrams,
    double? amountGrams,
    String? info,
  }) async {
    final response = await client
        .from('meal_items')
        .update({
          'name': name,
          'calories': calories,
          'protein_grams': proteinGrams,
          'fat_grams': fatGrams,
          'carbs_grams': carbsGrams,
          'amount_grams': amountGrams,
          'info': info,
        })
        .eq('id', id)
        .select()
        .single();
    return MealItem.fromJson(response);
  }

  Future<void> deleteMealItem(String itemId) async {
    await client.from('meal_items').delete().eq('id', itemId);
  }

  Future<void> deleteFoodEntry(String foodEntryId) async {
    await client.from('food_entries').delete().eq('id', foodEntryId);
  }

  Future<void> updateFoodEntryTotalCalories(
    String foodEntryId,
    int totalCalories,
  ) async {
    await client
        .from('food_entries')
        .update({'total_calories': totalCalories})
        .eq('id', foodEntryId);
  }

  /// Батч-версия getMealItems: одним запросом тянет позиции сразу для
  /// нескольких приёмов пищи (устраняет N+1 запросов в DailyTracker.loadToday).
  Future<List<MealItem>> getMealItemsForEntries(
    List<String> foodEntryIds,
  ) async {
    if (foodEntryIds.isEmpty) return [];
    final response = await client
        .from('meal_items')
        .select()
        .inFilter('food_entry_id', foodEntryIds)
        .order('created_at');
    return (response as List).map((e) => MealItem.fromJson(e)).toList();
  }

  Future<List<MealItem>> getMealItems(String foodEntryId) async {
    final response = await client
        .from('meal_items')
        .select()
        .eq('food_entry_id', foodEntryId)
        .order('created_at');
    return (response as List).map((e) => MealItem.fromJson(e)).toList();
  }

  // ────────────────────────────────────────────────────────────
  // BODY MEASUREMENTS (замеры тела)
  // ────────────────────────────────────────────────────────────

  Future<BodyMeasurement> saveBodyMeasurement(
    BodyMeasurement measurement,
  ) async {
    final existing = await client
        .from('body_measurements')
        .select()
        .eq('user_id', measurement.userId)
        .eq('date', measurement.date.toIso8601String().substring(0, 10))
        .maybeSingle();

    if (existing != null) {
      final updateData = measurement.toJson()..remove('id');
      final response = await client
          .from('body_measurements')
          .update(updateData)
          .eq('id', existing['id'])
          .select()
          .single();
      return BodyMeasurement.fromJson(response);
    } else {
      final response = await client
          .from('body_measurements')
          .insert(measurement.toJson())
          .select()
          .single();
      return BodyMeasurement.fromJson(response);
    }
  }

  Future<List<BodyMeasurement>> getBodyMeasurements(
    String userId, {
    DateTime? from,
    DateTime? to,
  }) async {
    var query = client
        .from('body_measurements')
        .select()
        .eq('user_id', userId)
        .order('date', ascending: false);

    final response = await query;
    final measurements = (response as List)
        .map((e) => BodyMeasurement.fromJson(e))
        .toList();

    if (from != null) {
      measurements.removeWhere((e) => e.date.isBefore(from));
    }
    if (to != null) {
      measurements.removeWhere((e) => e.date.isAfter(to));
    }

    return measurements;
  }

  // ────────────────────────────────────────────────────────────
  // BODY FAT ENTRIES (% жира)
  // ────────────────────────────────────────────────────────────

  Future<BodyFatEntry> saveBodyFatEntry(BodyFatEntry entry) async {
    final existing = await client
        .from('body_fat_entries')
        .select()
        .eq('user_id', entry.userId)
        .eq('date', entry.date.toIso8601String().substring(0, 10))
        .maybeSingle();

    if (existing != null) {
      final updateData = entry.toJson()..remove('id');
      final response = await client
          .from('body_fat_entries')
          .update(updateData)
          .eq('id', existing['id'])
          .select()
          .single();
      return BodyFatEntry.fromJson(response);
    } else {
      final response = await client
          .from('body_fat_entries')
          .insert(entry.toJson())
          .select()
          .single();
      return BodyFatEntry.fromJson(response);
    }
  }

  Future<List<BodyFatEntry>> getBodyFatEntries(
    String userId, {
    DateTime? from,
    DateTime? to,
  }) async {
    var query = client
        .from('body_fat_entries')
        .select()
        .eq('user_id', userId)
        .order('date', ascending: false);

    final response = await query;
    final entries = (response as List)
        .map((e) => BodyFatEntry.fromJson(e))
        .toList();

    if (from != null) {
      entries.removeWhere((e) => e.date.isBefore(from));
    }
    if (to != null) {
      entries.removeWhere((e) => e.date.isAfter(to));
    }

    return entries;
  }

  // ────────────────────────────────────────────────────────────
  // ACTIVITY LOGS
  // ────────────────────────────────────────────────────────────

  Future<ActivityLog> saveActivityLog(ActivityLog log) async {
    // Upsert — если запись за сегодня есть, обновляем
    final existing = await client
        .from('activity_logs')
        .select()
        .eq('user_id', log.userId)
        .eq('date', log.date.toIso8601String().substring(0, 10))
        .maybeSingle();

    if (existing != null) {
      final updateData = log.toJson()..remove('id');
      final response = await client
          .from('activity_logs')
          .update(updateData)
          .eq('id', existing['id'])
          .select()
          .single();
      return ActivityLog.fromJson(response);
    } else {
      final response = await client
          .from('activity_logs')
          .insert(log.toJson())
          .select()
          .single();
      return ActivityLog.fromJson(response);
    }
  }

  Future<List<ActivityLog>> getActivityLogs(
    String userId, {
    DateTime? from,
    DateTime? to,
  }) async {
    var query = client
        .from('activity_logs')
        .select()
        .eq('user_id', userId)
        .order('date', ascending: false);

    final response = await query;
    final logs = (response as List)
        .map((e) => ActivityLog.fromJson(e))
        .toList();

    // Фильтруем по дате в Dart
    if (from != null) {
      logs.removeWhere((e) => e.date.isBefore(from));
    }
    if (to != null) {
      logs.removeWhere((e) => e.date.isAfter(to));
    }

    return logs;
  }

  // ────────────────────────────────────────────────────────────
  // DAILY NUTRITION SUMMARY
  // ────────────────────────────────────────────────────────────

  Future<DailyNutrition> getOrCreateDailyNutrition(
    String userId,
    DateTime date,
  ) async {
    final dateStr = date.toIso8601String().substring(0, 10);
    final existing = await client
        .from('daily_nutrition')
        .select()
        .eq('user_id', userId)
        .eq('date', dateStr)
        .maybeSingle();

    if (existing != null) {
      return DailyNutrition.fromJson(existing);
    }

    final response = await client
        .from('daily_nutrition')
        .insert({'user_id': userId, 'date': dateStr})
        .select()
        .single();
    return DailyNutrition.fromJson(response);
  }

  Future<DailyNutrition> updateDailyNutrition(DailyNutrition nutrition) async {
    final response = await client
        .from('daily_nutrition')
        .update(nutrition.toJson())
        .eq('id', nutrition.id)
        .select()
        .single();
    return DailyNutrition.fromJson(response);
  }
}
