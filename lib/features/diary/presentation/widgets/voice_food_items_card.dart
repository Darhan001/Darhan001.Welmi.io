import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/services/ai/ai_food_models.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Список продуктов, которые AI распознал в голосовом сообщении.
class VoiceFoodItemsCard extends StatelessWidget {
  const VoiceFoodItemsCard({super.key, required this.items});

  final List<VoiceFoodItem> items;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tc.divider),
      ),
      child: Column(
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: tc.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${item.name} — ${item.portion}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: tc.text,
                    ),
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.kcalApprox(item.calories),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: tc.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Блок уточнения: AI не уверен в количестве и просит ввести его текстом.
class VoiceFoodClarifyCard extends StatelessWidget {
  const VoiceFoodClarifyCard({
    super.key,
    required this.question,
    required this.controller,
    required this.onSubmit,
  });

  final String question;
  final TextEditingController controller;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    const warning = Color(0xFFFFB347);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: warning.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.help_outline_rounded, color: warning, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  question,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: tc.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  style: GoogleFonts.inter(fontSize: 13, color: tc.text),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(
                      context,
                    )!.voiceFoodClarifyHint,
                    hintStyle: TextStyle(color: tc.textHint, fontSize: 13),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    filled: true,
                    fillColor: tc.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: AppLocalizations.of(context)!.voiceFoodClarify,
                onPressed: onSubmit,
                icon: Icon(
                  Icons.check_circle_rounded,
                  color: tc.green,
                  size: 28,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
