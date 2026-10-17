import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/ux_helpers.dart';
import 'package:lumina/features/food_database/domain/models/food_product.dart';

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
    final parsed = double.tryParse(
      _gramsController.text.trim().replaceAll(',', '.'),
    );
    if (parsed == null || !parsed.isFinite || parsed <= 0 || parsed > 5000) {
      return null;
    }
    return parsed;
  }

  FoodPortion? get _portion {
    final grams = _grams;
    return grams == null ? null : widget.product.portionOf(grams);
  }

  void _submit() {
    final portion = _portion;
    if (portion == null) {
      setState(() => _error = 'Укажи массу порции от 1 до 5000 г.');
      return;
    }
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
    final portion = _portion;

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
                Text(
                  product.subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: tc.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Text(
                _per100Label(product),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: tc.textSecondary,
                ),
              ),
              const SizedBox(height: 22),
              TextField(
                controller: _gramsController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
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
                children: [50, 100, 150, 200, 250]
                    .map(
                      (grams) => ChoiceChip(
                        label: Text('$grams г'),
                        selected: _grams == grams.toDouble(),
                        onSelected: (_) {
                          _gramsController.text = '$grams';
                          _gramsController.selection = TextSelection.collapsed(
                            offset: _gramsController.text.length,
                          );
                        },
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _grams == grams.toDouble()
                              ? tc.textOnPrimary
                              : tc.textSecondary,
                        ),
                        selectedColor: tc.primary,
                        backgroundColor: tc.card,
                        side: BorderSide.none,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
              if (!product.hasNutrition)
                _buildNoDataCard(tc)
              else if (portion == null)
                _buildHint(tc, 'Введи массу, чтобы увидеть расчёт.')
              else
                _buildPortionCard(portion, tc),
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tc.primary,
                    foregroundColor: tc.textOnPrimary,
                    disabledBackgroundColor: tc.disabled,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Добавить в дневник',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: tc.textOnPrimary,
                    ),
                  ),
                ),
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
          ),
        ),
      ),
    );
  }

  Widget _buildPortionCard(FoodPortion portion, ThemeColors tc) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${portion.isCaloriesEstimated ? '≈' : ''}${portion.calories ?? '—'}',
                style: GoogleFonts.inter(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: tc.text,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'ккал',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: tc.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _macro('Белки', portion.proteinGrams, tc),
              const SizedBox(width: 8),
              _macro('Жиры', portion.fatGrams, tc),
              const SizedBox(width: 8),
              _macro('Углеводы', portion.carbsGrams, tc),
            ],
          ),
          if (portion.isCaloriesEstimated) ...[
            const SizedBox(height: 10),
            Text(
              'Калорийность рассчитана из БЖУ: в базе её нет.',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: tc.textHint,
              ),
            ),
          ] else if (!widget.product.hasCompleteMacros) ...[
            const SizedBox(height: 10),
            Text(
              'В базе заполнены не все нутриенты — «—» означает «нет данных».',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: tc.textHint,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _macro(String label, double? value, ThemeColors tc) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: tc.background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
                color: tc.inactive,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value == null ? '—' : '${formatNutrient(value)} г',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: tc.text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataCard(ThemeColors tc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tc.errorBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: tc.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'В Open Food Facts у этого продукта нет пищевой ценности. '
              'Добавь запись вручную из дневника.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: tc.text,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHint(ThemeColors tc, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: tc.textSecondary,
      ),
    );
  }

  String _per100Label(FoodProduct product) {
    if (!product.hasNutrition) return 'Пищевая ценность: нет данных';
    final parts = <String>[
      if (product.kcalPer100g != null)
        '${formatNutrient(product.kcalPer100g)} ккал',
      if (product.proteinPer100g != null)
        'Б ${formatNutrient(product.proteinPer100g)} г',
      if (product.fatPer100g != null)
        'Ж ${formatNutrient(product.fatPer100g)} г',
      if (product.carbsPer100g != null)
        'У ${formatNutrient(product.carbsPer100g)} г',
    ];
    return 'На 100 г: ${parts.join(' · ')}';
  }
}
