import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'local_notifications_platform.dart';
import 'notification_ids.dart';
import 'notification_prefs.dart';
import 'notification_schedule_math.dart';
import 'notification_settings.dart';
import 'reminder_catalog.dart';

/// ============================================================
/// Сервис ЛОКАЛЬНЫХ уведомлений Welmi (без Firebase).
/// ============================================================
///
/// Всё планируется на устройстве через flutter_local_notifications + timezone:
///  - вода (интервал внутри окна, пока не достигнута дневная цель);
///  - завтрак, обед, ужин, активность, вечернее напоминание (фикс. время).
///
/// Ключевые гарантии:
///  - стабильные уникальные id ([NotificationIds]) — повторное планирование
///    ПЕРЕЗАПИСЫВАЕТ уведомление с тем же id, дубликаты не создаются;
///  - настройки хранятся в SharedPreferences ([NotificationPrefs]);
///  - на Android расписание восстанавливается после перезагрузки
///    (ScheduledNotificationBootReceiver + BOOT_COMPLETED);
///  - цель по воде передаётся снаружи (DailyTracker), сам сервис
///    не зависит от Supabase/авторизации.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final LocalNotificationsPlatform _platform = LocalNotificationsPlatform();

  bool _isInitialized = false;
  void Function(String? payload)? _onTapCallback;

  // Публичные константы сохранены для совместимости с экранами.
  static const int idWater = NotificationIds.water;
  static const int idBreakfast = NotificationIds.breakfast;
  static const int idLunch = NotificationIds.lunch;
  static const int idDinner = NotificationIds.dinner;
  static const int idActivity = NotificationIds.activity;
  static const int idEvening = NotificationIds.evening;
  static const int idTest = NotificationIds.test;

  static const String channelWater = NotificationChannels.water;
  static const String channelMeals = NotificationChannels.meals;
  static const String channelActivity = NotificationChannels.activity;

  static const int defaultWaterIntervalMin =
      NotificationPrefs.defaultWaterIntervalMin;
  static const int defaultWaterStartMin =
      NotificationPrefs.defaultWaterStartMin;
  static const int defaultWaterEndMin = NotificationPrefs.defaultWaterEndMin;
  static const int defaultBreakfastMin = NotificationPrefs.defaultBreakfastMin;
  static const int defaultLunchMin = NotificationPrefs.defaultLunchMin;
  static const int defaultDinnerMin = NotificationPrefs.defaultDinnerMin;
  static const int defaultActivityMin = NotificationPrefs.defaultActivityMin;
  static const int defaultEveningMin = NotificationPrefs.defaultEveningMin;

  bool get isInitialized => _isInitialized;

  // ─── Инициализация и разрешения ───

  Future<void> initialize({
    void Function(String? payload)? onNotificationTap,
  }) async {
    if (_isInitialized) {
      if (onNotificationTap != null) _onTapCallback = onNotificationTap;
      return;
    }
    if (kIsWeb) {
      _isInitialized = true;
      return;
    }
    await _platform.initialize(
      onTap: _handleNotificationTap,
      onBackgroundTap: notificationTapBackground,
    );
    _onTapCallback = onNotificationTap;
    _isInitialized = true;
    debugPrint('✅ NotificationService (local) initialized');
  }

  /// Просит разрешить точные будильники (Android 12+). Без него напоминания
  /// на многих прошивках (Xiaomi, Samsung, Huawei) откладываются на часы.
  /// Перепланированием занимаются вызывающие стороны (setMasterEnabled /
  /// rescheduleAll), чтобы не потерять состояние дневной цели по воде.
  Future<void> ensureExactAlarmsPermission() async {
    if (kIsWeb) return;
    await _platform.requestExactAlarmsIfNeeded();
    await _platform.refreshScheduleMode();
  }

  /// Запрашивает разрешение на уведомления (и точные будильники на Android).
  Future<bool> requestPermissions() async {
    if (kIsWeb) return true;
    return _platform.requestPermissions(
      onAndroidGranted: ensureExactAlarmsPermission,
    );
  }

  /// Проверка, выдано ли разрешение на уведомления.
  Future<bool> checkPermissions() async {
    if (kIsWeb) return true;
    return _platform.checkPermissions();
  }

  // ─── Настройки ───

  /// Снимок настроек уведомлений для UI.
  Future<NotificationSettings> getSettings() => NotificationPrefs.load();

  /// Главный переключатель. OFF — отменяет все уведомления Welmi,
  /// ON — восстанавливает расписание из сохранённых настроек.
  Future<void> setMasterEnabled(
    bool value, {
    bool waterGoalReached = false,
  }) async {
    await NotificationPrefs.setMaster(value);
    if (value) {
      await rescheduleAll(waterGoalReached: waterGoalReached);
    } else {
      await cancelAllWelmi();
    }
  }

  /// Включение/выключение одного напоминания по id.
  Future<void> setReminderEnabled(
    int id,
    bool value, {
    bool waterGoalReached = false,
  }) async {
    if (!await NotificationPrefs.setEnabled(id, value)) return;
    final settings = await NotificationPrefs.load();
    if (!settings.masterEnabled) return cancel(id);
    if (id == idWater) return scheduleWater(waterGoalReached: waterGoalReached);
    return value ? updateSchedule(id: id) : cancel(id);
  }

  /// Изменение времени напоминания (сохраняет и перепланирует).
  Future<void> setReminderTime(int id, int hour, int minute) async {
    if (!await NotificationPrefs.setTime(id, hour, minute)) return;
    await updateSchedule(id: id, newHour: hour, newMinute: minute);
  }

  /// Изменение интервала напоминаний о воде (сохраняет и перепланирует).
  Future<void> setWaterInterval(
    int minutes, {
    bool waterGoalReached = false,
  }) async {
    await NotificationPrefs.setWaterInterval(minutes);
    await scheduleWater(waterGoalReached: waterGoalReached);
  }

  // ─── Тестовое уведомление ───

  Future<void> showTestNotification({
    String title = 'Welmi 🔔',
    String body = 'Локальные уведомления работают!',
  }) async {
    if (!_isInitialized && !kIsWeb) await initialize();
    if (kIsWeb || !await checkPermissions()) return;
    final channel = ReminderCatalog.waterChannel;
    try {
      await _platform.show(
        idTest,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
            presentBadge: true,
          ),
        ),
        payload: 'test',
      );
    } catch (e) {
      debugPrint('❌ Test notification error: $e');
    }
  }

  // ─── Планирование ───

  /// Ежедневное уведомление в заданное время (time-zone-aware).
  /// Планирование с тем же [id] заменяет прежнее — дубликатов не будет.
  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required String channelId,
    required String channelName,
    String payload = '',
  }) => _schedule(
    'scheduleDaily',
    id: id,
    title: title,
    body: body,
    when: () => nextInstanceOf(hour, minute, tz.TZDateTime.now(tz.local)),
    channelId: channelId,
    channelName: channelName,
    payload: payload,
    repeatDaily: true,
  );

  /// Повторяющееся уведомление каждые [intervalMinutes] внутри окна
  /// [startMin; endMin] (минимум 15 минут). Слоты считаются от начала дня,
  /// поэтому id остаётся одним и тем же каждый день.
  Future<void> scheduleInterval({
    required int id,
    required String title,
    required String body,
    required int intervalMinutes,
    required int startMin,
    required int endMin,
    required String channelId,
    required String channelName,
    String payload = '',
  }) => _schedule(
    'scheduleInterval',
    id: id,
    title: title,
    body: body,
    when: () => currentOrNextSlot(
      intervalMinutes < 15 ? 15 : intervalMinutes,
      startMin,
      endMin,
      tz.TZDateTime.now(tz.local),
    ),
    channelId: channelId,
    channelName: channelName,
    payload: payload,
    repeatDaily: true,
  );

  /// Разовое уведомление в конкретный момент.
  Future<void> scheduleOnce({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime when,
    required String channelId,
    required String channelName,
    String payload = '',
  }) => _schedule(
    'scheduleOnce',
    id: id,
    title: title,
    body: body,
    when: () => when,
    channelId: channelId,
    channelName: channelName,
    payload: payload,
    repeatDaily: false,
  );

  Future<void> _schedule(
    String label, {
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime Function() when,
    required String channelId,
    required String channelName,
    required String payload,
    required bool repeatDaily,
  }) async {
    if (kIsWeb) return;
    if (!_isInitialized) await initialize();
    try {
      await _platform.scheduleZoned(
        id: id,
        title: title,
        body: body,
        when: when(),
        details: _platform.detailsFor(channelId, channelName),
        payload: payload,
        matchDateTimeComponents: repeatDaily ? DateTimeComponents.time : null,
      );
    } catch (e) {
      debugPrint('❌ $label($id) error: $e');
    }
  }

  Future<void> _scheduleContent(ReminderContent c, int id, int minutes) =>
      scheduleDaily(
        id: id,
        title: c.title,
        body: c.body,
        hour: minutes ~/ 60,
        minute: minutes % 60,
        channelId: c.channelId,
        channelName: c.channelName,
        payload: c.payload,
      );

  /// Планирует напоминания о воде по сохранённым настройкам.
  /// [waterGoalReached] — достигнута ли дневная цель воды на сегодня.
  Future<void> scheduleWater({bool waterGoalReached = false}) async {
    if (kIsWeb) return;
    final s = await NotificationPrefs.load();
    if (!s.masterEnabled) return;
    if (!s.waterEnabled) return cancel(idWater);
    if (waterGoalReached) {
      // Цель достигнута — обычные напоминания до следующего дня не нужны.
      await cancel(idWater);
      debugPrint('💧 Water goal reached — reminders paused until tomorrow');
      return;
    }
    const c = ReminderCatalog.water;
    await scheduleInterval(
      id: idWater,
      title: c.title,
      body: c.body,
      intervalMinutes: s.waterIntervalMin,
      startMin: s.waterStartMin,
      endMin: s.waterEndMin,
      channelId: c.channelId,
      channelName: c.channelName,
      payload: c.payload,
    );
  }

  /// Перестраивает всё расписание из сохранённых настроек. Вызывайте при
  /// включении главного переключателя, изменении времени и при запуске
  /// приложения (id стабильны → перезапись без дубликатов).
  Future<void> rescheduleAll({bool waterGoalReached = false}) async {
    if (kIsWeb) return;
    if (!_isInitialized) await initialize();
    final s = await NotificationPrefs.load();
    if (!s.masterEnabled) return cancelAllWelmi();

    await scheduleWater(waterGoalReached: waterGoalReached);
    for (final id in NotificationIds.daily) {
      if (s.isEnabled(id)) {
        await _scheduleContent(ReminderCatalog.daily(id)!, id, s.minutesOf(id));
      } else {
        await cancel(id);
      }
    }
    debugPrint('🔔 All Welmi notifications rescheduled');
  }

  /// Изменение расписания одного напоминания.
  /// [newHour]/[newMinute] — локальное время (необязательные параметры).
  Future<void> updateSchedule({
    required int id,
    int? newHour,
    int? newMinute,
    int? newIntervalMinutes,
  }) async {
    if (kIsWeb) return;
    if (!_isInitialized) await initialize();

    // Вода: интервал передаётся отдельно через setWaterInterval.
    if (id == idWater) {
      return newIntervalMinutes != null
          ? setWaterInterval(newIntervalMinutes)
          : scheduleWater();
    }

    final s = await NotificationPrefs.load();
    if (!s.isEnabled(id)) return cancel(id);

    // Сохраняем ТОЛЬКО явно переданные значения — иначе не трогаем prefs.
    final hasNewTime = newHour != null && newMinute != null;
    if (hasNewTime) await NotificationPrefs.setTime(id, newHour, newMinute);

    final content = ReminderCatalog.daily(id);
    if (content == null) return;
    final minutes = hasNewTime ? newHour * 60 + newMinute : s.minutesOf(id);
    await _scheduleContent(content, id, minutes);
  }

  // ─── Отмена ───

  Future<void> cancel(int id) async {
    if (kIsWeb) return;
    if (!_isInitialized) await initialize();
    try {
      await _platform.cancel(id);
    } catch (e) {
      debugPrint('❌ cancel($id) error: $e');
    }
  }

  /// Отмена всех уведомлений Welmi (все id сервиса).
  Future<void> cancelAllWelmi() async {
    if (kIsWeb) return;
    if (!_isInitialized) await initialize();
    for (final id in NotificationIds.all) {
      await cancel(id);
    }
    debugPrint('🔕 All Welmi notifications cancelled');
  }

  /// Полная отмена (включая тестовые).
  Future<void> cancelAll() async {
    if (kIsWeb) return;
    if (!_isInitialized) await initialize();
    await _platform.cancelAll();
  }

  /// Убирает уже показанные уведомления из шторки, не выключая напоминания.
  ///
  /// Плагин отменяет показанное и запланированное уведомление вместе (по id),
  /// поэтому сразу восстанавливаем расписание из сохранённых настроек.
  Future<void> clearDelivered({bool waterGoalReached = false}) async {
    if (kIsWeb) return;
    await cancelAll();
    await rescheduleAll(waterGoalReached: waterGoalReached);
  }

  /// Ещё не показанные запланированные уведомления
  /// (Android 12+ / iOS; на старых Android — пустой список).
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (kIsWeb || !_isInitialized) return [];
    try {
      return await _platform.pending();
    } catch (e) {
      debugPrint('❌ pendingNotificationRequests error: $e');
      return [];
    }
  }

  // ─── Нажатия ───

  void _handleNotificationTap(NotificationResponse response) {
    debugPrint('🔔 Notification tapped: ${response.payload}');
    _onTapCallback?.call(response.payload);
  }

  /// Фоновый обработчик нажатия (приложение убито). Статическая функция:
  /// изолят не может использовать замыкания.
  @pragma('vm:entry-point')
  static Future<void> notificationTapBackground(
    NotificationResponse response,
  ) async {
    debugPrint('🔔 Notification tapped (background): ${response.payload}');
  }
}
