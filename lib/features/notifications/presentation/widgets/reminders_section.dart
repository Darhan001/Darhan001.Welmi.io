import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/services/notifications/notification_service.dart';
import 'package:lumina/core/services/notifications/notification_settings.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/features/notifications/presentation/widgets/notification_tiles.dart';
import 'package:lumina/features/notifications/presentation/widgets/water_reminder_tile.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Раздел «Напоминания»: вода и напоминания по времени дня.
class RemindersSection extends StatelessWidget {
  const RemindersSection({
    super.key,
    required this.settings,
    required this.onWaterToggle,
    required this.onWaterIntervalTap,
    required this.onToggle,
    required this.onPickTime,
  });

  final NotificationSettings settings;
  final ValueChanged<bool> onWaterToggle;
  final VoidCallback onWaterIntervalTap;
  final void Function(int id, bool enabled) onToggle;
  final void Function(int id, TimeOfDay current) onPickTime;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final loc = AppLocalizations.of(context)!;
    final s = settings;
    final reminders = [
      (
        Icons.restaurant_outlined,
        loc.breakfast,
        NotificationService.idBreakfast,
        s.breakfastEnabled,
        s.breakfastTime,
      ),
      (
        Icons.lunch_dining_outlined,
        loc.lunch,
        NotificationService.idLunch,
        s.lunchEnabled,
        s.lunchTime,
      ),
      (
        Icons.dinner_dining_outlined,
        loc.dinner,
        NotificationService.idDinner,
        s.dinnerEnabled,
        s.dinnerTime,
      ),
      (
        Icons.directions_run_outlined,
        loc.activityLog,
        NotificationService.idActivity,
        s.activityEnabled,
        s.activityTime,
      ),
      (
        Icons.nights_stay_outlined,
        loc.notifEvening,
        NotificationService.idEvening,
        s.eveningEnabled,
        s.eveningTime,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.notifReminders.toUpperCase(),
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w900,
            fontSize: 12,
            color: tc.textHint,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 12),
        WaterReminderTile(
          settings: s,
          onToggle: onWaterToggle,
          onIntervalTap: onWaterIntervalTap,
        ),
        for (final (icon, title, id, enabled, time) in reminders)
          NotificationSwitchTile(
            icon: icon,
            title: title,
            value: enabled,
            indent: true,
            time: time,
            onTimeTap: () => onPickTime(id, time),
            onChanged: (v) => onToggle(id, v),
          ),
      ],
    );
  }
}
