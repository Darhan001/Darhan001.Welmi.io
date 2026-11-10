import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Ожидание: AI определяет продукты по распознанному тексту.
class VoiceFoodProcessingView extends StatelessWidget {
  const VoiceFoodProcessingView({super.key, required this.recognizedText});

  final String recognizedText;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(tc.green),
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context)!.voiceFoodAnalyzing,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: tc.text,
            ),
          ),
          const SizedBox(height: 6),
          if (recognizedText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '«$recognizedText»',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: tc.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
