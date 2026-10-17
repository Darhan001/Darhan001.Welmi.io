import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumina/core/models/supabase_models.dart';
import 'package:lumina/core/services/auth_service.dart';
import 'package:lumina/core/services/daily_tracker.dart';
import 'package:lumina/core/services/supabase_service.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/ux_helpers.dart';
import 'package:lumina/features/chat/presentation/pages/ai_chat_page.dart';
import 'package:lumina/features/meal_plan/data/recipe_repository.dart';
import 'package:lumina/features/meal_plan/data/recipes_seed_data.dart';
import 'package:lumina/features/meal_plan/domain/models/recipe_model.dart';
import 'package:lumina/l10n/app_localizations.dart';

const _green = Color(0xFF75A47F);

/// The former meal-plan screen is now the recipe catalog.
class MealPlanPage extends StatefulWidget {
  const MealPlanPage({super.key});

  @override
  State<MealPlanPage> createState() => _MealPlanPageState();
}

class _MealPlanPageState extends State<MealPlanPage> {
  final _search = TextEditingController();
  final _repository = RecipeRepository();
  List<Recipe> _recipes = buildSeedRecipes();
  Set<String> _favorites = {};
  String? _category;
  bool _loading = true;
  int? _maxCalories;
  int? _minProtein;
  int? _maxMinutes;
  String? _diet;

  @override
  void initState() {
    super.initState();
    _search.addListener(_refresh);
    _load();
  }

  @override
  void dispose() {
    _search.removeListener(_refresh);
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final values = await Future.wait([
      _repository.loadRecipes(),
      _repository.loadFavoriteIds(),
    ]);
    if (!mounted) return;
    setState(() {
      _recipes = values[0] as List<Recipe>;
      _favorites = values[1] as Set<String>;
      _loading = false;
    });
  }

  void _refresh() => setState(() {});

  /// Фильтр категории применяется к самой записи рецепта (её поля), а не к
  /// позиции в списке — поэтому фото всегда остаётся фото этого блюда.
  static bool _matchesCategory(Recipe r, String id) => switch (id) {
    'Быстрое' => r.isQuick,
    'Вегетарианское' => r.isVegetarian,
    'Высокобелковое' => r.isHighProtein,
    'Низкокалорийное' => r.isLowCalorie,
    _ => r.category.toLowerCase() == id.toLowerCase(),
  };

  List<Recipe> get _filtered {
    final query = _search.text.trim().toLowerCase();
    return _recipes.where((r) {
      final searchable = [
        r.title,
        r.category,
        ...r.tags,
        ...r.ingredients.map((e) => e.name),
        if (r.isHighProtein) 'белок протеин высокобелковый',
      ].join(' ').toLowerCase();
      if (query.isNotEmpty && !searchable.contains(query)) return false;
      if (_category != null && !_matchesCategory(r, _category!)) return false;
      if (_maxCalories != null && r.calories > _maxCalories!) return false;
      if (_minProtein != null && r.proteinGrams < _minProtein!) return false;
      if (_maxMinutes != null && r.cookingTimeMinutes > _maxMinutes!) {
        return false;
      }
      if (_diet == 'Вегетарианские' && !r.isVegetarian) return false;
      if (_diet == 'Без сахара' && r.sugarGrams > 2) return false;
      return true;
    }).toList();
  }

