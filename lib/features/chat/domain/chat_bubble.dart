import 'package:lumina/features/chat/domain/chat_markup.dart';

/// Сообщение на экране чата.
class ChatBubble {
  ChatBubble({
    required this.text,
    required this.isUser,
    this.isVoice = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final String text;
  final bool isUser;
  final bool isVoice;
  final DateTime timestamp;

  /// Разметка и текст для озвучивания считаются один раз, а не при каждой
  /// перерисовке списка (и при каждом старте/остановке речи).
  late final List<ChatTextSegment> segments = parseChatMarkup(text);
  late final String speechText = plainSpeechText(text);
}
