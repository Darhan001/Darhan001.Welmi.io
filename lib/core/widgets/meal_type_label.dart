import 'package:lumina/core/models/supabase_models.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Локализованное название приёма пищи. Единственное место сопоставления
/// [MealType] → строка: раньше одинаковый switch повторялся на нескольких
/// экранах, а на странице рецепта названия были записаны по-русски.
extension MealTypeLabel on AppLocalizations {
  String mealTypeLabel(MealType type) => switch (type) {
    MealType.breakfast => breakfast,
    MealType.lunch => lunch,
    MealType.dinner => dinner,
    MealType.snack => snack,
  };
}
