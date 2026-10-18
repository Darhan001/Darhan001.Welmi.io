import 'package:flutter_test/flutter_test.dart';
import 'package:lumina/core/services/ai_service.dart';
import 'package:lumina/core/services/units_service.dart';
import 'package:lumina/core/utils/number_input.dart';
import 'package:lumina/core/widgets/units_format.dart';
import 'package:lumina/l10n/app_localizations_ru.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('parseDecimalInput', () {
    test('принимает запятую как десятичный разделитель', () {
      expect(parseDecimalInput('72,5'), 72.5);
    });

    test('принимает точку и игнорирует пробелы', () {
      expect(parseDecimalInput(' 72.5 '), 72.5);
      expect(parseDecimalInput('1 000'), 1000);
    });

    test('пустой и некорректный ввод дают null, а не 0', () {
      expect(parseDecimalInput(''), isNull);
      expect(parseDecimalInput('   '), isNull);
      expect(parseDecimalInput('abc'), isNull);
      expect(parseDecimalInput('7,2,5'), isNull);
    });

    test('диапазон веса отсекает опечатки', () {
      expect(isPlausibleWeightKg(72.5), isTrue);
      expect(isPlausibleWeightKg(725), isFalse);
      expect(isPlausibleWeightKg(5), isFalse);
    });
  });

  group('UnitsService', () {
    final units = UnitsService.instance;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await units.load();
      await units.setSystem(UnitSystem.metric);
    });

    test('метрика ничего не пересчитывает', () {
      expect(units.weightToDisplay(70), 70);
      expect(units.weightFromDisplay(70), 70);
      expect(units.distanceToDisplay(5), 5);
    });

    test('фунты и мили пересчитываются в обе стороны без потерь', () async {
      await units.setSystem(UnitSystem.imperial);
      expect(units.weightToDisplay(70), closeTo(154.32, 0.01));
      expect(
        units.weightFromDisplay(units.weightToDisplay(72.5)),
        closeTo(72.5, 1e-9),
      );
      expect(units.distanceToDisplay(10), closeTo(6.2137, 0.0001));
      expect(
        units.distanceFromDisplay(units.distanceToDisplay(3.5)),
        closeTo(3.5, 1e-9),
      );
    });

    test('выбор сохраняется и восстанавливается после перезапуска', () async {
      await units.setSystem(UnitSystem.imperial);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('units_system'), 'imperial');

      units.value = UnitSystem.metric; // имитация «свежего» запуска
      await units.load();
      expect(units.value, UnitSystem.imperial);
    });

    test(
      'профиль применяется только если на устройстве выбора ещё нет',
      () async {
        SharedPreferences.setMockInitialValues({});
        await units.load();
        await units.adoptFromProfile('imperial');
        expect(units.value, UnitSystem.imperial);

        // Локальный выбор (мог быть сделан офлайн) важнее значения профиля.
        await units.setSystem(UnitSystem.metric);
        await units.adoptFromProfile('imperial');
        expect(units.value, UnitSystem.metric);
      },
    );

    test('неизвестный код из БД трактуется как метрика', () {
      expect(UnitSystem.fromCode(null), UnitSystem.metric);
      expect(UnitSystem.fromCode('garbage'), UnitSystem.metric);
    });
  });

  group('UnitsFormat', () {
    final loc = AppLocalizationsRu();

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await UnitsService.instance.load();
      await UnitsService.instance.setSystem(UnitSystem.metric);
    });

    test('форматирует вес с единицей и знаком', () async {
      expect(loc.formatWeight(72.46), '72.5 кг');
      expect(loc.formatWeight(1.2, signed: true), '+1.2 кг');
      expect(loc.formatWeight(-1.2, signed: true), '-1.2 кг');

      await UnitsService.instance.setSystem(UnitSystem.imperial);
      expect(loc.formatWeight(70), '154.3 lb');
      expect(loc.weightUnitLabel, 'lb');
      expect(loc.formatDistance(10), '6.2 mi');
    });
  });

  group('AiChatMessage.fromJson', () {
    test('восстанавливает сохранённое сообщение', () {
      final original = AiChatMessage(
        role: 'assistant',
        text: 'Привет',
        timestamp: DateTime.utc(2026, 10, 19, 8),
      );
      final restored = AiChatMessage.fromJson(original.toJson())!;
      expect(restored.role, 'assistant');
      expect(restored.text, 'Привет');
      expect(restored.timestamp, original.timestamp);
    });

    test('битые записи отбрасываются, а не роняют загрузку', () {
      expect(AiChatMessage.fromJson(null), isNull);
      expect(AiChatMessage.fromJson('text'), isNull);
      expect(AiChatMessage.fromJson({'role': 'system', 'text': 'x'}), isNull);
      expect(AiChatMessage.fromJson({'role': 'user'}), isNull);
    });
  });
}
