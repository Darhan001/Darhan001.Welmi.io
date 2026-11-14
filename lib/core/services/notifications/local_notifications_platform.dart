import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:lumina/core/theme/locale_provider.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:timezone/timezone.dart' as tz;

import 'reminder_catalog.dart';

/// Тонкая обёртка над flutter_local_notifications: инициализация, каналы,
/// разрешения и планирование с откатом на inexact-режим.
///
/// Не знает ничего о настройках и текстах — это делает [NotificationService].
class LocalNotificationsPlatform {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Режим планирования на Android.
  ///
  /// [AndroidScheduleMode.exactAllowWhileIdle] срабатывает вовремя даже в
  /// Doze/энергосбережении, но требует разрешения SCHEDULE_EXACT_ALARM
  /// (Android 12+). Пока разрешения нет — используем inexact, иначе
  /// планирование вообще перестало бы работать.
  AndroidScheduleMode _androidScheduleMode =
      AndroidScheduleMode.inexactAllowWhileIdle;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  IOSFlutterLocalNotificationsPlugin? get _ios => _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  Future<void> initialize({
    required DidReceiveNotificationResponseCallback onTap,
    required DidReceiveBackgroundNotificationResponseCallback onBackgroundTap,
  }) async {
    await _ensureTimezoneInitialized();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    // iOS: разрешение НЕ запрашиваем в момент инициализации —
    // это делает requestPermissions() в подходящий момент UX-потока.
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: onTap,
      onDidReceiveBackgroundNotificationResponse: onBackgroundTap,
    );

    await _createAndroidChannels();
    await refreshScheduleMode();
  }

  Future<void> _ensureTimezoneInitialized() async {
    tz_data.initializeTimeZones();
    try {
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
    } catch (e) {
      debugPrint('⚠️ Local timezone unavailable, fallback to UTC: $e');
      tz.setLocalLocation(tz.UTC);
    }
  }

  /// Создаёт каналы или обновляет их названия после смены языка.
  Future<void> refreshChannels() => _createAndroidChannels();

  Future<void> _createAndroidChannels() async {
    final android = _android;
    if (android == null) return;
    try {
      final loc = lookupAppLocalizations(localeProvider.locale);
      // Повторное создание канала с тем же id обновляет его название и
      // описание — так они следуют за языком приложения.
      for (final c in ReminderCatalog.channels(loc)) {
        await android.createNotificationChannel(
          AndroidNotificationChannel(
            c.id,
            c.name,
            description: c.description,
            importance: c.high ? Importance.high : Importance.defaultImportance,
          ),
        );
      }
    } catch (e) {
      debugPrint('⚠️ Channel create error: $e');
    }
  }

  /// Актуализирует режим планирования по текущему разрешению на точные
  /// будильники. На iOS/desktop ничего не делает.
  Future<void> refreshScheduleMode() async {
    if (kIsWeb) return;
    final android = _android;
    if (android == null) return;
    try {
      final canExact = await android.canScheduleExactNotifications() ?? false;
      _androidScheduleMode = canExact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;
    } catch (e) {
      debugPrint('⚠️ Exact alarm check failed: $e');
      _androidScheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
    }
  }

  /// Просит разрешение на точные будильники (Android 12+), если его нет.
  Future<void> requestExactAlarmsIfNeeded() async {
    final android = _android;
    if (android == null) return;
    try {
      final allowed = await android.canScheduleExactNotifications() ?? false;
      if (!allowed) await android.requestExactAlarmsPermission();
    } catch (e) {
      debugPrint('⚠️ Exact alarm permission request error: $e');
    }
  }

  /// Запрос разрешения на уведомления. На Android после согласия вызывается
  /// [onAndroidGranted] (запрос точных будильников).
  Future<bool> requestPermissions({
    required Future<void> Function() onAndroidGranted,
  }) async {
    try {
      final android = _android;
      if (android != null) {
        final granted = await android.requestNotificationsPermission() ?? false;
        debugPrint('📢 Android notifications permission: $granted');
        if (granted) await onAndroidGranted();
        return granted;
      }
      final ios = _ios;
      if (ios != null) {
        final granted = await ios.requestPermissions(
          alert: true,
          sound: true,
          badge: true,
        );
        return granted ?? false;
      }
    } catch (e) {
      debugPrint('❌ Permission request error: $e');
    }
    return false;
  }

  /// Выдано ли разрешение на уведомления.
  Future<bool> checkPermissions() async {
    try {
      final android = _android;
      if (android != null) {
        return await android.areNotificationsEnabled() ?? false;
      }
      final ios = _ios;
      if (ios != null) {
        final perms = await ios.checkPermissions();
        return perms?.isEnabled ?? false;
      }
    } catch (e) {
      debugPrint('❌ Permission check error: $e');
    }
    return false;
  }

  NotificationDetails detailsFor(String channelId, String channelName) =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBadge: true,
        ),
      );

  Future<void> show(
    int id,
    String title,
    String body,
    NotificationDetails details, {
    String? payload,
  }) => _plugin.show(id, title, body, details, payload: payload);

  /// Планирует уведомление через AlarmManager.
  ///
  /// Сначала пытаемся использовать точный будильник — он срабатывает
  /// вовремя даже в Doze. Если разрешение на точные будильники не выдано,
  /// `zonedSchedule` бросает исключение: в этом случае откатываемся на
  /// inexact-режим, чтобы напоминание всё равно было запланировано.
  Future<void> scheduleZoned({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime when,
    required NotificationDetails details,
    required String payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    Future<void> attempt(AndroidScheduleMode mode) => _plugin.zonedSchedule(
      id,
      title,
      body,
      when,
      details,
      androidScheduleMode: mode,
      matchDateTimeComponents: matchDateTimeComponents,
      payload: payload,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    await refreshScheduleMode();
    try {
      await attempt(_androidScheduleMode);
    } on PlatformException catch (e) {
      debugPrint('⚠️ zonedSchedule($id) failed, fallback to inexact: $e');
      _androidScheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
      await attempt(AndroidScheduleMode.inexactAllowWhileIdle);
    }
  }

  Future<void> cancel(int id) => _plugin.cancel(id);

  Future<void> cancelAll() => _plugin.cancelAll();

  Future<List<PendingNotificationRequest>> pending() =>
      _plugin.pendingNotificationRequests();
}
