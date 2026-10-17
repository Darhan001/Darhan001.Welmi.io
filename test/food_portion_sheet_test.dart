import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumina/features/food_database/domain/models/food_product.dart';
import 'package:lumina/features/food_database/presentation/widgets/food_portion_sheet.dart';

Future<void> _openSheet(
  WidgetTester tester,
  FoodProduct product,
  void Function(FoodDraft?) onResult,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push<FoodDraft>(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        Scaffold(body: FoodPortionSheet(product: product)),
                  ),
                );
                onResult(result);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('порция 150 г пересчитывает КБЖУ и возвращает запись', (
    tester,
  ) async {
    const product = FoodProduct(
      barcode: '1',
      name: 'Молоко',
      brand: 'Бренд',
      kcalPer100g: 250,
      proteinPer100g: 10,
      fatPer100g: 5,
      carbsPer100g: 30,
    );

    FoodDraft? result;
    await _openSheet(tester, product, (draft) => result = draft);

    expect(find.text('Порция'), findsOneWidget);
    expect(
      find.text('На 100 г: 250 ккал · Б 10 г · Ж 5 г · У 30 г'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField), '150');
    await tester.pump();

    expect(find.text('375'), findsOneWidget);
    expect(find.text('15 г'), findsOneWidget);
    expect(find.text('7.5 г'), findsOneWidget);
    expect(find.text('45 г'), findsOneWidget);

    await tester.tap(find.text('Добавить в дневник'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.name, 'Молоко');
    expect(result!.grams, 150);
    expect(result!.calories, 375);
    expect(result!.proteinGrams, closeTo(15, 0.0001));
    expect(result!.info, '150 г · Бренд');
  });

  testWidgets('без калорийности запись не сохраняется и есть объяснение', (
    tester,
  ) async {
    const product = FoodProduct(barcode: '2', name: 'Вода');

    FoodDraft? result;
    await _openSheet(tester, product, (draft) => result = draft);

    expect(find.textContaining('нет пищевой ценности'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '200');
    await tester.pump();
    await tester.tap(find.text('Добавить в дневник'));
    await tester.pump();

    expect(
      find.textContaining('нет калорийности этого продукта'),
      findsOneWidget,
    );
    expect(result, isNull);
  });
}
