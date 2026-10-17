import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lumina/core/models/supabase_models.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/ux_helpers.dart';
import 'package:lumina/features/food_database/domain/models/food_product.dart';

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

  double? _baseKcalPer100g;
  double? _baseProteinPer100g;
  double? _baseFatPer100g;
  double? _baseCarbsPer100g;

  String? _error;

  bool get _hasPortion =>
      widget.item.amountGrams != null && widget.item.amountGrams! > 0;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    final grams = item.amountGrams;

    if (grams != null && grams > 0) {
      _baseKcalPer100g = item.calories / grams * 100;
      _baseProteinPer100g = item.proteinGrams == null
          ? null
          : item.proteinGrams! / grams * 100;
      _baseFatPer100g = item.fatGrams == null
          ? null
          : item.fatGrams! / grams * 100;
      _baseCarbsPer100g = item.carbsGrams == null
          ? null
          : item.carbsGrams! / grams * 100;
    }

    _nameController = TextEditingController(text: item.name);
    _gramsController = TextEditingController(
      text: grams == null ? '' : formatGrams(grams),
    );
    _kcalController = TextEditingController(text: '${item.calories}');
    _proteinController = TextEditingController(
      text: item.proteinGrams == null ? '' : formatNutrient(item.proteinGrams),
    );
    _fatController = TextEditingController(
      text: item.fatGrams == null ? '' : formatNutrient(item.fatGrams),
    );
    _carbsController = TextEditingController(
      text: item.carbsGrams == null ? '' : formatNutrient(item.carbsGrams),
    );

    if (_hasPortion) {
      _gramsController.addListener(_recalculateFromGrams);
    }
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
    final grams = double.tryParse(
      _gramsController.text.trim().replaceAll(',', '.'),
    );
    if (grams == null || grams <= 0) return;

    void apply(TextEditingController controller, double? per100) {
      if (per100 == null) {
        controller.text = '';
        return;
      }
      controller.text = formatNutrient(per100 * grams / 100);
    }

    apply(_kcalController, _baseKcalPer100g);
    apply(_proteinController, _baseProteinPer100g);
    apply(_fatController, _baseFatPer100g);
    apply(_carbsController, _baseCarbsPer100g);
    if (mounted) setState(() => _error = null);
  }

  double? _parseOptional(TextEditingController controller) {
    final raw = controller.text.trim().replaceAll(',', '.');
    if (raw.isEmpty) return null;
    final value = double.tryParse(raw);
    if (value == null || !value.isFinite || value < 0) return null;
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
      grams = double.tryParse(
        _gramsController.text.trim().replaceAll(',', '.'),
      );
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
        description: _descriptionFromInfo(widget.item.info),
      ),
    );
  }

  /// Сохраняем бренд/описание из старой строки, но убираем из неё
  /// прежнюю массу — она будет собрана заново из нового значения.
  String _descriptionFromInfo(String? info) {
    if (info == null || info.trim().isEmpty) return '';
    final parts = info
        .split('·')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (!_hasPortion) return parts.join(' · ');
    final gramsPattern = RegExp(r'^\d+([.,]\d+)?\s*г$');
    parts.removeWhere(gramsPattern.hasMatch);
    return parts.join(' · ');
  }

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
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: SingleChildScrollView(
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
                'Изменить запись',
                style: GoogleFonts.notoSerif(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: tc.text,
                ),
              ),
              const SizedBox(height: 20),
              _field('Название', _nameController, tc),
              if (_hasPortion) ...[
                const SizedBox(height: 10),
                _field(
                  'Масса порции, г',
                  _gramsController,
                  tc,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
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
              _field(
                'Калории',
                _kcalController,
                tc,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _field('Белки, г', _proteinController, tc)),
                  const SizedBox(width: 10),
                  Expanded(child: _field('Жиры, г', _fatController, tc)),
                  const SizedBox(width: 10),
                  Expanded(child: _field('Углеводы, г', _carbsController, tc)),
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tc.primary,
                    foregroundColor: tc.textOnPrimary,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Сохранить',
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
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller,
    ThemeColors tc, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: tc.text,
      ),
      decoration: InputDecoration(
        labelText: label,
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
