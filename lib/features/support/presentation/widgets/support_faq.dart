import 'package:flutter/material.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Частые вопросы: раскрывается не больше одного ответа одновременно.
class SupportFaq extends StatefulWidget {
  const SupportFaq({super.key});

  @override
  State<SupportFaq> createState() => _SupportFaqState();
}

class _SupportFaqState extends State<SupportFaq> {
  int? _expanded;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final loc = AppLocalizations.of(context)!;
    final items = [
      (loc.faqQ1, loc.faqA1),
      (loc.faqQ2, loc.faqA2),
      (loc.faqQ3, loc.faqA3),
      (loc.faqQ4, loc.faqA4),
      (loc.faqQ5, loc.faqA5),
    ];
    const duration = Duration(milliseconds: 200);

    return Column(
      children: [
        for (var i = 0; i < items.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: tc.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _expanded == i
                    ? tc.green.withValues(alpha: 0.3)
                    : Colors.transparent,
              ),
            ),
            child: Column(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () =>
                      setState(() => _expanded = _expanded == i ? null : i),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            items[i].$1,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: tc.text,
                            ),
                          ),
                        ),
                        AnimatedRotation(
                          turns: _expanded == i ? 0.5 : 0,
                          duration: duration,
                          child: Icon(Icons.expand_more, color: tc.textHint),
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox(width: double.infinity),
                  secondChild: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      items[i].$2,
                      style: TextStyle(
                        color: tc.textSecondary,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                  crossFadeState: _expanded == i
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: duration,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Карточка контакта (почта, Telegram).
class SupportContactCard extends StatelessWidget {
  const SupportContactCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Material(
      color: tc.card,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: tc.isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : tc.successBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: tc.green, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: tc.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: tc.textHint,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
