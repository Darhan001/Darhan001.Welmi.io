import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/services/auth_service.dart';
import 'package:lumina/core/services/supabase_service.dart';
import 'package:lumina/core/services/daily_tracker.dart';
import 'package:lumina/core/models/supabase_models.dart';
import 'package:lumina/core/widgets/ux_helpers.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/features/diary/presentation/widgets/voice_food_dialog.dart';
import 'package:lumina/features/food_database/domain/models/food_product.dart';
import 'package:lumina/features/food_database/presentation/pages/product_search_page.dart';
import 'package:lumina/features/food_database/presentation/widgets/meal_item_editor_sheet.dart';
import 'package:lumina/l10n/app_localizations.dart';

class DiaryPage extends StatefulWidget {
  const DiaryPage({super.key});

  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  final SupabaseService _supabase = SupabaseService();
  final DailyTracker _tracker = DailyTracker();

  bool _isLoading = true;
  Map<MealType, List<Map<String, dynamic>>> _meals = {};
  Map<MealType, int> _mealTotals = {};
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
    } else {
      _errorMessage = null;
    }

    final userId = AuthService().userId;
    if (userId == null) {
      setState(() {
        _isLoading = false;
        _initEmptyMeals();
      });
      return;
    }

    try {
      final foodEntries = await _supabase.getFoodEntries(
        userId,
        DateTime.now(),
      );

      _meals = {
        MealType.breakfast: [],
        MealType.lunch: [],
        MealType.dinner: [],
        MealType.snack: [],
      };
      _mealTotals = {
        MealType.breakfast: 0,
        MealType.lunch: 0,
        MealType.dinner: 0,
        MealType.snack: 0,
      };

      for (final entry in foodEntries) {
        final items = await _supabase.getMealItems(entry.id);
        final itemMaps = items.map(_itemToMap).toList();

        _meals[entry.mealType]!.addAll(itemMaps);
        _mealTotals[entry.mealType] =
            (_mealTotals[entry.mealType] ?? 0) + entry.totalCalories;
      }

      await _tracker.loadToday();
    } catch (e) {
      _errorMessage = 'Ошибка загрузки данных';
      _initEmptyMeals();
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _itemToMap(MealItem item) => {
    'id': item.id,
    'food_entry_id': item.foodEntryId,
    'name': item.name,
    'info': item.info ?? '',
    'kcal': item.calories,
    'protein': item.proteinGrams,
    'fat': item.fatGrams,
    'carbs': item.carbsGrams,
    'amount_grams': item.amountGrams,
  };

  void _initEmptyMeals() {
    _meals = {
      MealType.breakfast: [],
      MealType.lunch: [],
      MealType.dinner: [],
      MealType.snack: [],
    };
    _mealTotals = {
      MealType.breakfast: 0,
      MealType.lunch: 0,
      MealType.dinner: 0,
      MealType.snack: 0,
    };
  }

  int get _totalCalories => _mealTotals.values.fold(0, (sum, v) => sum + v);

  void _addFoodItem(MealType mealType) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _AddFoodSheet(
        mealType: mealType,
        onAdd: (name, kcal, protein, fat, carbs, info) async {
          await _saveFoodToSupabase(
            mealType,
            FoodDraft(
              name: name,
              calories: kcal,
              proteinGrams: protein.toDouble(),
              fatGrams: fat.toDouble(),
              carbsGrams: carbs.toDouble(),
              description: info,
            ),
          );
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
      onConfirm: (name, kcal, protein, fat, carbs, info) async {
        await _saveFoodToSupabase(
          mealType,
          FoodDraft(
            name: name,
            calories: kcal,
            proteinGrams: protein.toDouble(),
            fatGrams: fat.toDouble(),
            carbsGrams: carbs.toDouble(),
            description: info,
          ),
        );
      },
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
    await _saveFoodToSupabase(mealType, draft);
  }

  Future<void> _saveFoodToSupabase(MealType mealType, FoodDraft draft) async {
    final userId = AuthService().userId;
    if (userId == null) {
      showWelmiSnackbar(
        context,
        AppLocalizations.of(context)!.loginToSave,
        icon: Icons.login,
      );
      return;
    }

    try {
      // Одна запись дневника = один FoodEntry + один MealItem.
      final entry = await _supabase.addFoodEntry(
        FoodEntry(
          userId: userId,
          mealType: mealType,
          date: DateTime.now(),
          totalCalories: draft.calories,
        ),
      );

      final item = await _supabase.addMealItem(
        MealItem(
          foodEntryId: entry.id,
          name: draft.name,
          calories: draft.calories,
          proteinGrams: draft.proteinGrams,
          fatGrams: draft.fatGrams,
          carbsGrams: draft.carbsGrams,
          amountGrams: draft.grams,
          info: draft.info.isEmpty ? null : draft.info,
        ),
      );

      setState(() {
        _meals[mealType]!.add(_itemToMap(item));
        _mealTotals[mealType] = (_mealTotals[mealType] ?? 0) + draft.calories;
      });

      await _tracker.addCalories(
        draft.calories,
        protein: (draft.proteinGrams ?? 0).round(),
        fat: (draft.fatGrams ?? 0).round(),
        carbs: (draft.carbsGrams ?? 0).round(),
        mealType: mealType,
      );
    } catch (e) {
      if (mounted) {
        showWelmiSnackbar(
          context,
          'Не удалось сохранить запись',
          icon: Icons.error_outline,
        );
      }
    }
  }

  Future<void> _openItemActions(Map<String, dynamic> item) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FoodItemActionsSheet(
        name: item['name'] as String? ?? '',
        info: item['info'] as String? ?? '',
        kcal: (item['kcal'] as num?)?.toInt() ?? 0,
        protein: (item['protein'] as num?)?.toDouble(),
        fat: (item['fat'] as num?)?.toDouble(),
        carbs: (item['carbs'] as num?)?.toDouble(),
      ),
    );
    if (!mounted || action == null) return;

    if (action == 'edit') {
      await _editFoodItem(item);
    } else if (action == 'delete') {
      await _deleteFoodItem(item);
    }
  }

  Future<void> _editFoodItem(Map<String, dynamic> item) async {
    final mealItem = MealItem(
      id: item['id'] as String? ?? '',
      foodEntryId: item['food_entry_id'] as String? ?? '',
      name: item['name'] as String? ?? '',
      calories: (item['kcal'] as num?)?.toInt() ?? 0,
      proteinGrams: (item['protein'] as num?)?.toDouble(),
      fatGrams: (item['fat'] as num?)?.toDouble(),
      carbsGrams: (item['carbs'] as num?)?.toDouble(),
      amountGrams: (item['amount_grams'] as num?)?.toDouble(),
      info: item['info'] as String?,
    );
    if (mealItem.id.isEmpty || mealItem.foodEntryId.isEmpty) return;

    final draft = await MealItemEditorSheet.show(context, mealItem);
    if (!mounted || draft == null) return;

    try {
      await _supabase.updateMealItem(
        id: mealItem.id,
        name: draft.name,
        calories: draft.calories,
        proteinGrams: draft.proteinGrams,
        fatGrams: draft.fatGrams,
        carbsGrams: draft.carbsGrams,
        amountGrams: draft.grams,
        info: draft.info.isEmpty ? null : draft.info,
      );
      await _supabase.updateFoodEntryTotalCalories(
        mealItem.foodEntryId,
        draft.calories,
      );
      await _loadTodayData(showSpinner: false);
      if (mounted) {
        showWelmiSnackbar(
          context,
          'Запись обновлена',
          icon: Icons.check_circle,
        );
      }
    } catch (e) {
      if (mounted) {
        showWelmiSnackbar(
          context,
          'Не удалось обновить запись',
          icon: Icons.error_outline,
        );
      }
    }
  }

  Future<void> _deleteFoodItem(Map<String, dynamic> item) async {
    final name = item['name'] as String? ?? '';
    final itemId = item['id'] as String? ?? '';
    final entryId = item['food_entry_id'] as String? ?? '';
    if (itemId.isEmpty || entryId.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final tc = ThemeColors.of(dialogContext);
        return AlertDialog(
          backgroundColor: tc.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'Удалить запись?',
            style: TextStyle(color: tc.text, fontWeight: FontWeight.w900),
          ),
          content: Text(
            name.isEmpty
                ? 'Запись будет удалена из дневника.'
                : '«$name» будет удалена из дневника.',
            style: TextStyle(color: tc.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                'Отмена',
                style: TextStyle(
                  color: tc.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                'Удалить',
                style: TextStyle(color: tc.error, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        );
      },
    );
    if (!mounted || confirmed != true) return;

    try {
      await _supabase.deleteMealItem(itemId);
      await _supabase.deleteFoodEntry(entryId);
      await _loadTodayData(showSpinner: false);
      if (mounted) {
        showWelmiSnackbar(
          context,
          'Запись удалена',
          icon: Icons.delete_outline,
        );
      }
    } catch (e) {
      if (mounted) {
        showWelmiSnackbar(
          context,
          'Не удалось удалить запись',
          icon: Icons.error_outline,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: tc.background,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: tc.text),
                const SizedBox(height: 16),
                Text(
                  'Загружаем дневник...',
                  style: GoogleFonts.inter(
                    color: tc.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: tc.background,
        body: SafeArea(
          child: ErrorStateWidget(
            message: _errorMessage!,
            onRetry: _loadTodayData,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: tc.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: tc.card,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: tc.shadow(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(Icons.arrow_back, size: 22, color: tc.text),
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context)!.diaryTitle,
                    style: GoogleFonts.notoSerif(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: tc.text,
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: 24),
              _buildSummaryCard(tc),
              const SizedBox(height: 24),
              _buildMealSection(
                AppLocalizations.of(context)!.breakfast,
                MealType.breakfast,
                tc,
              ),
              const SizedBox(height: 16),
              _buildMealSection(
                AppLocalizations.of(context)!.lunch,
                MealType.lunch,
                tc,
              ),
              const SizedBox(height: 16),
              _buildMealSection(
                AppLocalizations.of(context)!.dinner,
                MealType.dinner,
                tc,
              ),
              const SizedBox(height: 16),
              _buildMealSection(
                AppLocalizations.of(context)!.snack,
                MealType.snack,
                tc,
              ),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(ThemeColors tc) {
    final remaining = _tracker.remainingCalories;
    final goal = _tracker.goalCalories;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: tc.shadow(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.todayLabel,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: tc.text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppLocalizations.of(context)!.remainingKcal(remaining),
                      style: TextStyle(
                        fontSize: 13,
                        color: tc.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _CalorieArcProgress(current: _totalCalories, goal: goal, tc: tc),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              _buildMacroProgress(
                'БЕЛКИ',
                _tracker.proteinProgress,
                '${_tracker.totalProtein}г',
                '${_tracker.goalProtein}г',
                const Color(0xFF75A47F),
                tc,
              ),
              const SizedBox(width: 12),
              _buildMacroProgress(
                'ЖИРЫ',
                _tracker.fatProgress,
                '${_tracker.totalFat}г',
                '${_tracker.goalFat}г',
                const Color(0xFFFFB347),
                tc,
              ),
              const SizedBox(width: 12),
              _buildMacroProgress(
                'УГЛЕВОДЫ',
                _tracker.carbsProgress,
                '${_tracker.totalCarbs}г',
                '${_tracker.goalCarbs}г',
                const Color(0xFF4A90E2),
                tc,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroProgress(
    String label,
    double val,
    String current,
    String goal,
    Color color,
    ThemeColors tc,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  current,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: tc.text,
                  ),
                ),
                Text(
                  ' / $goal',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: tc.inactive,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              height: 6,
              width: double.infinity,
              decoration: BoxDecoration(
                color: tc.card,
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: val.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealSection(String title, MealType mealType, ThemeColors tc) {
    final items = _meals[mealType] ?? [];
    final total = _mealTotals[mealType] ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: tc.shadow(0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: tc.text,
                  ),
                ),
                Text(
                  '$total ккал',
                  style: TextStyle(
                    color: tc.inactive,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, indent: 20, endIndent: 20, color: tc.divider),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                AppLocalizations.of(context)!.nothingAdded,
                style: TextStyle(
                  color: tc.inactive,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            ...items.map((item) => _buildFoodItem(item, tc)),
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              children: [
                TextButton.icon(
                  onPressed: () => _addFoodItem(mealType),
                  icon: Icon(Icons.add, size: 16, color: tc.inactive),
                  label: Text(
                    AppLocalizations.of(context)!.addButton,
                    style: TextStyle(
                      color: tc.inactive,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(width: 1, height: 16, color: tc.divider),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Добавить голосом',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _addVoiceFoodItem(mealType),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.mic_rounded, size: 16, color: tc.green),
                          const SizedBox(width: 4),
                          Text(
                            'Голос',
                            style: GoogleFonts.inter(
                              color: tc.green,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 16,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: tc.divider,
                ),
                Tooltip(
                  message: 'Найти продукт в Open Food Facts',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _addFromDatabase(mealType),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.travel_explore_rounded,
                            size: 16,
                            color: tc.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'База',
                            style: GoogleFonts.inter(
                              color: tc.green,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodItem(Map<String, dynamic> item, ThemeColors tc) {
    final name = item['name'] as String? ?? '';
    final info = item['info'] as String? ?? '';
    final kcal = '${item['kcal'] ?? 0}';

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _openItemActions(item),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: tc.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.restaurant_rounded,
                size: 20,
                color: tc.inactive,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: tc.text,
                    ),
                  ),
                  if (info.isNotEmpty)
                    Text(
                      info,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: tc.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              kcal,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: tc.text,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.more_horiz_rounded, size: 16, color: tc.inactive),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 🍽️ ВСТРОЕННЫЙ БОТТОМ-ШИТ ДОБАВЛЕНИЯ ЕДЫ
// ═══════════════════════════════════════════════════════════════

class _AddFoodSheet extends StatefulWidget {
  final MealType mealType;
  final Future<void> Function(
    String name,
    int kcal,
    int protein,
    int fat,
    int carbs,
    String info,
  )
  onAdd;

  const _AddFoodSheet({required this.mealType, required this.onAdd});

  @override
  State<_AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends State<_AddFoodSheet> {
  final _nameController = TextEditingController();
  final _kcalController = TextEditingController();
  final _proteinController = TextEditingController();
  final _fatController = TextEditingController();
  final _carbsController = TextEditingController();
  final _infoController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _kcalController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    _carbsController.dispose();
    _infoController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final kcal = int.tryParse(_kcalController.text.trim()) ?? 0;
    if (name.isEmpty || kcal <= 0) {
      showWelmiSnackbar(
        context,
        AppLocalizations.of(context)!.enterNameAndCalories,
        icon: Icons.info_outline,
      );
      return;
    }

    setState(() => _isSaving = true);

    await widget.onAdd(
      name,
      kcal,
      int.tryParse(_proteinController.text.trim()) ?? 0,
      int.tryParse(_fatController.text.trim()) ?? 0,
      int.tryParse(_carbsController.text.trim()) ?? 0,
      _infoController.text.trim(),
    );

    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final mealLabels = {
      MealType.breakfast: AppLocalizations.of(context)!.breakfast,
      MealType.lunch: AppLocalizations.of(context)!.lunch,
      MealType.dinner: AppLocalizations.of(context)!.dinner,
      MealType.snack: AppLocalizations.of(context)!.snack,
    };

    return Container(
      decoration: BoxDecoration(
        color: tc.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: tc.inactive,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Добавить в ${mealLabels[widget.mealType]}',
            style: GoogleFonts.notoSerif(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: tc.text,
            ),
          ),
          const SizedBox(height: 24),
          _buildField(
            AppLocalizations.of(context)!.foodName,
            _nameController,
            tc,
            hint: AppLocalizations.of(context)!.foodNameHint,
          ),
          const SizedBox(height: 10),
          _buildField(
            AppLocalizations.of(context)!.kcalLabel,
            _kcalController,
            tc,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildField(
                  AppLocalizations.of(context)!.proteinGrams,
                  _proteinController,
                  tc,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildField(
                  AppLocalizations.of(context)!.fatGrams,
                  _fatController,
                  tc,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildField(
                  AppLocalizations.of(context)!.carbsGrams,
                  _carbsController,
                  tc,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildField(
            AppLocalizations.of(context)!.description,
            _infoController,
            tc,
            hint: AppLocalizations.of(context)!.descriptionHint,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: tc.primary,
                foregroundColor: tc.textOnPrimary,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isSaving
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: tc.textOnPrimary,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      AppLocalizations.of(context)!.addButton,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: tc.textOnPrimary,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    ThemeColors tc, {
    TextInputType? keyboardType,
    String? hint,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: tc.text,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: tc.textHint),
        filled: true,
        fillColor: tc.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: tc.textSecondary,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 🍽️ ДЕЙСТВИЯ С ЗАПИСЬЮ ДНЕВНИКА
// ═══════════════════════════════════════════════════════════════

class _FoodItemActionsSheet extends StatelessWidget {
  final String name;
  final String info;
  final int kcal;
  final double? protein;
  final double? fat;
  final double? carbs;

  const _FoodItemActionsSheet({
    required this.name,
    required this.info,
    required this.kcal,
    this.protein,
    this.fat,
    this.carbs,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    return Container(
      decoration: BoxDecoration(
        color: tc.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: tc.inactive,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            name,
            style: GoogleFonts.notoSerif(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: tc.text,
            ),
          ),
          if (info.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              info,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: tc.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: tc.card,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Text(
                  '$kcal',
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: tc.text,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'ккал',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: tc.textSecondary,
                  ),
                ),
                const Spacer(),
                _macroLabel('Б', protein, tc),
                const SizedBox(width: 10),
                _macroLabel('Ж', fat, tc),
                const SizedBox(width: 10),
                _macroLabel('У', carbs, tc),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context, 'delete'),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text(
                    'Удалить',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: tc.error,
                    side: BorderSide(color: tc.error.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, 'edit'),
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text(
                    'Изменить',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tc.primary,
                    foregroundColor: tc.textOnPrimary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _macroLabel(String label, double? value, ThemeColors tc) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            color: tc.textHint,
          ),
        ),
        Text(
          value == null ? '—' : '${formatNutrient(value)} г',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: tc.text,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 🌟 ПОЛУКРУГЛЫЙ АНИМИРОВАННЫЙ ПРОГРЕСС КАЛОРИЙ
// ═══════════════════════════════════════════════════════════════

class _CalorieArcProgress extends StatelessWidget {
  final int current;
  final int goal;
  final ThemeColors tc;

  const _CalorieArcProgress({
    required this.current,
    required this.goal,
    required this.tc,
  });

  @override
  Widget build(BuildContext context) {
    final double targetProgress = goal > 0
        ? (current / goal).clamp(0.0, 1.0)
        : 0.0;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: targetProgress),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, animatedProgress, child) {
        return SizedBox(
          width: 170,
          height: 98,
          child: CustomPaint(
            painter: _ArcPainter(
              progress: animatedProgress,
              trackColor: tc.card.computeLuminance() > 0.5
                  ? Colors.black.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.08),
              progressColor: tc.green,
            ),
            child: Align(
              alignment: const Alignment(0, 0.55),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$current',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                      color: tc.text,
                    ),
                  ),
                  Text(
                    ' / $goal',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: tc.inactive,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;

  _ArcPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 9.0;
    // Центр дуги в нижней части виджета
    final center = Offset(size.width / 2, size.height - 4);
    final radius = (size.width - strokeWidth) / 2;

    // Дуга идёт от -195 градусов до +15 градусов (210 градусов размах для изящной арки)
    const double startAngle = math.pi * 0.95; // ~171 градусов
    const double sweepAngle = math.pi * 1.1; // ~198 градусов размаха

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Фоновая дорожка
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, sweepAngle, false, trackPaint);

    // Заполненная часть прогресса с градиентом
    if (progress > 0.001) {
      final activeSweep = sweepAngle * progress;

      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startAngle, activeSweep, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor;
  }
}
