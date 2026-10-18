import 'package:flutter/material.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/app_app_bar.dart';
import 'package:lumina/core/widgets/app_button.dart';
import 'package:lumina/core/widgets/app_card.dart';
import 'package:lumina/core/widgets/app_states.dart';
import 'package:lumina/core/widgets/app_snackbar.dart';
import 'package:lumina/core/widgets/ux_helpers.dart';
import 'package:lumina/features/notifications/presentation/pages/notification_settings_page.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:lumina/services/notification_service.dart';

/// Экран «Уведомления»: реальное расписание напоминаний на день.
///
/// Раньше здесь был захардкоженный список «входящих» с выдуманными
/// событиями. История доставленных локальных уведомлений системой не
/// хранится, поэтому экран показывает то, что действительно запланировано:
/// включённые напоминания и их время, а также статус разрешения.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationService _service = NotificationService();

  NotificationSettings? _settings;
  bool _permissionGranted = true;
  bool _loading = true;
  bool _requesting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _service.initialize();
    final settings = await _service.getSettings();
    final granted = await _service.checkPermissions();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _permissionGranted = granted;
      _loading = false;
    });
  }

  Future<void> _requestPermission() async {
    if (_requesting) return;
    final loc = AppLocalizations.of(context)!;
    setState(() => _requesting = true);
    final granted = await _service.requestPermissions();
    if (granted) await _service.rescheduleAll();
    if (!mounted) return;
    setState(() {
      _permissionGranted = granted;
      _requesting = false;
    });
    if (granted) {
      AppSnackbar.success(context, loc.notifPermissionGranted);
    } else {
      AppSnackbar.error(context, loc.notifPermissionDenied);
    }
  }

  Future<void> _openSettings() async {
    hapticTap();
    await Navigator.push(
      context,
      smoothPageRoute(const NotificationSettingsPage()),
    );
    // Пользователь мог изменить расписание — показываем актуальное.
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: tc.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: AppAppBar(
                title: loc.notificationsPageTitle,
                actions: [
                  AppBarActionButton(
                    icon: Icons.tune_rounded,
                    tooltip: loc.notifOpenSettings,
                    onTap: _openSettings,
                  ),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _loading
                    ? const AppLoading(key: ValueKey('loading'))
                    : _buildContent(tc, loc),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ThemeColors tc, AppLocalizations loc) {
    final settings = _settings!;
    if (!settings.masterEnabled) {
      return AppEmptyState(
        key: const ValueKey('off'),
        icon: Icons.notifications_off_outlined,
        title: loc.notificationsDisabled,
        subtitle: loc.notifTurnOnHint,
        actionLabel: loc.notifOpenSettings,
        onAction: _openSettings,
      );
    }

    final reminders = buildReminderSchedule(
      settings,
      loc,
      (minutes) =>
          TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60).format(context),
    );

    return ListView(
      key: const ValueKey('list'),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        if (!_permissionGranted) ...[
          FadeSlideIn(child: _buildPermissionBanner(tc, loc)),
          const SizedBox(height: 16),
        ],
        if (reminders.isEmpty)
          AppEmptyState(
            icon: Icons.notifications_paused_outlined,
            title: loc.notifNoReminders,
            subtitle: loc.notifScheduleHint,
            actionLabel: loc.notifOpenSettings,
            onAction: _openSettings,
          )
        else ...[
          Text(
            loc.notifReminders,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: tc.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            loc.notifScheduleHint,
            style: TextStyle(fontSize: 12, color: tc.textSecondary),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < reminders.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FadeSlideIn(
                index: i,
                child: _buildReminderTile(tc, reminders[i]),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildPermissionBanner(ThemeColors tc, AppLocalizations loc) {
    return AppCard(
      color: tc.errorBg,
      shadow: false,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_active_outlined, color: tc.error),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  loc.notifPermissionBanner,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: tc.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppButton(
            text: loc.notifOpenSettings,
            icon: Icons.check_rounded,
            loading: _requesting,
            onPressed: _requestPermission,
          ),
        ],
      ),
    );
  }

  Widget _buildReminderTile(ThemeColors tc, ScheduledReminder reminder) {
    return AppCard(
      onTap: _openSettings,
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
@visibleForTesting
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
            '${_waterIntervalLabel(s, loc)} · ${formatTime(s.waterStartMin)}–${formatTime(s.waterEndMin)}',
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

String _waterIntervalLabel(NotificationSettings s, AppLocalizations loc) {
  return switch (s.waterIntervalMin) {
    30 => loc.notifEvery30Min,
    60 => loc.notifEvery1h,
    90 => loc.notifEvery90Min,
    120 => loc.notifEvery2h,
    180 => loc.notifEvery3h,
    _ => s.waterIntervalLabel,
  };
}
