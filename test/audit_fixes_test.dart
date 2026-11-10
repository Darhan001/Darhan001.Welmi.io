import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lumina/core/models/supabase_models.dart';
import 'package:lumina/core/services/health_sync_service.dart';
import 'package:lumina/core/services/supabase/diary_queries.dart';
import 'package:lumina/core/services/supabase/profile_queries.dart';
import 'package:lumina/core/services/supabase/supabase_base.dart';
import 'package:lumina/core/widgets/meal_type_label.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Дневник без сети: insert/delete записываются в журнал, сбой позиции
/// включается флагом.
class _FakeDiary with SupabaseQueryBase, DiaryQueries {
  _FakeDiary({this.failItem = false, this.failCleanup = false});

  final bool failItem;
  final bool failCleanup;
  final List<String> log = [];

  @override
  SupabaseClient get client => throw UnimplementedError('no network in test');

  @override
  Future<FoodEntry> addFoodEntry(FoodEntry entry) async {
    log.add('entry+');
    return FoodEntry(
      id: 'e1',
      userId: entry.userId,
      totalCalories: entry.totalCalories,
    );
  }

  @override
  Future<MealItem> addMealItem(MealItem item) async {
    if (failItem) {
      log.add('item!');
      throw Exception('insert failed');
    }
    log.add('item+:${item.foodEntryId}');
    return item;
  }

  @override
  Future<void> deleteFoodEntry(String foodEntryId) async {
    if (failCleanup) throw Exception('cleanup failed');
    log.add('entry-:$foodEntryId');
  }
}

class _FakeProfile with SupabaseQueryBase, ProfileQueries {
  @override
  SupabaseClient get client => throw UnimplementedError('no network in test');
}

MealItem _item(String entryId) =>
    MealItem(foodEntryId: entryId, name: 'Каша', calories: 300);

void main() {
  group('HealthSyncResult', () {
    test('без данных возвращает нули, а не выдуманные значения', () {
      const result = HealthSyncResult(HealthSyncStatus.error);
      expect(result.steps, 0);
      expect(result.calories, 0);
      expect(result.sleepHours, 0);
    });
  });

  group('addFoodEntryWithItem', () {
    test('позиция получает id созданной записи', () async {
      final diary = _FakeDiary();
      final item = await diary.addFoodEntryWithItem(
        FoodEntry(userId: 'u1', totalCalories: 300),
        _item,
      );
      expect(item.foodEntryId, 'e1');
      expect(diary.log, ['entry+', 'item+:e1']);
    });

    test(
      'сбой позиции удаляет созданную запись и пробрасывает ошибку',
      () async {
        final diary = _FakeDiary(failItem: true);
        await expectLater(
          diary.addFoodEntryWithItem(FoodEntry(userId: 'u1'), _item),
          throwsException,
        );
        expect(diary.log, ['entry+', 'item!', 'entry-:e1']);
      },
    );

    test('сбой очистки не подменяет исходную ошибку', () async {
      final diary = _FakeDiary(failItem: true, failCleanup: true);
      await expectLater(
        diary.addFoodEntryWithItem(FoodEntry(userId: 'u1'), _item),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('insert failed'),
          ),
        ),
      );
    });
  });

  group('uploadProfilePhoto', () {
    final profile = _FakeProfile();

    test('отклоняет неизображения до обращения к Storage', () async {
      // На io-платформе XFile.name берётся из path, поэтому задаём оба.
      final file = XFile.fromData(
        Uint8List.fromList([60, 104, 116, 109, 108, 62]),
        name: 'avatar.html',
        path: 'avatar.html',
      );
      await expectLater(
        profile.uploadProfilePhoto('u1', file),
        throwsA(
          isA<AvatarUploadException>().having(
            (e) => e.error,
            'error',
            AvatarUploadError.unsupportedFormat,
          ),
        ),
      );
    });

    test('допустимый JPEG проходит проверку и доходит до Storage', () async {
      final file = XFile.fromData(
        Uint8List.fromList([0xFF, 0xD8, 0xFF]),
        name: 'face.JPG',
        path: 'face.JPG',
      );
      // Фейковый клиент бросает UnimplementedError — значит, валидация
      // пропустила файл и началась загрузка.
      await expectLater(
        profile.uploadProfilePhoto('u1', file),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('отклоняет файл без расширения', () async {
      final file = XFile.fromData(
        Uint8List.fromList([1, 2, 3]),
        name: 'blob',
        path: 'blob',
      );
      await expectLater(
        profile.uploadProfilePhoto('u1', file),
        throwsA(isA<AvatarUploadException>()),
      );
    });

    test('отклоняет слишком большой файл', () async {
      final file = XFile.fromData(
        Uint8List(ProfileQueries.maxAvatarBytes + 1),
        name: 'big.jpg',
        path: 'big.jpg',
      );
      await expectLater(
        profile.uploadProfilePhoto('u1', file),
        throwsA(
          isA<AvatarUploadException>().having(
            (e) => e.error,
            'error',
            AvatarUploadError.tooLarge,
          ),
        ),
      );
    });
  });

  group('mealTypeLabel', () {
    test('названия приёмов пищи берутся из локализации на всех языках', () {
      for (final code in ['ru', 'en', 'ky']) {
        final loc = lookupAppLocalizations(Locale(code));
        expect(loc.mealTypeLabel(MealType.breakfast), loc.breakfast);
        expect(loc.mealTypeLabel(MealType.lunch), loc.lunch);
        expect(loc.mealTypeLabel(MealType.dinner), loc.dinner);
        expect(loc.mealTypeLabel(MealType.snack), loc.snack);
      }
    });

    test('ru и en различаются — строки действительно переведены', () {
      final ru = lookupAppLocalizations(const Locale('ru'));
      final en = lookupAppLocalizations(const Locale('en'));
      expect(ru.recipeAddFailed, isNot(en.recipeAddFailed));
      expect(ru.authContinueWithGoogle, isNot(en.authContinueWithGoogle));
      expect(en.recipeAddedToMeal('Lunch'), contains('Lunch'));
    });
  });
}
