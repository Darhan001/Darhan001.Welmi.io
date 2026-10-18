import 'package:flutter_test/flutter_test.dart';
import 'package:lumina/features/workout/domain/exercise_muscles.dart';

void main() {
  test('каждая мышца имеет название и назначение', () {
    for (final muscle in Muscle.values) {
      final info = muscleInfo[muscle];
      expect(info, isNotNull, reason: '$muscle без описания');
      expect(info!.name.trim(), isNotEmpty);
      expect(info.purpose.trim(), isNotEmpty);
    }
  });

  test('у каждого упражнения есть хотя бы одна основная мышца', () {
    for (final exercise in exerciseMuscleCatalog) {
      expect(exercise.primary, isNotEmpty, reason: exercise.name);
    }
  });

  test('основные и вспомогательные мышцы не пересекаются', () {
    for (final exercise in exerciseMuscleCatalog) {
      expect(
        exercise.primary.intersection(exercise.secondary),
        isEmpty,
        reason: exercise.name,
      );
    }
  });

  test('названия упражнений уникальны', () {
    final names = exerciseMuscleCatalog.map((e) => e.name).toList();
    expect(names.toSet().length, names.length);
  });

  test('каталог покрывает базовые упражнения (5–10 шт.)', () {
    expect(exerciseMuscleCatalog.length, inInclusiveRange(5, 10));
  });

  test('поиск без учёта регистра и пробелов', () {
    expect(findExerciseMuscles('  приседания ')?.name, 'Приседания');
    expect(findExerciseMuscles('Неизвестное'), isNull);
  });

  test('подсветка: основные мышцы — primary, вспомогательные — secondary', () {
    final squat = highlightFor('Приседания');
    expect(squat[Muscle.quadriceps], MuscleRole.primary);
    expect(squat[Muscle.glutes], MuscleRole.primary);
    expect(squat[Muscle.hamstrings], MuscleRole.secondary);
    expect(squat.containsKey(Muscle.biceps), isFalse);
  });

  test('неизвестное упражнение не подсвечивает ничего', () {
    expect(highlightFor('Что-то'), isEmpty);
  });

  test('подсветка отличается между упражнениями', () {
    expect(
      highlightFor('Отжимания').keys.toSet(),
      isNot(equals(highlightFor('Приседания').keys.toSet())),
    );
  });
}
