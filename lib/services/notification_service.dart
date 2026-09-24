import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// ============================================================
/// Сервис ЛОКАЛЬНЫХ уведомлений Welmi (без Firebase).
/// ============================================================
///
/// Всё планируется непосредственно на устройстве через
/// flutter_local_notifications + timezone:
///  - вода (интервал с 8:00 до 22:00, пока не достигнута дневная цель);
///  - завтрак, обед, ужин, активность, вечернее напоминание (фикс. время).
///
/// Ключевые гарантии:
///  - стабильные уникальные notification IDs (см. [NotificationId]) —
///    повторное планирование ПЕРЕЗАПИСЫВАЕТ уведомление с тем же id,
///    поэтому дубликаты при каждом запуске не создаются;
///  - настройки хранятся в SharedPreferences (UserDefaults на iOS);
///  - на Android запланированные уведомления восстанавливаются после
///    перезагрузки (ScheduledNotificationBootReceiver + BOOT_COMPLETED);
///  - цель по воде передаётся снаружи (DailyTracker), сам сервис
///    не зависит от Supabase/авторизации.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  void Function(String? payload)? _onTapCallback;

  // ─── Стабильные ID уведомлений ───
  // Один тип = один id. Планирование с тем же id заменяет прежнее
  // уведомление — это и защищает от дубликатов.
  static const int idWater = 1001;
  static const int idBreakfast = 1002;
  static const int idLunch = 1003;
  static const int idDinner = 1004;
  static const int idActivity = 1005;
  static const int idEvening = 1006;
  static const int idTest = 1999;

  static const List<int> _allIds = [
    idWater,
    idBreakfast,
    idLunch,
    idDinner,
    idActivity,
    idEvening,
  ];

  // ─── Android-каналы ───
  static const String channelWater = 'welmi_water';
  static const String channelMeals = 'welmi_meals';
  static const String channelActivity = 'welmi_activity';

  // ─── Ключи SharedPreferences ───
  static const String _keyMaster = 'notif_enabled';
  static const String _keyWater = 'notif_water_enabled';
  static const String _keyWaterInterval = 'notif_water_interval_min';
  static const String _keyWaterStart = 'notif_water_start_min';
  static const String _keyWaterEnd = 'notif_water_end_min';
  static const String _keyBreakfast = 'notif_breakfast_enabled';
  static const String _keyBreakfastTime = 'notif_breakfast_min';
  static const String _keyLunch = 'notif_lunch_enabled';
  static const String _keyLunchTime = 'notif_lunch_min';
  static const String _keyDinner = 'notif_dinner_enabled';
  static const String _keyDinnerTime = 'notif_dinner_min';
  static const String _keyActivity = 'notif_activity_enabled';
  static const String _keyActivityTime = 'notif_activity_min';
  static const String _keyEvening = 'notif_evening_enabled';
  static const String _keyEveningTime = 'notif_evening_min';

  /// Значения по умолчанию (минуты от полуночи).
  static const int defaultWaterIntervalMin = 120; // каждые 2 часа
  static const int defaultWaterStartMin = 8 * 60; // 08:00
  static const int defaultWaterEndMin = 22 * 60; // 22:00
  static const int defaultBreakfastMin = 8 * 60 + 30; // 08:30
  static const int defaultLunchMin = 13 * 60; // 13:00
  static const int defaultDinnerMin = 19 * 60; // 19:00
  static const int defaultActivityMin = 18 * 60; // 18:00
  static const int defaultEveningMin = 21 * 60 + 30; // 21:30

  bool get isInitialized => _isInitialized;

  // ════════════════════════════════════════════════════════════
  // ИНИЦИАЛИЗАЦИЯ
  // ════════════════════════════════════════════════════════════

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

    await _ensureTimezoneInitialized();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    // iOS: разрешение НЕ запрашиваем в момент инициализации —
    // это делает requestPermissions() в подходящий момент UX-потока.
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _handleNotificationTap,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Заголовки/тексты запланированных напоминаний берём при показе.
    await _createAndroidChannels();
    _onTapCallback = onNotificationTap;
    _isInitialized = true;
    debugPrint('✅ NotificationService (local) initialized');
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

  Future<void> _createAndroidChannels() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;
    try {
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          channelWater,
          'Welmi · Вода',
          description: 'Напоминания о воде',
          importance: Importance.high,
        ),
      );
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          channelMeals,
          'Welmi · Питание',
          description: 'Завтрак, обед и ужин',
          importance: Importance.high,
        ),
      );
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          channelActivity,
          'Welmi · Активность',
          description: 'Активность и вечерние напоминания',
          importance: Importance.defaultImportance,
        ),
      );
    } catch (e) {
      debugPrint('⚠️ Channel create error: $e');
    }
  }

  // ════════════════════════════════════════════════════════════
  // РАЗРЕШЕНИЯ
  // ════════════════════════════════════════════════════════════

  /// Запрос разрешения (POST_NOTIFICATIONS на Android 13+; alert/sound/badge на iOS).
  Future<bool> requestPermissions() async {
    if (kIsWeb) return true;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        final granted =
            await android.requestNotificationsPermission() ?? false;
        // Точные будильники не обязательны: используем inexactAllowWhileIdle.
        debugPrint('📢 Android notifications permission: $granted');
        return granted;
      }
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
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

  /// Проверка, выдано ли разрешение на уведомления.
  Future<bool> checkPermissions() async {
    if (kIsWeb) return true;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        return await android.areNotificationsEnabled() ?? false;
      }
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        final perms = await ios.checkPermissions();
        return perms?.isEnabled ?? false;
      }
    } catch (e) {
      debugPrint('❌ Permission check error: $e');
    }
    return false;
  }

  // ════════════════════════════════════════════════════════════
  // НАСТРОЙКИ (SharedPreferences) — типизированный снимок
  // ════════════════════════════════════════════════════════════

  /// Снимок настроек уведомлений для UI.
  Future<NotificationSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return NotificationSettings(
      masterEnabled: prefs.getBool(_keyMaster) ?? true,
      waterEnabled: prefs.getBool(_keyWater) ?? true,
      waterIntervalMin:
          prefs.getInt(_keyWaterInterval) ?? defaultWaterIntervalMin,
      waterStartMin: prefs.getInt(_keyWaterStart) ?? defaultWaterStartMin,
      waterEndMin: prefs.getInt(_keyWaterEnd) ?? defaultWaterEndMin,
      breakfastEnabled: prefs.getBool(_keyBreakfast) ?? true,
      breakfastMin: prefs.getInt(_keyBreakfastTime) ?? defaultBreakfastMin,
      lunchEnabled: prefs.getBool(_keyLunch) ?? true,
      lunchMin: prefs.getInt(_keyLunchTime) ?? defaultLunchMin,
      dinnerEnabled: prefs.getBool(_keyDinner) ?? true,
      dinnerMin: prefs.getInt(_keyDinnerTime) ?? defaultDinnerMin,
      activityEnabled: prefs.getBool(_keyActivity) ?? true,
      activityMin: prefs.getInt(_keyActivityTime) ?? defaultActivityMin,
      eveningEnabled: prefs.getBool(_keyEvening) ?? true,
      eveningMin: prefs.getInt(_keyEveningTime) ?? defaultEveningMin,
    );
  }

  /// Внутренняя карта «ключ → значение» для логики планирования.
  Future<Map<String, Object>> _loadSettingsMap() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      _keyMaster: prefs.getBool(_keyMaster) ?? true,
      _keyWater: prefs.getBool(_keyWater) ?? true,
      _keyWaterInterval:
          prefs.getInt(_keyWaterInterval) ?? defaultWaterIntervalMin,
      _keyWaterStart: prefs.getInt(_keyWaterStart) ?? defaultWaterStartMin,
      _keyWaterEnd: prefs.getInt(_keyWaterEnd) ?? defaultWaterEndMin,
      _keyBreakfast: prefs.getBool(_keyBreakfast) ?? true,
      _keyBreakfastTime: prefs.getInt(_keyBreakfastTime) ?? defaultBreakfastMin,
      _keyLunch: prefs.getBool(_keyLunch) ?? true,
      _keyLunchTime: prefs.getInt(_keyLunchTime) ?? defaultLunchMin,
      _keyDinner: prefs.getBool(_keyDinner) ?? true,
      _keyDinnerTime: prefs.getInt(_keyDinnerTime) ?? defaultDinnerMin,
      _keyActivity: prefs.getBool(_keyActivity) ?? true,
      _keyActivityTime: prefs.getInt(_keyActivityTime) ?? defaultActivityMin,
      _keyEvening: prefs.getBool(_keyEvening) ?? true,
      _keyEveningTime: prefs.getInt(_keyEveningTime) ?? defaultEveningMin,
    };
  }

  /// Ключ включённости для id напоминания.
  String? _enabledKeyFor(int id) => switch (id) {
        idWater => _keyWater,
        idBreakfast => _keyBreakfast,
        idLunch => _keyLunch,
        idDinner => _keyDinner,
        idActivity => _keyActivity,
        idEvening => _keyEvening,
        _ => null,
      };

  /// Ключ времени (минуты от полуночи) для id напоминания.
  String? _timeKeyFor(int id) => switch (id) {
        idBreakfast => _keyBreakfastTime,
        idLunch => _keyLunchTime,
        idDinner => _keyDinnerTime,
        idActivity => _keyActivityTime,
        idEvening => _keyEveningTime,
        _ => null,
      };

  // ─── Сеттеры (сохраняют настройку и переplанируют) ───

  /// Главный переключатель. OFF — отменяет все уведомления Welmi,
  /// ON — восстанавливает расписание из сохранённых настроек.
  Future<void> setMasterEnabled(
    bool value, {
    bool waterGoalReached = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMaster, value);
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
    final key = _enabledKeyFor(id);
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);

    final masterOn = (await _loadSettingsMap())[_keyMaster] == true;
    if (!masterOn) {
      await cancel(id);
      return;
    }
    if (id == idWater) {
      await scheduleWater(waterGoalReached: waterGoalReached);
      return;
    }
    if (value) {
      await updateSchedule(id: id);
    } else {
      await cancel(id);
    }
  }

  /// Изменение времени напоминания (сохраняет и переplанирует).
  Future<void> setReminderTime(int id, int hour, int minute) async {
    final key = _timeKeyFor(id);
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, hour * 60 + minute);
    await updateSchedule(id: id, newHour: hour, newMinute: minute);
  }

  /// Изменение интервала напоминаний о воде (сохраняет и переplанирует).
  Future<void> setWaterInterval(
    int minutes, {
    bool waterGoalReached = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyWaterInterval, minutes);
    await scheduleWater(waterGoalReached: waterGoalReached);
  }

  // ════════════════════════════════════════════════════════════
  // ТЕСТОВОЕ УВЕДОМЛЕНИЕ
  // ════════════════════════════════════════════════════════════

  Future<void> showTestNotification({
    String title = 'Welmi 🔔',
    String body = 'Локальные уведомления работают!',
  }) async {
    if (!await _ensureReadyForImmediate()) return;
    try {
      await _plugin.show(
        idTest,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            channelWater,
            'Welmi · Вода',
            channelDescription: 'Напоминания о воде',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
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

  Future<bool> _ensureReadyForImmediate() async {
    if (!_isInitialized && !kIsWeb) await initialize();
    if (kIsWeb) return false;
    return checkPermissions();
  }

  // ════════════════════════════════════════════════════════════
  // ПЛАНИРОВАНИЕ
  // ════════════════════════════════════════════════════════════

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
  }) async {
    if (kIsWeb) return;
    if (!_isInitialized) await initialize();
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        _nextInstanceOf(hour, minute),
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
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('❌ scheduleDaily($id) error: $e');
    }
  }

  /// Повторяющееся уведомление каждые [intervalMinutes], начиная со
  /// следующего момента (минимум +1 минута) внутри окна [startMin; endMin].
  /// Используются стабильно вычисляемые «слоты»: как только до конца окна
  /// остаётся меньше интервала, слот переносится на начало следующего дня —
  /// таким образом id остаётся одним и тем же каждый день.
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
  }) async {
    if (kIsWeb) return;
    if (!_isInitialized) await initialize();
    try {
      final safeInterval = intervalMinutes < 15 ? 15 : intervalMinutes;
      final slot = _currentOrNextSlot(safeInterval, startMin, endMin);
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        slot,
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
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('❌ scheduleInterval($id) error: $e');
    }
  }

  /// Один разовое уведомление в конкретный момент.
  Future<void> scheduleOnce({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime when,
    required String channelId,
    required String channelName,
    String payload = '',
  }) async {
    if (kIsWeb) return;
    if (!_isInitialized) await initialize();
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        when,
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
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('❌ scheduleOnce($id) error: $e');
    }
  }

  // ════════════════════════════════════════════════════════════
  // ВОДА (привязка к дневной цели)
  // ════════════════════════════════════════════════════════════

  /// Планирует напоминания о воде по сохранённым настройкам.
  /// [waterGoalReached] — достигнута ли дневная цель воды на сегодня.
  Future<void> scheduleWater({bool waterGoalReached = false}) async {
    if (kIsWeb) return;
    final s = await _loadSettingsMap();
    if (s[_keyMaster] != true) return;
    if (s[_keyWater] != true) {
      await cancel(idWater);
      return;
    }
    if (waterGoalReached) {
      // Цель достигнута — обычные напоминания до следующего дня не нужны.
      await cancel(idWater);
      debugPrint('💧 Water goal reached — reminders paused until tomorrow');
      return;
    }
    await scheduleInterval(
      id: idWater,
      title: '💧 Пора выпить воды',
      body: 'Не забывай о дневной цели по воде в Welmi',
      intervalMinutes: s[_keyWaterInterval] as int,
      startMin: s[_keyWaterStart] as int,
      endMin: s[_keyWaterEnd] as int,
      channelId: channelWater,
      channelName: 'Welmi · Вода',
      payload: 'water',
    );
  }

  // ════════════════════════════════════════════════════════════
  // ПОЛНОЕ ВОССТАНОВЛЕНИЕ РАСПИСАНИЯ
  // ════════════════════════════════════════════════════════════

  /// Перестраивает всё расписание из сохранённых настроек.
  /// Вызывайте при включении главного переключателя, изменении времени,
  /// и при запуске приложения (id стабильны → перезапись без дубликатов).
  /// [waterGoalReached] — текущее состояние дневной цели воды.
  Future<void> rescheduleAll({bool waterGoalReached = false}) async {
    if (kIsWeb) return;
    if (!_isInitialized) await initialize();
    final s = await _loadSettingsMap();
    final masterOn = s[_keyMaster] == true;

    if (!masterOn) {
      await cancelAllWelmi();
      return;
    }

    // Вода (см. scheduleWater — там же обработка достигнутой цели).
    await scheduleWater(waterGoalReached: waterGoalReached);

    // Приёмы пищи.
    if (s[_keyBreakfast] == true) {
      await scheduleDaily(
        id: idBreakfast,
        title: '🍳 Завтрак',
        body: 'Время позавтракать и записать приём пищи в дневник',
        hour: (s[_keyBreakfastTime] as int) ~/ 60,
        minute: (s[_keyBreakfastTime] as int) % 60,
        channelId: channelMeals,
        channelName: 'Welmi · Питание',
        payload: 'diary',
      );
    } else {
      await cancel(idBreakfast);
    }

    if (s[_keyLunch] == true) {
      await scheduleDaily(
        id: idLunch,
        title: '🍽 Обед',
        body: 'Не забудь пообедать и внести приём пищи в дневник',
        hour: (s[_keyLunchTime] as int) ~/ 60,
        minute: (s[_keyLunchTime] as int) % 60,
        channelId: channelMeals,
        channelName: 'Welmi · Питание',
        payload: 'diary',
      );
    } else {
      await cancel(idLunch);
    }

    if (s[_keyDinner] == true) {
      await scheduleDaily(
        id: idDinner,
        title: '🌙 Ужин',
        body: 'Время ужина — запиши приём пищи в Welmi',
        hour: (s[_keyDinnerTime] as int) ~/ 60,
        minute: (s[_keyDinnerTime] as int) % 60,
        channelId: channelMeals,
        channelName: 'Welmi · Питание',
        payload: 'diary',
      );
    } else {
      await cancel(idDinner);
    }

    // Активность.
    if (s[_keyActivity] == true) {
      await scheduleDaily(
        id: idActivity,
        title: '🏃 Время подвигаться',
        body: 'Немного активности приблизит тебя к цели',
        hour: (s[_keyActivityTime] as int) ~/ 60,
        minute: (s[_keyActivityTime] as int) % 60,
        channelId: channelActivity,
        channelName: 'Welmi · Активность',
        payload: 'activity',
      );
    } else {
      await cancel(idActivity);
    }

    // Вечернее напоминание.
    if (s[_keyEvening] == true) {
      await scheduleDaily(
        id: idEvening,
        title: '✨ Подведи итоги дня',
        body: 'Проверь воду, питание и вес в Welmi перед сном',
        hour: (s[_keyEveningTime] as int) ~/ 60,
        minute: (s[_keyEveningTime] as int) % 60,
        channelId: channelActivity,
        channelName: 'Welmi · Активность',
        payload: 'progress',
      );
    } else {
      await cancel(idEvening);
    }

    debugPrint('🔔 All Welmi notifications rescheduled');
  }

  /// Изменение существующего расписания одного напоминания.
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
      if (newIntervalMinutes != null) {
        await setWaterInterval(newIntervalMinutes);
      } else {
        await scheduleWater();
      }
      return;
    }

    final s = await _loadSettingsMap();
    final enabledKey = _enabledKeyFor(id);
    final isEnabled = enabledKey != null && s[enabledKey] == true;
    if (!isEnabled) {
      await cancel(id);
      return;
    }

    // Сохраняем ТОЛЬКО явно переданные значения — иначе не трогаем prefs.
    final timeKey = _timeKeyFor(id);
    if (timeKey != null && newHour != null && newMinute != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(timeKey, newHour * 60 + newMinute);
    }

    // Перепланируем только это уведомление.
    switch (id) {
      case idBreakfast:
        final t = timeOf(s, id, hour: newHour, minute: newMinute);
        await scheduleDaily(
          id: id,
          title: '🍳 Завтрак',
          body: 'Время позавтракать и записать приём пищи в дневник',
          hour: t.$1,
          minute: t.$2,
          channelId: channelMeals,
          channelName: 'Welmi · Питание',
          payload: 'diary',
        );
      case idLunch:
        final t = timeOf(s, id, hour: newHour, minute: newMinute);
        await scheduleDaily(
          id: id,
          title: '🍽 Обед',
          body: 'Не забудь пообедать и внести приём пищи в дневник',
          hour: t.$1,
          minute: t.$2,
          channelId: channelMeals,
          channelName: 'Welmi · Питание',
          payload: 'diary',
        );
      case idDinner:
        final t = timeOf(s, id, hour: newHour, minute: newMinute);
        await scheduleDaily(
          id: id,
          title: '🌙 Ужин',
          body: 'Время ужина — запиши приём пищи в Welmi',
          hour: t.$1,
          minute: t.$2,
          channelId: channelMeals,
          channelName: 'Welmi · Питание',
          payload: 'diary',
        );
      case idActivity:
        final t = timeOf(s, id, hour: newHour, minute: newMinute);
        await scheduleDaily(
          id: id,
          title: '🏃 Время подвигаться',
          body: 'Немного активности приблизит тебя к цели',
          hour: t.$1,
          minute: t.$2,
          channelId: channelActivity,
          channelName: 'Welmi · Активность',
          payload: 'activity',
        );
      case idEvening:
        final t = timeOf(s, id, hour: newHour, minute: newMinute);
        await scheduleDaily(
          id: id,
          title: '✨ Подведи итоги дня',
          body: 'Проверь воду, питание и вес в Welmi перед сном',
          hour: t.$1,
          minute: t.$2,
          channelId: channelActivity,
          channelName: 'Welmi · Активность',
          payload: 'progress',
        );
    }
  }

  (int, int) timeOf(
    Map<String, Object> s,
    int id, {
    int? hour,
    int? minute,
  }) {
    final timeKey = switch (id) {
      idBreakfast => _keyBreakfastTime,
      idLunch => _keyLunchTime,
      idDinner => _keyDinnerTime,
      idActivity => _keyActivityTime,
      idEvening => _keyEveningTime,
      _ => _keyBreakfastTime,
    };
    final stored = hour != null && minute != null
        ? hour * 60 + minute
        : (s[timeKey] as int?) ?? defaultBreakfastMin;
    return (stored ~/ 60, stored % 60);
  }

  // ════════════════════════════════════════════════════════════
  // ОТМЕНА
  // ════════════════════════════════════════════════════════════

  Future<void> cancel(int id) async {
    if (kIsWeb) return;
    if (!_isInitialized) await initialize();
    try {
      await _plugin.cancel(id);
    } catch (e) {
      debugPrint('❌ cancel($id) error: $e');
    }
  }

  /// Отмена всех уведомлений Welmi (все id сервиса).
  Future<void> cancelAllWelmi() async {
    if (kIsWeb) return;
    if (!_isInitialized) await initialize();
    for (final id in _allIds) {
      await cancel(id);
    }
    debugPrint('🔕 All Welmi notifications cancelled');
  }

  /// Полная отмена (включая тестовые).
  Future<void> cancelAll() async {
    if (kIsWeb) return;
    if (!_isInitialized) await initialize();
    await _plugin.cancelAll();
  }

  // ════════════════════════════════════════════════════════════
  // СПИСОК ЗАПЛАНИРОВАННЫХ
  // ════════════════════════════════════════════════════════════

  /// Список ещё не показанных запланированных уведомлений
  /// (работает на Android 12+ / iOS; на старых Android — пустой список).
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (kIsWeb || !_isInitialized) return [];
    try {
      return await _plugin.pendingNotificationRequests();
    } catch (e) {
      debugPrint('❌ pendingNotificationRequests error: $e');
      return [];
    }
  }

  // ════════════════════════════════════════════════════════════
  // ОБРАБОТКА НАЖАТИЯ
  // ════════════════════════════════════════════════════════════

  void _handleNotificationTap(NotificationResponse response) {
    debugPrint('🔔 Notification tapped: ${response.payload}');
    _onTapCallback?.call(response.payload);
  }

  /// Фоновый обработчик нажатия (приложение убито). Топ-левел функция:
  /// изолят не может использовать замыкания.
  @pragma('vm:entry-point')
  static Future<void> notificationTapBackground(
    NotificationResponse response,
  ) async {
    debugPrint('🔔 Notification tapped (background): ${response.payload}');
  }

  // ════════════════════════════════════════════════════════════
  // ВРЕМЕННЫЕ ХЕЛПЕРЫ
  // ════════════════════════════════════════════════════════════

  /// Ближайший момент [hour]:[minute] по локальному часовому поясу
  /// (сегодня, если время ещё не прошло, иначе — завтра).
  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var when = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!when.isAfter(now)) {
      when = when.add(const Duration(days: 1));
    }
    return when;
  }

  /// Ближайший «слот» повторяющегося напоминания: окно [startMin; endMin]
  /// делится на шаги [intervalMinutes]. Берём следующий слот после текущего
  /// момента; если следующего слота в окне нет — первый слот завтра
  /// (время вычисляется от начала дня, поэтому id остаётся стабильным).
  tz.TZDateTime _currentOrNextSlot(
    int intervalMinutes,
    int startMin,
    int endMin,
  ) {
    final now = tz.TZDateTime.now(tz.local);
    final nowMin = now.hour * 60 + now.minute;
    final window = endMin - startMin;
    final step = intervalMinutes.clamp(1, window <= 0 ? 1 : window);

    int slotMin = startMin;
    // Первый слот строго ПОСЛЕ текущего момента.
    while (slotMin <= nowMin) {
      slotMin += step;
    }
    if (slotMin > endMin) {
      // Окно на сегодня закончилось → первый слот завтра.
      final tomorrow = now.add(const Duration(days: 1));
      return tz.TZDateTime(
        tz.local,
        tomorrow.year,
        tomorrow.month,
        tomorrow.day,
        startMin ~/ 60,
        startMin % 60,
      );
    }
    return tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      slotMin ~/ 60,
      slotMin % 60,
    );
  }
}

