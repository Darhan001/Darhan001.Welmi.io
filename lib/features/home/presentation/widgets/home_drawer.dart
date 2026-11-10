import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Пункт бокового меню.
class HomeDrawerEntry {
  const HomeDrawerEntry({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

/// Боковое меню: профиль, разделы приложения и выход.
class HomeDrawer extends StatelessWidget {
  const HomeDrawer({
    super.key,
    required this.fullName,
    required this.isPremium,
    required this.entries,
    required this.onLogout,
  });

  final String fullName;

  /// Premium определяется только серверным entitlement.
  final bool isPremium;
  final List<HomeDrawerEntry> entries;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final loc = AppLocalizations.of(context)!;
    final initial = fullName.trim().isNotEmpty
        ? fullName.trim()[0].toUpperCase()
        : 'П';

    return Drawer(
      backgroundColor: tc.background,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: tc.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: TextStyle(
                          color: tc.textOnPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: tc.text,
                          ),
                        ),
                        // Статус Premium — только по серверному entitlement.
                        // Раньше подпись «Welmi Premium» видели все.
                        if (isPremium) ...[
                          const SizedBox(height: 2),
                          Text(
                            loc.welmiPremium,
                            style: TextStyle(color: tc.greenDark, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(indent: 24, endIndent: 24, color: tc.divider),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final entry in entries)
                    _DrawerItem(
                      icon: entry.icon,
                      title: entry.label,
                      onTap: entry.onTap,
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: _DrawerItem(
                icon: Icons.logout_rounded,
                title: loc.drawerLogout,
                onTap: onLogout,
                color: Colors.redAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    return Builder(
      // Свой context внутри Drawer: через него закрываем меню перед
      // переходом, иначе при возврате назад оно оставалось открытым.
      builder: (itemContext) => ListTile(
        onTap: () {
          Scaffold.maybeOf(itemContext)?.closeDrawer();
          onTap();
        },
        leading: Icon(icon, color: color ?? tc.text.withValues(alpha: 0.7)),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: color ?? tc.text,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
