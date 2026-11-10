import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lumina/core/services/auth_service.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/app_app_bar.dart';
import 'package:lumina/core/widgets/ux_helpers.dart';
import 'package:lumina/features/support/presentation/widgets/feedback_form.dart';
import 'package:lumina/features/support/presentation/widgets/support_faq.dart';
import 'package:lumina/l10n/app_localizations.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  static const _email = 'support@welmi.app';
  static const _telegram = 'welmi_support';

  /// Открывает первую ссылку, которую удалось запустить. Раньше проверка
  /// canLaunchUrl без <queries> в манифесте давала false, и кнопка «Написать
  /// нам» молча ничего не делала; теперь при неудаче показываем контакт.
  static Future<void> _open(
    BuildContext context,
    List<(Uri, LaunchMode)> targets,
    String contact,
  ) async {
    final loc = AppLocalizations.of(context)!;
    for (final (uri, mode) in targets) {
      try {
        if (await launchUrl(uri, mode: mode)) return;
      } catch (e) {
        debugPrint('⚠️ Launch $uri failed: $e');
      }
    }
    if (context.mounted) {
      showWelmiSnackbar(
        context,
        loc.supportOpenFailed(contact),
        icon: Icons.info_outline,
      );
    }
  }

  void _openEmail(BuildContext context) {
    final userName = AuthService().displayName ?? 'User';
    final email = Uri(
      scheme: 'mailto',
      path: _email,
      query:
          'subject=${Uri.encodeComponent('Welmi Support — $userName')}'
          '&body=${Uri.encodeComponent('Hello Welmi team,\n\n')}',
    );
    _open(context, [(email, LaunchMode.platformDefault)], _email);
  }

  void _openTelegram(BuildContext context) {
    _open(context, [
      // Сначала приложение Telegram, затем веб-версия.
      (Uri.parse('tg://resolve?domain=$_telegram'), LaunchMode.platformDefault),
      (Uri.parse('https://t.me/$_telegram'), LaunchMode.externalApplication),
    ], '@$_telegram');
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: tc.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
          children: [
            AppAppBar(title: loc.supportTitle),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SupportContactCard(
                    icon: Icons.email_outlined,
                    title: loc.writeToUs,
                    subtitle: _email,
                    onTap: () => _openEmail(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SupportContactCard(
                    icon: Icons.telegram_outlined,
                    title: loc.telegram,
                    subtitle: '@$_telegram',
                    onTap: () => _openTelegram(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              loc.faq,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: tc.text,
              ),
            ),
            const SizedBox(height: 16),
            const SupportFaq(),
            const SizedBox(height: 24),
            const FeedbackForm(),
          ],
        ),
      ),
    );
  }
}
