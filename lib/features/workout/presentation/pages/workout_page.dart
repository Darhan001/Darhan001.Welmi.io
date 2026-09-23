import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumina/core/models/workout_plan.dart';
import 'package:lumina/core/services/ai_service.dart';
import 'package:lumina/core/services/user_data_service.dart';
import 'package:lumina/core/widgets/ux_helpers.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:lumina/core/widgets/muscle_3d_viewer.dart';
import 'package:lumina/features/workout/presentation/pages/exercise_detail_page.dart';

// ─── Premium design tokens ────────────────────────────────────
class _Design {
  static const Color bg = Color(0xFF0F0F0F);
  static const Color card = Color(0xFF1A1A1A);
  static const Color cardBorder = Color(0xFF2A2A2A);
  static const Color lime = Color(0xFFD4FF44);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF8A8A8A);
  static const Color textMuted = Color(0xFF555555);
  static const double radiusLg = 28;
  static const double radiusMd = 20;
  static const double radiusSm = 14;
}

/// Варианты условий тренировок — что есть у пользователя дома.
class _EquipmentOption {
  final String key;
  final String label;
  final String subtitle;
  final String aiString;
  final IconData icon;
  final Color color;

  const _EquipmentOption({
    required this.key,
    required this.label,
    required this.subtitle,
    required this.aiString,
    required this.icon,
    required this.color,
  });
}

