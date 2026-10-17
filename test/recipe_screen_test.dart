import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/features/meal_plan/data/recipes_seed_data.dart';
import 'package:lumina/features/meal_plan/domain/models/recipe_model.dart';
import 'package:lumina/features/meal_plan/presentation/pages/meal_plan_page.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Проверяет экран «Рецепты» целиком: карточка, поиск и адаптивная сетка.
void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpRecipes(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ru'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: MealPlanPage(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('карточки рецептов показывают собственные фото', (tester) async {
    await pumpRecipes(tester, const Size(420, 900));

    expect(find.text('Блины гречневые'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.text('Сырники с ягодами'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    final assets = _visibleAssets(tester);

    expect(assets, contains('assets/images/recipes/syrniki.jpg'));
    // Сырники — отдельная запись, из TheMealDB их фото не подставляется.
    expect(
      assets.where((a) => a.contains('syrniki.jpg')).length,
      1,
      reason: 'У фото сырников должен быть ровно один владелец',
    );
  });

  testWidgets('поиск показывает название и фото того же блюда', (tester) async {
    await pumpRecipes(tester, const Size(420, 900));

    await tester.enterText(find.byType(TextField), 'лосось');
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Лосось терияки'), findsOneWidget);
    expect(
      find.text('Запечённый лосось с фенхелем и томатами'),
      findsOneWidget,
    );
    expect(find.text('Паста карбонара'), findsNothing);

    final visibleAssets = _visibleAssets(tester).toSet();

    // Найденные блюда показывают фото именно себя, а не соседней карточки.
    expect(
      visibleAssets,
      contains('assets/images/recipes/52773_salmon_teriyaki.jpg'),
    );
    expect(
      visibleAssets,
      contains('assets/images/recipes/52959_baked_salmon_fennel.jpg'),
    );
    expect(
      visibleAssets.any((asset) => asset.contains('carbonara')),
      isFalse,
      reason: 'Постороннее блюдо не должно попадать в результаты поиска',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('пустой результат объясняется и сбрасывается', (tester) async {
    await pumpRecipes(tester, const Size(420, 900));

    await tester.enterText(find.byType(TextField), 'цзарские щи');
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('Ничего не найдено'), findsOneWidget);
    expect(find.text('Сбросить'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('карточка открывает рецепт с фото и пометкой об оценке КБЖУ',
      (tester) async {
    await pumpRecipes(tester, const Size(420, 900));

    await tester.tap(find.text('Блины гречневые'));
    await tester.pumpAndSettle();

    expect(find.text('Блины гречневые'), findsOneWidget);
    expect(find.textContaining('Фото: TheMealDB'), findsOneWidget);
    expect(
      find.textContaining('КБЖУ — оценочные значения'),
      findsOneWidget,
    );
    expect(find.textContaining('порция 230 г'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('кнопка «Спросить» отправляет рецепт в чат одним сообщением',
      (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final recipe = buildSeedRecipes().first;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: RecipeDetailPage(
          recipe: recipe,
          favorite: false,
          onFavorite: () {},
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Спросить'));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    // Раньше вопрос дублировался: история чата загружалась параллельно с
    // отправкой стартового вопроса и добавляла его повторно.
    expect(find.textContaining('Я готовлю рецепт'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('без фото показывается placeholder, а не чужое блюдо',
      (tester) async {
    const recipe = Recipe(
      id: 'welmi-no-photo',
      title: 'Блюдо без фото',
      imageUrl: '',
      category: 'Завтрак',
      calories: 100,
      proteinGrams: 5,
      fatGrams: 4,
      carbsGrams: 10,
      cookingTimeMinutes: 10,
      ingredients: [
        RecipeIngredient(name: 'вода', amount: '100 мл', calories: 0),
      ],
      steps: [RecipeStep(stepNumber: 1, description: 'Смешайте.')],
    );

    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: RecipeDetailPage(
          recipe: recipe,
          favorite: false,
          onFavorite: () {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Фото скоро появится'), findsWidgets);
    expect(find.byType(Image), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('на широком экране сетка перестраивается без ошибок вёрстки',
      (tester) async {
    await pumpRecipes(tester, const Size(1024, 900));
    expect(find.text('Сырники с ягодами'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

/// `Image.asset` с `cacheWidth` оборачивает провайдер в [ResizeImage].
List<String> _visibleAssets(WidgetTester tester) {
  return tester.widgetList<Image>(find.byType(Image)).map((image) {
    final provider = image.image;
    final unwrapped = provider is ResizeImage ? provider.imageProvider : provider;
    return unwrapped is AssetImage ? unwrapped.assetName : null;
  }).whereType<String>().toList();
}
