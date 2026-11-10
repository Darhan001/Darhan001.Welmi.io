import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/utils/number_input.dart';
import 'package:lumina/core/widgets/app_button.dart';
import 'package:lumina/core/widgets/ux_helpers.dart';
import 'package:lumina/features/food_database/domain/models/food_product.dart';
import 'package:lumina/features/food_database/presentation/widgets/food_portion_details.dart';
import 'package:lumina/features/food_database/presentation/widgets/food_sheet_frame.dart';

/// Нижний шит выбора порции: показывает ценность на 100 г, пересчитывает
/// её на введённые граммы и возвращает готовую запись для дневника.
class FoodPortionSheet extends StatefulWidget {
  final FoodProduct product;
  final double initialGrams;

  const FoodPortionSheet({
    super.key,
    required this.product,
    this.initialGrams = 100,
  });

  static Future<FoodDraft?> show(
    BuildContext context,
    FoodProduct product, {
    double initialGrams = 100,
  }) {
    return showModalBottomSheet<FoodDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          FoodPortionSheet(product: product, initialGrams: initialGrams),
    );
  }

  @override
  State<FoodPortionSheet> createState() => _FoodPortionSheetState();
}

class _FoodPortionSheetState extends State<FoodPortionSheet> {
  static const _presets = [50, 100, 150, 200, 250];

  late final TextEditingController _gramsController;
  String? _error;

  @override
  void initState() {
    super.initState();
    _gramsController = TextEditingController(
      text: formatGrams(widget.initialGrams),
    );
    _gramsController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _gramsController.removeListener(_onChanged);
    _gramsController.dispose();
    super.dispose();
  }

  void _onChanged() {
    setState(() => _error = null);
  }

  double? get _grams {
    final parsed = parseDecimalInput(_gramsController.text);
    if (parsed == null || parsed <= 0 || parsed > 5000) return null;
    return parsed;
  }

  void _selectPreset(int grams) {
    _gramsController.text = '$grams';
    _gramsController.selection = TextSelection.collapsed(
      offset: _gramsController.text.length,
    );
  }

  void _submit() {
    final grams = _grams;
    if (grams == null) {
      setState(() => _error = 'Укажи массу порции от 1 до 5000 г.');
      return;
    }
    final portion = widget.product.portionOf(grams);
    if (portion.calories == null) {
      setState(
        () => _error =
            'В базе нет калорийности этого продукта — запись нельзя сохранить.',
      );
      return;
    }

    hapticSuccess();
    Navigator.pop(context, FoodDraft.fromPortion(widget.product, portion));
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final product = widget.product;
    final grams = _grams;

    return FoodSheetFrame(
      children: [
        Text(
          'Порция',
          style: GoogleFonts.notoSerif(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: tc.text,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          product.name,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: tc.text,
          ),
        ),
        if (product.subtitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(product.subtitle, style: _secondaryStyle(tc)),
        ],
        const SizedBox(height: 6),
        Text(per100Label(product), style: _secondaryStyle(tc)),
        const SizedBox(height: 22),
        TextField(
          controller: _gramsController,
          keyboardType: NutritionTextField.decimalKeyboard,
          inputFormatters: NutritionTextField.decimalFormatters,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: tc.text,
          ),
          decoration: InputDecoration(
            labelText: 'Масса порции',
            suffixText: 'г',
            filled: true,
            fillColor: tc.card,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            labelStyle: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: tc.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final preset in _presets)
              ChoiceChip(
                label: Text('$preset г'),
                selected: grams == preset.toDouble(),
                onSelected: (_) => _selectPreset(preset),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: grams == preset.toDouble()
                      ? tc.textOnPrimary
                      : tc.textSecondary,
                ),
                selectedColor: tc.primary,
                backgroundColor: tc.card,
                side: BorderSide.none,
              ),
          ],
        ),
        const SizedBox(height: 20),
        if (!product.hasNutrition)
          const FoodNoNutritionCard()
        else if (grams == null)
          Text('Введи массу, чтобы увидеть расчёт.', style: _secondaryStyle(tc))
        else
          FoodPortionCard(
            portion: product.portionOf(grams),
            hasCompleteMacros: product.hasCompleteMacros,
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
        const SizedBox(height: 20),
        AppButton(
          text: 'Добавить в дневник',
          size: AppButtonSize.lg,
          onPressed: _submit,
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            'Данные: Open Food Facts (открытая база)',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: tc.textHint,
            ),
          ),
        ),
      ],
    );
  }

  TextStyle _secondaryStyle(ThemeColors tc) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: tc.textSecondary,
  );
}
