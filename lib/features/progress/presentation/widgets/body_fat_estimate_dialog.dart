import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/features/progress/presentation/widgets/progress_common.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Диалог оценки % жира по замерам. Возвращает `true`, если пользователь
/// решил сохранить оценку. [estimate] == null — данных недостаточно.
Future<bool> showBodyFatEstimateDialog(
  BuildContext context, {
  required double? estimate,
  required bool isFemale,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final tc = ThemeColors.of(ctx);
      final loc = AppLocalizations.of(ctx)!;
      final bodyStyle = TextStyle(
        fontSize: 13,
        height: 1.45,
        color: tc.textSecondary,
      );
      return AlertDialog(
        backgroundColor: tc.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Оценка % жира',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: tc.text,
            fontSize: 17,
          ),
        ),
        content: estimate == null
            ? Text(
                'Недостаточно данных для расчёта.\n\n'
                'Нужны: рост и пол в профиле, а также замеры талии и шеи '
                '(для женщин — ещё и бёдер). Добавьте замеры и попробуйте снова.',
                style: bodyStyle,
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        estimate.toStringAsFixed(1),
                        style: GoogleFonts.inter(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: tc.text,
                        ),
                      ),
                      Text(
                        ' %',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: tc.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Расчёт по методу ВМФ США (Navy) на основе обхватов '
                    'талии, шеи${isFemale ? ', бёдер' : ''} и роста.\n\n'
                    'Это приблизительная оценка, а не измерение. '
                    'Погрешность метода — несколько процентных пунктов.',
                    style: bodyStyle.copyWith(fontSize: 12),
                  ),
                ],
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              estimate == null
                  ? MaterialLocalizations.of(ctx).okButtonLabel
                  : loc.cancel,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: tc.textSecondary,
              ),
            ),
          ),
          if (estimate != null)
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                loc.save,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: ProgressColors.bodyFat,
                ),
              ),
            ),
        ],
      );
    },
  );
  return result == true;
}
