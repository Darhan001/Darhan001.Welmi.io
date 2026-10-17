/// Клиент Open Food Facts.
///
/// Официальная документация: https://openfoodfacts.github.io/openfoodfacts-server/api/
///
/// Используются два публичных эндпоинта:
///  * поиск по названию — Search-a-licious: https://search.openfoodfacts.org/search
///    (полнотекстовый поиск в API v2/v3 отсутствует);
///  * продукт по штрихкоду — Product Opener v3:
///    https://world.openfoodfacts.org/api/v3/product/{barcode}.json
///
/// Правила сервиса, которые соблюдает клиент:
///  * кастомный User-Agent с названием приложения и контактом;
///  * не более 10 поисковых запросов в минуту (поиск только по кнопке,
///    не «по мере ввода»);
///  * не более 15 запросов продукта в минуту;
///  * результаты по штрихкоду кэшируются в рамках сессии.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import 'package:lumina/features/food_database/domain/models/food_product.dart';

/// Ошибка обращения к Open Food Facts с готовым для показа сообщением.
class OpenFoodFactsException implements Exception {
  final String message;

  /// Сколько осталось до конца локального ограничения частоты запросов.
  final Duration? retryAfter;

  const OpenFoodFactsException(this.message, {this.retryAfter});

  @override
  String toString() => message;
}

class OpenFoodFactsService {
  static final OpenFoodFactsService _instance = OpenFoodFactsService._();

  factory OpenFoodFactsService() => _instance;

