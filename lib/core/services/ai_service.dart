import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:lumina/core/models/workout_plan.dart';

class AiChatMessage {
  final String role; 
  final String text;
  final DateTime timestamp;
  AiChatMessage({required this.role, required this.text, DateTime? timestamp}) 
      : timestamp = timestamp ?? DateTime.now();
  Map<String, dynamic> toJson() => {'role': role, 'text': text, 'timestamp': timestamp.toIso8601String()};
}

class FoodAnalysisResult {
  final String name;
  final int calories;
  final double proteinGrams;
  final double fatGrams;
  final double carbsGrams;
  final double? amountGrams;
  final String description;

  FoodAnalysisResult({
    required this.name,
    required this.calories,
    required this.proteinGrams,
    required this.fatGrams,
    required this.carbsGrams,
    this.amountGrams,
    this.description = '',
  });

  factory FoodAnalysisResult.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }
    return FoodAnalysisResult(
      name: json['name']?.toString() ?? json['название']?.toString() ?? 'Блюдо',
      calories: toDouble(json['calories'] ?? json['калории'] ?? json['kcal']).toInt(),
      proteinGrams: toDouble(json['protein_grams'] ?? json['protein'] ?? json['белки']),
      fatGrams: toDouble(json['fat_grams'] ?? json['fat'] ?? json['жиры']),
      carbsGrams: toDouble(json['carbs_grams'] ?? json['carbs'] ?? json['углеводы']),
      amountGrams: toDouble(json['amount_grams'] ?? json['weight'] ?? json['вес']),
      description: json['description']?.toString() ?? json['описание']?.toString() ?? '',
    );
  }
}

/// Результат расчёта AI — персональный план питания
class AiNutritionPlan {
  final int dailyCalories;
  final int proteinGrams;
  final int fatGrams;
  final int carbGrams;
  final int waterMlGoal;
  final int tdee;
  final int bmr;
  final String mealSuggestion;

  AiNutritionPlan({
    required this.dailyCalories,
    required this.proteinGrams,
    required this.fatGrams,
    required this.carbGrams,
    this.waterMlGoal = 2000,
    this.tdee = 0,
    this.bmr = 0,
    this.mealSuggestion = '',
  });

  factory AiNutritionPlan.fromJson(Map<String, dynamic> json) {
    int getInt(List<String> keys, [int fallback = 0]) {
      for (final k in keys) {
        if (json.containsKey(k) && json[k] != null) {
          final v = json[k];
          if (v is num) return v.toInt();
          return int.tryParse(v.toString()) ?? fallback;
        }
      }
      return fallback;
    }

    return AiNutritionPlan(
      dailyCalories: getInt(['daily_calories', 'calories', 'калории'], 2000),
      proteinGrams: getInt(['protein_grams', 'protein', 'белки'], 120),
      fatGrams: getInt(['fat_grams', 'fat', 'жиры'], 60),
      carbGrams: getInt(['carb_grams', 'carbs', 'углеводы'], 200),
      waterMlGoal: getInt(['water_ml_goal', 'water', 'вода'], 2000),
      tdee: getInt(['tdee'], 0),
      bmr: getInt(['bmr'], 0),
      mealSuggestion: json['meal_suggestion']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'daily_calories': dailyCalories,
        'protein_grams': proteinGrams,
        'fat_grams': fatGrams,
        'carb_grams': carbGrams,
        'water_ml_goal': waterMlGoal,
        'tdee': tdee,
        'bmr': bmr,
        'meal_suggestion': mealSuggestion,
      };
}

class AiService {
  static final AiService _instance = AiService._internal();
  factory AiService() => _instance;
  AiService._internal();

  GenerativeModel? _nutritionModel;
  String? _openRouterKey;
  String? _scannerApiKey; // отдельный ключ только для сканера еды
  final List<AiChatMessage> _chatHistory = [];

  void initialize({
    required String nutritionApiKey,
    String? chatApiKey,
    String? scannerApiKey,
  }) {
    if (nutritionApiKey.startsWith('AIza')) {
      _nutritionModel = GenerativeModel(model: 'gemini-1.5-flash', apiKey: nutritionApiKey);
    }
    _openRouterKey = chatApiKey ?? (nutritionApiKey.startsWith('sk-or-') ? nutritionApiKey : null);
    _scannerApiKey = scannerApiKey;
  }

  // --- ПЛАН ПИТАНИЯ ---

  /// Рассчитать персональный план питания.
  /// Сначала пробуем Gemini, при ошибке — fallback на формулы Mifflin-St Jeor.
  Future<AiNutritionPlan?> calculateNutrition({
    required double heightCm,
    required double currentWeightKg,
    required double targetWeightKg,
    required int age,
    required String gender,
    required String goal,
    required String activityLevel,
    required double goalSpeedKgPerWeek,
  }) async {
    final prompt = '''
Ты — нутрициолог. Рассчитай план питания по параметрам:
рост: $heightCm см, вес: $currentWeightKg кг, целевой вес: $targetWeightKg кг,
возраст: $age, пол: $gender, цель: $goal, активность: $activityLevel, скорость: $goalSpeedKgPerWeek кг/нед.
Верни ТОЛЬКО JSON: {"daily_calories": 0, "protein_grams": 0, "fat_grams": 0, "carb_grams": 0, "water_ml_goal": 0, "tdee": 0, "bmr": 0, "meal_suggestion": ""}
''';

    // 1) Сначала Gemini SDK, если ключ валиден
    if (_nutritionModel != null) {
      try {
        final response = await _nutritionModel!
            .generateContent([Content.text(prompt)])
            .timeout(const Duration(seconds: 30));
        final text = response.text;
        if (text != null) {
          final json = _extractJson(text);
          if (json != null) return AiNutritionPlan.fromJson(json);
        }
      } catch (e) {
        debugPrint('⚠️ Gemini nutrition error: $e');
      }
    }

    // 2) Если не вышло — пробуем OpenRouter → Gemini REST
    try {
      final text = await _tryAiCompletion(
        systemPrompt: 'Ты — нутрициолог. Отвечай только JSON.',
        userPrompt: prompt,
        maxTokens: 800,
      ).timeout(const Duration(seconds: 50));
      if (text != null) {
        final json = _extractJson(text);
        if (json != null) return AiNutritionPlan.fromJson(json);
      }
    } catch (e) {
      debugPrint('⚠️ Nutrition AI fallback error: $e');
    }

    // Fallback — формулы Mifflin-St Jeor
    final isMale = gender == 'male';
    final bmr = isMale
        ? (10 * currentWeightKg + 6.25 * heightCm - 5 * age + 5).round()
        : (10 * currentWeightKg + 6.25 * heightCm - 5 * age - 161).round();
    final activity = switch (activityLevel) {
      'sedentary' => 1.2,
      'light' => 1.375,
      'moderate' => 1.55,
      'high' => 1.725,
      _ => 1.2,
    };
    final tdee = (bmr * activity).round();
    final deficit = (goalSpeedKgPerWeek * 1100).round();
    final dailyCalories = switch (goal) {
      'loseWeight' => (tdee - deficit).clamp(1200, tdee),
      'gainWeight' => tdee + deficit,
      _ => tdee,
    };
    final proteinGrams = (currentWeightKg * 1.6).round();
    final fatGrams = (dailyCalories * 0.25 / 9).round();
    final carbGrams =
        ((dailyCalories - proteinGrams * 4 - fatGrams * 9) / 4).round();
    final waterMlGoal = (currentWeightKg * 35).round();

    return AiNutritionPlan(
      dailyCalories: dailyCalories,
      proteinGrams: proteinGrams,
      fatGrams: fatGrams,
      carbGrams: carbGrams,
      waterMlGoal: waterMlGoal,
      tdee: tdee,
      bmr: bmr,
      mealSuggestion: switch (goal) {
        'loseWeight' => 'Сбалансированный рацион с дефицитом калорий',
        'gainWeight' => 'Рацион с профицитом калорий для набора массы',
        _ => 'Рацион для поддержания текущего веса',
      },
    );
  }

  /// Сгенерировать план питания на неделю. При ошибке — fallback.
  /// [country] — страна/регион пользователя, чтобы AI предлагал
  /// блюда местной кухни (манты, лагман, борщ и т.д.).
  /// Возвращает план и флаг [isFallback] (true — использован запасной).
  Future<({List<Map<String, dynamic>> days, bool isFallback})> generateMealPlan({
    required double currentWeightKg,
    required double targetWeightKg,
    required int dailyCalories,
    required String goal,
    required int proteinGrams,
    String country = '',
  }) async {
    final goalRu = switch (goal) {
      'loseWeight' => 'похудение (дефицит калорий)',
      'gainWeight' => 'набор массы (профицит калорий)',
      _ => 'поддержание веса',
    };
    final countryInstruction = country.trim().isEmpty
        ? ''
        : 'Страна/регион пользователя: $country.\n'
            'ВАЖНО: используй блюда МЕСТНОЙ кухни этой страны '
            '(например, для Кыргызстана: манты, лагман, самса, шаурма, бешбармак, '
            'куурдак, боорсок, ашлянфу; для России: борщ, гречка, овсянка, сырники, блины; '
            'для Казахстана: бешбармак, манты, кумыс; для Узбекистана: плов, самса, лагман; '
            'для США: овсянка, греческий йогурт, куриная грудка, сэндвичи, салаты). '
            'Указывай реальную калорийность каждого блюда.\n';
    final prompt = '''
Ты — нутрициолог. Составь план питания на 7 дней для ТЕКУЩЕЙ недели (с понедельника по воскресенье, реальные даты).
Цель: $goalRu, калорий в день: $dailyCalories, белка в день: $proteinGrams г, текущий вес: $currentWeightKg кг, целевой вес: $targetWeightKg кг.
$countryInstruction
Верни ТОЛЬКО JSON-массив из 7 элементов (даты — числа текущей недели):
[{"day":"Понедельник","date":"11","calories":1800,"meals":[{"name":"Завтрак: ...","time":"08:30","kcal":450},{"name":"Обед: ...","time":"13:00","kcal":720},{"name":"Ужин: ...","time":"19:00","kcal":630}]}]
''';

    try {
      // Пробуем все доступные AI-каналы: OpenRouter → Gemini REST.
      final text = await _tryAiCompletion(
        systemPrompt: 'Ты — нутрициолог. Отвечай только JSON.',
        userPrompt: prompt,
        maxTokens: 1800,
      ).timeout(const Duration(seconds: 55));
      if (text != null) {
        final parsed = _parseWeekPlan(text);
        if (parsed != null && parsed.isNotEmpty) {
          return (
            days: _withCurrentWeekDates(parsed),
            isFallback: false,
          );
        }
      }
    } catch (e) {
      debugPrint('⚠️ Meal plan AI error: $e');
    }
    return (
      days: _fallbackMealPlan(goal, dailyCalories, country),
      isFallback: true,
    );
  }

