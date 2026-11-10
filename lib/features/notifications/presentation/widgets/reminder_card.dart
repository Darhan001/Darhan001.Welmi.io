import 'package:flutter/material.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/app_card.dart';
import 'package:lumina/features/notifications/presentation/view_models/reminder_schedule.dart';

/// Карточка одного напоминания в расписании; по нажатию — настройки.
class ReminderCard extends StatelessWidget {
  const ReminderCard({super.key, required this.reminder, required this.onTap});

  final ScheduledReminder reminder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      radius: 20,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: reminder.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(reminder.icon, size: 20, color: reminder.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: tc.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reminder.subtitle,
                  style: TextStyle(fontSize: 12, color: tc.textSecondary),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: tc.inactive),
        ],
      ),
    );
  }
}
