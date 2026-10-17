import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lumina/core/theme/app_colors.dart';
import 'package:lumina/core/theme/theme_provider.dart';
import 'package:lumina/core/services/feedback_service.dart';
import 'package:lumina/core/services/auth_service.dart';

import 'package:lumina/core/widgets/ux_helpers.dart';
import 'package:lumina/l10n/app_localizations.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  int? _expandedFaq;
  final _feedbackController = TextEditingController();
  final _feedbackService = FeedbackService();
  String _selectedCategory = 'feedback';
  bool _isSending = false;

  List<Map<String, String>> get _faq {
    final loc = AppLocalizations.of(context)!;
    return [
      {'q': loc.faqQ1, 'a': loc.faqA1},
      {'q': loc.faqQ2, 'a': loc.faqA2},
      {'q': loc.faqQ3, 'a': loc.faqA3},
      {'q': loc.faqQ4, 'a': loc.faqA4},
      {'q': loc.faqQ5, 'a': loc.faqA5},
    ];
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  // ─── Отправка обратной связи ─────────────────────────────
  Future<void> _sendFeedback() async {
    final text = _feedbackController.text.trim();
    if (text.isEmpty) {
      showWelmiSnackbar(
        context,
        AppLocalizations.of(context)!.feedbackEmptyMessage,
        icon: Icons.info_outline,
      );
      return;
    }

    setState(() => _isSending = true);

    final result = await _feedbackService.sendFeedback(
      message: text,
      category: _selectedCategory,
    );

    if (!mounted) return;

    setState(() => _isSending = false);

    if (result.success) {
      _feedbackController.clear();
      showWelmiSnackbar(
        context,
        AppLocalizations.of(context)!.thankYouFeedback,
        icon: Icons.check_circle,
      );
    } else {
      final loc = AppLocalizations.of(context)!;
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
  }

  // ─── Открыть Telegram ────────────────────────────────────
  Future<void> _openTelegram() async {
    final username = 'welmi_support';
    // Пробуем открыть Telegram напрямую
    final telegramUri = Uri.parse('tg://resolve?domain=$username');
    final webUri = Uri.parse('https://t.me/$username');

    if (await canLaunchUrl(telegramUri)) {
      await launchUrl(telegramUri);
    } else if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  // ─── Открыть Email ──────────────────────────────────────
  Future<void> _openEmail() async {
    final userName = AuthService().displayName ?? 'User';
    final email = Uri(
      scheme: 'mailto',
      path: 'support@welmi.app',
      query:
          'subject=${Uri.encodeComponent('Welmi Support — $userName')}&body=${Uri.encodeComponent('Hello Welmi team,\n\n')}',
    );

    if (await canLaunchUrl(email)) {
      await launchUrl(email);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeProvider.isDark(context);
    final bgColor = isDark ? AppColors.darkBackground : AppColors.background;
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? AppColors.darkText : Colors.black;
    final textSecondary = isDark ? AppColors.darkTextSecondary : Colors.black54;
    final textHint = isDark ? AppColors.darkTextHint : Colors.black26;
    final inputBg = isDark ? AppColors.darkBackground : const Color(0xFFF9F7F2);
    final buttonColor = isDark ? Colors.white : Colors.black;
    final buttonTextColor = isDark ? Colors.black : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.arrow_back, size: 28, color: textColor),
                  ),
                  Text(
                    AppLocalizations.of(context)!.supportTitle,
                    style: GoogleFonts.notoSerif(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(width: 28),
                ],
              ),
              const SizedBox(height: 24),

              // Contact cards — кликабельные!
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _openEmail,
                      child: _buildContactCard(
                        Icons.email_outlined,
                        AppLocalizations.of(context)!.writeToUs,
                        'support@welmi.app',
                        isDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _openTelegram,
                      child: _buildContactCard(
                        Icons.telegram_outlined,
                        AppLocalizations.of(context)!.telegram,
                        '@welmi_support',
                        isDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // FAQ
              Text(
                AppLocalizations.of(context)!.faq,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 16),

              ..._faq.asMap().entries.map((entry) {
                final i = entry.key;
                final item = entry.value;
                final isExpanded = _expandedFaq == i;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isExpanded
                          ? AppColors.iconGreen.withValues(alpha: 0.3)
                          : Colors.transparent,
                    ),
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => setState(
                          () => _expandedFaq = isExpanded ? null : i,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item['q']!,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: textColor,
                                  ),
                                ),
                              ),
                              AnimatedRotation(
                                turns: isExpanded ? 0.5 : 0,
                                duration: const Duration(milliseconds: 200),
                                child: Icon(Icons.expand_more, color: textHint),
                              ),
                            ],
                          ),
                        ),
                      ),
                      AnimatedCrossFade(
                        firstChild: const SizedBox(),
                        secondChild: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Text(
                            item['a']!,
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ),
                        crossFadeState: isExpanded
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 200),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 24),

              // ─── Обратная связь (реальная отправка!) ───
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.feedback,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context)!.feedbackSubtitle,
                      style: TextStyle(
                        color: textHint,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ─── Категория ───
                    _buildCategoryPicker(isDark, textColor, textHint),
                    const SizedBox(height: 12),

                    // ─── Поле ввода ───
                    TextField(
                      controller: _feedbackController,
                      maxLines: 4,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.feedbackHint,
                        hintStyle: TextStyle(color: textHint),
                        filled: true,
                        fillColor: inputBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ─── Кнопка отправки ───
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSending ? null : _sendFeedback,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                          foregroundColor: buttonTextColor,
                          disabledBackgroundColor: buttonColor.withValues(
                            alpha: 0.5,
                          ),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _isSending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white70,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.send_outlined, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    AppLocalizations.of(context)!.send,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Выбор категории ────────────────────────────────────
  Widget _buildCategoryPicker(bool isDark, Color textColor, Color textHint) {
    final categories = [
      {
        'key': 'feedback',
        'icon': Icons.chat_bubble_outline,
        'label': AppLocalizations.of(context)!.feedback,
      },
      {'key': 'bug', 'icon': Icons.bug_report_outlined, 'label': 'Bug'},
      {'key': 'idea', 'icon': Icons.lightbulb_outline, 'label': 'Idea'},
      {
        'key': 'support',
        'icon': Icons.help_outline,
        'label': AppLocalizations.of(context)!.supportTitle,
      },
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((cat) {
        final isSelected = _selectedCategory == cat['key'];
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedCategory = cat['key'] as String);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.iconGreen.withValues(alpha: 0.15)
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFFF9F7F2)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.iconGreen : Colors.transparent,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  cat['icon'] as IconData,
                  size: 14,
                  color: isSelected ? AppColors.iconGreen : textHint,
                ),
                const SizedBox(width: 6),
                Text(
                  cat['label'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? AppColors.iconGreen : textHint,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildContactCard(
    IconData icon,
    String title,
    String subtitle,
    bool isDark,
  ) {
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? AppColors.darkText : Colors.black;
    final textHint = isDark ? AppColors.darkTextHint : Colors.black38;
    final iconBg = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : AppColors.accentGreen;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.iconGreen, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: textHint,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
