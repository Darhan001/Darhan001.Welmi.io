class AiChatMessage {
  final String role;
  final String text;
  final DateTime timestamp;

  AiChatMessage({required this.role, required this.text, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'role': role,
    'text': text,
    'timestamp': timestamp.toIso8601String(),
  };

  /// Возвращает null для повреждённой записи, чтобы одна битая строка
  /// не обнуляла всю историю.
  static AiChatMessage? fromJson(Object? json) {
    if (json is! Map) return null;
    final role = json['role'];
    final text = json['text'];
    if ((role != 'user' && role != 'assistant') || text is! String) return null;
    return AiChatMessage(
      role: role as String,
      text: text,
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? ''),
    );
  }
}
