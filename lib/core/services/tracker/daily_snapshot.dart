/// Типизированный снимок дневных данных — используется для оффлайн-кэша,
/// чтобы избежать опечаток в ключах и упростить сериализацию.
class DailySnapshot {
  final String date;
  final int calories;
  final int protein;
  final int fat;
  final int carbs;
  final int water;
  final int steps;
  final int burned;
  final Map<String, int> meals;

  const DailySnapshot({
    required this.date,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.water,
    required this.steps,
    required this.burned,
    required this.meals,
  });

  Map<String, dynamic> toJson() => {
    'date': date,
    'calories': calories,
    'protein': protein,
    'fat': fat,
    'carbs': carbs,
    'water': water,
    'steps': steps,
    'burned': burned,
    'meals': meals,
  };

  factory DailySnapshot.fromJson(Map<String, dynamic> json) {
    int read(String key) => switch (json[key]) {
      final num v => v.toInt(),
      _ => 0,
    };
    final meals = json['meals'] as Map? ?? const {};
    return DailySnapshot(
      date: json['date'] as String? ?? '',
      calories: read('calories'),
      protein: read('protein'),
      fat: read('fat'),
      carbs: read('carbs'),
      water: read('water'),
      steps: read('steps'),
      burned: read('burned'),
      meals: {
        for (final e in meals.entries)
          if (e.value is num) '${e.key}': (e.value as num).toInt(),
      },
    );
  }

  /// Снимок относится к дню [day] (кэш вчерашнего дня не используется).
  bool isFor(DateTime day) {
    final cached = DateTime.tryParse(date);
    return cached != null &&
        cached.year == day.year &&
        cached.month == day.month &&
        cached.day == day.day;
  }
}

/// Новое значение стрика «дней в цели подряд».
///
/// [lastDate] и [stored] — сохранённые дата последнего засчитанного дня и
/// длина стрика. Возвращает `null`, если сегодня уже посчитано.
({int streak, bool reset})? nextStreak({
  required String? lastDate,
  required int stored,
  required String today,
  required String yesterday,
  required bool metGoal,
}) {
  if (lastDate == today) return null;
  if (metGoal) {
    return (streak: lastDate == yesterday ? stored + 1 : 1, reset: false);
  }
  // День пропущен — стрик прерван.
  if (lastDate != null && lastDate != yesterday) {
    return (streak: 0, reset: true);
  }
  return (streak: stored, reset: false);
}
