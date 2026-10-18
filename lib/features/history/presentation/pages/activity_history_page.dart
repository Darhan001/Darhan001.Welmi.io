import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumina/core/services/units_service.dart';
import 'package:lumina/core/utils/number_input.dart';
import 'package:lumina/core/widgets/units_format.dart';
import 'package:lumina/core/services/auth_service.dart';
import 'package:lumina/core/services/supabase_service.dart';
import 'package:lumina/core/services/daily_tracker.dart';
import 'package:lumina/core/services/widget_service.dart';
import 'package:lumina/core/models/supabase_models.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/ux_helpers.dart';
import 'package:lumina/l10n/app_localizations.dart';

const _green = Color(0xFF75A47F);
const _greenDark = Color(0xFF4A8C5C);
const _greenSoft = Color(0xFFE8F3E5);
const _blue = Color(0xFF64B5F6);
const _blueSoft = Color(0xFFEAF3FE);
const _orange = Color(0xFFFFB74D);
const _orangeSoft = Color(0xFFFFF3E0);
const _pink = Color(0xFFE57373);
const _pinkSoft = Color(0xFFFDEBEB);

/// Один день в истории: шаги + вода + упражнения.
class _DayActivity {
  final DateTime date;
  int steps;
  int calories;
  int minutes;
  double distanceKm;
  int waterMl;
  List<Map<String, dynamic>> exercises;

  _DayActivity({
    required this.date,
    this.steps = 0,
    this.calories = 0,
    this.minutes = 0,
    this.distanceKm = 0,
    this.waterMl = 0,
    this.exercises = const [],
  });

  bool get isActive => steps > 0 || exercises.isNotEmpty || minutes > 0;
}

const _exerciseOptions = [
  (Icons.sports_gymnastics, 'Приседания'),
  (Icons.fitness_center, 'Отжимания'),
  (Icons.timer_outlined, 'Планка'),
  (Icons.directions_run, 'Бег'),
  (Icons.directions_walk, 'Ходьба'),
  (Icons.accessibility_new, 'Пресс'),
  (Icons.sports_martial_arts, 'Скакалка'),
  (Icons.directions_bike, 'Велосипед'),
  (Icons.self_improvement, 'Йога'),
  (Icons.spa, 'Растяжка'),
];

class ActivityHistoryPage extends StatefulWidget {
  const ActivityHistoryPage({super.key});

  @override
  State<ActivityHistoryPage> createState() => _ActivityHistoryPageState();
}

class _ActivityHistoryPageState extends State<ActivityHistoryPage> {
  final SupabaseService _supabase = SupabaseService();
  final DailyTracker _tracker = DailyTracker();

  List<_DayActivity> _days = [];
  List<ActivityLog> _logs30 = [];
  bool _isLoading = true;
  String? _error;

  static const _historyDays = 14;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  String _dateKey(DateTime d) => d.toIso8601String().substring(0, 10);

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final userId = AuthService().userId;
    if (userId == null) {
      setState(() {
        _isLoading = false;
        _error = 'loginToViewHistory';
      });
      return;
    }

