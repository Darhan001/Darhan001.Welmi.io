import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumina/core/theme/app_palette.dart';
import 'package:lumina/core/theme/app_theme.dart';
import 'package:lumina/core/widgets/app_button.dart';
import 'package:lumina/core/widgets/app_card.dart';
import 'package:lumina/core/widgets/app_skeleton.dart';
import 'package:lumina/core/widgets/press_scale.dart';
import 'package:lumina/core/widgets/ux_helpers.dart';

Widget _app(Widget child, {bool reduceMotion = false}) => MaterialApp(
  theme: AppTheme.build(AppPalette.light, textTheme: const TextTheme()),
  builder: (context, app) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
    child: app!,
  ),
  home: Scaffold(body: Center(child: child)),
);

/// Непрозрачная область: касание должно во что-то попасть, как в кнопку.
class _Target extends StatelessWidget {
  const _Target();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: Colors.black,
    child: SizedBox(width: 100, height: 60),
  );
}

double _scaleOf(WidgetTester tester) => tester
    .widget<AnimatedScale>(
      find.descendant(
        of: find.byType(PressScale),
        matching: find.byType(AnimatedScale),
      ),
    )
    .scale;

void main() {
  group('PressScale', () {
    testWidgets('проседает под пальцем и возвращается', (tester) async {
      await tester.pumpWidget(_app(const PressScale(child: _Target())));
      expect(_scaleOf(tester), 1);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PressScale)),
      );
      await tester.pump();
      expect(_scaleOf(tester), lessThan(1));

      await gesture.up();
      await tester.pumpAndSettle();
      expect(_scaleOf(tester), 1);
    });

    testWidgets('не двигается при «уменьшить движение»', (tester) async {
      await tester.pumpWidget(
        _app(const PressScale(child: _Target()), reduceMotion: true),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PressScale)),
      );
      await tester.pump();
      expect(_scaleOf(tester), 1);
      await gesture.up();
    });

    testWidgets('неактивная кнопка не проседает', (tester) async {
      await tester.pumpWidget(_app(const AppButton(text: 'Сохранить')));
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(AppButton)),
      );
      await tester.pump();
      expect(_scaleOf(tester), 1);
      await gesture.up();
    });
  });

  testWidgets('кнопка и карточка по-прежнему срабатывают по нажатию', (
    tester,
  ) async {
    var button = 0;
    var card = 0;
    await tester.pumpWidget(
      _app(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppButton(text: 'Далее', onPressed: () => button++),
            AppCard(onTap: () => card++, child: const Text('Карточка')),
          ],
        ),
      ),
    );
    await tester.tap(find.text('Далее'));
    await tester.tap(find.text('Карточка'));
    await tester.pumpAndSettle();
    expect(button, 1);
    expect(card, 1);
  });

  group('AppSkeleton', () {
    testWidgets('при «уменьшить движение» не анимируется', (tester) async {
      await tester.pumpWidget(
        _app(const AppSkeleton(width: 200, height: 40), reduceMotion: true),
      );
      // pumpAndSettle завершается только если нет идущих анимаций.
      await tester.pumpAndSettle();
      expect(find.byType(AppSkeleton), findsOneWidget);
    });

    testWidgets('пульсирует и корректно освобождается', (tester) async {
      await tester.pumpWidget(_app(const AppSkeleton(width: 200, height: 40)));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.hasRunningAnimations, isTrue);

      await tester.pumpWidget(_app(const SizedBox()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('переход между экранами: открывается, закрывается «Назад»', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.push(
              context,
              smoothPageRoute<void>(
                Scaffold(appBar: AppBar(), body: const Text('Второй экран')),
              ),
            ),
            child: const Text('Открыть'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Открыть'));
    await tester.pumpAndSettle();
    expect(find.text('Второй экран'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Второй экран'), findsNothing);
    expect(find.text('Открыть'), findsOneWidget);
  });

  test('шрифт Inter лежит в сборке вместе с лицензией', () {
    for (final name in [
      'Inter-Regular.ttf',
      'Inter-Medium.ttf',
      'Inter-SemiBold.ttf',
      'Inter-Bold.ttf',
      'Inter-ExtraBold.ttf',
      'Inter-Black.ttf',
      'Inter-OFL.txt',
    ]) {
      expect(
        File('assets/google_fonts/$name').existsSync(),
        isTrue,
        reason: name,
      );
    }
    expect(
      File('pubspec.yaml').readAsStringSync(),
      contains('- assets/google_fonts/'),
    );
  });
}
