import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumina/core/models/supabase_models.dart';
import 'package:lumina/core/services/notifications/notification_settings.dart';
import 'package:lumina/core/services/units_service.dart';
import 'package:lumina/core/theme/app_palette.dart';
import 'package:lumina/core/theme/app_theme.dart';
import 'package:lumina/features/activity/presentation/widgets/activity_tip_card.dart';
import 'package:lumina/features/notifications/presentation/widgets/notification_tiles.dart';
import 'package:lumina/features/scanner/presentation/widgets/scanner_controls.dart';
import 'package:lumina/features/weight/presentation/widgets/weight_summary_card.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:lumina/l10n/app_localizations_en.dart';
import 'package:lumina/l10n/app_localizations_ru.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _host(Widget child, {Locale locale = const Locale('ru')}) => MaterialApp(
  locale: locale,
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  theme: AppTheme.build(AppPalette.light, textTheme: const TextTheme()),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  group('waterIntervalLabel', () {
    test('подпись интервала зависит от языка, а не всегда по-русски', () {
      const s = NotificationSettings(
        masterEnabled: true,
        waterEnabled: true,
        waterIntervalMin: 120,
        waterStartMin: 480,
        waterEndMin: 1320,
        breakfastEnabled: false,
        breakfastMin: 0,
        lunchEnabled: false,
        lunchMin: 0,
        dinnerEnabled: false,
        dinnerMin: 0,
        activityEnabled: false,
        activityMin: 0,
        eveningEnabled: false,
        eveningMin: 0,
      );
      expect(waterIntervalLabel(s, AppLocalizationsRu()), contains('2'));
      expect(
        waterIntervalLabel(s, AppLocalizationsEn()),
        AppLocalizationsEn().notifEvery2h,
      );
    });
  });

  group('WeightSummaryCard', () {
    final units = UnitsService.instance;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await units.load();
    });

    tearDown(() => units.setSystem(UnitSystem.metric));

    testWidgets('крупное число веса — в фунтах при имперской системе', (
      tester,
    ) async {
      await units.setSystem(UnitSystem.imperial);
      await tester.pumpWidget(
        _host(const WeightSummaryCard(current: 80, start: 85, goal: 75)),
      );
      // 80 кг ≈ 176.4 фунта; раньше показывалось «80.0» при выбранных фунтах.
      expect(find.textContaining('176'), findsWidgets);
      expect(find.text('80.0'), findsNothing);
    });
  });

  group('ActivityTipCard', () {
    testWidgets('совет меняется по количеству шагов', (tester) async {
      final ru = AppLocalizationsRu();
      for (final (steps, tip) in [
        (1000, ru.activityTipLow),
        (6000, ru.activityTipMid),
        (9000, ru.activityTipHigh),
        (12000, ru.activityTipDone),
      ]) {
        await tester.pumpWidget(_host(ActivityTipCard(steps: steps)));
        expect(find.text(tip), findsOneWidget, reason: '$steps шагов');
      }
    });
  });

  group('ScannerMealTypeSelector', () {
    testWidgets('показывает локализованные приёмы пищи и сообщает выбор', (
      tester,
    ) async {
      MealType? picked;
      await tester.pumpWidget(
        _host(
          ScannerMealTypeSelector(
            selected: MealType.snack,
            onChanged: (t) => picked = t,
          ),
          locale: const Locale('en'),
        ),
      );
      final en = AppLocalizationsEn();
      expect(find.text(en.breakfast), findsOneWidget);
      await tester.tap(find.text(en.dinner));
      expect(picked, MealType.dinner);
    });
  });
}
