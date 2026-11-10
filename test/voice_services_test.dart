import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumina/core/services/ai_service.dart';
import 'package:lumina/core/services/speech_output_service.dart';
import 'package:lumina/core/services/speech_recognition_service.dart';
import 'package:lumina/core/widgets/voice_messages.dart';
import 'package:lumina/l10n/app_localizations_ru.dart';

void main() {
  group('SpeechVoice', () {
    test('languageCode берётся из локали без региона', () {
      const voice = SpeechVoice(name: 'Milena', locale: 'ru-RU');
      expect(voice.languageCode, 'ru');
    });

    test('поддерживает локаль с подчёркиванием (iOS/Web)', () {
      const voice = SpeechVoice(name: 'x', locale: 'en_US');
      expect(voice.languageCode, 'en');
    });
  });

  group('filterVoicesForLanguage', () {
    const voices = [
      SpeechVoice(name: 'Samantha', locale: 'en-US'),
      SpeechVoice(name: 'Milena', locale: 'ru-RU'),
      SpeechVoice(name: 'Yuri', locale: 'ru-RU'),
      SpeechVoice(name: 'Anna', locale: 'ru-BY'),
    ];

    test('оставляет только голоса нужного языка', () {
      final result = filterVoicesForLanguage(voices, 'ru');
      expect(result.map((v) => v.name), ['Anna', 'Milena', 'Yuri']);
    });

    test('сортирует по локали и имени, стабильно между запусками', () {
      final shuffled = [...voices.reversed];
      expect(
        filterVoicesForLanguage(shuffled, 'ru'),
        filterVoicesForLanguage(voices, 'ru'),
      );
    });

    test('пустой список, если голосов языка нет', () {
      expect(filterVoicesForLanguage(voices, 'ky'), isEmpty);
    });

    test('регистр кода языка не важен', () {
      expect(filterVoicesForLanguage(voices, 'RU'), hasLength(3));
    });
  });

  group('voiceTranscriptionMessage', () {
    final loc = AppLocalizationsRu();

    test('сеть, пустой результат и недоступность API дают разные тексты', () {
      final network = voiceTranscriptionMessage(
        loc,
        VoiceTranscriptionFailure.network,
      );
      final empty = voiceTranscriptionMessage(
        loc,
        VoiceTranscriptionFailure.emptyResult,
      );
      final unavailable = voiceTranscriptionMessage(
        loc,
        VoiceTranscriptionFailure.unavailable,
      );
      expect({network, empty, unavailable}, hasLength(3));
      expect(network, loc.voiceErrorNoInternet);
      expect(empty, loc.voiceErrorTranscribe);
    });

    test('отсутствие ключа показывается как недоступность сервиса', () {
      expect(
        voiceTranscriptionMessage(loc, VoiceTranscriptionFailure.noApiKey),
        loc.voiceErrorUnavailable,
      );
    });
  });

  group('распознавание на устройстве', () {
    test('коды ошибок Android/iOS сопоставляются с причинами', () {
      expect(
        mapSpeechErrorCode('error_permission'),
        SpeechRecognitionFailure.permissionDenied,
      );
      expect(
        mapSpeechErrorCode('error_no_match'),
        SpeechRecognitionFailure.noSpeech,
      );
      expect(
        mapSpeechErrorCode('error_speech_timeout'),
        SpeechRecognitionFailure.noSpeech,
      );
      expect(
        mapSpeechErrorCode('error_network_timeout'),
        SpeechRecognitionFailure.network,
      );
      expect(
        mapSpeechErrorCode('error_language_unavailable'),
        SpeechRecognitionFailure.languageUnsupported,
      );
      expect(
        mapSpeechErrorCode('error_unknown_new_code'),
        SpeechRecognitionFailure.other,
      );
    });

    test('каждая причина даёт отдельное понятное сообщение', () {
      final loc = AppLocalizationsRu();
      final messages = SpeechRecognitionFailure.values
          .map((f) => speechRecognitionMessage(loc, f))
          .toSet();
      expect(messages, hasLength(SpeechRecognitionFailure.values.length));
      expect(
        speechRecognitionMessage(
          loc,
          SpeechRecognitionFailure.permissionDenied,
        ),
        loc.voiceErrorPermissionSettings,
      );
    });
  });

  group('AiService.transcribeAudio', () {
    test('пустые байты сразу дают emptyResult', () async {
      expect(
        () => AiService().transcribeAudio(Uint8List(0)),
        throwsA(
          isA<VoiceTranscriptionException>().having(
            (e) => e.failure,
            'failure',
            VoiceTranscriptionFailure.emptyResult,
          ),
        ),
      );
    });
  });
}
