import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/models/supabase_models.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/features/diary/presentation/widgets/diary_food_item_tile.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Карточка приёма пищи: заголовок с суммой калорий, список продуктов и
/// способы добавления (вручную, голосом, из базы продуктов).
class DiaryMealSection extends StatelessWidget {
  final String title;
  final List<MealItem> items;
  final int totalCalories;
  final ValueChanged<MealItem> onItemTap;
  final VoidCallback onAddManual;
  final VoidCallback onAddVoice;
  final VoidCallback onAddFromDatabase;

  const DiaryMealSection({
    super.key,
    required this.title,
    required this.items,
    required this.totalCalories,
    required this.onItemTap,
    required this.onAddManual,
    required this.onAddVoice,
    required this.onAddFromDatabase,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final loc = AppLocalizations.of(context)!;

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
                  '$totalCalories ${loc.kcal}',
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
                loc.nothingAdded,
                style: TextStyle(
                  color: tc.inactive,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            for (final item in items)
              DiaryFoodItemTile(item: item, onTap: () => onItemTap(item)),
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              children: [
                TextButton.icon(
                  onPressed: onAddManual,
                  icon: Icon(Icons.add, size: 16, color: tc.inactive),
                  label: Text(
                    loc.addButton,
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
                _AccentAction(
                  tooltip: 'Добавить голосом',
                  icon: Icons.mic_rounded,
                  label: 'Голос',
                  onTap: onAddVoice,
                ),
                Container(
                  width: 1,
                  height: 16,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: tc.divider,
                ),
                _AccentAction(
                  tooltip: 'Найти продукт в Open Food Facts',
                  icon: Icons.travel_explore_rounded,
                  label: 'База',
                  onTap: onAddFromDatabase,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Зелёная кнопка-ссылка «иконка + подпись» под списком продуктов.
class _AccentAction extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AccentAction({
    required this.tooltip,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: tc.green),
              const SizedBox(width: 4),
              Text(
                label,
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
    );
  }
}
