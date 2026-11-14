import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumina/core/services/auth_service.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/features/meal_plan/data/recipe_repository.dart';
import 'package:lumina/features/meal_plan/data/recipes_seed_data.dart';
import 'package:lumina/features/meal_plan/domain/models/recipe_model.dart';
import 'package:lumina/features/meal_plan/domain/recipe_filters.dart';
import 'package:lumina/features/meal_plan/presentation/pages/recipe_detail_page.dart';
import 'package:lumina/features/meal_plan/presentation/widgets/recipe_card.dart';
import 'package:lumina/features/meal_plan/presentation/widgets/recipe_design.dart';
import 'package:lumina/features/meal_plan/presentation/widgets/recipe_empty_state.dart';
import 'package:lumina/features/meal_plan/presentation/widgets/recipe_filters_sheet.dart';
import 'package:lumina/features/meal_plan/presentation/widgets/recipe_image.dart';
import 'package:lumina/l10n/app_localizations.dart';

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
  RecipeFilters _filters = const RecipeFilters();

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
      final category = _category;
      if (category != null && !_matchesCategory(r, category)) return false;
      return _filters.matches(r);
    }).toList();
  }

  Future<void> _showFilters() async {
    final next = await showRecipeFiltersSheet(context, current: _filters);
    if (next == null || !mounted) return;
    setState(() => _filters = next);
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

  void _resetAll() {
    setState(() {
      _search.clear();
      _category = null;
      _filters = const RecipeFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final recipes = _filtered;
    final hasQuery = _search.text.trim().isNotEmpty;

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
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).backButtonTooltip,
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
                          tooltip: AppLocalizations.of(context)!.filtersTitle,
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
                              hintText: AppLocalizations.of(
                                context,
                              )!.recipeSearchHint,
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
                            tooltip: AppLocalizations.of(context)!.filtersTitle,
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
                                      child: RecipeImage(
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
                                      color: selected
                                          ? RecipeDesign.green
                                          : tc.text,
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
                            !hasQuery && _category == null
                                ? AppLocalizations.of(context)!.recipePopular
                                : AppLocalizations.of(
                                    context,
                                  )!.recipeResults(recipes.length),
                            style: GoogleFonts.notoSerif(
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                              color: tc.text,
                            ),
                          ),
                        ),
                        if (_category != null || _filters.isNotEmpty)
                          TextButton(
                            onPressed: _resetAll,
                            child: Text(
                              AppLocalizations.of(context)!.resetAction,
                            ),
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
                child: RecipeEmptyState(
                  hasFilters:
                      hasQuery || _category != null || _filters.isNotEmpty,
                  onReset: _resetAll,
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
                      itemBuilder: (context, index) {
                        final recipe = recipes[index];
                        final favorite = _favorites.contains(recipe.id);
                        return RecipeCard(
                          recipe: recipe,
                          favorite: favorite,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RecipeDetailPage(
                                recipe: recipe,
                                favorite: favorite,
                                onFavorite: () => _toggleFavorite(recipe),
                              ),
                            ),
                          ),
                          onFavorite: () => _toggleFavorite(recipe),
                        );
                      },
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
