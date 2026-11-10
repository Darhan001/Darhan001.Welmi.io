import 'package:flutter/material.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Подтверждение выхода из формы с несохранёнными изменениями.
///
/// Возвращает `true`, если пользователь согласился выйти без сохранения.
Future<bool> confirmDiscardProfileChanges(BuildContext context) async {
  final tc = ThemeColors.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: tc.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.discardChanges,
              style: TextStyle(fontWeight: FontWeight.w900, color: tc.text),
            ),
          ),
        ],
      ),
      content: Text(
        AppLocalizations.of(context)!.unsavedChangesBody,
        style: TextStyle(color: tc.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(
            AppLocalizations.of(context)!.stayAction,
            style: TextStyle(fontWeight: FontWeight.w700, color: tc.textHint),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            AppLocalizations.of(context)!.leaveAction,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.redAccent,
            ),
          ),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
