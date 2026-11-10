import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lumina/app/config_error_app.dart';
import 'package:lumina/app/welmi_app.dart';
import 'package:lumina/core/config/app_config.dart';
import 'package:lumina/core/network/timeout_http_client.dart';
import 'package:lumina/core/services/ai_service.dart';
import 'package:lumina/core/services/supabase_service.dart';
import 'package:lumina/core/services/push_notification_service.dart';
import 'package:lumina/core/services/units_service.dart';
import 'package:lumina/core/theme/theme_mode_controller.dart';
import 'package:lumina/features/profile/domain/services/subscription_service.dart';
import 'package:lumina/core/services/notifications/notification_service.dart';

// Конфигурация приложения (ключи из env.json) вынесена в
// `lib/core/config/app_config.dart`. Ключи в коде не хранятся,
// а подставляются флагом --dart-define-from-file=env.json.

/// Точка входа: проверка конфигурации, Sentry, инициализация сервисов.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();

  // Обязательна только конфигурация Supabase. Отсутствие AI/Sentry-ключей
  // запуск НЕ блокирует — приложение работает с fallback-логикой.
  if (!isSupabaseConfigured) {
    debugPrint(
      '❌ Конфигурация Supabase не задана: '
      '${missingRequiredEnvKeys.join(', ')}. Запустите с '
      '--dart-define-from-file=env.json',
    );
    runApp(ConfigErrorApp(missingKeys: missingRequiredEnvKeys));
    return;
  }

  debugPrint('✅ Конфигурация: ${configDiagnostics()}');

  final useSentry =
      !kIsWeb && sentryDsn.isNotEmpty && sentryDsn.startsWith('https://');
  if (useSentry) {
    try {
      await SentryFlutter.init((options) {
        options.dsn = sentryDsn;
        options.tracesSampleRate = 0.1;
        options.environment = kReleaseMode ? 'production' : 'development';
      }, appRunner: _startApp);
    } catch (e) {
      debugPrint('❌ Sentry init error: $e');
      await _startApp();
    }
  } else {
    await _startApp();
  }
}

Future<void> _startApp() async {
  // Локальные настройки: загружаем до первого кадра, чтобы вес сразу
  // показывался в выбранных единицах, а тема не мигала при запуске.
  final themeMode = ThemeModeController();
  await Future.wait([UnitsService.instance.load(), themeMode.load()]);
  await _initServices();

  final app = WelmiApp(themeMode: themeMode);
  if (kReleaseMode) {
    runApp(app);
  } else {
    runApp(DevicePreview(enabled: true, builder: (context) => app));
  }
}

Future<void> _initServices() async {
  try {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
      httpClient: TimeoutHttpClient(),
    );
    await SupabaseService().initialize();
    unawaited(SubscriptionService.instance.initialize());
    AiService().initialize(
      nutritionApiKey: geminiNutritionApiKey,
      chatApiKey: openRouterApiKey,
      scannerApiKey: scannerApiKey,
    );

    try {
      final notifications = NotificationService();
      await notifications.initialize();
      if (!kIsWeb) {
        // Разрешение — только по требованию пользователя (настройки/онбординг).
        // Если разрешение уже выдано — восстанавливаем расписание
        // (стабильные id перезаписывают прежние, дубликаты не создаются).
        final granted = await notifications.checkPermissions();
        if (granted) await notifications.rescheduleAll();
      }
    } catch (e) {
      debugPrint('❌ Notification Error: $e');
    }

    if (!kIsWeb) {
      try {
        await PushNotificationService().initialize();
      } catch (e) {
        debugPrint('❌ Push Error: $e');
      }
    }
  } catch (e) {
    debugPrint('❌ Ошибка инициализации: $e');
  }
}
