import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/ux_helpers.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Шапка главного экрана: меню, название и уведомления.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.onOpenDrawer,
    required this.onOpenNotifications,
  });

  final VoidCallback onOpenDrawer;
  final VoidCallback onOpenNotifications;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Зона нажатия 48×48 и подписи для экранного диктора: раньше
        // кнопка реагировала только на сами пиксели иконки.
        IconButton(
          tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
          onPressed: () {
            hapticTap();
            onOpenDrawer();
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: tc.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.menu, color: tc.textOnPrimary, size: 20),
          ),
        ),
        Text(
          'Welmi',
          style: GoogleFonts.notoSerif(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: tc.text,
          ),
        ),
        IconButton(
          tooltip: AppLocalizations.of(context)!.notificationsPageTitle,
          onPressed: () {
            hapticTap();
            onOpenNotifications();
          },
          icon: Icon(Icons.notifications_none, size: 28, color: tc.text),
        ),
      ],
    );
  }
}
