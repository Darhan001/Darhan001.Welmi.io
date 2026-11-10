import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lumina/core/services/daily_tracker.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/app_app_bar.dart';
import 'package:lumina/core/widgets/app_button.dart';
import 'package:lumina/core/widgets/ux_helpers.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:lumina/core/services/notifications/notification_service.dart';
import 'package:lumina/core/services/notifications/notification_settings.dart';
import 'package:lumina/features/notifications/presentation/widgets/notification_tiles.dart';
import 'package:lumina/features/notifications/presentation/widgets/reminders_section.dart';
import 'package:lumina/features/notifications/presentation/widgets/water_reminder_tile.dart';

/// ============================================================
/// Настройки → Уведомления (локальные уведомления Welmi).
/// ============================================================
///
/// Все настройки сохраняются локально через NotificationService
/// (SharedPreferences). Главный переключатель:
///  - OFF → отменяет все уведомления Welmi;
///  - ON  → восстанавливает расписание из сохранённых настроек.
class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  final NotificationService _service = NotificationService();
  final DailyTracker _tracker = DailyTracker();

  NotificationSettings? _settings;
  bool _permissionGranted = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await _service.getSettings();
    final granted = await _service.checkPermissions();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _permissionGranted = granted;
    });
  }

  Future<bool> _ensurePermission() async {
    // Сначала проверяем разрешение на уведомления.
    if (await _service.checkPermissions()) {
      // Разрешение уже есть — обновляем режим планирования и перепланируем,
      // чтобы уведомления сработали с правильным режимом (exact или inexact).
      await _service.ensureExactAlarmsPermission();
      if (mounted) setState(() => _permissionGranted = true);
      return true;
    }
    // Разрешение ещё не выдано — просим у пользователя.
    final granted = await _service.requestPermissions();
    if (granted) {
      // После получения разрешения обновляем режим и перепланируем напоминания.
      await _service.ensureExactAlarmsPermission();
    }
    if (mounted) setState(() => _permissionGranted = granted);
    return granted;
  }

  /// Достигнута ли дневная цель воды прямо сейчас (для планирования).
  bool get _waterGoalReached {
    final goal = _tracker.goalWaterMl;
    return goal > 0 && _tracker.totalWaterMl >= goal;
  }

  Future<void> _guard(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ─── Действия ───

  Future<void> _toggleMaster(bool value) => _guard(() async {
    if (value && !(await _ensurePermission())) {
      if (mounted) {
        showWelmiSnackbar(
          context,
          AppLocalizations.of(context)!.notifPermissionDenied,
          icon: Icons.notifications_off_outlined,
        );
      }
      return;
    }
    // Разрешение на точные будильники уже запрошено в _ensurePermission().
    await _service.setMasterEnabled(value, waterGoalReached: _waterGoalReached);
    await _load();
    if (mounted) {
      showWelmiSnackbar(
        context,
        value
            ? AppLocalizations.of(context)!.notificationsEnabled
            : AppLocalizations.of(context)!.notificationsDisabled,
        icon: value ? Icons.notifications_active : Icons.notifications_off,
      );
    }
  });

  Future<void> _toggleWater(bool value) => _guard(() async {
    await _service.setReminderEnabled(
      NotificationService.idWater,
      value,
      waterGoalReached: _waterGoalReached,
    );
    await _load();
  });

  Future<void> _toggleOther(int id, bool value) => _guard(() async {
    await _service.setReminderEnabled(id, value);
    await _load();
  });

  Future<void> _pickTime(int id, TimeOfDay current) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
      helpText: AppLocalizations.of(context)!.notifPickTime,
    );
    if (picked == null) return;
    HapticFeedback.selectionClick();
    await _guard(
      () => _service.setReminderTime(id, picked.hour, picked.minute),
    );
    await _load();
  }

  Future<void> _pickWaterInterval(int current) async {
    final picked = await showWaterIntervalSheet(context, current);
    if (picked == null) return;
    await _guard(
      () => _service.setWaterInterval(
        picked,
        waterGoalReached: _waterGoalReached,
      ),
    );
    await _load();
  }

  Future<void> _requestFromBanner() async {
    final granted = await _ensurePermission();
    if (granted && mounted) {
      showWelmiSnackbar(
        context,
        AppLocalizations.of(context)!.notifPermissionGranted,
        icon: Icons.check_circle,
      );
    }
  }

  Future<void> _showTestNotification() => _guard(() async {
    final loc = AppLocalizations.of(context)!;
    if (!(await _ensurePermission())) {
      if (mounted) {
        showWelmiSnackbar(
          context,
          loc.notifPermissionDenied,
          icon: Icons.notifications_off_outlined,
        );
      }
      return;
    }
    await _service.showTestNotification();
    if (mounted) {
      showWelmiSnackbar(context, loc.notifTestSent, icon: Icons.send_rounded);
    }
  });

  // ─── UI ───

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final loc = AppLocalizations.of(context)!;
    final s = _settings;

    return Scaffold(
      backgroundColor: tc.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: AppAppBar(title: loc.notificationsTitle),
            ),
            Expanded(
              child: s == null
                  ? const Center(child: CircularProgressIndicator())
                  : Stack(
                      children: [
                        ListView(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                          children: [
                            if (!_permissionGranted) ...[
                              NotificationPermissionBanner(
                                onTap: _requestFromBanner,
                              ),
                              const SizedBox(height: 16),
                            ],
                            NotificationSwitchTile(
                              icon: Icons.notifications_outlined,
                              title: loc.notificationsTitle,
                              subtitle: loc.notifMasterSubtitle,
                              value: s.masterEnabled,
                              onChanged: _toggleMaster,
                            ),
                            const SizedBox(height: 24),
                            // Список напоминаний (виден при включённых уведомлениях)
                            if (s.masterEnabled) ...[
                              RemindersSection(
                                settings: s,
                                onWaterToggle: _toggleWater,
                                onWaterIntervalTap: () =>
                                    _pickWaterInterval(s.waterIntervalMin),
                                onToggle: _toggleOther,
                                onPickTime: _pickTime,
                              ),
                              const SizedBox(height: 24),
                            ],
                            AppButton(
                              text: loc.notifTestButton,
                              icon: Icons.send_rounded,
                              variant: AppButtonVariant.secondary,
                              onPressed: _busy ? null : _showTestNotification,
                            ),
                          ],
                        ),
                        if (_busy)
                          ColoredBox(
                            color: tc.shadow(0.12),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
