import 'package:flutter/material.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/app_snackbar.dart';
import 'package:lumina/features/history/presentation/widgets/history_design.dart';
import 'package:lumina/features/history/presentation/widgets/history_form_parts.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Введённое упражнение до сохранения.
class ExerciseDraft {
  const ExerciseDraft({
    required this.name,
    required this.sets,
    required this.reps,
  });

  final String name;
  final int sets;
  final int reps;
}

/// Запись упражнения: выбор из списка, подходы и повторения.
Future<ExerciseDraft?> showExerciseDraftSheet(BuildContext context) =>
    showHistorySheet<ExerciseDraft>(
      context,
      (_) => const _ExerciseDraftSheet(),
    );

class _ExerciseDraftSheet extends StatefulWidget {
  const _ExerciseDraftSheet();

  @override
  State<_ExerciseDraftSheet> createState() => _ExerciseDraftSheetState();
}

class _ExerciseDraftSheetState extends State<_ExerciseDraftSheet> {
  final _sets = TextEditingController(text: '3');
  final _reps = TextEditingController();
  String? _selected;

  @override
  void dispose() {
    _sets.dispose();
    _reps.dispose();
    super.dispose();
  }

  List<(IconData, String)> _options(AppLocalizations loc) => [
    (Icons.sports_gymnastics, loc.exerciseSquats),
    (Icons.fitness_center, loc.exercisePushups),
    (Icons.timer_outlined, loc.exercisePlank),
    (Icons.directions_run, loc.exerciseRunning),
    (Icons.directions_walk, loc.exerciseWalking),
    (Icons.accessibility_new, loc.exerciseAbs),
    (Icons.sports_martial_arts, loc.exerciseRope),
    (Icons.directions_bike, loc.exerciseBike),
    (Icons.self_improvement, loc.exerciseYoga),
    (Icons.spa, loc.exerciseStretch),
  ];

  void _submit(AppLocalizations loc) {
    final name = _selected;
    if (name == null) {
      AppSnackbar.info(context, loc.selectExercise);
      return;
    }
    Navigator.pop(
      context,
      ExerciseDraft(
        name: name,
        sets: int.tryParse(_sets.text.trim()) ?? 3,
        reps: int.tryParse(_reps.text.trim()) ?? 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final loc = AppLocalizations.of(context)!;
    return HistorySheetFrame(
      title: loc.addExercise,
      submitLabel: loc.addButton,
      onSubmit: () => _submit(loc),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (icon, name) in _options(loc))
              ChoiceChip(
                selected: _selected == name,
                onSelected: (_) => setState(() => _selected = name),
                showCheckmark: false,
                avatar: Icon(
                  icon,
                  size: 16,
                  color: _selected == name
                      ? HistoryDesign.greenDark
                      : tc.textSecondary,
                ),
                label: Text(name),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: _selected == name
                      ? FontWeight.w800
                      : FontWeight.w600,
                  color: _selected == name
                      ? HistoryDesign.greenDark
                      : tc.textSecondary,
                ),
                backgroundColor: tc.surface,
                selectedColor: HistoryDesign.greenSoft,
                side: BorderSide(
                  color: _selected == name
                      ? HistoryDesign.green
                      : tc.divider.withValues(alpha: 0.4),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: HistoryFormField(
                controller: _sets,
                label: loc.setsLabel,
                hint: '3',
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: HistoryFormField(
                controller: _reps,
                label: loc.repsLabel,
                hint: '15',
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
