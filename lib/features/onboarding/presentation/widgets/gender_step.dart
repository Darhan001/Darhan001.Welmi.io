import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/models/onboarding_data.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/l10n/app_localizations.dart';

class GenderStep extends StatelessWidget {
  final Gender? selectedGender;
  final ValueChanged<Gender> onGenderChanged;

  const GenderStep({
    super.key,
    required this.selectedGender,
    required this.onGenderChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Text(
            AppLocalizations.of(context)!.onboardingGenderTitle,
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.onboardingGenderSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: tc.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 48),
          Row(
            children: [
              Expanded(
                child: _buildGenderCard(
                  AppLocalizations.of(context)!.male,
                  Icons.male,
                  Gender.male,
                  tc,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildGenderCard(
                  AppLocalizations.of(context)!.female,
                  Icons.female,
                  Gender.female,
                  tc,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderCard(
    String label,
    IconData icon,
    Gender gender,
    ThemeColors tc,
  ) {
    final isSelected = selectedGender == gender;
    return GestureDetector(
      onTap: () => onGenderChanged(gender),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: tc.card,
          borderRadius: BorderRadius.circular(24),
          border: isSelected ? Border.all(color: tc.primary, width: 2) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: isSelected ? tc.primary : tc.textHint),
            const SizedBox(height: 16),
            Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: isSelected ? tc.primary : tc.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
