import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/services/units_service.dart';
import 'package:lumina/core/utils/number_input.dart';
import 'package:lumina/core/widgets/units_format.dart';
import 'package:lumina/core/services/auth_service.dart';
import 'package:lumina/core/services/daily_tracker.dart';
import 'package:lumina/core/services/user_data_service.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/ux_helpers.dart';
import 'package:lumina/core/models/supabase_models.dart';
import 'package:lumina/l10n/app_localizations.dart';

class GoalPage extends StatefulWidget {
  const GoalPage({super.key});

  @override
  State<GoalPage> createState() => _GoalPageState();
}

class _GoalPageState extends State<GoalPage>
    with SingleTickerProviderStateMixin {
  final UserDataService _userData = UserDataService();

  late AnimationController _animController;
  bool _isLoading = true;
  String _aiInsight = '';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
    _loadData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await _userData.loadAll();
    _generateAiInsight();
    if (mounted) setState(() => _isLoading = false);
  }

  void _generateAiInsight() {
    final profile = _userData.profile;
    if (profile == null) {
      _aiInsight = 'Заполни профиль, чтобы получить персональные инсайты ✨';
      return;
    }

    final loss = _totalLoss;
    final remaining = _remaining;
    final avgPerDay = _avgLossPerDay;

    if (loss <= 0 && remaining <= 0) {
      _aiInsight = 'Начни записывать вес, чтобы увидеть прогресс! 🚀';
    } else if (avgPerDay > 0.1) {
      _aiInsight =
          'Отличный темп! ${_estimatedDaysToGoal > 0 ? 'Достигнешь цели через ~$_estimatedDaysToGoal дней 🎯' : 'Ты уже почти у цели!'}';
    } else if (avgPerDay > 0.03) {
      _aiInsight =
          'Хороший устойчивый прогресс. Продолжай в том же духе! 💪';
    } else if (remaining > 5) {
      _aiInsight =
          'Прогресс идёт медленно. Попробуй увеличить активность или скорректировать питание. 📈';
    } else {
      _aiInsight =
          'Ты на верном пути! Маленькие шаги ведут к большим результатам. 🌟';
    }
  }

  double get _startWeight => _userData.startWeight ?? 72.0;
  double get _currentWeight => _userData.latestWeight ?? _startWeight;
  double get _goalWeight => _userData.goalWeight ?? 65.0;

  /// Прогресс к цели (работает и для похудения, и для набора веса)
  double get _progress {
    final start = _startWeight;
    final goal = _goalWeight;
    final current = _currentWeight;
    if (goal > start) {
      // Набор массы
      return ((current - start) / (goal - start)).clamp(0.0, 1.0);
    }
    if (goal < start) {
      // Похудение
      return ((start - current) / (start - goal)).clamp(0.0, 1.0);
    }
    return 0.0;
  }

  double get _totalLoss => _startWeight - _currentWeight;

  /// Сколько осталось до цели (в кг), без учёта направления
  double get _remaining {
    final diff = (_currentWeight - _goalWeight).abs();
    return diff.clamp(0.0, 999.0);
  }

  /// Дней с первой записи веса (минимум 1 день, если запись есть)
  int get _daysIn {
    if (_userData.weightEntries.isEmpty) return 0;
    final first = _userData.weightEntries.last.date;
    final days = DateTime.now().difference(first).inDays;
    return days < 1 ? 1 : days;
  }

  /// Среднее изменение веса в день по факту (может быть отрицательным)
  double get _avgLossPerDay => _daysIn > 0 ? _totalLoss / _daysIn : 0;

  /// Запланированный темп из профиля (кг/день)
  double get _plannedPacePerDay {
    final speed = _userData.profile?.goalSpeedKgPerWeek ?? 0.5;
    return speed / 7;
  }

  /// Прогноз дней до цели: по факту (с учётом направления), иначе по плану
  int get _estimatedDaysToGoal {
    final goal = _userData.profile?.goal;
    if (goal == null || goal == GoalType.maintainWeight) return 0;
    if (_remaining <= 0) return 0;
    // Фактический темп в направлении к цели:
    // при похудении totalLoss положительный, при наборе — отрицательный.
    final actualPace = goal == GoalType.gainWeight
        ? -_avgLossPerDay
        : _avgLossPerDay;
    final pace = actualPace > 0.001 ? actualPace : _plannedPacePerDay;
    if (pace <= 0) return 0;
    return (_remaining / pace).round();
  }

  List<Map<String, dynamic>> get _milestones {
    final entries = _userData.weightEntries;
    final list = <Map<String, dynamic>>[];
    final limited = entries.take(5).toList();
    for (int i = 0; i < limited.length; i++) {
      final e = limited[i];
      final isFirst = i == 0;
      list.add({
        'label': AppLocalizations.of(context)!.formatWeight(e.weightKg),
        'date': _formatDate(e.date),
        'done': true,
        'first': isFirst,
      });
    }
    if (_currentWeight > _goalWeight) {
      list.add({
        'label': '${AppLocalizations.of(context)!.formatWeight(_goalWeight)} 🎯',
        'date': _estimatedDaysToGoal > 0
            ? '~$_estimatedDaysToGoal дн'
            : 'Цель!',
        'done': false,
        'first': false,
      });
    }
    return list;
  }

  String _formatDate(DateTime date) {
    const months = [
      'янв', 'фев', 'мар', 'апр', 'май', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    return ListenableBuilder(
      listenable: _userData,
      builder: (context, _) {
        if (_isLoading) {
          return Scaffold(
            backgroundColor: tc.background,
            body: SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: tc.primary),
                    const SizedBox(height: 16),
                    Text('Загружаем данные...',
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
                children: [
                  const SizedBox(height: 10),
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
                            boxShadow: [
                              BoxShadow(
                                color: tc.shadow(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child:
                              Icon(Icons.arrow_back, size: 22, color: tc.text),
                        ),
                      ),                       Text(AppLocalizations.of(context)!.goalTitle,
                          style: GoogleFonts.notoSerif(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              color: tc.text)),
                      GestureDetector(
                        onTap: () => _showEditGoalDialog(tc),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: tc.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.edit_outlined,
                              size: 18, color: tc.textOnPrimary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildGoalTypeCard(tc),
                  const SizedBox(height: 16),
                  _buildProgressRing(tc),
                  const SizedBox(height: 16),
                  _buildWeightComparison(tc),
                  const SizedBox(height: 24),
                  _buildMilestoneTimeline(tc),
                  const SizedBox(height: 24),
                  _buildDailyStats(tc),
                  const SizedBox(height: 24),
                  _buildAiInsightCard(tc),
                  const SizedBox(height: 16),
                  _buildMotivationCard(tc),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showEditGoalDialog(ThemeColors tc) {
    final existing = _userData.profile;
    GoalType? selectedGoal = existing?.goal;
    double selectedSpeed = existing?.goalSpeedKgPerWeek ?? 0.5;
    final targetCtl =
        TextEditingController(text: AppLocalizations.of(context)!.weightValue(_goalWeight));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) => Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 32,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
          ),
          decoration: BoxDecoration(
            color: tc.card,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SingleChildScrollView(
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
                const SizedBox(height: 24),
                Center(
                  child: Text('Изменить цель',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: tc.text)),
                ),
                const SizedBox(height: 28),
                _dialogSectionLabel('Тип цели', tc),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildDialogGoalChip(tc, GoalType.loseWeight,
                          '🔥', 'Похудение', selectedGoal == GoalType.loseWeight,
                          () => setSheetState(() => selectedGoal = GoalType.loseWeight)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDialogGoalChip(tc, GoalType.maintainWeight,
                          '⚖️', 'Поддерж.', selectedGoal == GoalType.maintainWeight,
                          () => setSheetState(() => selectedGoal = GoalType.maintainWeight)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDialogGoalChip(tc, GoalType.gainWeight,
                          '💪', 'Набор', selectedGoal == GoalType.gainWeight,
                          () => setSheetState(() => selectedGoal = GoalType.gainWeight)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _dialogSectionLabel('Целевой вес', tc),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 140,
                      child: TextField(
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        controller: targetCtl,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: tc.text),
                        decoration: InputDecoration(
                          enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: tc.divider)),
                          focusedBorder: const UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: Color(0xFF75A47F), width: 2)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context)!.weightUnitLabel,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: tc.textHint)),
                  ],
                ),
                const SizedBox(height: 24),
                _dialogSectionLabel('Скорость (кг/нед)', tc),
                const SizedBox(height: 12),
                Row(
                  children: [0.25, 0.5, 0.75, 1.0].map((speed) {
                    final isSel = selectedSpeed == speed;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: GestureDetector(
                          onTap: () =>
                              setSheetState(() => selectedSpeed = speed),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? const Color(0xFFE8F3E5)
                                  : tc.text.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSel
                                    ? const Color(0xFF4A8C5C)
                                    : tc.text.withValues(alpha: 0.06),
                                width: isSel ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  speed.toString(),
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                    color: isSel
                                        ? const Color(0xFF4A8C5C)
                                        : tc.text,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text('кг/нед',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: isSel
                                          ? const Color(0xFF4A8C5C)
                                          : tc.textHint,
                                      fontWeight: FontWeight.w600,
                                    )),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final entered = parseDecimalInput(targetCtl.text);
                      final val = entered == null ? null : UnitsService.instance.weightFromDisplay(entered);
                      if (val == null || !isPlausibleWeightKg(val)) {
                        showWelmiSnackbar(context,
                            'Введите корректный целевой вес',
                            icon: Icons.error_outline);
                        return;
                      }
                      if (selectedGoal == null) {
                        showWelmiSnackbar(context, 'Выберите тип цели',
                            icon: Icons.error_outline);
                        return;
                      }
                      final auth = AuthService();
                      final userId = auth.userId ?? existing?.id;
                      if (userId == null || userId.isEmpty) {
                        showWelmiSnackbar(context,
                            '❌ Не удалось определить пользователя',
                            icon: Icons.error_outline);
                        return;
                      }
                      final newProfile = UserProfile(
                        id: userId,
                        displayName: existing?.displayName ?? auth.displayName,
                        email: existing?.email ?? auth.email,
                        photoUrl: existing?.photoUrl ?? auth.photoUrl,
                        heightCm: existing?.heightCm ?? 175,
                        currentWeightKg: existing?.currentWeightKg ?? 72,
                        targetWeightKg: val,
                        gender: existing?.gender,
                        goal: selectedGoal,
                        activityLevel: existing?.activityLevel,
                        goalSpeedKgPerWeek: selectedSpeed,
                        birthDate: existing?.birthDate ?? DateTime(1995, 1, 1),
                        subscriptionTier: existing?.subscriptionTier,
                        subscriptionExpiresAt: existing?.subscriptionExpiresAt,
                        unitsSystem: existing?.unitsSystem,
                        notificationPrefs: existing?.notificationPrefs,
                      );
                      try {
                        await _userData.saveProfile(newProfile);
                        // loadToday пересчитывает цели калорий/БЖУ из профиля,
                        // так что главная обновится сразу после изменения цели
                        await DailyTracker().loadToday();
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          showWelmiSnackbar(context, '✅ Цель обновлена!',
                              icon: Icons.check_circle);
                        }
                        await _loadData();
                      } catch (e) {
                        if (ctx.mounted) {
                          showWelmiSnackbar(ctx, '❌ Ошибка сохранения',
                              icon: Icons.error_outline);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tc.primary,
                      foregroundColor: tc.textOnPrimary,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('Сохранить',
                        style:
                            TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dialogSectionLabel(String text, ThemeColors tc) {
    return Text(text,
        style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700, color: tc.textHint));
  }

  Widget _buildDialogGoalChip(ThemeColors tc, GoalType goal, String emoji,
      String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFE8F3E5)
              : tc.text.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4A8C5C)
                : tc.text.withValues(alpha: 0.06),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 6),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 11,
                  color: isSelected ? const Color(0xFF4A8C5C) : tc.text,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalTypeCard(ThemeColors tc) {
    final goal = _userData.profile?.goal;
    final goalLabel = switch (goal) {       GoalType.loseWeight => AppLocalizations.of(context)!.goalWeightLoss,
      GoalType.gainWeight => AppLocalizations.of(context)!.goalGainWeight,
      GoalType.maintainWeight => AppLocalizations.of(context)!.goalMaintain,
      null => AppLocalizations.of(context)!.goalNotSelected,
    };
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F3E5),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.fitness_center,
                color: Color(0xFF75A47F), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [                 Text(AppLocalizations.of(context)!.goalTypeLabel,
                    style: TextStyle(
                        fontSize: 10,
                        color: tc.textHint,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(goalLabel,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: tc.text,
                    )),
                const SizedBox(height: 2),
                Text(
                  goal == null
                      ? 'Нажми ✏️, чтобы выбрать цель'
                      : goal == GoalType.maintainWeight
                          ? 'Поддержание текущего веса'
                          : _estimatedDaysToGoal > 0
                              ? '~$_estimatedDaysToGoal дней до цели'
                              : _daysIn > 0
                                  ? '$_daysIn дней с начала пути'
                                  : AppLocalizations.of(context)!.goalTargetWeight(AppLocalizations.of(context)!.formatWeight(_goalWeight)),
                    style: TextStyle(fontSize: 12, color: tc.textHint)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRing(ThemeColors tc) {
    final progress = _progress;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(32),
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
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return SizedBox(
                width: 200,
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 12,
                      backgroundColor: tc.text.withValues(alpha: 0.05),
                      color: Colors.transparent,
                    ),
                    CircularProgressIndicator(
                      value: progress * _animController.value,
                      strokeWidth: 12,
                      backgroundColor: Colors.transparent,
                      color: const Color(0xFF75A47F),
                      strokeCap: StrokeCap.round,
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${(progress * 100).toStringAsFixed(0)}%',
                            style: GoogleFonts.inter(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF4A8C5C),
                            )),                         Text(AppLocalizations.of(context)!.completed,
                            style: TextStyle(
                              fontSize: 12,
                              color: tc.textHint,
                              fontWeight: FontWeight.w600,
                            )),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildRingStat(                   AppLocalizations.of(context)!.formatWeight(_startWeight), AppLocalizations.of(context)!.start, tc),
              _buildRingStat(
                  AppLocalizations.of(context)!.formatWeight(_totalLoss),
                  'Потеряно',
                  tc,
                  isHighlight: true),
              _buildRingStat(
                  AppLocalizations.of(context)!.formatWeight(_goalWeight), 'Цель', tc),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRingStat(String value, String label, ThemeColors tc,
      {bool isHighlight = false}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlight ? 20 : 16,
            fontWeight: FontWeight.w900,
            color: isHighlight
                ? const Color(0xFF4A8C5C)
                : tc.text,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: tc.textHint,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildWeightComparison(ThemeColors tc) {
    final maxWeight = (_startWeight + 2).clamp(_currentWeight + 2, 200.0);
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Сравнение',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: tc.text)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildWeightBar(
                  'Было',
                  _startWeight,
                  maxWeight,
                  Colors.black26,
                  tc,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildWeightBar(
                  'Сейчас',
                  _currentWeight,
                  maxWeight,
                  const Color(0xFF75A47F),
                  tc,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildWeightBar(
                  'Цель',
                  _goalWeight,
                  maxWeight,
                  const Color(0xFF4A8C5C),
                  tc,
                  isGoal: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeightBar(String label, double weight, double maxWeight,
      Color color, ThemeColors tc,
      {bool isGoal = false}) {
    final height = (weight / maxWeight * 140).clamp(40.0, 140.0);
    return Column(
      children: [
        AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              height: isGoal
                  ? 140 - (140 - height) * _animController.value
                  : height,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    color,
                    color.withValues(alpha: 0.6),
                  ],
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)!.weightValue(weight),
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: tc.text,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: tc.textHint,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildMilestoneTimeline(ThemeColors tc) {
    final milestones = _milestones;
    if (milestones.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Вехи прогресса',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: tc.text)),
          const SizedBox(height: 20),
          ...List.generate(milestones.length, (i) {
            final milestone = milestones[i];
            final isLast = i == milestones.length - 1;
            final isDone = milestone['done'] as bool;
            final isFirst = milestone['first'] as bool? ?? false;
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    child: Column(
                      children: [
                        Container(
                          width: i == 0 ? 0 : 2,
                          height: 8,
                          color: isDone
                              ? const Color(0xFF75A47F)
                              : tc.text.withValues(alpha: 0.08),
                        ),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDone
                                ? const Color(0xFF75A47F)
                                : tc.card,
                            border: Border.all(
                              color: isDone
                                  ? const Color(0xFF75A47F)
                                  : tc.text.withValues(alpha: 0.15),
                              width: 2,
                            ),
                          ),
                          child: isDone
                              ? const Icon(Icons.check,
                                  size: 12, color: Colors.white)
                              : null,
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: isDone
                                  ? const Color(0xFF75A47F)
                                  : tc.text.withValues(alpha: 0.08),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            milestone['label'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight:
                                  isDone ? FontWeight.w800 : FontWeight.w600,
                              color: isDone
                                  ? tc.text
                                  : tc.textHint,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            milestone['date'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDone ? tc.textHint : tc.textHint,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isFirst)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F3E5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Старт',
                          style: TextStyle(
                              color: Color(0xFF75A47F),
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Что показывать в карточке «В среднем»: факт, план или «—»
  String get _avgDisplay {
    if (_daysIn > 0 && _avgLossPerDay.abs() >= 0.005) {
      final goal = _userData.profile?.goal;
      // При наборе массы totalLoss отрицательный — показываем темп набора
      final value =
          goal == GoalType.gainWeight ? -_avgLossPerDay : _avgLossPerDay;
      return '${value.toStringAsFixed(2)} кг/день';
    }
    final goal = _userData.profile?.goal;
    if (goal == GoalType.loseWeight || goal == GoalType.gainWeight) {
      return '≈${_plannedPacePerDay.toStringAsFixed(2)} кг/день';
    }
    return '—';
  }

  Widget _buildDailyStats(ThemeColors tc) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'В среднем',
            _avgDisplay,
            Icons.trending_down,
            const Color(0xFF75A47F),
            tc,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Осталось дней',
            _estimatedDaysToGoal > 0 ? '$_estimatedDaysToGoal' : '—',
            Icons.calendar_today,
            Colors.blueGrey,
            tc,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon,
      Color color, ThemeColors tc) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: tc.textHint,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiInsightCard(ThemeColors tc) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E281E) : const Color(0xFFE8F3E5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: const Color(0xFF75A47F).withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF75A47F).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome,
                color: Color(0xFF75A47F), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welmi AI',
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: isDark ? const Color(0xFF8BC98E) : const Color(0xFF4A8C5C),
                        fontSize: 13)),
                const SizedBox(height: 4),
                Text(_aiInsight,
                    style: TextStyle(
                        fontSize: 13,
                        color: tc.text,
                        fontWeight: FontWeight.w600,
                        height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationCard(ThemeColors tc) {
    final quotes = [
      'Маленькие шаги ведут к большим результатам 🌱',
      'Ты уже на пути к своей цели — продолжай! 💪',
      'Каждый день — это шанс стать лучше ✨',
      'Твоё тело — твой самый верный проект 🏗️',
      'Никогда не сдавайся. Великие вещи требуют времени ⏳',
    ];
    final quote = quotes[DateTime.now().day % quotes.length];
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A8C5C), Color(0xFF75A47F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF75A47F).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),                         Text(AppLocalizations.of(context)!.motivation,
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            quote,
            style: GoogleFonts.notoSerif(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Welmi',
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
