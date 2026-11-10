import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/widgets/ux_helpers.dart';
import 'package:lumina/features/settings/presentation/pages/about_page.dart';
import 'package:lumina/features/settings/presentation/pages/privacy_policy_page.dart';
import 'package:lumina/features/settings/presentation/pages/terms_of_use_page.dart';
import 'package:lumina/features/settings/presentation/widgets/settings_card.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Раздел «О приложении»: версия сборки и правовые документы.
class SettingsAboutSection extends StatelessWidget {
  const SettingsAboutSection({
    super.key,
    required this.isDark,
    required this.version,
  });

  final bool isDark;

  /// Версия из сборки (`null`, пока она не загрузилась).
  final String? version;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionTitle(title: loc.aboutApp, isDark: isDark),
        const SizedBox(height: 12),
        SettingsCard(
          isDark: isDark,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              GestureDetector(
                onTap: () =>
                    Navigator.push(context, smoothPageRoute(const AboutPage())),
                child: SettingsInfoTile(
                  icon: Icons.info_outline,
                  title: loc.version,
                  trailing: version ?? '…',
                  isDark: isDark,
                ),
              ),
              Divider(
                height: 1,
                indent: 52,
                endIndent: 16,
                color: SettingsDesign.hairline(isDark),
              ),
              SettingsInfoTile(
                icon: Icons.description_outlined,
                title: loc.privacyPolicy,
                trailing: '',
                isDark: isDark,
                onTap: () => Navigator.push(
                  context,
                  smoothPageRoute(const PrivacyPolicyPage()),
                ),
              ),
              Divider(
                height: 1,
                indent: 52,
                endIndent: 16,
                color: SettingsDesign.hairline(isDark),
              ),
              SettingsInfoTile(
                icon: Icons.gavel_outlined,
                title: loc.termsOfUse,
                trailing: '',
                isDark: isDark,
                onTap: () => Navigator.push(
                  context,
                  smoothPageRoute(const TermsOfUsePage()),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Строка с иконкой, названием и значением (или стрелкой).
class SettingsInfoTile extends StatelessWidget {
  const SettingsInfoTile({
    super.key,
    required this.icon,
    required this.title,
    required this.trailing,
    required this.isDark,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String trailing;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        size: 22,
        color: isDark ? Colors.white70 : Colors.black54,
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: SettingsDesign.text(isDark),
        ),
      ),
      trailing: trailing.isNotEmpty
          ? Text(
              trailing,
              style: GoogleFonts.inter(
                color: isDark ? Colors.white24 : Colors.black26,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            )
          : Icon(
              Icons.chevron_right,
              size: 20,
              color: isDark ? Colors.white10 : Colors.black12,
            ),
    );
  }
}
