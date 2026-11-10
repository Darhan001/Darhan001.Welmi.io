import 'package:flutter/material.dart';
import 'package:lumina/core/services/notifications/notification_settings.dart';
import 'package:lumina/features/notifications/presentation/widgets/notification_tiles.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Одно включённое напоминание в расписании.
class ScheduledReminder {
  const ScheduledReminder({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.sortMinutes,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  /// Минуты от полуночи — для сортировки по времени дня.
  final int sortMinutes;
}

/// Строит список включённых напоминаний, отсортированный по времени дня.
/// [formatTime] превращает минуты от полуночи в строку времени.
List<ScheduledReminder> buildReminderSchedule(
  NotificationSettings s,
  AppLocalizations loc,
  String Function(int minutes) formatTime,
) {
  final reminders = <ScheduledReminder>[
    if (s.waterEnabled)
      ScheduledReminder(
        icon: Icons.water_drop_outlined,
        color: const Color(0xFF3B82F6),
        title: loc.waterReminders,
        subtitle:
            '${waterIntervalLabel(s, loc)} · ${formatTime(s.waterStartMin)}–${formatTime(s.waterEndMin)}',
        sortMinutes: s.waterStartMin,
      ),
    if (s.breakfastEnabled)
      ScheduledReminder(
        icon: Icons.free_breakfast_outlined,
        color: const Color(0xFFF59E0B),
        title: loc.breakfast,
        subtitle: formatTime(s.breakfastMin),
        sortMinutes: s.breakfastMin,
      ),
    if (s.lunchEnabled)
      ScheduledReminder(
        icon: Icons.lunch_dining_outlined,
        color: const Color(0xFFF97316),
        title: loc.lunch,
        subtitle: formatTime(s.lunchMin),
        sortMinutes: s.lunchMin,
      ),
    if (s.dinnerEnabled)
      ScheduledReminder(
        icon: Icons.dinner_dining_outlined,
        color: const Color(0xFFEF4444),
        title: loc.dinner,
        subtitle: formatTime(s.dinnerMin),
        sortMinutes: s.dinnerMin,
      ),
    if (s.activityEnabled)
      ScheduledReminder(
        icon: Icons.directions_run_rounded,
        color: const Color(0xFF75A47F),
        title: loc.activityLog,
        subtitle: formatTime(s.activityMin),
        sortMinutes: s.activityMin,
      ),
    if (s.eveningEnabled)
      ScheduledReminder(
        icon: Icons.nightlight_outlined,
        color: const Color(0xFF8B5CF6),
        title: loc.notifEvening,
        subtitle: formatTime(s.eveningMin),
        sortMinutes: s.eveningMin,
      ),
  ]..sort((a, b) => a.sortMinutes.compareTo(b.sortMinutes));
  return reminders;
}
