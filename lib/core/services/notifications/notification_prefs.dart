import 'package:shared_preferences/shared_preferences.dart';

import 'notification_ids.dart';
import 'notification_settings.dart';

/// Хранение настроек уведомлений в SharedPreferences (UserDefaults на iOS).
///
/// Ключи и значения по умолчанию совпадают с прежними — сохранённые
/// у пользователей настройки читаются без миграции.
abstract final class NotificationPrefs {
  static const String keyMaster = 'notif_enabled';
  static const String keyWater = 'notif_water_enabled';
  static const String keyWaterInterval = 'notif_water_interval_min';
  static const String keyWaterStart = 'notif_water_start_min';
  static const String keyWaterEnd = 'notif_water_end_min';
  static const String keyBreakfast = 'notif_breakfast_enabled';
  static const String keyBreakfastTime = 'notif_breakfast_min';
  static const String keyLunch = 'notif_lunch_enabled';
  static const String keyLunchTime = 'notif_lunch_min';
  static const String keyDinner = 'notif_dinner_enabled';
  static const String keyDinnerTime = 'notif_dinner_min';
  static const String keyActivity = 'notif_activity_enabled';
  static const String keyActivityTime = 'notif_activity_min';
  static const String keyEvening = 'notif_evening_enabled';
  static const String keyEveningTime = 'notif_evening_min';

  /// Значения по умолчанию (минуты от полуночи).
  static const int defaultWaterIntervalMin = 120; // каждые 2 часа
  static const int defaultWaterStartMin = 8 * 60; // 08:00
  static const int defaultWaterEndMin = 22 * 60; // 22:00
  static const int defaultBreakfastMin = 8 * 60 + 30; // 08:30
  static const int defaultLunchMin = 13 * 60; // 13:00
  static const int defaultDinnerMin = 19 * 60; // 19:00
  static const int defaultActivityMin = 18 * 60; // 18:00
  static const int defaultEveningMin = 21 * 60 + 30; // 21:30

  /// Ключ включённости для id напоминания.
  static String? enabledKeyFor(int id) => switch (id) {
    NotificationIds.water => keyWater,
    NotificationIds.breakfast => keyBreakfast,
    NotificationIds.lunch => keyLunch,
    NotificationIds.dinner => keyDinner,
    NotificationIds.activity => keyActivity,
    NotificationIds.evening => keyEvening,
    _ => null,
  };

  /// Ключ времени (минуты от полуночи) для id напоминания.
  static String? timeKeyFor(int id) => switch (id) {
    NotificationIds.breakfast => keyBreakfastTime,
    NotificationIds.lunch => keyLunchTime,
    NotificationIds.dinner => keyDinnerTime,
    NotificationIds.activity => keyActivityTime,
    NotificationIds.evening => keyEveningTime,
    _ => null,
  };

  /// Текущий снимок настроек.
  static Future<NotificationSettings> load() async {
    final p = await SharedPreferences.getInstance();
    return NotificationSettings(
      masterEnabled: p.getBool(keyMaster) ?? true,
      waterEnabled: p.getBool(keyWater) ?? true,
      waterIntervalMin: p.getInt(keyWaterInterval) ?? defaultWaterIntervalMin,
      waterStartMin: p.getInt(keyWaterStart) ?? defaultWaterStartMin,
      waterEndMin: p.getInt(keyWaterEnd) ?? defaultWaterEndMin,
      breakfastEnabled: p.getBool(keyBreakfast) ?? true,
      breakfastMin: p.getInt(keyBreakfastTime) ?? defaultBreakfastMin,
      lunchEnabled: p.getBool(keyLunch) ?? true,
      lunchMin: p.getInt(keyLunchTime) ?? defaultLunchMin,
      dinnerEnabled: p.getBool(keyDinner) ?? true,
      dinnerMin: p.getInt(keyDinnerTime) ?? defaultDinnerMin,
      activityEnabled: p.getBool(keyActivity) ?? true,
      activityMin: p.getInt(keyActivityTime) ?? defaultActivityMin,
      eveningEnabled: p.getBool(keyEvening) ?? true,
      eveningMin: p.getInt(keyEveningTime) ?? defaultEveningMin,
    );
  }

  static Future<void> setMaster(bool value) async =>
      (await SharedPreferences.getInstance()).setBool(keyMaster, value);

  /// Сохраняет включённость напоминания. Возвращает false для неизвестного id.
  static Future<bool> setEnabled(int id, bool value) async {
    final key = enabledKeyFor(id);
    if (key == null) return false;
    await (await SharedPreferences.getInstance()).setBool(key, value);
    return true;
  }

  /// Сохраняет время напоминания. Возвращает false для id без времени.
  static Future<bool> setTime(int id, int hour, int minute) async {
    final key = timeKeyFor(id);
    if (key == null) return false;
    await (await SharedPreferences.getInstance()).setInt(
      key,
      hour * 60 + minute,
    );
    return true;
  }

  static Future<void> setWaterInterval(int minutes) async =>
      (await SharedPreferences.getInstance()).setInt(keyWaterInterval, minutes);
}
