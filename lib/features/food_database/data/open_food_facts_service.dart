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
///    не «по мере ввода» — поэтому debounce не нужен);
///  * не более 15 запросов продукта в минуту;
///  * результаты по штрихкоду кэшируются в рамках сессии.
///
/// Разбор ответов — в [OpenFoodFactsParser].
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:lumina/features/food_database/data/open_food_facts_parser.dart';
import 'package:lumina/features/food_database/domain/models/food_product.dart';

/// Почему запрос к Open Food Facts не выполнен.
enum OpenFoodFactsFailure {
  /// Сервер ответил 429.
  rateLimited,

  /// Локальный лимит частоты: см. [OpenFoodFactsException.retryAfter].
  tooManyRequests,
  timeout,
  network,
  request,

  /// HTTP-ошибка: см. [OpenFoodFactsException.statusCode].
  unavailable,
  badResponse,
}

/// Ошибка обращения к Open Food Facts. Текст для пользователя строит UI
/// из локализации (`openFoodFactsMessage`), а не сервис.
class OpenFoodFactsException implements Exception {
  final OpenFoodFactsFailure failure;

  /// Сколько осталось до конца локального ограничения частоты запросов.
  final Duration? retryAfter;

  /// Код ответа для [OpenFoodFactsFailure.unavailable].
  final int? statusCode;

  const OpenFoodFactsException(
    this.failure, {
    this.retryAfter,
    this.statusCode,
  });

  @override
  String toString() => 'OpenFoodFactsException(${failure.name})';
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

  static const String _fields =
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
      'fields': _fields,
    });

    final response = await _request(uri);
    _throwOnHttpError(response);

    final hits = _decode(response)['hits'];
    if (hits is! List) return const [];

    final products = <FoodProduct>[];
    final seen = <String>{};
    for (final hit in hits) {
      if (hit is! Map) continue;
      final product = OpenFoodFactsParser.parseSearchHit(
        OpenFoodFactsParser.asJsonMap(hit),
      );
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
      'fields': _fields,
    });

    final response = await _request(uri);
    if (response.statusCode == 404) return null;
    _throwOnHttpError(response);

    final json = _decode(response);
    if (json['status'] == 'failure') return null;

    final rawProduct = json['product'];
    if (rawProduct is! Map) return null;

    final product = OpenFoodFactsParser.parseProduct(
      OpenFoodFactsParser.asJsonMap(rawProduct),
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

  /// Разбор результата поиска — см. [OpenFoodFactsParser.parseSearchHit].
  static FoodProduct? parseSearchHit(Map<String, dynamic> hit) =>
      OpenFoodFactsParser.parseSearchHit(hit);

  /// Разбор продукта по штрихкоду — см. [OpenFoodFactsParser.parseProduct].
  static FoodProduct? parseProduct(
    Map<String, dynamic> product, {
    String? fallbackBarcode,
  }) => OpenFoodFactsParser.parseProduct(
    product,
    fallbackBarcode: fallbackBarcode,
  );

  // ────────────────────────────────────────────────────────────
  // HTTP
  // ────────────────────────────────────────────────────────────

  Future<http.Response> _request(Uri uri) async {
    try {
      return await _client
          .get(uri, headers: const {'User-Agent': _userAgent})
          .timeout(_requestTimeout);
    } on TimeoutException {
      throw const OpenFoodFactsException(OpenFoodFactsFailure.timeout);
    } on http.ClientException catch (e) {
      debugPrint('Open Food Facts: no connection: $e');
      throw const OpenFoodFactsException(OpenFoodFactsFailure.network);
    } catch (e) {
      debugPrint('Open Food Facts: request failed: $e');
      throw const OpenFoodFactsException(OpenFoodFactsFailure.request);
    }
  }

  void _throwOnHttpError(http.Response response) {
    if (response.statusCode == 429) {
      throw const OpenFoodFactsException(OpenFoodFactsFailure.rateLimited);
    }
    if (response.statusCode != 200) {
      throw OpenFoodFactsException(
        OpenFoodFactsFailure.unavailable,
        statusCode: response.statusCode,
      );
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map) return OpenFoodFactsParser.asJsonMap(decoded);
    } on FormatException {
      // Ниже вернём понятную ошибку.
    }
    throw const OpenFoodFactsException(OpenFoodFactsFailure.badResponse);
  }

  void _checkRateLimit(DateTime? lastRequestAt, Duration interval) {
    if (lastRequestAt == null) return;
    final elapsed = DateTime.now().difference(lastRequestAt);
    if (elapsed >= interval) return;

    final wait = interval - elapsed;
    throw OpenFoodFactsException(
      OpenFoodFactsFailure.tooManyRequests,
      retryAfter: wait,
    );
  }
}
