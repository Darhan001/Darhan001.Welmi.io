import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/features/chat/presentation/widgets/chat_design.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Подтверждение новой переписки: старые сообщения будут удалены.
///
/// Возвращает `true`, если пользователь согласился начать с чистого листа.
Future<bool> confirmNewChat(BuildContext context) async {
  final loc = AppLocalizations.of(context)!;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ChatDesign.radiusLg),
      ),
      backgroundColor: ChatDesign.card,
      title: Text(
        loc.aiNewChat,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w800,
          color: ChatDesign.textPrimary,
        ),
      ),
      content: Text(
        loc.aiNewChatConfirm,
        style: GoogleFonts.inter(color: ChatDesign.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(
            loc.drawerCancel,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: ChatDesign.textSecondary,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            loc.aiStart,
            style: GoogleFonts.inter(
              color: ChatDesign.lime,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
