import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/features/settings/presentation/widgets/settings_card.dart';

/// Строка-переход: иконка, заголовок, подпись и стрелка (или свой хвост).
class SettingsNavTile extends StatelessWidget {
  const SettingsNavTile({
    super.key,
    required this.icon,
    required this.title,
    required this.isDark,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SettingsCard(
        isDark: isDark,
        child: Row(
          children: [
            SettingsTileIcon(icon: icon),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: SettingsDesign.text(isDark),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 11,
                        color: SettingsDesign.textMuted(isDark),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing ??
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

/// Отметка о подключённой синхронизации или кнопка «Подключить».
class SettingsStatusBadge extends StatelessWidget {
  const SettingsStatusBadge({
    super.key,
    required this.connected,
    required this.connectedLabel,
    required this.actionLabel,
  });

  final bool connected;
  final String connectedLabel;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: connected ? SettingsDesign.softGreen : Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        connected ? connectedLabel : actionLabel,
        style: TextStyle(
          color: connected ? SettingsDesign.green : Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
