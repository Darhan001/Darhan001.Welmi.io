/// Стабильные идентификаторы и Android-каналы локальных уведомлений Welmi.
///
/// Один тип напоминания = один id. Планирование с тем же id заменяет прежнее
/// уведомление — это и защищает от дубликатов при каждом запуске.
abstract final class NotificationIds {
  static const int water = 1001;
  static const int breakfast = 1002;
  static const int lunch = 1003;
  static const int dinner = 1004;
  static const int activity = 1005;
  static const int evening = 1006;
  static const int test = 1999;

  /// Все id, которыми управляет сервис (без тестового).
  static const List<int> all = [
    water,
    breakfast,
    lunch,
    dinner,
    activity,
    evening,
  ];

  /// Напоминания с фиксированным временем (все, кроме воды).
  static const List<int> daily = [breakfast, lunch, dinner, activity, evening];
}

/// Android-каналы уведомлений.
abstract final class NotificationChannels {
  static const String water = 'welmi_water';
  static const String meals = 'welmi_meals';
  static const String activity = 'welmi_activity';
}
