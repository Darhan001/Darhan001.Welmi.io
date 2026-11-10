import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Почему распознавание на устройстве не дало текста.
enum SpeechRecognitionFailure {
  permissionDenied,
  noSpeech,
  network,
  languageUnsupported,
  other,
}

class SpeechRecognitionException implements Exception {
  const SpeechRecognitionException(this.failure, [this.code]);
  final SpeechRecognitionFailure failure;

  /// Исходный код ошибки платформы (`error_no_match` и т.п.) для логов.
  final String? code;

  @override
  String toString() => 'SpeechRecognitionException: $failure ($code)';
}

/// Сопоставляет коды ошибок Android/iOS с причинами для UI.
@visibleForTesting
SpeechRecognitionFailure mapSpeechErrorCode(String code) {
  switch (code) {
    case 'error_permission':
    case 'error_insufficient_permissions':
      return SpeechRecognitionFailure.permissionDenied;
    case 'error_no_match':
    case 'error_speech_timeout':
      return SpeechRecognitionFailure.noSpeech;
    case 'error_network':
    case 'error_network_timeout':
    case 'error_server':
    case 'error_server_disconnected':
      return SpeechRecognitionFailure.network;
    case 'error_language_not_supported':
    case 'error_language_unavailable':
      return SpeechRecognitionFailure.languageUnsupported;
    default:
      return SpeechRecognitionFailure.other;
  }
}

/// Распознавание речи встроенным сервисом ОС (Google на Android, Apple на iOS).
///
/// Не требует API-ключей и баланса у провайдера: облачный Whisper через
/// OpenRouter требует платного баланса, поэтому системный распознаватель —
/// основной путь, а облако — запасной (если на устройстве его нет).
///
/// Один экземпляр на приложение: плагин хранит обработчики результатов
/// глобально, и второй экземпляр перехватил бы их у первого (чат перестал
/// бы получать текст после открытия голосового ввода в дневнике).
class SpeechRecognitionService {
  SpeechRecognitionService._() : _speech = SpeechToText();

  static final SpeechRecognitionService instance = SpeechRecognitionService._();

  final SpeechToText _speech;
  bool _available = false;
  Completer<String>? _session;
  String _lastWords = '';

  /// Текст, распознанный к текущему моменту (обновляется во время речи).
  final ValueNotifier<String> partialText = ValueNotifier<String>('');

  /// Есть ли системный распознаватель и разрешён ли микрофон.
  /// Успешный результат кэшируется; отказ — нет, чтобы после выдачи
  /// разрешения в настройках повторная попытка сработала.
  Future<bool> isAvailable() async {
    if (_available) return true;
    try {
      _available = await _speech.initialize(
        onError: _onError,
        onStatus: _onStatus,
      );
    } catch (e) {
      debugPrint('⚠️ Speech init error: $e');
      _available = false;
    }
    return _available;
  }

  /// Подходящая локаль распознавателя для языка (например `ru` → `ru_RU`).
  Future<String?> localeFor(String languageCode) async {
    try {
      final locales = await _speech.locales();
      final lang = languageCode.toLowerCase();
      for (final locale in locales) {
        final id = locale.localeId.toLowerCase();
        if (id == lang ||
            id.startsWith('${lang}_') ||
            id.startsWith('$lang-')) {
          return locale.localeId;
        }
      }
    } catch (e) {
      debugPrint('⚠️ Speech locales error: $e');
    }
    return null;
  }

  /// Начинает сессию. Результат — в [result].
  Future<void> start({String? localeId}) async {
    // Незавершённая прошлая сессия (например, после таймаута stop())
    // закрывается пустым результатом, а не остаётся висеть навсегда.
    final previous = _session;
    if (previous != null && !previous.isCompleted) previous.complete('');
    _lastWords = '';
    partialText.value = '';
    _session = Completer<String>();
    try {
      await _speech.listen(
        onResult: _onResult,
        listenOptions: SpeechListenOptions(
          partialResults: true,
          listenMode: ListenMode.dictation,
          cancelOnError: true,
          listenFor: const Duration(seconds: 60),
          pauseFor: const Duration(seconds: 4),
          localeId: localeId,
        ),
      );
    } catch (_) {
      // Сессия не началась: её future никто не ждёт, поэтому не завершаем
      // его ошибкой (это была бы необработанная ошибка), а просто убираем.
      _session = null;
      rethrow;
    }
  }

  /// Итоговый текст сессии. Завершается, когда пользователь остановил
  /// запись или распознаватель сам закончил после паузы.
  Future<String> get result =>
      _session?.future ??
      Future.error(
        const SpeechRecognitionException(SpeechRecognitionFailure.other),
      );

  bool get isSessionActive => _session != null && !_session!.isCompleted;

  /// Останавливает запись; итоговый текст придёт в [result].
  Future<void> stop() async {
    if (!isSessionActive) return;
    await _speech.stop();
  }

  /// Прерывает сессию без результата.
  Future<void> cancel() async {
    final session = _session;
    _session = null;
    try {
      await _speech.cancel();
    } catch (e) {
      debugPrint('⚠️ Speech cancel error: $e');
    }
    if (session != null && !session.isCompleted) session.complete('');
  }

  void _onResult(SpeechRecognitionResult result) {
    _lastWords = result.recognizedWords;
    partialText.value = _lastWords;
    if (result.finalResult) _finish();
  }

  void _onStatus(String status) {
    if (status == SpeechToText.doneStatus) _finish();
  }

  void _onError(SpeechRecognitionError error) {
    debugPrint(
      '⚠️ Speech error: ${error.errorMsg} (permanent: ${error.permanent})',
    );
    final session = _session;
    if (session == null || session.isCompleted) return;
    // Если что-то уже распознано, отдаём это, а не ошибку «не расслышал».
    if (_lastWords.trim().isNotEmpty) {
      _finish();
      return;
    }
    session.completeError(
      SpeechRecognitionException(
        mapSpeechErrorCode(error.errorMsg),
        error.errorMsg,
      ),
    );
  }

  void _finish() {
    final session = _session;
    if (session == null || session.isCompleted) return;
    final text = _lastWords.trim();
    if (text.isEmpty) {
      session.completeError(
        const SpeechRecognitionException(SpeechRecognitionFailure.noSpeech),
      );
    } else {
      session.complete(text);
    }
  }
}
