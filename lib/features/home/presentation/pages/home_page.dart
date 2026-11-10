import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/services/auth_service.dart';
import 'package:lumina/core/services/daily_tracker.dart';
import 'package:lumina/core/services/health_sync_service.dart';
import 'package:lumina/core/services/user_data_service.dart';
import 'package:lumina/core/services/widget_service.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/logout_flow.dart';
import 'package:lumina/core/widgets/ux_helpers.dart';
import 'package:lumina/features/activity/presentation/pages/activity_page.dart';
import 'package:lumina/features/chat/presentation/pages/ai_chat_page.dart';
import 'package:lumina/features/diary/presentation/pages/diary_page.dart';
import 'package:lumina/features/goal/presentation/pages/goal_page.dart';
import 'package:lumina/features/history/presentation/pages/activity_history_page.dart';
import 'package:lumina/features/home/presentation/widgets/home_ai_banner.dart';
import 'package:lumina/features/home/presentation/widgets/home_calorie_ring_card.dart';
import 'package:lumina/features/home/presentation/widgets/home_diary_card.dart';
import 'package:lumina/features/home/presentation/widgets/home_drawer.dart';
import 'package:lumina/features/home/presentation/widgets/home_header.dart';
import 'package:lumina/features/home/presentation/widgets/home_stat_tile.dart';
import 'package:lumina/features/meal_plan/presentation/pages/meal_plan_page.dart';
import 'package:lumina/features/notifications/presentation/pages/notifications_page.dart';
import 'package:lumina/features/onboarding/presentation/widgets/calculation_step.dart'
    show lastAiPlan;
