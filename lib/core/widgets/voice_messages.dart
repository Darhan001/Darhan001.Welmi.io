import 'package:lumina/core/services/ai_service.dart';
import 'package:lumina/core/services/speech_recognition_service.dart';
import 'package:lumina/core/services/voice_recorder_service.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Понятный текст ошибки записи голоса (нет доступа к микрофону и т.п.).
String voiceRecordMessage(AppLocalizations loc, VoiceRecordException e) {
  return switch (e.failure) {
    VoiceRecordFailure.permissionDenied => loc.voiceErrorPermissionSettings,
    VoiceRecordFailure.startFailed => loc.voiceErrorRecord,
    VoiceRecordFailure.readFailed => loc.voiceErrorTranscribe,
  };
}

/// Понятный текст ошибки распознавания на устройстве.
String speechRecognitionMessage(
  AppLocalizations loc,
  SpeechRecognitionFailure failure,
) {
  return switch (failure) {
    SpeechRecognitionFailure.permissionDenied =>
      loc.voiceErrorPermissionSettings,
    SpeechRecognitionFailure.noSpeech => loc.voiceErrorTranscribe,
    SpeechRecognitionFailure.network => loc.voiceErrorNoInternet,
    SpeechRecognitionFailure.languageUnsupported => loc.voiceErrorLanguage,
    SpeechRecognitionFailure.other => loc.voiceErrorUnavailable,
  };
}

/// Понятный текст ошибки облачного распознавания речи по её причине.
String voiceTranscriptionMessage(
  AppLocalizations loc,
  VoiceTranscriptionFailure failure,
) {
  return switch (failure) {
    VoiceTranscriptionFailure.network => loc.voiceErrorNoInternet,
    VoiceTranscriptionFailure.emptyResult => loc.voiceErrorTranscribe,
    VoiceTranscriptionFailure.noApiKey ||
    VoiceTranscriptionFailure.unavailable => loc.voiceErrorUnavailable,
  };
}

/// Текст ошибки голосового ввода по типу исключения.
/// [fallback] — для неожиданных ошибок; по умолчанию «не удалось записать».
String voiceInputErrorMessage(
  AppLocalizations loc,
  Object error, {
  String? fallback,
}) {
  return switch (error) {
    VoiceRecordException() => voiceRecordMessage(loc, error),
    SpeechRecognitionException(:final failure) => speechRecognitionMessage(
      loc,
      failure,
    ),
    VoiceTranscriptionException(:final failure) => voiceTranscriptionMessage(
      loc,
      failure,
    ),
    _ => fallback ?? loc.voiceErrorRecord,
  };
}