  /// Выровнять план по реальным датам текущей недели (пн–вс), чтобы
  /// пользователь видел вчерашний/сегодняшний/завтрашний день корректно.
  /// Берем максимум 7 дней (если модель вернула больше — обрезаем).
  List<Map<String, dynamic>> _withCurrentWeekDates(List<Map<String, dynamic>> plan) {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final count = plan.length > 7 ? 7 : plan.length;
    return List.generate(count, (i) {
      final d = monday.add(Duration(days: i));
      return {
        ...plan[i],
        'date': '${d.day}',
        'iso': d.toIso8601String().substring(0, 10),
      };
    });
  }

  List<Map<String, dynamic>> _fallbackMealPlan(
      String goal, int dailyCalories, String country) {
    const dayNames = [
      'Понедельник', 'Вторник', 'Среда', 'Четверг',
      'Пятница', 'Суббота', 'Воскресенье',
    ];
    final days = List.generate(7, (i) {
      return {
        'day': dayNames[i],
        'date': '',
        'calories': dailyCalories,
        'meals': _mealsForDay(country, dailyCalories, i),
      };
    });
    return _withCurrentWeekDates(days);
  }

  /// Блюда дня с учётом местной кухни страны (по дням — с ротацией).
  List<Map<String, dynamic>> _mealsForDay(
      String country, int dailyCalories, int dayIndex) {
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
      breakfasts = ['каша с молоком и изюмом', 'сырники со сметаной', 'омлет с хлебом и маслом'];
      lunches = ['бешбармак с мясом', 'куырдак с картофелем', 'манты с мясом'];
      dinners = ['суп кеспе с лапшой', 'запечённая рыба с овощами', 'творожная запеканка'];
    } else if (c.contains('узбек') || c.contains('uzbek')) {
      breakfasts = ['лепёшка с чаем и сыром', 'омлет с овощами', 'творог с лепёшкой'];
      lunches = ['плов с бараниной', 'лагман', 'манты с мясом'];
      dinners = ['шашлык с овощами', 'самса с мясом', 'тушёные овощи с курицей'];
    } else if (c.contains('рос') || c.contains('russ')) {
      breakfasts = ['овсяная каша с ягодами', 'сырники со сметаной', 'творог с мёдом и орехами'];
      lunches = ['борщ со сметаной и хлебом', 'гречка с куриной котлетой', 'суп-лапша с курицей'];
      dinners = ['запечённая рыба с овощами', 'куриное филе с рисом и салатом', 'творожная запеканка'];
    } else if (c.contains('америк') ||
        c.contains('сша') ||
        c.contains('usa') ||
        c.contains('americ')) {
      breakfasts = ['овсянка с бананом и арахисовой пастой', 'греческий йогурт с гранолой', 'яичница с тостом и авокадо'];
      lunches = ['куриная грудка с киноа и овощами', 'сэндвич с индейкой и салатом', 'салат с тунцом'];
      dinners = ['лосось с брокколи', 'паста с курицей и томатами', 'стейк с овощами'];
    } else {
      breakfasts = ['овсяная каша с фруктами', 'омлет с овощами', 'творог с ягодами'];
      lunches = ['курица с гречкой и овощами', 'рыба с рисом и салатом', 'суп с курицей'];
      dinners = ['запечённая рыба с овощами', 'куриное филе с овощами', 'творожная запеканка'];
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

  Map<String, dynamic>? _extractJson(String text) {
    try {
      final start = text.indexOf('{');
      final end = text.lastIndexOf('}');
      if (start == -1 || end == -1) return null;
      return jsonDecode(text.substring(start, end + 1)) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  List<Map<String, dynamic>>? _parseWeekPlan(String text) {
    try {
      final start = text.indexOf('[');
      final end = text.lastIndexOf(']');
      if (start != -1 && end != -1) {
        final list = jsonDecode(text.substring(start, end + 1)) as List;
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      // Модель могла вернуть объект вида {"days": [...]}
      final map = jsonDecode(text) as Map<String, dynamic>;
      final days = map['days'];
      if (days is List) {
        return days.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // --- ПЛАН ТРЕНИРОВОК ---

  /// Сгенерировать недельный план тренировок через AI.
  /// При ошибке или нехватке баланса — возвращает готовый fallback-план
  /// с упражнениями на гантелях (домашняя тренировка).
  Future<WorkoutPlan> generateWorkoutPlan({
    required String goal,
    required String gender,
    required double heightCm,
    required double currentWeightKg,
    required int age,
    required String activityLevel,
    required String equipment,
  }) async {
    final goalRu = switch (goal) {
      'loseWeight' => 'похудение (жиросжигание)',
      'gainWeight' => 'набор мышечной массы',
      _ => 'поддержание формы и тонус',
    };
    final activityRu = switch (activityLevel) {
      'sedentary' => 'сидячий образ жизни',
      'light' => 'лёгкая активность',
      'moderate' => 'умеренная активность',
      'high' => 'высокая активность',
      _ => 'умеренная активность',
    };
    final eq = equipment.toLowerCase();
    final isGym = eq.contains('зал') || eq.contains('тренажёр');
    final place = isGym ? 'тренажёрный зал' : 'дома';

    final prompt = '''
Ты — персональный фитнес-тренер. Составь недельный план тренировок для человека:
- Цель: $goalRu
- Пол: $gender
- Рост: $heightCm см, вес: $currentWeightKg кг, возраст: $age лет
- Образ жизни: $activityRu
- Место тренировок: $place
- Оборудование: ТОЛЬКО $equipment

Требования:
1. 7 дней: 4-5 тренировочных дней и 2-3 дня отдыха.
2. Для тренировочных дней — по 4-6 упражнений, доступных с этим инвентарём, НЕ предлагай то, чего нет у человека.
3. У каждого упражнения укажи: название, группу мышц, количество подходов (sets), повторения (reps), отдых (rest), сложность (difficulty: Начальный/Средний/Продвинутый), описание (description), технику выполнения из 3 коротких шагов (technique — массив строк), совет (tips).
4. Для дней отдыха: "exercises": [] и focus — «Отдых и восстановление».

Верни ТОЛЬКО JSON без markdown, в формате:
{"days":[{"day":"Понедельник","focus":"Грудь и трицепс","exercises":[{"name":"Отжимания от пола","muscle":"Грудь","equipment":"Собственный вес","sets":4,"reps":"12-15","rest":"60 сек","difficulty":"Начальный","description":"Короткое описание","technique":["Шаг 1","Шаг 2","Шаг 3"],"tips":"Совет"}]}]}
''';

    try {
      // Пробуем все доступные AI-каналы: OpenRouter → Gemini REST.
      // Если баланс закончился — переключится на другой ключ/провайдер.
      final text = await _tryAiCompletion(
        systemPrompt: 'Ты — фитнес-тренер. Отвечай только JSON.',
        userPrompt: prompt,
        maxTokens: 2000,
      ).timeout(const Duration(seconds: 55));
      if (text != null) {
        final parsed = _parseWorkoutPlan(text);
        if (parsed != null && parsed.days.isNotEmpty) return parsed;
      }
    } catch (e) {
      debugPrint('⚠️ Workout plan AI error: $e');
    }
    return _fallbackWorkoutPlan(equipment);
  }

  WorkoutPlan? _parseWorkoutPlan(String text) {
    try {
      // Модель может вернуть объект {"days": [...]}
      final start = text.indexOf('{');
      final end = text.lastIndexOf('}');
      if (start != -1 && end != -1) {
        final json = jsonDecode(text.substring(start, end + 1));
        final plan =
            WorkoutPlan.fromJson(Map<String, dynamic>.from(json as Map));
        if (plan.days.isNotEmpty) return plan;
      }
    } catch (_) {}
    try {
      // …или сразу массив дней
      final start = text.indexOf('[');
      final end = text.lastIndexOf(']');
      if (start != -1 && end != -1) {
        final list = jsonDecode(text.substring(start, end + 1)) as List;
        final plan = WorkoutPlan.fromJson({'days': list});
        if (plan.days.isNotEmpty) return plan;
      }
    } catch (_) {}
    return null;
  }

  /// Готовый план тренировок с гантелями — работает даже без интернета/баланса
  WorkoutPlan _fallbackDumbbellPlan() {
    WorkoutExercise ex({
      required String name,
      required String muscle,
      required String sets,
      required String reps,
      String rest = '60 сек',
      String difficulty = 'Средний',
      required String description,
      required List<String> technique,
      String tips = '',
    }) {
      return WorkoutExercise(
        name: name,
        muscle: muscle,
        equipment: 'Гантели',
        sets: int.tryParse(sets) ?? 3,
        reps: reps,
        rest: rest,
        difficulty: difficulty,
        description: description,
        technique: technique,
        tips: tips,
      );
    }

    return WorkoutPlan(days: [
      WorkoutDay(
        day: 'Понедельник',
        focus: 'Грудь и трицепс',
        exercises: [
          ex(
            name: 'Жим гантелей лёжа',
            muscle: 'Грудь',
            sets: '4',
            reps: '10-12',
            difficulty: 'Средний',
            description: 'Базовое упражнение на развитие грудных мышц и трицепсов с гантелями.',
            technique: [
              'Ляг на спину на коврик или скамью, ноги устойчиво на полу, гантели над грудью.',
              'Опусти гантели к груди, локти под углом ~45° к корпусу.',
              'С усилием выжми гантели вверх, полностью выпрямив руки.',
            ],
            tips: 'Не своди гантели в верхней точке — держи их на ширине плеч.',
          ),
          ex(
            name: 'Разведения гантелей лёжа',
            muscle: 'Грудь',
            sets: '3',
            reps: '12-15',
            difficulty: 'Начальный',
            description: 'Изолированное упражнение для растяжки и проработки грудных мышц.',
            technique: [
              'Ляг на спину, руки с гантелями вытянуты вверх, ладони друг к другу.',
              'Медленно разведи руки в стороны, чуть сгибая локти, до лёгкой растяжки.',
              'Верни руки вверх, сводя гантели вместе.',
            ],
            tips: 'Движение только в плечевом суставе, вес лёгкий — техника важнее.',
          ),
          ex(
            name: 'Французский жим гантелей',
            muscle: 'Трицепс',
            sets: '3',
            reps: '10-12',
            difficulty: 'Средний',
            description: 'Изолированное упражнение для задней поверхности руки — трицепса.',
            technique: [
              'Ляг на спину, гантели в вытянутых над грудью руках, ладони внутрь.',
              'Сгибая только локти, опусти гантели к голове.',
              'Разогни локти, вернув гантели в исходное положение.',
            ],
            tips: 'Локти не разводи в стороны — держи их неподвижно.',
          ),
          ex(
            name: 'Разгибания рук в наклоне',
            muscle: 'Трицепс',
            sets: '3',
            reps: '12-15',
            difficulty: 'Начальный',
            description: 'Эффективное упражнение на трицепс в положении наклона.',
            technique: [
              'Наклони корпус вперёд, спина прямая, одна рука с гантелью согнута в локте.',
              'Разогни руку назад до полного выпрямления, локоть прижат к корпусу.',
              'Плавно верни руку в исходное положение.',
            ],
            tips: 'Корпус держи неподвижно — работает только предплечье.',
          ),
        ],
      ),
      WorkoutDay(
        day: 'Вторник',
        focus: 'Спина и бицепс',
        exercises: [
          ex(
            name: 'Тяга гантелей в наклоне',
            muscle: 'Спина',
            sets: '4',
            reps: '10-12',
            difficulty: 'Средний',
            description: 'Базовое упражнение на широчайшие мышцы спины и ромбовидные.',
            technique: [
              'Наклони корпус вперёд, спина прямая, гантели в опущенных руках.',
              'Подтяни гантели к поясу, сводя лопатки вместе.',
              'Плавно опусти гантели вниз, контролируя движение.',
            ],
            tips: 'Спина всё время ровная — не округляй поясницу.',
          ),
          ex(
            name: 'Тяга одной гантели к поясу',
            muscle: 'Спина',
            sets: '3',
            reps: '10-12 на сторону',
            difficulty: 'Средний',
            description: 'Односторонняя тяга для лучшего контроля и проработки каждой стороны.',
            technique: [
              'Опрись коленом и рукой на скамью, в другой руке гантель.',
              'Подтяни гантель к поясу, локоть вдоль корпуса.',
              'Медленно опусти, полностью выпрямляя руку.',
            ],
            tips: 'Не вращай корпус — помогай только мышцами спины.',
          ),
          ex(
            name: 'Сгибания рук с гантелями',
            muscle: 'Бицепс',
            sets: '4',
            reps: '10-12',
            difficulty: 'Начальный',
            description: 'Классическое упражнение на бицепс с гантелями.',
            technique: [
              'Стоя, руки с гантелями вдоль корпуса, ладони вперёд.',
              'Согни руки в локтях, поднимая гантели к плечам.',
              'Плавно опусти гантели, полностью разгибая локти.',
            ],
            tips: 'Локти прижаты к корпусу — не раскачивайся.',
          ),
          ex(
            name: 'Молотки',
            muscle: 'Бицепс',
            sets: '3',
            reps: '12-15',
            difficulty: 'Начальный',
            description: 'Вариация сгибаний с нейтральным хватом — прорабатывает и плечо.',
            technique: [
              'Стоя, гантели в руках, ладони смотрят друг на друга.',
              'Согни руки, поднимая гантели к плечам, сохраняя нейтральный хват.',
              'Медленно опусти вниз.',
            ],
            tips: 'Держи корпус неподвижным, движение плавное.',
          ),
        ],
      ),
      WorkoutDay(
        day: 'Среда',
        focus: 'Ноги и ягодицы',
        exercises: [
          ex(
            name: 'Приседания с гантелями',
            muscle: 'Ноги',
            sets: '4',
            reps: '12-15',
            difficulty: 'Средний',
            description: 'Базовое упражнение на квадрицепсы, ягодицы и заднюю поверхность бедра.',
            technique: [
              'Встань, ноги на ширине плеч, гантели у плеч или вдоль корпуса.',
              'Присядь до угла 90° в коленях, спина прямая.',
              'Оттолкнись пятками и вернись в исходное положение.',
            ],
            tips: 'Колени не выходят за носки, пятки не отрывай от пола.',
          ),
          ex(
            name: 'Выпады назад с гантелями',
            muscle: 'Ноги',
            sets: '3',
            reps: '10-12 на ногу',
            difficulty: 'Средний',
            description: 'Отличное упражнение для ягодиц и баланса с гантелями.',
            technique: [
              'Стоя с гантелями, сделай широкий шаг назад одной ногой.',
              'Опустись, пока заднее колено не коснётся пола.',
              'Оттолкнись передней ногой и вернись в исходное положение.',
            ],
            tips: 'Переднее колено не выходит за носок, корпус вертикален.',
          ),
          ex(
            name: 'Румынская тяга с гантелями',
            muscle: 'Ноги',
            sets: '3',
            reps: '12',
            difficulty: 'Средний',
            description: 'Проработка задней поверхности бедра и ягодиц.',
            technique: [
              'Стоя, гантели перед бёдрами, колени чуть согнуты.',
              'Наклони корпус вперёд, отводя таз назад, гантели скользят вдоль ног.',
              'Почувствуй растяжение задней поверхности бедра и вернись вверх.',
            ],
            tips: 'Спину держи прямой на всём протяжении движения.',
          ),
          ex(
            name: 'Подъём на носки с гантелями',
            muscle: 'Икры',
            sets: '4',
            reps: '15-20',
            difficulty: 'Начальный',
            description: 'Упражнение для икроножных мышц с гантелями.',
            technique: [
              'Встань, гантели в руках, стопы на ширине таза.',
              'Поднимись на носки максимально высоко.',
              'Медленно опусти пятки вниз.',
            ],
            tips: 'В верхней точке задержись на 1-2 секунды.',
          ),
        ],
      ),
      WorkoutDay(
        day: 'Четверг',
        focus: 'Отдых и восстановление',
        exercises: [],
      ),
      WorkoutDay(
        day: 'Пятница',
        focus: 'Плечи и пресс',
        exercises: [
          ex(
            name: 'Жим гантелей сидя',
            muscle: 'Плечи',
            sets: '4',
            reps: '10-12',
            difficulty: 'Средний',
            description: 'Базовое упражнение на передние и средние пучки дельтовидных мышц.',
            technique: [
              'Сядь на стул/скамью, гантели на уровне плеч, локти вниз.',
              'Выжми гантели вверх, полностью выпрямив руки.',
              'Плавно опусти гантели к плечам.',
            ],
            tips: 'Не выгибай поясницу — пресс держи в напряжении.',
          ),
          ex(
            name: 'Махи гантелями в стороны',
            muscle: 'Плечи',
            sets: '3',
            reps: '12-15',
            difficulty: 'Начальный',
            description: 'Изолированное упражнение на средние пучки дельтовидных мышц.',
            technique: [
              'Стоя, руки с гантелями вдоль корпуса, локти чуть согнуты.',
              'Подними руки в стороны до уровня плеч.',
              'Медленно опусти вниз.',
            ],
            tips: 'Используй лёгкий вес — махи делаются чисто, без рывков.',
          ),
          ex(
            name: 'Скручивания с гантелью',
            muscle: 'Пресс',
            sets: '3',
            reps: '15-20',
            difficulty: 'Начальный',
            description: 'Упражнение на верхнюю часть пресса с дополнительным отягощением.',
            technique: [
              'Ляг на спину, ноги согнуты, гантель у груди.',
              'Скрути корпус, отрывая лопатки от пола.',
              'Плавно опустись обратно.',
            ],
            tips: 'Не тяни голову руками — работай мышцами живота.',
          ),
          ex(
            name: 'Планка с опорой на предплечья',
            muscle: 'Пресс',
            sets: '3',
            reps: '30-60 сек',
            difficulty: 'Средний',
            description: 'Статическое упражнение на все мышцы кора.',
            technique: [
              'Прими упор на предплечья и носки, тело — прямая линия.',
              'Напряги пресс и ягодицы, не прогибай поясницу.',
              'Удерживай положение заданное время.',
            ],
            tips: 'Дыши ровно — не задерживай дыхание.',
          ),
        ],
      ),
      WorkoutDay(
        day: 'Суббота',
        focus: 'Полное тело',
        exercises: [
          ex(
            name: 'Становая тяга с гантелями',
            muscle: 'Спина',
            sets: '3',
            reps: '10-12',
            difficulty: 'Средний',
            description: 'Комплексное упражнение на всё тело: спину, ноги и ягодицы.',
            technique: [
              'Стоя, гантели перед собой, ноги на ширине плеч.',
              'Наклонись, держа спину прямой, гантели скользят вдоль ног.',
              'Выпрямись, поднимая гантели и сжимая ягодицы.',
            ],
            tips: 'Движение начинается с таза, а не со спины.',
          ),
          ex(
            name: 'Гоблет-приседания',
            muscle: 'Ноги',
            sets: '3',
            reps: '12-15',
            difficulty: 'Начальный',
            description: 'Приседания с гантелью у груди — удобный вариант для дома.',
            technique: [
              'Держи одну гантель двумя руками у груди.',
              'Присядь, разводя колени, спина прямая.',
              'Вернись вверх, выпрямляя ноги.',
            ],
            tips: 'Гантель держи близко к груди — так легче сохранить баланс.',
          ),
          ex(
            name: 'Жим гантелей стоя',
            muscle: 'Плечи',
            sets: '3',
            reps: '10-12',
            difficulty: 'Средний',
            description: 'Жим над головой стоя — проработка плеч и кора.',
            technique: [
              'Стоя, гантели у плеч, пресс напряжён.',
              'Выжми гантели над головой, полностью выпрямив руки.',
              'Плавно опусти к плечам.',
            ],
            tips: 'Не прогибай поясницу — держи корпус стабильно.',
          ),
          ex(
            name: 'Бёрпи с гантелями',
            muscle: 'Полное тело',
            sets: '3',
            reps: '8-10',
            difficulty: 'Продвинутый',
            description: 'Интенсивное комплексное упражнение на всё тело и выносливость.',
            technique: [
              'Из положения стоя с гантелями присядь и упрись руками в пол.',
              'Отпрыгни ногами назад в упор лёжа.',
              'Верни ноги обратно, поднимись и выпрыгни вверх с гантелями.',
            ],
            tips: 'Начни без прыжка, если сложно — просто вставай и тянись вверх.',
          ),
        ],
      ),
      WorkoutDay(
        day: 'Воскресенье',
        focus: 'Отдых и растяжка',
        exercises: [],
      ),
    ]);
  }

  /// Выбрать запасной план по инвентарю пользователя.
  WorkoutPlan _fallbackWorkoutPlan(String equipment) {
    final eq = equipment.toLowerCase();
    if (eq.contains('без инвентаря') ||
        eq.contains('собственный вес') ||
        eq.contains('вес тела')) {
      return _fallbackBodyweightPlan();
    }
    if (eq.contains('зал') ||
        eq.contains('тренажёр') ||
        eq.contains('штанга')) {
      return _fallbackGymPlan();
    }
    if (eq.contains('турник') || eq.contains('резин')) {
      return _fallbackHomeCalisthenicsPlan();
    }
    return _fallbackDumbbellPlan();
  }

  /// Быстрый конструктор упражнения для запасных планов.
  WorkoutExercise _fbEx({
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
      technique: technique ?? [
        'Прими устойчивое исходное положение, спина прямая, пресс напряжён.',
        'Выполняй «$name» плавно и с полной амплитудой, без рывков.',
        'На усилии делай выдох, на расслаблении — вдох.',
      ],
      tips: tips,
    );
  }

  /// Запасной план — дома без инвентаря (только вес тела).
  WorkoutPlan _fallbackBodyweightPlan() {
    const eq = 'Собственный вес';
    return WorkoutPlan(days: [
      WorkoutDay(
        day: 'Понедельник',
        focus: 'Грудь и трицепс',
        exercises: [
          _fbEx(
            name: 'Отжимания от пола',
            muscle: 'Грудь',
            equipment: eq,
            sets: '4',
            reps: '12-15',
            difficulty: 'Начальный',
            description: 'Базовое упражнение с собственным весом на грудные мышцы и трицепс.',
            technique: [
              'Прими упор лёжа, ладони чуть шире плеч, тело — прямая линия.',
              'Опустись, сгибая локти под углом ~45°, грудь почти касается пола.',
              'Отожмись вверх, не прогибая поясницу.',
            ],
            tips: 'Если тяжело — начни с отжиманий с колен.',
          ),
          _fbEx(
            name: 'Отжимания узким хватом',
            muscle: 'Трицепс',
            equipment: eq,
            sets: '3',
            reps: '10-12',
            description: 'Отжимания с узкой постановкой рук — акцент на трицепс.',
            technique: [
              'Ладони на ширине плеч или уже, локти прижаты к корпусу.',
              'Опустись, ведя локти строго назад вдоль тела.',
              'Отожмись вверх до полного выпрямления рук.',
            ],
            tips: 'Держи локти прижатыми — так больше работает трицепс.',
          ),
          _fbEx(
            name: 'Отжимания с колен',
            muscle: 'Грудь',
            equipment: eq,
            sets: '3',
            reps: '12-15',
            difficulty: 'Начальный',
            description: 'Облегчённый вариант отжиманий для новичков.',
            technique: [
              'Встань на колени, ладони на полу чуть шире плеч.',
              'Опусти корпус вниз, сохраняя прямую линию от колен до головы.',
              'Отожмись вверх.',
            ],
          ),
          _fbEx(
            name: 'Разгибания рук от опоры',
            muscle: 'Трицепс',
            equipment: eq,
            sets: '3',
            reps: '12-15',
            description: 'Трицепс от стула или невысокой опоры — просто и эффективно.',
            technique: [
              'Встань спиной к стулу, ладони на край, ноги вытянуты вперёд.',
              'Сгибая локти, опусти таз вниз, локти назад.',
              'Отожмись вверх до прямых рук.',
            ],
            tips: 'Чем ближе ноги — тем легче упражнение.',
          ),
        ],
      ),
      WorkoutDay(
        day: 'Вторник',
        focus: 'Спина и бицепс',
        exercises: [
          _fbEx(
            name: 'Супермен (лодочка)',
            muscle: 'Спина',
            equipment: eq,
            sets: '4',
            reps: '12-15',
            description: 'Укрепляет разгибатели спины и ягодицы без инвентаря.',
            technique: [
              'Ляг на живот, руки вытянуты вперёд.',
              'Одновременно подними руки, грудь и ноги вверх.',
              'Задержись на 1-2 секунды и опустись.',
            ],
          ),
          _fbEx(
            name: 'Обратная гиперэкстензия',
            muscle: 'Спина',
            equipment: eq,
            sets: '3',
            reps: '12-15',
            description: 'Работает нижняя часть спины и ягодицы.',
            technique: [
              'Ляг на живот на край кровати/скамьи, ноги свисают.',
              'Подними прямые ноги вверх, сжимая ягодицы.',
              'Плавно опусти вниз.',
            ],
          ),
          _fbEx(
            name: 'Тяга полотенца',
            muscle: 'Спина',
            equipment: eq,
            sets: '3',
            reps: '12-15',
            description: 'Имитация тяги с помощью полотенца — проработка спины.',
            technique: [
              'Возьми полотенце за концы, руки перед собой на ширине плеч.',
              'Тяни полотенце в стороны, напрягая мышцы спины.',
              'Задержи напряжение на 2-3 секунды.',
            ],
          ),
          _fbEx(
            name: 'Сгибания рук с полотенцем',
            muscle: 'Бицепс',
            equipment: eq,
            sets: '3',
            reps: '15-20',
            description: 'Изометрическая нагрузка на бицепс без отягощения.',
            technique: [
              'Сядь на пол, полотенце за ступни, локти на коленях.',
              'Тяни полотенце к себе, напрягая бицепс.',
              'Задержи на 2 секунды и расслабься.',
            ],
          ),
        ],
      ),
      WorkoutDay(
        day: 'Среда',
        focus: 'Ноги и ягодицы',
        exercises: [
          _fbEx(
            name: 'Приседания',
            muscle: 'Ноги',
            equipment: eq,
            sets: '4',
            reps: '20-25',
            difficulty: 'Начальный',
            description: 'Классические приседания с собственным весом.',
            technique: [
              'Ноги на ширине плеч, носки чуть в стороны.',
              'Присядь до угла 90°, спина прямая, колени за носки не выходят.',
              'Оттолкнись пятками и вернись вверх.',
            ],
          ),
          _fbEx(
            name: 'Выпады назад',
            muscle: 'Ноги',
            equipment: eq,
            sets: '3',
            reps: '12-15 на ногу',
            description: 'Выпады с весом тела — ягодицы и передняя поверхность бедра.',
            technique: [
              'Шагни одной ногой назад и опустись вниз.',
              'Заднее колено почти касается пола, корпус вертикален.',
              'Вернись в исходное положение.',
            ],
          ),
          _fbEx(
            name: 'Ягодичный мостик',
            muscle: 'Ягодицы',
            equipment: eq,
            sets: '4',
            reps: '15-20',
            description: 'Изолированная работа на ягодицы.',
            technique: [
              'Ляг на спину, ноги согнуты, стопы на полу.',
              'Подними таз вверх, сжимая ягодицы в верхней точке.',
              'Плавно опустись.',
            ],
          ),
          _fbEx(
            name: 'Подъём на носки',
            muscle: 'Икры',
            equipment: eq,
            sets: '4',
            reps: '20-25',
            description: 'Проработка икроножных мышц с собственным весом.',
            technique: [
              'Встань прямо, стопы на ширине таза.',
              'Поднимись на носки максимально высоко.',
              'Медленно опусти пятки вниз.',
            ],
            tips: 'В верхней точке задержись на 1-2 секунды.',
          ),
        ],
      ),
      WorkoutDay(
        day: 'Четверг',
        focus: 'Отдых и восстановление',
        exercises: [],
      ),
      WorkoutDay(
        day: 'Пятница',
        focus: 'Плечи и пресс',
        exercises: [
          _fbEx(
            name: 'Отжимания «домик»',
            muscle: 'Плечи',
            equipment: eq,
            sets: '3',
            reps: '8-10',
            description: 'Отжимания с поднятым тазом — акцент на дельтовидные мышцы.',
            technique: [
              'Встань в позу «домик»: таз вверх, руки и ноги прямые.',
              'Сгибая локти, опусти голову к полу.',
              'Отожмись обратно.',
            ],
          ),
          _fbEx(
            name: 'Планка на предплечьях',
            muscle: 'Пресс',
            equipment: eq,
            sets: '3',
            reps: '30-60 сек',
            difficulty: 'Средний',
            description: 'Статическое упражнение на весь кор.',
            technique: [
              'Прими упор на предплечья и носки.',
              'Держи тело прямой линией, не прогибай поясницу.',
              'Удерживай положение заданное время.',
            ],
          ),
          _fbEx(
            name: 'Скручивания',
            muscle: 'Пресс',
            equipment: eq,
            sets: '3',
            reps: '15-20',
            description: 'Классические скручивания на верхний пресс.',
            technique: [
              'Ляг на спину, ноги согнуты, руки за головой.',
              'Скрути корпус, отрывая лопатки от пола.',
              'Плавно опустись.',
            ],
            tips: 'Не тяни голову руками — работай мышцами живота.',
          ),
          _fbEx(
            name: 'Велосипед',
            muscle: 'Пресс',
            equipment: eq,
            sets: '3',
            reps: '20 (всего)',
            description: 'Скручивание с имитацией езды на велосипеде — косые мышцы живота.',
            technique: [
              'Ляг на спину, руки за головой, ноги подняты.',
              'Тянись локтём к противоположному колену, выпрямляя другую ногу.',
              'Чередуй стороны.',
            ],
          ),
        ],
      ),
      WorkoutDay(
        day: 'Суббота',
        focus: 'Полное тело',
        exercises: [
          _fbEx(
            name: 'Бёрпи',
            muscle: 'Полное тело',
            equipment: eq,
            sets: '3',
            reps: '10-12',
            difficulty: 'Продвинутый',
            description: 'Интенсивное комплексное упражнение на всё тело и выносливость.',
            technique: [
              'Из положения стоя присядь и упрись руками в пол.',
              'Отпрыгни ногами назад в упор лёжа.',
              'Верни ноги обратно и выпрыгни вверх.',
            ],
            tips: 'Если сложно — пропусти прыжок, просто вставай.',
          ),
          _fbEx(
            name: 'Приседания с выпрыгиванием',
            muscle: 'Ноги',
            equipment: eq,
            sets: '3',
            reps: '12-15',
            description: 'Взрывные приседания для ног и выносливости.',
            technique: [
              'Присядь, руки перед собой.',
              'Выпрыгни вверх максимально высоко.',
              'Мягко приземлись и сразу в присед.',
            ],
          ),
          _fbEx(
            name: 'Отжимания с хлопком',
            muscle: 'Грудь',
            equipment: eq,
            sets: '3',
            reps: '8-10',
            difficulty: 'Продвинутый',
            description: 'Взрывные отжимания — сила и скорость.',
            technique: [
              'Прими упор лёжа, как в обычных отжиманиях.',
              'Мощно отожмись так, чтобы руки оторвались от пола.',
              'Сделай хлопок и приземлись на согнутые локти.',
            ],
          ),
          _fbEx(
            name: 'Альпинист',
            muscle: 'Пресс',
            equipment: eq,
            sets: '3',
            reps: '30 сек',
            description: 'Динамическое упражнение на кор и выносливость.',
            technique: [
              'Прими упор лёжа, руки под плечами.',
              'Поочерёдно подтягивай колени к груди в быстром темпе.',
              'Держи таз опущенным.',
            ],
          ),
        ],
      ),
      WorkoutDay(
        day: 'Воскресенье',
        focus: 'Отдых и растяжка',
        exercises: [],
      ),
    ]);
  }

  /// Запасной план — дома: турник и фитнес-резинки.
  WorkoutPlan _fallbackHomeCalisthenicsPlan() {
    return WorkoutPlan(days: [
      WorkoutDay(
        day: 'Понедельник',
        focus: 'Грудь и трицепс',
        exercises: [
          _fbEx(
            name: 'Отжимания от пола',
            muscle: 'Грудь',
            equipment: 'Собственный вес',
            sets: '4',
            reps: '12-15',
            difficulty: 'Начальный',
            description: 'Базовое упражнение на грудные мышцы и трицепс.',
            technique: [
              'Прими упор лёжа, ладони чуть шире плеч.',
              'Опустись, сгибая локти, грудь почти касается пола.',
              'Отожмись вверх.',
            ],
          ),
          _fbEx(
            name: 'Отжимания на брусьях (стулья)',
            muscle: 'Грудь',
            equipment: 'Собственный вес',
            sets: '3',
            reps: '10-12',
            description: 'Глубокие отжимания между двумя устойчивыми опорами.',
            technique: [
              'Поставь два стула на ширине плеч, упрись ладонями.',
              'Опустись между ними, сгибая локти.',
              'Отожмись вверх.',
            ],
          ),
          _fbEx(
            name: 'Разгибания с резинкой',
            muscle: 'Трицепс',
            equipment: 'Фитнес-резинка',
            sets: '3',
            reps: '12-15',
            description: 'Трицепс с фитнес-резинкой — лёгкая нагрузка и хороший тонус.',
            technique: [
              'Закрепи резинку наверху, возьмись за неё двумя руками.',
              'Разгибай руки вниз, локти прижаты к корпусу.',
              'Плавно верни руки вверх.',
            ],
          ),
          _fbEx(
            name: 'Отжимания узким хватом',
            muscle: 'Трицепс',
            equipment: 'Собственный вес',
            sets: '3',
            reps: '10-12',
            description: 'Акцент на трицепс с узкой постановкой рук.',
            technique: [
              'Ладони уже плеч, локти прижаты к корпусу.',
              'Опустись, ведя локти назад.',
              'Отожмись вверх.',
            ],
          ),
        ],
      ),
      WorkoutDay(
        day: 'Вторник',
        focus: 'Спина и бицепс',
        exercises: [
          _fbEx(
            name: 'Подтягивания на турнике',
            muscle: 'Спина',
            equipment: 'Турник',
            sets: '4',
            reps: '6-10',
            description: 'Королевское упражнение на широчайшие мышцы спины.',
            technique: [
              'Повисни на турнике, хват чуть шире плеч.',
              'Подтянись, сводя лопатки, грудь к перекладине.',
              'Медленно опустись до полного выпрямления рук.',
            ],
            tips: 'Если не получается — используй резинку для поддержки или негативные повторения.',
          ),
          _fbEx(
            name: 'Австралийские подтягивания',
            muscle: 'Спина',
            equipment: 'Турник',
            sets: '3',
            reps: '10-12',
            description: 'Подтягивания в низком хвате — легче классических.',
            technique: [
              'Низкий турник на уровне пояса, тело — прямая линия.',
              'Подтянись грудью к перекладине.',
              'Медленно опустись.',
            ],
          ),
          _fbEx(
            name: 'Тяга резинки к поясу',
            muscle: 'Спина',
            equipment: 'Фитнес-резинка',
            sets: '3',
            reps: '15',
            description: 'Имитация тяги в наклоне с резинкой.',
            technique: [
              'Сядь на пол, ноги прямые, резинка за стопами.',
              'Тяни резинку к поясу, сводя лопатки.',
              'Плавно разгибай руки.',
            ],
          ),
          _fbEx(
            name: 'Сгибания рук с резинкой',
            muscle: 'Бицепс',
            equipment: 'Фитнес-резинка',
            sets: '3',
            reps: '12-15',
            description: 'Сгибания на бицепс с резинкой.',
            technique: [
              'Встань на резинку, концы в руках.',
              'Согни руки в локтях, поднимая концы к плечам.',
              'Плавно опусти.',
            ],
          ),
        ],
      ),
      WorkoutDay(
        day: 'Среда',
        focus: 'Ноги и ягодицы',
        exercises: [
          _fbEx(
            name: 'Приседания',
            muscle: 'Ноги',
            equipment: 'Собственный вес',
            sets: '4',
            reps: '20-25',
            description: 'Классические приседания.',
            technique: [
              'Ноги на ширине плеч.',
              'Присядь до 90°, спина прямая.',
              'Оттолкнись пятками вверх.',
            ],
          ),
          _fbEx(
            name: 'Выпады с резинкой',
            muscle: 'Ягодицы',
            equipment: 'Фитнес-резинка',
            sets: '3',
            reps: '12-15 на ногу',
            description: 'Выпады с резинкой — ягодицы и ноги под нагрузкой.',
            technique: [
              'Надень резинку чуть выше колен.',
              'Шагни в выпад и опустись вниз.',
              'Вернись и повтори на другую ногу.',
            ],
          ),
          _fbEx(
            name: 'Ягодичный мостик с резинкой',
            muscle: 'Ягодицы',
            equipment: 'Фитнес-резинка',
            sets: '4',
            reps: '15-20',
            description: 'Мостик с резинкой над коленями — мощная нагрузка на ягодицы.',
            technique: [
              'Ляг на спину, резинка над коленями, стопы на полу.',
              'Подними таз вверх, разводя колени против резинки.',
              'Плавно опустись.',
            ],
          ),
          _fbEx(
            name: 'Подъём на носки',
            muscle: 'Икры',
            equipment: 'Собственный вес',
            sets: '4',
            reps: '20-25',
            description: 'Икроножные мышцы.',
            technique: [
              'Встань прямо.',
              'Поднимись на носки.',
              'Медленно опустись.',
            ],
          ),
        ],
      ),
      WorkoutDay(
        day: 'Четверг',
        focus: 'Отдых и восстановление',
        exercises: [],
      ),
      WorkoutDay(
        day: 'Пятница',
        focus: 'Плечи и пресс',
        exercises: [
          _fbEx(
            name: 'Подъём рук с резинкой',
            muscle: 'Плечи',
            equipment: 'Фитнес-резинка',
            sets: '3',
            reps: '15',
            description: 'Махи с резинкой — средние дельтовидные мышцы.',
            technique: [
              'Встань на резинку, концы в руках.',
              'Подними руки в стороны до уровня плеч.',
              'Медленно опусти.',
            ],
          ),
          _fbEx(
            name: 'Отжимания «домик»',
            muscle: 'Плечи',
            equipment: 'Собственный вес',
            sets: '3',
            reps: '8-10',
            description: 'Акцент на передние дельты.',
            technique: [
              'Поза «домик»: таз вверх, руки и ноги прямые.',
              'Опусти голову к полу, сгибая локти.',
              'Отожмись обратно.',
            ],
          ),
          _fbEx(
            name: 'Планка',
            muscle: 'Пресс',
            equipment: 'Собственный вес',
            sets: '3',
            reps: '30-60 сек',
            description: 'Статика на кор.',
            technique: [
              'Упор на предплечья и носки.',
              'Тело — прямая линия.',
              'Удерживай заданное время.',
            ],
          ),
          _fbEx(
            name: 'Подъём ног в висе',
            muscle: 'Пресс',
            equipment: 'Турник',
            sets: '3',
            reps: '10-15',
            description: 'Пресс и хват на турнике.',
            technique: [
              'Повисни на турнике.',
              'Подними прямые ноги до параллели с полом.',
              'Медленно опусти.',
            ],
            tips: 'Если тяжело — подтягивай колени к груди.',
          ),
        ],
      ),
      WorkoutDay(
        day: 'Суббота',
        focus: 'Полное тело',
        exercises: [
          _fbEx(
            name: 'Бёрпи',
            muscle: 'Полное тело',
            equipment: 'Собственный вес',
            sets: '3',
            reps: '10-12',
            difficulty: 'Продвинутый',
            description: 'Комплексное упражнение на всё тело.',
            technique: [
              'Присядь, упрись руками в пол.',
              'Отпрыгни ногами назад.',
              'Вернись и выпрыгни вверх.',
            ],
          ),
          _fbEx(
            name: 'Тяга резинки стоя',
            muscle: 'Спина',
            equipment: 'Фитнес-резинка',
            sets: '3',
            reps: '15',
            description: 'Вертикальная тяга резинки — спина и плечи.',
            technique: [
              'Резинка над головой или за спиной.',
              'Тяни руки вниз к бёдрам.',
              'Плавно верни вверх.',
            ],
          ),
          _fbEx(
            name: 'Отжимания',
            muscle: 'Грудь',
            equipment: 'Собственный вес',
            sets: '3',
            reps: '12-15',
            description: 'Классические отжимания.',
            technique: [
              'Упор лёжа, ладони чуть шире плеч.',
              'Опустись и отожмись.',
            ],
          ),
          _fbEx(
            name: 'Альпинист',
            muscle: 'Пресс',
            equipment: 'Собственный вес',
            sets: '3',
            reps: '30 сек',
            description: 'Динамика на кор.',
            technique: [
              'Упор лёжа, руки под плечами.',
              'Поочерёдно подтягивай колени к груди.',
            ],
          ),
        ],
      ),
      WorkoutDay(
        day: 'Воскресенье',
        focus: 'Отдых и растяжка',
        exercises: [],
      ),
    ]);
  }

  /// Запасной план — тренажёрный зал.
  WorkoutPlan _fallbackGymPlan() {
    return WorkoutPlan(days: [
      WorkoutDay(
        day: 'Понедельник',
        focus: 'Грудь и трицепс',
        exercises: [
          _fbEx(
            name: 'Жим штанги лёжа',
            muscle: 'Грудь',
            equipment: 'Штанга',
            sets: '4',
            reps: '8-10',
            difficulty: 'Средний',
            description: 'Классическое базовое упражнение на грудные мышцы.',
            technique: [
              'Ляг на скамью, ноги устойчиво на полу.',
              'Опусти штангу к груди, локти под углом ~45°.',
              'Выжми штангу вверх.',
            ],
          ),
          _fbEx(
            name: 'Жим гантелей на наклонной',
            muscle: 'Грудь',
            equipment: 'Гантели',
            sets: '3',
            reps: '10-12',
            description: 'Верх грудных мышц под другим углом.',
            technique: [
              'Скамья под углом ~30°, гантели у груди.',
              'Выжми гантели вверх.',
              'Плавно опусти.',
            ],
          ),
          _fbEx(
            name: 'Разведения гантелей лёжа',
            muscle: 'Грудь',
            equipment: 'Гантели',
            sets: '3',
            reps: '12-15',
            description: 'Изолированная растяжка грудных мышц.',
            technique: [
              'Ляг на спину, гантели вверх.',
              'Разведи руки в стороны до лёгкой растяжки.',
              'Сведи руки обратно.',
            ],
          ),
          _fbEx(
            name: 'Французский жим со штангой',
            muscle: 'Трицепс',
            equipment: 'Штанга',
            sets: '3',
            reps: '10-12',
            description: 'Изолированная работа на трицепс.',
            technique: [
              'Ляг на спину, штанга в вытянутых руках.',
              'Сгибая локти, опусти штангу к голове.',
              'Разогни локти обратно.',
            ],
          ),
        ],
      ),
      WorkoutDay(
        day: 'Вторник',
        focus: 'Спина и бицепс',
        exercises: [
          _fbEx(
            name: 'Подтягивания',
            muscle: 'Спина',
            equipment: 'Турник',
            sets: '4',
            reps: '8-12',
            description: 'Широчайшие мышцы спины.',
            technique: [
              'Хват чуть шире плеч.',
              'Подтянись к перекладине.',
              'Медленно опустись.',
            ],
          ),
          _fbEx(
            name: 'Тяга штанги в наклоне',
            muscle: 'Спина',
            equipment: 'Штанга',
            sets: '3',
            reps: '10-12',
            description: 'Толщина спины — ромбовидные и широчайшие.',
            technique: [
              'Наклон корпуса ~45°, спина прямая.',
              'Тяни штангу к поясу, сводя лопатки.',
              'Плавно опусти.',
            ],
          ),
          _fbEx(
            name: 'Тяга горизонтального блока',
            muscle: 'Спина',
            equipment: 'Тренажёр',
            sets: '3',
            reps: '12-15',
            description: 'Середина спины под контролем.',
            technique: [
              'Сядь, ноги упёрты, спина прямая.',
              'Тяни рукоять к животу.',
              'Медленно разгибай руки.',
            ],
          ),
          _fbEx(
            name: 'Сгибания рук со штангой',
            muscle: 'Бицепс',
            equipment: 'Штанга',
            sets: '3',
            reps: '10-12',
            description: 'Классика на бицепс.',
            technique: [
              'Стоя, штанга в опущенных руках.',
              'Согни руки, поднимая штангу к плечам.',
              'Плавно опусти.',
            ],
          ),
        ],
      ),
      WorkoutDay(
        day: 'Среда',
        focus: 'Ноги и ягодицы',
        exercises: [
          _fbEx(
            name: 'Приседания со штангой',
            muscle: 'Ноги',
            equipment: 'Штанга',
            sets: '4',
            reps: '8-10',
            difficulty: 'Продвинутый',
            description: 'Базовое упражнение для всего низа тела.',
            technique: [
              'Штанга на трапециях, ноги на ширине плеч.',
              'Присядь до параллели, спина прямая.',
              'Встань, отталкиваясь пятками.',
            ],
          ),
          _fbEx(
            name: 'Жим ногами',
            muscle: 'Ноги',
            equipment: 'Тренажёр',
            sets: '3',
            reps: '12',
            description: 'Квадрицепсы и ягодицы в тренажёре.',
            technique: [
              'Сядь в тренажёр, стопы на платформе.',
              'Опусти платформу до угла 90°.',
              'Выжми платформу вверх.',
            ],
          ),
          _fbEx(
            name: 'Румынская тяга',
            muscle: 'Задняя поверхность бедра',
            equipment: 'Штанга',
            sets: '3',
            reps: '10-12',
            description: 'Бицепс бедра и ягодицы.',
            technique: [
              'Штанга перед бёдрами, колени чуть согнуты.',
              'Наклони корпус, отводя таз назад.',
              'Вернись вверх, сжимая ягодицы.',
            ],
          ),
          _fbEx(
            name: 'Разгибания ног в тренажёре',
            muscle: 'Квадрицепс',
            equipment: 'Тренажёр',
            sets: '3',
            reps: '15',
            description: 'Изолированная работа на квадрицепс.',
            technique: [
              'Сядь в тренажёр, валик над стопами.',
              'Разогни ноги вверх.',
              'Плавно опусти.',
            ],
          ),
        ],
      ),
      WorkoutDay(
        day: 'Четверг',
        focus: 'Отдых и восстановление',
        exercises: [],
      ),
      WorkoutDay(
        day: 'Пятница',
        focus: 'Плечи и пресс',
        exercises: [
          _fbEx(
            name: 'Жим штанги сидя',
            muscle: 'Плечи',
            equipment: 'Штанга',
            sets: '4',
            reps: '8-10',
            description: 'Базовое упражнение на дельтовидные мышцы.',
            technique: [
              'Сядь на скамью, штанга у груди.',
              'Выжми штангу над головой.',
              'Плавно опусти.',
            ],
          ),
          _fbEx(
            name: 'Махи гантелями в стороны',
            muscle: 'Плечи',
            equipment: 'Гантели',
            sets: '3',
            reps: '12-15',
            description: 'Средние дельты.',
            technique: [
              'Стоя, гантели вдоль корпуса.',
              'Подними руки в стороны до уровня плеч.',
              'Медленно опусти.',
            ],
          ),
          _fbEx(
            name: 'Тяга к подбородку',
            muscle: 'Плечи',
            equipment: 'Штанга',
            sets: '3',
            reps: '10-12',
            description: 'Трапеции и средние дельты.',
            technique: [
              'Хват уже плеч.',
              'Тяни штангу к подбородку, локти вверх.',
              'Плавно опусти.',
            ],
          ),
          _fbEx(
            name: 'Подъём ног в висе',
            muscle: 'Пресс',
            equipment: 'Турник',
            sets: '3',
            reps: '12-15',
            description: 'Нижний пресс.',
            technique: [
              'Повисни на турнике.',
              'Подними прямые ноги вверх.',
              'Медленно опусти.',
            ],
          ),
        ],
      ),
      WorkoutDay(
        day: 'Суббота',
        focus: 'Полное тело',
        exercises: [
          _fbEx(
            name: 'Становая тяга',
            muscle: 'Спина',
            equipment: 'Штанга',
            sets: '3',
            reps: '8-10',
            difficulty: 'Продвинутый',
            description: 'Комплексное упражнение на всё тело.',
            technique: [
              'Штанга на полу, хват на ширине плеч.',
              'Выпрямись, поднимая штангу вдоль ног.',
              'Опусти штангу контролируемо.',
            ],
            tips: 'Держи спину прямой на всём протяжении движения.',
          ),
          _fbEx(
            name: 'Жим гантелей над головой',
            muscle: 'Плечи',
            equipment: 'Гантели',
            sets: '3',
            reps: '10-12',
            description: 'Плечи и стабилизаторы.',
            technique: [
              'Стоя, гантели у плеч.',
              'Выжми над головой.',
              'Плавно опусти.',
            ],
          ),
          _fbEx(
            name: 'Тяга блока к поясу',
            muscle: 'Спина',
            equipment: 'Тренажёр',
            sets: '3',
            reps: '12',
            description: 'Широчайшие под нагрузкой.',
            technique: [
              'Сядь, возьми рукоять.',
              'Тяни к животу, сводя лопатки.',
              'Медленно разгибай руки.',
            ],
          ),
          _fbEx(
            name: 'Планка с отягощением',
            muscle: 'Пресс',
            equipment: 'Блин',
            sets: '3',
            reps: '30-45 сек',
            description: 'Кор под нагрузкой.',
            technique: [
              'Упор на предплечья, блин на спине.',
              'Держи тело прямой линией.',
              'Удерживай заданное время.',
            ],
          ),
        ],
      ),
      WorkoutDay(
        day: 'Воскресенье',
        focus: 'Отдых и растяжка',
        exercises: [],
      ),
    ]);
  }

  /// Универсальная попытка получить ответ от AI.
  /// Пробует по цепочке: OpenRouter (валидные sk-or- ключи × модели) →
  /// Gemini REST напрямую (все ключи × модели). Если всё упало — null.
  Future<String?> _tryAiCompletion({
    required String systemPrompt,
    required String userPrompt,
    int maxTokens = 1000,
    List<Map<String, String>>? history,
  }) async {
    final keys = <String?>[_openRouterKey, _scannerApiKey]
        .whereType<String>()
        .toList();
    // OpenRouter принимает только ключи вида sk-or-…; остальные
    // (например ключ сканера) пропускаем, чтобы не тратить время на
    // гарантированные 401 и переходим к рабочему ключу быстрее.
    final orKeys = keys.where((k) => k.startsWith('sk-or-')).toList();

    // 1) OpenRouter — все валидные ключи и актуальные модели
    const orModels = ['google/gemini-2.5-flash', 'google/gemini-2.5-flash-lite'];
    for (final key in orKeys) {
      for (final model in orModels) {
        try {
          final messages = <Map<String, String>>[
            {'role': 'system', 'content': systemPrompt},
            if (history != null) ...history,
            {'role': 'user', 'content': userPrompt},
          ];
          final response = await http.post(
            Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
            headers: {
              'Authorization': 'Bearer $key',
              'Content-Type': 'application/json',
              'HTTP-Referer': 'https://welmi.app',
            },
            body: jsonEncode({
              'model': model,
              'max_tokens': maxTokens,
              'messages': messages,
            }),
          ).timeout(const Duration(seconds: 25));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final text = data['choices']?[0]?['message']?['content'] as String?;
            if (text != null && text.isNotEmpty) return text;
          } else {
            debugPrint('⚠️ AI HTTP ${response.statusCode} ($model)');
          }
        } catch (e) {
          debugPrint('⚠️ AI error with $model: $e');
        }
      }
    }

    // 2) Gemini REST напрямую — только ключи Google AI Studio
    // (начинаются с 'AIza'). OpenRouter-ключи здесь не работают.
    final geminiKeys = keys.where((k) => k.startsWith('AIza')).toList();
    const geminiModels = ['gemini-2.5-flash', 'gemini-2.0-flash'];
    for (final key in geminiKeys) {
      final encodedKey = Uri.encodeQueryComponent(key);
      for (final model in geminiModels) {
        try {
          final historyText = history == null
              ? ''
              : '\n\n${history.map((m) => '${m['role']}: ${m['content']}').join('\n')}';
          final response = await http.post(
            Uri.parse(
                'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$encodedKey'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {
                      'text': '$systemPrompt$historyText\n\nПользователь: $userPrompt'
                    }
                  ]
                }
              ],
              'generationConfig': {'maxOutputTokens': maxTokens},
            }),
          ).timeout(const Duration(seconds: 25));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body) as Map<String, dynamic>;
            final candidates = data['candidates'] as List?;
            if (candidates != null && candidates.isNotEmpty) {
              final content =
                  (candidates[0] as Map<String, dynamic>?)?['content']
                      as Map<String, dynamic>?;
              final parts = content?['parts'] as List?;
              if (parts != null) {
                for (final part in parts) {
                  final text = (part as Map<String, dynamic>?)?['text'] as String?;
                  if (text != null && text.isNotEmpty) return text;
                }
              }
            }
          } else {
            debugPrint('⚠️ Gemini HTTP ${response.statusCode} ($model)');
          }
        } catch (e) {
          debugPrint('⚠️ Gemini error with $model: $e');
        }
      }
    }

    return null;
  }

