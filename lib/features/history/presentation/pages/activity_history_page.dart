import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lumina/core/models/supabase_models.dart';
import 'package:lumina/core/services/auth_service.dart';
import 'package:lumina/core/services/daily_tracker.dart';
import 'package:lumina/core/services/supabase_service.dart';
import 'package:lumina/core/services/units_service.dart';
import 'package:lumina/core/services/widget_service.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/app_app_bar.dart';
import 'package:lumina/core/widgets/app_states.dart';
import 'package:lumina/core/widgets/units_format.dart';
import 'package:lumina/core/widgets/ux_helpers.dart';
import 'package:lumina/features/history/data/history_repository.dart';
import 'package:lumina/features/history/domain/day_activity.dart';
import 'package:lumina/features/history/presentation/widgets/activity_draft_sheet.dart';
import 'package:lumina/features/history/presentation/widgets/exercise_draft_sheet.dart';
import 'package:lumina/features/history/presentation/widgets/history_day_card.dart';
import 'package:lumina/features/history/presentation/widgets/history_design.dart';
import 'package:lumina/features/history/presentation/widgets/history_sheets.dart';
import 'package:lumina/l10n/app_localizations.dart';

class ActivityHistoryPage extends StatefulWidget {
  const ActivityHistoryPage({super.key});

  @override
  State<ActivityHistoryPage> createState() => _ActivityHistoryPageState();
}

class _ActivityHistoryPageState extends State<ActivityHistoryPage> {
  final HistoryRepository _repository = HistoryRepository();
  final DailyTracker _tracker = DailyTracker();

  List<DayActivity> _days = [];
  List<ActivityLog> _logs30 = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final loc = AppLocalizations.of(context)!;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final userId = AuthService().userId;
    if (userId == null) {
      setState(() {
        _isLoading = false;
        _error = loc.loginToViewHistory;
      });
      return;
    }

