import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/widgets/units_format.dart';
import 'package:lumina/features/workout/presentation/widgets/workout_design.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Ввод повторений или веса подхода. `null` — отменили.
Future<String?> showSetValueEditor(
  BuildContext context, {
  required int setIndex,
  required bool isReps,
  required String current,
}) {
  final controller = TextEditingController(text: current);
  final loc = AppLocalizations.of(context)!;

  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: WorkoutDesign.dialog,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        isReps
            ? loc.repsInSet(setIndex + 1)
            : loc.weightInSet(setIndex + 1, loc.weightUnitLabel),
        style: const TextStyle(
          color: WorkoutDesign.textPrimary,
          fontWeight: FontWeight.w900,
          fontSize: 16,
        ),
      ),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: isReps
            ? TextInputType.number
            : const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(
          color: WorkoutDesign.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
        decoration: InputDecoration(
          hintText: isReps ? loc.exampleReps : loc.exampleWeight,
          hintStyle: const TextStyle(color: Colors.white24),
          filled: true,
          fillColor: Colors.black38,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(
            loc.cancel,
            style: const TextStyle(color: Colors.white54),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, controller.text.trim()),
          style: ElevatedButton.styleFrom(
            backgroundColor: WorkoutDesign.accent,
            foregroundColor: Colors.black,
          ),
          child: Text(
            loc.done,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    ),
  );
}

/// Выбор замены упражнения. `null` — закрыли без выбора.
Future<String?> showReplaceExerciseSheet(
  BuildContext context, {
  required String muscle,
  required List<String> alternatives,
}) {
  final loc = AppLocalizations.of(context)!;

  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: WorkoutDesign.sheet,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Text(
              loc.replaceExercise,
              style: GoogleFonts.notoSerif(
                color: WorkoutDesign.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Text(
              loc.alternativesForMuscle(muscle),
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...alternatives.map(
            (name) => ListTile(
              onTap: () => Navigator.pop(ctx, name),
              leading: const Icon(
                Icons.fitness_center_rounded,
                color: WorkoutDesign.accent,
                size: 20,
              ),
              title: Text(
                name,
                style: const TextStyle(
                  color: WorkoutDesign.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    ),
  );
}

/// Совет тренера по упражнению.
Future<void> showCoachTipSheet(
  BuildContext context, {
  required Color color,
  required String? tip,
}) {
  final loc = AppLocalizations.of(context)!;

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: WorkoutDesign.sheet,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
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
              Text(
                loc.coachTip,
                style: GoogleFonts.notoSerif(
                  color: WorkoutDesign.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            tip != null && tip.isNotEmpty ? tip : loc.defaultTip,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              loc.startWithComfortableWeight,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Итог тренировки: подходы, повторения и объём.
Future<void> showWorkoutResultDialog(
  BuildContext context, {
  required int setsDone,
  required int repsTotal,
  required int volumeKg,
}) {
  final loc = AppLocalizations.of(context)!;

  Widget stat(String value, String label) => Column(
    children: [
      Text(
        value,
        style: GoogleFonts.inter(
          color: WorkoutDesign.accent,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
      Text(
        label,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      backgroundColor: WorkoutDesign.dialog,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: WorkoutDesign.accent, size: 56),
          const SizedBox(height: 16),
          Text(
            loc.workoutRecorded,
            style: const TextStyle(
              color: WorkoutDesign.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              stat('$setsDone', loc.sets),
              stat('$repsTotal', loc.repsLabel),
              stat('$volumeKg ${loc.kgLabel}', loc.volume),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: WorkoutDesign.accent,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                loc.great,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
