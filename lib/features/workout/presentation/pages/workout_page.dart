import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumina/core/models/workout_plan.dart';
import 'package:lumina/core/services/ai_service.dart';
import 'package:lumina/core/services/user_data_service.dart';
import 'package:lumina/core/widgets/muscle_3d_viewer.dart';
import 'package:lumina/core/widgets/ux_helpers.dart';
import 'package:lumina/features/workout/presentation/pages/exercise_detail_page.dart';
import 'package:lumina/features/workout/presentation/widgets/workout_design.dart';
import 'package:lumina/features/workout/presentation/widgets/workout_equipment_sheet.dart';
import 'package:lumina/features/workout/presentation/widgets/workout_plan_views.dart';
import 'package:lumina/l10n/app_localizations.dart';

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

  EquipmentOption _equipment = equipmentOptions.firstWhere(
    (o) => o.key == 'dumbbells',
  );

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
        final option = equipmentOptions
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
    final selected = await showEquipmentSheet(context, selected: _equipment);

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
      showWelmiSnackbar(
        context,
        AppLocalizations.of(context)!.planGeneratingSnackbar(
          selected.labelOf(AppLocalizations.of(context)!),
        ),
        icon: Icons.fitness_center_rounded,
      );
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

  void _openExercise(WorkoutExercise exercise, int index, int total) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      smoothPageRoute(
        ExerciseDetailPage(exercise: exercise, index: index + 1, total: total),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WorkoutDesign.bg,
      body: SafeArea(
        child: _isLoading ? const WorkoutLoadingView() : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final plan = _plan;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        if (_error || plan == null) WorkoutErrorCard(onRetry: _loadPlan),
        WorkoutTopBar(
          onBack: () => Navigator.pop(context),
          onOpenPlan: _pickEquipment,
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        WorkoutDaySelector(
          days: plan?.days ?? const [],
          selectedIndex: _selectedDay,
          onSelect: (index) => setState(() => _selectedDay = index),
          onAdd: _pickEquipment,
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        if (plan != null) ...[
          if (!plan.days[_selectedDay].isRestDay)
            SliverToBoxAdapter(child: _buildMuscle3DView(plan)),
          SliverToBoxAdapter(child: _buildDaySection(plan)),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildMuscle3DView(WorkoutPlan plan) {
    final day = plan.days[_selectedDay];
    final mainMuscle = day.focus.split(' ')[0].replaceAll(',', '');
    final visuals = muscleVisuals(mainMuscle);

    return Muscle3DViewer(
      key: ValueKey('day_view_3d_$_selectedDay'),
      highlightColor: visuals.color,
      muscleIcon: visuals.icon,
      muscleName: day.focus.isNotEmpty
          ? day.focus
          : AppLocalizations.of(context)!.workoutGeneralFocus,
      height: 260,
    );
  }

  Widget _buildDaySection(WorkoutPlan plan) {
    final day = plan.days[_selectedDay];
    if (day.isRestDay) return const WorkoutRestDay();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.exercisesCount(day.exercises.length),
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              color: WorkoutDesign.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          for (final (index, exercise) in day.exercises.indexed)
            WorkoutExerciseCard(
              exercise: exercise,
              onTap: () => _openExercise(exercise, index, day.exercises.length),
            ),
        ],
      ),
    );
  }
}
