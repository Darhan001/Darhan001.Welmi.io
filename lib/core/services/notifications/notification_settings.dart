import 'package:flutter/material.dart' show TimeOfDay;

import 'notification_ids.dart';

/// Типизированный снимок настроек уведомлений для UI и планировщика.
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

  /// Включено ли напоминание с данным id (без учёта главного переключателя).
  bool isEnabled(int id) => switch (id) {
    NotificationIds.water => waterEnabled,
    NotificationIds.breakfast => breakfastEnabled,
    NotificationIds.lunch => lunchEnabled,
    NotificationIds.dinner => dinnerEnabled,
    NotificationIds.activity => activityEnabled,
    NotificationIds.evening => eveningEnabled,
    _ => false,
  };

  /// Время напоминания с фиксированным временем (минуты от полуночи).
  /// Для неизвестного id — время завтрака, как и раньше.
  int minutesOf(int id) => switch (id) {
    NotificationIds.lunch => lunchMin,
    NotificationIds.dinner => dinnerMin,
    NotificationIds.activity => activityMin,
    NotificationIds.evening => eveningMin,
    _ => breakfastMin,
  };

  /// Локальное время напоминания как TimeOfDay для UI.
  TimeOfDay get breakfastTime => _time(breakfastMin);
  TimeOfDay get lunchTime => _time(lunchMin);
  TimeOfDay get dinnerTime => _time(dinnerMin);
  TimeOfDay get activityTime => _time(activityMin);
  TimeOfDay get eveningTime => _time(eveningMin);

  static TimeOfDay _time(int minutes) =>
      TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);

  /// Описание интервала воды для подзаголовка, например «Каждые 2 ч».
  String get waterIntervalLabel {
    if (waterIntervalMin % 60 == 0) {
      final h = waterIntervalMin ~/ 60;
      return h == 1 ? 'Каждый час' : 'Каждые $h ч';
    }
    return 'Каждые $waterIntervalMin мин';
  }
}
