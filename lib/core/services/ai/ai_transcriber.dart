import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:lumina/core/services/ai/ai_exceptions.dart';
import 'package:lumina/core/services/ai/ai_prompts.dart';
import 'package:lumina/core/services/ai/ai_provider_client.dart';

/// Облачное распознавание речи (speech-to-text).
class AiTranscriber {
  AiTranscriber(this._client);

  final AiProviderClient _client;

  static const _sttModels = ['openai/whisper-1', 'openai/whisper-large-v3'];
  static const _requestTimeout = Duration(seconds: 45);

  /// Уровни отказоустойчивости — как у сканера еды:
  ///   1) OpenRouter `/audio/transcriptions` (Whisper) — основной путь;
  ///   2) Gemini REST напрямую с `inline_data` (аудио) — запасной путь.
  ///
  /// Бросает [VoiceTranscriptionException] с причиной, если текст не получен.
  Future<String> transcribe(
    Uint8List audioBytes, {
    required String format,
    String? language,
  }) async {
    if (audioBytes.isEmpty) {
      throw const VoiceTranscriptionException(
        VoiceTranscriptionFailure.emptyResult,
      );
    }
    final orKeys = _client.openRouterKeys;
    // Раньше сюда не попадал GEMINI_NUTRITION_API_KEY, и запасной путь
    // распознавания пробовал только ключ сканера.
    final geminiKeys = <String?>[
      _client.geminiKey,
      _client.scannerApiKey,
      _client.openRouterKey,
    ].whereType<String>().where((k) => !k.startsWith('sk-or-')).toList();
    if (orKeys.isEmpty && geminiKeys.isEmpty) {
      throw const VoiceTranscriptionException(
        VoiceTranscriptionFailure.noApiKey,
      );
    }

    final base64Audio = base64Encode(audioBytes);
    var sawNetworkError = false;
    var sawEmptyResult = false;

    void noteError(Object e, String model) {
      // package:http оборачивает сбои сокета в ClientException.
      if (e is http.ClientException || e is TimeoutException) {
        sawNetworkError = true;
      }
      debugPrint('⚠️ STT error with $model: $e');
    }

    // 1) OpenRouter Speech-to-Text.
    for (final key in orKeys) {
      for (final model in _sttModels) {
        try {
          final response = await _client.postOpenRouter(
            'audio/transcriptions',
            key,
            {
              'model': model,
              'input_audio': {'data': base64Audio, 'format': format},
              'language': ?language,
            },
            _requestTimeout,
          );
          if (response.statusCode == 200) {
            final decoded = jsonDecode(response.body);
            final text = decoded is Map ? decoded['text'] : null;
            if (text is String && text.trim().isNotEmpty) return text.trim();
            sawEmptyResult = true;
          } else {
            debugPrint('⚠️ STT HTTP ${response.statusCode} ($model)');
          }
        } catch (e) {
          noteError(e, model);
        }
      }
    }

    // 2) Gemini REST напрямую: аудио передаётся как inline_data.
    for (final key in geminiKeys) {
      for (final model in AiProviderClient.geminiModels) {
        try {
          final response = await _client.postGemini(model, key, {
            'contents': [
              {
                'parts': [
                  {'text': AiPrompts.transcription},
                  {
                    'inline_data': {
                      'mime_type': audioMimeType(format),
                      'data': base64Audio,
                    },
                  },
                ],
              },
            ],
            'generationConfig': {'maxOutputTokens': 1000},
          }, _requestTimeout);
          if (response.statusCode == 200) {
            final result = AiProviderClient.geminiParts(
              response.body,
            ).join().trim();
            if (result.isNotEmpty) return result;
            sawEmptyResult = true;
          } else {
            debugPrint('⚠️ STT Gemini HTTP ${response.statusCode} ($model)');
          }
        } catch (e) {
          noteError(e, model);
        }
      }
    }

    throw VoiceTranscriptionException(
      sawNetworkError
          ? VoiceTranscriptionFailure.network
          : sawEmptyResult
          ? VoiceTranscriptionFailure.emptyResult
          : VoiceTranscriptionFailure.unavailable,
    );
  }

  /// MIME-тип аудио для Gemini REST (m4a — это контейнер с AAC внутри).
  @visibleForTesting
  static String audioMimeType(String format) {
    switch (format.toLowerCase()) {
      case 'wav':
        return 'audio/wav';
      case 'mp3':
        return 'audio/mp3';
      case 'ogg':
      case 'opus':
        return 'audio/ogg';
      case 'flac':
        return 'audio/flac';
      case 'webm':
        return 'audio/webm';
      case 'aac':
      case 'm4a':
      case 'mp4':
        return 'audio/aac';
      default:
        return 'audio/wav';
    }
  }
}
