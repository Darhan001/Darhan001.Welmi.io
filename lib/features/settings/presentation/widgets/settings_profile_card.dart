import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/services/auth_service.dart';
import 'package:lumina/core/services/user_data_service.dart';
import 'package:lumina/features/settings/presentation/widgets/settings_card.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Карточка профиля в настройках: аватар, имя и переход к редактированию.
class SettingsProfileCard extends StatelessWidget {
  const SettingsProfileCard({
    super.key,
    required this.isDark,
    required this.onTap,
  });

  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: SettingsDesign.card(isDark),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Hero(
              tag: 'profile_avatar',
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white : Colors.black,
                  shape: BoxShape.circle,
                ),
                clipBehavior: Clip.antiAlias,
                child: _ProfileAvatar(isDark: isDark),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AuthService().displayName ??
                        AppLocalizations.of(context)!.userDefault,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: SettingsDesign.text(isDark),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppLocalizations.of(context)!.editProfile,
                    style: GoogleFonts.inter(
                      color: SettingsDesign.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black12),
          ],
        ),
      ),
    );
  }
}

/// Аватар профиля: фото (если задано) или первая буква имени.
class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final photoUrl =
        UserDataService().profile?.photoUrl ?? AuthService().photoUrl;
    final name = AuthService().displayName ?? 'П';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'П';

    Widget letter() => Center(
      child: Text(
        initial,
        style: TextStyle(
          color: isDark ? Colors.black : Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    return photoUrl != null
        ? Image.network(
            photoUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => letter(),
          )
        : letter();
  }
}
