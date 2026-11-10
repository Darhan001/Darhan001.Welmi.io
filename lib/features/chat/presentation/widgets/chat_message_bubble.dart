import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/features/chat/domain/chat_bubble.dart';
import 'package:lumina/features/chat/domain/chat_markup.dart';
import 'package:lumina/features/chat/presentation/widgets/chat_design.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Пузырь сообщения: текст с разметкой, время и (у ответов AI) кнопка
/// озвучивания.
class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.speakingText,
    required this.spokenTexts,
    required this.onToggleSpeech,
  });

  final ChatBubble message;

  /// Текст, который сейчас озвучивается (`SpeechOutputService.speakingText`).
  final ValueListenable<String?> speakingText;

  /// Уже озвученные ответы: для них кнопка становится «повторить».
  final Set<String> spokenTexts;
  final ValueChanged<ChatBubble> onToggleSpeech;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final loc = AppLocalizations.of(context)!;
    final accent = ChatDesign.lime.withValues(alpha: 0.7);

    return Padding(
      padding: EdgeInsets.only(
        left: isUser ? 48 : 0,
        right: isUser ? 0 : 48,
        top: 6,
        bottom: 6,
      ),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) const ChatAiBadge(),
          Flexible(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: isUser
                    ? ChatDesign.lime.withValues(alpha: 0.12)
                    : ChatDesign.card,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                border: Border.all(
                  color: isUser
                      ? ChatDesign.lime.withValues(alpha: 0.1)
                      : ChatDesign.cardBorder,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.isVoice) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.mic_rounded, size: 13, color: accent),
                        const SizedBox(width: 4),
                        Text(
                          loc.voiceMessageLabel,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            letterSpacing: 0.4,
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                  _MessageText(message: message),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(loc, message.timestamp),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: ChatDesign.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (isUser) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.done_all_rounded,
                          size: 12,
                          color: ChatDesign.lime.withValues(alpha: 0.5),
                        ),
                      ] else ...[
                        const SizedBox(width: 8),
                        _speakButton(loc),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Кнопка озвучивания ответа AI: «озвучить», «повторить» или «стоп».
  Widget _speakButton(AppLocalizations loc) {
    return ValueListenableBuilder<String?>(
      valueListenable: speakingText,
      builder: (context, speaking, _) {
        final isSpeaking = speaking == message.speechText;
        final replay = spokenTexts.contains(message.text);
        return Tooltip(
          message: isSpeaking
              ? loc.ttsStop
              : (replay ? loc.ttsReplay : loc.ttsPlay),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onToggleSpeech(message),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(
                isSpeaking
                    ? Icons.stop_circle_outlined
                    : (replay ? Icons.replay_rounded : Icons.volume_up_rounded),
                size: 16,
                color: isSpeaking ? ChatDesign.lime : ChatDesign.textMuted,
              ),
            ),
          ),
        );
      },
    );
  }

  static String _formatTime(AppLocalizations loc, DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return loc.aiJustNow;
    if (diff.inMinutes < 60) return loc.aiMinutesAgo(diff.inMinutes);
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }
}

/// Текст сообщения: `**жирный**` и `_курсив_` из ответа AI.
class _MessageText extends StatelessWidget {
  const _MessageText({required this.message});
  final ChatBubble message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final baseColor = isUser ? ChatDesign.lime : ChatDesign.textPrimary;
    final segments = message.segments;
    final plain = GoogleFonts.inter(
      fontSize: 15,
      height: 1.5,
      color: baseColor,
      fontWeight: FontWeight.w500,
    );
    if (segments.length == 1 && segments.first.style == ChatTextStyle.plain) {
      return Text(message.text, style: plain);
    }
    final bold = plain.copyWith(fontWeight: FontWeight.w800);
    final italic = plain.copyWith(
      color: isUser
          ? ChatDesign.lime.withValues(alpha: 0.7)
          : ChatDesign.textSecondary,
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.w400,
    );
    return RichText(
      textScaler: MediaQuery.textScalerOf(context),
      text: TextSpan(
        children: [
          for (final s in segments)
            TextSpan(
              text: s.text,
              style: switch (s.style) {
                ChatTextStyle.plain => plain,
                ChatTextStyle.bold => bold,
                ChatTextStyle.italic => italic,
              },
            ),
        ],
      ),
    );
  }
}
