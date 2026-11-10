import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/models/supabase_models.dart';
import 'package:lumina/core/services/auth_service.dart';
import 'package:lumina/core/services/daily_tracker.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/app_app_bar.dart';
import 'package:lumina/core/widgets/app_dialog.dart';
import 'package:lumina/core/widgets/app_states.dart';
import 'package:lumina/core/widgets/ux_helpers.dart';
import 'package:lumina/features/diary/data/diary_repository.dart';
import 'package:lumina/features/diary/domain/diary_meals.dart';
import 'package:lumina/features/diary/presentation/widgets/add_food_sheet.dart';
import 'package:lumina/features/diary/presentation/widgets/diary_meal_section.dart';
import 'package:lumina/features/diary/presentation/widgets/diary_summary_card.dart';
import 'package:lumina/features/diary/presentation/widgets/food_item_actions_sheet.dart';
import 'package:lumina/features/diary/presentation/widgets/voice_food_dialog.dart';
import 'package:lumina/features/food_database/domain/models/food_product.dart';
import 'package:lumina/features/food_database/presentation/pages/product_search_page.dart';
import 'package:lumina/features/food_database/presentation/widgets/meal_item_editor_sheet.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Дневник питания за сегодня: сводка КБЖУ и приёмы пищи.
class DiaryPage extends StatefulWidget {
  const DiaryPage({super.key});

  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  final DiaryRepository _repository = DiaryRepository();
  final DailyTracker _tracker = DailyTracker();

