import 'package:lumina/core/models/workout_plan.dart';

/// Быстрый конструктор упражнения для запасных планов.
WorkoutExercise fallbackExercise({
  required String name,
  required String muscle,
  required String equipment,
  String sets = '3',
  String reps = '12-15',
  String rest = '60 сек',
  String difficulty = 'Начальный',
  String description = '',
  List<String>? technique,
  String tips = '',
}) {
  return WorkoutExercise(
    name: name,
    muscle: muscle,
    equipment: equipment,
    sets: int.tryParse(sets) ?? 3,
    reps: reps,
    rest: rest,
    difficulty: difficulty,
    description: description,
    technique:
        technique ??
        [
          'Прими устойчивое исходное положение, спина прямая, пресс напряжён.',
          'Выполняй «$name» плавно и с полной амплитудой, без рывков.',
          'На усилии делай выдох, на расслаблении — вдох.',
        ],
    tips: tips,
  );
}
