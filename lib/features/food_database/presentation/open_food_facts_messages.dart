import 'package:lumina/features/food_database/data/open_food_facts_service.dart';
import 'package:lumina/features/food_database/domain/models/food_product.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Текст ошибки Open Food Facts на языке приложения.
String openFoodFactsMessage(AppLocalizations loc, OpenFoodFactsException e) {
  return switch (e.failure) {
    OpenFoodFactsFailure.rateLimited => loc.offErrRateLimited,
    OpenFoodFactsFailure.tooManyRequests => loc.offErrTooMany(
      (e.retryAfter?.inSeconds ?? 0) + 1,
    ),
    OpenFoodFactsFailure.timeout => loc.offErrTimeout,
    OpenFoodFactsFailure.network => loc.offErrNetwork,
    OpenFoodFactsFailure.request => loc.offErrRequest,
    OpenFoodFactsFailure.unavailable => loc.offErrUnavailable(
      e.statusCode ?? 0,
    ),
    OpenFoodFactsFailure.badResponse => loc.offErrBadResponse,
  };
}

/// Вторая строка карточки продукта: бренд, фасовка и размер порции.
String productSubtitle(AppLocalizations loc, FoodProduct product) =>
    product.subtitleWith(loc.foodServingPrefix);

/// «На 100 г: 250 ккал · Б 10 г · Ж 5 г · У 30 г».
String per100Label(AppLocalizations loc, FoodProduct product) {
  if (!product.hasNutrition) return loc.foodPer100NoData;
  String grams(String letter, double? value) =>
      '$letter ${formatNutrient(value)} ${loc.gramsShort}';
  final parts = <String>[
    if (product.kcalPer100g != null)
      '${formatNutrient(product.kcalPer100g)} ${loc.kcal}',
    if (product.proteinPer100g != null)
      grams(loc.macroProteinShort, product.proteinPer100g),
    if (product.fatPer100g != null)
      grams(loc.macroFatShort, product.fatPer100g),
    if (product.carbsPer100g != null)
      grams(loc.macroCarbsShort, product.carbsPer100g),
  ];
  return loc.foodPer100(parts.join(' · '));
}
