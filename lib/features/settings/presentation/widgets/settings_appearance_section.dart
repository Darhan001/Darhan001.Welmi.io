import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/theme/theme_provider.dart';
import 'package:lumina/core/widgets/ux_helpers.dart';
import 'package:lumina/features/settings/presentation/widgets/settings_card.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Раздел «Внешний вид»: системная, светлая и тёмная темы.
class SettingsAppearanceSection extends StatelessWidget {
  const SettingsAppearanceSection({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionTitle(title: loc.appearance, isDark: isDark),
        const SizedBox(height: 12),
        SettingsCard(
          isDark: isDark,
          padding: const EdgeInsets.all(6),
          child: Row(
            children: [
              _ThemeOption(
                label: loc.themeSystem,
                mode: ThemeMode.system,
                icon: Icons.brightness_auto_outlined,
                isDark: isDark,
              ),
              _ThemeOption(
                label: loc.themeLight,
                mode: ThemeMode.light,
                icon: Icons.light_mode_outlined,
                isDark: isDark,
              ),
              _ThemeOption(
                label: loc.themeDark,
                mode: ThemeMode.dark,
                icon: Icons.dark_mode_outlined,
                isDark: isDark,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          loc.themeSystemDescription,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: SettingsDesign.textMuted(isDark),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.mode,
    required this.icon,
    required this.isDark,
  });

  final String label;
  final ThemeMode mode;
  final IconData icon;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final selected = ThemeProvider.of(context).themeMode == mode;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          hapticTap();
          ThemeProvider.of(context).onThemeChanged(mode);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? (isDark ? SettingsDesign.green : Colors.black)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 18,
                color: selected
                    ? Colors.white
                    : (isDark ? Colors.white54 : Colors.black45),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? Colors.white
                      : (isDark ? Colors.white70 : Colors.black54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
