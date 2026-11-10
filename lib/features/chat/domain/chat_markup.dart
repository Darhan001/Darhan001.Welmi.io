/// Стиль фрагмента ответа AI.
enum ChatTextStyle { plain, bold, italic }

/// Фрагмент ответа AI с упрощённой markdown-разметкой.
class ChatTextSegment {
  const ChatTextSegment(this.text, this.style);
  final String text;
  final ChatTextStyle style;

  @override
  bool operator ==(Object other) =>
      other is ChatTextSegment && other.text == text && other.style == style;

  @override
  int get hashCode => Object.hash(text, style);

  @override
  String toString() => '$style("$text")';
}

final _markupPattern = RegExp(r'(\*\*(.+?)\*\*|_(.+?)_)');
final _speechNoise = RegExp(r'[*_#`>]');

/// Разбивает текст на фрагменты: `**жирный**`, `_курсив_`, остальное — обычный.
List<ChatTextSegment> parseChatMarkup(String text) {
  if (!text.contains('**') && !text.contains('_')) {
    return [ChatTextSegment(text, ChatTextStyle.plain)];
  }
  final segments = <ChatTextSegment>[];
  var lastEnd = 0;
  for (final match in _markupPattern.allMatches(text)) {
    if (match.start > lastEnd) {
      segments.add(
        ChatTextSegment(
          text.substring(lastEnd, match.start),
          ChatTextStyle.plain,
        ),
      );
    }
    final isBold = match.group(1)!.startsWith('**');
    segments.add(
      ChatTextSegment(
        (isBold ? match.group(2) : match.group(3))!,
        isBold ? ChatTextStyle.bold : ChatTextStyle.italic,
      ),
    );
    lastEnd = match.end;
  }
  if (lastEnd < text.length) {
    segments.add(ChatTextSegment(text.substring(lastEnd), ChatTextStyle.plain));
  }
  return segments;
}

/// Убирает markdown-разметку, которую синтезатор прочитал бы вслух.
String plainSpeechText(String text) => text.replaceAll(_speechNoise, '').trim();
