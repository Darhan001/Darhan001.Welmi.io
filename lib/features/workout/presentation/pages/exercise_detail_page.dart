import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumina/core/models/workout_plan.dart';
import 'package:lumina/core/services/units_service.dart';
import 'package:lumina/core/utils/number_input.dart';
import 'package:lumina/core/widgets/muscle_3d_viewer.dart';
import 'package:lumina/core/widgets/ux_helpers.dart';
import 'package:lumina/features/workout/presentation/widgets/exercise_detail_sheets.dart';
import 'package:lumina/features/workout/presentation/widgets/exercise_info_views.dart';
import 'package:lumina/features/workout/presentation/widgets/exercise_set_views.dart';
import 'package:lumina/features/workout/presentation/widgets/exercise_library.dart';
import 'package:lumina/features/workout/presentation/widgets/workout_design.dart';
import 'package:lumina/l10n/app_localizations.dart';

class ExerciseDetailPage extends StatefulWidget {
  final WorkoutExercise exercise;
  final int index;
  final int total;

  const ExerciseDetailPage({
    super.key,
    required this.exercise,
    required this.index,
    required this.total,
  });

  @override
  State<ExerciseDetailPage> createState() => _ExerciseDetailPageState();
}

class _ExerciseDetailPageState extends State<ExerciseDetailPage> {
  late WorkoutExercise _exercise;
  late List<Map<String, dynamic>> _sets;
  int _restSeconds = 0;
  Timer? _restTimer;

  @override
  void initState() {
    super.initState();
    _exercise = widget.exercise;
    _initSets();
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    super.dispose();
  }

  void _initSets() {
    final count = _exercise.sets > 0 ? _exercise.sets : 3;
    _sets = List.generate(
      count,
      (index) => {
        'reps': _exercise.reps.contains('-')
            ? _exercise.reps.split('-').last
            : _exercise.reps,
        'weight': '',
        'done': false,
      },
    );
  }

