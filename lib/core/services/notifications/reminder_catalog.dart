import 'notification_ids.dart';

/// Содержимое одного напоминания: тексты, канал и маршрут по нажатию.
///
/// Раньше эти тексты были продублированы в `rescheduleAll` и
/// `updateSchedule`; теперь — единый справочник.
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

abstract final class ReminderCatalog {
  static const String _waterName = 'Welmi · Вода';
  static const String _mealsName = 'Welmi · Питание';
  static const String _activityName = 'Welmi · Активность';

  static const List<ReminderChannel> channels = [
    ReminderChannel(
      NotificationChannels.water,
      _waterName,
      'Напоминания о воде',
    ),
    ReminderChannel(
      NotificationChannels.meals,
      _mealsName,
      'Завтрак, обед и ужин',
    ),
    ReminderChannel(
      NotificationChannels.activity,
      _activityName,
      'Активность и вечерние напоминания',
      high: false,
    ),
  ];

  /// Канал воды — им же пользуется тестовое уведомление.
  static ReminderChannel get waterChannel => channels.first;

  static const ReminderContent water = ReminderContent(
    title: '💧 Пора выпить воды',
    body: 'Не забывай о дневной цели по воде в Welmi',
    channelId: NotificationChannels.water,
    channelName: _waterName,
    payload: 'water',
  );

  /// Содержимое напоминания с фиксированным временем; null для воды и
  /// неизвестных id.
  static ReminderContent? daily(int id) => switch (id) {
    NotificationIds.breakfast => const ReminderContent(
      title: '🍳 Завтрак',
      body: 'Время позавтракать и записать приём пищи в дневник',
      channelId: NotificationChannels.meals,
      channelName: _mealsName,
      payload: 'diary',
    ),
    NotificationIds.lunch => const ReminderContent(
      title: '🍽 Обед',
      body: 'Не забудь пообедать и внести приём пищи в дневник',
      channelId: NotificationChannels.meals,
      channelName: _mealsName,
      payload: 'diary',
    ),
    NotificationIds.dinner => const ReminderContent(
      title: '🌙 Ужин',
      body: 'Время ужина — запиши приём пищи в Welmi',
      channelId: NotificationChannels.meals,
      channelName: _mealsName,
      payload: 'diary',
    ),
    NotificationIds.activity => const ReminderContent(
      title: '🏃 Время подвигаться',
      body: 'Немного активности приблизит тебя к цели',
      channelId: NotificationChannels.activity,
      channelName: _activityName,
      payload: 'activity',
    ),
    NotificationIds.evening => const ReminderContent(
      title: '✨ Подведи итоги дня',
      body: 'Проверь воду, питание и вес в Welmi перед сном',
      channelId: NotificationChannels.activity,
      channelName: _activityName,
      payload: 'progress',
    ),
    _ => null,
  };
}
