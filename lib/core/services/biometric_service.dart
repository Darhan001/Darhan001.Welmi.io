import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _auth = LocalAuthentication();
  static const String _biometricKey = 'use_biometrics';

  /// Проверить, поддерживает ли устройство биометрию
  Future<bool> isBiometricAvailable() async {
    try {
      final bool canCheck = await _auth.canCheckBiometrics;
      final bool isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
    } catch (e) {
      return false;
    }
  }

  /// Проверить, включена ли биометрия в настройках приложения
  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricKey) ?? false;
  }

  /// Тексты окна биометрии на языке приложения.
  Future<bool> authenticateWith(AppLocalizations loc) => authenticate(
    reason: loc.biometricReason,
    title: loc.biometricTitle,
    hint: loc.biometricHint,
    cancel: loc.drawerCancel,
  );

  /// Включить/выключить биометрию в настройках
  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricKey, enabled);
  }

  /// Выполнить аутентификацию.
  ///
  /// Тексты приходят из UI на языке приложения: раньше окно показывало
  /// старое название «Lumina» и английский заголовок Android по умолчанию.
  Future<bool> authenticate({
    required String reason,
    required String title,
    required String hint,
    required String cancel,
  }) async {
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: reason,
        authMessages: <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: title,
            biometricHint: hint,
            cancelButton: cancel,
          ),
          IOSAuthMessages(cancelButton: cancel),
        ],
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
          useErrorDialogs: true,
        ),
      );
      return didAuthenticate;
    } on PlatformException catch (e) {
      // Ошибка может возникнуть, если биометрия не настроена на телефоне
      debugPrint('❌ Biometric error: $e');
      return false;
    } catch (e) {
      debugPrint('❌ Unknown biometric error: $e');
      return false;
    }
  }
}
