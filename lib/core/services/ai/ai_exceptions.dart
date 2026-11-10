/// Ни один AI-провайдер не ответил на запрос чата.
class AiUnavailableException implements Exception {
  const AiUnavailableException(this.reason);

  /// Причина для логов (не для показа пользователю: текст строится в UI).
  final String reason;

  @override
  String toString() => 'AiUnavailableException: $reason';
}

/// Почему распознавание речи не вернуло текст.
enum VoiceTranscriptionFailure { noApiKey, network, emptyResult, unavailable }

class VoiceTranscriptionException implements Exception {
  const VoiceTranscriptionException(this.failure);
  final VoiceTranscriptionFailure failure;

  @override
  String toString() => 'VoiceTranscriptionException: $failure';
}
