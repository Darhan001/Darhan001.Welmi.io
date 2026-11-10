import 'package:lumina/core/models/supabase_models.dart';
import 'package:lumina/core/services/supabase_service.dart';
import 'package:lumina/features/diary/domain/diary_meals.dart';
import 'package:lumina/features/food_database/domain/models/food_product.dart';

/// Чтение и изменение записей дневника питания в Supabase.
class DiaryRepository {
  DiaryRepository({SupabaseService? supabase})
    : _supabase = supabase ?? SupabaseService();

  final SupabaseService _supabase;

  /// Записи за [date]. Позиции всех записей загружаются одним запросом,
  /// а не отдельным запросом на каждую запись.
  Future<DiaryMeals> loadDay(String userId, DateTime date) async {
    final entries = await _supabase.getFoodEntries(userId, date);
    final items = await _supabase.getMealItemsForEntries(
      entries.map((e) => e.id).toList(),
    );
    return DiaryMeals.fromEntries(entries, items);
  }

  /// Сохраняет [draft] как отдельную запись приёма пищи [mealType].
  Future<MealItem> add(
    String userId,
    MealType mealType,
    FoodDraft draft,
  ) async {
    return _supabase.addFoodEntryWithItem(
      FoodEntry(
        userId: userId,
        mealType: mealType,
        date: DateTime.now(),
        totalCalories: draft.calories,
      ),
      (entryId) => MealItem(
        foodEntryId: entryId,
        name: draft.name,
        calories: draft.calories,
        proteinGrams: draft.proteinGrams,
        fatGrams: draft.fatGrams,
        carbsGrams: draft.carbsGrams,
        amountGrams: draft.grams,
        info: draft.info.isEmpty ? null : draft.info,
      ),
    );
  }

  /// Обновляет позицию и калорийность её записи.
  Future<void> update(MealItem item, FoodDraft draft) async {
    await _supabase.updateMealItem(
      id: item.id,
      name: draft.name,
      calories: draft.calories,
      proteinGrams: draft.proteinGrams,
      fatGrams: draft.fatGrams,
      carbsGrams: draft.carbsGrams,
      amountGrams: draft.grams,
      info: draft.info.isEmpty ? null : draft.info,
    );
    await _supabase.updateFoodEntryTotalCalories(
      item.foodEntryId,
      draft.calories,
    );
  }

  /// Удаляет позицию вместе с её записью.
  Future<void> delete(MealItem item) async {
    await _supabase.deleteMealItem(item.id);
    await _supabase.deleteFoodEntry(item.foodEntryId);
  }
}
