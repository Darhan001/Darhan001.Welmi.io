import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/services/auth_service.dart';
import 'package:lumina/core/services/supabase_service.dart';
import 'package:lumina/core/models/supabase_models.dart';
import 'package:lumina/core/services/health_sync_service.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/ux_helpers.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage>
    with SingleTickerProviderStateMixin {
  final SupabaseService _supabase = SupabaseService();
  late AnimationController _animController;

  bool _isLoading = true;
  bool _syncing = false;
  int _todaySteps = 0;
  double _todayCalories = 0;
  double _todayMinutes = 0;
  double _todayDistance = 0;
  int _stepGoal = 10000;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _loadTodayActivity();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadTodayActivity() async {
    setState(() => _isLoading = true);
    final userId = AuthService().userId;

    if (userId != null) {
      try {
        final logs = await _supabase.getActivityLogs(userId,
            from: DateTime.now().subtract(const Duration(days: 1)));

        // Ищем запись за сегодня
        final now = DateTime.now();
        final todayLog = logs.where((log) =>
            log.date.year == now.year &&
            log.date.month == now.month &&
            log.date.day == now.day).firstOrNull;

        if (todayLog != null) {
          _todaySteps = todayLog.steps;
          _todayCalories = todayLog.caloriesBurned ?? 0;
          _todayMinutes = todayLog.activeMinutes ?? 0;
          _todayDistance = todayLog.distanceKm ?? 0;
        }
      } catch (_) {
        // Если ошибка - используем демо-данные
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  /// Синхронизация с Google Fit / Apple Health
  Future<void> _syncFromHealth() async {
    if (_syncing) return;
    setState(() => _syncing = true);

    final health = HealthSyncService();

    // На Android нужен установленный Health Connect (Google Fit).
    if (!await health.isHealthConnectAvailable()) {
      if (mounted) {
        setState(() => _syncing = false);
        showWelmiSnackbar(
          context,
          'Для синхронизации шагов установи приложение Health Connect',
          icon: Icons.monitor_heart_outlined,
          actionLabel: 'Установить',
          onAction: () => health.installHealthConnect(),
        );
      }
      return;
    }

    final ok = await health.requestAuthorization();
    if (!ok) {
      if (mounted) {
        setState(() => _syncing = false);
        showWelmiSnackbar(context,
            'Нет доступа к шагам. Разреши доступ в настройках телефона',
            icon: Icons.lock_outline);
      }
      return;
    }

    final result = await health.syncToday();
    if (mounted) {
      setState(() => _syncing = false);
      switch (result.status) {
        case HealthSyncStatus.success:
          await _loadTodayActivity();
          hapticSuccess();
          showWelmiSnackbar(
            context,
            'Синхронизировано: ${result.steps} шагов · ${result.calories} ккал'
            '${result.sleepHours > 0 ? ' · сон ${result.sleepHours.toStringAsFixed(1)} ч' : ''}',
            icon: Icons.check_circle,
          );
          break;
        case HealthSyncStatus.notAuthorized:
          showWelmiSnackbar(context, 'Доступ к данным здоровья не получен',
              icon: Icons.lock_outline);
          break;
        case HealthSyncStatus.unsupported:
          showWelmiSnackbar(context,
              'Синхронизация доступна только на телефоне',
              icon: Icons.smartphone);
          break;
        case HealthSyncStatus.healthConnectMissing:
          showWelmiSnackbar(
            context,
            'Установи приложение Health Connect для синхронизации',
            icon: Icons.monitor_heart_outlined,
            actionLabel: 'Установить',
            onAction: () => health.installHealthConnect(),
          );
          break;
        case HealthSyncStatus.error:
          showWelmiSnackbar(context,
              'Не удалось получить данные из Health Connect',
              icon: Icons.error_outline);
          break;
      }
    }
  }

  void _showLogActivityDialog(ThemeColors tc) {
    final stepsCtl = TextEditingController(text: _todaySteps > 0 ? _todaySteps.toString() : '');
    final minutesCtl = TextEditingController(text: _todayMinutes > 0 ? _todayMinutes.toInt().toString() : '');
    final distanceCtl = TextEditingController(text: _todayDistance > 0 ? _todayDistance.toStringAsFixed(1) : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 32,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
        ),
        decoration: BoxDecoration(
          color: tc.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: tc.divider, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            Text('Записать активность', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: tc.text)),
            const SizedBox(height: 20),
            TextField(
              controller: stepsCtl,
              keyboardType: TextInputType.number,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: tc.text),
              decoration: InputDecoration(
                labelText: 'Шаги',
                hintText: 'Например: 8000',
                filled: true,
                fillColor: tc.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: minutesCtl,
                    keyboardType: TextInputType.number,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: tc.text),
                    decoration: InputDecoration(
                      labelText: 'Минуты',
                      hintText: '30',
                      filled: true,
                      fillColor: tc.background,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: distanceCtl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: tc.text),
                    decoration: InputDecoration(
                      labelText: 'Км',
                      hintText: '3.5',
                      filled: true,
                      fillColor: tc.background,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final steps = int.tryParse(stepsCtl.text) ?? 0;
                  final minutes = int.tryParse(minutesCtl.text) ?? 0;
                  final distance = double.tryParse(distanceCtl.text) ?? 0;

                  final userId = AuthService().userId;
                  if (userId != null) {
                    await _supabase.saveActivityLog(ActivityLog(
                      userId: userId,
                      steps: steps,
                      caloriesBurned: (steps * 0.045),
                      activeMinutes: minutes.toDouble(),
                      distanceKm: distance > 0 ? distance : null,
                    ));
                  }

                  if (mounted) {
                    hapticSuccess();
                    Navigator.pop(ctx);
                    _animController.reset();
                    _animController.forward();
                    _loadTodayActivity();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: tc.primary,
                  foregroundColor: tc.textOnPrimary,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Сохранить', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final progress = (_todaySteps / _stepGoal).clamp(0.0, 1.0);
    final remaining = (_stepGoal - _todaySteps).clamp(0, _stepGoal);

    return Scaffold(
      backgroundColor: tc.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                color: tc.card,
                                borderRadius: BorderRadius.circular(12)),
                            child: Icon(Icons.arrow_back,
                                size: 22, color: tc.text),
                          ),
                        ),
                        Text('Активность',
                            style: GoogleFonts.notoSerif(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                color: tc.text)),
                        GestureDetector(
                          onTap: () => _showLogActivityDialog(tc),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: tc.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.add,
                                color: tc.textOnPrimary, size: 22),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Steps card
                    _buildStepsCard(tc, _todaySteps, _stepGoal, remaining, progress),
                    const SizedBox(height: 24),

                    // Stats row
                    _buildStatsRow(tc),
                    const SizedBox(height: 24),

                    // Синхронизация с Google Fit / Apple Health
                    _buildHealthSyncCard(tc),
                    const SizedBox(height: 24),

                    // Tip card
                    _buildInfoCard(
                        tc,
                        'Совет дня',
                        _todaySteps < 5000
                            ? 'Больше двигайся! Постарайся сделать хотя бы 8000 шагов сегодня 🚶'
                            : _todaySteps < 8000
                                ? 'Хорошо, можно и больше! Добавь 15 мин прогулки 🌳'
                                : _todaySteps < 10000
                                    ? 'Отлично! Ещё немного до цели! 💪'
                                    : 'Цель достигнута! Ты невероятен! 🎉',
                        Icons.lightbulb_outline),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStepsCard(ThemeColors tc, int current, int goal,
      int remaining, double progress) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
              color: tc.shadow(0.04),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        children: [
          Text(
            remaining > 0 ? '$remaining шагов до цели' : 'Цель достигнута! 🎉',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: remaining > 0 ? Colors.orange : const Color(0xFF75A47F)),
          ),
          const SizedBox(height: 24),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 200,
                height: 200,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return CircularProgressIndicator(
                      value: value,
                      strokeWidth: 12,
                      backgroundColor: tc.text.withValues(alpha: 0.05),
                      color: progress >= 1.0
                          ? const Color(0xFF75A47F)
                          : Colors.orange,
                      strokeCap: StrokeCap.round,
                    );
                  },
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$current',
                      style: GoogleFonts.inter(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: tc.text)),
                  Text('шагов',
                      style: TextStyle(
                          fontSize: 14,
                          color: tc.textSecondary,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMiniStat(tc,
                  _todayDistance > 0 ? '${_todayDistance.toStringAsFixed(1)} км' : '—',
                  'Дистанция'),
              _buildMiniStat(tc,
                  _todayCalories > 0 ? '${_todayCalories.toInt()} ккал' : '—',
                  'Энергия'),
              _buildMiniStat(tc,
                  _todayMinutes > 0 ? '${_todayMinutes.toInt()} мин' : '—',
                  'Активность'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(ThemeColors tc) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
              tc, 'Цель', '$_stepGoal шагов', Icons.flag_rounded, Colors.orange),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
              tc, 'Прогресс',
              '${(_todaySteps / _stepGoal * 100).toStringAsFixed(0)}%',
              Icons.trending_up, const Color(0xFF75A47F)),
        ),
      ],
    );
  }

  Widget _buildHealthSyncCard(ThemeColors tc) {
    return GestureDetector(
      onTap: _syncFromHealth,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tc.card,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: tc.shadow(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F3E5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.monitor_heart_outlined,
                  size: 22, color: Color(0xFF75A47F)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Google Fit / Apple Health',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: tc.text)),
                  const SizedBox(height: 2),
                  Text('Подтянуть шаги и калории автоматически',
                      style: TextStyle(
                          fontSize: 11,
                          color: tc.textHint,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            if (_syncing)
              const Padding(
                padding: EdgeInsets.all(6),
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              )
            else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: tc.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sync_rounded,
                        size: 15, color: tc.textOnPrimary),
                    const SizedBox(width: 5),
                    Text('Синхр.',
                        style: TextStyle(
                            color: tc.textOnPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(ThemeColors tc, String label, String value,
      IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: tc.shadow(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 16,
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

  Widget _buildMiniStat(
      ThemeColors tc, String value, String label) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: tc.text)),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: tc.textHint,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildInfoCard(
      ThemeColors tc, String title, String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.orange, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Colors.orange.shade800,
                        fontSize: 14)),
                const SizedBox(height: 4),
                Text(text,
                    style: TextStyle(
                        fontSize: 12,
                        color: tc.textSecondary,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
