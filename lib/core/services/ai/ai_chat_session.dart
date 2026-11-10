import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:lumina/core/services/ai/ai_chat_message.dart';
import 'package:lumina/core/services/ai/ai_exceptions.dart';
import 'package:lumina/core/services/ai/ai_prompts.dart';
import 'package:lumina/core/services/ai/ai_provider_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Переписка с AI и её хранение на устройстве.
///
/// История хранится отдельно для каждого пользователя, чтобы на общем
/// устройстве не показывать чужую переписку. Последние 50 сообщений.
class AiChatSession {
  /// [_currentUserId] — id вошедшего пользователя (владельца истории).
  AiChatSession(this._client, this._currentUserId);

  final AiProviderClient _client;
  final String? Function() _currentUserId;
  final List<AiChatMessage> _history = [];

  static const int _maxStoredMessages = 50;

  /// Сколько прошлых сообщений отправлять как контекст: запрос должен
  /// укладываться в небольшой баланс аккаунта.
  static const int _contextMessages = 10;

  String? _historyOwner;

  /// Номер диалога: меняется при «новом чате» и смене пользователя, чтобы
  /// ответ на запрос из прошлого диалога не попал в новый.
  int _epoch = 0;

  static String _historyKey(String userId) => 'ai_chat_history_$userId';

  List<AiChatMessage> get history => List.unmodifiable(_history);

  /// Возвращает ответ AI. Если ни один провайдер не ответил, бросает
  /// [AiUnavailableException]: ошибка не попадает в историю как ответ AI.
  Future<String> send(String message) async {
    _client.lastIssue = null;
    final epoch = _epoch;
    // Текущее сообщение не включаем в контекст: оно передаётся через
    // userPrompt, иначе получатся два user-сообщения подряд.
    final context = _history.length > _contextMessages
        ? _history.sublist(_history.length - _contextMessages)
        : List.of(_history);
    final userMessage = AiChatMessage(role: 'user', text: message);
    _history.add(userMessage);

    String? text;
    try {
      text = await _client
          .complete(
            systemPrompt: AiPrompts.chatSystem,
            userPrompt: message,
            maxTokens: 1000,
            history: context
                .map((m) => {'role': m.role, 'content': m.text})
                .toList(),
            budget: const Duration(seconds: 70),
          )
          .timeout(const Duration(seconds: 75));
    } catch (e) {
      debugPrint('❌ Chat Error: $e');
      _client.lastIssue = 'нет ответа от AI-провайдера';
    }
    if (text == null || text.isEmpty) {
      // Убираем неотвеченное сообщение, чтобы история оставалась парной.
      // remove, а не removeLast: пока ждали ответ, историю могли очистить
      // (на пустом списке removeLast бросал StateError).
      _history.remove(userMessage);
      throw AiUnavailableException(
        _client.lastIssue ?? 'AI не настроен: добавьте ключ провайдера',
      );
    }
    // Пока ждали ответ, пользователь начал новый чат или вышел из аккаунта:
    // ответ отдаём вызывающему, но в новую историю не пишем.
    if (epoch != _epoch) return text;
    _history.add(AiChatMessage(role: 'assistant', text: text));
    await save();
    return text;
  }

  void startNew() {
    _history.clear();
    _epoch++;
    final userId = _currentUserId();
    if (userId == null) return;
    SharedPreferences.getInstance()
        .then((prefs) => prefs.remove(_historyKey(userId)))
        .catchError((Object e) {
          debugPrint('⚠️ Chat history clear error: $e');
          return false;
        });
  }

  /// Очищает переписку в памяти при выходе из аккаунта, не удаляя её
  /// с устройства: после повторного входа история вернётся.
  void clearInMemory() {
    _history.clear();
    _historyOwner = null;
    _epoch++;
  }

  Future<void> save() async {
    final userId = _currentUserId();
    if (userId == null) return;
    _historyOwner = userId;
    try {
      final prefs = await SharedPreferences.getInstance();
      final recent = _history.length > _maxStoredMessages
          ? _history.sublist(_history.length - _maxStoredMessages)
          : _history;
      await prefs.setString(
        _historyKey(userId),
        jsonEncode(recent.map((m) => m.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('⚠️ Chat history save error: $e');
    }
  }

  /// Загружает историю текущего пользователя. Если она уже в памяти
  /// (тот же пользователь в этой сессии) — ничего не делает.
  Future<void> load() async {
    final userId = _currentUserId();
    if (userId == null) {
      clearInMemory();
      return;
    }
    if (_historyOwner == userId) return;
    _history.clear();
    _historyOwner = userId;
    _epoch++;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_historyKey(userId));
      if (raw == null) return;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      _history.addAll(
        decoded.map(AiChatMessage.fromJson).whereType<AiChatMessage>(),
      );
    } catch (e) {
      debugPrint('⚠️ Chat history load error: $e');
    }
  }
}
