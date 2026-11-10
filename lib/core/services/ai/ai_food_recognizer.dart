import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:lumina/core/services/ai/ai_food_models.dart';
import 'package:lumina/core/services/ai/ai_json.dart';
import 'package:lumina/core/services/ai/ai_prompts.dart';
import 'package:lumina/core/services/ai/ai_provider_client.dart';

/// Распознавание еды: по фото (сканер) и по тексту (голосовой ввод).
class AiFoodRecognizer {
  AiFoodRecognizer(this._client);

  final AiProviderClient _client;

  /// Актуальные vision-модели. Последняя — бесплатная: сканер продолжает
  /// работать, когда у платных моделей закончились кредиты (HTTP 402).
  static const _visionModels = [
    'google/gemini-2.5-flash',
    'google/gemini-2.5-flash-lite',
    'nvidia/nemotron-3.5-super-vl:free',
  ];

  /// Общий лимит сканирования: без него перебор ключей и моделей
  /// (до 75 с на бесплатную модель) держал экран в загрузке минутами.
  static const _imageBudget = Duration(seconds: 120);

  Future<FoodAnalysisResult?> analyzeImage(Uint8List imageBytes) async {
    final base64Image = base64Encode(imageBytes);
    final deadline = DateTime.now().add(_imageBudget);

    // 1) Сначала основной (рабочий) ключ, затем отдельный ключ сканера.
    //    OpenRouter принимает только ключи sk-or-.
    for (final key in [_client.openRouterKey, _client.scannerApiKey]) {
      if (key == null || !key.startsWith('sk-or-')) continue;
      final res = await _tryOpenRouter(key, base64Image, deadline);
      if (res != null) return res;
    }

    // 2) Если ключ не работает через OpenRouter — пробуем Gemini REST напрямую
    final scannerKey = _client.scannerApiKey;
    if (scannerKey != null && scannerKey.startsWith('AIza')) {
      final res = await _tryGemini(scannerKey, base64Image, deadline);
      if (res != null) return res;
    }
    return null;
  }

  /// Время на запрос: не больше [cap] и не дальше [deadline]; null — лимит
  /// исчерпан.
  static Duration? _slot(DateTime deadline, Duration cap) {
    final left = deadline.difference(DateTime.now());
    if (left <= Duration.zero) return null;
    return left < cap ? left : cap;
  }

  Future<FoodAnalysisResult?> _tryOpenRouter(
    String key,
    String base64Image,
    DateTime deadline,
  ) async {
    for (final model in _visionModels) {
      final isFree = model.endsWith(':free');
      final timeout = _slot(deadline, Duration(seconds: isFree ? 75 : 35));
      if (timeout == null) return null;
      try {
        // Бесплатная reasoning-модель тратит токены на размышления, ей нужен
        // больший лимит, иначе JSON-ответ обрезается.
        final response = await _client.postOpenRouter('chat/completions', key, {
          'model': model,
          'max_tokens': isFree ? 1800 : 500,
          'messages': [
            {
              'role': 'user',
              'content': [
                {'type': 'text', 'text': AiPrompts.foodImage},
                {
                  'type': 'image_url',
                  'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
                },
              ],
            },
          ],
        }, timeout);

        if (response.statusCode == 200) {
          final text = AiProviderClient.openRouterText(response.body);
          final res = text == null ? null : _parseFood(text);
          if (res != null) return res;
        } else {
          _client.noteStatus(response.statusCode);
          debugPrint('❌ Scanner HTTP ${response.statusCode} ($model)');
        }
      } catch (e) {
        _client.lastIssue = 'нет связи с AI-провайдером';
        debugPrint('❌ Scanner Error with $model: $e');
      }
    }
    return null;
  }

  Future<FoodAnalysisResult?> _tryGemini(
    String key,
    String base64Image,
    DateTime deadline,
  ) async {
    for (final model in AiProviderClient.geminiModels) {
      final timeout = _slot(deadline, const Duration(seconds: 35));
      if (timeout == null) return null;
      try {
        final response = await _client.postGemini(model, key, {
          'contents': [
            {
              'parts': [
                {'text': AiPrompts.foodImage},
                {
                  'inline_data': {
                    'mime_type': 'image/jpeg',
                    'data': base64Image,
                  },
                },
              ],
            },
          ],
        }, timeout);

        if (response.statusCode == 200) {
          for (final text in AiProviderClient.geminiParts(response.body)) {
            final res = text.isEmpty ? null : _parseFood(text);
            if (res != null) return res;
          }
        } else {
          debugPrint('❌ Scanner Gemini HTTP ${response.statusCode} ($model)');
        }
      } catch (e) {
        debugPrint('❌ Scanner Gemini Error with $model: $e');
      }
    }
    return null;
  }

  static FoodAnalysisResult? _parseFood(String text) {
    final json = extractJsonObject(text);
    return json == null ? null : FoodAnalysisResult.fromJson(json);
  }

  /// AI-анализ распознанного текста о съеденной пище (для голосового ввода
  /// в дневник). null — продукты определить не удалось.
  Future<VoiceFoodAnalysisResult?> analyzeText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    try {
      final responseText = await _client.complete(
        systemPrompt: AiPrompts.foodTextSystem,
        userPrompt: AiPrompts.foodTextUser(trimmed),
        maxTokens: 800,
        budget: const Duration(seconds: 60),
      );
      if (responseText != null && responseText.isNotEmpty) {
        final json = extractJsonObject(responseText);
        if (json != null) return VoiceFoodAnalysisResult.fromJson(json);
      }
    } catch (e) {
      debugPrint('⚠️ Voice food analysis error: $e');
    }
    return null;
  }
}
