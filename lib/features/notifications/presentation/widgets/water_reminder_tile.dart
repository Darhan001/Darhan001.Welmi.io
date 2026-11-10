import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/services/notifications/notification_settings.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/features/notifications/presentation/widgets/notification_tiles.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Напоминания о воде: переключатель и выбор интервала.
class WaterReminderTile extends StatelessWidget {
  const WaterReminderTile({
    super.key,
    required this.settings,
    required this.onToggle,
    required this.onIntervalTap,
  });

  final NotificationSettings settings;
  final ValueChanged<bool> onToggle;
  final VoidCallback onIntervalTap;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final loc = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: notificationTileDecoration(tc),
      child: Column(
        children: [
          NotificationSwitchTile(
            icon: Icons.local_drink_outlined,
            title: loc.waterReminders,
            subtitle: loc.waterRemindersSubtitle,
            value: settings.waterEnabled,
            onChanged: onToggle,
            decorated: false,
          ),
          if (settings.waterEnabled)
            Padding(
              padding: const EdgeInsets.only(left: 52, right: 16, bottom: 12),
              child: Row(
                children: [
                  Icon(Icons.timer_outlined, size: 18, color: tc.textHint),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      loc.notifWaterInterval,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: tc.textSecondary,
                      ),
                    ),
                  ),
                  NotificationValueChip(
                    label: waterIntervalLabel(settings, loc),
                    onTap: onIntervalTap,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Лист выбора интервала напоминаний о воде. Возвращает минуты.
Future<int?> showWaterIntervalSheet(BuildContext context, int current) {
  final loc = AppLocalizations.of(context)!;
  final options = [
    (30, loc.notifEvery30Min),
    (60, loc.notifEvery1h),
    (90, loc.notifEvery90Min),
    (120, loc.notifEvery2h),
    (180, loc.notifEvery3h),
  ];
  return showModalBottomSheet<int>(
    context: context,
    builder: (ctx) {
      final tc = ThemeColors.of(ctx);
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Text(
              loc.notifWaterInterval,
              style: GoogleFonts.notoSerif(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: tc.text,
              ),
            ),
            const SizedBox(height: 8),
            for (final (minutes, label) in options)
              ListTile(
                title: Text(
                  label,
                  style: TextStyle(
                    fontWeight: minutes == current
                        ? FontWeight.w800
                        : FontWeight.w500,
                    color: minutes == current ? tc.greenDark : tc.text,
                  ),
                ),
                trailing: minutes == current
                    ? Icon(Icons.check_circle, color: tc.green)
                    : null,
                onTap: () => Navigator.pop(ctx, minutes),
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
