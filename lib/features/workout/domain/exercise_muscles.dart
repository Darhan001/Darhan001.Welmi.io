/// Данные «упражнение → работающие мышцы».
///
/// Это структурированный справочник, независимый от 3D-рендеринга. Его же
/// будет читать подсветка на модели: основные мышцы — красным, вспомогательные
/// — оранжевым. Сами названия и назначения мышц даны в обычной учебной
/// терминологии; это не медицинская консультация и не анатомически точная
/// разметка геометрии.
library;

enum Muscle {
  quadriceps,
  hamstrings,
  glutes,
  adductors,
  calves,
  erectorSpinae,
  chest,
  deltoids,
  triceps,
  biceps,
  forearms,
  lats,
  trapezius,
  rectusAbdominis,
  obliques,
}

enum MuscleRole { primary, secondary }

/// Название и назначение мышцы для карточки в приложении.
class MuscleInfo {
  const MuscleInfo({required this.name, required this.purpose});

  final String name;
  final String purpose;
}

const Map<Muscle, MuscleInfo> muscleInfo = {
  Muscle.quadriceps: MuscleInfo(
    name: 'Квадрицепсы',
    purpose: 'Разгибают колено; участвуют в приседаниях и выпадах.',
  ),
  Muscle.hamstrings: MuscleInfo(
    name: 'Задняя поверхность бедра',
    purpose: 'Сгибают колено и разгибают бедро; работают в тяге и мостах.',
  ),
  Muscle.glutes: MuscleInfo(
    name: 'Ягодичные',
    purpose: 'Разгибают и отводят бедро; основной двигатель в приседах и тяге.',
  ),
  Muscle.adductors: MuscleInfo(
    name: 'Приводящие мышцы бедра',
    purpose: 'Сводят ноги вместе; помогают стабилизировать таз в приседах.',
  ),
  Muscle.calves: MuscleInfo(
    name: 'Икроножные',
    purpose: 'Сгибают стопу; работают при подъёмах на носки и в выпадах.',
  ),
  Muscle.erectorSpinae: MuscleInfo(
    name: 'Разгибатели спины',
    purpose: 'Удерживают позвоночник в прямом положении при наклонах.',
  ),
  Muscle.chest: MuscleInfo(
    name: 'Грудные',
    purpose: 'Сводят и приводят плечо; основная мышца жимов и отжиманий.',
  ),
  Muscle.deltoids: MuscleInfo(
    name: 'Дельтовидные',
    purpose: 'Поднимают и отводят руку; главные в жиме над головой.',
  ),
  Muscle.triceps: MuscleInfo(
    name: 'Трицепсы',
    purpose: 'Разгибают локоть; работают во всех жимовых движениях.',
  ),
  Muscle.biceps: MuscleInfo(
    name: 'Бицепсы',
    purpose: 'Сгибают локоть и помогают в тяге.',
  ),
  Muscle.forearms: MuscleInfo(
    name: 'Предплечья',
    purpose: 'Удерживают гриф и гантели; работают в хвате.',
  ),
  Muscle.lats: MuscleInfo(
    name: 'Широчайшие',
    purpose: 'Тянут руку вниз и назад; основные в тягах.',
  ),
  Muscle.trapezius: MuscleInfo(
    name: 'Трапеции',
    purpose: 'Лопатки; участвуют в тягах и в шраге.',
  ),
  Muscle.rectusAbdominis: MuscleInfo(
    name: 'Прямая мышца живота',
    purpose: 'Сгибает позвоночник; стабилизирует корпус.',
  ),
  Muscle.obliques: MuscleInfo(
    name: 'Косые мышцы живота',
    purpose: 'Поворачивают и удерживают корпус от поворота.',
  ),
};

class ExerciseMuscles {
  const ExerciseMuscles({
    required this.name,
    required this.primary,
    this.secondary = const {},
    required this.description,
  });

