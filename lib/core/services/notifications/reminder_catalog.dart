import 'package:lumina/l10n/app_localizations.dart';

import 'notification_ids.dart';

/// Содержимое одного напоминания: тексты, канал и маршрут по нажатию.
class ReminderContent {
  const ReminderContent({
    required this.title,
    required this.body,
    required this.channelId,
    required this.channelName,
    required this.payload,
  });

  final String title;
  final String body;
  final String channelId;
  final String channelName;

  /// Маршрут, который откроется по нажатию ('water', 'diary' и т.д.).
  final String payload;
}

/// Описание Android-канала (создаётся при инициализации).
class ReminderChannel {
  const ReminderChannel(
    this.id,
    this.name,
    this.description, {
    this.high = true,
  });

  final String id;
  final String name;
  final String description;

  /// true — Importance.high, false — Importance.defaultImportance.
  final bool high;
}

/// Справочник напоминаний на языке приложения.
///
/// Тексты берутся из локализации: раньше заголовки уведомлений и названия
/// каналов были только на русском, какой бы язык ни выбрал пользователь.
/// Уведомление планируется заранее, поэтому после смены языка расписание
/// нужно перестроить (см. `WelmiApp`).
abstract final class ReminderCatalog {
  static List<ReminderChannel> channels(AppLocalizations loc) => [
    ReminderChannel(
      NotificationChannels.water,
      loc.notifChannelWater,
      loc.notifChannelWaterDesc,
    ),
    ReminderChannel(
      NotificationChannels.meals,
      loc.notifChannelMeals,
      loc.notifChannelMealsDesc,
    ),
    ReminderChannel(
      NotificationChannels.activity,
      loc.notifChannelActivity,
      loc.notifChannelActivityDesc,
      high: false,
    ),
  ];

  /// Канал воды — им же пользуется тестовое уведомление.
  static ReminderChannel waterChannel(AppLocalizations loc) =>
      channels(loc).first;

  static ReminderContent water(AppLocalizations loc) => ReminderContent(
    title: loc.remWaterTitle,
    body: loc.remWaterBody,
    channelId: NotificationChannels.water,
    channelName: loc.notifChannelWater,
    payload: 'water',
  );

  /// Содержимое напоминания с фиксированным временем; null для воды и
  /// неизвестных id.
  static ReminderContent? daily(AppLocalizations loc, int id) => switch (id) {
    NotificationIds.breakfast => ReminderContent(
      title: loc.remBreakfastTitle,
      body: loc.remBreakfastBody,
      channelId: NotificationChannels.meals,
      channelName: loc.notifChannelMeals,
      payload: 'diary',
    ),
    NotificationIds.lunch => ReminderContent(
      title: loc.remLunchTitle,
      body: loc.remLunchBody,
      channelId: NotificationChannels.meals,
      channelName: loc.notifChannelMeals,
      payload: 'diary',
    ),
    NotificationIds.dinner => ReminderContent(
      title: loc.remDinnerTitle,
      body: loc.remDinnerBody,
      channelId: NotificationChannels.meals,
      channelName: loc.notifChannelMeals,
      payload: 'diary',
    ),
    NotificationIds.activity => ReminderContent(
      title: loc.remActivityTitle,
      body: loc.remActivityBody,
      channelId: NotificationChannels.activity,
      channelName: loc.notifChannelActivity,
      payload: 'activity',
    ),
    NotificationIds.evening => ReminderContent(
      title: loc.remEveningTitle,
      body: loc.remEveningBody,
      channelId: NotificationChannels.activity,
      channelName: loc.notifChannelActivity,
      payload: 'progress',
    ),
    _ => null,
  };
}