  bool _isLoading = true;
  DiaryMeals _meals = DiaryMeals.empty();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tracker.addListener(_onTrackerChanged);
    _loadTodayData();
  }

  @override
  void dispose() {
    _tracker.removeListener(_onTrackerChanged);
    super.dispose();
  }

  void _onTrackerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadTodayData({bool showSpinner = true}) async {
    if (showSpinner) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    final userId = AuthService().userId;
    if (userId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = null;
        _meals = DiaryMeals.empty();
      });
      return;
    }

    // День собирается целиком и применяется одним setState: промежуточные
    // перестроения (например, от DailyTracker) не видят полузагруженный день.
    DiaryMeals meals;
    String? error;
    try {
      meals = await _repository.loadDay(userId, DateTime.now());
      await _tracker.loadToday();
    } catch (e) {
      debugPrint('Diary load failed: $e');
      error = 'Ошибка загрузки данных';
      meals = DiaryMeals.empty();
    }

    if (!mounted) return;
    setState(() {
      _meals = meals;
      _errorMessage = error;
      _isLoading = false;
    });
  }

  void _addFoodItem(MealType mealType) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => AddFoodSheet(
        mealType: mealType,
        onAdd: (draft) async {
          await _saveFood(mealType, draft);
          if (sheetContext.mounted) Navigator.pop(sheetContext);
        },
      ),
    );
  }

  void _addVoiceFoodItem(MealType mealType) {
    HapticFeedback.mediumImpact();
    VoiceFoodDialog.show(
      context: context,
      mealType: mealType,
      onConfirm: (name, kcal, protein, fat, carbs, info) => _saveFood(
        mealType,
        FoodDraft(
          name: name,
          calories: kcal,
          proteinGrams: protein.toDouble(),
          fatGrams: fat.toDouble(),
          carbsGrams: carbs.toDouble(),
          description: info,
        ),
      ),
    );
  }

  /// Поиск продукта в Open Food Facts и добавление выбранной порции.
  Future<void> _addFromDatabase(MealType mealType) async {
    HapticFeedback.mediumImpact();
    final draft = await Navigator.push<FoodDraft>(
      context,
      smoothPageRoute(const ProductSearchPage()),
    );
    if (!mounted || draft == null) return;
    await _saveFood(mealType, draft);
  }

  Future<void> _saveFood(MealType mealType, FoodDraft draft) async {
    final userId = AuthService().userId;
    if (userId == null) {
      if (mounted) {
        showWelmiSnackbar(
          context,
          AppLocalizations.of(context)!.loginToSave,
          icon: Icons.login,
        );
      }
      return;
    }

    try {
      final item = await _repository.add(userId, mealType, draft);
      if (mounted) setState(() => _meals.add(mealType, item, draft.calories));
      await _tracker.addCalories(
        draft.calories,
        protein: (draft.proteinGrams ?? 0).round(),
        fat: (draft.fatGrams ?? 0).round(),
        carbs: (draft.carbsGrams ?? 0).round(),
        mealType: mealType,
      );
    } catch (e) {
      debugPrint('Diary save failed: $e');
      if (mounted) {
        showWelmiSnackbar(
          context,
          AppLocalizations.of(context)!.saveError,
          icon: Icons.error_outline,
        );
      }
    }
  }

  Future<void> _openItemActions(MealItem item) async {
    final action = await FoodItemActionsSheet.show(context, item);
    if (!mounted || action == null) return;
    switch (action) {
      case FoodItemAction.edit:
        await _editFoodItem(item);
      case FoodItemAction.delete:
        await _deleteFoodItem(item);
    }
  }

  Future<void> _editFoodItem(MealItem item) async {
    if (item.id.isEmpty || item.foodEntryId.isEmpty) return;
    final draft = await MealItemEditorSheet.show(context, item);
    if (!mounted || draft == null) return;

    await _runAndReload(
      () => _repository.update(item, draft),
      success: 'Запись обновлена',
      successIcon: Icons.check_circle,
      failure: 'Не удалось обновить запись',
    );
  }

  Future<void> _deleteFoodItem(MealItem item) async {
    if (item.id.isEmpty || item.foodEntryId.isEmpty) return;
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Удалить запись?',
      message: item.name.isEmpty
          ? 'Запись будет удалена из дневника.'
          : '«${item.name}» будет удалена из дневника.',
      cancelLabel: AppLocalizations.of(context)!.cancel,
    );
    if (!mounted || confirmed != true) return;

    await _runAndReload(
      () => _repository.delete(item),
      success: 'Запись удалена',
      successIcon: Icons.delete_outline,
      failure: 'Не удалось удалить запись',
    );
  }

  /// Выполняет изменение в БД, перечитывает день и сообщает результат.
  Future<void> _runAndReload(
    Future<void> Function() change, {
    required String success,
    required IconData successIcon,
    required String failure,
  }) async {
    try {
      await change();
      await _loadTodayData(showSpinner: false);
      if (mounted) showWelmiSnackbar(context, success, icon: successIcon);
    } catch (e) {
      debugPrint('Diary change failed: $e');
      if (mounted) {
        showWelmiSnackbar(context, failure, icon: Icons.error_outline);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final loc = AppLocalizations.of(context)!;

    final Widget body;
    if (_isLoading) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: tc.text),
            const SizedBox(height: 16),
            Text(
              loc.loadingDiary,
              style: GoogleFonts.inter(
                color: tc.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    } else if (_errorMessage != null) {
      body = AppErrorState(message: _errorMessage!, onRetry: _loadTodayData);
    } else {
      body = SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Дневник — ещё и вкладка MainShell: там «назад» не нужна
            // (pop вытолкнул бы саму оболочку).
            AppAppBar(
              title: loc.diaryTitle,
              showBack: Navigator.canPop(context),
            ),
            const SizedBox(height: 24),
            DiarySummaryCard(
              tracker: _tracker,
              totalCalories: _meals.totalCalories,
            ),
            for (final (type, title) in [
              (MealType.breakfast, loc.breakfast),
              (MealType.lunch, loc.lunch),
              (MealType.dinner, loc.dinner),
              (MealType.snack, loc.snack),
            ]) ...[
              SizedBox(height: type == MealType.breakfast ? 24 : 16),
              DiaryMealSection(
                title: title,
                items: _meals.itemsOf(type),
                totalCalories: _meals.caloriesOf(type),
                onItemTap: _openItemActions,
                onAddManual: () => _addFoodItem(type),
                onAddVoice: () => _addVoiceFoodItem(type),
                onAddFromDatabase: () => _addFromDatabase(type),
              ),
            ],
            const SizedBox(height: 120),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: tc.background,
      body: SafeArea(child: body),
    );
  }
}
