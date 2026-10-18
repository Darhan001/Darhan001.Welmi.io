import 'package:lumina/core/services/ai_service.dart';
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

/// Понятный текст ошибки распознавания речи по её причине.
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
