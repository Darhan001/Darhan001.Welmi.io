import 'package:lumina/features/food_database/domain/models/food_product.dart';

/// Разбор ответов Open Food Facts.
///
/// Данные в базе неполные и разнотипные (числа строками, бренды массивом или
/// строкой), поэтому каждое поле читается без `as`-приведений: неожиданный
/// тип превращается в «нет данных», а не в исключение.
abstract final class OpenFoodFactsParser {
  static const _nameKeys = [
    'product_name',
    'product_name_ru',
    'product_name_en',
    'generic_name',
  ];

  /// Разбор одного результата поиска. Возвращает `null`, если в записи нет
  /// штрихкода или названия — такие результаты бесполезны в дневнике.
  static FoodProduct? parseSearchHit(Map<String, dynamic> hit) {
    final barcode = _text(hit['code']);
    final name = _firstText(hit, _nameKeys);
    if (barcode == null || name == null) return null;
    return _product(hit, barcode: barcode, name: name);
  }

  /// Разбор продукта из ответа `/api/v3/product/{barcode}.json`.
  ///
  /// Если название отсутствует, подставляется «Продукт {штрихкод}»:
  /// так пользователь видит, что запись найдена, но данных мало.
  static FoodProduct? parseProduct(
    Map<String, dynamic> product, {
    String? fallbackBarcode,
  }) {
    final barcode = _text(product['code']) ?? fallbackBarcode;
    if (barcode == null || barcode.isEmpty) return null;
    final name = _firstText(product, _nameKeys) ?? 'Продукт $barcode';
    return _product(product, barcode: barcode, name: name);
  }

  static FoodProduct _product(
    Map<String, dynamic> json, {
    required String barcode,
    required String name,
  }) {
    final nutriments = asJsonMap(json['nutriments']);
    return FoodProduct(
      barcode: barcode,
      name: name,
      brand: _brand(json['brands']),
      kcalPer100g: _energyKcal(nutriments),
      proteinPer100g: _number(nutriments['proteins_100g']),
      fatPer100g: _number(nutriments['fat_100g']),
      carbsPer100g: _number(nutriments['carbohydrates_100g']),
      quantity: _text(json['quantity']),
      servingSize: _text(json['serving_size']),
      nutriscoreGrade: _text(json['nutriscore_grade']),
    );
  }

  /// JSON-объект или пустая карта, если значение другого типа.
  static Map<String, dynamic> asJsonMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }

  static String? _text(dynamic value) {
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    if (value is num) return value.toString();
    return null;
  }

  static String? _firstText(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = _text(map[key]);
      if (value != null) return value;
    }
    return null;
  }

  /// В поиске `brands` — массив, в ответе продукта — строка через запятую.
  static String? _brand(dynamic value) {
    if (value is List) {
      for (final entry in value) {
        final text = _text(entry);
        if (text != null) return text;
      }
      return null;
    }
    final text = _text(value);
    if (text == null) return null;
    return text.split(',').first.trim();
  }

  static double? _number(dynamic value) {
    double? parsed;
    if (value is num) {
      parsed = value.toDouble();
    } else if (value is String) {
      parsed = double.tryParse(value.replaceAll(',', '.'));
    }
    if (parsed == null || !parsed.isFinite || parsed < 0) return null;
    // В базе встречаются float32-артефакты вида 4.69999980926514.
    // Двух знаков после запятой для нутриентов достаточно.
    return (parsed * 100).roundToDouble() / 100;
  }

  /// Калорийность на 100 г. Если в базе только килоджоули — переводим.
  static double? _energyKcal(Map<String, dynamic> nutriments) {
    final kcal = _number(nutriments['energy-kcal_100g']);
    if (kcal != null) return kcal;

    final kj =
        _number(nutriments['energy-kj_100g']) ??
        _number(nutriments['energy_100g']);
    if (kj != null) return (kj / 4.184 * 100).roundToDouble() / 100;
    return null;
  }
}