  // --- ЧАТ ---
  Future<String> sendChatMessage(String message) async {
    // Добавляем сообщение пользователя в историю
    _chatHistory.add(AiChatMessage(role: 'user', text: message));
    // Ограничиваем историю 10 последними сообщениями, чтобы запрос
    // укладывался в небольшой баланс аккаунта.
    // ВАЖНО: не включаем последнее сообщение пользователя в history,
    //因为它 уже передаётся через userPrompt, иначе получится
    // два подряд user-сообщения, что ломает API.
    final historyMessages = _chatHistory.length > 11
        ? _chatHistory.sublist(_chatHistory.length - 11, _chatHistory.length - 1)
        : _chatHistory.sublist(0, _chatHistory.length - 1);
    try {
      final text = await _tryAiCompletion(
        systemPrompt:
            'Ты — Welmi AI, помощник по здоровью и питанию. Отвечай на том же языке, на котором пишет пользователь: если он пишет по-русски — отвечай по-русски, по-английски — по-английски и т.д. Также приветствуй пользователя в начале диалога.',
        userPrompt: message,
        maxTokens: 1000,
        history: historyMessages
            .map((m) => {'role': m.role, 'content': m.text})
            .toList(),
      ).timeout(const Duration(seconds: 50));
      if (text != null && text.isNotEmpty) {
        _chatHistory.add(AiChatMessage(role: 'assistant', text: text));
        return text;
      }
    } catch (e) {
      debugPrint('❌ Chat Error: $e');
    }
    return 'AI недоступен. Проверьте интернет или попробуйте позже.';
  }

