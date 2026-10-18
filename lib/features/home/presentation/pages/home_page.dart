import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/services/auth_service.dart';
import 'package:lumina/core/services/daily_tracker.dart';
import 'package:lumina/core/services/user_data_service.dart';
import 'package:lumina/core/services/widget_service.dart';
import 'package:lumina/core/services/health_sync_service.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/ux_helpers.dart';
import 'package:lumina/features/onboarding/presentation/widgets/calculation_step.dart'
    show lastAiPlan;
import 'package:lumina/features/diary/presentation/pages/diary_page.dart';
import 'package:lumina/features/water/presentation/pages/water_page.dart';
import 'package:lumina/features/weight/presentation/pages/weight_page.dart';
import 'package:lumina/features/goal/presentation/pages/goal_page.dart';
import 'package:lumina/features/activity/presentation/pages/activity_page.dart';
import 'package:lumina/features/history/presentation/pages/activity_history_page.dart';
import 'package:lumina/features/meal_plan/presentation/pages/meal_plan_page.dart';
import 'package:lumina/features/workout/presentation/pages/workout_page.dart';
import 'package:lumina/features/notifications/presentation/pages/notifications_page.dart';
import 'package:lumina/features/settings/presentation/pages/settings_page.dart';
import 'package:lumina/features/support/presentation/pages/support_page.dart';
import 'package:lumina/features/chat/presentation/pages/ai_chat_page.dart';
import 'package:lumina/features/profile/domain/services/subscription_service.dart';
import 'package:lumina/core/widgets/logout_flow.dart';
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
      if (mounted && _tracker.lastUpdated != null) setState(() {});
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
      height: MediaQuery.of(context).size.height * 0.7,
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
    final consumed = _tracker.totalCalories;
    final goal = _tracker.goalCalories;
    final remaining = _tracker.remainingCalories;
    final progress = _tracker.calorieProgress;
    final fullName =
        _userData.profile?.displayName ??
        AuthService().displayName ??
        AppLocalizations.of(context)!.guest;
    final firstName = fullName.trim().split(' ').first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        // ── Шапка ──
        Builder(
          builder: (context) => Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Зона нажатия 48×48 и подписи для экранного диктора: раньше
              // колокольчик реагировал только на сами пиксели иконки.
              IconButton(
                tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
                onPressed: () {
                  hapticTap();
                  Scaffold.of(context).openDrawer();
                },
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: tc.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.menu, color: tc.textOnPrimary, size: 20),
                ),
              ),
              Text(
                'Welmi',
                style: GoogleFonts.notoSerif(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: tc.text,
                ),
              ),
              IconButton(
                tooltip: AppLocalizations.of(context)!.notificationsPageTitle,
                onPressed: () {
                  hapticTap();
                  Navigator.push(
                    context,
                    smoothPageRoute(const NotificationsPage()),
                  );
                },
                icon: Icon(Icons.notifications_none, size: 28, color: tc.text),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // ── Приветствие + совет ──
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

        // ── Круг калорий ──
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: tc.card,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: tc.shadow(0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 210,
                      height: 210,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: progress),
                        duration: const Duration(milliseconds: 1200),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return CircularProgressIndicator(
                            value: value,
                            strokeWidth: 14,
                            backgroundColor: tc.text.withValues(alpha: 0.05),
                            color: progress > 0.8
                                ? tc.green
                                : progress > 0.5
                                ? Colors.orange
                                : tc.primary,
                            strokeCap: StrokeCap.round,
                          );
                        },
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.remaining,
                          style: TextStyle(
                            fontSize: 14,
                            color: tc.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '$remaining',
                          style: GoogleFonts.inter(
                            fontSize: 52,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -2,
                            color: tc.text,
                          ),
                        ),
                        Text(
                          AppLocalizations.of(context)!.ofKcal(goal),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: tc.textHint,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // ── Макросы ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMacroPill(
                    tc,
                    AppLocalizations.of(context)!.protein,
                    '${_tracker.totalProtein} / ${_tracker.goalProtein}г',
                  ),
                  _buildMacroPill(
                    tc,
                    AppLocalizations.of(context)!.fat,
                    '${_tracker.totalFat} / ${_tracker.goalFat}г',
                  ),
                  _buildMacroPill(
                    tc,
                    AppLocalizations.of(context)!.carbs,
                    '${_tracker.totalCarbs} / ${_tracker.goalCarbs}г',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Сетка статистики ──
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.3,
          children: [
            _buildStatTile(
              tc,
              AppLocalizations.of(context)!.steps,
              _tracker.totalSteps > 0 ? '${_tracker.totalSteps}' : '—',
              Icons.directions_run,
              Colors.orange,
              () => Navigator.push(
                context,
                smoothPageRoute(const ActivityPage()),
              ),
            ),
            _buildStatTile(
              tc,
              AppLocalizations.of(context)!.water,
              _formatWater(_tracker.totalWaterMl),
              Icons.water_drop,
              const Color(0xFF5EB5FF),
              () => Navigator.push(context, smoothPageRoute(const WaterPage())),
            ),
            _buildStatTile(
              tc,
              AppLocalizations.of(context)!.weight,
              _userData.latestWeight != null
                  ? _userData.latestWeight!.toStringAsFixed(1)
                  : '—',
              Icons.monitor_weight_outlined,
              const Color(0xFFC78BFF),
              () =>
                  Navigator.push(context, smoothPageRoute(const WeightPage())),
            ),
            _buildStatTile(
              tc,
              AppLocalizations.of(context)!.goal,
              '${(progress * 100).clamp(0, 100).toInt()}%',
              Icons.flag_rounded,
              tc.green,
              () => Navigator.push(context, smoothPageRoute(const GoalPage())),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // ── Сегодня съедено ──
        Text(
          AppLocalizations.of(context)!.todayEaten,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: tc.text,
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () {
            hapticTap();
            Navigator.push(context, smoothPageRoute(const DiaryPage()));
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: tc.card,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: tc.shadow(0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: tc.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.restaurant_rounded,
                    size: 24,
                    color: tc.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.foodDiary,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: tc.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$consumed из $goal ккал · ${_tracker.totalProtein}г белка',
                        style: TextStyle(
                          fontSize: 12,
                          color: tc.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: tc.textHint),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // ── AI-помощник ──
        GestureDetector(
          onTap: () {
            hapticTap();
            Navigator.push(context, smoothPageRoute(const AiChatPage()));
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4A8C5C), Color(0xFF75A47F)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: tc.greenDark.withValues(alpha: 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    size: 22,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.aiAssistant,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppLocalizations.of(context)!.aiAssistantDesc,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  String _formatWater(int ml) {
    if (ml <= 0) return '—';
    return ml >= 1000 ? '${(ml / 1000).toStringAsFixed(1)}л' : '$mlмл';
  }

  Widget _buildMacroPill(ThemeColors tc, String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: tc.textHint,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: tc.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: tc.divider.withValues(alpha: 0.4)),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: tc.text,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile(
    ThemeColors tc,
    String label,
    String value,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tc.card,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: tc.shadow(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 13,
                  color: tc.textHint.withValues(alpha: 0.6),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: tc.text,
                    ),
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: tc.textHint,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Боковое меню
  // ─────────────────────────────────────────────

  Widget _buildDrawer(BuildContext context) {
    final tc = ThemeColors.of(context);
    final fullName =
        _userData.profile?.displayName ??
        AuthService().displayName ??
        AppLocalizations.of(context)!.userDefault;
    final initial = fullName.trim().isNotEmpty
        ? fullName.trim()[0].toUpperCase()
        : 'П';

    return Drawer(
      backgroundColor: tc.background,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: tc.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: TextStyle(
                          color: tc.textOnPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: tc.text,
                          ),
                        ),
                        // Статус Premium — только по серверному entitlement.
                        // Раньше подпись «Welmi Premium» видели все.
                        if (SubscriptionService.instance.state.isPremium) ...[
                          const SizedBox(height: 2),
                          Text(
                            AppLocalizations.of(context)!.welmiPremium,
                            style: TextStyle(color: tc.greenDark, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(indent: 24, endIndent: 24, color: tc.divider),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _drawerItem(
                    context,
                    Icons.fitness_center_rounded,
                    AppLocalizations.of(context)!.drawerWorkouts,
                    () {
                      hapticTap();
                      Navigator.push(
                        context,
                        smoothPageRoute(const WorkoutPage()),
                      );
                    },
                  ),
                  _drawerItem(
                    context,
                    Icons.auto_awesome_outlined,
                    AppLocalizations.of(context)!.drawerMyGoals,
                    () {
                      hapticTap();
                      Navigator.push(
                        context,
                        smoothPageRoute(const GoalPage()),
                      );
                    },
                  ),
                  _drawerItem(
                    context,
                    Icons.restaurant_menu_outlined,
                    AppLocalizations.of(context)!.drawerMealPlan,
                    () {
                      hapticTap();
                      Navigator.push(
                        context,
                        smoothPageRoute(const MealPlanPage()),
                      );
                    },
                  ),
                  _drawerItem(
                    context,
                    Icons.history_rounded,
                    AppLocalizations.of(context)!.drawerActivityHistory,
                    () {
                      hapticTap();
                      Navigator.push(
                        context,
                        smoothPageRoute(const ActivityHistoryPage()),
                      );
                    },
                  ),
                  _drawerItem(
                    context,
                    Icons.settings_outlined,
                    AppLocalizations.of(context)!.drawerSettings,
                    () {
                      hapticTap();
                      Navigator.push(
                        context,
                        smoothPageRoute(const SettingsPage()),
                      );
                    },
                  ),
                  _drawerItem(
                    context,
                    Icons.help_outline_rounded,
                    AppLocalizations.of(context)!.drawerSupport,
                    () {
                      hapticTap();
                      Navigator.push(
                        context,
                        smoothPageRoute(const SupportPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: _drawerItem(
                context,
                Icons.logout_rounded,
                AppLocalizations.of(context)!.drawerLogout,
                () {
                  confirmAndSignOut(context);
                },
                color: Colors.redAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color? color,
  }) {
    final tc = ThemeColors.of(context);
    return Builder(
      // Свой context внутри Drawer: через него закрываем меню перед
      // переходом, иначе при возврате назад оно оставалось открытым.
      builder: (itemContext) => ListTile(
        onTap: () {
          Scaffold.maybeOf(itemContext)?.closeDrawer();
          onTap();
        },
        leading: Icon(icon, color: color ?? tc.text.withValues(alpha: 0.7)),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: color ?? tc.text,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
