import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumina/core/models/workout_plan.dart';
import 'package:lumina/core/widgets/muscle_3d_viewer.dart';
import 'package:lumina/core/widgets/ux_helpers.dart';
import 'package:lumina/features/workout/presentation/widgets/exercise_library.dart';
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
    _sets = List.generate(count, (index) => {
      'reps': _exercise.reps.contains('-')
          ? _exercise.reps.split('-').last
          : _exercise.reps,
      'weight': '',
      'done': false,
    });
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
      final min = int.tryParse(RegExp(r'\d+').firstMatch(lower)?.group(0) ?? '');
      return min != null ? min * 60 : 60;
    }
    final sec = int.tryParse(RegExp(r'\d+').firstMatch(lower)?.group(0) ?? '');
    return sec ?? 60;
  }

  ({IconData icon, Color color}) _muscleVisuals(String muscle) {
    final m = muscle.toLowerCase();
    if (m.contains('груд')) return (icon: Icons.accessibility_new_rounded, color: const Color(0xFFEF5350));
    if (m.contains('спин')) return (icon: Icons.airline_seat_recline_normal_rounded, color: const Color(0xFF42A5F5));
    if (m.contains('ног') || m.contains('ягод')) return (icon: Icons.directions_run_rounded, color: const Color(0xFFAB47BC));
    return (icon: Icons.fitness_center_rounded, color: const Color(0xFFC6FF00));
  }

  Future<void> _editCell(int setIndex, String field, String current, {bool numeric = true}) async {
    final controller = TextEditingController(text: current);
    final loc = AppLocalizations.of(context)!;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          field == 'reps' ? loc.repsInSet(setIndex + 1) : loc.weightInKg(setIndex + 1),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: numeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
          decoration: InputDecoration(
            hintText: field == 'reps' ? loc.exampleReps : loc.exampleWeight,
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: Colors.black38,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(loc.cancel, style: const TextStyle(color: Colors.white54))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC6FF00), foregroundColor: Colors.black),
            child: Text(loc.done, style: const TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _sets[setIndex][field] = result);
    }
  }

  Future<void> _showReplaceSheet() async {
    final loc = AppLocalizations.of(context)!;
    final alternatives = alternativesFor(_exercise.muscle, equipment: _exercise.equipment);
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Text(loc.replaceExercise,
                  style: GoogleFonts.notoSerif(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: Text(loc.alternativesForMuscle(_exercise.muscle),
                  style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
            ...alternatives.map((name) => ListTile(
                  onTap: () => Navigator.pop(ctx, name),
                  leading: const Icon(Icons.fitness_center_rounded, color: Color(0xFFC6FF00), size: 20),
                  title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                )),
            const SizedBox(height: 12),
          ],
        ),
      ),
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
      showWelmiSnackbar(context, loc.exerciseReplaced(selected), icon: Icons.swap_horiz);
    }
  }

  Future<void> _saveResult() async {
    final loc = AppLocalizations.of(context)!;
    final done = _sets.where((s) => s['done'] == true).toList();
    double volume = 0;
    int repsTotal = 0;
    for (final s in done) {
      final weight = double.tryParse(s['weight'].toString()) ?? 0;
      final reps = int.tryParse(s['reps'].toString()) ?? 0;
      volume += weight * reps;
      repsTotal += reps;
    }

    if (done.isEmpty) {
      showWelmiSnackbar(context, loc.markAtLeastOneSet, icon: Icons.info_outline);
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final history = (prefs.getStringList('workout_history') ?? []).toList();
      history.add(jsonEncode({
        'date': DateTime.now().toIso8601String().substring(0, 10),
        'exercise': _exercise.name,
        'muscle': _exercise.muscle,
        'sets_done': done.length,
        'reps': repsTotal,
        'volume': volume.round(),
        'calories': _exercise.calories * done.length,
      }));
      await prefs.setStringList('workout_history', history);
    } catch (e) {
      debugPrint('⚠️ Workout save error: $e');
    }

    if (!mounted) return;
    hapticSuccess();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Color(0xFFC6FF00), size: 56),
            const SizedBox(height: 16),
            Text(loc.workoutRecorded, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildResultStat('${done.length}', loc.sets),
                _buildResultStat('$repsTotal', loc.repsLabel),
                _buildResultStat('${volume.round()} ${loc.kgLabel}', loc.volume),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC6FF00), foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: Text(loc.great, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.inter(color: const Color(0xFFC6FF00), fontSize: 20, fontWeight: FontWeight.w900)),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w700)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final visuals = _muscleVisuals(_exercise.muscle);

    // Техника: из данных упражнения или из библиотеки
    final technique = _exercise.technique.isNotEmpty
        ? _exercise.technique
        : techniqueFor(_exercise.name, _exercise.muscle);

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Column(
          children: [
            // ─── ШАПКА ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: Colors.white, size: 24),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text('${widget.index} / ${widget.total}',
                            style: const TextStyle(color: Color(0xFFC6FF00), fontSize: 12, fontWeight: FontWeight.w900)),
                        Text(_exercise.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                      ],
                    ),
                  ),
                  const Icon(Icons.more_vert, color: Colors.white38),
                ],
              ),
            ),

            if (_restSeconds > 0)
              Container(
                width: double.infinity,
                color: const Color(0xFFC6FF00),
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(loc.restTimer(_restSeconds),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 12)),
              ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── 3D МОДЕЛЬ (большая, на всю ширину) ───
                    Container(
                      height: 280,
                      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: Muscle3DViewer(
                        key: ValueKey('main_view_${_exercise.name}_${_exercise.sets}'),
                        highlightColor: visuals.color,
                        muscleIcon: visuals.icon,
                        muscleName: _exercise.muscle,
                        height: 280,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ─── КАК ВЫПОЛНЯТЬ (technique — сразу видна!) ───
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: visuals.color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: visuals.color.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.play_circle_fill_rounded, color: visuals.color, size: 20),
                                const SizedBox(width: 8),
                                Text(loc.howToPerform,
                                    style: GoogleFonts.inter(
                                        color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                              ],
                            ),
                            const SizedBox(height: 14),
                            ...technique.asMap().entries.map((entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    margin: const EdgeInsets.only(right: 12, top: 1),
                                    decoration: BoxDecoration(
                                      color: visuals.color.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text('${entry.key + 1}',
                                          style: TextStyle(
                                              color: visuals.color,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 12)),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(entry.value,
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                            height: 1.5)),
                                  ),
                                ],
                              ),
                            )),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ─── КНОПКИ: Заменить + Совет ───
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _buildActionChip(Icons.swap_horiz, loc.replace, _showReplaceSheet),
                          const SizedBox(width: 8),
                          _buildActionChip(
                            Icons.sports_gymnastics,
                            loc.coachTip,
                            () => _showTipsModal(visuals.color),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ─── Инфо: оборудование, сложность, отдых, калории ───
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildInfoCard(visuals.color),
                    ),

                    const SizedBox(height: 20),

                    // ─── ТАБЛИЦА ПОДХОДОВ ───
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const SizedBox(width: 40, child: Text('SET', style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w900))),
                              Expanded(child: Text(loc.repsHeader, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w900))),
                              Expanded(child: Text(loc.weightHeader, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w900))),
                              const SizedBox(width: 40),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...List.generate(_sets.length, (i) => _buildSetRow(i, visuals.color)),
                          const SizedBox(height: 12),
                          _buildAddSetButton(),
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
      bottomNavigationBar: _buildBottomButton(),
    );
  }

  Widget _buildInfoCard(Color accent) {
    final loc = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildInfoChip(Icons.fitness_center, _exercise.equipment),
              const SizedBox(width: 8),
              _buildInfoChip(Icons.trending_up, _exercise.difficulty),
              const SizedBox(width: 8),
              _buildInfoChip(Icons.timer_outlined, _exercise.rest),
              const SizedBox(width: 8),
              _buildInfoChip(Icons.local_fire_department, '${_exercise.calories} ${loc.kcal}'),
            ],
          ),
          if (_exercise.description.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(_exercise.description,
                style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFC6FF00).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFFC6FF00)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildActionChip(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: Colors.white70),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSetRow(int index, Color accent) {
    final set = _sets[index];
    final bool isDone = set['done'];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDone ? accent.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDone ? accent.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${index + 1}', style: TextStyle(color: isDone ? accent : Colors.white24, fontWeight: FontWeight.w900, fontSize: 14)),
                if (_sets.length > 1)
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _sets.removeAt(index));
                    },
                    child: const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.remove_circle_outline, size: 13, color: Colors.white24),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _editCell(index, 'reps', set['reps'].toString()),
              child: _buildCell(set['reps'].toString(), isDone),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => _editCell(index, 'weight', set['weight'].toString()),
              child: _buildCell(set['weight'].toString().isEmpty ? '--' : set['weight'].toString(), isDone),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              setState(() => _sets[index]['done'] = !isDone);
              if (!isDone) _startRestTimer();
            },
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: isDone ? accent : Colors.white10, borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.check, size: 20, color: isDone ? Colors.black : Colors.white10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCell(String val, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(val, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(color: active ? Colors.white : Colors.white60, fontWeight: FontWeight.w800, fontSize: 15)),
          ),
          const Icon(Icons.edit_outlined, size: 12, color: Colors.white24),
        ],
      ),
    );
  }

  Widget _buildAddSetButton() {
    final loc = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _sets.add({'reps': '10', 'weight': '', 'done': false}));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
        child: Center(child: Text(loc.addSet, style: const TextStyle(color: Colors.white38, fontWeight: FontWeight.w800, fontSize: 13))),
      ),
    );
  }

  Widget _buildBottomButton() {
    final loc = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      child: GestureDetector(
        onTap: _saveResult,
        child: Container(
          height: 60,
          decoration: BoxDecoration(color: const Color(0xFFC6FF00), borderRadius: BorderRadius.circular(30)),
          child: Center(child: Text(loc.saveResult.toUpperCase(), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16))),
        ),
      ),
    );
  }

  void _showTipsModal(Color color) {
    final loc = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sports_gymnastics, color: color, size: 24),
                const SizedBox(width: 10),
                Text(loc.coachTip, style: GoogleFonts.notoSerif(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              _exercise.tips.isNotEmpty ? _exercise.tips : loc.defaultTip,
              style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
              child: Text(
                loc.startWithComfortableWeight,
                style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
