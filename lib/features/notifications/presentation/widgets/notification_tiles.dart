import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/services/notifications/notification_settings.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/ux_helpers.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Подпись интервала напоминаний о воде на языке интерфейса.
String waterIntervalLabel(NotificationSettings s, AppLocalizations loc) {
  return switch (s.waterIntervalMin) {
    30 => loc.notifEvery30Min,
    60 => loc.notifEvery1h,
    90 => loc.notifEvery90Min,
    120 => loc.notifEvery2h,
    180 => loc.notifEvery3h,
    final m when m % 60 == 0 => loc.waterEveryHours(m ~/ 60),
    final m => loc.waterEveryMinutes(m),
  };
}

BoxDecoration notificationTileDecoration(ThemeColors tc) => BoxDecoration(
  color: tc.card,
  borderRadius: BorderRadius.circular(20),
  boxShadow: [
    BoxShadow(
      color: tc.shadow(0.02),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ],
);

/// Зелёная «таблетка» со значением (время, интервал); по нажатию — выбор.
class NotificationValueChip extends StatelessWidget {
  const NotificationValueChip({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          constraints: const BoxConstraints(minHeight: 36),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: tc.successBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: tc.isDark ? tc.success : tc.greenDark,
            ),
          ),
        ),
      ),
    );
  }
}

/// Строка с переключателем: главный выключатель или отдельное напоминание.
class NotificationSwitchTile extends StatelessWidget {
  const NotificationSwitchTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.indent = false,
    this.time,
    this.onTimeTap,
    this.decorated = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool indent;
  final TimeOfDay? time;
  final VoidCallback? onTimeTap;

  /// `false` — без собственной карточки (строка внутри другой карточки).
  final bool decorated;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Container(
      margin: decorated ? const EdgeInsets.only(bottom: 8) : null,
      padding: EdgeInsets.only(
        left: indent ? 52 : 16,
        right: 8,
        top: 10,
        bottom: 10,
      ),
      decoration: decorated ? notificationTileDecoration(tc) : null,
      child: Row(
        children: [
          if (!indent) ...[
            Icon(icon, size: 22, color: tc.textSecondary),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: tc.text,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: tc.textHint,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (time != null) ...[
            NotificationValueChip(
              label: time!.format(context),
              onTap: onTimeTap,
            ),
            const SizedBox(width: 8),
          ],
          Switch(
            value: value,
            onChanged: (v) {
              hapticTap();
              onChanged(v);
            },
            activeThumbColor: tc.green,
            inactiveThumbColor: tc.isDark
                ? Colors.grey.shade700
                : Colors.grey.shade300,
            inactiveTrackColor: tc.isDark
                ? Colors.white10
                : Colors.grey.shade100,
          ),
        ],
      ),
    );
  }
}

/// Предупреждение «уведомления не разрешены» — по нажатию запрос разрешения.
class NotificationPermissionBanner extends StatelessWidget {
  const NotificationPermissionBanner({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF4E0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFF0C36A)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 22,
                color: Color(0xFFB8860B),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.notifPermissionBanner,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF8A6508),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