  final String name;
  final Set<Muscle> primary;
  final Set<Muscle> secondary;
  final String description;

  /// Роль каждой задействованной мышцы. Основная мышца перекрывает вспомогательную.
  MuscleRole? roleOf(Muscle muscle) {
    if (primary.contains(muscle)) return MuscleRole.primary;
    if (secondary.contains(muscle)) return MuscleRole.secondary;
    return null;
  }
}

const List<ExerciseMuscles> exerciseMuscleCatalog = [
  ExerciseMuscles(
    name: 'Приседания',
    primary: {Muscle.quadriceps, Muscle.glutes},
    secondary: {Muscle.hamstrings, Muscle.adductors, Muscle.erectorSpinae},
    description:
        'Базовое упражнение на ноги: сгибание и разгибание в коленях и бедрах.',
  ),
  ExerciseMuscles(
    name: 'Выпады',
    primary: {Muscle.quadriceps, Muscle.glutes},
    secondary: {Muscle.hamstrings, Muscle.adductors, Muscle.calves},
    description:
        'Одноногое упражнение: нагрузка на каждую ногу по отдельности.',
  ),
  ExerciseMuscles(
    name: 'Отжимания',
    primary: {Muscle.chest, Muscle.triceps},
    secondary: {Muscle.deltoids, Muscle.rectusAbdominis},
    description: 'Жим собственного веса от пола; подходит без оборудования.',
  ),
  ExerciseMuscles(
    name: 'Жим лёжа',
    primary: {Muscle.chest, Muscle.triceps},
    secondary: {Muscle.deltoids},
    description: 'Жим штанги или гантелей лёжа на горизонтальной скамье.',
  ),
  ExerciseMuscles(
    name: 'Жим над головой',
    primary: {Muscle.deltoids, Muscle.triceps},
    secondary: {Muscle.trapezius, Muscle.rectusAbdominis},
    description: 'Жим веса вверх из положения у плеч, стоя или сидя.',
  ),
  ExerciseMuscles(
    name: 'Сгибание рук на бицепс',
    primary: {Muscle.biceps},
    secondary: {Muscle.forearms},
    description: 'Изолированное сгибание локтя с гантелями или штангой.',
  ),
  ExerciseMuscles(
    name: 'Тяга в наклоне',
    primary: {Muscle.lats, Muscle.trapezius},
    secondary: {Muscle.biceps, Muscle.erectorSpinae},
    description: 'Тяга гантели или штанги к поясу из наклона вперёд.',
  ),
  ExerciseMuscles(
    name: 'Становая тяга',
    primary: {Muscle.glutes, Muscle.hamstrings, Muscle.erectorSpinae},
    secondary: {Muscle.quadriceps, Muscle.trapezius, Muscle.forearms},
    description: 'Подъём штанги с пола до выпрямленного корпуса.',
  ),
  ExerciseMuscles(
    name: 'Планка',
    primary: {Muscle.rectusAbdominis},
    secondary: {Muscle.obliques, Muscle.erectorSpinae, Muscle.glutes},
    description:
        'Статическое удержание прямого корпуса в упоре на предплечьях.',
  ),
];

/// Ищет упражнение по названию без учёта регистра и пробелов по краям.
ExerciseMuscles? findExerciseMuscles(String name) {
  final key = name.trim().toLowerCase();
  for (final exercise in exerciseMuscleCatalog) {
    if (exercise.name.toLowerCase() == key) return exercise;
  }
  return null;
}

/// Карта «мышца → роль» для подсветки на модели. Пусто, если упражнение неизвестно.
Map<Muscle, MuscleRole> highlightFor(String exerciseName) {
  final exercise = findExerciseMuscles(exerciseName);
  if (exercise == null) return const {};
  return {
    for (final muscle in {...exercise.primary, ...exercise.secondary})
      muscle: exercise.roleOf(muscle)!,
  };
}