  void _startRestTimer() {
    _restTimer?.cancel();
    final seconds = _parseRestSeconds(_exercise.rest);
    setState(() => _restSeconds = seconds);
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restSeconds > 0) {
        setState(() => _restSeconds--);
      } else {
        timer.cancel();
        HapticFeedback.vibrate();
        if (mounted) {
          showWelmiSnackbar(
            context,
            AppLocalizations.of(context)!.restFinished,
            icon: Icons.notifications_active,
          );
        }
      }
    });
  }

  int _parseRestSeconds(String rest) {
    final lower = rest.toLowerCase().replaceAll(' ', '');
    if (lower.contains('мин')) {
      final min = int.tryParse(
        RegExp(r'\d+').firstMatch(lower)?.group(0) ?? '',
      );
      return min != null ? min * 60 : 60;
    }
    final sec = int.tryParse(RegExp(r'\d+').firstMatch(lower)?.group(0) ?? '');
    return sec ?? 60;
  }

  Future<void> _editCell(int setIndex, String field, String current) async {
    final result = await showSetValueEditor(
      context,
      setIndex: setIndex,
      isReps: field == 'reps',
      current: current,
    );
    if (!mounted) return;
    if (result != null && result.isNotEmpty) {
      setState(() => _sets[setIndex][field] = result);
    }
  }

  Future<void> _showReplaceSheet() async {
    final loc = AppLocalizations.of(context)!;
    final alternatives = alternativesFor(
      _exercise.muscle,
      equipment: _exercise.equipment,
    );
    final selected = await showReplaceExerciseSheet(
      context,
      muscle: _exercise.muscle,
      alternatives: alternatives,
    );

    // Экран могли закрыть, пока открыт выбор замены.
    if (!mounted) return;
    if (selected != null && selected != _exercise.name) {
      HapticFeedback.mediumImpact();
      setState(() {
        _exercise = alternativeExercise(_exercise, selected);
        _initSets();
        _restTimer?.cancel();
        _restSeconds = 0;
      });
      showWelmiSnackbar(
        context,
        loc.exerciseReplaced(selected),
        icon: Icons.swap_horiz,
      );
    }
  }

  Future<void> _saveResult() async {
    final loc = AppLocalizations.of(context)!;
    final done = _sets.where((s) => s['done'] == true).toList();
    double volume = 0;
    int repsTotal = 0;
    for (final s in done) {
      // Вес вводится в выбранных единицах и с запятой на ru/ky-клавиатуре:
      // double.tryParse('62,5') давал null, и объём считался по нулевому
      // весу. Храним объём в метрике (кг), как и остальные данные.
      final entered = parseDecimalInput(s['weight'].toString()) ?? 0;
      final weightKg = UnitsService.instance.weightFromDisplay(entered);
      final reps = parseDecimalInput(s['reps'].toString())?.round() ?? 0;
      volume += weightKg * reps;
      repsTotal += reps;
    }

    if (done.isEmpty) {
      showWelmiSnackbar(
        context,
        loc.markAtLeastOneSet,
        icon: Icons.info_outline,
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final history = (prefs.getStringList('workout_history') ?? []).toList();
      history.add(
        jsonEncode({
          'date': DateTime.now().toIso8601String().substring(0, 10),
          'exercise': _exercise.name,
          'muscle': _exercise.muscle,
          'sets_done': done.length,
          'reps': repsTotal,
          'volume': volume.round(),
          'calories': _exercise.calories * done.length,
        }),
      );
      await prefs.setStringList('workout_history', history);
    } catch (e) {
      // Раньше после ошибки всё равно показывался диалог «готово».
      debugPrint('⚠️ Workout save error: $e');
      if (mounted) {
        showWelmiSnackbar(context, loc.saveError, icon: Icons.error_outline);
      }
      return;
    }

    if (!mounted) return;
    hapticSuccess();
    await showWorkoutResultDialog(
      context,
      setsDone: done.length,
      repsTotal: repsTotal,
      volumeKg: volume.round(),
    );
  }

  void _showTipsModal(Color color) {
    showCoachTipSheet(context, color: color, tip: _exercise.tips);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final visuals = muscleVisuals(_exercise.muscle);

    // Техника: из данных упражнения или из библиотеки
    final technique = _exercise.technique.isNotEmpty
        ? _exercise.technique
        : techniqueFor(_exercise.name, _exercise.muscle);

    return Scaffold(
      backgroundColor: WorkoutDesign.exerciseBg,
      body: SafeArea(
        child: Column(
          children: [
            ExerciseDetailHeader(
              index: widget.index,
              total: widget.total,
              name: _exercise.name,
              onClose: () => Navigator.pop(context),
            ),
            if (_restSeconds > 0) ExerciseRestBanner(seconds: _restSeconds),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 280,
                      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: Muscle3DViewer(
                        key: ValueKey(
                          'main_view_${_exercise.name}_${_exercise.sets}',
                        ),
                        highlightColor: visuals.color,
                        muscleIcon: visuals.icon,
                        muscleName: _exercise.muscle,
                        height: 280,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ExerciseTechniqueCard(
                        technique: technique,
                        accent: visuals.color,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          ExerciseActionChip(
                            icon: Icons.swap_horiz,
                            label: loc.replace,
                            onTap: _showReplaceSheet,
                          ),
                          const SizedBox(width: 8),
                          ExerciseActionChip(
                            icon: Icons.sports_gymnastics,
                            label: loc.coachTip,
                            onTap: () => _showTipsModal(visuals.color),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ExerciseInfoCard(exercise: _exercise),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          const ExerciseSetTableHeader(),
                          const SizedBox(height: 12),
                          for (var i = 0; i < _sets.length; i++)
                            ExerciseSetRow(
                              index: i,
                              reps: _sets[i]['reps'].toString(),
                              weight: _sets[i]['weight'].toString(),
                              isDone: _sets[i]['done'] == true,
                              canRemove: _sets.length > 1,
                              accent: visuals.color,
                              onEditReps: () => _editCell(
                                i,
                                'reps',
                                _sets[i]['reps'].toString(),
                              ),
                              onEditWeight: () => _editCell(
                                i,
                                'weight',
                                _sets[i]['weight'].toString(),
                              ),
                              onToggle: () {
                                final wasDone = _sets[i]['done'] == true;
                                setState(() => _sets[i]['done'] = !wasDone);
                                if (!wasDone) _startRestTimer();
                              },
                              onRemove: () => setState(() => _sets.removeAt(i)),
                            ),
                          const SizedBox(height: 12),
                          ExerciseAddSetButton(
                            onTap: () => setState(
                              () => _sets.add({
                                'reps': '10',
                                'weight': '',
                                'done': false,
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ExerciseSaveButton(onPressed: _saveResult),
    );
  }
}
