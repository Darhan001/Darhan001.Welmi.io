import 'package:flutter/material.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/app_button.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Экран за системным окном отпечатка.
///
/// Отдельный виджет, а не метод корневого State: только так у него есть
/// context внутри MaterialApp с локализацией и темой. Раньше тексты брались
/// из context выше MaterialApp, и экран падал с ошибкой.
class LockScreen extends StatelessWidget {
  const LockScreen({super.key, required this.onUnlock});

  final Future<void> Function() onUnlock;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final tc = ThemeColors.of(context);
    return Scaffold(
      backgroundColor: tc.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    color: tc.green.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    size: 56,
                    color: tc.green,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  loc.accessRestricted,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: tc.text,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  loc.accessRestrictedSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: tc.textSecondary,
                  ),
                ),
                const SizedBox(height: 40),
                AppButton(
                  text: loc.unlockButton,
                  icon: Icons.fingerprint_rounded,
                  fullWidth: false,
                  onPressed: onUnlock,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
