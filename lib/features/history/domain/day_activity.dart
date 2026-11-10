/// Один день в истории: шаги + вода + упражнения.
class DayActivity {
  DayActivity({
    required this.date,
    this.steps = 0,
    this.calories = 0,
    this.minutes = 0,
    this.distanceKm = 0,
    this.waterMl = 0,
    this.exercises = const [],
  });

  final DateTime date;
  int steps;
  int calories;
  int minutes;
  double distanceKm;
  int waterMl;
  List<Map<String, dynamic>> exercises;

  bool get isActive => steps > 0 || exercises.isNotEmpty || minutes > 0;
}