  // --- ГОЛОСОВЫЕ СООБЩЕНИЯ (РАСПОЗНАВАНИЕ РЕЧИ) ---

  /// Распознаёт голосовое сообщение в текст (speech-to-text).
  ///
  /// Уровни отказоустойчивости — как у сканера еды:
  ///   1) OpenRouter `/audio/transcriptions` (Whisper) — основной путь;
  ///   2) Gemini REST напрямую с `inline_data` (аудио) — запасной путь.
  ///
  /// [format] — формат записи без точки (`m4a`, `wav`, `mp3`, `ogg`).
  /// [language] — подсказка языка по ISO-639-1 (`ru`, `en`);
  ///   если null, провайдер определяет язык сам.
  /// Возвращает null, если распознать не удалось (тогда UI покажет ошибку).
  Future<String?> transcribeAudio(
    Uint8List audioBytes, {
    String format = 'm4a',
    String? language,
  }) async {
    if (audioBytes.isEmpty) return null;
    final base64Audio = base64Encode(audioBytes);

    // 1) OpenRouter Speech-to-Text. Принимает только ключи вида sk-or-…
    const sttModels = ['openai/whisper-1', 'openai/whisper-large-v3'];
    final orKeys = <String?>[_openRouterKey, _scannerApiKey]
        .whereType<String>()
        .where((k) => k.startsWith('sk-or-'))
        .toList();

    for (final key in orKeys) {
      for (final model in sttModels) {
        try {
          final response = await http
              .post(
                Uri.parse('https://openrouter.ai/api/v1/audio/transcriptions'),
                headers: {
                  'Authorization': 'Bearer $key',
                  'Content-Type': 'application/json',
                  'HTTP-Referer': 'https://welmi.app',
                },
                body: jsonEncode({
                  'model': model,
                  'input_audio': {'data': base64Audio, 'format': format},
                  if (language != null) 'language': language,
                }),
              )
              .timeout(const Duration(seconds: 45));

          if (response.statusCode == 200) {
            final text = (jsonDecode(response.body) as Map)['text'] as String?;
            if (text != null && text.trim().isNotEmpty) return text.trim();
          } else {
            debugPrint('⚠️ STT HTTP ${response.statusCode} ($model)');
          }
        } catch (e) {
          debugPrint('⚠️ STT error with $model: $e');
        }
      }
    }

    // 2) Gemini REST напрямую: аудио передаётся как inline_data
    final geminiKeys = <String?>[_scannerApiKey, _openRouterKey]
        .whereType<String>()
        .where((k) => !k.startsWith('sk-or-'))
        .toList();
    const geminiModels = ['gemini-2.5-flash', 'gemini-2.0-flash'];
    const sttPrompt =
        'Распознай речь в этом аудио и верни ТОЛЬКО текст без пояснений. '
        'Сохрани исходный язык говорящего и знаки препинания.';

    for (final key in geminiKeys) {
      final encodedKey = Uri.encodeQueryComponent(key);
      for (final model in geminiModels) {
        try {
          final response = await http
              .post(
                Uri.parse(
                    'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$encodedKey'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'contents': [
                    {
                      'parts': [
                        {'text': sttPrompt},
                        {
                          'inline_data': {
                            'mime_type': _audioMimeType(format),
                            'data': base64Audio,
                          }
                        }
                      ]
                    }
                  ],
                  'generationConfig': {'maxOutputTokens': 1000},
                }),
              )
              .timeout(const Duration(seconds: 45));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body) as Map<String, dynamic>;
            final candidates = data['candidates'] as List?;
            if (candidates != null && candidates.isNotEmpty) {
              final content =
                  (candidates[0] as Map<String, dynamic>?)?['content']
                      as Map<String, dynamic>?;
              final parts = content?['parts'] as List?;
              if (parts != null) {
                final buffer = StringBuffer();
                for (final part in parts) {
                  final text = (part as Map<String, dynamic>?)?['text'] as String?;
                  if (text != null) buffer.write(text);
                }
                final result = buffer.toString().trim();
                if (result.isNotEmpty) return result;
              }
            }
          } else {
            debugPrint('⚠️ STT Gemini HTTP ${response.statusCode} ($model)');
          }
        } catch (e) {
          debugPrint('⚠️ STT Gemini error with $model: $e');
        }
      }
    }

    return null;
  }

  /// MIME-тип аудио для Gemini REST (m4a — это контейнер с AAC внутри).
  static String _audioMimeType(String format) {
    switch (format.toLowerCase()) {
      case 'wav':
        return 'audio/wav';
      case 'mp3':
        return 'audio/mp3';
      case 'ogg':
      case 'opus':
        return 'audio/ogg';
      case 'flac':
        return 'audio/flac';
      case 'webm':
        return 'audio/webm';
      case 'aac':
      case 'm4a':
      case 'mp4':
        return 'audio/aac';
      default:
        return 'audio/wav';
    }
  }

  // --- СКАНЕР ---
  Future<FoodAnalysisResult?> analyzeFoodImage(Uint8List imageBytes) async {
    const prompt = '''Проанализируй фото еды. Определи название, вес порции (г), калории, белки, жиры, углеводы. 
Верни результат СТРОГО в формате JSON на русском:
{
  "name": "название",
  "calories": 250,
  "protein_grams": 15,
  "fat_grams": 10,
  "carbs_grams": 30,
  "amount_grams": 200,
  "description": "краткое описание"
}''';
    final base64Image = base64Encode(imageBytes);
    // Актуальные vision-модели (старые ':free' удалены с OpenRouter)
    const models = [
      'google/gemini-2.5-flash',
      'google/gemini-2.5-flash-lite',
    ];

    // 1) Сначала основной (рабочий) ключ, затем отдельный ключ сканера.
    //    Пока ключ сканера не подтверждён — сканер работает через основной.
    for (final key in [_openRouterKey, _scannerApiKey]) {
      if (key == null) continue;
      final res = await _tryOpenRouterScan(key, prompt, base64Image, models);
      if (res != null) return res;
    }

    // 2) Если ключ не работает через OpenRouter — пробуем Gemini REST напрямую
    if (_scannerApiKey != null) {
      final res =
          await _tryGeminiRestScan(_scannerApiKey!, prompt, base64Image);
      if (res != null) return res;
    }

    return null;
  }

  Future<FoodAnalysisResult?> _tryOpenRouterScan(
    String key,
    String prompt,
    String base64Image,
    List<String> models,
  ) async {
    for (final model in models) {
      try {
        final response = await http.post(
          Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
          headers: {
            'Authorization': 'Bearer $key',
            'Content-Type': 'application/json',
            'HTTP-Referer': 'https://welmi.app',
          },
          body: jsonEncode({
            'model': model,
            'max_tokens': 500,
            'messages': [
              {
                'role': 'user',
                'content': [
                  {'type': 'text', 'text': prompt},
                  {
                    'type': 'image_url',
                    'image_url': {'url': 'data:image/jpeg;base64,$base64Image'}
                  }
                ]
              }
            ]
          }),
        ).timeout(const Duration(seconds: 35));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final text = data['choices'][0]['message']['content'] as String;
          final res = _parseJson(text);
          if (res != null) return res;
        } else {
          debugPrint('❌ Scanner HTTP ${response.statusCode} ($model)');
        }
      } catch (e) {
        debugPrint('❌ Scanner Error with $model: $e');
      }
    }
    return null;
  }

  Future<FoodAnalysisResult?> _tryGeminiRestScan(
    String key,
    String prompt,
    String base64Image,
  ) async {
    // Ключ в query-строку нужно кодировать: он может содержать символы
    // '+', '/' и т.п., которые ломают URL (в query '+' читается как пробел).
    final encodedKey = Uri.encodeQueryComponent(key);
    const models = ['gemini-2.5-flash', 'gemini-2.0-flash'];
    for (final model in models) {
      try {
        final response = await http.post(
          Uri.parse(
              'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$encodedKey'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt},
                  {
                    'inline_data': {
                      'mime_type': 'image/jpeg',
                      'data': base64Image
                    }
                  },
                ]
              }
            ]
          }),
        ).timeout(const Duration(seconds: 35));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final candidates = data['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final content =
                (candidates[0] as Map<String, dynamic>)['content']
                    as Map<String, dynamic>?;
            final parts = content?['parts'] as List?;
            if (parts != null) {
              for (final part in parts) {
                final text = (part as Map<String, dynamic>)['text'] as String?;
                if (text != null && text.isNotEmpty) {
                  final res = _parseJson(text);
                  if (res != null) return res;
                }
              }
            }
          }
        } else {
          debugPrint('❌ Scanner Gemini HTTP ${response.statusCode} ($model)');
        }
      } catch (e) {
        debugPrint('❌ Scanner Gemini Error with $model: $e');
      }
    }
    return null;
  }

  FoodAnalysisResult? _parseJson(String text) {
    try {
      final start = text.indexOf('{');
      final end = text.lastIndexOf('}');
      if (start == -1 || end == -1) return null;
      return FoodAnalysisResult.fromJson(jsonDecode(text.substring(start, end + 1)));
    } catch (_) { return null; }
  }

  List<AiChatMessage> get chatHistory => List.unmodifiable(_chatHistory);
  void startNewChat() => _chatHistory.clear();
  Future<void> saveChatHistory() async {}
  Future<void> loadChatHistory() async {}
}
