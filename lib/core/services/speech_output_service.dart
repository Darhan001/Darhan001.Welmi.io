import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Голос системного синтезатора речи (Text-to-Speech).
class SpeechVoice {
  const SpeechVoice({required this.name, required this.locale});

  final String name;

  /// Код локали вида `ru-RU`.
  final String locale;

  /// Язык без региона: `ru` из `ru-RU`.
  String get languageCode => locale.split(RegExp('[-_]')).first.toLowerCase();

  @override
  bool operator ==(Object other) =>
      other is SpeechVoice && other.name == name && other.locale == locale;

  @override
  int get hashCode => Object.hash(name, locale);
}

/// Синтез речи не удалось запустить (нет движка, язык не поддержан и т.п.).
class SpeechOutputException implements Exception {
  const SpeechOutputException(this.message);
  final String message;

  @override
  String toString() => 'SpeechOutputException: $message';
}

/// Озвучивание ответов AI: воспроизведение, остановка и выбор голоса.
///
/// Использует нативный движок ОС (Android TTS, AVSpeechSynthesizer, Web Speech
/// API), поэтому работает без сети. Набор доступных голосов зависит от
/// устройства: русский голос может отсутствовать — тогда выбрасывается
/// [SpeechOutputException].
class SpeechOutputService {
  SpeechOutputService({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;

  static const String _prefVoiceKey = 'tts_voice';

  /// Текст, который сейчас озвучивается, или null. Экран подсвечивает
  /// по нему нужное сообщение и меняет кнопку «играть» на «стоп».
  final ValueNotifier<String?> speakingText = ValueNotifier<String?>(null);

  SpeechVoice? _selectedVoice;
  SpeechVoice? get selectedVoice => _selectedVoice;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    _tts.setCompletionHandler(() => speakingText.value = null);
    _tts.setCancelHandler(() => speakingText.value = null);
    _tts.setErrorHandler((message) {
      debugPrint('⚠️ TTS error: $message');
      speakingText.value = null;
    });
    await _tts.awaitSpeakCompletion(false);
    await _restoreVoice();
  }

  /// Голоса на устройстве для языка [languageCode] (например `ru`).
  Future<List<SpeechVoice>> voicesFor(String languageCode) async {
    final raw = await _tts.getVoices;
    final all = <SpeechVoice>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is! Map) continue;
        final name = item['name']?.toString();
        final locale = item['locale']?.toString();
        if (name == null || locale == null) continue;
        all.add(SpeechVoice(name: name, locale: locale));
      }
    }
    return filterVoicesForLanguage(all, languageCode);
  }

  Future<void> selectVoice(SpeechVoice? voice) async {
    _selectedVoice = voice;
    final prefs = await SharedPreferences.getInstance();
    if (voice == null) {
      await prefs.remove(_prefVoiceKey);
    } else {
      await prefs.setString(_prefVoiceKey, '${voice.name}|${voice.locale}');
    }
  }

  /// Озвучивает [text] на языке [languageCode]. Предыдущая речь прерывается.
  Future<void> speak(String text, {required String languageCode}) async {
    await init();
    await _tts.stop();
    final locale = _selectedVoice?.languageCode == languageCode
        ? _selectedVoice!.locale
        : _localeFor(languageCode);
    final langResult = await _tts.setLanguage(locale);
    if (!_isOk(langResult)) {
      throw SpeechOutputException('Синтез речи для языка "$locale" недоступен');
    }
    final voice = _selectedVoice;
    if (voice != null && voice.languageCode == languageCode) {
      await _tts.setVoice({'name': voice.name, 'locale': voice.locale});
    }
    speakingText.value = text;
    final result = await _tts.speak(text);
    if (!_isOk(result)) {
      speakingText.value = null;
      throw const SpeechOutputException('Синтезатор речи не запустился');
    }
  }

  Future<void> stop() async {
    await _tts.stop();
    speakingText.value = null;
  }

  Future<void> _restoreVoice() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefVoiceKey);
    if (saved == null) return;
    final parts = saved.split('|');
    if (parts.length != 2) return;
    _selectedVoice = SpeechVoice(name: parts[0], locale: parts[1]);
  }

  static bool _isOk(dynamic result) => result == 1 || result == true;

  static String _localeFor(String languageCode) => switch (languageCode) {
    'ru' => 'ru-RU',
    'en' => 'en-US',
    'ky' => 'ky-KG',
    _ => languageCode,
  };

  void dispose() {
    _tts.stop();
    speakingText.dispose();
  }
}

/// Оставляет голоса нужного языка (любого региона: `ru-RU`, `ru-BY`, …),
/// отсортированные по локали и имени.
@visibleForTesting
List<SpeechVoice> filterVoicesForLanguage(
  List<SpeechVoice> voices,
  String languageCode,
) {
  final lang = languageCode.toLowerCase();
  final matched = voices.where((v) => v.languageCode == lang).toList()
    ..sort((a, b) {
      final byLocale = a.locale.compareTo(b.locale);
      return byLocale != 0 ? byLocale : a.name.compareTo(b.name);
    });
  return matched;
}