import 'package:lumina/features/profile/domain/services/subscription_service.dart';
import 'package:lumina/features/settings/presentation/pages/settings_page.dart';
import 'package:lumina/features/support/presentation/pages/support_page.dart';
import 'package:lumina/features/water/presentation/pages/water_page.dart';
import 'package:lumina/features/weight/presentation/pages/weight_page.dart';
import 'package:lumina/features/workout/presentation/pages/workout_page.dart';
import 'package:lumina/l10n/app_localizations.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DailyTracker _tracker = DailyTracker();
  final UserDataService _userData = UserDataService();
  final HealthSyncService _health = HealthSyncService();

  bool _isLoading = true;
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      // Экран открыт в полночь: счётчики дня обнуляются без перезапуска.
      unawaited(_tracker.refreshIfDayChanged());
      if (_tracker.lastUpdated != null) setState(() {});
    });
    _loadData();
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await _userData.loadAll();
    if (_userData.profile != null) {
      _tracker.loadGoalsFromProfile();
    } else {
      _tracker.loadGoalsFromAiPlan(lastAiPlan);
    }
    await _tracker.loadToday();

    try {
      final authorized = await _health.checkAuth();
      if (authorized) {
        await _health.syncToday();
      }
    } catch (e) {
      debugPrint('Health Connect skip: $e');
    }

    WidgetService().updateAll();
    if (mounted) setState(() => _isLoading = false);
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    final loc = AppLocalizations.of(context)!;
    if (hour < 5) return loc.greetingNight;
    if (hour < 12) return loc.greetingMorning;
    if (hour < 18) return loc.greetingAfternoon;
    return loc.greetingEvening;
  }

  /// Подсказка под приветствием — зависит от времени суток,
  /// а не только от прогресса за день.
  String _dailyTip(double progress, int consumed, int goal, int remaining) {
    final loc = AppLocalizations.of(context)!;
    if (progress > 0.8) return loc.dailyTipOver80(remaining);
    if (progress >= 0.3) return loc.dailyTipBetween30(consumed, goal);
    final hour = DateTime.now().hour;
    if (hour < 5) return loc.dailyTipLateNight;
    if (hour < 11) return loc.dailyTipBreakfast;
    if (hour < 16) return loc.dailyTipLunch;
    if (hour < 21) return loc.dailyTipDinner;
    return loc.dailyTipSnack;
  }

  String _displayName() =>
      _userData.profile?.displayName ??
      AuthService().displayName ??
      AppLocalizations.of(context)!.guest;

  void _open(Widget page) {
    hapticTap();
    Navigator.push(context, smoothPageRoute(page));
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    return Scaffold(
      backgroundColor: tc.background,
      drawer: _buildDrawer(context),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: tc.primary,
          backgroundColor: tc.card,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _isLoading ? _buildLoading(tc) : _buildContent(tc),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading(ThemeColors tc) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.7,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: tc.primary),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.loadingData,
              style: TextStyle(
                color: tc.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ThemeColors tc) {
    final loc = AppLocalizations.of(context)!;
    final consumed = _tracker.totalCalories;
    final goal = _tracker.goalCalories;
    final remaining = _tracker.remainingCalories;
    final progress = _tracker.calorieProgress;
    final firstName = _displayName().trim().split(' ').first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Builder(
          builder: (context) => HomeHeader(
            onOpenDrawer: () => Scaffold.of(context).openDrawer(),
            onOpenNotifications: () => _open(const NotificationsPage()),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          '${_greeting()}, $firstName!',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: tc.text,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _dailyTip(progress, consumed, goal, remaining),
          style: TextStyle(
            fontSize: 12,
            color: tc.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 24),
        HomeCalorieRingCard(
          remaining: remaining,
          goal: goal,
          progress: progress,
          macros: [
            HomeMacroValue(
              label: loc.protein,
              total: _tracker.totalProtein,
              goal: _tracker.goalProtein,
            ),
            HomeMacroValue(
              label: loc.fat,
              total: _tracker.totalFat,
              goal: _tracker.goalFat,
            ),
            HomeMacroValue(
              label: loc.carbs,
              total: _tracker.totalCarbs,
              goal: _tracker.goalCarbs,
            ),
          ],
        ),
        const SizedBox(height: 24),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.3,
          children: [
            HomeStatTile(
              label: loc.steps,
              value: _tracker.totalSteps > 0 ? '${_tracker.totalSteps}' : '—',
              icon: Icons.directions_run,
              color: Colors.orange,
              onTap: () => _open(const ActivityPage()),
            ),
            HomeStatTile(
              label: loc.water,
              value: _formatWater(_tracker.totalWaterMl),
              icon: Icons.water_drop,
              color: const Color(0xFF5EB5FF),
              onTap: () => _open(const WaterPage()),
            ),
            HomeStatTile(
              label: loc.weight,
              value: _userData.latestWeight != null
                  ? _userData.latestWeight!.toStringAsFixed(1)
                  : '—',
              icon: Icons.monitor_weight_outlined,
              color: const Color(0xFFC78BFF),
              onTap: () => _open(const WeightPage()),
            ),
            HomeStatTile(
              label: loc.goal,
              value: '${(progress * 100).clamp(0, 100).toInt()}%',
              icon: Icons.flag_rounded,
              color: tc.green,
              onTap: () => _open(const GoalPage()),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Text(
          loc.todayEaten,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: tc.text,
          ),
        ),
        const SizedBox(height: 16),
        HomeDiaryCard(
          consumed: consumed,
          goal: goal,
          protein: _tracker.totalProtein,
          onTap: () => _open(const DiaryPage()),
        ),
        const SizedBox(height: 24),
        HomeAiBanner(onTap: () => _open(const AiChatPage())),
        const SizedBox(height: 100),
      ],
    );
  }

  String _formatWater(int ml) {
    if (ml <= 0) return '—';
    final loc = AppLocalizations.of(context)!;
    return ml >= 1000
        ? loc.litersValue((ml / 1000).toStringAsFixed(1))
        : loc.mlValue(ml);
  }

  // ─────────────────────────────────────────────
  // Боковое меню
  // ─────────────────────────────────────────────

  Widget _buildDrawer(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return HomeDrawer(
      fullName: _displayName(),
      isPremium: SubscriptionService.instance.state.isPremium,
      onLogout: () => confirmAndSignOut(context),
      entries: [
        HomeDrawerEntry(
          icon: Icons.fitness_center_rounded,
          label: loc.drawerWorkouts,
          onTap: () => _open(const WorkoutPage()),
        ),
        HomeDrawerEntry(
          icon: Icons.auto_awesome_outlined,
          label: loc.drawerMyGoals,
          onTap: () => _open(const GoalPage()),
        ),
        HomeDrawerEntry(
          icon: Icons.restaurant_menu_outlined,
          label: loc.drawerMealPlan,
          onTap: () => _open(const MealPlanPage()),
        ),
        HomeDrawerEntry(
          icon: Icons.history_rounded,
          label: loc.drawerActivityHistory,
          onTap: () => _open(const ActivityHistoryPage()),
        ),
        HomeDrawerEntry(
          icon: Icons.settings_outlined,
          label: loc.drawerSettings,
          onTap: () => _open(const SettingsPage()),
        ),
        HomeDrawerEntry(
          icon: Icons.help_outline_rounded,
          label: loc.drawerSupport,
          onTap: () => _open(const SupportPage()),
        ),
      ],
    );
  }
}
