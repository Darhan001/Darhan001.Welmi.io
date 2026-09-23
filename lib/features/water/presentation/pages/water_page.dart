import 'package:flutter/material.dart';
import 'package:lumina/core/services/daily_tracker.dart';
import 'package:lumina/core/services/supabase_service.dart';
import 'package:lumina/core/services/auth_service.dart';
import 'package:lumina/core/services/widget_service.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/app_app_bar.dart';
import 'package:lumina/core/widgets/app_card.dart';
import 'package:lumina/core/widgets/app_chip.dart';
import 'package:lumina/core/widgets/app_states.dart';
import 'package:lumina/core/widgets/ux_helpers.dart';
import 'package:lumina/l10n/app_localizations.dart';

class WaterPage extends StatefulWidget {
  const WaterPage({super.key});

  @override
  State<WaterPage> createState() => _WaterPageState();
}

class _WaterPageState extends State<WaterPage> {
  final DailyTracker _tracker = DailyTracker();
  final SupabaseService _supabase = SupabaseService();
  List<double> _weeklyData = [0, 0, 0, 0, 0, 0, 0];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await _tracker.loadToday();
    await _loadWeeklyData();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadWeeklyData() async {
    final userId = AuthService().userId;
    if (userId == null) return;

    final now = DateTime.now();
    final weekData = <double>[];

    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      try {
        final total = await _supabase.getDailyWaterTotal(userId, day);
        weekData.add(total.toDouble());
      } catch (_) {
        weekData.add(0);
      }
    }

    if (mounted) setState(() => _weeklyData = weekData);
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    return ListenableBuilder(
      listenable: _tracker,
      builder: (context, _) {
        final progress = _tracker.waterProgress;
        final currentWater = _tracker.totalWaterMl;
        final dailyGoal = _tracker.goalWaterMl;
        final remaining = (dailyGoal - currentWater).clamp(0, dailyGoal);

        return Scaffold(
          backgroundColor: tc.background,
          body: SafeArea(
            child: _isLoading
                ? const AppLoading()
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        AppAppBar(                           title: AppLocalizations.of(context)!.water,
                          actions: [
                            AppBarActionButton(
                              icon: Icons.refresh_rounded,
                              onTap: _loadData,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildWaterGlass(
                            tc, progress, currentWater, remaining, dailyGoal),
                        const SizedBox(height: 24),
                        _buildQuickAddRow(tc),
                        const SizedBox(height: 24),
                        _buildWeeklyChart(tc),
                        const SizedBox(height: 24),
                        _buildStatsRow(tc, currentWater, dailyGoal),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildWaterGlass(ThemeColors tc, double progress, int current,
      int remaining, int goal) {
    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            progress >= 1.0
                ? 'Цель достигнута! 🎉'                 : AppLocalizations.of(context)!.remainingKcal(remaining),
            style: TextStyle(
                fontSize: 13,
                color: progress >= 1.0 ? tc.success : tc.textSecondary,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 180,
                height: 220,
                decoration: BoxDecoration(
                  color: tc.isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : const Color(0xFFF0F7FF),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                      color: tc.isDark
                          ? Colors.white10
                          : Colors.black.withValues(alpha: 0.06),
                      width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(38),
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        height: 220 * progress,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF75A47F), Color(0xFF4A8C5C)],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$current',
                      style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: Colors.white)),
                  Text('из $goal мл',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAddRow(ThemeColors tc) {
    return Row(
      children: [
        Expanded(
            child: _buildAddButton(tc, 100, '100 мл', Icons.water_drop)),
        const SizedBox(width: 12),
        Expanded(             child: _buildAddButton(tc, 250, AppLocalizations.of(context)!.glass, Icons.opacity)),
        const SizedBox(width: 12),
        Expanded(
            child:                 _buildAddButton(tc, 500, AppLocalizations.of(context)!.bottle, Icons.local_drink, dark: true)),
      ],
    );
  }

  Widget _buildAddButton(ThemeColors tc, int ml, String label, IconData icon,
      {bool dark = false}) {
    final bool isDarkBtn = dark && tc.isDark;
    return AppCard(
      onTap: () async {
        hapticTap();
        await _tracker.addWater(ml);
        // После добавления обновляем недельные данные и виджет на рабочем столе
        _loadWeeklyData();
        WidgetService().updateAll();
      },
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      color: dark ? (tc.isDark ? Colors.white : Colors.black) : null,
      child: Column(
        children: [
          Icon(icon,
              size: 22,
              color: dark
                  ? (isDarkBtn ? Colors.black : Colors.white)
                  : tc.green),
          const SizedBox(height: 10),
          Text('+$ml',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: dark
                      ? (isDarkBtn ? Colors.black : Colors.white)
                      : tc.text)),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: dark ? Colors.white70 : tc.textHint,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(ThemeColors tc) {
    final maxVal = _weeklyData
        .reduce((a, b) => a > b ? a : b)
        .clamp(1.0, double.infinity);
    final dayNames = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'];

    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppLocalizations.of(context)!.weightDynamics,
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: tc.text)),
              AppBadge(
                text:
                    '${(_weeklyData.reduce((a, b) => a + b) / 1000).toStringAsFixed(1)} л',
                icon: Icons.water_drop,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final val = _weeklyData[i];
              final height = (val / maxVal * 120).clamp(4.0, 120.0);
              final isToday = i == DateTime.now().weekday - 1;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${val.toInt()}',
                      style: TextStyle(
                          fontSize: 9,
                          color: tc.textHint,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Container(
                    width: 32,
                    height: height,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          tc.green,
                          tc.greenDark.withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: isToday
                          ? Border.all(color: tc.green, width: 2)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(dayNames[i],
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              isToday ? FontWeight.w800 : FontWeight.w600,
                          color: isToday ? tc.green : tc.textHint)),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(ThemeColors tc, int current, int goal) {
    final cups = (current / 250).round();
    final weekTotal = _weeklyData.reduce((a, b) => a + b).toInt();
    return Row(
      children: [
        Expanded(             child: _buildStatCard(tc, AppLocalizations.of(context)!.weightLost, '$current мл',
                Icons.water_drop, tc.success)),
        const SizedBox(width: 12),
        Expanded(             child: _buildStatCard(tc, AppLocalizations.of(context)!.glass, '$cups',
                Icons.opacity, tc.green)),
        const SizedBox(width: 12),
        Expanded(             child: _buildStatCard(tc, AppLocalizations.of(context)!.weekChange('7'), '$weekTotal мл',
                Icons.calendar_view_week, tc.success)),
      ],
    );
  }

  Widget _buildStatCard(ThemeColors tc, String label, String value,
      IconData icon, Color color) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: tc.text)),
          Text(label,
              style: TextStyle(
                  fontSize: 9,
                  color: tc.textHint,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
