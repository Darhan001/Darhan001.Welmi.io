import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/features/history/presentation/widgets/history_design.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Что записать: активность, воду или упражнение.
Future<void> showHistoryAddSheet(
  BuildContext context, {
  required VoidCallback onActivity,
  required VoidCallback onWater,
  required VoidCallback onExercise,
}) {
  final tc = ThemeColors.of(context);
  final loc = AppLocalizations.of(context)!;

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: tc.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.whatToLog,
              style: GoogleFonts.notoSerif(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: tc.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              loc.whatToLogSubtitle,
              style: TextStyle(fontSize: 13, color: tc.textSecondary),
            ),
            const SizedBox(height: 16),
            _AddActionTile(
              icon: Icons.directions_run_rounded,
              title: loc.activityLog,
              subtitle: loc.activityLogSubtitle,
              color: HistoryDesign.orange,
              onTap: () {
                Navigator.pop(ctx);
                onActivity();
              },
            ),
            _AddActionTile(
              icon: Icons.water_drop_rounded,
              title: loc.waterLog,
              subtitle: loc.waterLogSubtitle,
              color: HistoryDesign.blue,
              onTap: () {
                Navigator.pop(ctx);
                onWater();
              },
            ),
            _AddActionTile(
              icon: Icons.fitness_center_rounded,
              title: loc.exerciseLog,
              subtitle: loc.exerciseLogSubtitle,
              color: HistoryDesign.green,
              onTap: () {
                Navigator.pop(ctx);
                onExercise();
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _AddActionTile extends StatelessWidget {
  const _AddActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: tc.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: tc.text,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: tc.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: tc.textHint),
          ],
        ),
      ),
    );
  }
}

/// Сколько воды добавить. Возвращает миллилитры или `null`.
Future<int?> showWaterAmountSheet(
  BuildContext context, {
  required int todayMl,
}) {
  final tc = ThemeColors.of(context);
  final loc = AppLocalizations.of(context)!;

  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: tc.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.addWater,
              style: GoogleFonts.notoSerif(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: tc.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              loc.waterDrunkToday(todayMl),
              style: TextStyle(fontSize: 13, color: tc.textSecondary),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _WaterAmountChip(ml: 250, label: loc.glass),
                const SizedBox(width: 8),
                _WaterAmountChip(ml: 500, label: loc.bottle),
                const SizedBox(width: 8),
                _WaterAmountChip(ml: 1000, label: loc.liter),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _WaterAmountChip extends StatelessWidget {
  const _WaterAmountChip({required this.ml, required this.label});

  final int ml;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    return Expanded(
      child: GestureDetector(
        onTap: () => Navigator.pop(context, ml),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: HistoryDesign.blueSoft,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: HistoryDesign.blue.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.water_drop_rounded,
                size: 20,
                color: HistoryDesign.blue,
              ),
              const SizedBox(height: 6),
              Text(
                '+$ml',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2196F3),
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: tc.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
