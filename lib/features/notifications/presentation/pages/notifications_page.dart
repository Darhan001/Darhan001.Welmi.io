import 'package:flutter/material.dart';
import 'package:lumina/core/services/daily_tracker.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/app_app_bar.dart';
import 'package:lumina/core/widgets/app_button.dart';
import 'package:lumina/core/widgets/app_card.dart';
import 'package:lumina/core/widgets/app_states.dart';
import 'package:lumina/core/widgets/app_snackbar.dart';
import 'package:lumina/core/widgets/ux_helpers.dart';
import 'package:lumina/features/notifications/presentation/pages/notification_settings_page.dart';
import 'package:lumina/features/notifications/presentation/view_models/reminder_schedule.dart';
import 'package:lumina/features/notifications/presentation/widgets/reminder_card.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:lumina/core/services/notifications/notification_service.dart';
import 'package:lumina/core/services/notifications/notification_settings.dart';

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

  bool _clearing = false;

  Future<void> _clearDelivered() async {
    if (_clearing) return;
    final loc = AppLocalizations.of(context)!;
    hapticTap();
    setState(() => _clearing = true);
    final tracker = DailyTracker();
    final waterReached =
        tracker.goalWaterMl > 0 && tracker.totalWaterMl >= tracker.goalWaterMl;
    try {
      await _service.clearDelivered(waterGoalReached: waterReached);
      if (mounted) AppSnackbar.success(context, loc.notifClearedDelivered);
    } catch (e) {
      debugPrint('⚠️ Clear notifications error: $e');
      if (mounted) AppSnackbar.error(context, loc.saveError);
    } finally {
      if (mounted) setState(() => _clearing = false);
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
                    icon: Icons.clear_all_rounded,
                    tooltip: loc.notifClearDelivered,
                    onTap: _clearing ? null : _clearDelivered,
                  ),
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
                child: ReminderCard(
                  reminder: reminders[i],
                  onTap: _openSettings,
                ),
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
}
