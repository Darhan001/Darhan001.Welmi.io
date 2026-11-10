import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/models/supabase_models.dart';
import 'package:lumina/core/services/auth_service.dart';
import 'package:lumina/core/services/daily_tracker.dart';
import 'package:lumina/core/services/supabase_service.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/meal_type_label.dart';
import 'package:lumina/core/widgets/ux_helpers.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:lumina/features/chat/presentation/pages/ai_chat_page.dart';
import 'package:lumina/features/meal_plan/domain/models/recipe_model.dart';
import 'package:lumina/features/meal_plan/presentation/widgets/recipe_design.dart';
import 'package:lumina/features/meal_plan/presentation/widgets/recipe_image.dart';

/// Страница рецепта: состав, КБЖУ и пошаговое приготовление.
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
      showWelmiSnackbar(
        context,
        AppLocalizations.of(context)!.recipeSignInToAdd,
      );
      return;
    }
    try {
      await _supabase.addFoodEntryWithItem(
        FoodEntry(
          userId: userId,
          mealType: meal,
          date: DateTime.now(),
          totalCalories: widget.recipe.calories,
        ),
        (entryId) => MealItem(
          foodEntryId: entryId,
          name: widget.recipe.title,
          calories: widget.recipe.calories,
          proteinGrams: widget.recipe.proteinGrams,
          fatGrams: widget.recipe.fatGrams,
          carbsGrams: widget.recipe.carbsGrams,
          info: AppLocalizations.of(context)!.recipeServingInfo,
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
          AppLocalizations.of(context)!.recipeAddedToMeal(_mealName(meal)),
          icon: Icons.check_circle_outline,
        );
      }
    } catch (e) {
      if (mounted) {
        showWelmiSnackbar(
          context,
          AppLocalizations.of(context)!.recipeAddFailed,
          icon: Icons.error_outline,
        );
      }
    }
  }

  String _mealName(MealType meal) =>
      AppLocalizations.of(context)!.mealTypeLabel(meal);

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
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: () => Navigator.pop(context),
              icon: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.arrow_back, color: Colors.black),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'recipe-image-${r.id}',
                child: RecipeImage(
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
                      color: RecipeDesign.green,
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
                        color: RecipeDesign.green,
                      ),
                      _Nutrient(
                        value: '${r.proteinGrams.round()} г',
                        label: 'Белки',
                        color: RecipeDesign.protein,
                      ),
                      _Nutrient(
                        value: '${r.fatGrams.round()} г',
                        label: 'Жиры',
                        color: RecipeDesign.fat,
                      ),
                      _Nutrient(
                        value: '${r.carbsGrams.round()} г',
                        label: 'Углеводы',
                        color: RecipeDesign.carbs,
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
                        color: RecipeDesign.green.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Шаг ${_cookingStep + 1} из ${r.steps.length}',
                            style: const TextStyle(
                              color: RecipeDesign.green,
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
                            backgroundColor: RecipeDesign.green.withValues(
                              alpha: .15,
                            ),
                            child: Text(
                              '${s.stepNumber}',
                              style: const TextStyle(
                                color: RecipeDesign.green,
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
              backgroundColor: RecipeDesign.green,
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

  final String value;
  final String label;
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
    avatar: Icon(icon, size: 17, color: RecipeDesign.green),
    label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    onPressed: onTap,
  );
}
