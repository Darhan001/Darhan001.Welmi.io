import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/services/auth_service.dart';
import 'package:lumina/core/services/supabase_service.dart';
import 'package:lumina/core/services/daily_tracker.dart';
import 'package:lumina/core/models/supabase_models.dart';
import 'package:lumina/core/widgets/ux_helpers.dart';
import 'package:lumina/core/theme/theme_colors.dart';
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
    _loadTodayData();
  }

  Future<void> _loadTodayData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final userId = AuthService().userId;
    if (userId == null) {
      setState(() {
        _isLoading = false;
        _initEmptyMeals();
      });
      return;
    }

    try {
      final foodEntries = await _supabase.getFoodEntries(userId, DateTime.now());

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
        final itemMaps = items.map((item) => {
          'id': item.id,
          'food_entry_id': item.foodEntryId,
          'name': item.name,
          'info': item.info ?? '',
          'kcal': item.calories,
          'protein': item.proteinGrams ?? 0,
          'fat': item.fatGrams ?? 0,
          'carbs': item.carbsGrams ?? 0,
        }).toList();

        _meals[entry.mealType] = itemMaps;
        _mealTotals[entry.mealType] = entry.totalCalories;
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

  int get _totalCalories =>
      _mealTotals.values.fold(0, (sum, v) => sum + v);

  void _addFoodItem(MealType mealType) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddFoodSheet(
        mealType: mealType,
        onAdd: (name, kcal, protein, fat, carbs, info) async {
          await _saveFoodToSupabase(mealType, name, kcal, protein, fat, carbs, info);
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _saveFoodToSupabase(
    MealType mealType, String name, int kcal,
    int protein, int fat, int carbs, String info,
  ) async {
    final userId = AuthService().userId;
    if (userId == null) {        showWelmiSnackbar(context, AppLocalizations.of(context)!.loginToSave, icon: Icons.login);
      return;
    }

    try {
      // Создаём FoodEntry для нового элемента (totalCalories = калории только этого элемента)
      final entry = await _supabase.addFoodEntry(FoodEntry(
        userId: userId,
        mealType: mealType,
        date: DateTime.now(),
        totalCalories: kcal,
      ));

      await _supabase.addMealItem(MealItem(
        foodEntryId: entry.id,
        name: name,
        calories: kcal,
        proteinGrams: protein.toDouble(),
        fatGrams: fat.toDouble(),
        carbsGrams: carbs.toDouble(),
        info: info.isNotEmpty ? info : null,
      ));

      setState(() {
        _meals[mealType]!.add({
          'id': entry.id,
          'food_entry_id': entry.id,
          'name': name,
          'info': info,
          'kcal': kcal,
          'protein': protein,
          'fat': fat,
          'carbs': carbs,
        });
        _mealTotals[mealType] = _mealTotals[mealType]! + kcal;
      });

      await _tracker.addCalories(kcal,
          protein: protein, fat: fat, carbs: carbs, mealType: mealType);
    } catch (e) {
      if (mounted) {
        showWelmiSnackbar(context, AppLocalizations.of(context)!.activitySaved, icon: Icons.error_outline);
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
                Text('Загружаем дневник...',
                    style: GoogleFonts.inter(
                        color: tc.textSecondary,
                        fontWeight: FontWeight.w600)),
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
                  Text(AppLocalizations.of(context)!.diaryTitle,
                      style: GoogleFonts.notoSerif(
                          fontWeight: FontWeight.w900, fontSize: 20, color: tc.text)),
                  const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: 24),
              _buildSummaryCard(tc),
              const SizedBox(height: 24),
              _buildMealSection(AppLocalizations.of(context)!.breakfast, MealType.breakfast, tc),
              const SizedBox(height: 16),
              _buildMealSection(AppLocalizations.of(context)!.lunch, MealType.lunch, tc),
              const SizedBox(height: 16),
              _buildMealSection(AppLocalizations.of(context)!.dinner, MealType.dinner, tc),
              const SizedBox(height: 16),
              _buildMealSection(AppLocalizations.of(context)!.snack, MealType.snack, tc),
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
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.todayLabel,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: tc.text)),
                  const SizedBox(height: 4),                   Text(AppLocalizations.of(context)!.remainingKcal(remaining),
                      style: TextStyle(
                          fontSize: 13, color: tc.textSecondary, fontWeight: FontWeight.w600)),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('$_totalCalories',
                      style: GoogleFonts.inter(
                          fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1, color: tc.text)),
                  Text(' / $goal',
                      style: TextStyle(
                          fontSize: 16, color: tc.inactive, fontWeight: FontWeight.w900)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              _buildMacroProgress(
                  'БЕЛКИ', _tracker.proteinProgress,
                  '${_tracker.totalProtein}г', '${_tracker.goalProtein}г',
                  const Color(0xFF75A47F), tc),
              const SizedBox(width: 12),
              _buildMacroProgress(
                  'ЖИРЫ', _tracker.fatProgress,
                  '${_tracker.totalFat}г', '${_tracker.goalFat}г',
                  const Color(0xFFFFB347), tc),
              const SizedBox(width: 12),
              _buildMacroProgress(
                  'УГЛЕВОДЫ', _tracker.carbsProgress,
                  '${_tracker.totalCarbs}г', '${_tracker.goalCarbs}г',
                  const Color(0xFF4A90E2), tc),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroProgress(String label, double val, String current, String goal, Color color, ThemeColors tc) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha:0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5)),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(current,
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w900, color: tc.text)),
                Text(' / $goal',
                    style: TextStyle(
                        fontSize: 9, fontWeight: FontWeight.w700, color: tc.inactive)),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              height: 6, width: double.infinity,
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
          )
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 16, color: tc.text)),
                Text('$total ккал',
                    style: TextStyle(
                        color: tc.inactive, fontSize: 13, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          Divider(height: 1, indent: 20, endIndent: 20, color: tc.divider),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(AppLocalizations.of(context)!.nothingAdded,
                  style: TextStyle(color: tc.inactive, fontSize: 12, fontWeight: FontWeight.w600)),
            )
          else
            ...items.map((item) => _buildFoodItem(
                  item['name'] as String? ?? '',
                  item['info'] as String? ?? '',
                  '${item['kcal'] ?? 0}',
                  tc,
                )),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextButton.icon(
              onPressed: () => _addFoodItem(mealType),
              icon: Icon(Icons.add, size: 16, color: tc.inactive),
              label: Text(AppLocalizations.of(context)!.addButton,
                  style: TextStyle(color: tc.inactive, fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodItem(String name, String info, String kcal, ThemeColors tc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: tc.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.restaurant_rounded,
                size: 20, color: tc.inactive),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800, color: tc.text)),
                if (info.isNotEmpty)
                  Text(info,
                      style: TextStyle(
                          fontSize: 12, color: tc.textSecondary, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Text(kcal,
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: tc.text)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 🍽️ ВСТРОЕННЫЙ БОТТОМ-ШИТ ДОБАВЛЕНИЯ ЕДЫ
// ═══════════════════════════════════════════════════════════════

class _AddFoodSheet extends StatefulWidget {
  final MealType mealType;
  final Future<void> Function(String name, int kcal, int protein, int fat, int carbs, String info) onAdd;

  const _AddFoodSheet({
    required this.mealType,
    required this.onAdd,
  });

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
    if (name.isEmpty || kcal <= 0) {        showWelmiSnackbar(context, AppLocalizations.of(context)!.enterNameAndCalories, icon: Icons.info_outline);
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
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: tc.inactive,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text('Добавить в ${mealLabels[widget.mealType]}',
              style: GoogleFonts.notoSerif(
                  fontSize: 20, fontWeight: FontWeight.w900, color: tc.text)),
          const SizedBox(height: 24),
          _buildField(AppLocalizations.of(context)!.foodName, _nameController, tc, hint: AppLocalizations.of(context)!.foodNameHint),
          const SizedBox(height: 10),
          _buildField(AppLocalizations.of(context)!.kcalLabel, _kcalController, tc, keyboardType: TextInputType.number),
          const SizedBox(height: 10),
          Row(
            children: [               Expanded(child: _buildField(AppLocalizations.of(context)!.proteinGrams, _proteinController, tc, keyboardType: TextInputType.number)),
              const SizedBox(width: 10),               Expanded(child: _buildField(AppLocalizations.of(context)!.fatGrams, _fatController, tc, keyboardType: TextInputType.number)),
              const SizedBox(width: 10),               Expanded(child: _buildField(AppLocalizations.of(context)!.carbsGrams, _carbsController, tc, keyboardType: TextInputType.number)),
            ],
          ),
          const SizedBox(height: 10),
          _buildField(AppLocalizations.of(context)!.description, _infoController, tc, hint: AppLocalizations.of(context)!.descriptionHint),
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
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isSaving
                  ? SizedBox(
                      width: 24, height: 24,
                      child: CircularProgressIndicator(
                          color: tc.textOnPrimary, strokeWidth: 2))
                  : Text(AppLocalizations.of(context)!.addButton,
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: tc.textOnPrimary)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, ThemeColors tc,
      {TextInputType? keyboardType, String? hint}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: tc.text),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w600, color: tc.textSecondary),
      ),
    );
  }
}
