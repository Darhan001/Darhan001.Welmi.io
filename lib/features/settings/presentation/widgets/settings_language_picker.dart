import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/theme/locale_provider.dart';
import 'package:lumina/features/settings/presentation/widgets/settings_card.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Показывает шторку выбора языка и применяет выбор.
Future<void> showSettingsLanguagePicker(
  BuildContext context, {
  required bool isDark,
}) {
  final currentCode = localeProvider.locale.languageCode;
  const languages = [
    {'code': 'ru', 'name': 'Русский', 'flag': '🇷🇺'},
    {'code': 'ky', 'name': 'Кыргызча', 'flag': '🇰🇬'},
    {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
  ];

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)!.chooseLanguage,
              style: GoogleFonts.notoSerif(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: SettingsDesign.text(isDark),
              ),
            ),
            const SizedBox(height: 16),
            ...languages.map((lang) {
              final isSelected = currentCode == lang['code'];
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  localeProvider.setLocale(Locale(lang['code']!));
                  Navigator.pop(ctx);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? SettingsDesign.softGreen
                        : SettingsDesign.card(isDark),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? SettingsDesign.green
                          : Colors.transparent,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(lang['flag']!, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          lang['name']!,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: isSelected
                                ? const Color(0xFF4A8C5C)
                                : SettingsDesign.text(isDark),
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          size: 20,
                          color: SettingsDesign.green,
                        ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    ),
  );
}

/// Строка настроек с текущим языком интерфейса.
class SettingsLanguageTile extends StatelessWidget {
  const SettingsLanguageTile({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final currentCode = localeProvider.locale.languageCode;
    final currentName = LocaleProvider.localeNames[currentCode] ?? currentCode;
    final currentFlag = currentCode == 'ru'
        ? '🇷🇺'
        : currentCode == 'ky'
        ? '🇰🇬'
        : '🇬🇧';

    return GestureDetector(
      onTap: () => showSettingsLanguagePicker(context, isDark: isDark),
      child: SettingsCard(
        isDark: isDark,
        child: Row(
          children: [
            const SettingsTileIcon(icon: Icons.language),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.languageLabel,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: SettingsDesign.text(isDark),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$currentFlag $currentName',
                    style: TextStyle(
                      fontSize: 11,
                      color: SettingsDesign.textMuted(isDark),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: isDark ? Colors.white10 : Colors.black12,
            ),
          ],
        ),
      ),
    );
  }
}
