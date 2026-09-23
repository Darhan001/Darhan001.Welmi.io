import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Сервис обратной связи — отправляет сообщения пользователей через Telegram Bot API.
///
/// Настройка:
/// 1. Создай бота через @BotFather в Telegram → получи токен
/// 2. Напиши боту любое сообщение, затем открой:
///    https://api.telegram.org/bot<TOKEN>/getUpdates
///    и найди свой chat_id
/// 3. Добавь в env.json:
///    "TELEGRAM_BOT_TOKEN": "токен_бота",
///    "TELEGRAM_CHAT_ID": "твой_chat_id"
class FeedbackService {
  static final FeedbackService _instance = FeedbackService._internal();
  factory FeedbackService() => _instance;
  FeedbackService._internal();

  /// Токен Telegram-бота (из env.json через --dart-define)
  static const String _botToken = String.fromEnvironment(
    'TELEGRAM_BOT_TOKEN',
    defaultValue: '',
  );

  /// Chat ID получателя (твой Telegram user ID или группа)
  static const String _chatId = String.fromEnvironment(
    'TELEGRAM_CHAT_ID',
    defaultValue: '',
  );

  /// Проверить, настроен ли бот
  bool get isConfigured => _botToken.isNotEmpty && _chatId.isNotEmpty;

  /// Отправить обратную связь
  Future<FeedbackResult> sendFeedback({
    required String message,
    String? userEmail,
    String? userName,
    String category = 'feedback',
  }) async {
    if (message.trim().isEmpty) {
      return FeedbackResult(success: false, error: 'Сообщение пустое');
    }

    // Сохраняем локально как бэкап
    await _saveLocally(message, category);

    if (!isConfigured) {
      debugPrint('⚠️ Telegram bot not configured. Message saved locally.');
      return FeedbackResult(
        success: false,
        error: 'Telegram bot not configured. Message saved locally.',
      );
    }

    try {
      final text = _formatMessage(message, userName, userEmail, category);
      final response = await http.post(
        Uri.parse('https://api.telegram.org/bot$_botToken/sendMessage'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chat_id': _chatId,
          'text': text,
          'parse_mode': 'HTML',
          'disable_web_page_preview': true,
        }),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['ok'] == true) {
          return FeedbackResult(success: true);
        } else {
          return FeedbackResult(
            success: false,
            error: body['description']?.toString() ?? 'Telegram API error',
          );
        }
      } else {
        return FeedbackResult(
          success: false,
          error: 'HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('❌ Feedback send error: $e');
      return FeedbackResult(success: false, error: e.toString());
    }
  }

  /// Форматирует сообщение для Telegram
  String _formatMessage(String message, String? userName, String? userEmail, String category) {
    final buffer = StringBuffer();
    buffer.writeln('📝 <b>Новое сообщение поддержки</b>');
    buffer.writeln('─────────────────');

    if (userName != null && userName.isNotEmpty) {
      buffer.writeln('👤 <b>Имя:</b> $userName');
    }
    if (userEmail != null && userEmail.isNotEmpty) {
      buffer.writeln('📧 <b>Email:</b> $userEmail');
    }

    buffer.writeln('📋 <b>Категория:</b> ${_categoryLabel(category)}');
    buffer.writeln('🕐 <b>Время:</b> ${DateTime.now().toString().substring(0, 19)}');
    buffer.writeln('');
    buffer.writeln('💬 <b>Сообщение:</b>');
    buffer.writeln(message);

    return buffer.toString();
  }

  String _categoryLabel(String category) {
    switch (category) {
      case 'feedback':
        return 'Обратная связь';
      case 'bug':
        return 'Ошибка / Баг';
      case 'idea':
        return 'Идея / Предложение';
      case 'support':
        return 'Поддержка';
      default:
        return 'Обратная связь';
    }
  }

  /// Сохранить сообщение локально (бэкап + история)
  Future<void> _saveLocally(String message, String category) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList('feedback_history') ?? [];
      history.add(jsonEncode({
        'message': message,
        'category': category,
        'timestamp': DateTime.now().toIso8601String(),
        'sent': isConfigured,
      }));
      // Храним последние 50 сообщений
      if (history.length > 50) {
        history.removeRange(0, history.length - 50);
      }
      await prefs.setStringList('feedback_history', history);
    } catch (e) {
      debugPrint('⚠️ Feedback local save error: $e');
    }
  }

  /// Получить историю отправленных сообщений
  Future<List<Map<String, dynamic>>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList('feedback_history') ?? [];
      return history.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
    } catch (e) {
      return [];
    }
  }
}

class FeedbackResult {
  final bool success;
  final String? error;

  const FeedbackResult({required this.success, this.error});
}
