import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/models/supabase_models.dart';
import 'package:lumina/core/theme/app_tokens.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/app_button.dart';
import 'package:lumina/features/food_database/domain/models/food_product.dart';
import 'package:lumina/features/food_database/presentation/widgets/food_sheet_frame.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Что пользователь выбрал в листе действий с записью дневника.
enum FoodItemAction { edit, delete }

/// Нижний лист с КБЖУ записи и кнопками «Удалить» / «Изменить».
class FoodItemActionsSheet extends StatelessWidget {
  final MealItem item;

  const FoodItemActionsSheet({super.key, required this.item});

  static Future<FoodItemAction?> show(BuildContext context, MealItem item) {
    return showModalBottomSheet<FoodItemAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FoodItemActionsSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final tokens = AppTokens.of(context);
    final info = item.info ?? '';

    return FoodSheetFrame(
      children: [
        Text(
          item.name,
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
                '${item.calories}',
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: tc.text,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                AppLocalizations.of(context)!.kcal,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: tc.textSecondary,
                ),
              ),
              const Spacer(),
              _MacroLabel(label: 'Б', value: item.proteinGrams),
              const SizedBox(width: 10),
              _MacroLabel(label: 'Ж', value: item.fatGrams),
              const SizedBox(width: 10),
              _MacroLabel(label: 'У', value: item.carbsGrams),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              // Деструктивное действие: отдельного варианта у AppButton
              // нет, поэтому рамка в цвет ошибки, геометрия — из AppTokens.
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context, FoodItemAction.delete),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text(
                  'Удалить',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: tc.error,
                  side: BorderSide(color: tc.error.withValues(alpha: 0.4)),
                  padding: tokens.buttonMedium.padding,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(tokens.buttonRadius),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton(
                text: 'Изменить',
                icon: Icons.edit_rounded,
                onPressed: () => Navigator.pop(context, FoodItemAction.edit),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MacroLabel extends StatelessWidget {
  final String label;
  final double? value;

  const _MacroLabel({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
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