    try {
      // Активность за 30 дней
      final from = DateTime.now().subtract(const Duration(days: 30));
      _logs30 = await _supabase.getActivityLogs(userId, from: from);
      final byDate = <String, ActivityLog>{};
      for (final log in _logs30) {
        byDate[_dateKey(log.date)] = log;
      }

      // Вода по дням (последние 14 дней)
      final waters = <String, int>{};
      final now = DateTime.now();
      for (var i = 0; i < _historyDays; i++) {
        final day = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: i));
        try {
          waters[_dateKey(day)] =
              await _supabase.getDailyWaterTotal(userId, day);
        } catch (_) {
          waters[_dateKey(day)] = 0;
        }
      }

      // Упражнения (локально)
      final exercises = await _loadExercises();

      final days = List.generate(_historyDays, (i) {
        final day = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: i));
        final key = _dateKey(day);
        final log = byDate[key];
        return _DayActivity(
          date: day,
          steps: log?.steps ?? 0,
          calories: (log?.caloriesBurned ?? 0).toInt(),
          minutes: (log?.activeMinutes ?? 0).toInt(),
          distanceKm: log?.distanceKm ?? 0,
          waterMl: waters[key] ?? 0,
          exercises: exercises[key] ?? [],
        );
      });

      if (mounted) {
        setState(() {
          _days = days;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Ошибка загрузки: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  // ─── Упражнения (локальное хранилище) ───

  String get _exerciseKey => 'exercise_log_${AuthService().userId ?? 'anon'}';

  Future<Map<String, List<Map<String, dynamic>>>> _loadExercises() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_exerciseKey);
      if (raw == null) return {};
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return data.map(
        (k, v) => MapEntry(
          k,
          (v as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList(),
        ),
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> _addExercise(String name, int sets, int reps) async {
    final prefs = await SharedPreferences.getInstance();
    final data = await _loadExercises();
    final key = _dateKey(DateTime.now());
    final list = data[key] ?? [];
    list.add({'name': name, 'sets': sets, 'reps': reps});
    data[key] = list;
    await prefs.setString(_exerciseKey, jsonEncode(data));
  }

  // ─── Stats ───

  int get _totalSteps =>
      _logs30.fold<int>(0, (sum, log) => sum + log.steps);
  int get _totalWater => _days.fold<int>(0, (sum, d) => sum + d.waterMl);
  int get _activeDays =>
      _days.where((d) => d.isActive).length;

  String _formatNumber(int n) {
    if (n >= 1000) {
      final thousands = n / 1000;
      return thousands == thousands.roundToDouble()
          ? '${thousands.round()}к'
          : '${thousands.toStringAsFixed(1)}к';
    }
    return n.toString();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now
        .difference(DateTime(date.year, date.month, date.day))
        .inDays;
    if (diff == 0) return 'Сегодня';
    if (diff == 1) return 'Вчера';
    const months = [
      'янв', 'фев', 'мар', 'апр', 'май', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  // ─── Запись данных ───

  void _showAddSheet() {
    final tc = ThemeColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: tc.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [               Text(AppLocalizations.of(context)!.whatToLog,
                  style: GoogleFonts.notoSerif(
                      fontSize: 20, fontWeight: FontWeight.w900, color: tc.text)),
              const SizedBox(height: 4),
              Text('Шаги, воду или тренировку',
                  style: TextStyle(fontSize: 13, color: tc.textSecondary)),
              const SizedBox(height: 16),
              _addActionTile(ctx, Icons.directions_run_rounded,                   AppLocalizations.of(context)!.activityLog, AppLocalizations.of(context)!.activityLogSubtitle, _orange, () {
                Navigator.pop(ctx);
                _showActivityDialog();
              }),               _addActionTile(ctx, Icons.water_drop_rounded, AppLocalizations.of(context)!.waterLog,
                   AppLocalizations.of(context)!.waterLogSubtitle, _blue, () {
                Navigator.pop(ctx);
                _showWaterDialog();
              }),               _addActionTile(ctx, Icons.fitness_center_rounded, AppLocalizations.of(context)!.exerciseLog,
                   AppLocalizations.of(context)!.exerciseLogSubtitle, _green, () {
                Navigator.pop(ctx);
                _showExerciseDialog();
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _addActionTile(BuildContext ctx, IconData icon, String title,
      String subtitle, Color color, VoidCallback onTap) {
    final tc = ThemeColors.of(ctx);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: tc.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: tc.text)),
                  Text(subtitle,
                      style: TextStyle(fontSize: 11, color: tc.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: tc.textHint),
          ],
        ),
      ),
    );
  }

  Future<void> _showActivityDialog() async {
    final tc = ThemeColors.of(context);
    final stepsCtl = TextEditingController();
    final minutesCtl = TextEditingController();
    final distanceCtl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: tc.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: tc.divider,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),             Text(AppLocalizations.of(context)!.logActivity,
                style: GoogleFonts.notoSerif(
                    fontSize: 20, fontWeight: FontWeight.w900, color: tc.text)),
            const SizedBox(height: 16),
            _field(ctx, stepsCtl, 'Шаги', 'Например: 8000',
                TextInputType.number),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                    child: _field(ctx, minutesCtl, 'Минуты', '30',
                        TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(
                    child: _field(ctx, distanceCtl,
                        AppLocalizations.of(context)!.distanceUnitLabel, '3.5',
                        const TextInputType.numberWithOptions(decimal: true))),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final steps = int.tryParse(stepsCtl.text) ?? 0;
                  final minutes = int.tryParse(minutesCtl.text) ?? 0;
                  final distance = UnitsService.instance
                      .distanceFromDisplay(parseDecimalInput(distanceCtl.text) ?? 0);
                  final userId = AuthService().userId;
                  if (userId == null) return;

                  Navigator.pop(ctx);
                  await _supabase.saveActivityLog(ActivityLog(
                    userId: userId,
                    date: DateTime.now(),
                    steps: steps,
                    caloriesBurned: steps > 0 ? steps * 0.045 : null,
                    activeMinutes: minutes > 0 ? minutes.toDouble() : null,
                    distanceKm: distance > 0 ? distance : null,
                  ));
                  await _tracker.loadToday();
                  WidgetService().updateAll();
                  if (mounted) {
                    hapticSuccess();                     showWelmiSnackbar(context, AppLocalizations.of(context)!.activitySaved,
                        icon: Icons.check_circle);
                    _loadHistory();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _greenDark,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                ),                     child: Text(AppLocalizations.of(context)!.save,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWaterDialog() {
    final tc = ThemeColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: tc.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [               Text(AppLocalizations.of(context)!.addWater,
                  style: GoogleFonts.notoSerif(
                      fontSize: 20, fontWeight: FontWeight.w900, color: tc.text)),
              const SizedBox(height: 4),
              Text(
                  'Сегодня выпито:'
                  ' ${_days.isNotEmpty ? _days.first.waterMl : 0} мл',
                  style: TextStyle(fontSize: 13, color: tc.textSecondary)),
              const SizedBox(height: 16),
              Row(
                children: [                   _waterAmountChip(ctx, 250, AppLocalizations.of(context)!.glass),
                  const SizedBox(width: 8),                   _waterAmountChip(ctx, 500, AppLocalizations.of(context)!.bottle),
                  const SizedBox(width: 8),                   _waterAmountChip(ctx, 1000, AppLocalizations.of(context)!.liter),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _waterAmountChip(BuildContext ctx, int ml, String label) {
    final tc = ThemeColors.of(ctx);
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          Navigator.pop(ctx);
          await _tracker.addWater(ml);
          WidgetService().updateAll();
          if (mounted) {
            hapticSuccess();
            showWelmiSnackbar(context, '+$ml мл воды',
                icon: Icons.water_drop_rounded);
            _loadHistory();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: _blueSoft,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _blue.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              const Icon(Icons.water_drop_rounded, size: 20, color: _blue),
              const SizedBox(height: 6),
              Text('+$ml',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2196F3))),
              Text(label,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: tc.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  void _showExerciseDialog() {
    final tc = ThemeColors.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: tc.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        String? selected;
        final setsCtl = TextEditingController(text: '3');
        final repsCtl = TextEditingController();

        return StatefulBuilder(
          builder: (context, setSheetState) => Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: tc.divider,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),                 Text(AppLocalizations.of(context)!.addExercise,
                    style: GoogleFonts.notoSerif(
                        fontSize: 20, fontWeight: FontWeight.w900, color: tc.text)),
                const SizedBox(height: 16),
                // Выбор упражнения
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _exerciseOptions.map((opt) {
                    final name = opt.$2;
                    final isSel = selected == name;
                    return GestureDetector(
                      onTap: () => setSheetState(() => selected = name),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSel ? _greenSoft : tc.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSel
                                ? _green
                                : tc.divider.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(opt.$1,
                                size: 16,
                                color: isSel ? _greenDark : tc.textSecondary),
                            const SizedBox(width: 6),
                            Text(name,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSel
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: isSel
                                        ? _greenDark
                                        : tc.textSecondary)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _field(context, setsCtl, 'Подходы', '3',
                          TextInputType.number),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _field(context, repsCtl, 'Повторения', '15',
                          TextInputType.number),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (selected == null) {                         showWelmiSnackbar(context, AppLocalizations.of(context)!.selectExercise,
                            icon: Icons.info_outline);
                        return;
                      }
                      final sets = int.tryParse(setsCtl.text) ?? 3;
                      final reps = int.tryParse(repsCtl.text) ?? 0;
                      Navigator.pop(context);
                      await _addExercise(selected!, sets, reps);
                      if (mounted) {
                        hapticSuccess();
                        showWelmiSnackbar(
                            this.context, '$selected — добавлено в историю',
                            icon: Icons.fitness_center_rounded);
                        _loadHistory();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _greenDark,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 54),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                    ),                     child: Text(AppLocalizations.of(context)!.addButton,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _field(BuildContext ctx, TextEditingController ctl, String label,
      String hint, TextInputType type) {
    final tc = ThemeColors.of(ctx);
    return TextField(
      controller: ctl,
      keyboardType: type,
      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: tc.text),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: tc.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  // ─── UI ───

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: tc.background,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: tc.primary),
                const SizedBox(height: 16),                 Text(AppLocalizations.of(context)!.loadingHistory,
                    style: TextStyle(
                        color: tc.textSecondary,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: tc.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child:
                          Icon(Icons.arrow_back, size: 22, color: tc.text),
                    ),
                  ),                   Text(AppLocalizations.of(context)!.historyTitle,
                      style: GoogleFonts.notoSerif(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: tc.text)),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _loadHistory,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: tc.card,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.refresh_rounded,
                              size: 20, color: tc.textHint),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _showAddSheet,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _greenDark,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.add_rounded,
                              size: 22, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (_error != null && _days.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: tc.card,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.info_outline, size: 48, color: tc.textHint),
                      const SizedBox(height: 16),
                      Text(_error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: tc.textSecondary, fontSize: 14)),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _loadHistory,
                        child: const Text('Повторить',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _green)),
                      ),
                    ],
                  ),
                )
              else ...[
                // ── Сводка за период ──
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: tc.card,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: tc.shadow(0.03),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _summaryItem(
                            Icons.directions_walk_rounded,
                            _formatNumber(_totalSteps),
                            'шагов за 30 дней',
                            _orange,
                            _orangeSoft,
                            tc),
                      ),
                      Container(
                          width: 1,
                          height: 44,
                          color: tc.divider.withValues(alpha: 0.4)),
                      Expanded(
                        child: _summaryItem(
                            Icons.water_drop_rounded,
                            '${(_totalWater / 1000).toStringAsFixed(1)} л',
                            'воды за 14 дней',
                            _blue,
                            _blueSoft,
                            tc),
                      ),
                      Container(
                          width: 1,
                          height: 44,
                          color: tc.divider.withValues(alpha: 0.4)),
                      Expanded(
                        child: _summaryItem(
                            Icons.fitness_center_rounded,
                            '$_activeDays',
                            'активных дней',
                            _green,
                            _greenSoft,
                            tc),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (_days.every((d) => !d.isActive))
                  Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: tc.card,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.monitor_heart_outlined,
                            size: 48, color: tc.textHint),
                        const SizedBox(height: 16),
                        Text('Пока нет записей',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: tc.text)),
                        const SizedBox(height: 8),
                        Text('Запиши шаги, воду или тренировку',
                            style: TextStyle(
                                fontSize: 13, color: tc.textSecondary)),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _showAddSheet,
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Записать'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _greenDark,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18)),
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  Text('Последние дни',
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: tc.text)),
                  const SizedBox(height: 16),
                  ..._days.where((d) => d.isActive).map(
                        (d) => _buildDayCard(tc, d),
                      ),
                ],
              ],

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryItem(IconData icon, String value, String label, Color color,
      Color soft, ThemeColors tc) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: soft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(height: 8),
        Text(value,
            style: GoogleFonts.inter(
                fontSize: 18, fontWeight: FontWeight.w900, color: tc.text)),
        Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 9, color: tc.textHint, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildDayCard(ThemeColors tc, _DayActivity d) {
    final isToday = _dateKey(d.date) == _dateKey(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: tc.shadow(0.03),
              blurRadius: 12,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(_formatDate(d.date),
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: isToday ? _greenDark : tc.text)),
              const Spacer(),
              if (d.isActive)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _greenSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Активный',
                      style: TextStyle(
                          color: _greenDark,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          // Метрики
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (d.steps > 0)
                _metricChip(Icons.directions_walk_rounded,
                    _formatNumber(d.steps), 'шагов', _orange, _orangeSoft),
              if (d.waterMl > 0)
                _metricChip(Icons.water_drop_rounded, '${d.waterMl}',
                    'мл воды', _blue, _blueSoft),
              if (d.calories > 0)
                _metricChip(Icons.local_fire_department_rounded,
                    '${d.calories}', 'ккал', _pink, _pinkSoft),
              if (d.minutes > 0)
                _metricChip(
                    Icons.timer_outlined, '${d.minutes}', 'мин', _orange, _orangeSoft),
              if (d.distanceKm > 0)
                _metricChip(
                    Icons.straighten,
                    AppLocalizations.of(context)!.distanceValue(d.distanceKm),
                    AppLocalizations.of(context)!.distanceUnitLabel,
                    _green,
                    _greenSoft),
            ],
          ),
          // Упражнения
          if (d.exercises.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            ...d.exercises.map((ex) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.fitness_center_rounded,
                          size: 16, color: _greenDark),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(ex['name'] as String? ?? '',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: tc.text)),
                      ),
                      Text(
                        '${ex['sets']}×${ex['reps']}',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: _greenDark),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _metricChip(
      IconData icon, String value, String label, Color color, Color soft) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(value,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: color)),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color.withValues(alpha: 0.8))),
        ],
      ),
    );
  }
}
