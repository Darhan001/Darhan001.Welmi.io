import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lumina/core/services/feedback_service.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/app_button.dart';
import 'package:lumina/core/widgets/ux_helpers.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Форма обратной связи: категория, текст и отправка через Edge Function.
class FeedbackForm extends StatefulWidget {
  const FeedbackForm({super.key});

  @override
  State<FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<FeedbackForm> {
  final _controller = TextEditingController();
  final _service = FeedbackService();
  String _category = 'feedback';
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final loc = AppLocalizations.of(context)!;
    final text = _controller.text.trim();
    if (text.isEmpty) {
      showWelmiSnackbar(
        context,
        loc.feedbackEmptyMessage,
        icon: Icons.info_outline,
      );
      return;
    }

    setState(() => _sending = true);
    final result = await _service.sendFeedback(
      message: text,
      category: _category,
    );
    if (!mounted) return;
    setState(() => _sending = false);

    if (result.success) {
      _controller.clear();
      showWelmiSnackbar(
        context,
        loc.thankYouFeedback,
        icon: Icons.check_circle,
      );
      return;
    }
    final errorMessage = switch (result.error) {
      'too_long' => loc.feedbackMessageTooLong,
      'session' => loc.feedbackSessionError,
      'rate_limit' => loc.feedbackRateLimitError,
      'function_missing' => loc.feedbackFunctionMissing,
      'secrets' => loc.feedbackSecretsMissing,
      'telegram' => loc.feedbackTelegramError,
      'function' => loc.feedbackFunctionError,
      'network' => loc.feedbackNetworkError,
      _ => loc.feedbackSendError,
    };
    showWelmiSnackbar(context, errorMessage, icon: Icons.error_outline);
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final loc = AppLocalizations.of(context)!;
    final categories = [
      ('feedback', Icons.chat_bubble_outline, loc.feedback),
      ('bug', Icons.bug_report_outlined, loc.feedbackCategoryBug),
      ('idea', Icons.lightbulb_outline, loc.feedbackCategoryIdea),
      ('support', Icons.help_outline, loc.supportTitle),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.feedback,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: tc.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            loc.feedbackSubtitle,
            style: TextStyle(
              color: tc.textHint,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (key, icon, label) in categories)
                ChoiceChip(
                  selected: _category == key,
                  onSelected: (_) {
                    HapticFeedback.selectionClick();
                    setState(() => _category = key);
                  },
                  showCheckmark: false,
                  avatar: Icon(
                    icon,
                    size: 14,
                    color: _category == key ? tc.green : tc.textHint,
                  ),
                  label: Text(label),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _category == key ? tc.green : tc.textHint,
                  ),
                  backgroundColor: tc.background,
                  selectedColor: tc.green.withValues(alpha: 0.15),
                  side: BorderSide(
                    color: _category == key ? tc.green : Colors.transparent,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLines: 4,
            maxLength: FeedbackService.maxMessageLength,
            style: TextStyle(color: tc.text),
            decoration: InputDecoration(
              hintText: loc.feedbackHint,
              hintStyle: TextStyle(color: tc.textHint),
              filled: true,
              fillColor: tc.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 8),
          AppButton(
            text: loc.send,
            icon: Icons.send_outlined,
            loading: _sending,
            onPressed: _send,
          ),
        ],
      ),
    );
  }
}
