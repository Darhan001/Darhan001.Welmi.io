import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Отправляет обратную связь через Supabase Edge Function.
/// Telegram credentials доступны только серверной функции.
class FeedbackService {
  static final FeedbackService _instance = FeedbackService._internal();
  factory FeedbackService() => _instance;
  FeedbackService._internal();

  static const int maxMessageLength = 3000;

  Future<FeedbackResult> sendFeedback({
    required String message,
    String category = 'feedback',
  }) async {
    final trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty) {
      return const FeedbackResult(success: false, error: 'empty');
    }
    if (trimmedMessage.length > maxMessageLength) {
      return const FeedbackResult(success: false, error: 'too_long');
    }

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final response = await Supabase.instance.client.functions.invoke(
        'send-feedback',
        body: {
          'category': category,
          'message': trimmedMessage,
          'user_id': Supabase.instance.client.auth.currentUser?.id,
          'app_version': packageInfo.version,
          'platform': _platformName,
        },
      );

      if (response.status < 200 || response.status >= 300) {
        debugPrint('Feedback Edge Function returned HTTP ${response.status}.');
        return FeedbackResult(
          success: false,
          error: _userMessageForStatus(response.status),
        );
      }

      await _saveLocally(trimmedMessage, category);
      return const FeedbackResult(success: true);
    } on FunctionException catch (error) {
      debugPrint('Feedback Edge Function returned HTTP ${error.status}.');
      return FeedbackResult(
        success: false,
        error: _userMessageForStatus(error.status),
      );
    } catch (error) {
      debugPrint('Feedback request failed (${error.runtimeType}).');
      return const FeedbackResult(success: false, error: 'network');
    }
  }

  String get _platformName {
    if (kIsWeb) return 'Web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'Android',
      TargetPlatform.iOS => 'iOS',
      TargetPlatform.macOS => 'macOS',
      TargetPlatform.windows => 'Windows',
      TargetPlatform.linux => 'Linux',
      TargetPlatform.fuchsia => 'Fuchsia',
    };
  }

  String _userMessageForStatus(int status) {
    if (status == 401 || status == 403) return 'session';
    if (status == 429) return 'rate_limit';
    if (status == 404) return 'function_missing';
    if (status == 502) return 'telegram';
    if (status == 503) return 'secrets';
    if (status >= 500) return 'function';
    return 'send';
  }

  Future<void> _saveLocally(String message, String category) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList('feedback_history') ?? [];
      history.add(
        jsonEncode({
          'message': message,
          'category': category,
          'timestamp': DateTime.now().toIso8601String(),
          'sent': true,
        }),
      );
      if (history.length > 50) {
        history.removeRange(0, history.length - 50);
      }
      await prefs.setStringList('feedback_history', history);
    } catch (_) {
      // История необязательна; успешную доставку не считаем неуспешной.
    }
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList('feedback_history') ?? [];
      return history
          .map((entry) => jsonDecode(entry) as Map<String, dynamic>)
          .toList();
    } catch (_) {
      return [];
    }
  }
}

class FeedbackResult {
  final bool success;
  final String? error;

  const FeedbackResult({required this.success, this.error});
}
