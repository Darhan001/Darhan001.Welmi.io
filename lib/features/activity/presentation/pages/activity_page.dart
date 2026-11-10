import 'package:flutter/material.dart';
import 'package:lumina/core/models/supabase_models.dart';
import 'package:lumina/core/services/auth_service.dart';
import 'package:lumina/core/services/health_sync_service.dart';
import 'package:lumina/core/services/supabase_service.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/app_app_bar.dart';
import 'package:lumina/core/widgets/app_states.dart';
import 'package:lumina/core/widgets/ux_helpers.dart';
import 'package:lumina/features/activity/presentation/widgets/activity_info_cards.dart';
import 'package:lumina/features/activity/presentation/widgets/activity_steps_card.dart';
import 'package:lumina/features/activity/presentation/widgets/activity_tip_card.dart';
import 'package:lumina/features/activity/presentation/widgets/log_activity_sheet.dart';
import 'package:lumina/l10n/app_localizations.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  static const int _stepGoal = 10000;

  final SupabaseService _supabase = SupabaseService();

  bool _isLoading = true;
  bool _loadFailed = false;
  bool _syncing = false;

  /// Растёт при каждом обновлении — перезапускает анимацию кольца.
  int _revision = 0;
  ActivityLog? _today;

  @override
  void initState() {
    super.initState();
    _loadTodayActivity();
  }

  Future<void> _loadTodayActivity() async {
    setState(() {
      _isLoading = true;
      _loadFailed = false;
    });
    final userId = AuthService().userId;
    ActivityLog? today;
    var failed = false;

    if (userId != null) {
      try {
        final now = DateTime.now();
        final logs = await _supabase.getActivityLogs(
          userId,
          from: now.subtract(const Duration(days: 1)),
        );
        today = logs
            .where(
              (log) =>
                  log.date.year == now.year &&
                  log.date.month == now.month &&
                  log.date.day == now.day,
            )
            .firstOrNull;
      } catch (e) {
        // Раньше ошибка молча превращалась в нули — показываем её явно.
        debugPrint('⚠️ Activity load error: $e');
        failed = true;
      }
    }

    if (!mounted) return;
    setState(() {
      _today = today;
      _loadFailed = failed;
      _isLoading = false;
      _revision++;
    });
  }

  /// Синхронизация с Google Fit / Apple Health
  Future<void> _syncFromHealth() async {
    if (_syncing) return;
    final loc = AppLocalizations.of(context)!;
    setState(() => _syncing = true);
    final health = HealthSyncService();

    void report(String message, IconData icon, {bool install = false}) {
      if (!mounted) return;
      setState(() => _syncing = false);
      showWelmiSnackbar(
        context,
        message,
        icon: icon,
        actionLabel: install ? loc.healthInstall : null,
        onAction: install ? health.installHealthConnect : null,
      );
    }

    // На Android нужен установленный Health Connect (Google Fit).
    if (!await health.isHealthConnectAvailable()) {
      return report(
        loc.healthInstallHint,
        Icons.monitor_heart_outlined,
        install: true,
      );
    }
    if (!await health.requestAuthorization()) {
      return report(loc.healthNoAccess, Icons.lock_outline);
    }

    final result = await health.syncToday();
    if (!mounted) return;
    switch (result.status) {
      case HealthSyncStatus.success:
        setState(() => _syncing = false);
        await _loadTodayActivity();
        if (!mounted) return;
        hapticSuccess();
        final sleep = result.sleepHours > 0
            ? loc.healthSleepSuffix(result.sleepHours.toStringAsFixed(1))
            : '';
        report(
          '${loc.healthSynced(result.steps, result.calories)}$sleep',
          Icons.check_circle,
        );
      case HealthSyncStatus.notAuthorized:
        report(loc.healthNotAuthorized, Icons.lock_outline);
      case HealthSyncStatus.unsupported:
        report(loc.healthUnsupported, Icons.smartphone);
      case HealthSyncStatus.healthConnectMissing:
        report(
          loc.healthInstallHint,
          Icons.monitor_heart_outlined,
          install: true,
        );
      case HealthSyncStatus.error:
        report(loc.healthError, Icons.error_outline);
    }
  }

  Future<void> _logActivity() async {
    final today = _today;
    final saved = await LogActivitySheet.show(
      context,
      steps: today?.steps ?? 0,
      minutes: today?.activeMinutes ?? 0,
      distanceKm: today?.distanceKm ?? 0,
    );
    if (saved != true || !mounted) return;
    final loc = AppLocalizations.of(context)!;
    await _loadTodayActivity();
    if (!mounted) return;
    showWelmiSnackbar(context, loc.activitySaved, icon: Icons.check_circle);
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final loc = AppLocalizations.of(context)!;
    final today = _today;
    final steps = today?.steps ?? 0;

    final Widget body;
    if (_isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_loadFailed) {
      body = AppErrorState(
        message: loc.activityLoadError,
        onRetry: _loadTodayActivity,
      );
    } else {
      body = SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 24),
            ActivityStepsCard(
              key: ValueKey(_revision),
              steps: steps,
              goal: _stepGoal,
              distanceKm: today?.distanceKm ?? 0,
              calories: today?.caloriesBurned ?? 0,
              minutes: today?.activeMinutes ?? 0,
            ),
            const SizedBox(height: 24),
            ActivityStatsRow(steps: steps, goal: _stepGoal),
            const SizedBox(height: 24),
            HealthSyncCard(syncing: _syncing, onSync: _syncFromHealth),
            const SizedBox(height: 24),
            ActivityTipCard(steps: steps),
            const SizedBox(height: 100),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: tc.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: AppAppBar(
                title: loc.activityLog,
                actions: [
                  AppBarActionButton(
                    icon: Icons.add,
                    color: tc.text,
                    tooltip: loc.logActivity,
                    onTap: _isLoading ? null : _logActivity,
                  ),
                ],
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}
