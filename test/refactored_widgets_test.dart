import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumina/core/models/workout_plan.dart';
import 'package:lumina/core/services/ai/ai_food_models.dart';
import 'package:lumina/core/theme/app_palette.dart';
import 'package:lumina/core/theme/app_theme.dart';
import 'package:lumina/features/chat/presentation/widgets/chat_welcome_view.dart';
import 'package:lumina/features/diary/presentation/widgets/voice_food_items_card.dart';
import 'package:lumina/features/history/presentation/widgets/history_day_card.dart';
import 'package:lumina/features/home/presentation/widgets/home_calorie_ring_card.dart';
import 'package:lumina/features/settings/presentation/widgets/settings_nav_tile.dart';
import 'package:lumina/features/settings/presentation/widgets/settings_switch_tile.dart';
import 'package:lumina/features/workout/presentation/widgets/exercise_set_views.dart';
import 'package:lumina/features/workout/presentation/widgets/workout_plan_views.dart';
import 'package:lumina/l10n/app_localizations.dart';

Widget _app(Widget child) => MaterialApp(
  locale: const Locale('ru'),
  theme: AppTheme.build(AppPalette.light, textTheme: const TextTheme()),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: Scaffold(
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: child,
    ),
  ),
);

/// Полноэкранный хост: для виджетов, которые занимают всю высоту
/// (внутри есть Expanded).
Widget _page(Widget child) => MaterialApp(
  locale: const Locale('ru'),
  theme: AppTheme.build(AppPalette.light, textTheme: const TextTheme()),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: Scaffold(body: child),
);

void main() {
  setUp(() {
    // Карточки рассчитаны на телефонную ширину.
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('история: карточка дня с метриками и упражнением', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const HistoryDayCard(
          dateLabel: 'Вчера',
          isToday: false,
          stepsLabel: '8к',
          waterMl: 1500,
          calories: 320,
          minutes: 45,
          distanceLabel: '3.5',
          distanceUnit: 'км',
          exercises: [
            {'name': 'Приседания', 'sets': 3, 'reps': 15},
          ],
        ),
      ),
    );

    expect(find.text('Вчера'), findsOneWidget);
    expect(find.text('Приседания'), findsOneWidget);
    expect(find.text('3×15'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('история: сводка за период', (tester) async {
    await tester.pumpWidget(
      _app(
        const HistorySummaryCard(
          steps: '120к',
          waterLiters: '18.4',
          activeDays: 9,
        ),
      ),
    );

    expect(find.text('9'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('главная: кольцо калорий с макросами', (tester) async {
    await tester.pumpWidget(
      _app(
        const HomeCalorieRingCard(
          remaining: 1250,
          goal: 2100,
          progress: 0.4,
          macros: [
            HomeMacroValue(label: 'Белки', total: 90, goal: 140),
            HomeMacroValue(label: 'Жиры', total: 50, goal: 70),
            HomeMacroValue(label: 'Углеводы', total: 120, goal: 240),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1250'), findsOneWidget);
    expect(find.text('90 / 140г'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('тренировки: карточка упражнения и строка подхода', (
    tester,
  ) async {
    final exercise = WorkoutExercise(name: 'Жим гантелей', muscle: 'Грудь');
    await tester.pumpWidget(
      _app(
        Column(
          children: [
            WorkoutExerciseCard(exercise: exercise, onTap: () {}),
            ExerciseSetRow(
              index: 0,
              reps: '12',
              weight: '10',
              isDone: false,
              canRemove: true,
              accent: const Color(0xFFC6FF00),
              onEditReps: () {},
              onEditWeight: () {},
              onToggle: () {},
              onRemove: () {},
            ),
          ],
        ),
      ),
    );

    expect(find.text('Жим гантелей'), findsOneWidget);
    expect(find.text('3 х 10-12'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('настройки: переключатель и строка перехода', (tester) async {
    await tester.pumpWidget(
      _app(
        Column(
          children: [
            SettingsSwitchTile(
              icon: Icons.fingerprint,
              title: 'Вход по биометрии',
              subtitle: 'Быстрый вход в приложение',
              value: true,
              onChanged: (_) {},
              isDark: false,
            ),
            const SettingsNavTile(
              icon: Icons.monitor_heart_outlined,
              title: 'Google Fit / Apple Health',
              subtitle: 'Синхронизация шагов',
              isDark: false,
              trailing: SettingsStatusBadge(
                connected: true,
                connectedLabel: '✓',
                actionLabel: 'Подключить',
              ),
            ),
          ],
        ),
      ),
    );

    expect(find.text('Вход по биометрии'), findsOneWidget);
    expect(find.text('✓'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('чат: приветственный экран с подсказками', (tester) async {
    String? suggestion;
    await tester.pumpWidget(
      _page(
        ChatWelcomeView(
          inputArea: const SizedBox(height: 60),
          onSuggestion: (text) => suggestion = text,
        ),
      ),
    );

    await tester.tap(find.text('Скорректировать план'));
    expect(suggestion, 'Скорректировать план');
    expect(tester.takeException(), isNull);
  });

  testWidgets('диалог голосового ввода: список продуктов', (tester) async {
    await tester.pumpWidget(
      _app(
        VoiceFoodItemsCard(
          items: [
            VoiceFoodItem(
              name: 'Яйцо',
              portion: '2 шт.',
              calories: 140,
              proteinGrams: 12,
              fatGrams: 10,
              carbsGrams: 1,
            ),
          ],
        ),
      ),
    );

    expect(find.text('Яйцо — 2 шт.'), findsOneWidget);
    expect(find.text('~140 ккал'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
