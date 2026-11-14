import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumina/core/theme/app_palette.dart';
import 'package:lumina/core/theme/app_theme.dart';
import 'package:lumina/core/widgets/animated_count.dart';
import 'package:lumina/core/widgets/pressable.dart';
import 'package:lumina/features/home/presentation/widgets/home_calorie_ring_card.dart';
import 'package:lumina/features/home/presentation/widgets/home_stat_tile.dart';
import 'package:lumina/l10n/app_localizations.dart';

Widget _app(Widget child, {bool reduceMotion = false, double textScale = 1}) =>
    MaterialApp(
      locale: const Locale('ru'),
      theme: AppTheme.build(AppPalette.light, textTheme: const TextTheme()),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: reduceMotion,
          textScaler: TextScaler.linear(textScale),
        ),
        child: app!,
      ),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  group('HomeMacroValue.progress', () {
    test('без нормы — ноль, а не деление на ноль', () {
      const m = HomeMacroValue(label: 'Белки', total: 50, goal: 0);
      expect(m.progress, 0);
    });

    test('перебор не выходит за 100%', () {
      const m = HomeMacroValue(label: 'Белки', total: 300, goal: 120);
      expect(m.progress, 1);
    });

    test('обычная доля', () {
      const m = HomeMacroValue(label: 'Белки', total: 30, goal: 120);
      expect(m.progress, closeTo(0.25, 1e-9));
    });
  });

  group('AnimatedCount', () {
    testWidgets('досчитывает до нового значения', (tester) async {
      await tester.pumpWidget(_app(const AnimatedCount(value: 100)));
      expect(find.text('100'), findsOneWidget);

      await tester.pumpWidget(_app(const AnimatedCount(value: 500)));
      await tester.pump(const Duration(milliseconds: 100));
      // Идёт счёт: на экране промежуточное число.
      expect(find.text('500'), findsNothing);

      await tester.pumpAndSettle();
      expect(find.text('500'), findsOneWidget);
    });

    testWidgets('при «уменьшить движение» меняется сразу', (tester) async {
      await tester.pumpWidget(
        _app(const AnimatedCount(value: 100), reduceMotion: true),
      );
      await tester.pumpWidget(
        _app(const AnimatedCount(value: 500), reduceMotion: true),
      );
      await tester.pump();
      expect(find.text('500'), findsOneWidget);
    });

    testWidgets('формат применяется к числу', (tester) async {
      await tester.pumpWidget(
        _app(AnimatedCount(value: 7, format: (v) => '$v мл')),
      );
      expect(find.text('7 мл'), findsOneWidget);
    });
  });

  group('Pressable', () {
    testWidgets('нажатие вызывает действие и объявлено кнопкой', (
      tester,
    ) async {
      var taps = 0;
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          Pressable(
            onTap: () => taps++,
            semanticLabel: 'Вода: 500 мл',
            child: const SizedBox(width: 120, height: 80),
          ),
        ),
      );

      await tester.tap(find.byType(Pressable));
      await tester.pumpAndSettle();
      expect(taps, 1);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Вода: 500 мл')),
        matchesSemantics(
          label: 'Вода: 500 мл',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          hasFocusAction: true,
          isFocusable: true,
        ),
      );
      handle.dispose();
    });
  });

  group('главная на узком экране с крупным шрифтом', () {
    Future<void> useSmallPhone(WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }

    testWidgets('кольцо калорий не переполняется', (tester) async {
      await useSmallPhone(tester);
      await tester.pumpWidget(
        _app(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: HomeCalorieRingCard(
              remaining: 12345,
              goal: 23456,
              progress: 1.4,
              macros: [
                HomeMacroValue(label: 'Углеводы', total: 1234, goal: 2345),
                HomeMacroValue(label: 'Белки', total: 123, goal: 234),
                HomeMacroValue(label: 'Жиры', total: 12, goal: 0),
              ],
            ),
          ),
          textScale: 1.5,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('12345'), findsOneWidget);
    });

    // Высота плитки на главной: 104 × системный масштаб шрифта (не больше
    // 1.6) — та же формула, что в сетке HomePage.
    for (final scale in [1.0, 1.3, 1.6]) {
      testWidgets('плитка статистики при шрифте ×$scale не переполняется', (
        tester,
      ) async {
        await useSmallPhone(tester);
        var taps = 0;
        await tester.pumpWidget(
          _app(
            SizedBox(
              width: 132,
              height: 104 * scale,
              child: HomeStatTile(
                label: 'Очень длинная подпись раздела',
                value: '1234567.8 lb',
                icon: Icons.monitor_weight_outlined,
                color: Colors.purple,
                onTap: () => taps++,
              ),
            ),
            textScale: scale,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.tap(find.byType(HomeStatTile));
        await tester.pumpAndSettle();
        expect(taps, 1);
      });
    }
  });
}
