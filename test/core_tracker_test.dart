import 'package:flutter_test/flutter_test.dart';
import 'package:lumina/core/services/supabase/supabase_base.dart';
import 'package:lumina/core/services/tracker/daily_snapshot.dart';

void main() {
  group('nextStreak', () {
    const today = '2026-10-22';
    const yesterday = '2026-10-21';

    test('сегодня уже посчитано — без изменений', () {
      expect(
        nextStreak(
          lastDate: today,
          stored: 4,
          today: today,
          yesterday: yesterday,
          metGoal: true,
        ),
        isNull,
      );
    });

    test('цель выполнена после вчерашнего дня — стрик растёт', () {
      final r = nextStreak(
        lastDate: yesterday,
        stored: 4,
        today: today,
        yesterday: yesterday,
        metGoal: true,
      )!;
      expect(r.streak, 5);
    });

    test('цель выполнена после пропуска — стрик начинается заново', () {
      final r = nextStreak(
        lastDate: '2026-10-10',
        stored: 4,
        today: today,
        yesterday: yesterday,
        metGoal: true,
      )!;
      expect(r.streak, 1);
    });

    test('цель не выполнена и был пропуск — стрик сбрасывается', () {
      final r = nextStreak(
        lastDate: '2026-10-10',
        stored: 4,
        today: today,
        yesterday: yesterday,
        metGoal: false,
      )!;
      expect(r.streak, 0);
      expect(r.reset, isTrue);
    });

    test('цель пока не выполнена, вчера засчитано — стрик сохраняется', () {
      final r = nextStreak(
        lastDate: yesterday,
        stored: 4,
        today: today,
        yesterday: yesterday,
        metGoal: false,
      )!;
      expect(r.streak, 4);
      expect(r.reset, isFalse);
    });
  });

  group('DailySnapshot', () {
    test('сериализация туда и обратно', () {
      const s = DailySnapshot(
        date: '2026-10-22T00:00:00.000',
        calories: 1500,
        protein: 90,
        fat: 50,
        carbs: 160,
        water: 1750,
        steps: 8000,
        burned: 280,
        meals: {'breakfast': 400, 'lunch': 700},
      );
      final back = DailySnapshot.fromJson(s.toJson());
      expect(back.calories, 1500);
      expect(back.water, 1750);
      expect(back.meals, {'breakfast': 400, 'lunch': 700});
    });

    test('повреждённые и дробные значения не роняют чтение кэша', () {
      final s = DailySnapshot.fromJson({
        'date': '2026-10-22',
        'calories': 1200.0,
        'water': 'мусор',
        'meals': {'lunch': 300.4, 'dinner': null},
      });
      expect(s.calories, 1200);
      expect(s.water, 0);
      expect(s.meals, {'lunch': 300});
    });

    test('кэш вчерашнего дня не применяется', () {
      const s = DailySnapshot(
        date: '2026-10-21T00:00:00.000',
        calories: 0,
        protein: 0,
        fat: 0,
        carbs: 0,
        water: 0,
        steps: 0,
        burned: 0,
        meals: {},
      );
      expect(s.isFor(DateTime(2026, 10, 21)), isTrue);
      expect(s.isFor(DateTime(2026, 10, 22)), isFalse);
    });
  });

  test('day() форматирует дату для колонки date', () {
    expect(SupabaseQueryBase.day(DateTime(2026, 3, 7, 23, 59)), '2026-03-07');
  });
}
