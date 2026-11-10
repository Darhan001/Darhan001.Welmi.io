import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/services/speech_output_service.dart';
import 'package:lumina/features/chat/presentation/widgets/chat_design.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Выбор голоса синтезатора речи.
///
/// Возвращает `VoicePick` с выбранным голосом (`null` — голос по умолчанию)
/// или `null`, если шторку закрыли без выбора.
class VoicePick {
  const VoicePick(this.voice);
  final SpeechVoice? voice;
}

Future<VoicePick?> showChatVoicePicker(
  BuildContext context, {
  required List<SpeechVoice> voices,
  required SpeechVoice? selected,
}) {
  final loc = AppLocalizations.of(context)!;

  return showModalBottomSheet<VoicePick>(
    context: context,
    backgroundColor: ChatDesign.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(ChatDesign.radiusLg),
      ),
    ),
    builder: (ctx) {
      final maxHeight = MediaQuery.sizeOf(ctx).height * 0.6;
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Text(
                  loc.ttsVoiceSettings,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: ChatDesign.textPrimary,
                  ),
                ),
              ),
              _VoiceTile(
                title: loc.ttsVoiceDefault,
                isSelected: selected == null,
                onTap: () => Navigator.pop(ctx, const VoicePick(null)),
              ),
              if (voices.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: Text(
                    loc.ttsVoicesEmpty,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: ChatDesign.textSecondary,
                    ),
                  ),
                ),
              for (final voice in voices)
                _VoiceTile(
                  title: voice.name,
                  subtitle: voice.locale,
                  isSelected: voice == selected,
                  onTap: () => Navigator.pop(ctx, VoicePick(voice)),
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _VoiceTile extends StatelessWidget {
  const _VoiceTile({
    required this.title,
    this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: ChatDesign.textPrimary,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: ChatDesign.textSecondary,
              ),
            ),
      trailing: isSelected
          ? const Icon(Icons.check_rounded, color: ChatDesign.lime)
          : null,
    );
  }
}
