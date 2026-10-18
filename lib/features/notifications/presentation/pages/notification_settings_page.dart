import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/services/daily_tracker.dart';
import 'package:lumina/core/theme/theme_provider.dart';
import 'package:lumina/core/widgets/ux_helpers.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:lumina/services/notification_service.dart';

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
        await _service.setMasterEnabled(
          value,
          waterGoalReached: _waterGoalReached,
        );
        await _load();
        if (mounted) {
          showWelmiSnackbar(
            context,
            value
                ? AppLocalizations.of(context)!.notificationsEnabled
                : AppLocalizations.of(context)!.notificationsDisabled,
            icon: value
                ? Icons.notifications_active
                : Icons.notifications_off,
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
    await _guard(() => _service.setReminderTime(id, picked.hour, picked.minute));
    await _load();
  }

  Future<void> _pickWaterInterval(int current) async {
    const options = [30, 60, 90, 120, 180];
    final labels = [
      AppLocalizations.of(context)!.notifEvery30Min,
      AppLocalizations.of(context)!.notifEvery1h,
      AppLocalizations.of(context)!.notifEvery90Min,
      AppLocalizations.of(context)!.notifEvery2h,
      AppLocalizations.of(context)!.notifEvery3h,
    ];
    final picked = await showModalBottomSheet<int>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.notifWaterInterval,
              style: GoogleFonts.notoSerif(
                  fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            ...List.generate(options.length, (i) {
              final selected = options[i] == current;
              return ListTile(
                title: Text(labels[i],
                    style: TextStyle(
                      fontWeight:
                          selected ? FontWeight.w800 : FontWeight.w500,
                      color: selected ? const Color(0xFF4A8C5C) : null,
                    )),
                trailing: selected
                    ? const Icon(Icons.check_circle,
                        color: Color(0xFF75A47F))
                    : null,
                onTap: () => Navigator.pop(ctx, options[i]),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked == null) return;
    await _guard(
        () => _service.setWaterInterval(picked, waterGoalReached: _waterGoalReached));
    await _load();
  }

  Future<void> _showTestNotification() => _guard(() async {
        if (!(await _ensurePermission())) {
          if (mounted) {
            showWelmiSnackbar(
              context,
              AppLocalizations.of(context)!.notifPermissionDenied,
              icon: Icons.notifications_off_outlined,
            );
          }
          return;
        }
        await _service.showTestNotification();
        if (mounted) {
          showWelmiSnackbar(
            context,
            AppLocalizations.of(context)!.notifTestSent,
            icon: Icons.send_rounded,
          );
        }
      });

  // ─── UI ───

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeProvider.isDark(context);
    final s = _settings;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF9F7F2),
      body: SafeArea(
        child: s == null
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        _buildHeader(isDark),
                        const SizedBox(height: 20),

                        if (!_permissionGranted) _buildPermissionBanner(isDark),
                        if (!_permissionGranted) const SizedBox(height: 16),

                        // Главный переключатель
                        _buildSwitchTile(
                          icon: Icons.notifications_outlined,
                          title: AppLocalizations.of(context)!.notificationsTitle,
                          subtitle:
                              AppLocalizations.of(context)!.notifMasterSubtitle,
                          value: s.masterEnabled,
                          isDark: isDark,
                          onChanged: _toggleMaster,
                        ),
                        const SizedBox(height: 24),

                        // Список напоминаний (виден при включённых уведомлениях)
                        if (s.masterEnabled) ...[
                          _buildSectionTitle(
                              AppLocalizations.of(context)!.notifReminders,
                              isDark),
                          const SizedBox(height: 12),
                          _buildWaterTile(s, isDark),
                          _buildSwitchTile(
                            icon: Icons.restaurant_outlined,
                            title: AppLocalizations.of(context)!.breakfast,
                            value: s.breakfastEnabled,
                            isDark: isDark,
                            indent: true,
                            trailingTime: s.breakfastTime,
                            onTimeTap: () => _pickTime(
                                NotificationService.idBreakfast,
                                s.breakfastTime),
                            onChanged: (v) =>
                                _toggleOther(NotificationService.idBreakfast, v),
                          ),
                          _buildSwitchTile(
                            icon: Icons.lunch_dining_outlined,
                            title: AppLocalizations.of(context)!.lunch,
                            value: s.lunchEnabled,
                            isDark: isDark,
                            indent: true,
                            trailingTime: s.lunchTime,
                            onTimeTap: () => _pickTime(
                                NotificationService.idLunch, s.lunchTime),
                            onChanged: (v) =>
                                _toggleOther(NotificationService.idLunch, v),
                          ),
                          _buildSwitchTile(
                            icon: Icons.dinner_dining_outlined,
                            title: AppLocalizations.of(context)!.dinner,
                            value: s.dinnerEnabled,
                            isDark: isDark,
                            indent: true,
                            trailingTime: s.dinnerTime,
                            onTimeTap: () => _pickTime(
                                NotificationService.idDinner, s.dinnerTime),
                            onChanged: (v) =>
                                _toggleOther(NotificationService.idDinner, v),
                          ),
                          _buildSwitchTile(
                            icon: Icons.directions_run_outlined,
                            title: AppLocalizations.of(context)!.activityLog,
                            value: s.activityEnabled,
                            isDark: isDark,
                            indent: true,
                            trailingTime: s.activityTime,
                            onTimeTap: () => _pickTime(
                                NotificationService.idActivity, s.activityTime),
                            onChanged: (v) =>
                                _toggleOther(NotificationService.idActivity, v),
                          ),
                          _buildSwitchTile(
                            icon: Icons.nights_stay_outlined,
                            title: AppLocalizations.of(context)!.notifEvening,
                            value: s.eveningEnabled,
                            isDark: isDark,
                            indent: true,
                            trailingTime: s.eveningTime,
                            onTimeTap: () => _pickTime(
                                NotificationService.idEvening, s.eveningTime),
                            onChanged: (v) =>
                                _toggleOther(NotificationService.idEvening, v),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Тестовое уведомление
                        _buildTestButton(isDark),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                  if (_busy)
                    Container(
                      color: Colors.black12,
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.black),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(Icons.arrow_back,
                size: 22, color: isDark ? Colors.white : Colors.black),
          ),
        ),
        Text(
          AppLocalizations.of(context)!.notificationsTitle,
          style: GoogleFonts.notoSerif(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(width: 42),
      ],
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.inter(
        fontWeight: FontWeight.w900,
        fontSize: 12,
        color: isDark ? Colors.white38 : Colors.black.withValues(alpha: 0.35),
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildPermissionBanner(bool isDark) {
    return GestureDetector(
      onTap: () async {
        final granted = await _ensurePermission();
        if (granted && mounted) {
          showWelmiSnackbar(context,
              AppLocalizations.of(context)!.notifPermissionGranted,
              icon: Icons.check_circle);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4E0),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF0C36A), width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                size: 22, color: Color(0xFFB8860B)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.notifPermissionBanner,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF8A6508),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaterTile(NotificationSettings s, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            icon: Icons.local_drink_outlined,
            title: AppLocalizations.of(context)!.waterReminders,
            subtitle: AppLocalizations.of(context)!.waterRemindersSubtitle,
            value: s.waterEnabled,
            isDark: isDark,
            onChanged: _toggleWater,
          ),
          if (s.waterEnabled)
            Padding(
              padding: const EdgeInsets.only(left: 52, right: 16, bottom: 12),
              child: GestureDetector(
                onTap: () => _pickWaterInterval(s.waterIntervalMin),
                child: Row(
                  children: [
                    Icon(Icons.timer_outlined,
                        size: 18,
                        color: isDark ? Colors.white38 : Colors.black38),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.notifWaterInterval,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F3E5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        s.waterIntervalLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF4A8C5C),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
    bool indent = false,
    TimeOfDay? trailingTime,
    VoidCallback? onTimeTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.only(
        left: indent ? 52 : 16,
        right: 8,
        top: 10,
        bottom: 10,
      ),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (!indent) ...[
            Icon(icon, size: 22, color: isDark ? Colors.white70 : Colors.black54),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black,
                    )),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark ? Colors.white38 : Colors.black38,
                        fontWeight: FontWeight.w500,
                      )),
                ],
              ],
            ),
          ),
          if (trailingTime != null)
            GestureDetector(
              onTap: onTimeTap,
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F3E5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  trailingTime.format(context),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF4A8C5C),
                  ),
                ),
              ),
            ),
          Switch(
            value: value,
            onChanged: (v) {
              hapticTap();
              onChanged(v);
            },
            activeThumbColor: const Color(0xFF75A47F),
            inactiveThumbColor:
                isDark ? Colors.grey.shade700 : Colors.grey.shade300,
            inactiveTrackColor: isDark ? Colors.white10 : Colors.grey.shade100,
          ),
        ],
      ),
    );
  }

  Widget _buildTestButton(bool isDark) {
    return GestureDetector(
      onTap: _showTestNotification,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF75A47F).withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.send_rounded, size: 20, color: Color(0xFF75A47F)),
            const SizedBox(width: 10),
            Text(
              AppLocalizations.of(context)!.notifTestButton,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF4A8C5C),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
