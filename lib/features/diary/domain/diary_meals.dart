import 'package:lumina/core/models/supabase_models.dart';

/// Записи дневника за день, разложенные по приёмам пищи.
///
/// Калории приёма пищи считаются по `FoodEntry.totalCalories`, как и раньше:
/// одна запись дневника = один `FoodEntry` + один `MealItem`.
class DiaryMeals {
  DiaryMeals._(this._items, this._totals);

  /// Пустой день: у каждого приёма пищи пустой список и 0 ккал.
  factory DiaryMeals.empty() => DiaryMeals._(
    {for (final type in MealType.values) type: <MealItem>[]},
    {for (final type in MealType.values) type: 0},
  );

  /// Раскладывает позиции по приёмам пищи в порядке записей [entries]
  /// (внутри записи — в порядке [items]).
  factory DiaryMeals.fromEntries(
    List<FoodEntry> entries,
    List<MealItem> items,
  ) {
    final meals = DiaryMeals.empty();
    final byEntry = <String, List<MealItem>>{};
    for (final item in items) {
      byEntry.putIfAbsent(item.foodEntryId, () => []).add(item);
    }
    for (final entry in entries) {
      meals._items[entry.mealType]!.addAll(byEntry[entry.id] ?? const []);
      meals._totals[entry.mealType] =
          meals.caloriesOf(entry.mealType) + entry.totalCalories;
    }
    return meals;
  }

  final Map<MealType, List<MealItem>> _items;
  final Map<MealType, int> _totals;

  List<MealItem> itemsOf(MealType type) => List.unmodifiable(_items[type]!);

  int caloriesOf(MealType type) => _totals[type] ?? 0;

  int get totalCalories => _totals.values.fold(0, (sum, v) => sum + v);

  /// Добавляет только что сохранённую позицию без перезагрузки дня.
  void add(MealType type, MealItem item, int calories) {
    _items[type]!.add(item);
    _totals[type] = caloriesOf(type) + calories;
  }
}
