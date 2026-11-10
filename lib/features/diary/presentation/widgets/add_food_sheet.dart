import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/models/supabase_models.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/utils/number_input.dart';
import 'package:lumina/core/widgets/app_button.dart';
import 'package:lumina/core/widgets/ux_helpers.dart';
import 'package:lumina/features/food_database/domain/models/food_product.dart';
import 'package:lumina/features/food_database/presentation/widgets/food_sheet_frame.dart';
import 'package:lumina/core/widgets/meal_type_label.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Нижний лист ручного добавления продукта в приём пищи.
///
/// [onAdd] сохраняет запись; лист закрывает вызывающая сторона.
class AddFoodSheet extends StatefulWidget {
  final MealType mealType;
  final Future<void> Function(FoodDraft draft) onAdd;

  const AddFoodSheet({super.key, required this.mealType, required this.onAdd});

  @override
  State<AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends State<AddFoodSheet> {
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

  /// Неотрицательное число из поля; пустое или некорректное — 0.
  double _macro(TextEditingController controller) {
    final value = parseDecimalInput(controller.text) ?? 0;
    return value < 0 ? 0 : value;
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final kcal = (parseDecimalInput(_kcalController.text) ?? 0).round();
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
      FoodDraft(
        name: name,
        calories: kcal,
        proteinGrams: _macro(_proteinController),
        fatGrams: _macro(_fatController),
        carbsGrams: _macro(_carbsController),
        description: _infoController.text.trim(),
      ),
    );
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final loc = AppLocalizations.of(context)!;
    final mealLabel = loc.mealTypeLabel(widget.mealType);

    return FoodSheetFrame(
      handleGap: 24,
      children: [
        Text(
          'Добавить в $mealLabel',
          style: GoogleFonts.notoSerif(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: tc.text,
          ),
        ),
        const SizedBox(height: 24),
        NutritionTextField(
          label: loc.foodName,
          controller: _nameController,
          hint: loc.foodNameHint,
        ),
        const SizedBox(height: 10),
        NutritionTextField(
          label: loc.kcalLabel,
          controller: _kcalController,
          keyboardType: NutritionTextField.decimalKeyboard,
          inputFormatters: NutritionTextField.decimalFormatters,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: NutritionTextField(
                label: loc.proteinGrams,
                controller: _proteinController,
                keyboardType: NutritionTextField.decimalKeyboard,
                inputFormatters: NutritionTextField.decimalFormatters,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: NutritionTextField(
                label: loc.fatGrams,
                controller: _fatController,
                keyboardType: NutritionTextField.decimalKeyboard,
                inputFormatters: NutritionTextField.decimalFormatters,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: NutritionTextField(
                label: loc.carbsGrams,
                controller: _carbsController,
                keyboardType: NutritionTextField.decimalKeyboard,
                inputFormatters: NutritionTextField.decimalFormatters,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        NutritionTextField(
          label: loc.description,
          controller: _infoController,
          hint: loc.descriptionHint,
        ),
        const SizedBox(height: 24),
        AppButton(
          text: loc.addButton,
          size: AppButtonSize.lg,
          loading: _isSaving,
          onPressed: _submit,
        ),
      ],
    );
  }
}
