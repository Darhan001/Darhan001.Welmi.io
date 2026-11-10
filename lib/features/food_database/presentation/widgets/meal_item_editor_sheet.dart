import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lumina/core/models/supabase_models.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/utils/number_input.dart';
import 'package:lumina/core/widgets/app_button.dart';
import 'package:lumina/core/widgets/ux_helpers.dart';
import 'package:lumina/features/food_database/domain/models/food_product.dart';
import 'package:lumina/features/food_database/presentation/widgets/food_sheet_frame.dart';

/// Редактирование записи дневника.
///
/// Если у записи известна масса порции, пищевая ценность на 100 г
/// восстанавливается из сохранённых значений, и при изменении граммов
/// калории и БЖУ пересчитываются автоматически. Для старых записей без
/// массы все значения редактируются вручную.
class MealItemEditorSheet extends StatefulWidget {
  final MealItem item;

  const MealItemEditorSheet({super.key, required this.item});

  static Future<FoodDraft?> show(BuildContext context, MealItem item) {
    return showModalBottomSheet<FoodDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MealItemEditorSheet(item: item),
    );
  }

  /// Сохраняем бренд/описание из старой строки, но убираем из неё
  /// прежнюю массу — она будет собрана заново из нового значения.
  static String descriptionFromInfo(String? info, {required bool hasPortion}) {
    if (info == null || info.trim().isEmpty) return '';
    final parts = info
        .split('·')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (!hasPortion) return parts.join(' · ');
    final gramsPattern = RegExp(r'^\d+([.,]\d+)?\s*г$');
    parts.removeWhere(gramsPattern.hasMatch);
    return parts.join(' · ');
  }

  @override
  State<MealItemEditorSheet> createState() => _MealItemEditorSheetState();
}

class _MealItemEditorSheetState extends State<MealItemEditorSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _gramsController;
  late final TextEditingController _kcalController;
  late final TextEditingController _proteinController;
  late final TextEditingController _fatController;
  late final TextEditingController _carbsController;

  /// Пищевая ценность на 100 г, восстановленная из сохранённой порции.
  FoodProduct? _per100;

  String? _error;

  bool get _hasPortion => _per100 != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    final grams = item.amountGrams;

    if (grams != null && grams > 0) {
      double? per100(double? value) =>
          value == null ? null : value / grams * 100;
      _per100 = FoodProduct(
        barcode: '',
        name: item.name,
        kcalPer100g: item.calories / grams * 100,
        proteinPer100g: per100(item.proteinGrams),
        fatPer100g: per100(item.fatGrams),
        carbsPer100g: per100(item.carbsGrams),
      );
    }

    String optional(double? value) =>
        value == null ? '' : formatNutrient(value);
    _nameController = TextEditingController(text: item.name);
    _gramsController = TextEditingController(
      text: grams == null ? '' : formatGrams(grams),
    );
    _kcalController = TextEditingController(text: '${item.calories}');
    _proteinController = TextEditingController(
      text: optional(item.proteinGrams),
    );
    _fatController = TextEditingController(text: optional(item.fatGrams));
    _carbsController = TextEditingController(text: optional(item.carbsGrams));

    if (_hasPortion) _gramsController.addListener(_recalculateFromGrams);
  }

  @override
  void dispose() {
    _gramsController.removeListener(_recalculateFromGrams);
    _nameController.dispose();
    _gramsController.dispose();
    _kcalController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    _carbsController.dispose();
    super.dispose();
  }

  void _recalculateFromGrams() {
    final grams = parseDecimalInput(_gramsController.text);
    final base = _per100;
    if (grams == null || grams <= 0 || base == null) return;

    final portion = base.portionOf(grams);
    String optional(double? value) =>
        value == null ? '' : formatNutrient(value);
    // Калории — целое число: поле принимает только цифры, а сохранение
    // разбирает его как int. Дробное значение («82.5») не сохранилось бы.
    _kcalController.text = portion.calories?.toString() ?? '';
    _proteinController.text = optional(portion.proteinGrams);
    _fatController.text = optional(portion.fatGrams);
    _carbsController.text = optional(portion.carbsGrams);
    if (mounted) setState(() => _error = null);
  }

  double? _parseOptional(TextEditingController controller) {
    final value = parseDecimalInput(controller.text);
    if (value == null || value < 0) return null;
    return value;
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Название не может быть пустым.');
      return;
    }

    final kcal = int.tryParse(_kcalController.text.trim());
    if (kcal == null || kcal < 0) {
      setState(() => _error = 'Укажи калорийность целым числом.');
      return;
    }

    double? grams;
    if (_hasPortion) {
      grams = parseDecimalInput(_gramsController.text);
      if (grams == null || grams <= 0 || grams > 5000) {
        setState(() => _error = 'Масса порции должна быть от 1 до 5000 г.');
        return;
      }
    }

    hapticSuccess();
    Navigator.pop(
      context,
      FoodDraft(
        name: name,
        calories: kcal,
        proteinGrams: _parseOptional(_proteinController),
        fatGrams: _parseOptional(_fatController),
        carbsGrams: _parseOptional(_carbsController),
        grams: grams,
        description: MealItemEditorSheet.descriptionFromInfo(
          widget.item.info,
          hasPortion: _hasPortion,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    return FoodSheetFrame(
      children: [
        Text(
          'Изменить запись',
          style: GoogleFonts.notoSerif(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: tc.text,
          ),
        ),
        const SizedBox(height: 20),
        NutritionTextField(label: 'Название', controller: _nameController),
        if (_hasPortion) ...[
          const SizedBox(height: 10),
          NutritionTextField(
            label: 'Масса порции, г',
            controller: _gramsController,
            keyboardType: NutritionTextField.decimalKeyboard,
            inputFormatters: NutritionTextField.decimalFormatters,
          ),
          const SizedBox(height: 6),
          Text(
            'При изменении массы калории и БЖУ пересчитываются '
            'автоматически.',
            style: TextStyle(
              fontSize: 10,
              height: 1.35,
              fontWeight: FontWeight.w600,
              color: tc.textHint,
            ),
          ),
        ],
        const SizedBox(height: 10),
        NutritionTextField(
          label: 'Калории',
          controller: _kcalController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final (label, controller) in [
              ('Белки, г', _proteinController),
              ('Жиры, г', _fatController),
              ('Углеводы, г', _carbsController),
            ]) ...[
              if (label != 'Белки, г') const SizedBox(width: 10),
              Expanded(
                child: NutritionTextField(
                  label: label,
                  controller: controller,
                  keyboardType: NutritionTextField.decimalKeyboard,
                  inputFormatters: NutritionTextField.decimalFormatters,
                ),
              ),
            ],
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: TextStyle(
              color: tc.error,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 22),
        AppButton(text: 'Сохранить', size: AppButtonSize.lg, onPressed: _save),
      ],
    );
  }
}
