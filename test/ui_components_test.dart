import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumina/core/services/units_service.dart';
import 'package:lumina/core/widgets/app_app_bar.dart';
import 'package:lumina/features/notifications/presentation/pages/notifications_page.dart';
import 'package:lumina/features/weight/presentation/widgets/record_weight_sheet.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:lumina/l10n/app_localizations_ru.dart';
import 'package:lumina/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app(Widget home) => MaterialApp(
  locale: const Locale('ru'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: home,
);

/// Открывает шторку кнопкой и возвращает результат через [onResult].
Widget _sheetHost({
  required double? initialKg,
  required Future<void> Function(double kg) onSave,
  required void Function(bool saved) onResult,
}) {
  return _app(
    Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () async => onResult(
              await showRecordWeightSheet(
                context,
                initialKg: initialKg,
                onSave: onSave,
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await UnitsService.instance.load();
    await UnitsService.instance.setSystem(UnitSystem.metric);
  });

  group('RecordWeightSheet', () {
    testWidgets('сохраняет вес, введённый через запятую', (tester) async {
      double? savedKg;
      bool? result;
      await tester.pumpWidget(
        _sheetHost(
          initialKg: null,
          onSave: (kg) async => savedKg = kg,
          onResult: (r) => result = r,
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '72,5');
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();

      expect(savedKg, 72.5);
      expect(result, isTrue);
      expect(find.byType(RecordWeightSheet), findsNothing);
    });

    testWidgets('без истории поле пустое, а не выдуманный вес', (tester) async {
      await tester.pumpWidget(
        _sheetHost(initialKg: null, onSave: (_) async {}, onResult: (_) {}),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, isEmpty);
    });

    testWidgets('некорректный вес показывает ошибку и не сохраняет', (
      tester,
    ) async {
      var calls = 0;
      await tester.pumpWidget(
        _sheetHost(
          initialKg: 70,
          onSave: (_) async => calls++,
          onResult: (_) {},
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '725');
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();

      expect(calls, 0);
      expect(find.text(AppLocalizationsRu().weightInvalid), findsOneWidget);
      expect(find.byType(RecordWeightSheet), findsOneWidget);
    });

    testWidgets('ошибка сети остаётся в шторке и сообщается', (tester) async {
      bool? result;
      await tester.pumpWidget(
        _sheetHost(
          initialKg: 70,
          onSave: (_) async => throw Exception('offline'),
          onResult: (r) => result = r,
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();

      expect(find.text(AppLocalizationsRu().weightSaveError), findsOneWidget);
      expect(find.byType(RecordWeightSheet), findsOneWidget);
      expect(result, isNull);
    });

    testWidgets('в фунтах сохраняет килограммы', (tester) async {
      await UnitsService.instance.setSystem(UnitSystem.imperial);
      double? savedKg;
      await tester.pumpWidget(
        _sheetHost(
          initialKg: null,
          onSave: (kg) async => savedKg = kg,
          onResult: (_) {},
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('lb'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '154.3');
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();

      expect(savedKg, closeTo(70, 0.05));
    });
  });

  group('AppAppBar', () {
    testWidgets('кнопки шапки имеют зону нажатия не меньше 48×48', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: AppAppBar(
              title:
                  'Очень длинный заголовок экрана, который не должен ломать шапку',
              actions: [
                AppBarActionButton(
                  icon: Icons.tune,
                  tooltip: 'Настройки',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      );

      final backTooltip = MaterialLocalizations.of(
        tester.element(find.byType(AppAppBar)),
      ).backButtonTooltip;
      final back = tester.getSize(find.byTooltip(backTooltip));
      expect(back.width, greaterThanOrEqualTo(48));
      expect(back.height, greaterThanOrEqualTo(48));
      expect(
        tester.getSize(find.byTooltip('Настройки')).width,
        greaterThanOrEqualTo(48),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('нажатие действия вызывает обработчик', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: AppAppBar(
              title: 'T',
              actions: [
                AppBarActionButton(
                  icon: Icons.tune,
                  tooltip: 'A',
                  onTap: () => taps++,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.byTooltip('A'));
      expect(taps, 1);
    });
  });

  group('buildReminderSchedule', () {
    NotificationSettings settings({
      bool water = true,
      bool breakfast = true,
      bool lunch = true,
      bool dinner = true,
      bool activity = true,
      bool evening = true,
    }) => NotificationSettings(
      masterEnabled: true,
      waterEnabled: water,
      waterIntervalMin: 120,
      waterStartMin: 8 * 60,
      waterEndMin: 22 * 60,
      breakfastEnabled: breakfast,
      breakfastMin: 7 * 60 + 30,
      lunchEnabled: lunch,
      lunchMin: 13 * 60,
      dinnerEnabled: dinner,
      dinnerMin: 19 * 60,
      activityEnabled: activity,
      activityMin: 18 * 60,
      eveningEnabled: evening,
      eveningMin: 21 * 60 + 30,
    );

    String fmt(int m) =>
        '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';

    test('показывает только включённые напоминания по порядку времени', () {
      final loc = AppLocalizationsRu();
      final list = buildReminderSchedule(
        settings(water: false, activity: false),
        loc,
        fmt,
      );
      expect(list.map((r) => r.title), [
        loc.breakfast,
        loc.lunch,
        loc.dinner,
        loc.notifEvening,
      ]);
      expect(list.first.subtitle, '07:30');
    });

    test('вода показывает интервал и окно времени', () {
      final loc = AppLocalizationsRu();
      final water = buildReminderSchedule(
        settings(),
        loc,
        fmt,
      ).firstWhere((r) => r.title == loc.waterReminders);
      expect(water.subtitle, '${loc.notifEvery2h} · 08:00–22:00');
    });

    test('все выключены — пустой список (экран покажет пустое состояние)', () {
      final list = buildReminderSchedule(
        settings(
          water: false,
          breakfast: false,
          lunch: false,
          dinner: false,
          activity: false,
          evening: false,
        ),
        AppLocalizationsRu(),
        fmt,
      );
      expect(list, isEmpty);
    });
  });
}
