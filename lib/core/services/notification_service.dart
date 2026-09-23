import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// Сервис локальных уведомлений
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // Настройки уведомлений
  bool waterRemindersEnabled = true;
  bool mealRemindersEnabled = true;
  bool motivationalEnabled = false;

  /// Инициализация
  Future<void> initialize() async {
    if (_isInitialized) return;

    if (kIsWeb) {
      _isInitialized = true;
      return;
    }

    try {
      // Инициализируем базу данных часовых поясов
      tz_data.initializeTimeZones();
      
      // Чтобы избежать ошибок с отсутствующим пакетом flutter_timezone,
      // устанавливаем локацию по умолчанию (например, Europe/Moscow или UTC).
      // Это обеспечит работу функций планирования уведомлений.
      tz.setLocalLocation(tz.getLocation('Europe/Moscow'));
    } catch (e) {
      debugPrint('❌ Timezone init error: $e');
      try {
        tz.setLocalLocation(tz.getLocation('UTC'));
      } catch (_) {}
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _isInitialized = true;
    debugPrint('✅ NotificationService initialized without external timezone package');
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('🔔 Notification tapped: ${response.payload}');
  }

  /// Запросить разрешения (обязательно для Android 13+)
  Future<bool> requestPermissions() async {
    if (kIsWeb) return true;

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      debugPrint('📢 Android notification permission: $granted');
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      await ios.requestPermissions(alert: true, badge: true, sound: true);
    }
    return true;
  }

  /// Показать мгновенное уведомление
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'welmi_general',
      'Welmi General',
      channelDescription: 'Основной канал уведомлений',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails());
    await _plugin.show(id, title, body, details);
  }

  Future<void> scheduleRepeating({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required List<int> weekdays,
  }) async {
    final now = tz.TZDateTime.now(tz.local);

    for (final day in weekdays) {
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      try {
        await _plugin.zonedSchedule(
          id + day,
          title,
          body,
          scheduledDate,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'welmi_repeating',
              'Напоминания Welmi',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (e) {
        debugPrint('❌ Error scheduling notification $id: $e');
      }
    }
  }

  Future<void> startAllNotifications() async {
    if (kIsWeb) return;
    await cancelAll();
    
    if (waterRemindersEnabled) {
      await scheduleRepeating(
        id: 100,
        title: '💧 Время пить воду!',
        body: 'Не забудь выпить стакан чистой воды.',
        hour: 10, minute: 0, weekdays: [1,2,3,4,5,6,7],
      );
      await scheduleRepeating(
        id: 110,
        title: '💧 Пора освежиться',
        body: 'Твоему телу нужна вода для энергии.',
        hour: 14, minute: 30, weekdays: [1,2,3,4,5,6,7],
      );
    }
    
    debugPrint('🔔 All notifications rescheduled');
  }

  Future<void> cancelAll() async => await _plugin.cancelAll();
  
  Future<void> updateSettings({bool? waterReminders, bool? mealReminders, bool? motivational}) async {
    waterRemindersEnabled = waterReminders ?? waterRemindersEnabled;
    mealRemindersEnabled = mealReminders ?? mealRemindersEnabled;
    motivationalEnabled = motivational ?? motivationalEnabled;
    await startAllNotifications();
  }
}
