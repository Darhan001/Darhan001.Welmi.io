import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
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

  /// Включить/выключить биометрию в настройках
  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricKey, enabled);
  }

  /// Выполнить аутентификацию
  Future<bool> authenticate() async {
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Пожалуйста, подтвердите личность для входа в Lumina',
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
