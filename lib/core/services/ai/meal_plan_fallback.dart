// Запасной план питания на неделю — когда AI недоступен.

/// Выровнять план по реальным датам текущей недели (пн–вс), чтобы
/// пользователь видел вчерашний/сегодняшний/завтрашний день корректно.
/// Берем максимум 7 дней (если модель вернула больше — обрезаем).
/// [now] — для тестов; по умолчанию текущий момент.
List<Map<String, dynamic>> withCurrentWeekDates(
  List<Map<String, dynamic>> plan, {
  DateTime? now,
}) {
  final today = now ?? DateTime.now();
  final count = plan.length > 7 ? 7 : plan.length;
  return List.generate(count, (i) {
    // Календарная арифметика, а не Duration(days:): при переходе на летнее
    // время «+24 ч» попадает на предыдущий день.
    final d = DateTime(
      today.year,
      today.month,
      today.day - (today.weekday - 1) + i,
    );
    return {
      ...plan[i],
      'date': '${d.day}',
      'iso': d.toIso8601String().substring(0, 10),
    };
  });
}

List<Map<String, dynamic>> fallbackMealPlan(
  String goal,
  int dailyCalories,
  String country,
) {
  const dayNames = [
    'Понедельник',
    'Вторник',
    'Среда',
    'Четверг',
    'Пятница',
    'Суббота',
    'Воскресенье',
  ];
  final days = List.generate(7, (i) {
    return {
      'day': dayNames[i],
      'date': '',
      'calories': dailyCalories,
      'meals': _mealsForDay(country, dailyCalories, i),
    };
  });
  return withCurrentWeekDates(days);
}

/// Блюда дня с учётом местной кухни страны (по дням — с ротацией).
List<Map<String, dynamic>> _mealsForDay(
  String country,
  int dailyCalories,
  int dayIndex,
) {
  final br = (dailyCalories * 0.25).round();
  final ln = (dailyCalories * 0.4).round();
  final dn = (dailyCalories * 0.35).round();
  final c = country.toLowerCase();

  final List<String> breakfasts;
  final List<String> lunches;
  final List<String> dinners;

  if (c.contains('кирг') || c.contains('кырг') || c.contains('kyrgyz')) {
    breakfasts = [
      'боорсок с сыром и зелёным чаем',
      'омлет с лепёшкой и овощами',
      'творог со сметаной и мёдом',
    ];
    lunches = [
      'лагман с говядиной',
      'манты (3–4 шт) с овощным салатом',
      'плов с курицей и огурцами',
    ];
    dinners = [
      'бешбармак (небольшая порция) с овощами',
      'куурдак с картофелем и луком',
      'самса с мясом и чай',
    ];
  } else if (c.contains('казах') || c.contains('kazakh')) {
    breakfasts = [
      'каша с молоком и изюмом',
      'сырники со сметаной',
      'омлет с хлебом и маслом',
    ];
    lunches = ['бешбармак с мясом', 'куырдак с картофелем', 'манты с мясом'];
    dinners = [
      'суп кеспе с лапшой',
      'запечённая рыба с овощами',
      'творожная запеканка',
    ];
  } else if (c.contains('узбек') || c.contains('uzbek')) {
    breakfasts = [
      'лепёшка с чаем и сыром',
      'омлет с овощами',
      'творог с лепёшкой',
    ];
    lunches = ['плов с бараниной', 'лагман', 'манты с мясом'];
    dinners = ['шашлык с овощами', 'самса с мясом', 'тушёные овощи с курицей'];
  } else if (c.contains('рос') || c.contains('russ')) {
    breakfasts = [
      'овсяная каша с ягодами',
      'сырники со сметаной',
      'творог с мёдом и орехами',
    ];
    lunches = [
      'борщ со сметаной и хлебом',
      'гречка с куриной котлетой',
      'суп-лапша с курицей',
    ];
    dinners = [
      'запечённая рыба с овощами',
      'куриное филе с рисом и салатом',
      'творожная запеканка',
    ];
  } else if (c.contains('америк') ||
      c.contains('сша') ||
      c.contains('usa') ||
      c.contains('americ')) {
    breakfasts = [
      'овсянка с бананом и арахисовой пастой',
      'греческий йогурт с гранолой',
      'яичница с тостом и авокадо',
    ];
    lunches = [
      'куриная грудка с киноа и овощами',
      'сэндвич с индейкой и салатом',
      'салат с тунцом',
    ];
    dinners = [
      'лосось с брокколи',
      'паста с курицей и томатами',
      'стейк с овощами',
    ];
  } else {
    breakfasts = [
      'овсяная каша с фруктами',
      'омлет с овощами',
      'творог с ягодами',
    ];
    lunches = [
      'курица с гречкой и овощами',
      'рыба с рисом и салатом',
      'суп с курицей',
    ];
    dinners = [
      'запечённая рыба с овощами',
      'куриное филе с овощами',
      'творожная запеканка',
    ];
  }

  return [
    {
      'name': 'Завтрак: ${breakfasts[dayIndex % breakfasts.length]}',
      'time': '08:30',
      'kcal': br,
    },
    {
      'name': 'Обед: ${lunches[dayIndex % lunches.length]}',
      'time': '13:00',
      'kcal': ln,
    },
    {
      'name': 'Ужин: ${dinners[dayIndex % dinners.length]}',
      'time': '19:00',
      'kcal': dn,
    },
  ];
}