/// Типизированный снимок настроек уведомлений для UI.
class NotificationSettings {
  const NotificationSettings({
    required this.masterEnabled,
    required this.waterEnabled,
    required this.waterIntervalMin,
    required this.waterStartMin,
    required this.waterEndMin,
    required this.breakfastEnabled,
    required this.breakfastMin,
    required this.lunchEnabled,
    required this.lunchMin,
    required this.dinnerEnabled,
    required this.dinnerMin,
    required this.activityEnabled,
    required this.activityMin,
    required this.eveningEnabled,
    required this.eveningMin,
  });

  final bool masterEnabled;
  final bool waterEnabled;
  final int waterIntervalMin;
  final int waterStartMin;
  final int waterEndMin;
  final bool breakfastEnabled;
  final int breakfastMin;
  final bool lunchEnabled;
  final int lunchMin;
  final bool dinnerEnabled;
  final int dinnerMin;
  final bool activityEnabled;
  final int activityMin;
  final bool eveningEnabled;
  final int eveningMin;

  /// Локальное время напоминания как TimeOfDay для UI.
  TimeOfDay get breakfastTime =>
      TimeOfDay(hour: breakfastMin ~/ 60, minute: breakfastMin % 60);
  TimeOfDay get lunchTime => TimeOfDay(hour: lunchMin ~/ 60, minute: lunchMin % 60);
  TimeOfDay get dinnerTime =>
      TimeOfDay(hour: dinnerMin ~/ 60, minute: dinnerMin % 60);
  TimeOfDay get activityTime =>
      TimeOfDay(hour: activityMin ~/ 60, minute: activityMin % 60);
  TimeOfDay get eveningTime =>
      TimeOfDay(hour: eveningMin ~/ 60, minute: eveningMin % 60);

  /// Описание интервала воды для подзаголовка, например «Каждые 2 ч».
  String get waterIntervalLabel {
    if (waterIntervalMin % 60 == 0) {
      final h = waterIntervalMin ~/ 60;
      return h == 1 ? 'Каждый час' : 'Каждые $h ч';
    }
    return 'Каждые $waterIntervalMin мин';
  }
}
