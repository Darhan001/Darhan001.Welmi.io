import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the app's locale and persists the user's language choice.
class LocaleProvider extends ChangeNotifier {
  static const String _localeKey = 'app_locale';
  Locale _locale = const Locale('ru'); // Default: Russian

  Locale get locale => _locale;

  /// Supported locale codes
  static const supportedLocaleCodes = ['ru', 'ky', 'en'];

  /// Maps locale code to display name (in its own language)
  static const localeNames = {
    'ru': 'Русский',
    'ky': 'Кыргызча',
    'en': 'English',
  };

  LocaleProvider() {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_localeKey);
      if (saved != null && supportedLocaleCodes.contains(saved)) {
        _locale = Locale(saved);
        notifyListeners();
      } else {
        // Try to match device locale
        final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
        final deviceCode = deviceLocale.languageCode;
        if (supportedLocaleCodes.contains(deviceCode)) {
          _locale = Locale(deviceCode);
          notifyListeners();
        }
        // Otherwise keep default 'ru'
      }
    } catch (e) {
      debugPrint('Locale load error: $e');
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, locale.languageCode);
    } catch (e) {
      debugPrint('Locale save error: $e');
    }
  }
}
