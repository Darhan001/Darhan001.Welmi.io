import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/features/chat/presentation/widgets/chat_design.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Стартовый экран чата: пока переписки нет, вместо сообщений показываем
/// аватар, приветствие и готовые вопросы.
class ChatWelcomeView extends StatelessWidget {
  const ChatWelcomeView({
    super.key,
    required this.inputArea,
    required this.onSuggestion,
  });

  /// Поле ввода — прижато к низу, как и в режиме переписки.
  final Widget inputArea;
  final ValueChanged<String> onSuggestion;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  const _GlowAvatar(),
                  const SizedBox(height: 24),
                  Text(
                    loc.gymtoneTrainer,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: ChatDesign.lime.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    loc.aiWelcomeGreeting,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: ChatDesign.textPrimary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 36),
                  for (final suggestion in [
                    loc.aiSuggestion1,
                    loc.aiSuggestion2,
                    loc.aiSuggestion3,
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _SuggestionPill(
                        text: suggestion,
                        onTap: () => onSuggestion(suggestion),
                      ),
                    ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
        inputArea,
      ],
    );
  }
}

/// Аватар Welmi AI: три круга с лаймовым свечением вокруг.
class _GlowAvatar extends StatelessWidget {
  const _GlowAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            ChatDesign.lime.withValues(alpha: 0.2),
            ChatDesign.lime.withValues(alpha: 0.05),
            Colors.transparent,
          ],
          stops: const [0.3, 0.7, 1.0],
        ),
      ),
      child: Center(
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ChatDesign.lime.withValues(alpha: 0.1),
            border: Border.all(
              color: ChatDesign.lime.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: ChatDesign.avatarGradient,
                boxShadow: [
                  BoxShadow(
                    color: ChatDesign.lime.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'W',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Готовая подсказка: нажатие отправляет её в чат.
class _SuggestionPill extends StatelessWidget {
  const _SuggestionPill({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [ChatDesign.card, ChatDesign.cardGradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(ChatDesign.radiusLg),
          border: Border.all(color: ChatDesign.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: ChatDesign.textPrimary,
          ),
        ),
      ),
    );
  }
}
