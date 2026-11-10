import 'package:flutter/material.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Карточка «Сегодня съедено» с переходом в дневник.
class HomeDiaryCard extends StatelessWidget {
  const HomeDiaryCard({
    super.key,
    required this.consumed,
    required this.goal,
    required this.protein,
    required this.onTap,
  });

  final int consumed;
  final int goal;
  final int protein;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final loc = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: tc.card,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: tc.shadow(0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: tc.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.restaurant_rounded, size: 24, color: tc.green),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.foodDiary,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: tc.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    loc.homeDiarySummary(consumed, goal, protein),
                    style: TextStyle(
                      fontSize: 12,
                      color: tc.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: tc.textHint),
          ],
        ),
      ),
    );
  }
}
