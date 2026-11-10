import 'package:flutter/foundation.dart';
import 'package:lumina/core/models/supabase_models.dart';
import 'package:lumina/core/services/supabase/supabase_base.dart';

/// Дневник питания: приёмы пищи, их позиции и дневная сводка.
mixin DiaryQueries on SupabaseQueryBase {
  // ── Приёмы пищи ──

  Future<FoodEntry> addFoodEntry(FoodEntry entry) async {
    final response = await client
        .from('food_entries')
        .insert(entry.toJson())
        .select()
        .single();
    return FoodEntry.fromJson(response);
  }

  /// Создаёт запись приёма пищи вместе с её позицией.
  ///
  /// Два insert не атомарны: если позиция не сохранилась, только что
  /// созданная запись удаляется. Раньше оставалась «пустая» запись с
  /// калориями, а повторное нажатие после ошибки удваивало калории дня.
  Future<MealItem> addFoodEntryWithItem(
    FoodEntry entry,
    MealItem Function(String foodEntryId) buildItem,
  ) async {
    final created = await addFoodEntry(entry);
    try {
      return await addMealItem(buildItem(created.id));
    } catch (_) {
      try {
        await deleteFoodEntry(created.id);
      } catch (cleanupError) {
        debugPrint('⚠️ Orphan food entry cleanup failed: $cleanupError');
      }
      rethrow;
    }
  }

  Future<List<FoodEntry>> getFoodEntries(String userId, DateTime date) async {
    final response = await client
        .from('food_entries')
        .select()
        .eq('user_id', userId)
        .eq('date', SupabaseQueryBase.day(date))
        .order('created_at');
    return response.map(FoodEntry.fromJson).toList();
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

  // ── Позиции приёма пищи ──

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
    return response.map(MealItem.fromJson).toList();
  }

  Future<List<MealItem>> getMealItems(String foodEntryId) async {
    final response = await client
        .from('meal_items')
        .select()
        .eq('food_entry_id', foodEntryId)
        .order('created_at');
    return response.map(MealItem.fromJson).toList();
  }
}
