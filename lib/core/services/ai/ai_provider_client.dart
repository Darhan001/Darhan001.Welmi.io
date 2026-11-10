import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Сетевой доступ к AI-провайдерам: OpenRouter и Gemini REST.
///
/// Ключи приходят только из `AiService.initialize` (а туда — из
/// `AppConfig`, `String.fromEnvironment`). Значения ключей не логируются:
/// ключ Gemini передаётся заголовком `x-goog-api-key`, а не в URL, поэтому
/// не попадает в текст `ClientException` при сетевой ошибке.
class AiProviderClient {
  AiProviderClient({http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  final http.Client _http;

  static const _openRouterBase = 'https://openrouter.ai/api/v1';
  static const _geminiBase =
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// Модели OpenRouter для текста. Последняя бесплатная: даже с нулевым
  /// балансом чат отвечает, когда платные вернули 402.
  static const openRouterTextModels = [
    'google/gemini-2.5-flash',
    'google/gemini-2.5-flash-lite',
    'nvidia/nemotron-3-super-120b-a12b:free',
  ];
  static const geminiModels = ['gemini-2.5-flash', 'gemini-2.0-flash'];

  String? openRouterKey;
  String? scannerApiKey; // отдельный ключ только для сканера еды
  String? geminiKey; // ключ Google AI Studio (GEMINI_NUTRITION_API_KEY)

  /// Последняя причина, по которой AI-провайдер отказал. Нужна, чтобы вместо
  /// общего «проверьте интернет» показать пользователю реальную причину.
  String? lastIssue;

  void noteStatus(int status) {
    lastIssue = switch (status) {
      401 || 403 => 'ключ AI-провайдера не принят',
      402 => 'закончились кредиты AI-провайдера (OpenRouter)',
      429 => 'AI-провайдер временно ограничил запросы (429)',
      >= 500 => 'AI-провайдер временно недоступен ($status)',
      _ => 'ошибка AI-провайдера (HTTP $status)',
    };
  }

  /// Ключи текстовых запросов (основной и сканера).
  List<String> get _textKeys =>
      [openRouterKey, scannerApiKey].whereType<String>().toList();

  /// OpenRouter принимает только ключи вида sk-or-…; остальные пропускаем,
  /// чтобы не тратить время на гарантированные 401.
  List<String> get openRouterKeys =>
      _textKeys.where((k) => k.startsWith('sk-or-')).toList();

  Future<http.Response> postOpenRouter(
    String path,
    String key,
    Map<String, Object?> body,
    Duration timeout,
  ) {
    return _http
        .post(
          Uri.parse('$_openRouterBase/$path'),
          headers: {
            'Authorization': 'Bearer $key',
            'Content-Type': 'application/json',
            'HTTP-Referer': 'https://welmi.app',
          },
          body: jsonEncode(body),
        )
        .timeout(timeout);
  }

  Future<http.Response> postGemini(
    String model,
    String key,
    Map<String, Object?> body,
    Duration timeout,
  ) {
    return _http
        .post(
          Uri.parse('$_geminiBase/$model:generateContent'),
          headers: {'Content-Type': 'application/json', 'x-goog-api-key': key},
          body: jsonEncode(body),
        )
        .timeout(timeout);
  }

  /// Текст ответа OpenRouter (`choices[0].message.content`) или null.
  /// У reasoning-моделей content может быть null — не падаем.
  static String? openRouterText(String body) {
    final data = _decodeMap(body);
    final choices = data?['choices'];
    if (choices is! List || choices.isEmpty) return null;
    final first = choices.first;
    final message = first is Map ? first['message'] : null;
    final content = message is Map ? message['content'] : null;
    return content is String ? content : null;
  }

  /// Текстовые части первого кандидата Gemini.
  static List<String> geminiParts(String body) {
    final candidates = _decodeMap(body)?['candidates'];
    if (candidates is! List || candidates.isEmpty) return const [];
    final first = candidates.first;
    final content = first is Map ? first['content'] : null;
    final parts = content is Map ? content['parts'] : null;
    if (parts is! List) return const [];
    return [
      for (final part in parts)
        if (part is Map && part['text'] is String) part['text'] as String,
    ];
  }

  static Map<String, dynamic>? _decodeMap(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }

  /// Универсальная попытка получить ответ от AI.
  /// Пробует по цепочке: OpenRouter (валидные sk-or- ключи × модели) →
  /// Gemini REST напрямую (ключи AIza × модели). Если всё упало — null.
  ///
  /// [budget] — общий лимит времени: по его исчерпании новые попытки не
  /// начинаются, поэтому внешний `timeout` не оставляет запросы «висеть»
  /// в фоне по всей цепочке ключей и моделей.
  Future<String?> complete({
    required String systemPrompt,
    required String userPrompt,
    int maxTokens = 1000,
    List<Map<String, String>>? history,
    Duration budget = const Duration(seconds: 60),
  }) async {
    final deadline = DateTime.now().add(budget);
    Duration? slot(int seconds) {
      final left = deadline.difference(DateTime.now());
      if (left <= Duration.zero) return null;
      final cap = Duration(seconds: seconds);
      return left < cap ? left : cap;
    }

    // 1) OpenRouter — все валидные ключи и актуальные модели.
    for (final key in openRouterKeys) {
      for (final model in openRouterTextModels) {
        final timeout = slot(25);
        if (timeout == null) return null;
        try {
          final response = await postOpenRouter('chat/completions', key, {
            'model': model,
            'max_tokens': maxTokens,
            'messages': [
              {'role': 'system', 'content': systemPrompt},
              ...?history,
              {'role': 'user', 'content': userPrompt},
            ],
          }, timeout);
          if (response.statusCode == 200) {
            final text = openRouterText(response.body);
            if (text != null && text.isNotEmpty) return text;
            lastIssue = 'AI-провайдер вернул пустой ответ';
          } else {
            noteStatus(response.statusCode);
            debugPrint('⚠️ AI HTTP ${response.statusCode} ($model)');
          }
        } catch (e) {
          lastIssue = 'нет связи с AI-провайдером';
          debugPrint('⚠️ AI error with $model: $e');
        }
      }
    }

    // 2) Gemini REST напрямую — только ключи Google AI Studio
    // (начинаются с 'AIza'). OpenRouter-ключи здесь не работают.
    final geminiKeys = _textKeys.where((k) => k.startsWith('AIza'));
    final historyText = history == null
        ? ''
        : '\n\n${history.map((m) => '${m['role']}: ${m['content']}').join('\n')}';
    for (final key in geminiKeys) {
      for (final model in geminiModels) {
        final timeout = slot(25);
        if (timeout == null) return null;
        try {
          final response = await postGemini(model, key, {
            'contents': [
              {
                'parts': [
                  {
                    'text':
                        '$systemPrompt$historyText\n\nПользователь: $userPrompt',
                  },
                ],
              },
            ],
            'generationConfig': {'maxOutputTokens': maxTokens},
          }, timeout);
          if (response.statusCode == 200) {
            for (final text in geminiParts(response.body)) {
              if (text.isNotEmpty) return text;
            }
          } else {
            noteStatus(response.statusCode);
            debugPrint('⚠️ Gemini HTTP ${response.statusCode} ($model)');
          }
        } catch (e) {
          lastIssue = 'нет связи с AI-провайдером';
          debugPrint('⚠️ Gemini error with $model: $e');
        }
      }
    }

    return null;
  }
}
