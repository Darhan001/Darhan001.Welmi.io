import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/services/auth_service.dart';
import 'package:lumina/core/services/daily_tracker.dart';
import 'package:lumina/core/services/health_sync_service.dart';
import 'package:lumina/core/services/user_data_service.dart';
import 'package:lumina/core/services/widget_service.dart';
import 'package:lumina/core/theme/app_colors.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/app_skeleton.dart';
import 'package:lumina/core/widgets/logout_flow.dart';
import 'package:lumina/core/widgets/units_format.dart';
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

  /// Индикатор на весь экран — только при первой загрузке. При обновлении
  /// жестом прежние данные остаются на месте (у RefreshIndicator свой
  /// индикатор), а не сменяются пустым экраном.
  Future<void> _loadData({bool refresh = false}) async {
    // При запуске профиль уже загружен корневым виджетом — повторные
    // запросы нужны только по явному обновлению жестом.
    await (refresh ? _userData.loadAll() : _userData.ensureLoaded());
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
          onRefresh: () => _loadData(refresh: true),
          color: tc.primary,
          backgroundColor: tc.card,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            // Показатели дня меняются на других экранах (вода, дневник, вес):
            // слушаем трекер и профиль, чтобы главная не показывала
            // устаревшие цифры до следующего ручного обновления.
            child: _isLoading
                ? _buildLoading(tc)
                : ListenableBuilder(
                    listenable: Listenable.merge([_tracker, _userData]),
                    builder: (context, _) => _buildContent(tc),
                  ),
          ),
        ),
      ),
    );
  }

  /// Заглушки повторяют раскладку экрана: когда данные приходят, блоки
  /// появляются на своих местах и содержимое не «прыгает».
  Widget _buildLoading(ThemeColors tc) {
    return Semantics(
      label: AppLocalizations.of(context)!.loadingData,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 68),
          AppSkeleton(width: 220, height: 24, radius: 8),
          SizedBox(height: 10),
          AppSkeleton(width: 280, height: 14, radius: 6),
          SizedBox(height: 24),
          AppSkeleton(height: 340),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: AppSkeleton(height: 104)),
              SizedBox(width: 16),
              Expanded(child: AppSkeleton(height: 104)),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: AppSkeleton(height: 104)),
              SizedBox(width: 16),
              Expanded(child: AppSkeleton(height: 104)),
            ],
          ),
        ],
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
            fontSize: 24,
            height: 1.15,
            letterSpacing: -0.5,
            fontWeight: FontWeight.w800,
            color: tc.text,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _dailyTip(progress, consumed, goal, remaining),
          style: TextStyle(
            fontSize: 14,
            height: 1.35,
            color: tc.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 24),
        FadeSlideIn(
          child: HomeCalorieRingCard(
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
        ),
        const SizedBox(height: 24),
        FadeSlideIn(
          index: 1,
          child: GridView(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            // Высота плитки растёт вместе с системным размером шрифта: при
            // фиксированной пропорции крупный текст не помещался.
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              mainAxisExtent:
                  104 *
                  MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6),
            ),
            children: [
              HomeStatTile(
                label: loc.steps,
                value: _tracker.totalSteps > 0 ? '${_tracker.totalSteps}' : '—',
                icon: Icons.directions_run,
                color: AppColors.accentActivity,
                onTap: () => _open(const ActivityPage()),
              ),
              HomeStatTile(
                label: loc.water,
                value: _formatWater(_tracker.totalWaterMl),
                icon: Icons.water_drop,
                color: AppColors.accentWater,
                onTap: () => _open(const WaterPage()),
              ),
              HomeStatTile(
                label: loc.weight,
                // Вес хранится в кг; показываем в единицах пользователя.
                value: _userData.latestWeight != null
                    ? loc.formatWeight(_userData.latestWeight!)
                    : '—',
                icon: Icons.monitor_weight_outlined,
                color: AppColors.accentWeight,
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
        FadeSlideIn(
          index: 2,
          child: HomeDiaryCard(
            consumed: consumed,
            goal: goal,
            protein: _tracker.totalProtein,
            onTap: () => _open(const DiaryPage()),
          ),
        ),
        const SizedBox(height: 24),
        FadeSlideIn(
          index: 3,
          child: HomeAiBanner(onTap: () => _open(const AiChatPage())),
        ),
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