  Future<void> _showFilters() async {
    var calories = _maxCalories;
    var protein = _minProtein;
    var minutes = _maxMinutes;
    var diet = _diet;
    final tc = ThemeColors.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: tc.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: tc.divider,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Фильтры',
                  style: GoogleFonts.notoSerif(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: tc.text,
                  ),
                ),
                const SizedBox(height: 12),
                _filterChoice<int>('Калории', calories, const [
                  300,
                  500,
                  700,
                ], (v) => setSheet(() => calories = v)),
                _filterChoice<int>('Белок от', protein, const [
                  20,
                  30,
                  40,
                ], (v) => setSheet(() => protein = v)),
                _filterChoice<int>('Время до', minutes, const [
                  20,
                  30,
                  45,
                ], (v) => setSheet(() => minutes = v)),
                _filterChoice<String>('Питание', diet, const [
                  'Вегетарианские',
                  'Без сахара',
                ], (v) => setSheet(() => diet = v)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _maxCalories = null;
                          _minProtein = null;
                          _maxMinutes = null;
                          _diet = null;
                        });
                        Navigator.pop(sheetContext);
                      },
                      child: const Text('Сбросить'),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          _maxCalories = calories;
                          _minProtein = protein;
                          _maxMinutes = minutes;
                          _diet = diet;
                        });
                        Navigator.pop(sheetContext);
                      },
                      child: const Text('Показать'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _filterChoice<T>(
    String title,
    T? selected,
    List<T> values,
    ValueChanged<T?> onSelect,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Любое'),
                selected: selected == null,
                onSelected: (_) => onSelect(null),
              ),
              ...values.map(
                (value) => ChoiceChip(
                  label: Text(
                    value is int
                        ? (title == 'Калории'
                              ? 'До $value ккал'
                              : title == 'Белок от'
                              ? 'От $value г'
                              : 'До $value мин')
                        : value.toString(),
                  ),
                  selected: selected == value,
                  onSelected: (_) => onSelect(selected == value ? null : value),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFavorite(Recipe recipe) async {
    final wasFavorite = _favorites.contains(recipe.id);
    setState(
      () => wasFavorite
          ? _favorites.remove(recipe.id)
          : _favorites.add(recipe.id),
    );
    final key = 'recipe_favorites_${AuthService().userId ?? 'anon'}';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, _favorites.toList());
    try {
      await _repository.setFavorite(recipe.id, !wasFavorite);
    } catch (_) {
      // Local per-account cache remains available until Supabase setup is run.
    }
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final recipes = _filtered;
    return Scaffold(
      backgroundColor: tc.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.maybePop(context),
                          icon: Icon(Icons.arrow_back_rounded, color: tc.text),
                        ),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)!.mealPlanTitle,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.notoSerif(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: tc.text,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _showFilters,
                          icon: Icon(Icons.tune_rounded, color: tc.text),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _search,
                            decoration: InputDecoration(
                              hintText: 'Найти блюдо или ингредиент',
                              prefixIcon: const Icon(Icons.search_rounded),
                              filled: true,
                              fillColor: tc.card,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Material(
                          color: tc.card,
                          borderRadius: BorderRadius.circular(16),
                          child: IconButton(
                            onPressed: _showFilters,
                            icon: Icon(
                              Icons.filter_list_rounded,
                              color: tc.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      height: 116,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: seedRecipeCategories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final category = seedRecipeCategories[index];
                          final selected = _category == category.id;
                          return GestureDetector(
                            onTap: () => setState(
                              () => _category = selected ? null : category.id,
                            ),
                            child: SizedBox(
                              width: 98,
                              child: Column(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(18),
                                      child: _RecipeImage(
                                        imageUrl: category.imageUrl,
                                        imagePath: category.imagePath,
                                        label: category.name,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    category.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: selected ? _green : tc.text,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _search.text.isEmpty && _category == null
                                ? 'Популярные'
                                : 'Результаты · ${recipes.length}',
                            style: GoogleFonts.notoSerif(
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                              color: tc.text,
                            ),
                          ),
                        ),
                        if (_category != null ||
                            _maxCalories != null ||
                            _minProtein != null ||
                            _maxMinutes != null ||
                            _diet != null)
                          TextButton(
                            onPressed: () => setState(() {
                              _category = null;
                              _maxCalories = null;
                              _minProtein = null;
                              _maxMinutes = null;
                              _diet = null;
                            }),
                            child: const Text('Сбросить'),
                          ),
                      ],
                    ),
                    if (_loading) const LinearProgressIndicator(minHeight: 2),
                  ],
                ),
              ),
            ),
            if (recipes.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyRecipes(
                  hasFilters:
                      _search.text.trim().isNotEmpty ||
                      _category != null ||
                      _maxCalories != null ||
                      _minProtein != null ||
                      _maxMinutes != null ||
                      _diet != null,
                  onReset: () => setState(() {
                    _search.clear();
                    _category = null;
                    _maxCalories = null;
                    _minProtein = null;
                    _maxMinutes = null;
                    _diet = null;
                  }),
                ),
              )
            else
              // Одинаковые квадратные фото на всех размерах экрана.
              SliverLayoutBuilder(
                builder: (context, constraints) {
                  const spacing = 14.0;
                  final width = constraints.crossAxisExtent - 40;
                  final columns = width >= 880
                      ? 4
                      : width >= 620
                      ? 3
                      : 2;
                  final tile = (width - spacing * (columns - 1)) / columns;
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                    sliver: SliverGrid.builder(
                      itemCount: recipes.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: spacing,
                        crossAxisSpacing: spacing,
                        // Квадратное изображение + блок текста фиксированной
                        // высоты: карточки и кадры одинаковые при любом числе
                        // колонок и разной длине названия.
                        mainAxisExtent: tile + 74,
                      ),
                      itemBuilder: (context, index) => _RecipeCard(
                        recipe: recipes[index],
                        favorite: _favorites.contains(recipes[index].id),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RecipeDetailPage(
                              recipe: recipes[index],
                              favorite: _favorites.contains(recipes[index].id),
                              onFavorite: () => _toggleFavorite(recipes[index]),
                            ),
                          ),
                        ),
                        onFavorite: () => _toggleFavorite(recipes[index]),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({
    required this.recipe,
    required this.favorite,
    required this.onTap,
    required this.onFavorite,
  });
  final Recipe recipe;
  final bool favorite;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final meta = recipe.servingWeightGrams > 0
        ? '${recipe.cookingTimeMinutes} мин · ${recipe.servingWeightGrams} г'
        : '${recipe.cookingTimeMinutes} мин · Б ${recipe.proteinGrams.round()} г';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: tc.card,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: tc.shadow(.06),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'recipe-image-${recipe.id}',
                    child: _RecipeImage(
                      imageUrl: recipe.imageUrl,
                      imagePath: recipe.imagePath,
                      label: recipe.title,
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Material(
                      color: Colors.white.withValues(alpha: .9),
                      shape: const CircleBorder(),
                      child: IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: onFavorite,
                        icon: Icon(
                          favorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: favorite
                              ? Colors.redAccent
                              : const Color(0xFF333333),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: .56),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${recipe.calories} ккал',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 10, 11, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.15,
                      fontWeight: FontWeight.w900,
                      color: tc.text,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 12,
                        color: tc.textSecondary,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: tc.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RecipeDetailPage extends StatefulWidget {
  const RecipeDetailPage({
    super.key,
    required this.recipe,
    required this.favorite,
    required this.onFavorite,
  });
  final Recipe recipe;
  final bool favorite;
  final VoidCallback onFavorite;
  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  final _supabase = SupabaseService();
  bool _favorite = false;
  bool _cooking = false;
  int _cookingStep = 0;
  @override
  void initState() {
    super.initState();
    _favorite = widget.favorite;
  }

  Future<void> _addToDiary() async {
    final meal = await showModalBottomSheet<MealType>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(18),
              child: Text(
                'Добавить в приём пищи',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            for (final type in MealType.values)
              ListTile(
                title: Text(_mealName(type)),
                onTap: () => Navigator.pop(ctx, type),
              ),
          ],
        ),
      ),
    );
    if (meal == null || !mounted) return;
    final userId = AuthService().userId;
    if (userId == null) {
      showWelmiSnackbar(context, 'Войдите, чтобы добавить блюдо в дневник');
      return;
    }
    try {
      final entry = await _supabase.addFoodEntry(
        FoodEntry(
          userId: userId,
          mealType: meal,
          date: DateTime.now(),
          totalCalories: widget.recipe.calories,
        ),
      );
      await _supabase.addMealItem(
        MealItem(
          foodEntryId: entry.id,
          name: widget.recipe.title,
          calories: widget.recipe.calories,
          proteinGrams: widget.recipe.proteinGrams,
          fatGrams: widget.recipe.fatGrams,
          carbsGrams: widget.recipe.carbsGrams,
          info: '1 порция · рецепт Welmi',
        ),
      );
      await DailyTracker().addCalories(
        widget.recipe.calories,
        protein: widget.recipe.proteinGrams.round(),
        fat: widget.recipe.fatGrams.round(),
        carbs: widget.recipe.carbsGrams.round(),
        mealType: meal,
      );
      if (mounted) {
        showWelmiSnackbar(
          context,
          'Рецепт добавлен в «${_mealName(meal)}»',
          icon: Icons.check_circle_outline,
        );
      }
    } catch (e) {
      if (mounted) {
        showWelmiSnackbar(
          context,
          'Не удалось добавить рецепт. Проверьте подключение.',
          icon: Icons.error_outline,
        );
      }
    }
  }

  String _mealName(MealType meal) => switch (meal) {
    MealType.breakfast => 'Завтрак',
    MealType.lunch => 'Обед',
    MealType.dinner => 'Ужин',
    MealType.snack => 'Перекус',
  };

  void _advanceCooking() {
    if (_cookingStep + 1 >= widget.recipe.steps.length) {
      setState(() {
        _cooking = false;
        _cookingStep = 0;
      });
      showWelmiSnackbar(context, 'Приятного аппетита!');
      return;
    }
    setState(() => _cookingStep++);
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final r = widget.recipe;
    return Scaffold(
      backgroundColor: tc.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: tc.background,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.arrow_back, color: Colors.black),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'recipe-image-${r.id}',
                child: _RecipeImage(
                  imageUrl: r.imageUrl,
                  imagePath: r.imagePath,
                  label: r.title,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.category,
                    style: const TextStyle(
                      color: _green,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    r.title,
                    style: GoogleFonts.notoSerif(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: tc.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    r.description,
                    style: TextStyle(color: tc.textSecondary, height: 1.4),
                  ),
                  if (r.imageCredit != null && r.imageCredit!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Фото: ${r.imageCredit}',
                      style: TextStyle(fontSize: 10.5, color: tc.textHint),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ActionChip(
                        icon: _favorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        label: 'Сохранить',
                        onTap: () {
                          setState(() => _favorite = !_favorite);
                          widget.onFavorite();
                        },
                      ),
                      _ActionChip(
                        icon: _cooking
                            ? Icons.check_circle
                            : Icons.soup_kitchen,
                        label: _cooking
                            ? 'Шаг ${_cookingStep + 1}'
                            : 'Готовить',
                        onTap: () => setState(() {
                          _cooking = !_cooking;
                          _cookingStep = 0;
                        }),
                      ),
                      _ActionChip(
                        icon: Icons.add,
                        label: 'В дневник',
                        onTap: _addToDiary,
                      ),
                      _ActionChip(
                        icon: Icons.auto_awesome,
                        label: 'Спросить',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AiChatPage(
                              initialPrompt:
                                  'Я готовлю рецепт «${r.title}» (${r.calories} ккал, Б ${r.proteinGrams} г, Ж ${r.fatGrams} г, У ${r.carbsGrams} г). Подскажи: ',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  Text(
                    'Калории и нутриенты',
                    style: GoogleFonts.notoSerif(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: tc.text,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _Nutrient(
                        value: '${r.calories}',
                        label: 'ккал',
                        color: _green,
                      ),
                      _Nutrient(
                        value: '${r.proteinGrams.round()} г',
                        label: 'Белки',
                        color: const Color(0xFF65A66F),
                      ),
                      _Nutrient(
                        value: '${r.fatGrams.round()} г',
                        label: 'Жиры',
                        color: const Color(0xFFE6A64A),
                      ),
                      _Nutrient(
                        value: '${r.carbsGrams.round()} г',
                        label: 'Углеводы',
                        color: const Color(0xFF6699D1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Клетчатка ${r.fiberGrams.round()} г · Сахар ${r.sugarGrams.round()} г · Натрий ${r.sodiumMg.round()} мг'
                    '${r.servingWeightGrams > 0 ? ' · порция ${r.servingWeightGrams} г' : ''}',
                    style: TextStyle(fontSize: 12, color: tc.textSecondary),
                  ),
                  if (r.nutritionIsEstimate) ...[
                    const SizedBox(height: 6),
                    Text(
                      'КБЖУ — оценочные значения на порцию по составу рецепта. '
                      'TheMealDB не публикует пищевую ценность.',
                      style: TextStyle(fontSize: 10.5, color: tc.textHint),
                    ),
                  ],
                  const SizedBox(height: 26),
                  Text(
                    'Ингредиенты · ${r.servings} порция',
                    style: GoogleFonts.notoSerif(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: tc.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...r.ingredients.map(
                    (i) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: tc.card,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              i.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: tc.text,
                              ),
                            ),
                          ),
                          Text(
                            i.amount,
                            style: TextStyle(
                              color: tc.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Приготовление',
                    style: GoogleFonts.notoSerif(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: tc.text,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_cooking)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _green.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Шаг ${_cookingStep + 1} из ${r.steps.length}',
                            style: const TextStyle(
                              color: _green,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            r.steps[_cookingStep].description,
                            style: TextStyle(color: tc.text, height: 1.4),
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton(
                              onPressed: _advanceCooking,
                              child: Text(
                                _cookingStep + 1 == r.steps.length
                                    ? 'Завершить'
                                    : 'Следующий шаг',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ...r.steps.map(
                    (s) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: tc.card,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: _green.withValues(alpha: .15),
                            child: Text(
                              '${s.stepNumber}',
                              style: const TextStyle(
                                color: _green,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              s.description,
                              style: TextStyle(height: 1.4, color: tc.text),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _addToDiary,
            icon: const Icon(Icons.add),
            label: const Text('В дневник'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: _green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Nutrient extends StatelessWidget {
  const _Nutrient({
    required this.value,
    required this.label,
    required this.color,
  });
  final String value, label;
  final Color color;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      margin: const EdgeInsets.only(right: 7),
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w900, color: color),
          ),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(fontSize: 10)),
        ],
      ),
    ),
  );
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ActionChip(
    avatar: Icon(icon, size: 17, color: _green),
    label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    onPressed: onTap,
  );
}

/// Фото блюда.
///
/// Сначала берётся собственный файл записи (пакет приложения), затем —
/// `strMealThumb` того же блюда из TheMealDB. Если недоступно и то и другое,
/// показывается нейтральный тематический placeholder: фотография другого
/// блюда не подставляется никогда.
class _RecipeImage extends StatelessWidget {
  const _RecipeImage({
    this.imageUrl,
    this.imagePath,
    required this.label,
  });

  final String? imageUrl;
  final String? imagePath;
  final String label;

  Widget _placeholder(BuildContext context) =>
      _RecipeImagePlaceholder(label: label);

  Widget _networkImage(BuildContext context) {
    final url = imageUrl;
    if (url == null || url.isEmpty) return _placeholder(context);
    return Image.network(
      url,
      fit: BoxFit.cover,
      cacheWidth: 720,
      semanticLabel: label,
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : const _RecipeImageSkeleton(),
      errorBuilder: (_, __, ___) => _placeholder(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final path = imagePath;
    if (path == null || path.isEmpty) return _networkImage(context);
    return Image.asset(
      path,
      fit: BoxFit.cover,
      cacheWidth: 720,
      semanticLabel: label,
      // Файл не найден — пробуем фото того же блюда по сети.
      errorBuilder: (_, __, ___) => _networkImage(context),
    );
  }
}

class _RecipeImagePlaceholder extends StatelessWidget {
  const _RecipeImagePlaceholder({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Semantics(
      label: 'Нет фото: $label',
      image: true,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [tc.surface, _green.withValues(alpha: tc.isDark ? .16 : .12)],
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.restaurant_rounded,
              color: _green.withValues(alpha: .75),
              size: 30,
            ),
            const SizedBox(height: 6),
            Text(
              'Фото скоро появится',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: tc.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipeImageSkeleton extends StatelessWidget {
  const _RecipeImageSkeleton();

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Container(
      color: tc.surface,
      alignment: Alignment.center,
      child: const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: _green),
      ),
    );
  }
}

class _EmptyRecipes extends StatelessWidget {
  const _EmptyRecipes({required this.hasFilters, required this.onReset});

  final bool hasFilters;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 44,
              color: tc.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              hasFilters
                  ? 'Ничего не найдено.\nПопробуйте изменить запрос или фильтры.'
                  : 'Рецепты скоро появятся.',
              textAlign: TextAlign.center,
              style: TextStyle(color: tc.textSecondary, height: 1.4),
            ),
            if (hasFilters) ...[
              const SizedBox(height: 8),
              TextButton(onPressed: onReset, child: const Text('Сбросить')),
            ],
          ],
        ),
      ),
    );
  }
}
