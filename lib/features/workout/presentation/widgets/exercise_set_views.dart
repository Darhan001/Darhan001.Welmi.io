import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/features/workout/presentation/widgets/workout_design.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Заголовок таблицы подходов.
class ExerciseSetTableHeader extends StatelessWidget {
  const ExerciseSetTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    const style = TextStyle(
      color: Colors.white24,
      fontSize: 10,
      fontWeight: FontWeight.w900,
    );

    return Row(
      children: [
        const SizedBox(width: 40, child: Text('SET', style: style)),
        Expanded(
          child: Text(
            loc.repsHeader,
            textAlign: TextAlign.center,
            style: style,
          ),
        ),
        Expanded(
          child: Text(
            loc.weightHeader,
            textAlign: TextAlign.center,
            style: style,
          ),
        ),
        const SizedBox(width: 40),
      ],
    );
  }
}

/// Строка подхода: номер, повторения, вес и галочка «сделано».
class ExerciseSetRow extends StatelessWidget {
  const ExerciseSetRow({
    super.key,
    required this.index,
    required this.reps,
    required this.weight,
    required this.isDone,
    required this.canRemove,
    required this.accent,
    required this.onEditReps,
    required this.onEditWeight,
    required this.onToggle,
    required this.onRemove,
  });

  final int index;
  final String reps;
  final String weight;
  final bool isDone;
  final bool canRemove;
  final Color accent;
  final VoidCallback onEditReps;
  final VoidCallback onEditWeight;
  final VoidCallback onToggle;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDone
            ? accent.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDone
              ? accent.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: isDone ? accent : Colors.white24,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                if (canRemove)
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onRemove();
                    },
                    child: const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.remove_circle_outline,
                        size: 13,
                        color: Colors.white24,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: onEditReps,
              child: _ValueCell(value: reps, active: isDone),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: onEditWeight,
              child: _ValueCell(
                value: weight.isEmpty ? '--' : weight,
                active: isDone,
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              onToggle();
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDone ? accent : Colors.white10,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.check,
                size: 20,
                color: isDone ? Colors.black : Colors.white10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ValueCell extends StatelessWidget {
  const _ValueCell({required this.value, required this.active});

  final String value;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: active ? WorkoutDesign.textPrimary : Colors.white60,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
          const Icon(Icons.edit_outlined, size: 12, color: Colors.white24),
        ],
      ),
    );
  }
}

/// «Добавить подход».
class ExerciseAddSetButton extends StatelessWidget {
  const ExerciseAddSetButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            AppLocalizations.of(context)!.addSet,
            style: const TextStyle(
              color: Colors.white38,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

/// Кнопка «Сохранить результат».
class ExerciseSaveButton extends StatelessWidget {
  const ExerciseSaveButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: WorkoutDesign.accent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(
              AppLocalizations.of(context)!.saveResult.toUpperCase(),
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