    try {
      final data = await _repository.load(userId);
      if (!mounted) return;
      setState(() {
        _days = data.days;
        _logs30 = data.logs30;
        _isLoading = false;
      });
    } catch (e) {
      // Текст исключения — в лог, пользователю — понятное сообщение.
      debugPrint('⚠️ History load error: $e');
      if (!mounted) return;
      setState(() {
        _error = loc.historyLoadError;
        _isLoading = false;
      });
    }
  }

  // ─── Форматирование ───

  String _compact(int n) => NumberFormat.compact(
    locale: AppLocalizations.of(context)!.localeName,
  ).format(n);

  String _formatDate(DateTime date, AppLocalizations loc) {
    final now = DateTime.now();
    final diff = DateTime(
      now.year,
      now.month,
      now.day,
    ).difference(DateTime(date.year, date.month, date.day)).inDays;
    if (diff == 0) return loc.today;
    if (diff == 1) return loc.yesterday;
    return DateFormat('d MMM', loc.localeName).format(date);
  }

  // ─── Запись данных ───

  Future<void> _showAddSheet() => showHistoryAddSheet(
    context,
    onActivity: _logActivity,
    onWater: _logWater,
    onExercise: _logExercise,
  );

  Future<void> _logActivity() async {
    final draft = await showActivityDraftSheet(context);
    if (draft == null || !mounted) return;
    final loc = AppLocalizations.of(context)!;
    final userId = AuthService().userId;
    if (userId == null) {
      showWelmiSnackbar(context, loc.signInRequired, icon: Icons.login);
      return;
    }

    final distance = UnitsService.instance.distanceFromDisplay(
      draft.distanceDisplay,
    );
    try {
      await SupabaseService().saveActivityLog(
        ActivityLog(
          userId: userId,
          date: DateTime.now(),
          steps: draft.steps,
          caloriesBurned: draft.steps > 0 ? draft.steps * 0.045 : null,
          activeMinutes: draft.minutes > 0 ? draft.minutes.toDouble() : null,
          distanceKm: distance > 0 ? distance : null,
        ),
      );
    } catch (e) {
      // Раньше сбой сети здесь был необработанным исключением без ответа.
      debugPrint('⚠️ Save activity error: $e');
      if (mounted) {
        showWelmiSnackbar(context, loc.saveError, icon: Icons.error_outline);
      }
      return;
    }
    await _tracker.loadToday();
    WidgetService().updateAll();
    if (!mounted) return;
    hapticSuccess();
    showWelmiSnackbar(context, loc.activitySaved, icon: Icons.check_circle);
    _loadHistory();
  }

  Future<void> _logWater() async {
    final todayMl = _days.isNotEmpty ? _days.first.waterMl : 0;
    final ml = await showWaterAmountSheet(context, todayMl: todayMl);
    if (ml == null || !mounted) return;
    final loc = AppLocalizations.of(context)!;

    await _tracker.addWater(ml);
    WidgetService().updateAll();
    if (!mounted) return;
    hapticSuccess();
    showWelmiSnackbar(
      context,
      loc.waterAddedMl(ml),
      icon: Icons.water_drop_rounded,
    );
    _loadHistory();
  }

  Future<void> _logExercise() async {
    final draft = await showExerciseDraftSheet(context);
    final userId = AuthService().userId;
    if (draft == null || userId == null || !mounted) return;
    final loc = AppLocalizations.of(context)!;

    await _repository.addExercise(
      userId,
      name: draft.name,
      sets: draft.sets,
      reps: draft.reps,
    );
    if (!mounted) return;
    hapticSuccess();
    showWelmiSnackbar(
      context,
      loc.exerciseAddedToHistory(draft.name),
      icon: Icons.fitness_center_rounded,
    );
    _loadHistory();
  }

  // ─── UI ───

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
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: AppAppBar(
                title: loc.historyTitle,
                actions: [
                  AppBarActionButton(
                    icon: Icons.refresh_rounded,
                    tooltip: loc.refresh,
                    onTap: _isLoading ? null : _loadHistory,
                  ),
                  AppBarActionButton(
                    icon: Icons.add_rounded,
                    color: HistoryDesign.greenDark,
                    tooltip: loc.historyLogButton,
                    onTap: _showAddSheet,
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBody(tc, loc)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ThemeColors tc, AppLocalizations loc) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              loc.loadingHistory,
              style: TextStyle(
                color: tc.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
    if (_error != null && _days.isEmpty) {
      return AppErrorState(message: _error!, onRetry: _loadHistory);
    }

    final activeDays = _days.where((d) => d.isActive).toList();
    final totalSteps = _logs30.fold<int>(0, (sum, log) => sum + log.steps);
    final totalWater = _days.fold<int>(0, (sum, d) => sum + d.waterMl);
    final todayKey = DateUtils.dateOnly(DateTime.now());

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      children: [
        HistorySummaryCard(
          steps: _compact(totalSteps),
          waterLiters: (totalWater / 1000).toStringAsFixed(1),
          activeDays: activeDays.length,
        ),
        const SizedBox(height: 24),
        if (activeDays.isEmpty)
          AppEmptyState(
            icon: Icons.monitor_heart_outlined,
            title: loc.historyEmptyTitle,
            subtitle: loc.historyEmptySubtitle,
            actionLabel: loc.historyLogButton,
            onAction: _showAddSheet,
          )
        else ...[
          Text(
            loc.historyRecentDays,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: tc.text,
            ),
          ),
          const SizedBox(height: 16),
          for (final day in activeDays)
            HistoryDayCard(
              dateLabel: _formatDate(day.date, loc),
              isToday: DateUtils.isSameDay(day.date, todayKey),
              stepsLabel: day.steps > 0 ? _compact(day.steps) : null,
              waterMl: day.waterMl,
              calories: day.calories,
              minutes: day.minutes,
              distanceLabel: day.distanceKm > 0
                  ? loc.distanceValue(day.distanceKm)
                  : null,
              distanceUnit: loc.distanceUnitLabel,
              exercises: day.exercises,
            ),
        ],
      ],
    );
  }
}