  OpenFoodFactsService._({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  static const String _userAgent = 'Welmi/1.0.1 (support@welmi.app)';

  static const String _searchHost = 'search.openfoodfacts.org';
  static const String _productHost = 'world.openfoodfacts.org';

  static const Duration _requestTimeout = Duration(seconds: 15);

  /// 10 запросов в минуту => минимум 6 секунд между поисками.
  static const Duration _searchInterval = Duration(seconds: 6);

  /// 15 запросов в минуту => минимум 4 секунды между запросами продукта.
  static const Duration _productInterval = Duration(seconds: 4);

  static const String _searchFields =
      'code,product_name,product_name_ru,product_name_en,generic_name,'
      'brands,nutriments,quantity,serving_size,nutriscore_grade';

  static const String _productFields =
      'code,product_name,product_name_ru,product_name_en,generic_name,'
      'brands,nutriments,quantity,serving_size,nutriscore_grade';

  DateTime? _lastSearchAt;
  DateTime? _lastProductAt;

  final Map<String, FoodProduct> _barcodeCache = {};
  static const int _maxCachedProducts = 100;

  /// Полнотекстовый поиск продуктов по названию.
  ///
  /// [pageSize] ограничен 50, чтобы не тратить трафик и лимиты.
  Future<List<FoodProduct>> search(
    String query, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final normalized = query.trim();
    if (normalized.isEmpty) return const [];

    _checkRateLimit(_lastSearchAt, _searchInterval);
    _lastSearchAt = DateTime.now();

    final uri = Uri.https(_searchHost, '/search', {
      'q': normalized,
      'page': '${math.max(1, page)}',
      'page_size': '${pageSize.clamp(1, 50)}',
      'fields': _searchFields,
    });

    final response = await _request(uri);
    if (response.statusCode == 429) {
      throw const OpenFoodFactsException(
        'Open Food Facts ограничил частоту запросов. Подожди минуту и повтори.',
      );
    }
    if (response.statusCode != 200) {
      throw OpenFoodFactsException(
        'Open Food Facts временно недоступен (код ${response.statusCode}).',
      );
    }

    final json = _decode(response);
    final hits = json['hits'];
    if (hits is! List) return const [];

    final products = <FoodProduct>[];
    final seen = <String>{};
    for (final hit in hits) {
      if (hit is! Map) continue;
      final product = parseSearchHit(Map<String, dynamic>.from(hit));
      if (product == null) continue;
      if (seen.add(product.barcode)) products.add(product);
    }
    return products;
  }

  /// Продукт по штрихкоду. `null` — продукт не найден в открытой базе.
  Future<FoodProduct?> fetchByBarcode(String rawBarcode) async {
    final barcode = rawBarcode.replaceAll(RegExp(r'\D'), '');
    if (barcode.isEmpty) return null;

    final cached = _barcodeCache[barcode];
    if (cached != null) return cached;

    _checkRateLimit(_lastProductAt, _productInterval);
    _lastProductAt = DateTime.now();

    final uri = Uri.https(_productHost, '/api/v3/product/$barcode.json', {
      'fields': _productFields,
    });

    final response = await _request(uri);
    if (response.statusCode == 404) return null;
    if (response.statusCode == 429) {
      throw const OpenFoodFactsException(
        'Open Food Facts ограничил частоту запросов. Подожди минуту и повтори.',
      );
    }
    if (response.statusCode != 200) {
      throw OpenFoodFactsException(
        'Open Food Facts временно недоступен (код ${response.statusCode}).',
      );
    }

    final json = _decode(response);
    if (json['status'] == 'failure') return null;

    final rawProduct = json['product'];
    if (rawProduct is! Map) return null;

    final product = parseProduct(
      Map<String, dynamic>.from(rawProduct),
      fallbackBarcode: barcode,
    );
    if (product != null) {
      if (_barcodeCache.length >= _maxCachedProducts) {
        _barcodeCache.remove(_barcodeCache.keys.first);
      }
      _barcodeCache[barcode] = product;
    }
    return product;
  }

  /// Разбор одного результата поиска. Возвращает `null`, если в записи нет
  /// штрихкода или названия — такие результаты бесполезны в дневнике.
  static FoodProduct? parseSearchHit(Map<String, dynamic> hit) {
    final barcode = _text(hit['code']);
    final name = _firstText(hit, const [
      'product_name',
      'product_name_ru',
      'product_name_en',
      'generic_name',
    ]);
    if (barcode == null || name == null) return null;

    final nutriments = _map(hit['nutriments']);
    return FoodProduct(
      barcode: barcode,
      name: name,
      brand: _brand(hit['brands']),
      kcalPer100g: _energyKcal(nutriments),
      proteinPer100g: _number(nutriments['proteins_100g']),
      fatPer100g: _number(nutriments['fat_100g']),
      carbsPer100g: _number(nutriments['carbohydrates_100g']),
      quantity: _text(hit['quantity']),
      servingSize: _text(hit['serving_size']),
      nutriscoreGrade: _text(hit['nutriscore_grade']),
    );
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

    final name =
        _firstText(product, const [
          'product_name',
          'product_name_ru',
          'product_name_en',
          'generic_name',
        ]) ??
        'Продукт $barcode';

    final nutriments = _map(product['nutriments']);
    return FoodProduct(
      barcode: barcode,
      name: name,
      brand: _brand(product['brands']),
      kcalPer100g: _energyKcal(nutriments),
      proteinPer100g: _number(nutriments['proteins_100g']),
      fatPer100g: _number(nutriments['fat_100g']),
      carbsPer100g: _number(nutriments['carbohydrates_100g']),
      quantity: _text(product['quantity']),
      servingSize: _text(product['serving_size']),
      nutriscoreGrade: _text(product['nutriscore_grade']),
    );
  }

  // ────────────────────────────────────────────────────────────
  // HTTP
  // ────────────────────────────────────────────────────────────

  Future<http.Response> _request(Uri uri) async {
    try {
      return await _client
          .get(uri, headers: const {'User-Agent': _userAgent})
          .timeout(_requestTimeout);
    } on TimeoutException {
      throw const OpenFoodFactsException(
        'Open Food Facts не ответил вовремя. Проверь интернет и повтори.',
      );
    } on http.ClientException {
      throw const OpenFoodFactsException(
        'Нет связи с Open Food Facts. Проверь интернет и повтори.',
      );
    } catch (_) {
      throw const OpenFoodFactsException(
        'Не удалось загрузить данные из Open Food Facts. Попробуй ещё раз.',
      );
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } on FormatException {
      // Ниже вернём понятную ошибку.
    }
    throw const OpenFoodFactsException(
      'Open Food Facts вернул некорректный ответ. Попробуй позже.',
    );
  }

  void _checkRateLimit(DateTime? lastRequestAt, Duration interval) {
    if (lastRequestAt == null) return;
    final elapsed = DateTime.now().difference(lastRequestAt);
    if (elapsed >= interval) return;

    final wait = interval - elapsed;
    throw OpenFoodFactsException(
      'Слишком много запросов. Повтори через ${wait.inSeconds + 1} с.',
      retryAfter: wait,
    );
  }

  // ────────────────────────────────────────────────────────────
  // Парсинг значений (данные в базе неполные и разнотипные)
  // ────────────────────────────────────────────────────────────

  static Map<String, dynamic> _map(dynamic value) {
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
