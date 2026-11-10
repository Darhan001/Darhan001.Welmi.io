import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/app_button.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Ошибка распознавания: сообщение и повторная попытка.
class VoiceFoodErrorView extends StatelessWidget {
  const VoiceFoodErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    return Column(
      children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tc.error.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.error_outline_rounded, color: tc.error, size: 36),
        ),
        const SizedBox(height: 16),
        Text(
          message ?? 'Произошла ошибка при распознавании',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: tc.text,
          ),
        ),
        const SizedBox(height: 24),
        AppButton(
          text: AppLocalizations.of(context)!.retry,
          icon: Icons.refresh_rounded,
          onPressed: onRetry,
        ),
      ],
    );
  }
}
