import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumina/app/bootstrap.dart';
import 'package:lumina/core/services/notifications/notification_ids.dart';
import 'package:lumina/core/services/notifications/notification_settings.dart';
import 'package:lumina/core/services/notifications/reminder_catalog.dart';
import 'package:lumina/features/notifications/presentation/widgets/notification_tiles.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:lumina/l10n/app_localizations_en.dart';
import 'package:lumina/l10n/app_localizations_ky.dart';
import 'package:lumina/l10n/app_localizations_ru.dart';

NotificationSettings _settings({required int waterIntervalMin}) =>
    NotificationSettings(
      masterEnabled: true,
      waterEnabled: true,
      waterIntervalMin: waterIntervalMin,
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

void main() {
  final locales = <String, AppLocalizations>{
    'ru': AppLocalizationsRu(),
    'en': AppLocalizationsEn(),
    'ky': AppLocalizationsKy(),
  };

  group('ReminderCatalog', () {
    for (final entry in locales.entries) {
      test('${entry.key}: у каждого напоминания есть заголовок и текст', () {
        final loc = entry.value;
        final contents = [
          ReminderCatalog.water(loc),
          for (final id in NotificationIds.daily)
            ReminderCatalog.daily(loc, id),
        ];
        for (final c in contents) {
          expect(c, isNotNull);
          expect(c!.title.trim(), isNotEmpty);
          expect(c.body.trim(), isNotEmpty);
          expect(c.channelName.trim(), isNotEmpty);
        }
      });
    }

    test('тексты зависят от языка, а не всегда русские', () {
      final ru = ReminderCatalog.water(locales['ru']!);
      final en = ReminderCatalog.water(locales['en']!);
      final ky = ReminderCatalog.water(locales['ky']!);
      expect({ru.title, en.title, ky.title}, hasLength(3));
      expect({ru.body, en.body, ky.body}, hasLength(3));
    });

    test('маршрут и канал не зависят от языка', () {
      for (final id in NotificationIds.daily) {
        final ru = ReminderCatalog.daily(locales['ru']!, id)!;
        final en = ReminderCatalog.daily(locales['en']!, id)!;
        expect(en.payload, ru.payload);
        expect(en.channelId, ru.channelId);
      }
      expect(ReminderCatalog.water(locales['en']!).payload, 'water');
    });

    test('каналы: три штуки с одинаковыми id на любом языке', () {
      final ids = [
        for (final loc in locales.values)
          ReminderCatalog.channels(loc).map((c) => c.id).toList(),
      ];
      expect(ids.first, hasLength(3));
      expect(ids[1], ids.first);
      expect(ids[2], ids.first);
    });

    test('вода и неизвестный id не считаются ежедневным напоминанием', () {
      final loc = locales['ru']!;
      expect(ReminderCatalog.daily(loc, NotificationIds.water), isNull);
      expect(ReminderCatalog.daily(loc, -1), isNull);
    });
  });

  group('waterIntervalLabel для нестандартного интервала', () {
    test('минуты', () {
      final s = _settings(waterIntervalMin: 45);
      expect(waterIntervalLabel(s, locales['en']!), 'Every 45 min');
      expect(waterIntervalLabel(s, locales['ru']!), 'Каждые 45 мин');
    });

    test('целые часы', () {
      final s = _settings(waterIntervalMin: 240);
      expect(waterIntervalLabel(s, locales['en']!), 'Every 4 h');
      expect(waterIntervalLabel(s, locales['ky']!), contains('4'));
    });
  });

  group('silenceLogsInRelease', () {
    final original = debugPrint;
    tearDown(() => debugPrint = original);

    test('в release вывод отключается', () {
      final lines = <String?>[];
      debugPrint = (String? message, {int? wrapWidth}) => lines.add(message);
      silenceLogsInRelease(isRelease: true);
      debugPrint('user id 123');
      expect(lines, isEmpty);
    });

    test('в debug вывод остаётся', () {
      final lines = <String?>[];
      debugPrint = (String? message, {int? wrapWidth}) => lines.add(message);
      silenceLogsInRelease(isRelease: false);
      debugPrint('hello');
      expect(lines, ['hello']);
    });
  });
}
