/// WORKOUT MODELS — план тренировок от AI тренера
library;

/// Одно упражнение
class WorkoutExercise {
  final String name;
  final String muscle; // группа мышц
  final String equipment; // инвентарь
  final int sets; // подходы
  final String reps; // повторения
  final String rest; // отдых
  final String difficulty; // сложность
  final int calories; // ккал за подход
  final String description;
  final List<String> technique; // шаги «как делать правильно»
  final String tips; // совет тренера

  WorkoutExercise({
    required this.name,
    this.muscle = 'Общее',
    this.equipment = 'Гантели',
    this.sets = 3,
    this.reps = '10-12',
    this.rest = '60 сек',
    this.difficulty = 'Средний',
    this.calories = 150,
    this.description = '',
    List<String>? technique,
    this.tips = '',
  }) : technique = technique ?? [];

  static int _toInt(dynamic val, int fallback) {
    if (val == null) return fallback;
    if (val is num) return val.toInt();
    return int.tryParse(val.toString()) ?? fallback;
  }

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    // Техника может прийти списком или строкой (по строкам)
    List<String> technique = [];
    final rawTech = json['technique'] ?? json['steps'] ?? json['how_to'];
    if (rawTech is List) {
      technique = rawTech.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    } else if (rawTech is String && rawTech.trim().isNotEmpty) {
      technique = rawTech
          .split(RegExp(r'\n+|\.\s'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return WorkoutExercise(
      name: json['name']?.toString() ?? 'Упражнение',
      muscle: json['muscle']?.toString() ??
          json['muscle_group']?.toString() ??
          json['группа_мышц']?.toString() ??
          'Общее',
      equipment: json['equipment']?.toString() ??
          json['inventory']?.toString() ??
          'Гантели',
      sets: _toInt(json['sets'] ?? json['set'] ?? json['подходы'], 3),
      reps: json['reps']?.toString() ??
          json['repetitions']?.toString() ??
          json['повторения']?.toString() ??
          '10-12',
      rest: json['rest']?.toString() ?? json['отдых']?.toString() ?? '60 сек',
      difficulty: json['difficulty']?.toString() ??
          json['сложность']?.toString() ??
          'Средний',
      calories: _toInt(json['calories'] ?? json['kcal'], 150),
      description: json['description']?.toString() ??
          json['описание']?.toString() ??
          '',
      technique: technique,
      tips: json['tips']?.toString() ??
          json['tip']?.toString() ??
          json['совет']?.toString() ??
          '',
    );
  }
}

/// Один день тренировки
class WorkoutDay {
  final String day;
  final String focus; // группа мышц дня
  final List<WorkoutExercise> exercises;

  WorkoutDay({
    required this.day,
    this.focus = '',
    List<WorkoutExercise>? exercises,
  }) : exercises = exercises ?? [];

  bool get isRestDay => exercises.isEmpty;

  factory WorkoutDay.fromJson(Map<String, dynamic> json) {
    final exercises = (json['exercises'] as List? ?? [])
        .whereType<Map>()
        .map((e) => WorkoutExercise.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.name != 'Упражнение' || e.description.isNotEmpty)
        .toList();

    return WorkoutDay(
      day: json['day']?.toString() ??
          json['name']?.toString() ??
          json['день']?.toString() ??
          '',
      focus: json['focus']?.toString() ??
          json['muscle_group']?.toString() ??
          json['цель']?.toString() ??
          '',
      exercises: exercises,
    );
  }
}

/// Недельный план тренировок
class WorkoutPlan {
  final List<WorkoutDay> days;

  WorkoutPlan({required this.days});

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) {
    final days = (json['days'] as List? ?? [])
        .whereType<Map>()
        .map((e) => WorkoutDay.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return WorkoutPlan(days: days);
  }
}
