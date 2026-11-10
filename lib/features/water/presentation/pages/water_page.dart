import 'package:flutter/material.dart';
import 'package:lumina/core/services/auth_service.dart';
import 'package:lumina/core/services/daily_tracker.dart';
import 'package:lumina/core/services/supabase_service.dart';
import 'package:lumina/core/services/widget_service.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/app_app_bar.dart';
import 'package:lumina/core/widgets/app_card.dart';
import 'package:lumina/core/widgets/app_states.dart';
import 'package:lumina/core/widgets/ux_helpers.dart';
import 'package:lumina/features/water/presentation/widgets/water_glass_card.dart';
import 'package:lumina/features/water/presentation/widgets/water_quick_add.dart';
import 'package:lumina/features/water/presentation/widgets/water_week_chart.dart';
import 'package:lumina/l10n/app_localizations.dart';

class WaterPage extends StatefulWidget {
  const WaterPage({super.key});

  @override
  State<WaterPage> createState() => _WaterPageState();
}

class _WaterPageState extends State<WaterPage> {
  final DailyTracker _tracker = DailyTracker();
  final SupabaseService _supabase = SupabaseService();
  List<({DateTime day, int ml})> _week = _emptyWeek();
  bool _isLoading = true;

  static List<({DateTime day, int ml})> _emptyWeek() {
    final today = DateUtils.dateOnly(DateTime.now());
    return [
      for (var i = 6; i >= 0; i--)
        (day: today.subtract(Duration(days: i)), ml: 0),
    ];
  }

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

  /// Вода за 7 дней одним запросом (раньше — 7 запросов по очереди).
  Future<void> _loadWeeklyData() async {
    final userId = AuthService().userId;
    if (userId == null) return;
    final week = _emptyWeek();
    try {
      final totals = await _supabase.getWaterTotalsByDay(
        userId,
        from: week.first.day,
        to: week.last.day,
      );
      String keyOf(DateTime d) => d.toIso8601String().substring(0, 10);
      if (!mounted) return;
      setState(() {
        _week = [
          for (final d in week) (day: d.day, ml: totals[keyOf(d.day)] ?? 0),
        ];
      });
    } catch (e) {
      // Неделя — второстепенный блок: оставляем нули, сегодня берём из трекера.
      debugPrint('⚠️ Water week load error: $e');
    }
  }

  Future<void> _addWater(int ml) async {
    hapticTap();
    await _tracker.addWater(ml);
    // После добавления обновляем недельные данные и виджет на рабочем столе
    _loadWeeklyData();
    WidgetService().updateAll();
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: tc.background,
      body: SafeArea(
        child: _isLoading
            ? const AppLoading()
            : ListenableBuilder(
                listenable: _tracker,
                builder: (context, _) => ListView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                  children: [
                    AppAppBar(
                      title: loc.water,
                      actions: [
                        AppBarActionButton(
                          icon: Icons.refresh_rounded,
                          tooltip: loc.refresh,
                          onTap: _loadData,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    WaterGlassCard(
                      currentMl: _tracker.totalWaterMl,
                      goalMl: _tracker.goalWaterMl,
                      progress: _tracker.waterProgress,
                    ),
                    const SizedBox(height: 24),
                    WaterQuickAddRow(onAdd: _addWater),
                    const SizedBox(height: 24),
                    WaterWeekChart(days: _week),
                    const SizedBox(height: 24),
                    _buildStatsRow(tc, loc),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatsRow(ThemeColors tc, AppLocalizations loc) {
    final current = _tracker.totalWaterMl;
    final weekTotal = _week.fold<int>(0, (sum, d) => sum + d.ml);
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            loc.waterDrunk,
            loc.mlValue(current),
            Icons.water_drop,
            tc.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            loc.glass,
            '${(current / 250).round()}',
            Icons.opacity,
            tc.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            loc.weekChange('7'),
            loc.mlValue(weekTotal),
            Icons.calendar_view_week,
            tc.success,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(this.label, this.value, this.icon, this.color);

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: tc.text,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              color: tc.textHint,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