const _equipmentOptions = [
  _EquipmentOption(
    key: 'bodyweight',
    label: 'No equipment',
    subtitle: 'Только вес тела: отжимания, приседания, планка',
    aiString: 'собственный вес, без инвентаря (отжимания, приседания, планка)',
    icon: Icons.self_improvement_rounded,
    color: Color(0xFF75A47F),
  ),
  _EquipmentOption(
    key: 'dumbbells',
    label: 'Гантели',
    subtitle: 'Набор гантелей для домашних тренировок',
    aiString: 'гантели (домашняя тренировка)',
    icon: Icons.fitness_center_rounded,
    color: Color(0xFFEF9A9A),
  ),
  _EquipmentOption(
    key: 'calisthenics',
    label: 'Турник и резинки',
    subtitle: 'Турник, фитнес-резинки, коврик',
    aiString: 'турник, фитнес-резинки и коврик (дома)',
    icon: Icons.sports_gymnastics_rounded,
    color: Color(0xFF64B5F6),
  ),
  _EquipmentOption(
    key: 'gym',
    label: 'Спортзал',
    subtitle: 'Штанга, гантели, тренажёры — полный зал',
    aiString: 'тренажёрный зал: штанга, гантели, тренажёры',
    icon: Icons.apartment_rounded,
    color: Color(0xFFFFB74D),
  ),
];

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key});

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  final UserDataService _userData = UserDataService();
  final AiService _ai = AiService();

  bool _isLoading = true;
  bool _error = false;
  WorkoutPlan? _plan;
  int _selectedDay = 0;

  _EquipmentOption _equipment = _equipmentOptions
      .firstWhere((o) => o.key == 'dumbbells');

  static const _prefsKey = 'workout_equipment_key';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _restoreEquipment();
    if (mounted) _loadPlan();
  }

  Future<void> _restoreEquipment() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      if (saved != null) {
        final option = _equipmentOptions
            .where((o) => o.key == saved)
            .firstOrNull;
        if (option != null && mounted) {
          setState(() => _equipment = option);
        }
      }
    } catch (e) {
      debugPrint('⚠️ Equipment restore error: $e');
    }
  }

  Future<void> _pickEquipment() async {
    final selected = await showModalBottomSheet<_EquipmentOption>(
      context: context,
      backgroundColor: _Design.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(_Design.radiusLg)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [               Text(AppLocalizations.of(context)!.whereDoYouTrain,
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: _Design.textPrimary)),
              const SizedBox(height: 4),               Text(AppLocalizations.of(context)!.trainSubtitle,
                  style: GoogleFonts.inter(fontSize: 12, color: _Design.textSecondary)),
              const SizedBox(height: 16),
              ..._equipmentOptions.map((o) {
                final isSel = o.key == _equipment.key;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.pop(ctx, o);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSel
                          ? _Design.lime.withValues(alpha: 0.08)
                          : _Design.card,
                      borderRadius: BorderRadius.circular(_Design.radiusMd),
                      border: Border.all(
                        color: isSel
                            ? _Design.lime.withValues(alpha: 0.4)
                            : _Design.cardBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: _Design.lime.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(_Design.radiusSm),
                          ),
                          child: Icon(o.icon, size: 20, color: _Design.lime),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(o.label,
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: _Design.textPrimary)),
                              Text(o.subtitle,
                                  style: GoogleFonts.inter(
                                      fontSize: 11, color: _Design.textSecondary)),
                            ],
                          ),
                        ),
                        isSel
                            ? Icon(Icons.check_circle_rounded, size: 18, color: _Design.lime)
                            : const SizedBox(width: 18),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );

    if (selected == null || selected.key == _equipment.key) return;
    HapticFeedback.mediumImpact();
    setState(() => _equipment = selected);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, selected.key);
    } catch (e) {
      debugPrint('⚠️ Equipment save error: $e');
    }
    if (mounted) {
      showWelmiSnackbar(context, AppLocalizations.of(context)!.planGeneratingSnackbar(selected.label),
          icon: Icons.fitness_center_rounded);
    }
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    setState(() => _isLoading = true);
    await _userData.loadAll();
    await _fetchPlan();
  }

  Future<void> _fetchPlan() async {
    try {
      final profile = _userData.profile;
      final goal = profile?.goal?.name ?? 'maintainWeight';
      final gender = profile?.gender?.name ?? 'male';
      final heightCm = profile?.heightCm ?? 175;
      final currentWeightKg =
          _userData.latestWeight ?? profile?.currentWeightKg ?? 70;
      final age = profile?.age ?? 25;
      final activityLevel = profile?.activityLevel?.name ?? 'moderate';

      final plan = await _ai.generateWorkoutPlan(
        goal: goal,
        gender: gender,
        heightCm: heightCm,
        currentWeightKg: currentWeightKg,
        age: age,
        activityLevel: activityLevel,
        equipment: _equipment.aiString,
      );

      if (mounted) {
        setState(() {
          _plan = plan;
          _error = false;
          _isLoading = false;
          if (_selectedDay >= plan.days.length) _selectedDay = 0;
        });
      }
    } catch (e) {
      debugPrint('⚠️ Workout plan error: $e');
      if (mounted) {
        setState(() {
          _error = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Design.bg,
      body: SafeArea(
        child: _isLoading ? _buildLoading() : _buildContent(),
      ),
    );
  }

  // ─── Loading State ─────────────────────────────────────────
  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pulsing lime ring
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _Design.lime.withValues(alpha: 0.15), width: 3),
            ),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(
                color: _Design.lime,
                strokeWidth: 2.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(AppLocalizations.of(context)!.generatingPlan,
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700, fontSize: 16, color: _Design.textPrimary)),
          const SizedBox(height: 6),
          Text(AppLocalizations.of(context)!.aiAnalyzing,
              style: GoogleFonts.inter(fontSize: 12, color: _Design.textSecondary)),
        ],
      ),
    );
  }

  // ─── Main Content ──────────────────────────────────────────
  Widget _buildContent() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        if (_error || _plan == null) _buildErrorCard(),
        _buildTopBar(),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        _buildDaySelector(),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        if (_plan != null) ...[
          if (!_plan!.days[_selectedDay].isRestDay)
            SliverToBoxAdapter(child: _buildMuscle3DView()),
          SliverToBoxAdapter(child: _buildDaySection()),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  // ─── Top Bar: Pill widget + Avatar ─────────────────────────
  Widget _buildTopBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
        child: Row(
          children: [
            // Back button
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: _Design.textPrimary, size: 20),
            ),
            // Pill widget: icon + "Мой план: Неделя 2" + arrow
            GestureDetector(
              onTap: _pickEquipment,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _Design.card,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: _Design.cardBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.directions_run_rounded, size: 16, color: _Design.lime),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.myPlan,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _Design.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.chevron_right, size: 16, color: _Design.textSecondary),
                  ],
                ),
              ),
            ),
            const Spacer(),
            // Profile avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _Design.card,
                border: Border.all(color: _Design.cardBorder),
              ),
              child: Center(
                child: Icon(Icons.person_outline_rounded, size: 20, color: _Design.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Day Selector (horizontal tabs) ────────────────────────
  Widget _buildDaySelector() {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 60,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: (_plan?.days.length ?? 0) + 1, // +1 for "add" button
          itemBuilder: (context, index) {
            if (index == 0) {
              // Plus circle button
              return GestureDetector(
                onTap: () => _pickEquipment(),
                child: Container(
                  width: 56,
                  height: 56,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _Design.lime.withValues(alpha: 0.1),
                    border: Border.all(color: _Design.lime.withValues(alpha: 0.2)),
                  ),
                  child: Icon(Icons.add, color: _Design.lime, size: 22),
                ),
              );
            }
            final dayIndex = index - 1;
            final day = _plan!.days[dayIndex];
            final isSelected = dayIndex == _selectedDay;
            final label = day.day.length > 3 ? day.day.substring(0, 3) : day.day;

            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _selectedDay = dayIndex);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                height: 56,
                decoration: BoxDecoration(
                  color: isSelected
                      ? _Design.lime.withValues(alpha: 0.12)
                      : _Design.card,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isSelected ? _Design.lime : _Design.cardBorder,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    label.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? _Design.lime : _Design.textSecondary,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── 3D Muscle View ────────────────────────────────────────
  Widget _buildMuscle3DView() {
    final day = _plan!.days[_selectedDay];
    final mainMuscle = day.focus.split(' ')[0].replaceAll(',', '');
    final visuals = _muscleVisuals(mainMuscle);
    return Muscle3DViewer(
      key: ValueKey('day_view_3d_${_selectedDay}'),
      highlightColor: visuals.color,
      muscleIcon: visuals.icon,
      muscleName: day.focus.isNotEmpty ? day.focus : 'Общая',
      height: 260,
    );
  }

  // ─── Day Section (exercises list) ──────────────────────────
  Widget _buildDaySection() {
    final day = _plan!.days[_selectedDay];
    if (day.isRestDay) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.hotel_rounded, size: 48, color: _Design.lime.withValues(alpha: 0.3)),
              const SizedBox(height: 16),               Text(AppLocalizations.of(context)!.restDay,
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700, fontSize: 18, color: _Design.textPrimary)),
              const SizedBox(height: 6),               Text(AppLocalizations.of(context)!.restDaySubtitle,
                  style: GoogleFonts.inter(fontSize: 13, color: _Design.textSecondary)),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title: "Упражнения — 5"
          Text(             AppLocalizations.of(context)!.exercisesCount(day.exercises.length),
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              color: _Design.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          // Exercise cards
          ...day.exercises.asMap().entries.map((entry) {
            return _buildExerciseCard(entry.key, entry.value, day.exercises.length);
          }),
        ],
      ),
    );
  }

  // ─── Exercise Card ─────────────────────────────────────────
  Widget _buildExerciseCard(int index, WorkoutExercise ex, int total) {
    final visuals = _muscleVisuals(ex.muscle);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(context, smoothPageRoute(
          ExerciseDetailPage(exercise: ex, index: index + 1, total: total),
        ));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _Design.card,
          borderRadius: BorderRadius.circular(_Design.radiusMd),
          border: Border.all(color: _Design.cardBorder),
        ),
        child: Row(
          children: [
            // Dark icon placeholder (60x60, rounded 16)
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _Design.lime.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(visuals.icon, size: 26, color: _Design.lime),
            ),
            const SizedBox(width: 14),
            // Text: name + sets info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ex.name,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: _Design.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${ex.sets} х ${ex.reps}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: _Design.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: _Design.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  // ─── Error Card ────────────────────────────────────────────
  Widget _buildErrorCard() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(_Design.radiusMd),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_rounded, color: Colors.orange, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(                 AppLocalizations.of(context)!.failedToLoadPlan,
                style: GoogleFonts.inter(
                    color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
              onPressed: _loadPlan,               child: Text(AppLocalizations.of(context)!.retry,
                  style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Muscle Visuals Helper ─────────────────────────────────
  ({IconData icon, Color color}) _muscleVisuals(String muscle) {
    final m = muscle.toLowerCase();
    if (m.contains('груд')) return (icon: Icons.accessibility_new_rounded, color: const Color(0xFFEF5350));
    if (m.contains('спин')) return (icon: Icons.airline_seat_recline_normal_rounded, color: const Color(0xFF42A5F5));
    if (m.contains('ног') || m.contains('ягод')) return (icon: Icons.directions_run_rounded, color: const Color(0xFFAB47BC));
    return (icon: Icons.fitness_center_rounded, color: _Design.lime);
  }
}
