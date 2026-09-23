import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';

/// Канал push-уведомлений (Android). Должен существовать заранее,
/// иначе системные (фоновые) push не будут показываться.
const String kPushChannelId = 'welmi_push';

/// ============================================================
/// Сервис PUSH-уведомлений (Firebase Cloud Messaging)
/// ============================================================
/// Что делает:
/// 1. Инициализирует Firebase.
/// 2. Запрашивает разрешение и получает FCM-токен устройства.
/// 3. Сохраняет токен в таблицу `device_tokens` (Supabase), чтобы
///    Edge Function `send-push` могла слать уведомления этому пользователю.
/// 4. Показывает уведомления в foreground (через flutter_local_notifications)
///    и обрабатывает нажатия (в т.ч. когда приложение запускается из уведомления).
///
/// Требует ручной настройки (см. README → «Push-уведомления»):
/// - Firebase-проект и файл android/app/google-services.json;
/// - таблица device_tokens (SQL уже в supabase_schema.sql);
/// - деплой Edge Function send-push.
class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  /// Глобальный ключ навигатора — нужен, чтобы открыть нужный экран
  /// при нажатии на push (привязывается в main.dart к MaterialApp).
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Колбэк для обработки нажатия на push. Получает строку из payload
  /// `data['route']` (например 'water', 'diary', 'progress'). Задаётся в main.dart.
  void Function(String? route)? onRouteTap;

  bool _isInitialized = false;
  bool _isFcmAvailable = false;

  // ────────────────────────────────────────────────────────────
  // ОБРАБОТКА ФОНОВЫХ СООБЩЕНИЙ
  // ────────────────────────────────────────────────────────────
  // Топ-левел функция обязана быть статической и без замыканий —
  // её вызывает отдельный изолят, когда приложение в фоне/убито.
  // Если в сообщении есть блок `notification`, Android покажет его сам,
  // а наш хендлер нужен только для data-сообщений.

  @pragma('vm:entry-point')
  static Future<void> onBackgroundMessage(RemoteMessage message) async {
    if (message.notification != null) return;
    await _showLocalNotification(message);
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      const initSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      );
      await plugin.initialize(initSettings);

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          kPushChannelId,
          'Welmi Push',
          channelDescription: 'Push-уведомления Welmi',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );

      final data = message.data;
      // id: миллисекунды (mod int32) — почти исключает коллизии,
      // в отличие от секунд (два push за одну секунду не перезапишут друг друга).
      final id = DateTime.now().millisecondsSinceEpoch % 0x7fffffff;
      await plugin.show(
        id,
        message.notification?.title ?? data['title'] ?? 'Welmi',
        message.notification?.body ?? data['body'] ?? '',
        details,
      );
    } catch (e) {
      debugPrint('❌ Push local show error: $e');
    }
  }

  // ────────────────────────────────────────────────────────────
  // ИНИЦИАЛИЗАЦИЯ
  // ────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_isInitialized || kIsWeb) return;
    _isInitialized = true; // защита от повторного вызова при ошибке

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _isFcmAvailable = true;
    } catch (e) {
      debugPrint('❌ Firebase init failed (google-services.json?): $e');
      return;
    }

    try {
      final messaging = FirebaseMessaging.instance;

      // Регистрируем фоновый хендлер (обязательно до остального).
      FirebaseMessaging.onBackgroundMessage(onBackgroundMessage);

      // Создаём Android-канал заранее, чтобы системные (фоновые) push
      // гарантированно показывались.
      final android = FlutterLocalNotificationsPlugin()
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          kPushChannelId,
          'Welmi Push',
          description: 'Push-уведомления Welmi',
          importance: Importance.high,
        ),
      );

      // Разрешение (Android 13+). Если отказали — push всё равно придут,
      // но не покажутся. Мягко просим, не блокируем.
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Foreground: приложение открыто — показываем сами.
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Тап по уведомлению, когда приложение было в фоне.
      FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

      // Тап по уведомлению, когда приложение было убито (запуск из push).
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) _handleTap(initialMessage);

      // Обновление токена (например, после переустановки).
      messaging.onTokenRefresh.listen(_saveToken);

      // Регистрируем текущий токен.
      final token = await messaging.getToken();
      if (token != null) await _saveToken(token);

      debugPrint('✅ PushNotificationService initialized');
    } catch (e) {
      debugPrint('❌ Push init error: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    // Показываем и обычные (notification), и data-only сообщения.
    _showLocalNotification(message);
  }

  void _handleTap(RemoteMessage message) {
    final route = message.data['route'] as String?;
    debugPrint('🔔 Push tapped: route=$route, data=${message.data}');
    onRouteTap?.call(route);
  }

  // ────────────────────────────────────────────────────────────
  // РЕГИСТРАЦИЯ ТОКЕНА В SUPABASE
  // ────────────────────────────────────────────────────────────

  /// Сохранить/обновить FCM-токен устройства в таблице device_tokens.
  Future<void> _saveToken(String token) async {
    final userId = AuthService().userId;
    if (userId == null || userId.isEmpty) return;

    try {
      await Supabase.instance.client.from('device_tokens').upsert(
        {
          'user_id': userId,
          'token': token,
          'platform': 'android',
          'enabled': true,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'token',
      );
      debugPrint('📲 FCM token saved for user $userId');
    } catch (e) {
      // Таблица может ещё не существовать — не роняем приложение.
      debugPrint('⚠️ Token save error (проверь, что создана таблица device_tokens): $e');
    }
  }

  /// Вызвать после входа пользователя (токен мог быть получен до логина).
  Future<void> registerTokenIfNeeded() async {
    if (!_isFcmAvailable || kIsWeb) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _saveToken(token);
    } catch (e) {
      debugPrint('⚠️ registerTokenIfNeeded error: $e');
    }
  }

  /// Удалить токен ТЕКУЩЕГО устройства при выходе из аккаунта.
  /// Важно: не удаляем чужие устройства пользователя — иначе после выхода
  /// на одном телефоне push перестанут приходить на второй.
  Future<void> unregisterAllTokens() async {
    final userId = AuthService().userId;
    if (userId == null || userId.isEmpty) return;
    try {
      String? token;
      try {
        token = await FirebaseMessaging.instance.getToken();
      } catch (_) {}

      if (token != null && token.isNotEmpty) {
        await Supabase.instance.client
            .from('device_tokens')
            .delete()
            .eq('token', token);
        debugPrint('📴 FCM token removed (this device)');
      } else {
        // Не удалось узнать токен (нет сети) — fallback: удаляем все свои.
        await Supabase.instance.client
            .from('device_tokens')
            .delete()
            .eq('user_id', userId);
        debugPrint('📴 FCM tokens removed for user $userId');
      }
    } catch (e) {
      debugPrint('⚠️ Token delete error: $e');
    }
  }
}
