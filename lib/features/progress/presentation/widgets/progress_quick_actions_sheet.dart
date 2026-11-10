import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/features/progress/presentation/widgets/progress_common.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Действие из шторки «Быстрые действия».
enum ProgressQuickAction { weight, measurements, bodyFat }

/// Шторка быстрых действий. Возвращает выбранное действие или null.
/// Открывать следующую шторку вызывающий код должен уже после закрытия этой.
Future<ProgressQuickAction?> showProgressQuickActions(BuildContext context) {
  final tc = ThemeColors.of(context);
  final loc = AppLocalizations.of(context)!;
  return showModalBottomSheet<ProgressQuickAction>(
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
              loc.quickActions,
              style: GoogleFonts.notoSerif(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: tc.text,
              ),
            ),
            const SizedBox(height: 16),
            for (final (action, icon, label, color) in [
              (
                ProgressQuickAction.weight,
                Icons.monitor_weight_outlined,
                loc.recordWeightAction,
                ProgressColors.weight,
              ),
              (
                ProgressQuickAction.measurements,
                Icons.straighten,
                loc.recordMeasurements,
                ProgressColors.measurements,
              ),
              (
                ProgressQuickAction.bodyFat,
                Icons.monitor_heart_outlined,
                loc.recordBodyFat,
                ProgressColors.bodyFat,
              ),
            ])
              _ActionTile(
                icon: icon,
                label: label,
                color: color,
                onTap: () => Navigator.pop(ctx, action),
              ),
          ],
        ),
      ),
    ),
  );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: tc.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: tc.text,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, size: 18, color: tc.textHint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
