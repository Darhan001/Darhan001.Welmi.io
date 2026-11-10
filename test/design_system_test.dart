import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumina/core/theme/app_palette.dart';
import 'package:lumina/core/theme/app_theme.dart';
import 'package:lumina/core/theme/app_tokens.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/theme/theme_mode_controller.dart';
import 'package:lumina/core/widgets/app_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Без google_fonts: в тестах шрифты по сети не загружаются.
const _text = TextTheme();
final _light = AppTheme.build(AppPalette.light, textTheme: _text);
final _dark = AppTheme.build(AppPalette.dark, textTheme: _text);

Widget _host(ThemeData theme, Widget child) => MaterialApp(
  theme: theme,
  home: Scaffold(body: Center(child: child)),
);

final _anyButton = find.byWidgetPredicate((w) => w is ButtonStyleButton);

ButtonStyle _styleOf(WidgetTester tester) =>
    tester.widget<ButtonStyleButton>(_anyButton).style!;

void main() {
  group('ThemeModeController', () {
    test('кодирует и декодирует все режимы', () {
      for (final mode in ThemeMode.values) {
        expect(
          ThemeModeController.decode(ThemeModeController.encode(mode)),
          mode,
        );
      }
      expect(ThemeModeController.decode(null), ThemeMode.system);
      expect(ThemeModeController.decode('мусор'), ThemeMode.system);
    });

    test('загружает сохранённый режим и сохраняет новый', () async {
      SharedPreferences.setMockInitialValues({
        ThemeModeController.storageKey: 'dark',
      });
      final controller = ThemeModeController();
      var notified = 0;
      controller.addListener(() => notified++);

      await controller.load();
      expect(controller.mode, ThemeMode.dark);

      await controller.setMode(ThemeMode.light);
      expect(controller.mode, ThemeMode.light);
      expect(notified, 2);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(ThemeModeController.storageKey), 'light');
    });

    test('повторная установка того же режима не уведомляет', () async {
      SharedPreferences.setMockInitialValues({});
      final controller = ThemeModeController();
      var notified = 0;
      controller.addListener(() => notified++);
      await controller.setMode(ThemeMode.system);
      expect(notified, 0);
    });
  });

  group('Палитра в теме', () {
    test('светлая и тёмная темы содержат свои палитры и токены', () {
      expect(_light.extension<AppPalette>(), AppPalette.light);
      expect(_dark.extension<AppPalette>(), AppPalette.dark);
      expect(_light.extension<AppTokens>(), isNotNull);
      expect(_dark.brightness, Brightness.dark);
      expect(_dark.scaffoldBackgroundColor, AppPalette.dark.background);
    });

    testWidgets('ThemeColors.of читает палитру из темы', (tester) async {
      const custom = Color(0xFF123456);
      late ThemeColors tc;
      await tester.pumpWidget(
        _host(
          AppTheme.build(
            AppPalette.light.copyWith(card: custom),
            textTheme: _text,
          ),
          Builder(
            builder: (context) {
              tc = ThemeColors.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(tc.card, custom);
      expect(tc.isDark, isFalse);
    });

    testWidgets('без расширения палитра выбирается по яркости', (tester) async {
      late AppPalette palette;
      await tester.pumpWidget(
        _host(
          ThemeData(brightness: Brightness.dark),
          Builder(
            builder: (context) {
              palette = AppPalette.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(palette, AppPalette.dark);
    });
  });

  group('AppButton берёт стиль из темы', () {
    testWidgets('primary окрашивается цветом palette.primary', (tester) async {
      const brand = Color(0xFF00AA55);
      await tester.pumpWidget(
        _host(
          AppTheme.build(
            AppPalette.light.copyWith(primary: brand),
            textTheme: _text,
          ),
          AppButton(text: 'OK', onPressed: () {}),
        ),
      );
      expect(_styleOf(tester).backgroundColor!.resolve({}), brand);
    });

    testWidgets('скругление и отступы задаются токенами', (tester) async {
      const tokens = AppTokens(
        buttonRadius: 8,
        buttonMedium: ButtonSizeSpec(
          horizontalPadding: 40,
          verticalPadding: 20,
          fontSize: 15,
        ),
      );
      await tester.pumpWidget(
        _host(
          AppTheme.build(AppPalette.light, tokens: tokens, textTheme: _text),
          AppButton(text: 'OK', onPressed: () {}),
        ),
      );
      final style = _styleOf(tester);
      final shape = style.shape!.resolve({})! as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(8));
      expect(
        style.padding!.resolve({}),
        const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      );
    });

    testWidgets('в тёмной теме primary меняет цвет автоматически', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(_dark, AppButton(text: 'OK', onPressed: () {})),
      );
      expect(
        _styleOf(tester).backgroundColor!.resolve({}),
        AppPalette.dark.primary,
      );
    });

    testWidgets('без обработчика кнопка неактивна', (tester) async {
      await tester.pumpWidget(_host(_light, const AppButton(text: 'OK')));
      expect(tester.widget<ButtonStyleButton>(_anyButton).enabled, isFalse);
    });

    testWidgets('loading показывает индикатор и блокирует нажатие', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          _light,
          AppButton(text: 'OK', loading: true, onPressed: () => taps++),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.text('OK'));
      expect(taps, 0);
    });

    testWidgets('варианты отображаются нужными Material-кнопками', (
      tester,
    ) async {
      for (final (variant, type) in [
        (AppButtonVariant.primary, ElevatedButton),
        (AppButtonVariant.secondary, ElevatedButton),
        (AppButtonVariant.outline, OutlinedButton),
        (AppButtonVariant.text, TextButton),
      ]) {
        await tester.pumpWidget(
          _host(
            _light,
            AppButton(text: 'OK', variant: variant, onPressed: () {}),
          ),
        );
        expect(find.byType(type), findsOneWidget, reason: '$variant');
      }
    });

    testWidgets('AppIconButton имеет подсказку и зону 48×48', (tester) async {
      await tester.pumpWidget(
        _host(
          _light,
          AppIconButton(icon: Icons.add, tooltip: 'Добавить', onPressed: () {}),
        ),
      );
      expect(find.byTooltip('Добавить'), findsOneWidget);
      final size = tester.getSize(find.byType(IconButton));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });
  });

  testWidgets('глобальная тема стилизует обычные ElevatedButton', (
    tester,
  ) async {
    const brand = Color(0xFF884400);
    final theme = AppTheme.build(
      AppPalette.light.copyWith(primary: brand),
      textTheme: _text,
    );
    await tester.pumpWidget(
      _host(theme, ElevatedButton(onPressed: () {}, child: const Text('OK'))),
    );
    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(ElevatedButton),
        matching: find.byType(Material),
      ),
    );
    expect(material.color, brand);
  });
}
