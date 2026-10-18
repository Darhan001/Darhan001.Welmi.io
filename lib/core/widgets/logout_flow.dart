import 'package:flutter/material.dart';
import 'package:lumina/core/services/ai_service.dart';
import 'package:lumina/core/services/auth_service.dart';
import 'package:lumina/core/services/daily_tracker.dart';
import 'package:lumina/core/services/user_data_service.dart';
import 'package:lumina/core/widgets/app_snackbar.dart';
import 'package:lumina/core/widgets/ux_helpers.dart';
import 'package:lumina/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Единый сценарий выхода из аккаунта (боковое меню и профиль).
///
/// Раньше выход был реализован дважды и по-разному: из меню не очищались
/// данные профиля, а из профиля переход на экран входа не выполнялся, потому
/// что проверялся `mounted` уже закрытого диалога.
Future<void> confirmAndSignOut(BuildContext context) async {
  final loc = AppLocalizations.of(context)!;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        loc.drawerLogout,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      content: Text(loc.drawerLogoutConfirm),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(
            loc.drawerCancel,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(
            loc.drawerLogout,
            style: const TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  try {
    await AuthService().signOut();
  } catch (e) {
    debugPrint('⚠️ Sign out error: $e');
    if (context.mounted) AppSnackbar.error(context, loc.authError);
    return;
  }

  // Данные прошлого пользователя не должны мелькнуть у следующего.
  clearSessionData();

  if (!context.mounted) return;
  Navigator.of(context).pushAndRemoveUntil(
    smoothPageRoute(const OnboardingPage()),
    (route) => false,
  );
}

/// Очищает данные пользователя в памяти. Сохранённые на устройстве кэши
/// привязаны к userId, поэтому другому аккаунту не достанутся.
void clearSessionData() {
  DailyTracker().resetAll();
  UserDataService().reset();
  AiService().clearInMemory();
}
